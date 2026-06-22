import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Local SQLite store for outbox queues and message cache.
class AppDatabase {
  static final AppDatabase _instance = AppDatabase._();
  factory AppDatabase() => _instance;
  AppDatabase._();

  static const _dbName = 'shamba_smart.db';
  static const _dbVersion = 5;

  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    final path = join(dir, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // v2: store the remote Storage URL for image messages so the recipient
      // (and the sender after re-sync) can render the actual photo.
      await db.execute('ALTER TABLE messages ADD COLUMN image_url TEXT');
    }
    if (oldVersion < 3) {
      // v3: wipe the cached messages once so any rows mis-attributed by the old
      // sender logic are dropped and re-pulled fresh from Supabase (correct
      // from_id). Outbox is untouched, so unsent messages still send.
      await db.delete('messages');
    }
    if (oldVersion < 4) {
      // v4: track whether a message was edited (for the "(imehaririwa)" label).
      await db.execute('ALTER TABLE messages ADD COLUMN edited INTEGER NOT NULL DEFAULT 0');
    }
    if (oldVersion < 5) {
      // v5: offline cache for the field-officer directory.
      await db.execute(_createOfficersCacheSql);
    }
  }

  static const _createOfficersCacheSql = '''
    CREATE TABLE field_officers_cache (
      id TEXT PRIMARY KEY,
      json TEXT NOT NULL,
      rank INTEGER NOT NULL
    )
  ''';

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE outbox (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        retry_count INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        last_error TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY,
        client_id TEXT,
        owner_id TEXT NOT NULL,
        from_id TEXT NOT NULL,
        to_id TEXT NOT NULL,
        from_name TEXT NOT NULL,
        to_name TEXT NOT NULL,
        from_role TEXT NOT NULL,
        to_role TEXT NOT NULL,
        content TEXT NOT NULL,
        type TEXT NOT NULL DEFAULT 'text',
        is_read INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'sent',
        created_at TEXT NOT NULL,
        edited INTEGER NOT NULL DEFAULT 0,
        image_path TEXT,
        image_url TEXT,
        location_lat REAL,
        location_lng REAL,
        location_name TEXT,
        file_path TEXT,
        file_name TEXT,
        file_type TEXT,
        file_size INTEGER
      )
    ''');

    await db.execute(
        'CREATE INDEX idx_outbox_status ON outbox(status, created_at)');
    await db.execute(
        'CREATE INDEX idx_messages_owner ON messages(owner_id, created_at)');

    await db.execute(_createOfficersCacheSql);
  }

  // ── Field-officer directory cache (offline-first) ──────────────────────────

  Future<void> cacheOfficers(List<String> jsonRows) async {
    final db = await database;
    final batch = db.batch();
    batch.delete('field_officers_cache');
    for (var i = 0; i < jsonRows.length; i++) {
      batch.insert('field_officers_cache',
          {'id': '$i', 'json': jsonRows[i], 'rank': i});
    }
    await batch.commit(noResult: true);
  }

  Future<List<String>> cachedOfficers() async {
    final db = await database;
    final rows =
        await db.query('field_officers_cache', orderBy: 'rank ASC');
    return rows.map((r) => r['json'] as String).toList();
  }

  // ── Outbox ────────────────────────────────────────────────────────────────

  Future<void> enqueueOutbox({
    required String id,
    required String type,
    required String payloadJson,
  }) async {
    final db = await database;
    await db.insert('outbox', {
      'id': id,
      'type': type,
      'payload_json': payloadJson,
      'status': 'pending',
      'retry_count': 0,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> pendingOutbox({String? type}) async {
    final db = await database;
    if (type != null) {
      return db.query(
        'outbox',
        where: "status = 'pending' AND type = ?",
        whereArgs: [type],
        orderBy: 'created_at ASC',
      );
    }
    return db.query(
      'outbox',
      where: "status = 'pending'",
      orderBy: 'created_at ASC',
    );
  }

  Future<int> pendingCount() async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT COUNT(*) as c FROM outbox WHERE status = 'pending'",
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> markOutboxSending(String id) async {
    final db = await database;
    await db.update('outbox', {'status': 'sending'}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> markOutboxSent(String id) async {
    final db = await database;
    await db.delete('outbox', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> markOutboxFailed(String id, String error) async {
    final db = await database;
    await db.rawUpdate('''
      UPDATE outbox
      SET status = 'pending', retry_count = retry_count + 1, last_error = ?
      WHERE id = ?
    ''', [error, id]);
  }

  Future<void> markOutboxDead(String id, String error) async {
    final db = await database;
    await db.update(
      'outbox',
      {'status': 'failed', 'last_error': error},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ── Messages cache ────────────────────────────────────────────────────────

  Future<void> upsertMessage(Map<String, dynamic> row) async {
    final db = await database;
    await db.insert('messages', row, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> messagesForOwner(String ownerId) async {
    final db = await database;
    return db.query(
      'messages',
      where: 'owner_id = ?',
      whereArgs: [ownerId],
      orderBy: 'created_at ASC',
    );
  }

  Future<void> clearMessagesForOwner(String ownerId) async {
    final db = await database;
    await db.delete('messages', where: 'owner_id = ?', whereArgs: [ownerId]);
  }

  Future<void> deleteMessageById(String id) async {
    final db = await database;
    await db.delete('messages', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateMessageContent(String id, String content) async {
    final db = await database;
    await db.update(
      'messages',
      {'content': content, 'edited': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

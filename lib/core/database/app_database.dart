import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Local SQLite store for outbox queues and message cache.
class AppDatabase {
  static final AppDatabase _instance = AppDatabase._();
  factory AppDatabase() => _instance;
  AppDatabase._();

  static const _dbName = 'shamba_smart.db';
  static const _dbVersion = 1;

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
    );
  }

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
        image_path TEXT,
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
}

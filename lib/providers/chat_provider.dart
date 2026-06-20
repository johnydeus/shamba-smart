import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../features/messaging/data/message_repository.dart';
import '../features/messaging/domain/message_status.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';

class ChatProvider extends ChangeNotifier {
  String? _myId;

  // Single source of truth for "who am I": the live Supabase auth uid. This is
  // exactly the value stamped as from_id when sending, so mine-vs-theirs is
  // always correct regardless of cached/profile id state.
  String? get _authUid => Supabase.instance.client.auth.currentUser?.id;
  String? get _effectiveId =>
      (_authUid != null && _authUid!.isNotEmpty) ? _authUid : _myId;

  final MessageRepository _repo = MessageRepository();
  final Map<String, ConversationModel> _conversations = {};
  Map<String, ConversationModel> get conversations => _conversations;

  bool get isReady => _myId != null && _myId!.isNotEmpty;

  int get totalUnread =>
      _conversations.values.fold(0, (sum, c) => sum + c.unreadCount);

  int get pendingCount => _conversations.values
      .expand((c) => c.messages)
      .where((m) => m.isFromMe && m.status == MessageStatus.pending)
      .length;

  RealtimeChannel? _channel;

  Future<void> init(String userId, String userName, String userRole) async {
    // Prefer the auth uid so the id used to STAMP from_id and the id used to
    // COMPARE (isFromMe) are guaranteed identical.
    _myId = _authUid ?? userId;
    _conversations.clear();

    _repo.configure(ownerId: _myId!, myName: userName, myRole: userRole);

    // Offline-first: load local cache immediately.
    await _loadFromLocal();
    _subscribeRealtime();

    // Background sync from Supabase.
    _syncFromRemote();
  }

  void clear() {
    _channel?.unsubscribe();
    _channel = null;
    _myId = null;
    _repo.clear();
    _conversations.clear();
    notifyListeners();
  }

  void _subscribeRealtime() {
    _channel?.unsubscribe();
    if (_myId == null) return;

    _channel = Supabase.instance.client
        .channel('messages_$_myId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          table: 'direct_messages',
          callback: (payload) {
            final row = payload.newRecord;
            if (row['to_id'] == _myId || row['from_id'] == _myId) {
              _syncFromRemote();
            }
          },
        )
        .subscribe();
  }

  Future<void> _loadFromLocal() async {
    if (!isReady) return;
    try {
      final rows = await _repo.loadLocalRows();
      _buildConversationsFromRows(
        rows.map((r) => _localRowToSupabaseShape(r)).toList(),
      );
      notifyListeners();
    } catch (e) {
      debugPrint('ChatProvider._loadFromLocal error: $e');
    }
  }

  Map<String, dynamic> _localRowToSupabaseShape(Map<String, dynamic> row) => {
        'id': row['id'],
        'from_id': row['from_id'],
        'to_id': row['to_id'],
        'from_name': row['from_name'],
        'to_name': row['to_name'],
        'from_role': row['from_role'],
        'to_role': row['to_role'],
        'content': row['content'],
        'type': row['type'],
        'image_url': row['image_url'],
        'image_path': row['image_path'],
        'edited': (row['edited'] as int? ?? 0) == 1,
        'is_read': (row['is_read'] as int? ?? 0) == 1,
        'created_at': row['created_at'],
        'status': row['status'],
      };

  Future<void> _syncFromRemote() async {
    if (!isReady) return;
    try {
      final rows = await Supabase.instance.client
          .from('direct_messages')
          .select()
          .or('from_id.eq.$_myId,to_id.eq.$_myId')
          .order('created_at', ascending: true)
          .timeout(const Duration(seconds: 8));

      await _repo.cacheFromRemote(rows as List);
      _buildConversationsFromRows(rows.cast<Map<String, dynamic>>());
      notifyListeners();
    } catch (e) {
      debugPrint('ChatProvider._syncFromRemote error: $e');
    }
  }

  Future<void> loadMessages() => _syncFromRemote();

  void _buildConversationsFromRows(List<Map<String, dynamic>> rows) {
    final newConvs = <String, ConversationModel>{};

    for (final row in rows) {
      final fromId = row['from_id'] as String;
      final myId = _effectiveId;
      final toId = row['to_id'] as String;
      final fromName = row['from_name'] as String;
      final toName = row['to_name'] as String;
      final fromRole = row['from_role'] as String? ?? 'mkulima';
      final toRole = row['to_role'] as String? ?? 'mkulima';
      final isFromMe = fromId == myId;

      final partnerId = isFromMe ? toId : fromId;
      final partnerName = isFromMe ? toName : fromName;
      final partnerRole = isFromMe ? toRole : fromRole;
      final partnerColor = UserRoleX.fromKey(partnerRole).colorHex;

      final conv = newConvs.putIfAbsent(
        partnerId,
        () => ConversationModel(
          contactId: partnerId,
          contactName: partnerName,
          contactRole: UserRoleX.fromKey(partnerRole),
          contactColorHex: partnerColor,
          messages: [],
        ),
      );

      final typeStr = row['type'] as String? ?? 'text';
      final statusStr = row['status'] as String? ?? 'sent';

      conv.messages.add(MessageModel(
        id: row['id'] as String,
        senderId: fromId,
        text: row['content'] as String,
        timestamp: DateTime.parse(row['created_at'] as String).toLocal(),
        isFromMe: isFromMe,
        isRead: row['is_read'] as bool? ?? false,
        type: MessageType.values.firstWhere(
          (t) => t.name == typeStr,
          orElse: () => MessageType.text,
        ),
        status: MessageStatus.values.firstWhere(
          (s) => s.name == statusStr,
          orElse: () => MessageStatus.sent,
        ),
        edited: row['edited'] as bool? ?? false,
        imageUrl: row['image_url'] as String?,
        imagePath: row['image_path'] as String?,
      ));

      if (!isFromMe && !(row['is_read'] as bool? ?? false)) {
        conv.unreadCount++;
      }
    }

    _conversations.clear();
    _conversations.addAll(newConvs);
  }

  Future<void> sendMessage({
    required String currentUserId,
    required String contactId,
    required String contactName,
    required UserRole contactRole,
    required String contactColorHex,
    required String text,
  }) async {
    if (!isReady) {
      throw Exception(
          'Hujaunganika bado. Funga app na uifungue tena kisha jaribu.');
    }
    if (text.trim().isEmpty) return;

    final msg = await _repo.sendText(
      contactId: contactId,
      contactName: contactName,
      contactRole: contactRole,
      text: text,
    );

    final conv = getConversation(
      contactId,
      contactName,
      contactRole,
      contactColorHex,
    );
    conv.messages.add(msg);
    notifyListeners();
  }

  Future<void> sendImage({
    required String currentUserId,
    required String contactId,
    required String contactName,
    required UserRole contactRole,
    required String contactColorHex,
    required String imagePath,
    String caption = '',
  }) async {
    if (!isReady) {
      throw Exception(
          'Hujaunganika bado. Funga app na uifungue tena kisha jaribu.');
    }

    // Compress + upload, then queue the message carrying the real image URL.
    // Throws on failure (offline / upload error) so the UI can show a retry
    // message — we never add a fake "sent" bubble.
    final msg = await _repo.sendImageMessage(
      contactId: contactId,
      contactName: contactName,
      contactRole: contactRole,
      localPath: imagePath,
      caption: caption,
    );

    final conv = getConversation(
      contactId,
      contactName,
      contactRole,
      contactColorHex,
    );
    conv.messages.add(msg);
    notifyListeners();
  }

  // ── Edit / delete own messages (owner enforced by RLS) ──────────────────────

  Future<void> editMessage(String contactId, MessageModel message, String newText) async {
    final trimmed = newText.trim();
    if (trimmed.isEmpty || trimmed == message.text) return;
    await _repo.editMessage(message.id, trimmed);

    final conv = _conversations[contactId];
    if (conv == null) return;
    final i = conv.messages.indexWhere((m) => m.id == message.id);
    if (i != -1) {
      final m = conv.messages[i];
      conv.messages[i] = MessageModel(
        id: m.id,
        senderId: m.senderId,
        text: trimmed,
        timestamp: m.timestamp,
        isFromMe: m.isFromMe,
        isRead: m.isRead,
        type: m.type,
        status: m.status,
        edited: true,
        imagePath: m.imagePath,
        imageUrl: m.imageUrl,
      );
      notifyListeners();
    }
  }

  Future<void> deleteMessage(String contactId, MessageModel message) async {
    await _repo.deleteMessage(message.id, imageUrl: message.imageUrl);
    final conv = _conversations[contactId];
    if (conv != null) {
      conv.messages.removeWhere((m) => m.id == message.id);
      notifyListeners();
    }
  }

  Future<void> sendLocation({
    required String currentUserId,
    required String contactId,
    required String contactName,
    required UserRole contactRole,
    required String contactColorHex,
    required double lat,
    required double lng,
    String locationName = 'Eneo Langu',
  }) async {
    final text =
        '📍 $locationName\nLat: ${lat.toStringAsFixed(5)}, Lng: ${lng.toStringAsFixed(5)}\nhttps://maps.google.com/?q=$lat,$lng';
    await sendMessage(
      currentUserId: currentUserId,
      contactId: contactId,
      contactName: contactName,
      contactRole: contactRole,
      contactColorHex: contactColorHex,
      text: text,
    );
  }

  Future<void> sendFile({
    required String currentUserId,
    required String contactId,
    required String contactName,
    required UserRole contactRole,
    required String contactColorHex,
    required String filePath,
    required String fileName,
    required String fileType,
    required int fileSize,
  }) async {
    final kb = (fileSize / 1024).toStringAsFixed(1);
    await sendMessage(
      currentUserId: currentUserId,
      contactId: contactId,
      contactName: contactName,
      contactRole: contactRole,
      contactColorHex: contactColorHex,
      text: '📄 Faili: $fileName ($kb KB)',
    );
  }

  Future<void> markRead(String contactId) async {
    if (_conversations.containsKey(contactId)) {
      _conversations[contactId]!.unreadCount = 0;
      notifyListeners();
    }
    if (!isReady) return;
    try {
      await Supabase.instance.client
          .from('direct_messages')
          .update({'is_read': true})
          .eq('to_id', _myId!)
          .eq('from_id', contactId)
          .eq('is_read', false);
    } catch (e) {
      debugPrint('ChatProvider.markRead error: $e');
    }
  }

  ConversationModel getConversation(
    String contactId,
    String contactName,
    UserRole contactRole,
    String contactColorHex,
  ) =>
      _conversations.putIfAbsent(
        contactId,
        () => ConversationModel(
          contactId: contactId,
          contactName: contactName,
          contactRole: contactRole,
          contactColorHex: contactColorHex,
          messages: [],
        ),
      );
}

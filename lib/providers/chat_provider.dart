import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';

class ChatProvider extends ChangeNotifier {
  String? _myId;
  String? _myName;
  String? _myRole;

  final Map<String, ConversationModel> _conversations = {};
  Map<String, ConversationModel> get conversations => _conversations;

  bool get isReady => _myId != null && _myId!.isNotEmpty;

  int get totalUnread =>
      _conversations.values.fold(0, (sum, c) => sum + c.unreadCount);

  RealtimeChannel? _channel;

  // ── Init ────────────────────────────────────────────────────────────────────

  Future<void> init(String userId, String userName, String userRole) async {
    _myId   = userId;
    _myName = userName;
    _myRole = userRole;
    _conversations.clear();

    await loadMessages();
    _subscribeRealtime();  // listen for instant incoming messages
  }

  void clear() {
    _channel?.unsubscribe();
    _channel = null;
    _myId   = null;
    _myName = null;
    _myRole = null;
    _conversations.clear();
    notifyListeners();
  }

  // ── Supabase Realtime — instant delivery ────────────────────────────────────

  void _subscribeRealtime() {
    _channel?.unsubscribe();
    if (_myId == null) return;

    _channel = Supabase.instance.client
        .channel('messages_$_myId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'direct_messages',
          callback: (payload) {
            // Only process messages addressed TO me
            final row = payload.newRecord;
            if (row['to_id'] == _myId || row['from_id'] == _myId) {
              loadMessages(); // refresh the full conversation
            }
          },
        )
        .subscribe();

    debugPrint('ChatProvider: realtime subscribed for $_myId');
  }

  // ── Load conversations from Supabase ────────────────────────────────────────

  Future<void> loadMessages() async {
    if (!isReady) return;
    try {
      final rows = await Supabase.instance.client
          .from('direct_messages')
          .select()
          .or('from_id.eq.$_myId,to_id.eq.$_myId')
          .order('created_at');

      final newConvs = <String, ConversationModel>{};

      for (final row in rows as List) {
        final fromId    = row['from_id']   as String;
        final toId      = row['to_id']     as String;
        final fromName  = row['from_name'] as String;
        final toName    = row['to_name']   as String;
        final fromRole  = row['from_role'] as String? ?? 'mkulima';
        final toRole    = row['to_role']   as String? ?? 'mkulima';
        final isFromMe  = fromId == _myId;

        final partnerId    = isFromMe ? toId     : fromId;
        final partnerName  = isFromMe ? toName   : fromName;
        final partnerRole  = isFromMe ? toRole   : fromRole;
        final partnerColor = UserRoleX.fromKey(partnerRole).colorHex;

        final conv = newConvs.putIfAbsent(
          partnerId,
          () => ConversationModel(
            contactId:       partnerId,
            contactName:     partnerName,
            contactRole:     UserRoleX.fromKey(partnerRole),
            contactColorHex: partnerColor,
            messages:        [],
          ),
        );

        conv.messages.add(MessageModel(
          id:        row['id'] as String,
          senderId:  fromId,
          text:      row['content'] as String,
          timestamp: DateTime.parse(row['created_at'] as String).toLocal(),
          isFromMe:  isFromMe,
          type:      MessageType.text,
        ));

        if (!isFromMe && !(row['is_read'] as bool? ?? false)) {
          conv.unreadCount++;
        }
      }

      _conversations.clear();
      _conversations.addAll(newConvs);
      notifyListeners();
    } catch (e) {
      debugPrint('ChatProvider.loadMessages error: $e');
      rethrow; // let callers handle it
    }
  }

  // ── Send message ─────────────────────────────────────────────────────────────

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

    final id  = DateTime.now().microsecondsSinceEpoch.toString();

    await Supabase.instance.client.from('direct_messages').insert({
      'id':        id,
      'from_id':   _myId,
      'from_name': _myName ?? 'Mkulima',
      'from_role': _myRole ?? 'mkulima',
      'to_id':     contactId,
      'to_name':   contactName,
      'to_role':   contactRole.key,
      'content':   text.trim(),
      'type':      'text',
      'is_read':   false,
    });

    // Refresh immediately so sender sees their message
    await loadMessages();
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
    final notice = caption.isNotEmpty ? '📷 Picha: $caption' : '📷 Ametuma picha';
    await sendMessage(
      currentUserId: currentUserId, contactId: contactId,
      contactName: contactName, contactRole: contactRole,
      contactColorHex: contactColorHex, text: notice,
    );
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
      currentUserId: currentUserId, contactId: contactId,
      contactName: contactName, contactRole: contactRole,
      contactColorHex: contactColorHex, text: text,
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
      currentUserId: currentUserId, contactId: contactId,
      contactName: contactName, contactRole: contactRole,
      contactColorHex: contactColorHex, text: '📄 Faili: $fileName ($kb KB)',
    );
  }

  // ── Mark read ────────────────────────────────────────────────────────────────

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

  // ── Helper ───────────────────────────────────────────────────────────────────

  ConversationModel getConversation(
    String contactId,
    String contactName,
    UserRole contactRole,
    String contactColorHex,
  ) =>
      _conversations.putIfAbsent(
        contactId,
        () => ConversationModel(
          contactId: contactId, contactName: contactName,
          contactRole: contactRole, contactColorHex: contactColorHex,
          messages: [],
        ),
      );
}

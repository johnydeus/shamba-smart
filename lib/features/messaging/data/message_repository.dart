import 'dart:convert';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../../../core/network/connectivity_service.dart';
import '../../../core/sync/sync_coordinator.dart';
import '../../../core/utils/image_upload_helper.dart';
import '../../../models/message_model.dart';
import '../../../models/user_model.dart';
import '../domain/message_status.dart';

/// Private chat photos are stored in the existing public `community-images`
/// bucket under a dedicated `chat/` folder, with random UUID filenames so the
/// URLs are unguessable (the privacy model chosen for this app).
const _kChatImageBucket = 'community-images';
const _kChatImageFolder = 'chat';

/// Offline-first message repository with outbox queue.
class MessageRepository {
  static final MessageRepository _instance = MessageRepository._();
  factory MessageRepository() => _instance;
  MessageRepository._();

  final AppDatabase _db = AppDatabase();
  final ConnectivityService _connectivity = ConnectivityService();
  final _uuid = const Uuid();

  String? _ownerId;
  String? _myName;
  String? _myRole;

  void configure({
    required String ownerId,
    required String myName,
    required String myRole,
  }) {
    _ownerId = ownerId;
    _myName = myName;
    _myRole = myRole;
  }

  void clear() {
    _ownerId = null;
    _myName = null;
    _myRole = null;
  }

  bool get isReady => _ownerId != null && _ownerId!.isNotEmpty;

  Future<List<Map<String, dynamic>>> loadLocalRows() async {
    if (!isReady) return [];
    return _db.messagesForOwner(_ownerId!);
  }

  Future<void> cacheFromRemote(List<dynamic> rows) async {
    if (!isReady) return;
    for (final row in rows) {
      await _db.upsertMessage({
        'id': row['id'] as String,
        'client_id': row['client_id'] as String?,
        'owner_id': _ownerId,
        'from_id': row['from_id'] as String,
        'to_id': row['to_id'] as String,
        'from_name': row['from_name'] as String,
        'to_name': row['to_name'] as String,
        'from_role': row['from_role'] as String? ?? 'mkulima',
        'to_role': row['to_role'] as String? ?? 'mkulima',
        'content': row['content'] as String,
        'type': row['type'] as String? ?? 'text',
        'image_url': row['image_url'] as String?,
        'edited': (row['edited'] as bool? ?? false) ? 1 : 0,
        'is_read': (row['is_read'] as bool? ?? false) ? 1 : 0,
        'status': 'sent',
        'created_at': row['created_at'] as String,
      });
    }
  }

  Future<MessageModel> sendText({
    required String contactId,
    required String contactName,
    required UserRole contactRole,
    required String text,
  }) async {
    if (!isReady) {
      throw Exception('Hujaunganika bado. Jaribu tena.');
    }

    final clientId = _uuid.v4();
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final now = DateTime.now().toIso8601String();

    final row = {
      'id': id,
      'client_id': clientId,
      'owner_id': _ownerId,
      'from_id': _ownerId,
      'to_id': contactId,
      'from_name': _myName ?? 'Mkulima',
      'to_name': contactName,
      'from_role': _myRole ?? 'mkulima',
      'to_role': contactRole.key,
      'content': text.trim(),
      'type': 'text',
      'is_read': 0,
      'status': MessageStatus.pending.name,
      'created_at': now,
    };

    await _db.upsertMessage(row);

    await _db.enqueueOutbox(
      id: clientId,
      type: 'message',
      payloadJson: jsonEncode({
        'id': id,
        'client_id': clientId,
        'from_id': _ownerId,
        'from_name': _myName ?? 'Mkulima',
        'from_role': _myRole ?? 'mkulima',
        'to_id': contactId,
        'to_name': contactName,
        'to_role': contactRole.key,
        'content': text.trim(),
        'type': 'text',
      }),
    );

    await SyncCoordinator().refreshStatus();

    if (_connectivity.isOnline) {
      await SyncCoordinator().flushAll();
    }

    return MessageModel(
      id: id,
      senderId: _ownerId!,
      text: text.trim(),
      timestamp: DateTime.parse(now),
      isFromMe: true,
      status: MessageStatus.pending,
    );
  }

  /// Send a photo message: compress + upload to Storage, then queue the
  /// message row carrying the resulting public URL. Requires connectivity —
  /// throws if the upload fails so the UI can show a retry message and never
  /// fake a "sent" state. [localPath] is kept for an instant optimistic preview.
  Future<MessageModel> sendImageMessage({
    required String contactId,
    required String contactName,
    required UserRole contactRole,
    required String localPath,
    String caption = '',
  }) async {
    if (!isReady) {
      throw Exception('Hujaunganika bado. Jaribu tena.');
    }
    if (!_connectivity.isOnline) {
      throw Exception('Hakuna intaneti. Huwezi kutuma picha bila mtandao.');
    }

    // 1. Compress + upload (throws on failure → caller shows retry message).
    final imageUrl = await ImageUploadHelper.compressAndUpload(
      File(localPath),
      bucket: _kChatImageBucket,
      folder: _kChatImageFolder,
    );

    final clientId = _uuid.v4();
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final now = DateTime.now().toIso8601String();
    final content = caption.trim();

    await _db.upsertMessage({
      'id': id,
      'client_id': clientId,
      'owner_id': _ownerId,
      'from_id': _ownerId,
      'to_id': contactId,
      'from_name': _myName ?? 'Mkulima',
      'to_name': contactName,
      'from_role': _myRole ?? 'mkulima',
      'to_role': contactRole.key,
      'content': content,
      'type': 'image',
      'image_path': localPath,
      'image_url': imageUrl,
      'is_read': 0,
      'status': MessageStatus.pending.name,
      'created_at': now,
    });

    await _db.enqueueOutbox(
      id: clientId,
      type: 'message',
      payloadJson: jsonEncode({
        'id': id,
        'client_id': clientId,
        'from_id': _ownerId,
        'from_name': _myName ?? 'Mkulima',
        'from_role': _myRole ?? 'mkulima',
        'to_id': contactId,
        'to_name': contactName,
        'to_role': contactRole.key,
        'content': content,
        'type': 'image',
        'image_url': imageUrl,
      }),
    );

    await SyncCoordinator().refreshStatus();
    if (_connectivity.isOnline) {
      await SyncCoordinator().flushAll();
    }

    return MessageModel(
      id: id,
      senderId: _ownerId!,
      text: content,
      timestamp: DateTime.parse(now),
      isFromMe: true,
      type: MessageType.image,
      status: MessageStatus.pending,
      imagePath: localPath,
      imageUrl: imageUrl,
    );
  }

  /// Process outbox message item (called by SyncCoordinator).
  Future<bool> processOutboxItem(Map<String, dynamic> item) async {
    final payload =
        jsonDecode(item['payload_json'] as String) as Map<String, dynamic>;

    final imageUrl = payload['image_url'] as String?;
    await Supabase.instance.client.from('direct_messages').insert({
      'id': payload['id'],
      'from_id': payload['from_id'],
      'from_name': payload['from_name'],
      'from_role': payload['from_role'],
      'to_id': payload['to_id'],
      'to_name': payload['to_name'],
      'to_role': payload['to_role'],
      'content': payload['content'],
      'type': payload['type'] ?? 'text',
      // Only sent for image messages — keeps text inserts working even if the
      // direct_messages.image_url column has not been added yet.
      'image_url': ?imageUrl,
      'is_read': false,
    });

    if (_ownerId != null) {
      await _db.upsertMessage({
        'id': payload['id'] as String,
        'client_id': payload['client_id'] as String?,
        'owner_id': _ownerId,
        'from_id': payload['from_id'],
        'to_id': payload['to_id'],
        'from_name': payload['from_name'],
        'to_name': payload['to_name'],
        'from_role': payload['from_role'],
        'to_role': payload['to_role'],
        'content': payload['content'],
        'type': payload['type'] ?? 'text',
        'image_url': imageUrl,
        'is_read': 0,
        'status': 'sent',
        'created_at': DateTime.now().toIso8601String(),
      });
    }

    return true;
  }

  MessageModel rowToModel(Map<String, dynamic> row) {
    final fromId = row['from_id'] as String;
    final typeStr = row['type'] as String? ?? 'text';
    final statusStr = row['status'] as String? ?? 'sent';

    return MessageModel(
      id: row['id'] as String,
      senderId: fromId,
      text: row['content'] as String,
      timestamp: DateTime.parse(row['created_at'] as String).toLocal(),
      isFromMe: fromId == _ownerId,
      isRead: (row['is_read'] as int? ?? 0) == 1,
      type: MessageType.values.firstWhere(
        (t) => t.name == typeStr,
        orElse: () => MessageType.text,
      ),
      status: MessageStatus.values.firstWhere(
        (s) => s.name == statusStr,
        orElse: () => MessageStatus.sent,
      ),
      edited: (row['edited'] as int? ?? 0) == 1,
      imagePath: row['image_path'] as String?,
      imageUrl: row['image_url'] as String?,
    );
  }

  /// Edit a text message the user sent (owner enforced by RLS). Sets edited=true.
  Future<void> editMessage(String messageId, String newText) async {
    await Supabase.instance.client
        .from('direct_messages')
        .update({'content': newText, 'edited': true})
        .eq('id', messageId)
        .timeout(const Duration(seconds: 8));
    await _db.updateMessageContent(messageId, newText);
  }

  /// Delete a message the user sent (owner enforced by RLS). Also removes its
  /// Storage image if it was an image message.
  Future<void> deleteMessage(String messageId, {String? imageUrl}) async {
    await Supabase.instance.client
        .from('direct_messages')
        .delete()
        .eq('id', messageId)
        .timeout(const Duration(seconds: 8));
    await _db.deleteMessageById(messageId);
    if (imageUrl != null && imageUrl.isNotEmpty) {
      await ImageUploadHelper.deleteByUrl(imageUrl, bucket: _kChatImageBucket);
    }
  }
}

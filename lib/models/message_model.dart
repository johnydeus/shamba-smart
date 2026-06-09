import '../features/messaging/domain/message_status.dart';
import '../models/user_model.dart';

// Types of messages that can be sent in a conversation
enum MessageType { text, image, location, file }

// A single chat message — supports text, image, location, and file
class MessageModel {
  final String id;
  final String senderId;
  final String text;           // used for text messages and captions
  final DateTime timestamp;
  final bool isFromMe;
  final bool isRead;
  final MessageType type;
  final MessageStatus status;

  // ── Image message fields ──────────────────────────────────────────────────
  final String? imagePath;     // local file path to the image

  // ── Location message fields ───────────────────────────────────────────────
  final double? locationLat;
  final double? locationLng;
  final String? locationName;  // human-readable label e.g. "Shamba langu"

  // ── File message fields ───────────────────────────────────────────────────
  final String? filePath;      // local file path
  final String? fileName;      // display name e.g. "Bei_za_mbegu.pdf"
  final String? fileType;      // "pdf" or "txt"
  final int? fileSize;         // bytes

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    required this.isFromMe,
    this.isRead = false,
    this.type = MessageType.text,
    this.status = MessageStatus.sent,
    this.imagePath,
    this.locationLat,
    this.locationLng,
    this.locationName,
    this.filePath,
    this.fileName,
    this.fileType,
    this.fileSize,
  });

  // Human-readable file size
  String get fileSizeLabel {
    if (fileSize == null) return '';
    if (fileSize! < 1024) return '${fileSize}B';
    if (fileSize! < 1024 * 1024) {
      return '${(fileSize! / 1024).toStringAsFixed(1)}KB';
    }
    return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  factory MessageModel.fromJson(Map<String, dynamic> j) => MessageModel(
        id: j['id'] as String,
        senderId: j['senderId'] as String,
        text: j['text'] as String? ?? '',
        timestamp: DateTime.parse(j['timestamp'] as String),
        isFromMe: j['isFromMe'] as bool,
        type: MessageType.values.firstWhere(
          (t) => t.name == (j['type'] as String? ?? 'text'),
          orElse: () => MessageType.text,
        ),
        status: MessageStatus.values.firstWhere(
          (s) => s.name == (j['status'] as String? ?? 'sent'),
          orElse: () => MessageStatus.sent,
        ),
        imagePath: j['imagePath'] as String?,
        locationLat: (j['locationLat'] as num?)?.toDouble(),
        locationLng: (j['locationLng'] as num?)?.toDouble(),
        locationName: j['locationName'] as String?,
        filePath: j['filePath'] as String?,
        fileName: j['fileName'] as String?,
        fileType: j['fileType'] as String?,
        fileSize: j['fileSize'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'senderId': senderId,
        'text': text,
        'timestamp': timestamp.toIso8601String(),
        'isFromMe': isFromMe,
        'type': type.name,
        'status': status.name,
        if (imagePath != null) 'imagePath': imagePath,
        if (locationLat != null) 'locationLat': locationLat,
        if (locationLng != null) 'locationLng': locationLng,
        if (locationName != null) 'locationName': locationName,
        if (filePath != null) 'filePath': filePath,
        if (fileName != null) 'fileName': fileName,
        if (fileType != null) 'fileType': fileType,
        if (fileSize != null) 'fileSize': fileSize,
      };
}

// A conversation thread with one contact
class ConversationModel {
  final String contactId;
  final String contactName;
  final UserRole contactRole;
  final String contactColorHex;
  List<MessageModel> messages;
  int unreadCount;

  ConversationModel({
    required this.contactId,
    required this.contactName,
    required this.contactRole,
    required this.contactColorHex,
    required this.messages,
    this.unreadCount = 0,
  });

  String get lastMessage {
    if (messages.isEmpty) return '';
    final last = messages.last;
    return switch (last.type) {
      MessageType.text     => last.text,
      MessageType.image    => '📷 Picha',
      MessageType.location => '📍 Eneo',
      MessageType.file     => '📄 ${last.fileName ?? 'Faili'}',
    };
  }

  DateTime? get lastMessageTime =>
      messages.isNotEmpty ? messages.last.timestamp : null;

  String get initials {
    final parts = contactName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return contactName.isNotEmpty ? contactName[0].toUpperCase() : '?';
  }

  factory ConversationModel.fromJson(Map<String, dynamic> j) =>
      ConversationModel(
        contactId: j['contactId'] as String,
        contactName: j['contactName'] as String,
        contactRole:
            UserRoleX.fromKey(j['contactRole'] as String),
        contactColorHex: j['contactColorHex'] as String,
        messages: (j['messages'] as List)
            .map((e) =>
                MessageModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        unreadCount: (j['unreadCount'] as int?) ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'contactId': contactId,
        'contactName': contactName,
        'contactRole': contactRole.key,
        'contactColorHex': contactColorHex,
        'messages': messages.map((m) => m.toJson()).toList(),
        'unreadCount': unreadCount,
      };
}

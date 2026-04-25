import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';

const _kMsgs = 'ss_msgs';

// Auto-replies in Kiswahili for each message type
const _textReplies = [
  'Asante kwa mawasiliano. Nitajibu hivi karibuni. 🙏',
  'Ndio, bidhaa bado ipo. Tunaweza kuzungumza zaidi. Bei inaweza kujadiliwa.',
  'Karibu sana! Tutafanya biashara nzuri pamoja. 📞',
  'Samahani kwa kuchelewa. Niko shambani sasa. Nitawasiliana nawe baadaye. 🌿',
  'Ndiyo, ninaweza kusaidia. Tuma nambari yako nikusisitize zaidi. ✅',
];

const _imageReplies = [
  'Picha nzuri! Asante kwa kutuma. 👍',
  'Nimeona picha yako. Bidhaa inaonekana nzuri sana! 😊',
  'Asante kwa picha. Nitatoa jibu hivi karibuni. 📷',
];

const _locationReplies = [
  'Asante kwa eneo lako. Nitafika hivi karibuni! 📍',
  'Nimepokea eneo. Niko karibu nawe, nitakuja saa 2. 🗺️',
  'Eneo limepokewa. Tunaweza kukutana kesho asubuhi? 📍',
];

const _fileReplies = [
  'Nimeipokea faili. Nitaisoma hivi karibuni. 📄',
  'Asante kwa faili. Nitakagua bei na kukujibu. 📋',
  'Faili imefika vizuri. Nitashiriki na timu yangu. ✅',
];

class ChatProvider extends ChangeNotifier {
  final Map<String, ConversationModel> _conversations = {};
  final _rand = Random();

  Map<String, ConversationModel> get conversations => _conversations;

  int get totalUnread =>
      _conversations.values.fold(0, (sum, c) => sum + c.unreadCount);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kMsgs);
    if (raw != null) {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      for (final entry in map.entries) {
        _conversations[entry.key] = ConversationModel.fromJson(
            entry.value as Map<String, dynamic>);
      }
    }
    if (_conversations.isEmpty) {
      _seedDemo();
      await _save();
    }
    notifyListeners();
  }

  ConversationModel getConversation(
    String contactId,
    String contactName,
    UserRole contactRole,
    String contactColorHex,
  ) {
    return _conversations.putIfAbsent(
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

  // ── Send methods ───────────────────────────────────────────────────────────

  Future<void> sendMessage({
    required String currentUserId,
    required String contactId,
    required String contactName,
    required UserRole contactRole,
    required String contactColorHex,
    required String text,
  }) async {
    await _addOutgoing(
      currentUserId: currentUserId,
      contactId: contactId,
      contactName: contactName,
      contactRole: contactRole,
      contactColorHex: contactColorHex,
      message: MessageModel(
        id: _newId(),
        senderId: currentUserId,
        text: text,
        timestamp: DateTime.now(),
        isFromMe: true,
        type: MessageType.text,
      ),
      replies: _textReplies,
    );
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
    await _addOutgoing(
      currentUserId: currentUserId,
      contactId: contactId,
      contactName: contactName,
      contactRole: contactRole,
      contactColorHex: contactColorHex,
      message: MessageModel(
        id: _newId(),
        senderId: currentUserId,
        text: caption,
        timestamp: DateTime.now(),
        isFromMe: true,
        type: MessageType.image,
        imagePath: imagePath,
      ),
      replies: _imageReplies,
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
    await _addOutgoing(
      currentUserId: currentUserId,
      contactId: contactId,
      contactName: contactName,
      contactRole: contactRole,
      contactColorHex: contactColorHex,
      message: MessageModel(
        id: _newId(),
        senderId: currentUserId,
        text: '',
        timestamp: DateTime.now(),
        isFromMe: true,
        type: MessageType.location,
        locationLat: lat,
        locationLng: lng,
        locationName: locationName,
      ),
      replies: _locationReplies,
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
    await _addOutgoing(
      currentUserId: currentUserId,
      contactId: contactId,
      contactName: contactName,
      contactRole: contactRole,
      contactColorHex: contactColorHex,
      message: MessageModel(
        id: _newId(),
        senderId: currentUserId,
        text: '',
        timestamp: DateTime.now(),
        isFromMe: true,
        type: MessageType.file,
        filePath: filePath,
        fileName: fileName,
        fileType: fileType,
        fileSize: fileSize,
      ),
      replies: _fileReplies,
    );
  }

  // ── Internal helpers ───────────────────────────────────────────────────────

  Future<void> _addOutgoing({
    required String currentUserId,
    required String contactId,
    required String contactName,
    required UserRole contactRole,
    required String contactColorHex,
    required MessageModel message,
    required List<String> replies,
  }) async {
    final conv = getConversation(
        contactId, contactName, contactRole, contactColorHex);
    conv.messages.add(message);
    await _save();
    notifyListeners();

    // Auto-reply after 1800ms
    Future.delayed(const Duration(milliseconds: 1800), () async {
      if (_conversations.containsKey(contactId)) {
        final reply = replies[_rand.nextInt(replies.length)];
        _conversations[contactId]!.messages.add(MessageModel(
          id: '${_newId()}_r',
          senderId: contactId,
          text: reply,
          timestamp: DateTime.now(),
          isFromMe: false,
          type: MessageType.text,
        ));
        _conversations[contactId]!.unreadCount++;
        await _save();
        notifyListeners();
      }
    });
  }

  Future<void> markRead(String contactId) async {
    if (_conversations.containsKey(contactId)) {
      _conversations[contactId]!.unreadCount = 0;
      await _save();
      notifyListeners();
    }
  }

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _kMsgs,
        jsonEncode(
            _conversations.map((k, v) => MapEntry(k, v.toJson()))));
  }

  // ── Demo seed data ─────────────────────────────────────────────────────────

  void _seedDemo() {
    final now = DateTime.now();

    _addDemoConv(
      contactId: 'seller_001',
      contactName: 'Amina Rashid',
      role: UserRole.mkulima,
      colorHex: '#2E7D32',
      messages: [
        _txt('seller_001', 'Habari! Bado una pilipili kali? 🌶️',
            now.subtract(const Duration(minutes: 45)), false),
        _txt('me', 'Ndio, tuna kilo 500 zinapatikana. Bei ni TZS 3,200/kg.',
            now.subtract(const Duration(minutes: 40)), true),
        _txt('seller_001',
            'Vizuri! Ninaweza kununua kilo 100. Unitumie eneo la shamba.',
            now.subtract(const Duration(minutes: 35)), false),
      ],
    );

    _addDemoConv(
      contactId: 'seller_002',
      contactName: 'AgriPlus Morogoro',
      role: UserRole.duka,
      colorHex: '#1565C0',
      messages: [
        _txt('me', 'Mnazo Coragen SC 500ml? Ninahitaji haraka kwa viwavi.',
            now.subtract(const Duration(hours: 3)), true),
        _txt('seller_002',
            'Ndio tuna! TZS 18,500 kwa chupa. Nitumie PDF ya bei zetu zote.',
            now.subtract(const Duration(hours: 2, minutes: 55)), false),
      ],
    );

    _addDemoConv(
      contactId: 'seller_004',
      contactName: 'Musa Komba',
      role: UserRole.mwekezaji,
      colorHex: '#C8860A',
      messages: [
        _txt('seller_004',
            'Habari! Shamba la ekari 10 Chalinze linapatikana.',
            now.subtract(const Duration(days: 1, hours: 2)), false),
        _txt('me', 'Ndiyo, nina nia. Piga picha ya shamba unitumie.',
            now.subtract(const Duration(days: 1, hours: 1)), true),
        _txt('seller_004', 'Sawa! Nitatuma picha na eneo sasa hivi.',
            now.subtract(const Duration(days: 1)), false),
      ],
    );

    _addDemoConv(
      contactId: 'seller_005',
      contactName: 'Hassan Ikungi Farm',
      role: UserRole.mkulima,
      colorHex: '#2E7D32',
      messages: [
        _txt('me',
            'Vitunguu vyako vya Singida — naweza kununua tani 10?',
            now.subtract(const Duration(days: 2)), true),
        _txt('seller_005',
            'Ndiyo! Tuna tani 15. Nitumie faili ya bei na masharti.',
            now.subtract(const Duration(days: 1, hours: 23)), false),
      ],
    );

    _addDemoConv(
      contactId: 'seller_007',
      contactName: 'Mbogamboga Logistics',
      role: UserRole.muuzaji,
      colorHex: '#6A1B9A',
      messages: [
        _txt('me', 'Mnatoa usafiri DSM hadi Morogoro?',
            now.subtract(const Duration(days: 3)), true),
        _txt('seller_007',
            'Ndio! TZS 120,000 kwa safari. Tutumiane eneo la kupakia mazao.',
            now.subtract(const Duration(days: 2, hours: 22)), false),
      ],
    );
  }

  void _addDemoConv({
    required String contactId,
    required String contactName,
    required UserRole role,
    required String colorHex,
    required List<MessageModel> messages,
  }) {
    final unread = messages.where((m) => !m.isFromMe).length;
    _conversations[contactId] = ConversationModel(
      contactId: contactId,
      contactName: contactName,
      contactRole: role,
      contactColorHex: colorHex,
      messages: messages,
      unreadCount: unread > 1 ? 1 : 0,
    );
  }

  MessageModel _txt(String sender, String text, DateTime time, bool fromMe) =>
      MessageModel(
        id: '${time.millisecondsSinceEpoch}_$sender',
        senderId: sender,
        text: text,
        timestamp: time,
        isFromMe: fromMe,
        type: MessageType.text,
      );
}

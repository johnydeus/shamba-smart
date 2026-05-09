import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/common_widgets.dart';

// ── Helpers ────────────────────────────────────────────────────────────────────

String _bubbleTime(DateTime dt) =>
    '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

Color _hexColor(String hex) {
  final h = hex.replaceFirst('#', '');
  return Color(int.parse('FF$h', radix: 16));
}

// ── ChatScreen ─────────────────────────────────────────────────────────────────

class ChatScreen extends StatefulWidget {
  final String contactId;
  final String contactName;
  final UserRole contactRole;
  final String contactColorHex;
  final String? initialMessage;

  const ChatScreen({
    super.key,
    required this.contactId,
    required this.contactName,
    required this.contactRole,
    required this.contactColorHex,
    this.initialMessage,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _textCtrl   = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _picker     = ImagePicker();
  bool _sending     = false;
  bool _loadingInit = true;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    // Load messages immediately when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final chat = context.read<ChatProvider>();
      try {
        await chat.loadMessages();
      } catch (_) {}
      if (!mounted) return;
      chat.markRead(widget.contactId);
      setState(() => _loadingInit = false);
      if (widget.initialMessage != null && widget.initialMessage!.isNotEmpty) {
        _textCtrl.text = widget.initialMessage!;
      }
      _scrollToBottom();
    });

    // Poll every 3 seconds as backup (Realtime is primary)
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (!mounted) return;
      final chat = context.read<ChatProvider>();
      if (!chat.isReady) return;
      final prevCount =
          chat.conversations[widget.contactId]?.messages.length ?? 0;
      try {
        await chat.loadMessages();
      } catch (_) {}
      if (!mounted) return;
      final newCount =
          chat.conversations[widget.contactId]?.messages.length ?? 0;
      if (newCount > prevCount) _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Send text ────────────────────────────────────────────────────────────────

  Future<void> _sendText() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    _textCtrl.clear();
    setState(() => _sending = true);

    try {
      final user = context.read<AuthProvider>().currentUser!;
      await context.read<ChatProvider>().sendMessage(
            currentUserId: user.id,
            contactId: widget.contactId,
            contactName: widget.contactName,
            contactRole: widget.contactRole,
            contactColorHex: widget.contactColorHex,
            text: text,
          );
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Imeshindwa kutuma: ${e.toString()}'),
          backgroundColor: Colors.red.shade700,
          action: SnackBarAction(
            label: 'Jaribu Tena',
            textColor: Colors.white,
            onPressed: () {
              _textCtrl.text = text;
              _sendText();
            },
          ),
        ));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  // ── Send image ───────────────────────────────────────────────────────────────

  Future<void> _sendImage(ImageSource source) async {
    Navigator.pop(context); // close attachment sheet
    final XFile? photo = await _picker.pickImage(
        source: source, imageQuality: 80);
    if (photo == null) return;

    if (!mounted) return;
    setState(() => _sending = true);
    final chat = context.read<ChatProvider>();
    final userId = context.read<AuthProvider>().currentUser!.id;
    await chat.sendImage(
          currentUserId: userId,
          contactId: widget.contactId,
          contactName: widget.contactName,
          contactRole: widget.contactRole,
          contactColorHex: widget.contactColorHex,
          imagePath: photo.path,
        );
    setState(() => _sending = false);
    _scheduleScrollAfterReply();
  }

  // ── Send location ────────────────────────────────────────────────────────────

  Future<void> _sendLocation() async {
    Navigator.pop(context); // close attachment sheet

    // Show loading snackbar
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('📍 Inapata GPS...'),
            duration: Duration(seconds: 2)),
      );
    }

    try {
      bool enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        _showError('GPS imezimwa. Washa GPS kwenye simu yako.');
        return;
      }
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        _showError('Ruhusa ya GPS ilikataliwa.');
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      if (!mounted) return;
      setState(() => _sending = true);
      final locChat = context.read<ChatProvider>();
      final locUserId = context.read<AuthProvider>().currentUser!.id;
      await locChat.sendLocation(
            currentUserId: locUserId,
            contactId: widget.contactId,
            contactName: widget.contactName,
            contactRole: widget.contactRole,
            contactColorHex: widget.contactColorHex,
            lat: pos.latitude,
            lng: pos.longitude,
            locationName: 'Eneo langu sasa hivi',
          );
      setState(() => _sending = false);
      _scheduleScrollAfterReply();
    } catch (e) {
      _showError('Hitilafu ya GPS: ${e.toString()}');
    }
  }

  // ── Send file ────────────────────────────────────────────────────────────────

  Future<void> _sendFile() async {
    Navigator.pop(context); // close attachment sheet

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt'],
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    if (file.path == null) return;

    if (!mounted) return;
    setState(() => _sending = true);
    final fileChat = context.read<ChatProvider>();
    final fileUserId = context.read<AuthProvider>().currentUser!.id;
    await fileChat.sendFile(
          currentUserId: fileUserId,
          contactId: widget.contactId,
          contactName: widget.contactName,
          contactRole: widget.contactRole,
          contactColorHex: widget.contactColorHex,
          filePath: file.path!,
          fileName: file.name,
          fileType: file.extension ?? 'txt',
          fileSize: file.size,
        );
    setState(() => _sending = false);
    _scheduleScrollAfterReply();
  }

  void _scheduleScrollAfterReply() {
    _scrollToBottom();
    Future.delayed(
        const Duration(milliseconds: 2100), _scrollToBottom);
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(msg),
            backgroundColor: Colors.red.shade700),
      );
    }
  }

  // ── Attachment bottom sheet ───────────────────────────────────────────────────

  void _openAttachmentSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.mid.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text('Tuma Faili au Eneo',
                style: GoogleFonts.playfairDisplay(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.soil)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _AttachBtn(
                  emoji: '📷',
                  label: 'Camera',
                  color: AppColors.harvest,
                  onTap: () => _sendImage(ImageSource.camera),
                ),
                _AttachBtn(
                  emoji: '🖼️',
                  label: 'Picha Zilizopo',
                  color: const Color(0xFF0277BD),
                  onTap: () => _sendImage(ImageSource.gallery),
                ),
                _AttachBtn(
                  emoji: '📍',
                  label: 'Eneo (GPS)',
                  color: AppColors.leaf,
                  onTap: _sendLocation,
                ),
                _AttachBtn(
                  emoji: '📄',
                  label: 'PDF / TXT',
                  color: const Color(0xFF6A1B9A),
                  onTap: _sendFile,
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatProv = context.watch<ChatProvider>();
    final contactColor = _hexColor(widget.contactColorHex);

    // Use direct map lookup — never use getConversation() in build
    // (getConversation uses putIfAbsent which modifies state during build)
    final conv = chatProv.conversations[widget.contactId];
    final messages = conv?.messages ?? const [];

    return Scaffold(
      backgroundColor: AppColors.mist,
      appBar: AppBar(
        leadingWidth: 40,
        title: Row(
          children: [
            UserAvatarCircle(
                name: widget.contactName,
                role: widget.contactRole,
                size: 36),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.contactName,
                      style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                      overflow: TextOverflow.ellipsis),
                  Text(
                    chatProv.isReady
                        ? widget.contactRole.label
                        : 'Inaunganika...',
                    style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: chatProv.isReady
                            ? Colors.white60
                            : Colors.orange),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Onyesha upya',
            onPressed: () async {
              try {
                await chatProv.loadMessages();
                _scrollToBottom();
              } catch (e) {
                if (mounted) _showError('Hitilafu: ${e.toString()}');
              }
            },
          ),
        ],
      ),

      body: Column(
        children: [
          // ── Not-connected warning ──────────────────────────────────────────
          if (!chatProv.isReady)
            Container(
              width: double.infinity,
              color: Colors.orange,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Hujaunganika. Funga app na uifungue tena.',
                      style: GoogleFonts.dmSans(
                          color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

          // ── Messages list ──────────────────────────────────────────────────
          Expanded(
            child: _loadingInit
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: AppColors.leaf),
                        SizedBox(height: 12),
                        Text('Inapakia mazungumzo...',
                            style: TextStyle(color: AppColors.mid)),
                      ],
                    ),
                  )
                : messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('👋', style: TextStyle(fontSize: 40)),
                            const SizedBox(height: 10),
                            Text(
                              'Anza mazungumzo na\n${widget.contactName.split(' ').first}!',
                              style: GoogleFonts.dmSans(
                                  color: AppColors.mid, fontSize: 14),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    itemCount: messages.length,
                    itemBuilder: (ctx, i) {
                      final msg = messages[i];
                      final showAvatar = i == 0 ||
                          messages[i - 1].isFromMe != msg.isFromMe;
                      return _MessageBubble(
                        message: msg,
                        showAvatar: showAvatar,
                        contactName: widget.contactName,
                        contactRole: widget.contactRole,
                        contactColor: contactColor,
                      );
                    },
                  ),
          ),

          // Typing indicator
          if (_sending)
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  UserAvatarCircle(
                      name: widget.contactName,
                      role: widget.contactRole,
                      size: 24),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _Dot(delay: 0),
                        const SizedBox(width: 4),
                        _Dot(delay: 200),
                        const SizedBox(width: 4),
                        _Dot(delay: 400),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // ── Input bar ──────────────────────────────────────────────────────
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.cream,
              border: Border(
                  top: BorderSide(
                      color: AppColors.mid.withValues(alpha: 0.15))),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  // Attachment button
                  IconButton(
                    icon: const Icon(Icons.attach_file_rounded,
                        color: AppColors.harvest),
                    onPressed: _openAttachmentSheet,
                    tooltip: 'Picha / Eneo / Faili',
                  ),

                  // Text field
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.mist,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                            color: AppColors.mid.withValues(alpha: 0.2)),
                      ),
                      child: TextField(
                        controller: _textCtrl,
                        maxLines: 4,
                        minLines: 1,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendText(),
                        style: GoogleFonts.dmSans(
                            fontSize: 14, color: AppColors.ink),
                        decoration: InputDecoration(
                          hintText: 'Andika ujumbe...',
                          hintStyle: GoogleFonts.dmSans(
                              color: AppColors.mid, fontSize: 14),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Send button
                  GestureDetector(
                    onTap: _sending ? null : _sendText,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: AppColors.harvest,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send_rounded,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Message bubble — renders all 4 types ──────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool showAvatar;
  final String contactName;
  final UserRole contactRole;
  final Color contactColor;

  const _MessageBubble({
    required this.message,
    required this.showAvatar,
    required this.contactName,
    required this.contactRole,
    required this.contactColor,
  });

  @override
  Widget build(BuildContext context) {
    final sent = message.isFromMe;

    return Padding(
      padding: EdgeInsets.only(top: showAvatar ? 10 : 3, bottom: 2),
      child: Row(
        mainAxisAlignment:
            sent ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Received: show avatar
          if (!sent)
            Padding(
              padding: const EdgeInsets.only(right: 6, bottom: 2),
              child: CircleAvatar(
                radius: 14,
                backgroundColor: contactColor,
                child: Text(contactName[0].toUpperCase(),
                    style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
            ),

          Column(
            crossAxisAlignment:
                sent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              // Route to correct bubble type
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth:
                      MediaQuery.of(context).size.width * 0.72,
                ),
                child: switch (message.type) {
                  MessageType.image    => _ImageBubble(message: message, sent: sent),
                  MessageType.location => _LocationBubble(message: message, sent: sent),
                  MessageType.file     => _FileBubble(message: message, sent: sent),
                  MessageType.text     => _TextBubble(message: message, sent: sent),
                },
              ),
              const SizedBox(height: 3),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_bubbleTime(message.timestamp),
                      style: GoogleFonts.dmSans(
                          fontSize: 10, color: AppColors.mid)),
                  if (sent) ...[
                    const SizedBox(width: 4),
                    Icon(
                      message.isRead
                          ? Icons.done_all_rounded
                          : Icons.done_rounded,
                      size: 14,
                      color: message.isRead
                          ? const Color(0xFF1976D2)
                          : AppColors.mid,
                    ),
                  ],
                ],
              ),
            ],
          ),

          if (sent) const SizedBox(width: 4),
        ],
      ),
    );
  }
}

// ── Text bubble ────────────────────────────────────────────────────────────────

class _TextBubble extends StatelessWidget {
  final MessageModel message;
  final bool sent;
  const _TextBubble({required this.message, required this.sent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: sent ? AppColors.harvest : Colors.white,
        borderRadius: sent
            ? const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(4),
              )
            : const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
        boxShadow: [
          BoxShadow(
              color: AppColors.soil.withValues(alpha: 0.06),
              blurRadius: 4),
        ],
      ),
      child: Text(message.text,
          style: GoogleFonts.dmSans(
              fontSize: 14,
              color: sent ? Colors.white : AppColors.ink,
              height: 1.4)),
    );
  }
}

// ── Image bubble ───────────────────────────────────────────────────────────────

class _ImageBubble extends StatelessWidget {
  final MessageModel message;
  final bool sent;
  const _ImageBubble({required this.message, required this.sent});

  @override
  Widget build(BuildContext context) {
    final file = File(message.imagePath ?? '');
    final exists = file.existsSync();

    return GestureDetector(
      onTap: exists
          ? () => _showFullImage(context, file)
          : null,
      child: Container(
        decoration: BoxDecoration(
          color: sent ? AppColors.harvest : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: AppColors.soil.withValues(alpha: 0.08),
                blurRadius: 6),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14)),
              child: exists
                  ? Image.file(file,
                      width: 220,
                      height: 180,
                      fit: BoxFit.cover)
                  : Container(
                      width: 220,
                      height: 140,
                      color: AppColors.mist,
                      child: const Center(
                        child: Icon(Icons.broken_image_outlined,
                            color: AppColors.mid, size: 40),
                      ),
                    ),
            ),
            if (message.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
                child: Text(message.text,
                    style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: sent ? Colors.white : AppColors.ink)),
              )
            else
              const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  void _showFullImage(BuildContext ctx, File file) {
    Navigator.push(
      ctx,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: const Text('Picha'),
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.file(file, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Location bubble ────────────────────────────────────────────────────────────

class _LocationBubble extends StatelessWidget {
  final MessageModel message;
  final bool sent;
  const _LocationBubble({required this.message, required this.sent});

  Future<void> _openMaps() async {
    final lat = message.locationLat;
    final lng = message.locationLng;
    if (lat == null || lng == null) return;

    final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lat = message.locationLat;
    final lng = message.locationLng;

    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: sent ? AppColors.harvest : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: AppColors.soil.withValues(alpha: 0.08),
              blurRadius: 6),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Map preview (static colour block with pin)
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(14)),
            child: Container(
              height: 100,
              width: double.infinity,
              color: const Color(0xFFE3F2FD),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Grid lines to mimic a map
                  CustomPaint(
                    size: const Size(220, 100),
                    painter: _MapGridPainter(),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_on,
                          color: Colors.red, size: 36),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black12, blurRadius: 4)
                          ],
                        ),
                        child: Text(
                          message.locationName ?? 'Eneo',
                          style: GoogleFonts.dmSans(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.soil),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message.locationName ?? 'Eneo Linaloshirikiwa',
                    style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: sent ? Colors.white : AppColors.ink)),
                if (lat != null && lng != null)
                  Text(
                    '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
                    style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: sent
                            ? Colors.white70
                            : AppColors.mid),
                  ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _openMaps,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1976D2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.map_outlined,
                            color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text('Fungua Ramani',
                            style: GoogleFonts.dmSans(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── File bubble ────────────────────────────────────────────────────────────────

class _FileBubble extends StatelessWidget {
  final MessageModel message;
  final bool sent;
  const _FileBubble({required this.message, required this.sent});

  IconData get _fileIcon => switch (message.fileType?.toLowerCase()) {
        'pdf' => Icons.picture_as_pdf_outlined,
        'txt' => Icons.description_outlined,
        _     => Icons.insert_drive_file_outlined,
      };

  Color get _fileColor => switch (message.fileType?.toLowerCase()) {
        'pdf' => const Color(0xFFB71C1C),
        'txt' => const Color(0xFF1565C0),
        _     => AppColors.mid,
      };

  Future<void> _openFile() async {
    if (message.filePath == null) return;
    await OpenFilex.open(message.filePath!);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openFile,
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: sent ? AppColors.harvest : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: AppColors.soil.withValues(alpha: 0.08),
                blurRadius: 6),
          ],
        ),
        child: Row(
          children: [
            // File type icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _fileColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_fileIcon, color: _fileColor, size: 24),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.fileName ?? 'Faili',
                    style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: sent ? Colors.white : AppColors.ink),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${message.fileType?.toUpperCase() ?? 'FILE'}  •  ${message.fileSizeLabel}',
                    style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: sent
                            ? Colors.white70
                            : AppColors.mid),
                  ),
                ],
              ),
            ),
            Icon(Icons.download_outlined,
                color: sent ? Colors.white70 : AppColors.mid,
                size: 18),
          ],
        ),
      ),
    );
  }
}

// ── Attachment option button ───────────────────────────────────────────────────

class _AttachBtn extends StatelessWidget {
  final String emoji;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AttachBtn({
    required this.emoji,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                  color: color.withValues(alpha: 0.3), width: 1.5),
            ),
            child: Center(
              child:
                  Text(emoji, style: const TextStyle(fontSize: 26)),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 70,
            child: Text(label,
                style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: AppColors.mid,
                    fontWeight: FontWeight.w600),
                textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }
}

// ── Map grid painter (static map-like background) ─────────────────────────────

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFBBDEFB)
      ..strokeWidth = 0.8;

    const step = 20.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Draw a fake road
    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4;
    canvas.drawLine(
        const Offset(0, 60), Offset(size.width, 40), roadPaint);
    canvas.drawLine(
        const Offset(100, 0), const Offset(120, 100), roadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Animated typing dot ────────────────────────────────────────────────────────

class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    Future.delayed(
        Duration(milliseconds: widget.delay),
        () => _ctrl.repeat(reverse: true));
    _anim = Tween(begin: 0.3, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _anim,
        child: Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
              color: AppColors.mid, shape: BoxShape.circle),
        ),
      );
}

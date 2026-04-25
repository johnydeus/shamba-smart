import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/message_model.dart';
import '../providers/chat_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/common_widgets.dart';
import 'chat_screen.dart';

// Helper: format timestamp for conversation list
String _fmtTime(DateTime? dt) {
  if (dt == null) return '';
  final now = DateTime.now();
  final diff = now.difference(dt);
  if (diff.inDays == 0) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  } else if (diff.inDays == 1) {
    return 'Jana';
  } else if (diff.inDays < 7) {
    const days = ['Ju', 'Jt', 'Jn', 'Jt', 'Al', 'Ij', 'Jm'];
    return days[dt.weekday % 7];
  }
  return '${dt.day}/${dt.month}';
}

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final chatProv = context.watch<ChatProvider>();
    final convList = chatProv.conversations.values.toList()
      ..sort((a, b) {
        final ta = a.lastMessageTime ?? DateTime(2000);
        final tb = b.lastMessageTime ?? DateTime(2000);
        return tb.compareTo(ta); // newest first
      });

    return Scaffold(
      backgroundColor: AppColors.mist,
      appBar: AppBar(
        title: Text(
          'Mazungumzo',
          style: GoogleFonts.playfairDisplay(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: convList.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('💬', style: TextStyle(fontSize: 56)),
                  const SizedBox(height: 12),
                  Text(
                    'Hujafanya mazungumzo bado.',
                    style: GoogleFonts.dmSans(
                        color: AppColors.mid, fontSize: 15),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Bonyeza "Ongea" kwenye orodha yoyote katika Soko.',
                    style: GoogleFonts.dmSans(
                        color: AppColors.mid, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: convList.length,
              separatorBuilder: (context, idx) =>
                  Divider(height: 1, color: AppColors.mid.withValues(alpha: 0.1)),
              itemBuilder: (context, i) {
                final conv = convList[i];
                return _ConversationTile(
                  conversation: conv,
                  onTap: () {
                    chatProv.markRead(conv.contactId);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          contactId: conv.contactId,
                          contactName: conv.contactName,
                          contactRole: conv.contactRole,
                          contactColorHex: conv.contactColorHex,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final ConversationModel conversation;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.conversation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasUnread = conversation.unreadCount > 0;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar
            UserAvatarCircle(
              name: conversation.contactName,
              role: conversation.contactRole,
              size: 50,
            ),
            const SizedBox(width: 12),

            // Name + last message
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.contactName,
                          style: GoogleFonts.dmSans(
                            fontWeight: hasUnread
                                ? FontWeight.bold
                                : FontWeight.w600,
                            fontSize: 14,
                            color: AppColors.ink,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _fmtTime(conversation.lastMessageTime),
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: hasUnread
                              ? AppColors.harvest
                              : AppColors.mid,
                          fontWeight: hasUnread
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      RoleChip(conversation.contactRole,
                          fontSize: 9),
                      const SizedBox(width: 6),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.lastMessage,
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: hasUnread
                                ? AppColors.ink
                                : AppColors.mid,
                            fontWeight: hasUnread
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Unread badge
                      if (hasUnread)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.harvest,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${conversation.unreadCount}',
                            style: GoogleFonts.dmSans(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

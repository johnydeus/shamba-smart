import "dart:async";
import "dart:io";
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/community_post.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/community_provider.dart';
import '../services/privacy_service.dart';
import '../theme/app_colors.dart';
import '../widgets/common_widgets.dart';
import 'chat_screen.dart';
import 'expert_profile_screen.dart';

// ── Time helpers ──────────────────────────────────────────────────────────────

String _fmtTime(DateTime? dt) {
  if (dt == null) return '';
  final now = DateTime.now();
  final diff = now.difference(dt);
  if (diff.inMinutes < 1) return 'Sasa hivi';
  if (diff.inMinutes < 60) return '${diff.inMinutes}dk';
  if (diff.inDays == 0) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
  if (diff.inDays == 1) return 'Jana';
  if (diff.inDays < 7) {
    const d = ['Ju', 'Jt', 'Jn', 'Jt', 'Al', 'Ij', 'Jm'];
    return d[dt.weekday % 7];
  }
  return '${dt.day}/${dt.month}';
}

// (No demo directory — all users come from Supabase farmers table)

// ── MessagesScreen (Social Hub) ───────────────────────────────────────────────

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _topicFilter = 'zote';
  String _roleFilter = 'zote';
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    // Poll for new messages and unread badge while MessagesScreen is open
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) context.read<ChatProvider>().loadMessages();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    final totalUnread = chat.totalUnread;

    return Scaffold(
      backgroundColor: AppColors.mist,
      // Resize when the keyboard opens so inline inputs (post replies, the
      // "Watu" search box) lift above it instead of being hidden behind it.
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text('Mawasiliano',
            style: GoogleFonts.playfairDisplay(
                color: Colors.white, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.chat_bubble_outline, size: 15),
                  const SizedBox(width: 5),
                  const Text('Mazungumzo', style: TextStyle(fontSize: 12)),
                  if (totalUnread > 0) ...[
                    const SizedBox(width: 4),
                    _badge('$totalUnread', AppColors.harvest),
                  ],
                ],
              ),
            ),
            const Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.people, size: 15),
                  SizedBox(width: 5),
                  Text('Jamii', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
            const Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_search, size: 15),
                  SizedBox(width: 5),
                  Text('Watu', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _ChatTab(),
          _CommunityTab(
            topicFilter: _topicFilter,
            onTopicChanged: (t) => setState(() => _topicFilter = t),
          ),
          _DirectoryTab(
            roleFilter: _roleFilter,
            onRoleChanged: (r) => setState(() => _roleFilter = r),
            searchCtrl: _searchCtrl,
            searchQuery: _searchQuery,
            onSearchChanged: (q) => setState(() => _searchQuery = q),
          ),
        ],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabCtrl,
        builder: (context, _) {
          if (_tabCtrl.index != 1) return const SizedBox.shrink();
          final user = context.read<AuthProvider>().currentUser;
          if (user == null) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            backgroundColor: AppColors.leaf,
            icon: const Icon(Icons.add_photo_alternate_rounded,
                color: Colors.white),
            label: const Text('Andika / Picha',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            onPressed: () => _showPostSheet(context, user),
          );
        },
      ),
    );
  }

  Widget _badge(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration:
            BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
        child: Text(text,
            style: const TextStyle(
                fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
      );
}

// ── Tab 1: Private chats ──────────────────────────────────────────────────────

class _ChatTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final chatProv = context.watch<ChatProvider>();
    final convList = chatProv.conversations.values.toList()
      ..sort((a, b) {
        final ta = a.lastMessageTime ?? DateTime(2000);
        final tb = b.lastMessageTime ?? DateTime(2000);
        return tb.compareTo(ta);
      });

    if (convList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('💬', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 12),
              Text('Hujafanya mazungumzo bado.',
                  style: GoogleFonts.dmSans(color: AppColors.mid, fontSize: 15)),
              const SizedBox(height: 6),
              Text(
                'Nenda kwenye kichupo "Watu" uchague mtu na uanze mazungumzo.',
                style: GoogleFonts.dmSans(color: AppColors.mid, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: convList.length,
      separatorBuilder: (context, _) =>
          Divider(height: 1, color: AppColors.mid.withValues(alpha: 0.1)),
      itemBuilder: (context, i) {
        final conv = convList[i];
        final hasUnread = conv.unreadCount > 0;
        return InkWell(
          onTap: () {
            chatProv.markRead(conv.contactId);
            Navigator.push(context,
                MaterialPageRoute(
                    builder: (_) => ChatScreen(
                          contactId: conv.contactId,
                          contactName: conv.contactName,
                          contactRole: conv.contactRole,
                          contactColorHex: conv.contactColorHex,
                        )));
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                UserAvatarCircle(
                    name: conv.contactName, role: conv.contactRole, size: 50),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(conv.contactName,
                                style: GoogleFonts.dmSans(
                                    fontWeight: hasUnread
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                    fontSize: 14,
                                    color: AppColors.ink),
                                overflow: TextOverflow.ellipsis),
                          ),
                          Text(_fmtTime(conv.lastMessageTime),
                              style: GoogleFonts.dmSans(
                                  fontSize: 11,
                                  color: hasUnread
                                      ? AppColors.harvest
                                      : AppColors.mid,
                                  fontWeight: hasUnread
                                      ? FontWeight.bold
                                      : FontWeight.normal)),
                        ],
                      ),
                      const SizedBox(height: 3),
                      RoleChip(conv.contactRole, fontSize: 9),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Expanded(
                            child: Text(conv.lastMessage,
                                style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    color: hasUnread ? AppColors.ink : AppColors.mid,
                                    fontWeight: hasUnread
                                        ? FontWeight.w500
                                        : FontWeight.normal),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                          if (hasUnread)
                            Container(
                              margin: const EdgeInsets.only(left: 6),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                  color: AppColors.harvest,
                                  borderRadius: BorderRadius.circular(10)),
                              child: Text('${conv.unreadCount}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold)),
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
      },
    );
  }
}

// ── Tab 2: Community feed ─────────────────────────────────────────────────────

class _CommunityTab extends StatelessWidget {
  final String topicFilter;
  final ValueChanged<String> onTopicChanged;

  const _CommunityTab(
      {required this.topicFilter, required this.onTopicChanged});

  @override
  Widget build(BuildContext context) {
    final community = context.watch<CommunityProvider>();
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    final filtered = topicFilter == 'zote'
        ? community.posts
        : community.posts.where((p) => p.topic == topicFilter).toList();

    return Column(
      children: [
        // Topic filter chips
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: PostTopic.all.map((t) {
              final isSelected = topicFilter == t['key'];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text('${t['emoji']} ${t['label']}',
                      style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? Colors.white : AppColors.soil)),
                  selected: isSelected,
                  onSelected: (_) => onTopicChanged(t['key']!),
                  selectedColor: AppColors.leaf,
                  backgroundColor: Colors.white,
                ),
              );
            }).toList(),
          ),
        ),

        // Post list
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => context.read<CommunityProvider>().loadPosts(),
            color: AppColors.leaf,
            child: filtered.isEmpty
                ? ListView(
                    children: [
                      SizedBox(
                        height: 300,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('📭', style: TextStyle(fontSize: 48)),
                              const SizedBox(height: 12),
                              Text('Hakuna machapisho bado.',
                                  style: GoogleFonts.dmSans(color: AppColors.mid)),
                              const SizedBox(height: 8),
                              if (user != null)
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.add),
                                  label: const Text('Chapisho la Kwanza'),
                                  onPressed: () =>
                                      _showPostSheet(context, user),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
                    itemCount: filtered.length,
                    separatorBuilder: (context, _) => const SizedBox(height: 12),
                    itemBuilder: (context, i) => _PostCard(post: filtered[i]),
                  ),
          ),
        ),
      ],
    );
  }
}

// ── Post card ─────────────────────────────────────────────────────────────────

class _PostCard extends StatefulWidget {
  final CommunityPost post;
  const _PostCard({required this.post});

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  bool _showReplies = false;
  final _replyCtrl = TextEditingController();

  @override
  void dispose() {
    _replyCtrl.dispose();
    super.dispose();
  }

  void _showFullImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 4.0,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                placeholder: (_, _) => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                errorWidget: (_, _, _) => const Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white54,
                    size: 64),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final community = context.watch<CommunityProvider>();
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final post = widget.post;
    final roleColor = AppColors.roleColor(post.role);
    final isLiked = user != null && post.isLikedBy(user.id);

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: roleColor.withValues(alpha: 0.15),
                  child: Text(
                    post.authorName.isNotEmpty ? post.authorName[0].toUpperCase() : '?',
                    style: TextStyle(
                        color: roleColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.authorName,
                          style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppColors.soil)),
                      Row(
                        children: [
                          RoleChip(post.role, fontSize: 9),
                          const SizedBox(width: 6),
                          const Icon(Icons.location_on,
                              size: 10, color: Colors.grey),
                          Text(post.authorRegion,
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ),
                // Topic badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.mint,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${PostTopic.emoji(post.topic)} ${PostTopic.label(post.topic)}',
                    style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.leaf,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Content ───────────────────────────────────────────
            if (post.content != '📷')
              Text(post.content,
                  style: GoogleFonts.dmSans(
                      fontSize: 13.5,
                      color: AppColors.soil,
                      height: 1.45)),

            // ── Image ─────────────────────────────────────────────
            if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ...[
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => _showFullImage(context, post.imageUrl!),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: post.imageUrl!,
                    width: double.infinity,
                    height: 220,
                    fit: BoxFit.cover,
                    placeholder: (ctx, _) => Container(
                      height: 220,
                      color: AppColors.mint,
                      child: const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.leaf)),
                    ),
                    errorWidget: (ctx, _, __) => Container(
                      height: 100,
                      color: AppColors.mint,
                      child: const Center(
                          child: Icon(Icons.broken_image,
                              color: Colors.grey, size: 40)),
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 6),
            Text(_fmtTime(post.createdAt),
                style: const TextStyle(fontSize: 11, color: Colors.grey)),

            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // ── Action bar ────────────────────────────────────────
            Row(
              children: [
                // Like button
                InkWell(
                  onTap: user == null
                      ? null
                      : () => community.toggleLike(post.id, user.id),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          isLiked
                              ? Icons.thumb_up
                              : Icons.thumb_up_outlined,
                          size: 16,
                          color: isLiked
                              ? AppColors.leaf
                              : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text('${post.likedByIds.length}',
                            style: TextStyle(
                                fontSize: 12,
                                color: isLiked ? AppColors.leaf : Colors.grey,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Reply button
                InkWell(
                  onTap: () => setState(() => _showReplies = !_showReplies),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.chat_bubble_outline,
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                            '${post.replies.length} ${post.replies.length == 1 ? 'jibu' : 'majibu'}',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // Direct message button
                if (user != null && post.authorId != user.id)
                  TextButton.icon(
                    onPressed: () async {
                      final canMsg =
                          await PrivacyService.canSendMessage(
                        senderId: user.id,
                        recipientId: post.authorId,
                        senderIsOfficer:
                            user.role == UserRole.afisa,
                      );
                      if (!context.mounted) return;
                      if (!canMsg) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Mtu huyu haukuruhusu kupokea ujumbe.')));
                        return;
                      }
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                    contactId: post.authorId,
                                    contactName: post.authorName,
                                    contactRole: post.role,
                                    contactColorHex: post.role.colorHex,
                                  )));
                    },
                    icon: const Icon(Icons.send, size: 14),
                    label: const Text('Wasiliana',
                        style: TextStyle(fontSize: 11)),
                    style: TextButton.styleFrom(
                      foregroundColor: roleColor,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
              ],
            ),

            // ── Replies ───────────────────────────────────────────
            if (_showReplies) ...[
              const SizedBox(height: 10),
              ...post.replies.map((r) => _ReplyTile(reply: r)),
              const SizedBox(height: 8),
              if (user != null) _ReplyInput(post: post, replyCtrl: _replyCtrl),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReplyTile extends StatelessWidget {
  final CommunityReply reply;
  const _ReplyTile({required this.reply});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.roleColor(reply.role);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.mint.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: color.withValues(alpha: 0.15),
            child: Text(
              reply.authorName.isNotEmpty ? reply.authorName[0].toUpperCase() : '?',
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(reply.authorName,
                        style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: AppColors.soil)),
                    const SizedBox(width: 6),
                    RoleChip(reply.role, fontSize: 8),
                    const Spacer(),
                    Text(_fmtTime(reply.createdAt),
                        style: const TextStyle(
                            fontSize: 10, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 3),
                Text(reply.content,
                    style: GoogleFonts.dmSans(
                        fontSize: 12, color: AppColors.soil)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReplyInput extends StatelessWidget {
  final CommunityPost post;
  final TextEditingController replyCtrl;
  const _ReplyInput({required this.post, required this.replyCtrl});

  @override
  Widget build(BuildContext context) {
    final community = context.read<CommunityProvider>();
    final user = context.read<AuthProvider>().currentUser!;

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: replyCtrl,
            decoration: InputDecoration(
              hintText: 'Andika jibu...',
              hintStyle: const TextStyle(fontSize: 12),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide:
                      BorderSide(color: AppColors.mid.withValues(alpha: 0.3))),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide:
                      BorderSide(color: AppColors.mid.withValues(alpha: 0.3))),
              filled: true,
              fillColor: Colors.white,
            ),
            style: const TextStyle(fontSize: 13),
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: () async {
            final text = replyCtrl.text.trim();
            if (text.isEmpty) return;
            replyCtrl.clear();
            await community.addReply(
              postId: post.id,
              authorId: user.id,
              authorName: user.displayName,
              authorRole: user.role,
              content: text,
            );
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: AppColors.leaf, shape: BoxShape.circle),
            child: const Icon(Icons.send, color: Colors.white, size: 18),
          ),
        ),
      ],
    );
  }
}

// ── Tab 3: User directory — loads from Supabase farmers table ────────────────

class _DirectoryTab extends StatefulWidget {
  final String roleFilter;
  final ValueChanged<String> onRoleChanged;
  final TextEditingController searchCtrl;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;

  const _DirectoryTab({
    required this.roleFilter,
    required this.onRoleChanged,
    required this.searchCtrl,
    required this.searchQuery,
    required this.onSearchChanged,
  });

  @override
  State<_DirectoryTab> createState() => _DirectoryTabState();
}

class _DirectoryTabState extends State<_DirectoryTab> {
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;
  String? _error;

  static const _roleFilters = [
    {"key": "zote",       "label": "Wote"},
    {"key": "mkulima",    "label": "Wakulima"},
    {"key": "duka",       "label": "Maduka"},
    {"key": "muuzaji",    "label": "Wauuzaji"},
    {"key": "mwekezaji",  "label": "Wawekezaji"},
    {"key": "afisa",      "label": "Maafisa"},
  ];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() { _loading = true; _error = null; });
    try {
      final myId = context.read<AuthProvider>().currentUser?.id ?? "";
      final combined = <String, Map<String, dynamic>>{};

      // 1. Query farmers table (old registrations)
      try {
        final rows = await Supabase.instance.client
            .from("farmers")
            .select("id, name, region, role, color_hex, extra_info")
            .neq("id", myId)
            .order("created_at", ascending: false);
        for (final r in (rows as List).cast<Map<String, dynamic>>()) {
          combined[r['id'] as String] = r;
        }
      } catch (_) {}

      // 2. Query profiles table (new registrations) — merge on top
      try {
        final rows = await Supabase.instance.client
            .from("profiles")
            .select("id, first_name, last_name, email, region, role, specializations, is_available, consultation_count, bio, organization, district")
            .neq("id", myId)
            .order("joined_at", ascending: false);
        for (final r in (rows as List).cast<Map<String, dynamic>>()) {
          final id = r['id'] as String;
          final name = '${r['first_name'] ?? ''} ${r['last_name'] ?? ''}'.trim();
          final roleKey = r['role'] as String? ?? 'mkulima';
          combined[id] = {
            'id': id,
            'name': name.isEmpty ? (r['email'] as String? ?? 'Mtumiaji') : name,
            'first_name': r['first_name'] ?? '',
            'last_name': r['last_name'] ?? '',
            'region': r['region'] ?? '',
            'role': roleKey,
            'color_hex': UserRoleX.fromKey(roleKey).colorHex,
            'extra_info': '',
            'specializations': r['specializations'] ?? [],
            'is_available': r['is_available'] ?? true,
            'consultation_count': r['consultation_count'] ?? 0,
            'bio': r['bio'] ?? '',
            'organization': r['organization'] ?? '',
            'district': r['district'] ?? '',
          };
        }
      } catch (_) {}

      setState(() { _users = combined.values.toList(); });
    } catch (e) {
      setState(() { _error = "Hitilafu ya mtandao. Angalia intaneti."; });
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    var filtered = _users;
    if (widget.roleFilter != "zote") {
      filtered = filtered.where((u) => (u["role"] ?? "mkulima") == widget.roleFilter).toList();
    }
    if (widget.searchQuery.isNotEmpty) {
      final q = widget.searchQuery.toLowerCase();
      filtered = filtered.where((u) =>
          (u["name"] as String? ?? "").toLowerCase().contains(q) ||
          (u["region"] as String? ?? "").toLowerCase().contains(q) ||
          (u["extra_info"] as String? ?? "").toLowerCase().contains(q)).toList();
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: TextField(
            controller: widget.searchCtrl,
            onChanged: widget.onSearchChanged,
            decoration: InputDecoration(
              hintText: "Tafuta kwa jina, mkoa au zao...",
              hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              suffixIcon: widget.searchQuery.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () { widget.searchCtrl.clear(); widget.onSearchChanged(""); })
                  : IconButton(icon: const Icon(Icons.refresh, size: 18), onPressed: _loadUsers, tooltip: "Onyesha upya"),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              filled: true, fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            children: _roleFilters.map((f) {
              final sel = widget.roleFilter == f["key"];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(f["label"]!, style: TextStyle(fontSize: 12, color: sel ? Colors.white : AppColors.soil)),
                  selected: sel,
                  onSelected: (_) => widget.onRoleChanged(f["key"]!),
                  selectedColor: AppColors.leaf, backgroundColor: Colors.white,
                ),
              );
            }).toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(children: [
            Text(_loading ? "Inapakia watumiaji..." : "${filtered.length} watumiaji waliojisajili",
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ]),
        ),
        Expanded(child: _buildBody(filtered)),
      ],
    );
  }

  Widget _buildBody(List<Map<String, dynamic>> users) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.leaf));
    if (_error != null) {
      return Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: Colors.grey), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton.icon(icon: const Icon(Icons.refresh), label: const Text("Jaribu Tena"), onPressed: _loadUsers),
        ],
      )));
    }
    if (users.isEmpty) {
      return Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("👥", style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            _users.isEmpty ? "Hakuna watumiaji wengine waliojisajili bado. Washirikishe app hii ili wajisajili!"
                           : "Hakuna watumiaji wanaofanana na utafutaji wako.",
            style: const TextStyle(color: Colors.grey), textAlign: TextAlign.center),
        ],
      )));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
      itemCount: users.length,
      separatorBuilder: (context, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final u = users[i];
        final role     = UserRoleX.fromKey(u["role"] as String? ?? "mkulima");
        final colorHex = role.colorHex;
        final color    = AppColors.roleColor(role);
        final firstName = u["first_name"] as String? ?? "";
        final lastName  = u["last_name"] as String? ?? "";
        final displayName = "$firstName $lastName".trim().isEmpty
            ? (u["name"] as String? ?? "Mtumiaji")
            : "$firstName $lastName".trim();
        final specs = (u["specializations"] as List?)?.cast<String>() ?? [];
        final isAvailable = u["is_available"] as bool? ?? true;
        final consultCount = u["consultation_count"] as int? ?? 0;

        // Afisa → ExpertProfileScreen; wengine → ChatScreen moja kwa moja
        if (role == UserRole.afisa) {
          return _ExpertCard(
            userData: u,
            displayName: displayName,
            region: u["region"] as String? ?? "",
            specializations: specs,
            isAvailable: isAvailable,
            consultCount: consultCount,
            color: color,
          );
        }
        return _UserCard(
          id: u["id"] as String, displayName: displayName,
          role: role, region: u["region"] as String? ?? "",
          extra: "", colorHex: colorHex, color: color,
        );
      },
    );
  }
}
class _UserCard extends StatelessWidget {
  final String id;
  final String displayName;
  final UserRole role;
  final String region;
  final String extra;
  final String colorHex;
  final Color color;

  const _UserCard({
    required this.id,
    required this.displayName,
    required this.role,
    required this.region,
    required this.extra,
    required this.colorHex,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 26,
              backgroundColor: color.withValues(alpha: 0.13),
              child: Text(
                displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(displayName,
                      style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.soil)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      RoleChip(role, fontSize: 10),
                      const SizedBox(width: 8),
                      const Icon(Icons.location_on,
                          size: 11, color: Colors.grey),
                      const SizedBox(width: 2),
                      Text(region,
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                  if (extra.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(extra,
                        style: TextStyle(
                            fontSize: 11,
                            color: color.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ],
              ),
            ),

            // Chat button
            ElevatedButton.icon(
              onPressed: () async {
                final auth = context.read<AuthProvider>();
                final myId = auth.currentUser?.id ?? '';
                final myRole = auth.currentUser?.role;
                final canMsg = await PrivacyService.canSendMessage(
                  senderId: myId,
                  recipientId: id,
                  senderIsOfficer: myRole == UserRole.afisa,
                );
                if (!context.mounted) return;
                if (!canMsg) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Mtu huyu haukuruhusu kupokea ujumbe.')));
                  return;
                }
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => ChatScreen(
                              contactId: id,
                              contactName: displayName,
                              contactRole: role,
                              contactColorHex: colorHex,
                            )));
              },
              icon: const Icon(Icons.chat_bubble_outline, size: 14),
              label: const Text('Ongea', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Expert card (Afisa with specializations) ──────────────────────────────────

class _ExpertCard extends StatelessWidget {
  final Map<String, dynamic> userData;
  final String displayName;
  final String region;
  final List<String> specializations;
  final bool isAvailable;
  final int consultCount;
  final Color color;

  const _ExpertCard({
    required this.userData, required this.displayName, required this.region,
    required this.specializations, required this.isAvailable,
    required this.consultCount, required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => ExpertProfileScreen(userData: userData))),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Avatar with availability dot
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: color.withValues(alpha: 0.13),
                        child: Text(
                          displayName.isNotEmpty ? displayName[0].toUpperCase() : 'A',
                          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                      Container(
                        width: 12, height: 12,
                        decoration: BoxDecoration(
                          color: isAvailable ? Colors.green : Colors.grey,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(displayName,
                            style: GoogleFonts.dmSans(
                                fontWeight: FontWeight.bold,
                                fontSize: 14, color: AppColors.soil)),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00695C).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text('Afisa Kilimo',
                                  style: GoogleFonts.dmSans(
                                      fontSize: 10, color: const Color(0xFF00695C),
                                      fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.location_on, size: 11, color: Colors.grey),
                            const SizedBox(width: 2),
                            Text(region, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isAvailable ? '🟢 Anapatikana sasa' : '⚪ Nje ya mtandao',
                          style: GoogleFonts.dmSans(
                              fontSize: 11,
                              color: isAvailable ? Colors.green.shade700 : Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  // Stats + button
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('$consultCount', style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.soil)),
                      Text('walioshauriwa', style: GoogleFonts.dmSans(
                          fontSize: 9, color: AppColors.mid)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00695C),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('Wasiliana',
                            style: GoogleFonts.dmSans(
                                color: Colors.white, fontSize: 11,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
              // Specializations
              if (specializations.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6, runSpacing: 4,
                  children: specializations.take(4).map((s) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00695C).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(specLabel(s),
                        style: GoogleFonts.dmSans(
                            fontSize: 10, color: const Color(0xFF00695C),
                            fontWeight: FontWeight.w600)),
                  )).toList()
                    ..addAll(specializations.length > 4
                        ? [Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text('+${specializations.length - 4} zaidi',
                                style: GoogleFonts.dmSans(
                                    fontSize: 10, color: Colors.grey)))]
                        : []),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Post sheet (new post) ─────────────────────────────────────────────────────

void _showPostSheet(BuildContext context, UserModel user) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PostSheet(user: user),
  );
}

class _PostSheet extends StatefulWidget {
  final UserModel user;
  const _PostSheet({required this.user});

  @override
  State<_PostSheet> createState() => _PostSheetState();
}

class _PostSheetState extends State<_PostSheet> {
  String _topic = 'mazao';
  final _ctrl = TextEditingController();
  File? _imageFile;
  bool _posting = false;
  final _picker = ImagePicker();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 75);
    if (picked != null) setState(() => _imageFile = File(picked.path));
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.97,
      minChildSize: 0.5,
      builder: (ctx, scroll) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ListView(
          controller: scroll,
          padding: EdgeInsets.fromLTRB(
              20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text('Chapisho Jipya',
                style: GoogleFonts.playfairDisplay(
                    fontSize: 18, fontWeight: FontWeight.bold,
                    color: AppColors.soil)),
            const SizedBox(height: 4),
            Text('Shiriki habari, swali, picha au tangazo na jamii.',
                style: GoogleFonts.dmSans(color: Colors.grey, fontSize: 13)),

            const SizedBox(height: 16),

            // Topic selector
            Text('Mada:',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 6,
              children: PostTopic.all
                  .where((t) => t['key'] != 'zote')
                  .map((t) => ChoiceChip(
                        label: Text('${t['emoji']} ${t['label']}',
                            style: TextStyle(
                                fontSize: 12,
                                color: _topic == t['key'] ? Colors.white : AppColors.soil)),
                        selected: _topic == t['key'],
                        onSelected: (_) => setState(() => _topic = t['key']!),
                        selectedColor: AppColors.leaf,
                        backgroundColor: AppColors.mint.withValues(alpha: 0.4),
                      ))
                  .toList(),
            ),

            const SizedBox(height: 16),

            // Text content
            Text('Ujumbe:',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: _ctrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Andika hapa — swali, bei, habari ya mazao, n.k.',
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.mid.withValues(alpha: 0.3))),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.mid.withValues(alpha: 0.3))),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.leaf, width: 2)),
                filled: true,
                fillColor: AppColors.mint.withValues(alpha: 0.3),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),

            const SizedBox(height: 16),

            // Image section
            Text('Picha (si lazima):',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),

            if (_imageFile != null) ...[
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _imageFile!,
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8, right: 8,
                    child: GestureDetector(
                      onTap: () => setState(() => _imageFile = null),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                            color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(Icons.close, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => setState(() => _imageFile = null),
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('Ondoa picha', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt, size: 18),
                      label: const Text('Piga Picha', style: TextStyle(fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.leaf,
                        side: const BorderSide(color: AppColors.leaf),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library, size: 18),
                      label: const Text('Matunzio', style: TextStyle(fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.mid,
                        side: BorderSide(color: AppColors.mid.withValues(alpha: 0.5)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 20),

            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.leaf,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                icon: _posting
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send),
                label: Text(
                  _posting
                      ? (_imageFile != null ? 'Inapakia picha...' : 'Inachapisha...')
                      : 'Chapisha',
                  style: GoogleFonts.dmSans(
                      fontSize: 15, fontWeight: FontWeight.bold),
                ),
                onPressed: _posting
                    ? null
                    : () async {
                        final text = _ctrl.text.trim();
                        if (text.length < 3 && _imageFile == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Andika ujumbe au chagua picha kwanza.')));
                          return;
                        }
                        setState(() => _posting = true);
                        try {
                          await context.read<CommunityProvider>().addPost(
                                authorId: widget.user.id,
                                authorName: widget.user.displayName,
                                authorRole: widget.user.role,
                                authorRegion: widget.user.region,
                                topic: _topic,
                                content:
                                    text.isNotEmpty ? text : '📷',
                                imageFile: _imageFile,
                              );
                          if (context.mounted) Navigator.pop(context);
                        } catch (e) {
                          if (context.mounted) {
                            setState(() => _posting = false);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('Imeshindwa: ${e.toString()}'),
                                backgroundColor: Colors.red.shade700));
                          }
                        }
                      },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

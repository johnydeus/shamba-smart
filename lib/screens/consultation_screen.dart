import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/common_widgets.dart';
import 'chat_screen.dart';

class ConsultationScreen extends StatefulWidget {
  const ConsultationScreen({super.key});

  @override
  State<ConsultationScreen> createState() => _ConsultationScreenState();
}

class _ConsultationScreenState extends State<ConsultationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  // Real farmers from Supabase
  List<Map<String, dynamic>> _farmers = [];
  bool _loadingFarmers = false;
  String? _farmersError;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadFarmers();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFarmers() async {
    setState(() { _loadingFarmers = true; _farmersError = null; });
    try {
      final myId = context.read<AuthProvider>().currentUser?.id ?? '';
      final combined = <String, Map<String, dynamic>>{};

      // 1. farmers table (old users)
      try {
        final rows = await Supabase.instance.client
            .from('farmers')
            .select('id, name, region, role, color_hex, extra_info, created_at')
            .neq('id', myId)
            .order('created_at', ascending: false);
        for (final r in (rows as List).cast<Map<String, dynamic>>()) {
          combined[r['id'] as String] = r;
        }
      } catch (_) {}

      // 2. profiles table (new users) — merges on top
      try {
        final rows = await Supabase.instance.client
            .from('profiles')
            .select('id, first_name, last_name, email, region, role, joined_at')
            .neq('id', myId)
            .order('joined_at', ascending: false);
        for (final r in (rows as List).cast<Map<String, dynamic>>()) {
          final id = r['id'] as String;
          final name = '${r['first_name'] ?? ''} ${r['last_name'] ?? ''}'.trim();
          final roleKey = r['role'] as String? ?? 'mkulima';
          combined[id] = {
            'id': id,
            'name': name.isEmpty ? (r['email'] as String? ?? 'Mtumiaji') : name,
            'region': r['region'] ?? '',
            'role': roleKey,
            'color_hex': UserRoleX.fromKey(roleKey).colorHex,
            'extra_info': '',
            'created_at': r['joined_at'] ?? '',
          };
        }
      } catch (_) {}

      if (mounted) {
        setState(() {
          _farmers = combined.values.toList();
          _loadingFarmers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _farmersError = 'Hitilafu ya mtandao. Angalia intaneti na ujaribu tena.';
          _loadingFarmers = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _filteredFarmers {
    if (_searchQuery.isEmpty) return _farmers;
    final q = _searchQuery.toLowerCase();
    return _farmers.where((f) {
      return (f['name'] as String? ?? '').toLowerCase().contains(q) ||
          (f['region'] as String? ?? '').toLowerCase().contains(q) ||
          (f['extra_info'] as String? ?? '').toLowerCase().contains(q) ||
          (f['role'] as String? ?? '').toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final chatProv = context.watch<ChatProvider>();
    final activeConvs = chatProv.conversations.values.toList()
      ..sort((a, b) {
        final ta = a.lastMessageTime ?? DateTime(2000);
        final tb = b.lastMessageTime ?? DateTime(2000);
        return tb.compareTo(ta);
      });

    return Scaffold(
      backgroundColor: AppColors.mist,
      appBar: AppBar(
        title: const Text('Ushauri wa Wakulima'),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.chat_bubble_outline, size: 16),
                  const SizedBox(width: 6),
                  const Text('Mazungumzo'),
                  if (activeConvs.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.harvest,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('${activeConvs.length}',
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.people_outline, size: 16),
                  const SizedBox(width: 6),
                  const Text('Wakulima'),
                  if (_farmers.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('${_farmers.length}',
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildConversationsTab(activeConvs, chatProv),
          _buildFarmersTab(),
        ],
      ),
    );
  }

  // ── Tab 1: Active conversations ───────────────────────────────────────────

  Widget _buildConversationsTab(
      List<dynamic> convs, ChatProvider chatProv) {
    if (convs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('💬', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 16),
              Text('Hakuna mazungumzo bado',
                  style: GoogleFonts.playfairDisplay(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                'Nenda kwenye kichupo cha "Wakulima" uanze\n'
                'mazungumzo na mkulima yeyote.',
                style: GoogleFonts.dmSans(
                    color: Colors.grey, fontSize: 13, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _tabCtrl.animateTo(1),
                icon: const Icon(Icons.people_outline),
                label: const Text('Angalia Wakulima'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: convs.length,
      separatorBuilder: (context, _) => Divider(
          height: 1, color: AppColors.mid.withValues(alpha: 0.1)),
      itemBuilder: (context, i) {
        final conv = convs[i];
        final hasUnread = conv.unreadCount > 0;
        return InkWell(
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
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                UserAvatarCircle(
                    name: conv.contactName,
                    role: conv.contactRole,
                    size: 50),
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
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14)),
                          ),
                          if (hasUnread)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00695C),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text('${conv.unreadCount}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      RoleChip(conv.contactRole, fontSize: 9),
                      const SizedBox(height: 3),
                      Text(conv.lastMessage,
                          style: GoogleFonts.dmSans(
                              fontSize: 12, color: Colors.grey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right,
                    color: Colors.grey, size: 18),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Tab 2: Real farmers directory from Supabase ───────────────────────────

  Widget _buildFarmersTab() {
    return Column(
      children: [
        // Search + refresh bar
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'Tafuta kwa jina, mkoa au zao...',
              hintStyle:
                  const TextStyle(color: Colors.grey, fontSize: 13),
              prefixIcon:
                  const Icon(Icons.search, color: Colors.grey),
              suffixIcon: _loadingFarmers
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF1A5C2E))),
                    )
                  : IconButton(
                      icon: const Icon(Icons.refresh, size: 20,
                          color: Color(0xFF1A5C2E)),
                      tooltip: 'Pakia upya',
                      onPressed: _loadFarmers,
                    ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ),

        // Error banner
        if (_farmersError != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.wifi_off, color: Colors.red.shade400, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(_farmersError!,
                          style: TextStyle(
                              fontSize: 12, color: Colors.red.shade700))),
                  TextButton(
                      onPressed: _loadFarmers,
                      child: const Text('Jaribu Tena',
                          style: TextStyle(fontSize: 12))),
                ],
              ),
            ),
          ),

        // Count
        if (!_loadingFarmers && _farmersError == null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
            child: Row(
              children: [
                Text(
                  '${_filteredFarmers.length} watumiaji wamepatikana',
                  style: const TextStyle(
                      fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),

        Expanded(
          child: _loadingFarmers
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Color(0xFF1A5C2E)),
                      SizedBox(height: 12),
                      Text('Inapakia watumiaji...',
                          style: TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                )
              : _filteredFarmers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.people_outline,
                              size: 60, color: Colors.grey),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'Hakuna watumiaji wanaofanana\nna utafutaji wako.'
                                : 'Hakuna watumiaji wengine bado.\nWaalike wenzako wajisajili!',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.refresh),
                            label: const Text('Pakia Tena'),
                            onPressed: _loadFarmers,
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding:
                          const EdgeInsets.fromLTRB(12, 0, 12, 24),
                      itemCount: _filteredFarmers.length,
                      separatorBuilder: (context, _) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, i) =>
                          _RealFarmerCard(farmer: _filteredFarmers[i]),
                    ),
        ),
      ],
    );
  }
}

// ── Real farmer card — data from Supabase ────────────────────────────────────

class _RealFarmerCard extends StatelessWidget {
  final Map<String, dynamic> farmer;

  const _RealFarmerCard({required this.farmer});

  @override
  Widget build(BuildContext context) {
    final name = farmer['name'] as String? ?? 'Mtumiaji';
    final region = farmer['region'] as String? ?? '';
    final roleKey = farmer['role'] as String? ?? 'mkulima';
    final extraInfo = farmer['extra_info'] as String? ?? '';
    final colorHex = farmer['color_hex'] as String? ?? '#2E7D32';
    final farmerId = farmer['id'] as String;
    final role = UserRoleX.fromKey(roleKey);

    Color avatarColor;
    try {
      final hex = colorHex.replaceAll('#', '');
      avatarColor = Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      avatarColor = const Color(0xFF2E7D32);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: avatarColor.withValues(alpha: 0.15),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(
                    color: avatarColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 3),
                  RoleChip(role, fontSize: 10),
                  if (region.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 12, color: Colors.grey),
                        const SizedBox(width: 3),
                        Text(region,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ],
                  if (extraInfo.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(extraInfo,
                        style: const TextStyle(
                            fontSize: 11, color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                final chatProv = context.read<ChatProvider>();
                if (!chatProv.isReady) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Bado hujaunganika. Subiri sekunde moja.')),
                  );
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      contactId: farmerId,
                      contactName: name,
                      contactRole: role,
                      contactColorHex: colorHex,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                textStyle: const TextStyle(fontSize: 12),
              ),
              icon: const Icon(Icons.chat_bubble_outline, size: 14),
              label: const Text('Wasiliana'),
            ),
          ],
        ),
      ),
    );
  }
}

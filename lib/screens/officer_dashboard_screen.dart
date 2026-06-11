import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../services/officer_service.dart';
import '../theme/app_colors.dart';
import 'chat_screen.dart';

class OfficerDashboardScreen extends StatefulWidget {
  const OfficerDashboardScreen({super.key});

  @override
  State<OfficerDashboardScreen> createState() => _OfficerDashboardScreenState();
}

class _OfficerDashboardScreenState extends State<OfficerDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<Map<String, dynamic>> _farmers = [];
  List<Map<String, dynamic>> _broadcasts = [];
  bool _loading = true;
  String? _officerId;

  // Broadcast composer
  final _titleCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  String _priority = 'normal';
  bool _posting = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _titleCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    // Look up officer record linked to this user
    try {
      final farmers = await OfficerService.getOfficerFarmers(user.id);
      final region = user.region.isNotEmpty ? user.region : 'Tanzania';
      final broadcasts =
          await OfficerService.getRegionalBroadcasts(region: region);
      if (mounted) {
        setState(() {
          _officerId = user.id;
          _farmers = farmers;
          _broadcasts = broadcasts;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _postBroadcast() async {
    if (_titleCtrl.text.trim().isEmpty || _msgCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Andika kichwa na ujumbe')));
      return;
    }
    setState(() => _posting = true);
    final user = context.read<AuthProvider>().currentUser!;
    try {
      await OfficerService.postBroadcast(
        officerId: _officerId ?? user.id,
        title: _titleCtrl.text.trim(),
        message: _msgCtrl.text.trim(),
        region: user.region.isNotEmpty ? user.region : 'Tanzania',
        priority: _priority,
      );
      _titleCtrl.clear();
      _msgCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Tangazo limetumwa kwa wakulima wote wa mkoa wako'),
          backgroundColor: AppColors.leaf,
        ));
        await _load();
        _tabs.animateTo(2); // go to broadcasts tab
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Hitilafu: $e'),
            backgroundColor: Colors.red.shade700));
      }
    }
    if (mounted) setState(() => _posting = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: const Color(0xFFFDF6EE),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dashibodi ya Afisa',
                style: GoogleFonts.playfairDisplay(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            Text('${user.region} — Afisa Kilimo',
                style:
                    const TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.harvest,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle:
              GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 12),
          tabs: [
            Tab(
                icon: const Icon(Icons.people_outline, size: 18),
                text: 'Wakulima (${_farmers.length})'),
            const Tab(
                icon: Icon(Icons.campaign_outlined, size: 18),
                text: 'Tuma Tangazo'),
            Tab(
                icon: const Icon(Icons.article_outlined, size: 18),
                text: 'Matangazo (${_broadcasts.length})'),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.leaf))
          : TabBarView(
              controller: _tabs,
              children: [
                _buildFarmersTab(user),
                _buildComposeTab(user),
                _buildBroadcastsTab(),
              ],
            ),
    );
  }

  // ── TAB 1: Farmers list ────────────────────────────────────────────────────

  Widget _buildFarmersTab(UserModel user) {
    if (_farmers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🌱', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text('Hakuna wakulima waliounganishwa nawe bado',
                style: GoogleFonts.playfairDisplay(
                    color: AppColors.soil, fontSize: 16)),
            const SizedBox(height: 8),
            const Text(
                'Wakulima wa mkoa wako wataunganishwa nawe '
                'kiotomatiki wanapojisajili.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
                textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Stats summary
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _statBox('Wakulima', _farmers.length.toString(), Icons.people),
              Container(width: 1, height: 40, color: Colors.grey.shade200),
              _statBox('Mkoa', user.region.isEmpty ? '—' : user.region,
                  Icons.location_on_outlined),
            ],
          ),
        ),

        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _farmers.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _buildFarmerCard(_farmers[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildFarmerCard(Map<String, dynamic> farmer) {
    final name =
        '${farmer['first_name'] ?? ''} ${farmer['last_name'] ?? ''}'.trim();
    final region = farmer['region'] as String? ?? '';
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.leaf.withValues(alpha: 0.1),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'M',
                style: const TextStyle(
                    color: AppColors.leaf, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name.isEmpty ? 'Mkulima' : name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  if (region.isNotEmpty)
                    Text(region,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline,
                  color: AppColors.harvest),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    contactId: farmer['id'] as String,
                    contactName: name.isEmpty ? 'Mkulima' : name,
                    contactRole: UserRole.mkulima,
                    contactColorHex: '2E7D32',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── TAB 2: Broadcast composer ──────────────────────────────────────────────

  Widget _buildComposeTab(UserModel user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.leaf.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.campaign, color: AppColors.leaf),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tangazo lako litafikia wakulima wote wa ${user.region.isEmpty ? "mkoa wako" : user.region}.',
                    style: const TextStyle(fontSize: 13, color: AppColors.leaf),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Priority
          const Text('Kipaumbele',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _priorityChip('normal', '💬 Kawaida', Colors.grey),
              _priorityChip('urgent', '⚠️ Muhimu', Colors.orange),
              _priorityChip('emergency', '🚨 Dharura', Colors.red),
            ],
          ),
          const SizedBox(height: 16),

          // Title
          const Text('Kichwa cha Tangazo',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          TextField(
            controller: _titleCtrl,
            maxLength: 80,
            decoration: InputDecoration(
              hintText: 'Mfano: Tahadhari ya Wadudu wa Mahindi',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 12),

          // Message
          const Text('Ujumbe',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          TextField(
            controller: _msgCtrl,
            maxLines: 6,
            maxLength: 500,
            decoration: InputDecoration(
              hintText: 'Andika ujumbe wako kwa Kiswahili...',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _posting ? null : _postBroadcast,
              icon: _posting
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.send),
              label: Text(_posting
                  ? 'Inatuma...'
                  : 'Tuma Tangazo kwa Wakulima'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: AppColors.leaf,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _priorityChip(String value, String label, Color color) =>
      ChoiceChip(
        label: Text(label),
        selected: _priority == value,
        onSelected: (_) => setState(() => _priority = value),
        selectedColor: color.withValues(alpha: 0.15),
        labelStyle: TextStyle(
            color: _priority == value ? color : Colors.grey,
            fontWeight: _priority == value ? FontWeight.bold : FontWeight.normal),
        side: BorderSide(
            color: _priority == value
                ? color
                : Colors.grey.shade300),
      );

  // ── TAB 3: Past broadcasts ─────────────────────────────────────────────────

  Widget _buildBroadcastsTab() {
    if (_broadcasts.isEmpty) {
      return const Center(
        child: Text('Hakuna matangazo bado.',
            style: TextStyle(color: Colors.grey)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _broadcasts.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final b = _broadcasts[i];
        final priority = b['priority'] as String? ?? 'normal';
        final Color c = priority == 'urgent'
            ? Colors.orange
            : priority == 'emergency'
                ? Colors.red
                : AppColors.leaf;
        return Card(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.campaign, color: c, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(b['title'] as String? ?? '',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: c)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: c.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(priority,
                        style:
                            TextStyle(fontSize: 10, color: c,
                                fontWeight: FontWeight.bold)),
                  ),
                ]),
                const SizedBox(height: 6),
                Text(b['message'] as String? ?? '',
                    style: const TextStyle(fontSize: 13, height: 1.4),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statBox(String label, String value, IconData icon) => Column(
        children: [
          Icon(icon, color: AppColors.leaf, size: 20),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16)),
          Text(label,
              style:
                  const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      );
}

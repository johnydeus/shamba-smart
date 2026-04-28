import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/chat_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/common_widgets.dart';
import 'chat_screen.dart';

// Demo farmers the field officer can consult with
// In a production app these would come from Supabase
const List<Map<String, dynamic>> _demoFarmers = [
  {
    'id': 'farmer_001',
    'name': 'Amina Juma',
    'region': 'Morogoro',
    'crops': ['Mahindi', 'Nyanya'],
    'acres': 2.5,
    'issue': 'Magonjwa ya mahindi',
  },
  {
    'id': 'farmer_002',
    'name': 'Hassan Mwangi',
    'region': 'Kilosa',
    'crops': ['Muhogo', 'Maharagwe'],
    'acres': 4.0,
    'issue': 'Udongo wenye tindikali',
  },
  {
    'id': 'farmer_003',
    'name': 'Fatuma Said',
    'region': 'Arusha',
    'crops': ['Nyanya', 'Pilipili hoho'],
    'acres': 1.5,
    'issue': 'Wadudu kwenye nyanya',
  },
  {
    'id': 'farmer_004',
    'name': 'John Mwambene',
    'region': 'Mbeya',
    'crops': ['Mchele', 'Mahindi'],
    'acres': 6.0,
    'issue': 'Umwagiliaji',
  },
  {
    'id': 'farmer_005',
    'name': 'Zena Komba',
    'region': 'Dodoma',
    'crops': ['Alizeti', 'Mtama'],
    'acres': 3.0,
    'issue': 'Ukame na mbolea',
  },
  {
    'id': 'farmer_006',
    'name': 'Peter Chaula',
    'region': 'Iringa',
    'crops': ['Viazi vitamu', 'Maharagwe'],
    'acres': 2.0,
    'issue': 'Kuoza kwa viazi',
  },
  {
    'id': 'farmer_007',
    'name': 'Mariam Ally',
    'region': 'Tanga',
    'crops': ['Muhogo', 'Ndizi'],
    'acres': 5.0,
    'issue': 'Ugonjwa wa mosaic muhogo',
  },
  {
    'id': 'farmer_008',
    'name': 'Rashidi Bakari',
    'region': 'Mwanza',
    'crops': ['Pamba', 'Mahindi'],
    'acres': 8.0,
    'issue': 'Viwavi wa jeshi',
  },
];

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

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
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

    final filtered = _demoFarmers.where((f) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return (f['name'] as String).toLowerCase().contains(q) ||
          (f['region'] as String).toLowerCase().contains(q) ||
          (f['crops'] as List).any(
              (c) => c.toString().toLowerCase().contains(q));
    }).toList();

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
            const Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.people_outline, size: 16),
                  SizedBox(width: 6),
                  Text('Wakulima'),
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
          _buildFarmersTab(filtered),
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

  // ── Tab 2: Farmers directory ──────────────────────────────────────────────

  Widget _buildFarmersTab(List<Map<String, dynamic>> farmers) {
    return Column(
      children: [
        // Search bar
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
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
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

        Expanded(
          child: farmers.isEmpty
              ? Center(
                  child: Text('Hakuna wakulima wanaofanana na utafutaji.',
                      style: GoogleFonts.dmSans(color: Colors.grey)),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                  itemCount: farmers.length,
                  separatorBuilder: (context, _) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, i) =>
                      _FarmerContactCard(farmer: farmers[i]),
                ),
        ),
      ],
    );
  }
}

// ── Farmer contact card ───────────────────────────────────────────────────────

class _FarmerContactCard extends StatelessWidget {
  final Map<String, dynamic> farmer;

  const _FarmerContactCard({required this.farmer});

  @override
  Widget build(BuildContext context) {
    final crops = (farmer['crops'] as List).cast<String>();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 26,
              backgroundColor:
                  const Color(0xFF2E7D32).withValues(alpha: 0.12),
              child: Text(
                (farmer['name'] as String)[0].toUpperCase(),
                style: const TextStyle(
                    color: Color(0xFF2E7D32),
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
                  Text(
                    farmer['name'] as String,
                    style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 12, color: Colors.grey),
                      const SizedBox(width: 3),
                      Text(farmer['region'] as String,
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12)),
                      const SizedBox(width: 8),
                      const Icon(Icons.landscape,
                          size: 12, color: Colors.grey),
                      const SizedBox(width: 3),
                      Text('${farmer['acres']} ekari',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 4,
                    children: crops
                        .map((c) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2E7D32)
                                    .withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(c,
                                  style: const TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF2E7D32),
                                      fontWeight: FontWeight.w600)),
                            ))
                        .toList(),
                  ),
                  if ((farmer['issue'] as String).isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.info_outline,
                            size: 12, color: Colors.orange),
                        const SizedBox(width: 4),
                        Text(
                          farmer['issue'] as String,
                          style: const TextStyle(
                              fontSize: 11, color: Colors.orange),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Chat button
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    contactId: farmer['id'] as String,
                    contactName: farmer['name'] as String,
                    contactRole: UserRole.mkulima,
                    contactColorHex: '#2E7D32',
                  ),
                ),
              ),
              icon: const Icon(Icons.chat_bubble_outline, size: 14),
              label: const Text('Ongea',
                  style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00695C),
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

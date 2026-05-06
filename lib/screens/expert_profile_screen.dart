import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/common_widgets.dart';
import 'chat_screen.dart';

// Orodha ya utaalamu unaoweza kuchagua
const List<Map<String, String>> kSpecializations = [
  {'key': 'mahindi',       'label': '🌽 Mahindi'},
  {'key': 'mpunga',        'label': '🌾 Mpunga'},
  {'key': 'ngano',         'label': '🌾 Ngano'},
  {'key': 'mtama',         'label': '🌾 Mtama / Uwele'},
  {'key': 'nyanya',        'label': '🍅 Nyanya'},
  {'key': 'pilipili',      'label': '🌶️ Pilipili'},
  {'key': 'vitunguu',      'label': '🧅 Vitunguu'},
  {'key': 'kabichi',       'label': '🥦 Mbogamboga'},
  {'key': 'mango',         'label': '🥭 Mango'},
  {'key': 'ndizi',         'label': '🍌 Ndizi'},
  {'key': 'papai',         'label': '🍈 Papai'},
  {'key': 'machungwa',     'label': '🍊 Machungwa / Matunda'},
  {'key': 'kahawa',        'label': '☕ Kahawa'},
  {'key': 'chai',          'label': '🍵 Chai'},
  {'key': 'korosho',       'label': '🥜 Korosho'},
  {'key': 'pamba',         'label': '🌿 Pamba'},
  {'key': 'miwa',          'label': '🎋 Miwa'},
  {'key': 'alizeti',       'label': '🌻 Alizeti'},
  {'key': 'mifugo',        'label': '🐄 Mifugo'},
  {'key': 'kuku',          'label': '🐔 Ufugaji wa Kuku'},
  {'key': 'umwagiliaji',   'label': '💧 Kilimo cha Umwagiliaji'},
  {'key': 'udongo',        'label': '🧪 Udongo na Rutuba'},
  {'key': 'ugonjwa',       'label': '🔬 Ugonjwa na Wadudu'},
  {'key': 'hali_hewa',     'label': '🌦️ Hali ya Hewa na Mazao'},
  {'key': 'masoko',        'label': '📈 Masoko na Biashara ya Mazao'},
];

String specLabel(String key) =>
    kSpecializations.firstWhere(
      (s) => s['key'] == key,
      orElse: () => {'key': key, 'label': key},
    )['label']!;

// ─────────────────────────────────────────────────────────────────────────────
// ExpertProfileScreen — ukurasa wa umma wa Afisa Kilimo
// ─────────────────────────────────────────────────────────────────────────────

class ExpertProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const ExpertProfileScreen({super.key, required this.userData});

  @override
  State<ExpertProfileScreen> createState() => _ExpertProfileScreenState();
}

class _ExpertProfileScreenState extends State<ExpertProfileScreen> {
  Map<String, dynamic> _data = {};
  bool _loading = true;

  static SupabaseClient get _db => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _data = Map<String, dynamic>.from(widget.userData);
    _loadFullProfile();
  }

  Future<void> _loadFullProfile() async {
    final id = _data['id'] as String? ?? '';
    if (id.isEmpty) { setState(() => _loading = false); return; }
    try {
      final row = await _db
          .from('profiles')
          .select('id, first_name, last_name, region, role, organization, district, badge_number, specializations, is_available, consultation_count, bio, joined_at')
          .eq('id', id)
          .single();
      if (mounted) setState(() { _data = Map<String, dynamic>.from(row); _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String get _name =>
      '${_data['first_name'] ?? ''} ${_data['last_name'] ?? ''}'.trim();
  List<String> get _specs =>
      (_data['specializations'] as List?)?.cast<String>() ?? [];
  bool get _available => _data['is_available'] as bool? ?? true;
  int get _consultCount => _data['consultation_count'] as int? ?? 0;
  String get _bio       => _data['bio'] as String? ?? '';
  String get _region    => _data['region'] as String? ?? '';
  String get _org       => _data['organization'] as String? ?? '';
  String get _district  => _data['district'] as String? ?? '';
  String get _badge     => _data['badge_number'] as String? ?? '';
  String get _roleKey   => _data['role'] as String? ?? 'afisa';

  @override
  Widget build(BuildContext context) {
    final role      = UserRoleX.fromKey(_roleKey);
    final roleColor = AppColors.roleColor(role);
    final myId      = context.read<AuthProvider>().currentUser?.id ?? '';
    final expertId  = _data['id'] as String? ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFFDF6EE),
      body: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: const Color(0xFF00695C),
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: _ProfileHeader(
                name: _name.isEmpty ? 'Afisa Kilimo' : _name,
                role: role,
                region: _region,
                org: _org,
                district: _district,
                available: _available,
                consultCount: _consultCount,
                loading: _loading,
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator(
                        color: AppColors.leaf)),
                  )
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Bio ────────────────────────────────────────────
                        if (_bio.isNotEmpty) ...[
                          _Section(
                            icon: Icons.info_outline,
                            title: 'Kuhusu',
                            child: Text(_bio,
                                style: GoogleFonts.dmSans(
                                    fontSize: 13.5, height: 1.6,
                                    color: AppColors.ink)),
                          ),
                          const SizedBox(height: 14),
                        ],

                        // ── Specializations ────────────────────────────────
                        _Section(
                          icon: Icons.workspace_premium_outlined,
                          title: 'Maeneo ya Utaalamu',
                          child: _specs.isEmpty
                              ? Text('Bado hajaweka maeneo ya utaalamu',
                                  style: GoogleFonts.dmSans(
                                      color: AppColors.mid, fontSize: 13,
                                      fontStyle: FontStyle.italic))
                              : Wrap(
                                  spacing: 8, runSpacing: 8,
                                  children: _specs.map((s) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF00695C)
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                          color: const Color(0xFF00695C)
                                              .withValues(alpha: 0.3)),
                                    ),
                                    child: Text(specLabel(s),
                                        style: GoogleFonts.dmSans(
                                            fontSize: 12,
                                            color: const Color(0xFF00695C),
                                            fontWeight: FontWeight.w600)),
                                  )).toList(),
                                ),
                        ),
                        const SizedBox(height: 14),

                        // ── Official info ──────────────────────────────────
                        _Section(
                          icon: Icons.badge_outlined,
                          title: 'Taarifa Rasmi',
                          child: Column(
                            children: [
                              if (_org.isNotEmpty) _InfoRow(Icons.account_balance_outlined, 'Shirika/Wizara', _org),
                              if (_district.isNotEmpty) ...[if (_org.isNotEmpty) const Divider(height: 14), _InfoRow(Icons.location_city, 'Wilaya Anayohudumia', _district)],
                              if (_badge.isNotEmpty) ...[if (_district.isNotEmpty || _org.isNotEmpty) const Divider(height: 14), _InfoRow(Icons.numbers_outlined, 'Nambari ya Kitambulisho', _badge)],
                              if (_region.isNotEmpty) ...[const Divider(height: 14), _InfoRow(Icons.map_outlined, 'Mkoa', _region)],
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── Chat button ────────────────────────────────────
                        if (expertId != myId) ...[
                          ElevatedButton.icon(
                            onPressed: () => Navigator.push(context,
                                MaterialPageRoute(builder: (_) => ChatScreen(
                                  contactId:       expertId,
                                  contactName:     _name.isEmpty ? 'Afisa' : _name,
                                  contactRole:     role,
                                  contactColorHex: roleColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2),
                                ))),
                            icon: const Icon(Icons.chat_bubble_outline, size: 18),
                            label: Text(
                              _available
                                  ? 'Wasiliana Naye — Yuko Mtandaoni'
                                  : 'Wasiliana Naye — Atakujibu Baadaye',
                              style: GoogleFonts.dmSans(fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _available
                                  ? const Color(0xFF00695C)
                                  : Colors.grey.shade600,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(54),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Center(
                            child: Text(
                              _available
                                  ? '✅ Anapatikana kwa ushauri sasa hivi'
                                  : '⏰ Atakujibu hivi karibuni',
                              style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  color: _available ? AppColors.leaf : Colors.grey),
                            ),
                          ),
                        ],

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Profile header ────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final String name;
  final UserRole role;
  final String region;
  final String org;
  final String district;
  final bool available;
  final int consultCount;
  final bool loading;

  const _ProfileHeader({
    required this.name, required this.role, required this.region,
    required this.org, required this.district, required this.available,
    required this.consultCount, required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF004D40), Color(0xFF00695C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 52, 20, 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Availability dot + avatar
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'A',
                      style: GoogleFonts.playfairDisplay(
                          color: Colors.white, fontSize: 34,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (!loading)
                    Container(
                      width: 16, height: 16,
                      decoration: BoxDecoration(
                        color: available ? Colors.greenAccent : Colors.grey,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(name.isEmpty ? 'Afisa Kilimo' : name,
                  style: GoogleFonts.playfairDisplay(
                      color: Colors.white, fontSize: 20,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
              const SizedBox(height: 4),
              RoleChip(role, fontSize: 11),
              const SizedBox(height: 4),
              if (org.isNotEmpty)
                Text(org,
                    style: GoogleFonts.dmSans(
                        color: Colors.white70, fontSize: 12),
                    textAlign: TextAlign.center),
              if (district.isNotEmpty || region.isNotEmpty)
                Text('${district.isNotEmpty ? district : ''} • $region'.trim().replaceFirst(RegExp(r'^• '), '').replaceFirst(RegExp(r' • $'), ''),
                    style: GoogleFonts.dmSans(
                        color: Colors.white60, fontSize: 11)),
              const SizedBox(height: 12),
              // Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _HeaderStat(
                      value: available ? 'Mtandaoni' : 'Nje ya Mtandao',
                      label: 'Hali',
                      color: available ? Colors.greenAccent : Colors.grey.shade300),
                  const SizedBox(width: 24),
                  _HeaderStat(
                      value: '$consultCount',
                      label: 'Walioshauriwa',
                      color: Colors.white),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _HeaderStat({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(value,
              style: GoogleFonts.dmSans(
                  color: color, fontSize: 14,
                  fontWeight: FontWeight.bold)),
          Text(label,
              style: GoogleFonts.dmSans(
                  color: Colors.white54, fontSize: 10)),
        ],
      );
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  const _Section({required this.icon, required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: const Color(0xFF00695C)),
                  const SizedBox(width: 8),
                  Text(title,
                      style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 14, color: AppColors.soil)),
                ],
              ),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: AppColors.mid),
          const SizedBox(width: 8),
          Text('$label: ',
              style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.mid)),
          Expanded(
            child: Text(value,
                style: GoogleFonts.dmSans(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: AppColors.ink)),
          ),
        ],
      );
}

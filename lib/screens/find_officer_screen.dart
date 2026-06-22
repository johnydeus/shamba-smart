import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/location_service.dart';
import '../services/officer_service.dart';
import '../services/field_officer_service.dart';
import '../models/field_officer.dart';
import '../theme/app_colors.dart';
import 'officer_profile_detail_screen.dart';
import 'chat_screen.dart';
import '../models/user_model.dart';

class FindOfficerScreen extends StatefulWidget {
  const FindOfficerScreen({super.key});

  @override
  State<FindOfficerScreen> createState() => _FindOfficerScreenState();
}

class _FindOfficerScreenState extends State<FindOfficerScreen> {
  List<Map<String, dynamic>> _officers = [];
  List<Map<String, dynamic>> _broadcasts = [];
  Map<String, dynamic>? _linkedOfficer;
  bool _loading = true;
  String? _region;
  String _filterCrop = '';
  String _search = '';
  bool _showVerifiedOnly = false;
  bool _showVisitOnly = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final user = context.read<AuthProvider>().currentUser;

    final region =
        user?.region.isNotEmpty == true ? user!.region : 'Morogoro';
    _region = region;

    // Real, self-registered field officers (approved + pending) from Supabase
    // `field_officers`, offline-cached. Mapped to the keys the card already
    // reads, with the model stashed under '_model' for the Wasifu screen.
    final liveOfficers = await FieldOfficerService.directory();
    final officers = liveOfficers
        .map((o) => <String, dynamic>{
              'id': o.userId, // chat opens with the officer's user_id
              'user_id': o.userId,
              'full_name': o.fullName,
              'title': o.title,
              'primary_region': o.region,
              'is_verified': o.verified,
              'average_rating': o.rating,
              'total_ratings': o.ratingCount,
              'farmers_served': o.farmersServed,
              'response_time_hours': o.avgResponseHours,
              'farm_visit_available': o.visitFeeTzs != null,
              'farm_visit_cost_tzs': o.visitFeeTzs,
              'specialisation': o.crops,
              '_model': o,
            })
        .toList();

    final broadcasts =
        await OfficerService.getRegionalBroadcasts(region: region);

    Map<String, dynamic>? linked;
    if (user != null) {
      linked = await OfficerService.getLinkedOfficer(user.id);
    }

    if (mounted) {
      setState(() {
        _officers = officers;
        _broadcasts = broadcasts;
        _linkedOfficer = linked;
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filtered {
    var list = List<Map<String, dynamic>>.from(_officers);
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((o) {
        final name = (o['full_name'] as String? ?? '').toLowerCase();
        final specs =
            ((o['specialisation'] as List?)?.join(' ') ?? '').toLowerCase();
        return name.contains(q) || specs.contains(q);
      }).toList();
    }
    if (_showVerifiedOnly) {
      list = list.where((o) => (o['is_verified'] as bool?) == true).toList();
    }
    if (_showVisitOnly) {
      list = list
          .where((o) => (o['farm_visit_available'] as bool?) == true)
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6EE),
      appBar: AppBar(
        title: Text(
          'Wataalamu wa Kilimo',
          style: GoogleFonts.playfairDisplay(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.leaf))
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Region info
                    _buildRegionBanner(),
                    const SizedBox(height: 12),

                    // Linked officer card (primary)
                    if (_linkedOfficer != null) ...[
                      _buildLinkedOfficerCard(),
                      const SizedBox(height: 16),
                    ],

                    // Regional broadcasts
                    if (_broadcasts.isNotEmpty) ...[
                      _buildSectionHeader(
                          '📢 Matangazo ya Mkoa', Icons.campaign_outlined),
                      const SizedBox(height: 8),
                      ..._broadcasts.take(3).map(_buildBroadcastCard),
                      const SizedBox(height: 16),
                    ],

                    // Search + filters
                    _buildSearchBar(),
                    const SizedBox(height: 8),
                    _buildFilters(),
                    const SizedBox(height: 16),

                    // Officers list
                    _buildSectionHeader(
                      'Wataalamu katika ${_region ?? 'Mkoa Wako'}',
                      Icons.people_outlined,
                    ),
                    const SizedBox(height: 10),
                    if (_filtered.isEmpty)
                      _buildEmpty()
                    else
                      ..._filtered.map(_buildOfficerCard),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildRegionBanner() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.leaf.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.leaf.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.location_on, color: AppColors.leaf, size: 18),
            const SizedBox(width: 8),
            Text('Mkoa wako: ${_region ?? 'Haijulikani'}',
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: AppColors.leaf)),
          ],
        ),
      );

  Widget _buildLinkedOfficerCard() {
    final o = _linkedOfficer!;
    return Card(
      color: const Color(0xFFE8F5E9),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.verified_user,
                  color: AppColors.leaf, size: 18),
              const SizedBox(width: 8),
              Text('Mtaalamu Wako Mkuu',
                  style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.bold,
                      color: AppColors.leaf)),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              _officerAvatar(o),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(o['full_name'] as String? ?? '',
                        style: GoogleFonts.playfairDisplay(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(
                        '${o['title'] ?? ''} — ${o['primary_district'] ?? ''}',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey)),
                    _ratingRow(o),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: _actionButton(
                  '💬 Ujumbe',
                  AppColors.leaf,
                  () => _openChat(o),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _actionButton(
                  '👤 Wasifu',
                  const Color(0xFF1565C0),
                  () => _openProfile(o),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildBroadcastCard(Map<String, dynamic> b) {
    final priority = b['priority'] as String? ?? 'normal';
    final officerName =
        (b['agri_officers'] as Map?)?['full_name'] as String? ?? 'Afisa';
    final Color bgColor = priority == 'urgent'
        ? const Color(0xFFFFF3E0)
        : priority == 'emergency'
            ? const Color(0xFFFFEBEE)
            : const Color(0xFFE3F2FD);
    final Color borderColor = priority == 'urgent'
        ? Colors.orange
        : priority == 'emergency'
            ? Colors.red
            : const Color(0xFF1565C0);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            if (priority == 'urgent' || priority == 'emergency')
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(Icons.warning_amber_rounded,
                    color: borderColor, size: 16),
              ),
            Expanded(
              child: Text(b['title'] as String? ?? '',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: borderColor)),
            ),
          ]),
          const SizedBox(height: 6),
          Text(b['message'] as String? ?? '',
              style: const TextStyle(fontSize: 13, height: 1.4),
              maxLines: 3,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text('— $officerName',
              style:
                  const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildSearchBar() => TextField(
        onChanged: (v) => setState(() => _search = v),
        decoration: InputDecoration(
          hintText: 'Tafuta mtaalamu au utaalamu...',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        ),
      );

  Widget _buildFilters() => Wrap(
        spacing: 8,
        children: [
          FilterChip(
            label: const Text('✅ Waliothibitishwa'),
            selected: _showVerifiedOnly,
            onSelected: (v) => setState(() => _showVerifiedOnly = v),
            selectedColor: AppColors.leaf.withValues(alpha: 0.2),
          ),
          FilterChip(
            label: const Text('🏡 Wanaofanya Ziara'),
            selected: _showVisitOnly,
            onSelected: (v) => setState(() => _showVisitOnly = v),
            selectedColor: AppColors.leaf.withValues(alpha: 0.2),
          ),
        ],
      );

  Widget _buildSectionHeader(String title, IconData icon) => Row(
        children: [
          Icon(icon, color: AppColors.soil, size: 18),
          const SizedBox(width: 8),
          Text(title,
              style: GoogleFonts.playfairDisplay(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.soil)),
        ],
      );

  Widget _buildOfficerCard(Map<String, dynamic> o) {
    final isVerified = (o['is_verified'] as bool?) == true;
    final canVisit = (o['farm_visit_available'] as bool?) == true;
    final specs = ((o['specialisation'] as List?)?.cast<String>() ?? [])
        .take(3)
        .toList();
    final responseHours = (o['response_time_hours'] as num?)?.toDouble();
    final farmersServed = (o['farmers_served'] as num?)?.toInt() ?? 0;
    // New officers have no track record yet — render gracefully.
    final isNew = ((o['total_ratings'] as num?)?.toInt() ?? 0) == 0 &&
        farmersServed == 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _officerAvatar(o),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                          child: Text(o['full_name'] as String? ?? '',
                              style: GoogleFonts.playfairDisplay(
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                        if (isVerified)
                          const Tooltip(
                            message: 'Imethibitishwa',
                            child: Icon(Icons.verified,
                                color: Color(0xFF1565C0), size: 18),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('Inasubiri uthibitisho',
                                style: TextStyle(
                                    fontSize: 9.5,
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w600)),
                          ),
                      ]),
                      Text(
                          '${o['title'] ?? 'Mtaalamu'} — ${o['primary_region'] ?? ''}',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 4),
                      _ratingRow(o),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Stats row
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                _statChip(Icons.people_outline,
                    isNew ? 'Mpya' : '$farmersServed wakulima'),
                _statChip(
                    Icons.timer_outlined,
                    responseHours == null
                        ? 'Hujibu —'
                        : 'Hujibu ${_formatResponseTime(responseHours)}'),
                if (canVisit)
                  _statChip(Icons.directions_walk,
                      'TZS ${_fmt(o['farm_visit_cost_tzs'])} ziara'),
              ],
            ),

            // Specialities
            if (specs.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: specs
                    .map((s) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.leaf.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(s,
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.leaf,
                                  fontWeight: FontWeight.w600)),
                        ))
                    .toList(),
              ),
            ],

            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: _actionButton(
                    '📩 Tuma Ujumbe', AppColors.harvest, () => _openChat(o)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _actionButton(
                    '👤 Wasifu', const Color(0xFF1565C0),
                    () => _openProfile(o)),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const Text('🌿', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text('Hakuna wataalamu wanaopatikana sasa',
                  style: GoogleFonts.playfairDisplay(
                      color: AppColors.soil, fontSize: 16)),
              const SizedBox(height: 8),
              Text('Tutawasiliana nawe wataalamu watakapoandikishwa '
                  'katika mkoa wako.',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );

  // ── Sub-widgets ────────────────────────────────────────────────────────────

  Widget _officerAvatar(Map<String, dynamic> o) {
    final name = o['full_name'] as String? ?? '?';
    return CircleAvatar(
      radius: 26,
      backgroundColor: const Color(0xFF00695C).withValues(alpha: 0.1),
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF00695C)),
      ),
    );
  }

  Widget _ratingRow(Map<String, dynamic> o) {
    final rating = (o['average_rating'] as num?)?.toDouble() ?? 0.0;
    final count = (o['total_ratings'] as num?)?.toInt() ?? 0;
    // No ratings yet → show "Mpya" instead of "0.0 (0)".
    if (count == 0) {
      return Row(
        children: [
          Icon(Icons.fiber_new_outlined, color: AppColors.mid, size: 14),
          const SizedBox(width: 3),
          const Text('Mpya',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      );
    }
    return Row(
      children: [
        const Icon(Icons.star, color: Color(0xFFFFB300), size: 14),
        const SizedBox(width: 3),
        Text('${rating.toStringAsFixed(1)} ($count)',
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _statChip(IconData icon, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.mid),
          const SizedBox(width: 3),
          Text(label,
              style: const TextStyle(fontSize: 11, color: AppColors.mid)),
        ],
      );

  Widget _actionButton(String label, Color color, VoidCallback onTap) =>
      ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withValues(alpha: 0.1),
          foregroundColor: color,
          elevation: 0,
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: color.withValues(alpha: 0.3))),
        ),
        child: Text(label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center),
      );

  String _formatResponseTime(double hours) {
    if (hours < 1) return '< saa 1';
    if (hours == 1) return 'saa 1';
    if (hours < 24) return 'masaa ${hours.round()}';
    return 'siku 1+';
  }

  String _fmt(dynamic val) {
    final n = (val as num?)?.toInt() ?? 0;
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}K';
    return n.toString();
  }

  void _openProfile(Map<String, dynamic> officer) {
    final model = officer['_model'] as FieldOfficer;
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => OfficerProfileDetailScreen(officer: model)),
    );
  }

  void _openChat(Map<String, dynamic> officer) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          contactId: officer['id'] as String,
          contactName: officer['full_name'] as String? ?? 'Mtaalamu',
          contactRole: UserRole.afisa,
          contactColorHex: '00695C',
        ),
      ),
    );
  }
}

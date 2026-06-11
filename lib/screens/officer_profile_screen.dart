import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../services/officer_service.dart';
import '../theme/app_colors.dart';
import 'chat_screen.dart';

class OfficerProfileScreen extends StatefulWidget {
  final Map<String, dynamic> officer;
  const OfficerProfileScreen({super.key, required this.officer});

  @override
  State<OfficerProfileScreen> createState() => _OfficerProfileScreenState();
}

class _OfficerProfileScreenState extends State<OfficerProfileScreen> {
  int _userRating = 0;
  bool _ratingSubmitted = false;
  bool _submittingRating = false;

  Future<void> _submitRating(int rating) async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;
    setState(() => _submittingRating = true);
    await OfficerService.rateOfficer(
      farmerId: user.id,
      officerId: widget.officer['id'] as String,
      rating: rating,
    );
    setState(() {
      _userRating = rating;
      _ratingSubmitted = true;
      _submittingRating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.officer;
    final isVerified = (o['is_verified'] as bool?) == true;
    final canVisit = (o['farm_visit_available'] as bool?) == true;
    final specs =
        ((o['specialisation'] as List?)?.cast<String>() ?? []);
    final rating = (o['average_rating'] as num?)?.toDouble() ?? 0.0;
    final ratingCount = (o['total_ratings'] as int?) ?? 0;
    final bio = o['bio'] as String? ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFFDF6EE),
      appBar: AppBar(
        title: Text('Wasifu wa Mtaalamu',
            style: GoogleFonts.playfairDisplay(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Header ───────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF00695C), Color(0xFF004D40)],
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: Text(
                      (o['full_name'] as String? ?? '?')[0].toUpperCase(),
                      style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(o['full_name'] as String? ?? '',
                      style: GoogleFonts.playfairDisplay(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(o['title'] as String? ?? '',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13)),
                  if (isVerified) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified,
                              color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text('Imethibitishwa',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  // Rating stars
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ...List.generate(
                          5,
                          (i) => Icon(
                                i < rating.round()
                                    ? Icons.star
                                    : Icons.star_border,
                                color: const Color(0xFFFFB300),
                                size: 20,
                              )),
                      const SizedBox(width: 8),
                      Text('$rating ($ratingCount)',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── About ──────────────────────────────────────────────
                  if (bio.isNotEmpty) ...[
                    _card(Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle('Kuhusu'),
                        const SizedBox(height: 8),
                        Text(bio,
                            style: const TextStyle(
                                fontSize: 14, height: 1.5)),
                      ],
                    )),
                    const SizedBox(height: 12),
                  ],

                  // ── Details ────────────────────────────────────────────
                  _card(Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('Maelezo'),
                      const SizedBox(height: 10),
                      _detailRow(Icons.account_balance_outlined, 'Mwajiri',
                          o['employer'] as String? ?? '—'),
                      _detailRow(Icons.school_outlined, 'Elimu',
                          o['qualification'] as String? ?? '—'),
                      _detailRow(Icons.location_on_outlined, 'Wilaya',
                          '${o['primary_district'] ?? ''}, ${o['primary_region'] ?? ''}'),
                      _detailRow(Icons.people_outline, 'Wakulima Waliosaidiwa',
                          '${o['farmers_served'] ?? 0}'),
                      _detailRow(Icons.timer_outlined, 'Wakati wa Kujibu',
                          _formatTime(
                              (o['response_time_hours'] as num?)?.toDouble())),
                    ],
                  )),
                  const SizedBox(height: 12),

                  // ── Specialisations ────────────────────────────────────
                  if (specs.isNotEmpty) ...[
                    _card(Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle('Utaalamu'),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: specs
                              .map((s) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF00695C)
                                          .withValues(alpha: 0.08),
                                      borderRadius:
                                          BorderRadius.circular(20),
                                      border: Border.all(
                                          color: const Color(0xFF00695C)
                                              .withValues(alpha: 0.3)),
                                    ),
                                    child: Text(s,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF00695C),
                                            fontWeight: FontWeight.w600)),
                                  ))
                              .toList(),
                        ),
                      ],
                    )),
                    const SizedBox(height: 12),
                  ],

                  // ── Contact / Actions ──────────────────────────────────
                  _card(Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('Wasiliana'),
                      const SizedBox(height: 12),
                      _contactButton(
                          Icons.message_outlined,
                          '📩 Tuma Ujumbe',
                          const Color(0xFF00695C),
                          () => _openChat()),
                      if (canVisit) ...[
                        const SizedBox(height: 8),
                        _contactButton(
                            Icons.directions_walk_outlined,
                            '🏡 Omba Ziara ya Shamba  •  TZS ${_fmt(o['farm_visit_cost_tzs'])}',
                            const Color(0xFF1565C0),
                            () => _requestVisit()),
                      ],
                    ],
                  )),
                  const SizedBox(height: 12),

                  // ── Rate this officer ──────────────────────────────────
                  _card(Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('Tathmini Mtaalamu Huyu'),
                      const SizedBox(height: 4),
                      const Text(
                          'Tathmini yako itasaidia wakulima wengine.',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 12),
                      if (_ratingSubmitted)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.check_circle,
                                  color: Colors.green, size: 18),
                              SizedBox(width: 8),
                              Text('Asante! Tathmini yako imepokewa.',
                                  style: TextStyle(color: Colors.green)),
                            ],
                          ),
                        )
                      else
                        Row(
                          children: [
                            ...List.generate(
                              5,
                              (i) => GestureDetector(
                                onTap: () => _submittingRating
                                    ? null
                                    : _submitRating(i + 1),
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: Icon(
                                    i < _userRating
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: const Color(0xFFFFB300),
                                    size: 32,
                                  ),
                                ),
                              ),
                            ),
                            if (_submittingRating)
                              const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2)),
                          ],
                        ),
                    ],
                  )),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(Widget child) => Card(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 1,
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      );

  Widget _sectionTitle(String title) => Text(title,
      style: GoogleFonts.playfairDisplay(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: AppColors.soil));

  Widget _detailRow(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey),
            const SizedBox(width: 8),
            Text('$label: ',
                style:
                    const TextStyle(color: Colors.grey, fontSize: 12)),
            Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
            ),
          ],
        ),
      );

  Widget _contactButton(
      IconData icon, String label, Color color, VoidCallback onTap) =>
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 18),
          label: Text(label),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );

  void _openChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          contactId: widget.officer['id'] as String,
          contactName:
              widget.officer['full_name'] as String? ?? 'Mtaalamu',
          contactRole: UserRole.afisa,
          contactColorHex: '00695C',
        ),
      ),
    );
  }

  void _requestVisit() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text(
          'Ombi la ziara limetumwa! Mtaalamu atawasiliana nawe hivi karibuni.'),
      backgroundColor: Color(0xFF00695C),
    ));
  }

  String _formatTime(double? hours) {
    if (hours == null) return '—';
    if (hours < 1) return '< saa 1';
    if (hours < 24) return 'masaa ${hours.round()}';
    return 'siku 1+';
  }

  String _fmt(dynamic val) {
    final n = (val as num?)?.toInt() ?? 0;
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}K';
    return n.toString();
  }
}

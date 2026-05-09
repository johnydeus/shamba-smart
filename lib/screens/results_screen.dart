import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../theme/app_colors.dart';
import 'chat_screen.dart';
import 'home_screen.dart';
import 'scan_screen.dart';

class ResultsScreen extends StatefulWidget {
  final Map<String, dynamic> diagnosis;
  final String imagePath;
  final String cropName;

  const ResultsScreen({
    super.key,
    required this.diagnosis,
    required this.imagePath,
    required this.cropName,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  bool _treatmentExpanded = false;

  String _confidenceLabel(double conf) {
    if (conf >= 0.90) return 'AI ina uhakika mkubwa sana';
    if (conf >= 0.75) return 'AI ina uhakika wa kutosha';
    if (conf >= 0.55) return 'AI ina uhakika wa wastani';
    return 'AI hana uhakika wa kutosha';
  }

  String _scanTypeLabel(String? t) {
    switch (t) {
      case 'wadudu':
        return 'Wadudu / Pest';
      case 'magugu':
        return 'Gugu / Weed';
      default:
        return 'Ugonjwa / Disease';
    }
  }

  IconData _scanTypeIcon(String? t) {
    switch (t) {
      case 'wadudu':
        return Icons.pest_control;
      case 'magugu':
        return Icons.grass;
      default:
        return Icons.biotech;
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.diagnosis;
    final hasError = d['error'] == true;
    final isHealthy = d['is_healthy'] == true;

    return Scaffold(
      backgroundColor: AppColors.mist,
      appBar: AppBar(
        title: Text(
          'Matokeo ya Uchunguzi',
          style: GoogleFonts.playfairDisplay(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF1A5C2E),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Photo ──────────────────────────────────────────────────────
            if (widget.imagePath.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(widget.imagePath),
                  height: 220,
                  fit: BoxFit.cover,
                ),
              ),

            const SizedBox(height: 16),

            // ── Error ───────────────────────────────────────────────────────
            if (hasError)
              _card(
                color: const Color(0xFFB71C1C),
                child: Text(
                  d['message'] ?? 'Hitilafu isiyojulikana.',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 15),
                  textAlign: TextAlign.center,
                ),
              ),

            // ── Healthy ─────────────────────────────────────────────────────
            if (!hasError && isHealthy)
              _card(
                color: const Color(0xFF2E8B57),
                child: const Column(children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 48),
                  SizedBox(height: 8),
                  Text(
                    'Mmea Wako Unaonekana Mzima!',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ]),
              ),

            // ── Disease / Pest / Weed results ───────────────────────────────
            if (!hasError && !isHealthy) ..._buildDiseaseBody(d),

            const SizedBox(height: 24),

            // ── Action buttons ──────────────────────────────────────────────
            ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: const Text('Piga Picha Nyingine'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A5C2E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const ScanScreen()),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.home),
              label: const Text('Rudi Nyumbani'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1A5C2E),
                side: const BorderSide(color: Color(0xFF1A5C2E)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (r) => false,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDiseaseBody(Map<String, dynamic> d) {
    final diseaseSw = (d['disease_name_sw'] as String?) ?? '';
    final diseaseEn = (d['disease_name_en'] as String?) ?? '';
    final scanType = (d['scan_type'] as String?) ?? 'ugonjwa';
    final confidence = (d['confidence'] as num?)?.toDouble() ?? 0.0;
    final cropName = (d['affected_crop'] as String?) ?? widget.cropName;
    final description = (d['description_sw'] as String?) ?? '';
    final cause = (d['cause_sw'] as String?) ?? '';
    final actionSw = (d['immediate_action_sw'] as String?) ?? '';
    final chemical = (d['chemical_treatment'] as String?) ?? '';
    final biological = (d['biological_treatment'] as String?) ?? '';
    final prevention = (d['prevention_treatment'] as String?) ?? '';

    final hasTreatment =
        chemical.isNotEmpty || biological.isNotEmpty || prevention.isNotEmpty;

    return [
      // ── 1. Identification card ──────────────────────────────────────────
      Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Crop
              Row(children: [
                const Icon(Icons.eco, color: Color(0xFF2E7D32), size: 18),
                const SizedBox(width: 6),
                Text('Zao:',
                    style: GoogleFonts.dmSans(
                        color: Colors.grey[600], fontSize: 13)),
                const SizedBox(width: 6),
                Text(cropName,
                    style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.bold, fontSize: 14)),
              ]),
              const SizedBox(height: 8),
              // Scan type
              Row(children: [
                Icon(_scanTypeIcon(scanType),
                    color: const Color(0xFF1A5C2E), size: 18),
                const SizedBox(width: 6),
                Text('Aina ya tatizo:',
                    style: GoogleFonts.dmSans(
                        color: Colors.grey[600], fontSize: 13)),
                const SizedBox(width: 6),
                Text(_scanTypeLabel(scanType),
                    style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.bold, fontSize: 13)),
              ]),
              const Divider(height: 20),
              // Disease name
              Text('Tatizo Lililogunduliwa:',
                  style: GoogleFonts.dmSans(
                      color: Colors.grey[600], fontSize: 12)),
              const SizedBox(height: 4),
              Text(
                diseaseSw.isNotEmpty ? diseaseSw : 'Haijulikani',
                style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1A1A)),
              ),
              if (diseaseEn.isNotEmpty && diseaseEn != diseaseSw)
                Text(diseaseEn,
                    style: GoogleFonts.dmSans(
                        color: Colors.grey[500], fontSize: 13,
                        fontStyle: FontStyle.italic)),
            ],
          ),
        ),
      ),

      const SizedBox(height: 12),

      // ── 2. Confidence card ──────────────────────────────────────────────
      Card(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.analytics_outlined,
                    color: Color(0xFF1A5C2E), size: 16),
                const SizedBox(width: 6),
                Text('Uhakika wa Utambuzi',
                    style: GoogleFonts.dmSans(
                        color: const Color(0xFF1A5C2E),
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Text('${(confidence * 100).toStringAsFixed(0)}%',
                    style: GoogleFonts.dmSans(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A5C2E))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LinearProgressIndicator(
                        value: confidence,
                        color: const Color(0xFF1A5C2E),
                        backgroundColor: const Color(0xFFE8F5E9),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _confidenceLabel(confidence),
                        style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ]),
              if (confidence < 0.70) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(children: [
                    const Icon(Icons.info_outline,
                        color: Colors.orange, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Uhakika ni mdogo — thibitisha na afisa kilimo.',
                        style: GoogleFonts.dmSans(
                            fontSize: 11, color: Colors.orange[800]),
                      ),
                    ),
                  ]),
                ),
              ],
            ],
          ),
        ),
      ),

      const SizedBox(height: 12),

      // ── 3. Description ──────────────────────────────────────────────────
      if (description.isNotEmpty)
        _sectionCard(
          icon: Icons.info_outline,
          title: 'Maelezo',
          color: const Color(0xFF1A5C2E),
          child: Text(description,
              style: GoogleFonts.dmSans(fontSize: 14, height: 1.5)),
        ),

      // ── 4. Cause ────────────────────────────────────────────────────────
      if (cause.isNotEmpty) ...[
        const SizedBox(height: 12),
        _sectionCard(
          icon: Icons.help_outline,
          title: 'Sababu ya Tatizo',
          color: const Color(0xFF6A1B9A),
          child: Text(cause,
              style: GoogleFonts.dmSans(fontSize: 14, height: 1.5)),
        ),
      ],

      const SizedBox(height: 12),

      // ── 5. Immediate action ─────────────────────────────────────────────
      if (actionSw.isNotEmpty)
        _card(
          color: const Color(0xFFFF6F00),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.warning_amber,
                    color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('Fanya Sasa Hivi:',
                    style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
              ]),
              const SizedBox(height: 8),
              Text(actionSw,
                  style: GoogleFonts.dmSans(
                      color: Colors.white, fontSize: 14, height: 1.4)),
            ],
          ),
        ),

      const SizedBox(height: 12),

      // ── 6. Treatment expandable ─────────────────────────────────────────
      if (hasTreatment)
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () =>
                setState(() => _treatmentExpanded = !_treatmentExpanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header button
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A5C2E)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.medication,
                            color: Color(0xFF1A5C2E), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Mapendekezo ya Dawa',
                          style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: const Color(0xFF1A5C2E)),
                        ),
                      ),
                      Icon(
                        _treatmentExpanded
                            ? Icons.expand_less
                            : Icons.expand_more,
                        color: const Color(0xFF1A5C2E),
                      ),
                    ],
                  ),

                  // Expanded content
                  if (_treatmentExpanded) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),

                    if (chemical.isNotEmpty) ...[
                      _treatmentSection(
                        icon: Icons.science,
                        title: 'Dawa ya Kemikali',
                        text: chemical,
                        color: const Color(0xFFB71C1C),
                      ),
                      const SizedBox(height: 12),
                    ],

                    if (biological.isNotEmpty) ...[
                      _treatmentSection(
                        icon: Icons.eco,
                        title: 'Dawa ya Asili / Kibiolojia',
                        text: biological,
                        color: const Color(0xFF2E7D32),
                      ),
                      const SizedBox(height: 12),
                    ],

                    if (prevention.isNotEmpty)
                      _treatmentSection(
                        icon: Icons.shield,
                        title: 'Kinga na Uzuiaji',
                        text: prevention,
                        color: const Color(0xFF1565C0),
                      ),
                  ],
                ],
              ),
            ),
          ),
        )
      else
        // No treatment data — show advice
        _card(
          color: const Color(0xFF37474F),
          child: Row(children: [
            const Icon(Icons.tips_and_updates,
                color: Colors.white70, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Wasiliana na mtaalamu wa kilimo au duka la pembejeo karibu nawe kwa ushauri zaidi wa dawa.',
                style: GoogleFonts.dmSans(
                    color: Colors.white, fontSize: 13, height: 1.4),
              ),
            ),
          ]),
        ),

      // ── Consult buttons ─────────────────────────────────────────────────
      const SizedBox(height: 20),
      Row(children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text('Omba Msaada',
              style: GoogleFonts.dmSans(
                  color: Colors.grey[500], fontSize: 12)),
        ),
        const Expanded(child: Divider()),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(
          child: _consultBtn(
            icon: Icons.agriculture,
            label: 'Afisa Kilimo',
            subtitle: 'Omba ushauri',
            color: const Color(0xFF00695C),
            onTap: () => _showContactSheet(
              context: context,
              diagnosis: d,
              role: UserRole.afisa,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _consultBtn(
            icon: Icons.storefront,
            label: 'Duka la Dawa',
            subtitle: 'Tafuta dawa',
            color: const Color(0xFF1565C0),
            onTap: () => _showContactSheet(
              context: context,
              diagnosis: d,
              role: UserRole.duka,
            ),
          ),
        ),
      ]),
    ];
  }

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required Color color,
    required Widget child,
  }) {
    return Card(
      elevation: 1,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(title,
                  style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontSize: 14)),
            ]),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }

  Widget _treatmentSection({
    required IconData icon,
    required String title,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(title,
                style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 13)),
          ]),
          const SizedBox(height: 6),
          Text(text,
              style: GoogleFonts.dmSans(
                  fontSize: 13, height: 1.5, color: AppColors.soil)),
        ],
      ),
    );
  }

  Widget _card({required Color color, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }

  // ── Consult button widget ─────────────────────────────────────────────────

  Widget _consultBtn({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(label,
                  style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: color)),
              Text(subtitle,
                  style: GoogleFonts.dmSans(
                      fontSize: 11, color: Colors.grey[600])),
            ],
          ),
        ),
      ),
    );
  }

  // ── Contact bottom sheet (Afisa or Duka) ─────────────────────────────────

  void _showContactSheet({
    required BuildContext context,
    required Map<String, dynamic> diagnosis,
    required UserRole role,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ContactSheet(
        diagnosis: diagnosis,
        role: role,
        imagePath: widget.imagePath,
      ),
    );
  }
}

// ── Contact Sheet ─────────────────────────────────────────────────────────────

class _ContactSheet extends StatefulWidget {
  final Map<String, dynamic> diagnosis;
  final UserRole role;
  final String imagePath;

  const _ContactSheet({
    required this.diagnosis,
    required this.role,
    required this.imagePath,
  });

  @override
  State<_ContactSheet> createState() => _ContactSheetState();
}

class _ContactSheetState extends State<_ContactSheet> {
  List<Map<String, dynamic>> _contacts = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rows = await Supabase.instance.client
          .from('profiles')
          .select('id, first_name, last_name, region, role, shop_name, organization, district')
          .eq('role', widget.role.key)
          .order('first_name')
          .limit(50);
      setState(() {
        _contacts = List<Map<String, dynamic>>.from(rows);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Hitilafu ya kupakia orodha.';
        _loading = false;
      });
    }
  }

  String _formatMessage() {
    final d = widget.diagnosis;
    final disease = d['disease_name_sw'] ?? d['disease_name_en'] ?? 'Haijulikani';
    final crop = d['affected_crop'] ?? '';
    final conf = ((d['confidence'] as num? ?? 0) * 100).round();
    final severity = _severityLabel(d['severity'] ?? '');
    final desc = (d['description_sw'] as String? ?? '').isNotEmpty
        ? '\nMaelezo: ${d['description_sw']}'
        : '';
    final cause = (d['cause_sw'] as String? ?? '').isNotEmpty
        ? '\nSababu: ${d['cause_sw']}'
        : '';
    final action = (d['immediate_action_sw'] as String? ?? '').isNotEmpty
        ? '\nHatua ya haraka: ${d['immediate_action_sw']}'
        : '';
    final req = widget.role == UserRole.duka
        ? 'Naomba ujulishe kama una dawa inayofaa na bei yake, au mbadala unaoweza kupendekeza.'
        : 'Naomba ushauri wa kitaalamu kuhusu matibabu sahihi na jinsi ya kuzuia tatizo hili.';

    return '🌾 OMBI LA USHAURI — MATOKEO YA UCHUNGUZI\n'
        '─────────────────────────────\n'
        'Zao: $crop\n'
        'Tatizo: $disease\n'
        'Uhakika: $conf% | Ukali: $severity'
        '$desc$cause$action\n'
        '─────────────────────────────\n'
        '$req';
  }

  String _severityLabel(String s) {
    switch (s.toLowerCase()) {
      case 'low': return 'Chini';
      case 'medium': return 'Wastani';
      case 'high': return 'Juu';
      case 'critical': return 'Hatari Sana';
      default: return s;
    }
  }

  void _openChat(Map<String, dynamic> contact) {
    final role = UserRoleX.fromKey(contact['role'] as String? ?? 'mkulima');
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          contactId: contact['id'] as String,
          contactName: _contactName(contact),
          contactRole: role,
          contactColorHex: role.colorHex.replaceFirst('#', ''),
          initialMessage: _formatMessage(),
        ),
      ),
    );
  }

  String _contactName(Map<String, dynamic> c) {
    final first = (c['first_name'] as String? ?? '').trim();
    final last = (c['last_name'] as String? ?? '').trim();
    final shop = c['shop_name'] as String?;
    if (shop != null && shop.isNotEmpty) return shop;
    return '$first $last'.trim();
  }

  String _contactSub(Map<String, dynamic> c) {
    final parts = <String>[];
    final org = c['organization'] as String?;
    final district = c['district'] as String?;
    final region = c['region'] as String?;
    if (org != null && org.isNotEmpty) parts.add(org);
    if (district != null && district.isNotEmpty) parts.add(district);
    if (region != null && region.isNotEmpty) parts.add(region);
    return parts.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    final isAfisa = widget.role == UserRole.afisa;
    final color = isAfisa ? const Color(0xFF00695C) : const Color(0xFF1565C0);
    final title = isAfisa ? 'Chagua Afisa Kilimo' : 'Chagua Duka la Dawa';
    final icon = isAfisa ? Icons.agriculture : Icons.storefront;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 10),
                Text(title,
                    style: GoogleFonts.playfairDisplay(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color)),
              ]),
            ),
            const Divider(height: 1),
            // Body
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Text(_error!,
                              style: GoogleFonts.dmSans(color: Colors.red)))
                      : _contacts.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  isAfisa
                                      ? 'Hakuna afisa kilimo waliojisajili bado katika mfumo huu.'
                                      : 'Hakuna maduka ya dawa yaliyojisajili bado katika mfumo huu.',
                                  style: GoogleFonts.dmSans(
                                      color: Colors.grey[600], fontSize: 14),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                          : ListView.separated(
                              controller: ctrl,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              itemCount: _contacts.length,
                              separatorBuilder: (context2, i2) =>
                                  const Divider(height: 1),
                              itemBuilder: (_, i) {
                                final c = _contacts[i];
                                final name = _contactName(c);
                                final sub = _contactSub(c);
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        color.withValues(alpha: 0.15),
                                    child: Text(
                                      name.isNotEmpty
                                          ? name[0].toUpperCase()
                                          : '?',
                                      style: TextStyle(
                                          color: color,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  title: Text(name,
                                      style: GoogleFonts.dmSans(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14)),
                                  subtitle: sub.isNotEmpty
                                      ? Text(sub,
                                          style: GoogleFonts.dmSans(
                                              fontSize: 12,
                                              color: Colors.grey[600]))
                                      : null,
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: color,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text('Wasiliana',
                                        style: GoogleFonts.dmSans(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                  onTap: () => _openChat(c),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

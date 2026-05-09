import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
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

  Color _severityColor(String s) {
    switch (s.toLowerCase()) {
      case 'high':
      case 'critical':
        return const Color(0xFFB71C1C);
      case 'medium':
        return const Color(0xFFFF6F00);
      default:
        return const Color(0xFF2E8B57);
    }
  }

  String _severityLabel(String s) {
    switch (s.toLowerCase()) {
      case 'low':
        return 'Chini';
      case 'medium':
        return 'Wastani';
      case 'high':
        return 'Juu';
      case 'critical':
        return 'Hatari Sana';
      default:
        return s;
    }
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
    final severity = (d['severity'] as String?) ?? 'low';
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

      // ── 2. Confidence + Severity ────────────────────────────────────────
      Row(children: [
        Expanded(
          child: Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(children: [
                Text('Uhakika',
                    style: GoogleFonts.dmSans(
                        color: Colors.grey[600], fontSize: 12)),
                const SizedBox(height: 8),
                Text('${(confidence * 100).toStringAsFixed(0)}%',
                    style: GoogleFonts.dmSans(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A5C2E))),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: confidence,
                  color: const Color(0xFF1A5C2E),
                  backgroundColor: const Color(0xFFE8F5E9),
                ),
              ]),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(children: [
                Text('Ukali',
                    style: GoogleFonts.dmSans(
                        color: Colors.grey[600], fontSize: 12)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: _severityColor(severity)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _severityLabel(severity),
                    style: GoogleFonts.dmSans(
                        color: _severityColor(severity),
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ]),

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
}

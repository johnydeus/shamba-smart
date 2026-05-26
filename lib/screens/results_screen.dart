import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../routes/fade_slide_route.dart';
import '../services/mkulima_service.dart';
import '../theme/app_theme.dart';
import '../widgets/shamba_button.dart';
import '../widgets/status_badge.dart';
import '../widgets/shamba_card.dart';
import 'home_screen.dart';
import 'scan_screen.dart';

class ResultsScreen extends StatefulWidget {
  final Map<String, dynamic> diagnosis;
  final String imagePath;
  final String cropName;
  final MkulimaResult? mkulimaResult;

  const ResultsScreen({
    super.key,
    required this.diagnosis,
    required this.imagePath,
    required this.cropName,
    this.mkulimaResult,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  bool _aiExpanded = false;

  Color _severityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'low':
        return AppColors.success;
      case 'medium':
        return AppColors.warning;
      case 'high':
        return AppColors.warningLight;
      case 'critical':
        return AppColors.critical;
      default:
        return AppColors.textTertiary;
    }
  }

  String _severityLabel(String severity) {
    switch (severity.toLowerCase()) {
      case 'low':
        return 'Chini';
      case 'medium':
        return 'Wastani';
      case 'high':
        return 'Juu';
      case 'critical':
        return 'Hatari Sana';
      default:
        return severity;
    }
  }

  Future<void> _shareWhatsApp() async {
    final d = widget.diagnosis;
    final text = Uri.encodeComponent(
      '🌿 Shamba Smart — Uchunguzi\n'
      'Zao: ${widget.cropName}\n'
      'Ugonjwa: ${d['disease_name_sw'] ?? '—'}\n'
      'Uhakika: ${(((d['confidence'] ?? 0.0) as double) * 100).toStringAsFixed(0)}%\n'
      'Hatua: ${d['immediate_action_sw'] ?? '—'}',
    );
    final uri = Uri.parse('https://wa.me/?text=$text');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final diagnosis = widget.diagnosis;
    final hasError = diagnosis['error'] == true;
    final isHealthy = diagnosis['is_healthy'] == true;

    final diseaseSw =
        diagnosis['disease_name_sw'] ?? 'Ugonjwa haujulikani';
    final diseaseEn = diagnosis['disease_name_en'] ?? '';
    final confidence = (diagnosis['confidence'] ?? 0.0) as double;
    final severity = diagnosis['severity'] ?? 'low';
    final descriptionSw = diagnosis['description_sw'] ?? '';
    final actionSw = diagnosis['immediate_action_sw'] ?? '';
    final pest1Name = diagnosis['pesticide_1_name'] ?? '';
    final pest1Dose = diagnosis['pesticide_1_dose'] ?? '';
    final pest2Name = diagnosis['pesticide_2_name'] ?? '';
    final pest2Dose = diagnosis['pesticide_2_dose'] ?? '';
    final daysCritical = diagnosis['days_until_critical'] ?? 0;
    final preventionSw = diagnosis['prevention_sw'] as String? ?? '';
    final threatType = diagnosis['threat_type'] as String? ?? '';
    final phiDays = diagnosis['phi_days'];

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Matokeo ya Uchunguzi'),
        automaticallyImplyLeading: false,
        actions: [
          if (!hasError && !isHealthy)
            IconButton(
              icon: const Icon(Icons.share_outlined),
              onPressed: _shareWhatsApp,
              tooltip: 'Shiriki WhatsApp',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.imagePath.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: Image.file(
                  File(widget.imagePath),
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ).animate().fadeIn(duration: 400.ms),

            const SizedBox(height: AppSpacing.md),

            // ── Mkulima AI card (shown only for disease scans) ────────────
            if (widget.mkulimaResult != null)
              _MkulimaCard(result: widget.mkulimaResult!),

            if (widget.mkulimaResult != null)
              const SizedBox(height: AppSpacing.md),

            if (hasError)
              _AlertBanner(
                color: AppColors.critical,
                child: Text(
                  diagnosis['message'] ?? 'Hitilafu isiyojulikana.',
                  style: GoogleFonts.poppins(
                    color: AppColors.white,
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            if (!hasError && isHealthy)
              _AlertBanner(
                color: AppColors.success,
                child: Column(
                  children: [
                    const Icon(Icons.check_circle_outline,
                        color: AppColors.white, size: 48),
                    const SizedBox(height: 8),
                    Text(
                      'Mmea Wako Unaonekana Mzima! 🌿',
                      style: GoogleFonts.poppins(
                        color: AppColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

            if (!hasError && !isHealthy) ...[
              _DiseaseGradientBanner(
                diseaseSw: diseaseSw,
                diseaseEn: diseaseEn,
                confidence: confidence,
                severity: severity,
                severityLabel: _severityLabel(severity.toString()),
                severityColor: _severityColor(severity.toString()),
              ),

              if (descriptionSw.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                ShambaCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Maelezo',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        descriptionSw,
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],

              if (actionSw.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                _AlertBanner(
                  color: AppColors.warning,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.warning_amber_outlined,
                              color: AppColors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Fanya Sasa Hivi',
                            style: GoogleFonts.poppins(
                              color: AppColors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        actionSw,
                        style: GoogleFonts.poppins(
                          color: AppColors.white,
                          fontSize: 14,
                        ),
                      ),
                      if (daysCritical > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Hatari ndani ya siku $daysCritical',
                            style: GoogleFonts.poppins(
                              color: AppColors.white.withValues(alpha: 0.9),
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],

              if (pest1Name.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                _TreatmentCard(
                  title: 'Dawa ya Kwanza',
                  name: pest1Name,
                  dose: pest1Dose,
                  borderColor: AppColors.primary,
                  phiDays: phiDays,
                  isPrimary: true,
                ),
                if (pest2Name.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _TreatmentCard(
                    title: 'Dawa Mbadala',
                    name: pest2Name,
                    dose: pest2Dose,
                    borderColor: AppColors.info,
                    isPrimary: false,
                  ),
                ],
              ],

              if (preventionSw.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                ShambaCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.shield_outlined,
                              color: AppColors.success, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'Kinga na Uzuiaji',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(preventionSw,
                          style: GoogleFonts.poppins(fontSize: 14)),
                    ],
                  ),
                ),
              ],

              if (threatType.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Center(
                    child: StatusBadge(
                      label: 'Aina: $threatType',
                      type: BadgeType.info,
                    ),
                  ),
                ),

              const SizedBox(height: AppSpacing.md),
              Material(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: InkWell(
                  onTap: () => setState(() => _aiExpanded = !_aiExpanded),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.auto_awesome_outlined,
                                color: AppColors.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Maelezo zaidi ya AI',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Icon(_aiExpanded
                                ? Icons.expand_less
                                : Icons.expand_more),
                          ],
                        ),
                        if (_aiExpanded) ...[
                          const SizedBox(height: 8),
                          Text(
                            descriptionSw.isNotEmpty
                                ? descriptionSw
                                : 'AI imechambua picha yako kulingana na hali ya mazao Tanzania.',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.lg),

            ShambaButton(
              label: 'Piga Picha Nyingine',
              icon: Icons.camera_alt_outlined,
              fullWidth: true,
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  FadeSlideRoute(page: const ScanScreen()),
                );
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            ShambaButton(
              label: 'Shiriki WhatsApp',
              icon: Icons.share_outlined,
              variant: ButtonVariant.outline,
              fullWidth: true,
              onPressed: hasError || isHealthy ? null : _shareWhatsApp,
            ),
            const SizedBox(height: AppSpacing.sm),
            ShambaButton(
              label: 'Rudi Nyumbani',
              icon: Icons.home_outlined,
              variant: ButtonVariant.ghost,
              fullWidth: true,
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  FadeSlideRoute(page: const HomeScreen()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DiseaseGradientBanner extends StatelessWidget {
  final String diseaseSw;
  final String diseaseEn;
  final double confidence;
  final dynamic severity;
  final String severityLabel;
  final Color severityColor;

  const _DiseaseGradientBanner({
    required this.diseaseSw,
    required this.diseaseEn,
    required this.confidence,
    required this.severity,
    required this.severityLabel,
    required this.severityColor,
  });

  @override
  Widget build(BuildContext context) {
    final isCritical = severity.toString().toLowerCase() == 'critical';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            severityColor.withValues(alpha: 0.9),
            AppColors.primaryDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadow.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            diseaseSw,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
          if (diseaseEn.isNotEmpty)
            Text(
              diseaseEn,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textOnDarkSoft,
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Uhakika: ${(confidence * 100).toStringAsFixed(0)}%',
            style: GoogleFonts.poppins(
              color: AppColors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: confidence),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.full),
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 8,
                  backgroundColor: Colors.white24,
                  valueColor: AlwaysStoppedAnimation(
                    value > 0.7
                        ? AppColors.primaryLight
                        : value > 0.4
                            ? AppColors.warningLight
                            : AppColors.critical,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          StatusBadge(
            label: severityLabel,
            type: StatusBadge.fromSeverity(severity?.toString()),
            showDot: isCritical,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.05, end: 0);
  }
}

class _AlertBanner extends StatelessWidget {
  final Color color;
  final Widget child;

  const _AlertBanner({required this.color, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: child,
    );
  }
}

// ── Mkulima AI disease card ──────────────────────────────────────────────────

class _MkulimaCard extends StatefulWidget {
  final MkulimaResult result;
  const _MkulimaCard({required this.result});

  @override
  State<_MkulimaCard> createState() => _MkulimaCardState();
}

class _MkulimaCardState extends State<_MkulimaCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    final color = r.ukaliColor;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
        boxShadow: AppShadow.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.lg)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(r.emoji,
                        style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A5C2E),
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.full),
                                ),
                                child: Text(
                                  'Mkulima AI',
                                  style: GoogleFonts.poppins(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.15),
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.full),
                                ),
                                child: Text(
                                  'Ukali: ${r.ukali}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            r.jinaSw,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (r.jinaEn.isNotEmpty)
                            Text(
                              r.jinaEn,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Confidence bar
                Text(
                  'Uhakika: ${(r.confidence * 100).toStringAsFixed(1)}%',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: r.confidence),
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => ClipRRect(
                    borderRadius:
                        BorderRadius.circular(AppRadius.full),
                    child: LinearProgressIndicator(
                      value: value,
                      minHeight: 6,
                      backgroundColor: Colors.black12,
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Urgent action alert (juu sana only) ─────────────────────────
          if (r.isUrgent && r.hatuaYaHaraka.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.critical.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                    color: AppColors.critical.withValues(alpha: 0.4)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_rounded,
                      color: AppColors.critical, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hatua ya Haraka!',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppColors.critical,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(r.hatuaYaHaraka,
                            style: GoogleFonts.poppins(fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // ── Body rows ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (r.dalili.isNotEmpty) _InfoRow('🔍 Dalili', r.dalili),
                if (r.sababu.isNotEmpty) _InfoRow('🦠 Sababu', r.sababu),
                if (r.dawa.isNotEmpty) _InfoRow('💊 Dawa', r.dawa),
                if (r.dawaAsili.isNotEmpty)
                  _InfoRow('🌿 Dawa ya Asili', r.dawaAsili),

                // Expandable prevention + top3
                InkWell(
                  onTap: () => setState(() => _expanded = !_expanded),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Text(
                          _expanded ? 'Ficha maelezo' : 'Ona zaidi',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _expanded
                              ? Icons.expand_less
                              : Icons.expand_more,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),

                if (_expanded) ...[
                  if (r.kinga.isNotEmpty) _InfoRow('🛡️ Kinga', r.kinga),
                  if (!r.isUrgent && r.hatuaYaHaraka.isNotEmpty)
                    _InfoRow('⚡ Hatua ya Haraka', r.hatuaYaHaraka),
                  if (r.wakatiHatari.isNotEmpty)
                    _InfoRow('⏰ Wakati Hatari', r.wakatiHatari),
                  const SizedBox(height: 8),
                  // Top 3 predictions
                  Text(
                    'Matokeo 3 bora:',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...r.top3.map((p) {
                    final conf = (p['confidence'] as double?) ?? 0.0;
                    final jina = (p['jina_sw'] as String?) ?? '';
                    final em = (p['emoji'] as String?) ?? '🌿';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Text(em,
                              style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  jina,
                                  style: GoogleFonts.poppins(
                                      fontSize: 12),
                                ),
                                const SizedBox(height: 2),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                      AppRadius.full),
                                  child: LinearProgressIndicator(
                                    value: conf.clamp(0.0, 1.0),
                                    minHeight: 4,
                                    backgroundColor: Colors.black12,
                                    valueColor:
                                        AlwaysStoppedAnimation(
                                            AppColors.primary
                                                .withValues(
                                                    alpha: 0.6)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${(conf * 100).toStringAsFixed(0)}%',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.04, end: 0);
  }

  Widget _InfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(value, style: GoogleFonts.poppins(fontSize: 13)),
        ],
      ),
    );
  }
}

// ── Treatment card ───────────────────────────────────────────────────────────

class _TreatmentCard extends StatelessWidget {
  final String title;
  final String name;
  final String dose;
  final Color borderColor;
  final dynamic phiDays;
  final bool isPrimary;

  const _TreatmentCard({
    required this.title,
    required this.name,
    required this.dose,
    required this.borderColor,
    this.phiDays,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.divider),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: borderColor,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(AppRadius.lg),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: borderColor,
                          ),
                        ),
                        const Spacer(),
                        if (isPrimary)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.successBg,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.full),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.verified_outlined,
                                    size: 12, color: AppColors.success),
                                const SizedBox(width: 4),
                                Text(
                                  'TPRI',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      name,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    if (dose.isNotEmpty)
                      Text(
                        dose,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    if (phiDays != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        '⏰ Subiri siku $phiDays kabla ya mavuno',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

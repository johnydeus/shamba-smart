import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/feature_flags.dart';
import '../core/utils/image_upload_helper.dart';
import '../features/scan/data/gemini_scan_translator.dart';
import '../features/scan/data/scan_taxonomy.dart';
import '../features/scan/domain/scan_request.dart';
import '../routes/fade_slide_route.dart';
import '../services/audio_service.dart';
import '../services/claude_service.dart';
import '../services/gemini_scan_service.dart';
import '../services/mkulima_service.dart';
import '../services/supabase_service.dart';
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
  final Map<String, dynamic>? cloudEnrichment;
  final String? scanSource;
  final bool queuedForEnrichment;

  // Two-stage verification fields (disease scans only)
  final bool isVerifying;      // true → auto-fire Claude verification on open
  final ScanRequest? scanRequest; // needed to run verifyDiagnosis

  const ResultsScreen({
    super.key,
    required this.diagnosis,
    required this.imagePath,
    required this.cropName,
    this.mkulimaResult,
    this.cloudEnrichment,
    this.scanSource,
    this.queuedForEnrichment = false,
    this.isVerifying = false,
    this.scanRequest,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  bool _aiExpanded = false;

  // ── Two-stage verification state ──────────────────────────────────────────
  bool _verifying = false;
  Map<String, dynamic>? _verification; // Claude's structured verification result
  String? _verifyError;                // human-readable error if Claude call failed

  @override
  void initState() {
    super.initState();
    if (widget.isVerifying && widget.scanRequest != null) {
      _runVerification();
    }
  }

  Future<void> _runVerification() async {
    if (_verifying) return;
    setState(() { _verifying = true; _verifyError = null; });

    try {
      final req = widget.scanRequest!;
      final mkulima = widget.mkulimaResult;

      // FLAG ON: Gemini does the CLASSIFICATION/verification, translated into
      // the existing `_verification` keys. FLAG OFF (default): the original
      // Claude verifyDiagnosis call runs unchanged.
      final Map<String, dynamic> result;
      if (FeatureFlags.useGeminiScan) {
        result = await _verifyWithGemini(req);
      } else {
        result = await ClaudeService.verifyDiagnosis(
          imageFile: File(req.imagePath),
          mkulimaGuess: mkulima?.jinaSw ?? 'Haijulikani',
          mkulimaConfidence: mkulima?.confidence ?? 0.0,
          mkulimaWasLowConfidence: mkulima == null,
          regionContext: req.region,
        );
      }

      if (!mounted) return;

      if (result['error'] == true) {
        setState(() {
          _verifying = false;
          _verifyError = result['message'] as String?;
        });
        return;
      }

      // Save full result to Supabase (fire-and-forget)
      SupabaseService.saveDiagnosis(
        cropName: req.cropName,
        claudeResponse: result,
        photoPath: req.imagePath,
        gpsLat: req.gpsLat,
        gpsLng: req.gpsLng,
        mkulimaResult: mkulima,
      );

      setState(() { _verifying = false; _verification = result; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _verifying = false; _verifyError = e.toString(); });
    }
  }

  // Gemini classification path for the two-stage disease verify (flag ON only).
  // Returns the `_verification` map shape ResultsScreen renders.
  Future<Map<String, dynamic>> _verifyWithGemini(ScanRequest req) async {
    await ScanTaxonomy().ensureLoaded();
    final allowed = ScanTaxonomy().allowedLabelsForCrop(req.cropName);
    final base64 = await ImageUploadHelper.optimisedBase64ForScan(
        File(req.imagePath));

    var tier = 'flash-lite';
    var g = await GeminiScanService.classify(
      imageBase64: base64,
      cropType: req.cropName,
      problemType: 'disease',
      allowedLabels: allowed,
      modelTier: tier,
    );
    if (g['error'] == null && g['needs_flash_escalation'] == true) {
      final g2 = await GeminiScanService.classify(
        imageBase64: base64,
        cropType: req.cropName,
        problemType: 'disease',
        allowedLabels: allowed,
        modelTier: 'flash',
      );
      if (g2['error'] == null) {
        tier = 'flash';
        g = g2;
      }
    }

    if (g['error'] != null) {
      return {'error': true, 'message': 'Uhakiki wa picha umeshindwa. Jaribu tena.'};
    }

    final localized =
        ScanTaxonomy().localizeByEnglish((g['top_prediction'] as String?) ?? '');
    return GeminiScanTranslator.toVerificationMap(
      g,
      cropName: req.cropName,
      tier: tier,
      localized: localized,
    );
  }

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

            // ── Claude verification result (two-stage flow) ───────────────
            if (_verifying)
              _VerifyingBanner(),

            if (!_verifying && _verification != null)
              _VerificationCard(
                verification: _verification!,
                mkulimaGuess: widget.mkulimaResult?.jinaSw,
                onRetry: null, // already verified
              ),

            // ── Offline banner + "Hakiki Tena" button ─────────────────────
            if (!_verifying &&
                _verification == null &&
                widget.isVerifying == false &&
                widget.scanRequest != null)
              _OfflineBanner(onRetry: _runVerification),

            // ── Verification error (Claude call failed) ────────────────────
            if (!_verifying && _verifyError != null && _verification == null)
              _VerifyErrorBanner(
                message: _verifyError!,
                onRetry: _runVerification,
              ),

            if (_verifying ||
                _verification != null ||
                (_verifyError != null && _verification == null))
              const SizedBox(height: AppSpacing.md),

            // ── Mkulima AI card (shown only for disease scans) ────────────
            if (widget.mkulimaResult != null)
              _MkulimaCard(
                result: widget.mkulimaResult!,
                imagePath: widget.imagePath,
              ),

            if (widget.mkulimaResult != null)
              const SizedBox(height: AppSpacing.md),

            if (widget.scanSource != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        widget.queuedForEnrichment
                            ? Icons.schedule
                            : Icons.offline_bolt,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.scanSource!,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

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
                      Row(
                        children: [
                          Text(
                            'Maelezo',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          const Spacer(),
                          SpeakerButton(
                            text: 'Ugonjwa uliopatikana ni $diseaseSw. $descriptionSw. Hatua ya kuchukua: $actionSw',
                          ),
                        ],
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

              if (widget.cloudEnrichment != null &&
                  widget.cloudEnrichment!['error'] != true) ...[
                const SizedBox(height: AppSpacing.md),
                _CloudEnrichmentCard(enrichment: widget.cloudEnrichment!),
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

// ── Optional online enrichment (does not replace Mkulima) ───────────────────

class _CloudEnrichmentCard extends StatelessWidget {
  final Map<String, dynamic> enrichment;

  const _CloudEnrichmentCard({required this.enrichment});

  @override
  Widget build(BuildContext context) {
    final extraAction = enrichment['immediate_action_sw'] as String? ?? '';
    final extraDesc = enrichment['description_sw'] as String? ?? '';
    final extraPest = enrichment['pesticide_1_name'] as String? ?? '';

    return ShambaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cloud_done_outlined, color: AppColors.info, size: 20),
              const SizedBox(width: 8),
              Text(
                'Ushauri wa Ziada (Mtandaoni)',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: AppColors.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Mkulima AI ndiyo uchunguzi mkuu — hii ni usaidizi wa ziada kutoka mtandaoni.',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textTertiary,
            ),
          ),
          if (extraDesc.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(extraDesc, style: GoogleFonts.poppins(fontSize: 14)),
          ],
          if (extraAction.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Hatua ya ziada: $extraAction',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.warning,
              ),
            ),
          ],
          if (extraPest.isNotEmpty && extraPest != 'Hakuna') ...[
            const SizedBox(height: 6),
            Text(
              'Dawa ya ziada: $extraPest',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Mkulima AI disease card ──────────────────────────────────────────────────

const _kMkulimaGreen = Color(0xFF2E7D32);
const _kMkulimaOrange = Color(0xFFE65100);
const _kMkulimaRed = Color(0xFFB71C1C);

class _MkulimaCard extends StatefulWidget {
  final MkulimaResult result;
  final String imagePath;
  const _MkulimaCard({required this.result, required this.imagePath});

  @override
  State<_MkulimaCard> createState() => _MkulimaCardState();
}

class _MkulimaCardState extends State<_MkulimaCard> {
  // Which section is expanded
  final Map<String, bool> _open = {
    'dalili': false,
    'dawa': false,
    'asili': false,
    'kinga': false,
    'top3': false,
  };

  // Feedback state
  bool? _feedbackPositive; // null=none, true=confirm, false=reject
  bool _feedbackSubmitted = false;

  Color _confidenceColor(double c) {
    if (c >= 0.70) return _kMkulimaGreen;
    if (c >= 0.40) return _kMkulimaOrange;
    return _kMkulimaRed;
  }

  Color _ukaliColor(String ukali) {
    switch (ukali.toLowerCase()) {
      case 'juu sana':
      case 'hatari':
        return _kMkulimaRed;
      case 'juu':
      case 'wastani':
        return _kMkulimaOrange;
      default:
        return _kMkulimaGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    final confColor = _confidenceColor(r.confidence);
    final ukaliCol = _ukaliColor(r.ukali);

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: _kMkulimaGreen.withValues(alpha: 0.25)),
            boxShadow: [
              BoxShadow(
                color: _kMkulimaGreen.withValues(alpha: 0.10),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Gradient header ─────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Brand row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Text('🌿',
                                  style: TextStyle(fontSize: 10)),
                              const SizedBox(width: 4),
                              Text('Mkulima AI',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  )),
                            ],
                          ),
                        ),
                        const Spacer(),
                        // Severity badge
                        if (r.ukali.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: ukaliCol.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: ukaliCol.withValues(alpha: 0.5)),
                            ),
                            child: Text(
                              'Ukali: ${r.ukali}',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: ukaliCol == _kMkulimaRed
                                    ? Colors.red[100]
                                    : ukaliCol == _kMkulimaOrange
                                        ? Colors.orange[100]
                                        : Colors.green[100],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Disease name
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.emoji,
                            style: const TextStyle(fontSize: 32)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.jinaSw,
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  height: 1.2,
                                ),
                              ),
                              if (r.jinaEn.isNotEmpty)
                                Text(
                                  r.jinaEn,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.white60,
                                  ),
                                ),
                              if (r.zao.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Zao: ${r.zao}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: Colors.white54,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Confidence bar
                    Row(
                      children: [
                        Text(
                          'Uhakika: ${(r.confidence * 100).toStringAsFixed(1)}%',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: confColor.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            r.confidence >= 0.70
                                ? 'Juu'
                                : r.confidence >= 0.40
                                    ? 'Wastani'
                                    : 'Chini',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: r.confidence >= 0.70
                                  ? Colors.green[200]
                                  : r.confidence >= 0.40
                                      ? Colors.orange[200]
                                      : Colors.red[200],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: r.confidence),
                      duration: const Duration(milliseconds: 1200),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) => ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: value,
                          minHeight: 8,
                          backgroundColor: Colors.white24,
                          valueColor:
                              AlwaysStoppedAnimation(confColor),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Four expandable sections ─────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: Column(
                  children: [
                    _ExpandableSection(
                      emoji: '🔍',
                      label: 'Dalili',
                      content: r.dalili,
                      isOpen: _open['dalili']!,
                      onToggle: () =>
                          setState(() => _open['dalili'] = !_open['dalili']!),
                    ),
                    _ExpandableSection(
                      emoji: '💊',
                      label: 'Dawa',
                      content: r.dawa,
                      isOpen: _open['dawa']!,
                      onToggle: () =>
                          setState(() => _open['dawa'] = !_open['dawa']!),
                    ),
                    _ExpandableSection(
                      emoji: '🌿',
                      label: 'Dawa ya Asili',
                      content: r.dawaAsili,
                      isOpen: _open['asili']!,
                      onToggle: () =>
                          setState(() => _open['asili'] = !_open['asili']!),
                    ),
                    _ExpandableSection(
                      emoji: '🛡️',
                      label: 'Kinga',
                      content: r.kinga,
                      isOpen: _open['kinga']!,
                      onToggle: () =>
                          setState(() => _open['kinga'] = !_open['kinga']!),
                    ),
                    // Top 3 predictions
                    _ExpandableSection(
                      emoji: '📊',
                      label: 'Matokeo 3 bora',
                      content: null,
                      isOpen: _open['top3']!,
                      onToggle: () =>
                          setState(() => _open['top3'] = !_open['top3']!),
                      customContent: _open['top3']!
                          ? _Top3List(top3: r.top3)
                          : null,
                    ),
                  ],
                ),
              ),

              // ── Urgent alert (juu sana) ───────────────────────────────────
              if (r.isUrgent && r.hatuaYaHaraka.isNotEmpty)
                Container(
                  margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _kMkulimaRed.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: _kMkulimaRed.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning_rounded,
                          color: _kMkulimaRed, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '⚡ Hatua ya Haraka!',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: _kMkulimaRed,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(r.hatuaYaHaraka,
                                style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: const Color(0xFF7F1D1D))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Feedback buttons ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Je, jibu hili ni sahihi?',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: _feedbackSubmitted
                                ? null
                                : () {
                                    setState(() {
                                      _feedbackPositive = true;
                                      _feedbackSubmitted = true;
                                    });
                                    SupabaseService.submitTrainingFeedback(
                                      diseaseKey: widget.result.diseaseKey,
                                      isCorrect: true,
                                      imagePath: widget.imagePath,
                                      cropName: widget.result.zao.isNotEmpty
                                          ? widget.result.zao
                                          : null,
                                    );
                                  },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 11),
                              decoration: BoxDecoration(
                                color: _feedbackPositive == true
                                    ? _kMkulimaGreen
                                    : _kMkulimaGreen.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _kMkulimaGreen
                                      .withValues(alpha: 0.4),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Text('✅',
                                      style: const TextStyle(
                                          fontSize: 14)),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Ndiyo, Sahihi',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: _feedbackPositive == true
                                          ? Colors.white
                                          : _kMkulimaGreen,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: _feedbackSubmitted
                                ? null
                                : () {
                                    setState(() {
                                      _feedbackPositive = false;
                                      _feedbackSubmitted = true;
                                    });
                                    SupabaseService.submitTrainingFeedback(
                                      diseaseKey: widget.result.diseaseKey,
                                      isCorrect: false,
                                      imagePath: widget.imagePath,
                                      cropName: widget.result.zao.isNotEmpty
                                          ? widget.result.zao
                                          : null,
                                    );
                                  },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 11),
                              decoration: BoxDecoration(
                                color: _feedbackPositive == false
                                    ? _kMkulimaRed
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: _kMkulimaRed
                                        .withValues(alpha: 0.5)),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Text('❌',
                                      style: const TextStyle(
                                          fontSize: 14)),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Hapana, Si Hilo',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: _feedbackPositive == false
                                          ? Colors.white
                                          : _kMkulimaRed,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_feedbackPositive != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _feedbackPositive!
                              ? 'Asante! Maoni yako yanasaidia kuboresha Mkulima AI.'
                              : 'Asante! Piga picha tena au wasiliana na mtaalamu.',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.04, end: 0);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Two-stage verification widgets
// ══════════════════════════════════════════════════════════════════════════════

/// Spinner banner shown while Claude is verifying.
class _VerifyingBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1B4332),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(Colors.white70),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Mkulima AI inahakiki na mtaalamu wa AI (Claude)...',
              style: GoogleFonts.poppins(
                  fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

/// The trusted final result from Claude — shown once verification completes.
class _VerificationCard extends StatelessWidget {
  final Map<String, dynamic> verification;
  final String? mkulimaGuess;
  final VoidCallback? onRetry;

  const _VerificationCard({
    required this.verification,
    this.mkulimaGuess,
    this.onRetry,
  });

  Color _confidenceBadgeColor(String conf) {
    switch (conf.toLowerCase()) {
      case 'high':
        return const Color(0xFF2E7D32);
      case 'medium':
        return const Color(0xFFE65100);
      default:
        return const Color(0xFFB71C1C);
    }
  }

  String _confidenceLabel(String conf) {
    switch (conf.toLowerCase()) {
      case 'high':
        return 'Uhakika Mkubwa';
      case 'medium':
        return 'Uhakika wa Kati';
      default:
        return 'Uhakika Mdogo';
    }
  }

  @override
  Widget build(BuildContext context) {
    final detectedCrop = verification['detected_crop'] as String? ?? '';
    final agrees = verification['agrees_with_mkulima'] as bool? ?? false;
    final diagSw = verification['final_diagnosis_sw'] as String? ?? '';
    final diagEn = verification['final_diagnosis_en'] as String? ?? '';
    final confStr = verification['confidence'] as String? ?? 'low';
    final isHealthy = verification['is_healthy'] as bool? ?? false;
    final imageQualityOk = verification['image_quality_ok'] as bool? ?? true;
    final explanationSw = verification['explanation_sw'] as String? ?? '';
    final actionSw = verification['recommended_action_sw'] as String? ?? '';
    final pest1Name = verification['pesticide_1_name'] as String? ?? '';
    final pest1Dose = verification['pesticide_1_dose'] as String? ?? '';
    final pest2Name = verification['pesticide_2_name'] as String? ?? '';
    final pest2Dose = verification['pesticide_2_dose'] as String? ?? '';

    // If Claude says "not a crop plant"
    if (detectedCrop == 'SI_MMEA') {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.warningLight.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const Text('⚠️', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Hii haionekani kama mmea wa kilimo. '
                'Piga picha ya jani la zao lako.',
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ).animate().fadeIn().slideY(begin: 0.08, end: 0);
    }

    // Poor image quality
    if (!imageQualityOk) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.warningLight.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const Text('📸', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Picha haiko wazi vya kutosha. Tafadhali piga tena '
                'kwa ukaribu na mwanga mzuri.',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
            ),
          ],
        ),
      ).animate().fadeIn().slideY(begin: 0.08, end: 0);
    }

    final badgeColor = _confidenceBadgeColor(confStr);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF004D40), Color(0xFF00695C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Brand + trust badge row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(children: [
                        const Text('✅', style: TextStyle(fontSize: 10)),
                        const SizedBox(width: 4),
                        Text('Uchunguzi wa Uhakika',
                            style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ]),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: badgeColor.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        _confidenceLabel(confStr),
                        style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white70),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Diagnosis name
                if (isHealthy) ...[
                  const Text('🌱', style: TextStyle(fontSize: 32)),
                  const SizedBox(height: 6),
                  Text('Mmea Wako Una Afya Njema!',
                      style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                ] else ...[
                  Text(diagSw.isNotEmpty ? diagSw : 'Ugonjwa Uligunduliwa',
                      style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.2)),
                  if (diagEn.isNotEmpty)
                    Text(diagEn,
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: Colors.white60)),
                ],

                if (detectedCrop.isNotEmpty && detectedCrop != 'SI_MMEA') ...[
                  const SizedBox(height: 6),
                  Text('Zao: $detectedCrop',
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: Colors.white54)),
                ],

                // Correction note — only when Claude disagreed with Mkulima
                if (!agrees &&
                    mkulimaGuess != null &&
                    mkulimaGuess!.isNotEmpty &&
                    !mkulimaGuess!.startsWith('Inahakiki') &&
                    !isHealthy) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      'Mkulima AI ilidhani "$mkulimaGuess", '
                      'lakini uchunguzi wa kina unaonyesha '
                      '"${diagSw.isNotEmpty ? diagSw : diagEn}".',
                      style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.orange[100]),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Explanation ────────────────────────────────────────────────
          if (explanationSw.isNotEmpty)
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Text(
                explanationSw,
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.5),
              ),
            ),

          // ── Recommended action ─────────────────────────────────────────
          if (actionSw.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.bolt,
                      size: 18, color: AppColors.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      actionSw,
                      style: GoogleFonts.poppins(
                          fontSize: 13, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),

          // ── Pesticides ─────────────────────────────────────────────────
          if (pest1Name.isNotEmpty &&
              pest1Name != 'Hakuna' &&
              !isHealthy) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _VerifyPesticideTile(
                  name: pest1Name, dose: pest1Dose, isPrimary: true),
            ),
            if (pest2Name.isNotEmpty && pest2Name != 'Hakuna')
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                child: _VerifyPesticideTile(
                    name: pest2Name, dose: pest2Dose, isPrimary: false),
              ),
          ],

          const SizedBox(height: 16),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.06, end: 0);
  }
}

class _VerifyPesticideTile extends StatelessWidget {
  final String name;
  final String dose;
  final bool isPrimary;
  const _VerifyPesticideTile(
      {required this.name, required this.dose, required this.isPrimary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isPrimary
            ? AppColors.primary.withValues(alpha: 0.06)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: isPrimary ? 0.3 : 0.1)),
      ),
      child: Row(
        children: [
          Icon(Icons.medication_outlined,
              size: 18,
              color:
                  isPrimary ? AppColors.primary : AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                if (dose.isNotEmpty && dose != 'Hakuna')
                  Text(dose,
                      style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Banner shown when offline — farmer can retry verification later.
class _OfflineBanner extends StatelessWidget {
  final VoidCallback onRetry;
  const _OfflineBanner({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.wifi_off_outlined,
                  size: 18, color: AppColors.warning),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '⚠️ Uchunguzi wa awali (bila intaneti)',
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.warning),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Pata uchunguzi kamili ukiwa na intaneti.',
            style: GoogleFonts.poppins(
                fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 16),
              label: Text('Hakiki Tena',
                  style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

/// Small error banner with retry when Claude call failed.
class _VerifyErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _VerifyErrorBanner(
      {required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.critical.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.critical.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline,
              size: 18, color: AppColors.critical),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Hakikisho halikufaulu. Jaribu tena.',
              style: GoogleFonts.poppins(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: Text('Jaribu',
                style: GoogleFonts.poppins(
                    fontSize: 12, color: AppColors.primary)),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

class _ExpandableSection extends StatelessWidget {
  final String emoji;
  final String label;
  final String? content;
  final bool isOpen;
  final VoidCallback onToggle;
  final Widget? customContent;

  const _ExpandableSection({
    required this.emoji,
    required this.label,
    required this.content,
    required this.isOpen,
    required this.onToggle,
    this.customContent,
  });

  @override
  Widget build(BuildContext context) {
    final hasContent =
        (content != null && content!.isNotEmpty) || customContent != null;
    if (!hasContent) return const SizedBox.shrink();

    return Column(
      children: [
        InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: isOpen
                  ? const Color(0xFF2E7D32).withValues(alpha: 0.06)
                  : Colors.grey.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isOpen
                    ? const Color(0xFF2E7D32).withValues(alpha: 0.2)
                    : Colors.grey.withValues(alpha: 0.12),
              ),
            ),
            child: Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isOpen
                          ? const Color(0xFF2E7D32)
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: isOpen ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: isOpen
                        ? const Color(0xFF2E7D32)
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState: isOpen
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: const SizedBox.shrink(),
          secondChild: Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 2, bottom: 2),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color:
                      const Color(0xFF2E7D32).withValues(alpha: 0.12)),
            ),
            child: customContent ??
                Text(
                  content ?? '',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    height: 1.5,
                  ),
                ),
          ),
        ),
        const SizedBox(height: 6),
      ],
    );
  }
}

class _Top3List extends StatelessWidget {
  final List<Map<String, dynamic>> top3;
  const _Top3List({required this.top3});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: top3.map((p) {
        final conf = (p['confidence'] as double?) ?? 0.0;
        final jina = (p['jina_sw'] as String?) ?? '';
        final em = (p['emoji'] as String?) ?? '🌿';
        final barColor = conf >= 0.70
            ? _kMkulimaGreen
            : conf >= 0.40
                ? _kMkulimaOrange
                : _kMkulimaRed;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Text(em, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(jina,
                        style: GoogleFonts.poppins(fontSize: 12)),
                    const SizedBox(height: 3),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: conf.clamp(0.0, 1.0),
                        minHeight: 5,
                        backgroundColor: Colors.black12,
                        valueColor: AlwaysStoppedAnimation(barColor),
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
                  fontWeight: FontWeight.w700,
                  color: barColor,
                ),
              ),
            ],
          ),
        );
      }).toList(),
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

import 'package:supabase_flutter/supabase_flutter.dart';

/// Routing outcome after Flash-Lite (+ optional Flash escalation).
enum ScanRoutingState { confident, uncertain, needsExpert, error }

class GeminiRoutingResult {
  final Map<String, dynamic> gemini; // final raw gemini-proxy JSON
  final String tier; // 'flash-lite' or 'flash'
  final ScanRoutingState state;
  final String? escalationReason; // why Flash was tried; null if never escalated
  // True when this is a named OPEN-mode result (allowedLabels was empty) that
  // was accepted as `uncertain` rather than discarded to needsExpert — so
  // Phase 5 retraining can distinguish open-mode from closed-list labels.
  final bool openAccepted;
  const GeminiRoutingResult(this.gemini, this.tier, this.state,
      {this.escalationReason, this.openAccepted = false});
}

/// Calls the `gemini-proxy` edge function for crop image CLASSIFICATION.
/// Mirrors ClaudeService's proxy-call style (functions.invoke). The Gemini key
/// lives only in Supabase secrets — never in the app.
///
/// Returns the strict Gemini JSON (see gemini-proxy schema) or a
/// `{ 'error': ... }` map. Translation to the app's diagnosis-map keys is done
/// separately by GeminiScanTranslator — this service does NOT shape the result.
class GeminiScanService {
  /// modelTier: 'flash-lite' (default) or 'flash' (escalation).
  static Future<Map<String, dynamic>> classify({
    required String imageBase64,
    required String cropType,
    required String problemType,
    required List<String> allowedLabels,
    String modelTier = 'flash-lite',
  }) async {
    try {
      final response = await Supabase.instance.client.functions
          .invoke('gemini-proxy', body: {
            'imageBase64': imageBase64,
            'cropType': cropType,
            'problemType': problemType,
            'allowedLabels': allowedLabels,
            'modelTier': modelTier,
          })
          // Fail-safe: never let a stalled function hang the scan UI. On
          // timeout the caller maps {error} to the safe Swahili fallback.
          .timeout(const Duration(seconds: 20));
      final data = response.data;
      if (data is Map<String, dynamic>) return data;
      return {'error': 'Unexpected gemini-proxy response'};
    } catch (e) {
      return {'error': 'gemini-proxy call failed: $e'};
    }
  }

  static const double _confidentMin = 0.80; // >= -> accept as suggestion
  static const double _uncertainMin = 0.60; // [0.60,0.80) -> uncertain banner

  static bool _isUnknownLabel(String? label) {
    final l = (label ?? '').trim().toLowerCase();
    return l.isEmpty || l == 'unknown' || l.contains('needs human');
  }

  // image_quality is "poor but still usable" when it mentions blur/dark/far.
  static bool _poorButUsable(Map<String, dynamic> g) {
    final q = (g['image_quality'] as String?)?.toLowerCase() ?? '';
    return q.contains('blur') || q.contains('dark') || q.contains('far');
  }

  /// Classify with confidence-threshold routing + ONE Flash escalation.
  /// Flash-Lite is ALWAYS tried first (cost control); Flash runs only when the
  /// Flash-Lite result is low-confidence / Unknown / flagged / poor-but-usable.
  /// [onEscalate] fires just before the Flash retry (for a progress message).
  static Future<GeminiRoutingResult> classifyWithRouting({
    required String imageBase64,
    required String cropType,
    required String problemType,
    required List<String> allowedLabels,
    void Function()? onEscalate,
  }) async {
    // Open mode = no closed list (gemini-proxy identified freely from its own
    // knowledge). A named, symptom-backed open result is worth showing as
    // `uncertain` (with the human-confirm flow) instead of throwing it away as
    // needsExpert. Closed-list scans (allowedLabels non-empty) are unaffected.
    final openMode = allowedLabels.isEmpty;
    bool openNamed(Map<String, dynamic> g) {
      if (!openMode) return false;
      if (_isUnknownLabel(g['top_prediction'] as String?)) return false;
      final syms = g['symptoms_seen'];
      final hasSymptoms = syms is List &&
          syms.any((s) => (s?.toString().trim().isNotEmpty ?? false));
      final c = (g['confidence'] as num?)?.toDouble() ?? 0;
      return hasSymptoms && c >= 0.50;
    }

    final g1 = await classify(
      imageBase64: imageBase64,
      cropType: cropType,
      problemType: problemType,
      allowedLabels: allowedLabels,
      modelTier: 'flash-lite',
    );
    if (g1['error'] != null) {
      return const GeminiRoutingResult({}, 'flash-lite', ScanRoutingState.error);
    }

    final conf1 = (g1['confidence'] as num?)?.toDouble() ?? 0;
    final unknown1 = _isUnknownLabel(g1['top_prediction'] as String?);
    // Reason recorded for retraining (and to drive the one escalation).
    final reason = unknown1
        ? 'unknown'
        : conf1 < _uncertainMin
            ? 'low_confidence'
            : g1['needs_flash_escalation'] == true
                ? 'flagged'
                : _poorButUsable(g1)
                    ? 'poor_image'
                    : null;
    final mustEscalate = reason != null;
    // TODO Phase 4b: also escalate on multi-image disagreement or by user role
    // (Afisa/paid/NGO/government) once those signals are available at scan time.

    if (!mustEscalate) {
      // 0.60–0.79 -> uncertain (NO escalation per spec); >=0.80 -> confident.
      final state = conf1 >= _confidentMin
          ? ScanRoutingState.confident
          : ScanRoutingState.uncertain;
      return GeminiRoutingResult(g1, 'flash-lite', state);
    }

    // Escalate once to Flash (same image + allowedLabels).
    onEscalate?.call();
    final g2 = await classify(
      imageBase64: imageBase64,
      cropType: cropType,
      problemType: problemType,
      allowedLabels: allowedLabels,
      modelTier: 'flash',
    );
    if (g2['error'] != null) {
      // Flash failed — judge by the Flash-Lite result we already have.
      final ok = conf1 >= _uncertainMin && !unknown1;
      if (!ok && openNamed(g1)) {
        // Named open-mode diagnosis — show it (uncertain) instead of discarding.
        return GeminiRoutingResult(g1, 'flash-lite', ScanRoutingState.uncertain,
            escalationReason: reason, openAccepted: true);
      }
      return GeminiRoutingResult(g1, 'flash-lite',
          ok ? ScanRoutingState.uncertain : ScanRoutingState.needsExpert,
          escalationReason: reason);
    }

    final conf2 = (g2['confidence'] as num?)?.toDouble() ?? 0;
    final unknown2 = _isUnknownLabel(g2['top_prediction'] as String?);
    if (conf2 >= _uncertainMin && !unknown2) {
      final state = conf2 >= _confidentMin
          ? ScanRoutingState.confident
          : ScanRoutingState.uncertain;
      return GeminiRoutingResult(g2, 'flash', state, escalationReason: reason);
    }
    // Named open-mode diagnosis at moderate confidence -> show it (uncertain)
    // with the human-confirm flow, rather than discarding a correct answer.
    if (openNamed(g2)) {
      return GeminiRoutingResult(g2, 'flash', ScanRoutingState.uncertain,
          escalationReason: reason, openAccepted: true);
    }
    // Both tiers tried, still not confident -> needs expert review.
    return GeminiRoutingResult(g2, 'flash', ScanRoutingState.needsExpert,
        escalationReason: reason);
  }

  /// Step 1 of auto-detect: identify the CROP from a fixed candidate list.
  /// Returns the matched candidate, or null when Gemini can't confidently
  /// identify it (caller then asks the farmer to pick the crop manually —
  /// never guess).
  static Future<String?> detectCrop({
    required String imageBase64,
    required List<String> candidates,
  }) async {
    final g = await classify(
      imageBase64: imageBase64,
      cropType: '',
      problemType: 'crop_identification',
      allowedLabels: candidates,
      modelTier: 'flash-lite',
    );
    if (g['error'] != null) return null;
    final top = (g['top_prediction'] as String?)?.trim() ?? '';
    final l = top.toLowerCase();
    if (top.isEmpty || l == 'unknown' || l.contains('needs human')) return null;
    // Must be one of the candidates (taxonomy lock).
    for (final c in candidates) {
      if (c.toLowerCase() == l) return c;
    }
    return null;
  }
}

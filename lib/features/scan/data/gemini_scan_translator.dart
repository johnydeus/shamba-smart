/// Pure translation from gemini-proxy's strict JSON into the EXACT diagnosis-map
/// keys ResultsScreen already reads. No IO, no network — fully testable.
///
/// Two target shapes exist in the app:
///   1) the primary `diagnosis` map (enrichOnline path), and
///   2) the `_verification` map (ResultsScreen._runVerification path).
///
/// SAFETY: pesticide_* fields are NEVER fabricated here. They are omitted so the
/// existing approved-only safe fallback in the UI renders instead.
///
/// MAPPING TABLE (Gemini key -> app key):
///   top_prediction          -> disease_name_en  (and disease_name_sw via
///                              [localized] localization when available, else
///                              top_prediction passed through)
///   confidence              -> confidence
///   symptoms_seen / farmer_safe_message -> description_sw
///   recommended_next_action -> immediate_action_sw / recommended_action_sw
///   top_prediction=="Healthy" -> is_healthy: true
///   (tier)                  -> source: `gemini-{tier}`
///   localized.ukali         -> severity (when localization found)
///   localized.kinga         -> prevention_sw (when localization found)
///   image_quality           -> image_quality_ok (verification shape)
///   pesticide_1_*/2_*       -> OMITTED (safe fallback shows)
class GeminiScanTranslator {
  GeminiScanTranslator._();

  static bool _isHealthy(String label) =>
      label.trim().toLowerCase() == 'healthy';

  static bool _isUnknown(String label) {
    final l = label.trim().toLowerCase();
    return l.isEmpty || l == 'unknown' || l.contains('needs human');
  }

  static String _descriptionFrom(Map<String, dynamic> g) {
    final symptoms = (g['symptoms_seen'] as List?)
            ?.map((e) => e.toString())
            .where((s) => s.trim().isNotEmpty)
            .toList() ??
        const [];
    final msg = (g['farmer_safe_message'] as String?)?.trim() ?? '';
    final parts = <String>[];
    if (symptoms.isNotEmpty) parts.add(symptoms.join(', '));
    if (msg.isNotEmpty) parts.add(msg);
    return parts.join('. ');
  }

  /// Gemini JSON -> primary `diagnosis` map (enrichOnline path).
  /// [localized] is the matched Swahili disease data (from ScanTaxonomy) or null.
  static Map<String, dynamic> toDiagnosisMap(
    Map<String, dynamic> g, {
    required String cropName,
    required String scanType,
    required String tier,
    Map<String, dynamic>? localized,
  }) {
    final topEn = (g['top_prediction'] as String?)?.trim() ?? '';
    final conf = (g['confidence'] as num?)?.toDouble();
    final source = 'gemini-$tier';

    if (_isHealthy(topEn)) {
      return {
        'is_healthy': true,
        'confidence': conf,
        'affected_crop': cropName,
        'source': source,
        'threat_type': scanType,
      };
    }

    final swName = (localized?['jina_swahili'] as String?)?.trim();
    final desc = _descriptionFrom(g);
    final action = (g['recommended_next_action'] as String?)?.trim();

    return {
      'is_healthy': false,
      // Unknown -> pass a safe label through; UI shows "needs review".
      'disease_name_en': _isUnknown(topEn) ? 'Unknown' : topEn,
      'disease_name_sw':
          swName != null && swName.isNotEmpty ? swName : topEn,
      'confidence': conf,
      if (localized?['ukali'] != null)
        'severity': _ukaliToSeverity(localized!['ukali'] as String),
      if (desc.isNotEmpty) 'description_sw': desc,
      if (action != null && action.isNotEmpty) 'immediate_action_sw': action,
      if ((localized?['kinga'] as String?)?.trim().isNotEmpty == true)
        'prevention_sw': localized!['kinga'],
      'source': source,
      'threat_type': scanType,
      'needs_human_confirmation': g['needs_human_confirmation'] ?? true,
      // pesticide_* deliberately OMITTED — never fabricated.
    };
  }

  /// Gemini JSON -> `_verification` map (ResultsScreen._runVerification path).
  static Map<String, dynamic> toVerificationMap(
    Map<String, dynamic> g, {
    required String cropName,
    required String tier,
    Map<String, dynamic>? localized,
  }) {
    final topEn = (g['top_prediction'] as String?)?.trim() ?? '';
    final conf = (g['confidence'] as num?)?.toDouble();
    final healthy = _isHealthy(topEn);
    final swName = (localized?['jina_swahili'] as String?)?.trim();
    final quality = (g['image_quality'] as String?)?.toLowerCase() ?? '';

    return {
      'detected_crop': (g['crop'] as String?)?.trim().isNotEmpty == true
          ? g['crop']
          : cropName,
      'agrees_with_mkulima': null, // Gemini is now the classifier, not a judge.
      'final_diagnosis_en': healthy
          ? 'Healthy'
          : (_isUnknown(topEn) ? 'Unknown' : topEn),
      'final_diagnosis_sw': healthy
          ? 'Mmea una afya'
          : (swName != null && swName.isNotEmpty ? swName : topEn),
      'confidence': conf,
      'is_healthy': healthy,
      'image_quality_ok': !(quality.contains('blur') ||
          quality.contains('dark') ||
          quality.contains('far')),
      'explanation_sw': _descriptionFrom(g),
      'recommended_action_sw':
          (g['recommended_next_action'] as String?)?.trim() ?? '',
      'source': 'gemini-$tier',
      'needs_human_confirmation': g['needs_human_confirmation'] ?? true,
      // pesticide_1_*/2_* deliberately OMITTED — never fabricated.
    };
  }

  static String _ukaliToSeverity(String ukali) {
    final l = ukali.toLowerCase();
    if (l.contains('hatari') || l.contains('juu sana')) return 'critical';
    if (l.contains('juu')) return 'high';
    if (l.contains('wastani')) return 'medium';
    return 'low';
  }
}

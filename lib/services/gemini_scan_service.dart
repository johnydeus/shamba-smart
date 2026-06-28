import 'package:supabase_flutter/supabase_flutter.dart';

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

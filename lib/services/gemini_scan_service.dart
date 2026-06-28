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
      final response =
          await Supabase.instance.client.functions.invoke('gemini-proxy', body: {
        'imageBase64': imageBase64,
        'cropType': cropType,
        'problemType': problemType,
        'allowedLabels': allowedLabels,
        'modelTier': modelTier,
      });
      final data = response.data;
      if (data is Map<String, dynamic>) return data;
      return {'error': 'Unexpected gemini-proxy response'};
    } catch (e) {
      return {'error': 'gemini-proxy call failed: $e'};
    }
  }
}

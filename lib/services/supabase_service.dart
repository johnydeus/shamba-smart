import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'mkulima_service.dart';

class SupabaseService {
  // Get the Supabase client instance
  static SupabaseClient get _client => Supabase.instance.client;

  // Save a diagnosis result to the diagnoses table.
  // Returns the inserted row id (used by the human-confirmation write-back),
  // or null on failure. Fire-and-forget callers may ignore it.
  static Future<String?> saveDiagnosis({
    required String cropName,
    required Map<String, dynamic> claudeResponse,
    required String photoPath,
    double? gpsLat,
    double? gpsLng,
    MkulimaResult? mkulimaResult,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;

      // Upload the leaf photo to Supabase Storage
      String? photoUrl;
      if (photoPath.isNotEmpty) {
        final file = File(photoPath);
        final fileName =
            'diagnoses/${userId ?? 'anon'}/${DateTime.now().millisecondsSinceEpoch}.jpg';
        await _client.storage.from('leaf-photos').upload(fileName, file);
        photoUrl =
            _client.storage.from('leaf-photos').getPublicUrl(fileName);
      }

      // Build row — add Mkulima fields if available (requires SQL migration)
      final row = <String, dynamic>{
        'farmer_id': userId,
        'crop_name': cropName,
        'disease_name_en': claudeResponse['disease_name_en'],
        'disease_name_sw': claudeResponse['disease_name_sw'],
        // diagnoses.confidence is double precision. Verification maps carry a
        // string bucket ('high'/'medium'/'low') for the UI card, so prefer the
        // numeric confidence_value and never pass a non-num to the column
        // (a string here fails the whole insert and the row is lost).
        'confidence': claudeResponse['confidence_value'] ??
            (claudeResponse['confidence'] is num
                ? claudeResponse['confidence']
                : null),
        'severity': claudeResponse['severity'],
        'photo_url': photoUrl,
        'claude_response': claudeResponse,
        'gps_lat': gpsLat,
        'gps_lng': gpsLng,
      };

      if (mkulimaResult != null) {
        row.addAll(mkulimaResult.toSupabaseRow());
      }

      // ── Retraining capture (Phase 5): describe EVERY scan's true origin ──
      // Derived from the shown result map, AFTER the Mkulima addAll above so the
      // legacy `source`/`model_version` columns are untouched.
      row.addAll(_retrainingMeta(claudeResponse));

      final inserted =
          await _client.from('diagnoses').insert(row).select('id').limit(1);
      if (inserted.isNotEmpty) return inserted.first['id']?.toString();
      return null;
    } catch (e) {
      // Print error but don't crash the app — diagnosis still shows on screen
      debugPrint('Error saving diagnosis: $e');
      return null;
    }
  }

  // Map the shown result -> {model_used, final_label, label_source,
  // escalation_reason}. Honest for every path: Mkulima, Gemini flash-lite/flash,
  // needs-expert, and the flag-off Claude path.
  static Map<String, dynamic> _retrainingMeta(Map<String, dynamic> resp) {
    final src = (resp['source'] as String?) ?? '';
    final needsExpert = resp['needs_expert'] == true;
    final healthy = resp['is_healthy'] == true;

    String modelUsed;
    String labelSource;
    if (src == 'gemini-flash') {
      modelUsed = 'gemini-flash';
      labelSource = 'flash';
    } else if (src == 'gemini-flash-lite') {
      modelUsed = 'gemini-flash-lite';
      labelSource = 'flash-lite';
    } else if (src.startsWith('mkulima')) {
      modelUsed = 'mkulima_v2';
      labelSource = 'mobilenet';
    } else {
      // claude_vision (single-stage) OR the flag-off Claude verify (no source).
      modelUsed = 'claude';
      labelSource = 'claude';
    }

    String? finalLabel;
    if (healthy) {
      finalLabel = 'Healthy';
    } else {
      finalLabel = (resp['final_label'] ??
              resp['final_diagnosis_en'] ??
              resp['disease_name_en']) as String? ??
          (needsExpert ? 'Unknown' : null);
    }

    // An explicit label_source on the map wins (e.g. open-mode results tagged
    // 'gemini-<tier>-open' by the scan pipeline); else use the derived value.
    final explicitLabelSource = resp['label_source'] as String?;

    return {
      'model_used': modelUsed,
      'final_label': finalLabel,
      'label_source': explicitLabelSource ?? labelSource,
      'escalation_reason':
          resp['escalation_reason'] as String? ?? (needsExpert ? 'needs_expert' : null),
    };
  }

  // Human confirmation/correction write-back: a farmer/agronomist confirmed (or
  // corrected) the shown label. Updates the SAME diagnoses row.
  static Future<void> confirmDiagnosisLabel({
    required String diagnosisId,
    required String finalLabel,
  }) async {
    try {
      await _client.from('diagnoses').update({
        'final_label': finalLabel,
        'label_source': 'human',
      }).eq('id', diagnosisId);
    } catch (e) {
      debugPrint('confirmDiagnosisLabel error: $e');
    }
  }

  // Get all past diagnoses for the logged-in farmer
  static Future<List<Map<String, dynamic>>> getDiagnosisHistory() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _client
          .from('diagnoses')
          .select()
          .eq('farmer_id', userId)
          .order('created_at', ascending: false)
          .limit(20);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching history: $e');
      return [];
    }
  }

  // Submit farmer feedback for the Mkulima AI training loop.
  // Uploads the photo if not yet uploaded, then writes to training_submissions.
  static Future<void> submitTrainingFeedback({
    required String diseaseKey,
    required bool isCorrect,
    required String imagePath,
    String? cropName,
    String modelVersion = 'v2',
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;

      String? photoUrl;
      if (imagePath.isNotEmpty) {
        final file = File(imagePath);
        final fileName =
            'training/${userId ?? 'anon'}/${DateTime.now().millisecondsSinceEpoch}.jpg';
        await _client.storage.from('leaf-photos').upload(fileName, file);
        photoUrl =
            _client.storage.from('leaf-photos').getPublicUrl(fileName);
      }

      await _client.from('training_submissions').insert({
        'farmer_id': userId,
        'disease_key': diseaseKey,
        'is_correct': isCorrect,
        'crop_name': cropName,
        'photo_url': photoUrl,
        'model_version': modelVersion,
      });
    } catch (e) {
      debugPrint('submitTrainingFeedback error: $e');
    }
  }

  // Get agrovets in a specific region
  static Future<List<Map<String, dynamic>>> getAgrovetsByRegion({
    required String region,
  }) async {
    try {
      final response = await _client
          .from('agrovets')
          .select()
          .eq('region', region)
          .limit(10);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching agrovets by region: $e');
      return [];
    }
  }

  // Get current market prices for a specific crop
  static Future<List<Map<String, dynamic>>> getMarketPrices({
    required String cropName,
  }) async {
    try {
      final response = await _client
          .from('market_prices')
          .select()
          .eq('crop_name', cropName)
          .order('price_date', ascending: false)
          .limit(5);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching prices: $e');
      return [];
    }
  }

  // Save soil data fetched from iSDAsoil API
  static Future<void> saveSoilData({
    required double lat,
    required double lng,
    double? ph,
    double? nitrogen,
    double? phosphorus,
    double? potassium,
    String? texture,
    String source = 'iSDAsoil',
  }) async {
    try {
      await _client.from('soil_data').insert({
        'gps_lat': lat,
        'gps_lng': lng,
        'ph': ph,
        'nitrogen': nitrogen,
        'phosphorus': phosphorus,
        'potassium': potassium,
        'texture': texture,
        'source': source,
        'fetched_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error saving soil data: $e');
    }
  }

  // Get nearby agrovets by GPS distance (region fallback)
  static Future<List<Map<String, dynamic>>> getNearbyAgrovets({
    required double lat,
    required double lng,
    double radiusKm = 50,
  }) async {
    try {
      final response = await _client
          .from('agrovets')
          .select()
          .gte('gps_lat', lat - 0.5)
          .lte('gps_lat', lat + 0.5)
          .gte('gps_lng', lng - 0.5)
          .lte('gps_lng', lng + 0.5)
          .limit(15);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching nearby agrovets: $e');
      return [];
    }
  }

  // Get all diagnoses for the logged-in farmer
  static Future<List<Map<String, dynamic>>> getFarmerDiagnoses(
      String farmerId) async {
    try {
      final response = await _client
          .from('diagnoses')
          .select()
          .eq('farmer_id', farmerId)
          .order('created_at', ascending: false)
          .limit(20);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching farmer diagnoses: $e');
      return [];
    }
  }

  // Save an irrigation plan to the database
  static Future<void> saveIrrigationPlan({
    required String cropName,
    required String soilType,
    required double farmAcres,
    required double dailyLitres,
    required Map<String, dynamic> scheduleJson,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;

      await _client.from('irrigation_plans').insert({
        'farmer_id': userId,
        'crop_name': cropName,
        'soil_type': soilType,
        'farm_acres': farmAcres,
        'daily_litres': dailyLitres,
        'schedule_json': scheduleJson,
      });
    } catch (e) {
      debugPrint('Error saving irrigation plan: $e');
    }
  }
}

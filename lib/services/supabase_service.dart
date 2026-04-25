import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  // Get the Supabase client instance
  static SupabaseClient get _client => Supabase.instance.client;

  // Save a diagnosis result to the diagnoses table
  static Future<void> saveDiagnosis({
    required String cropName,
    required Map<String, dynamic> claudeResponse,
    required String photoPath,
    double? gpsLat,
    double? gpsLng,
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

      // Insert the diagnosis record into the database
      await _client.from('diagnoses').insert({
        'farmer_id': userId,
        'crop_name': cropName,
        'disease_name_en': claudeResponse['disease_name_en'],
        'disease_name_sw': claudeResponse['disease_name_sw'],
        'confidence': claudeResponse['confidence'],
        'severity': claudeResponse['severity'],
        'photo_url': photoUrl,
        'claude_response': claudeResponse,
        'gps_lat': gpsLat,
        'gps_lng': gpsLng,
      });
    } catch (e) {
      // Print error but don't crash the app — diagnosis still shows on screen
      debugPrint('Error saving diagnosis: $e');
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

  // Get nearby agrovets from the database
  static Future<List<Map<String, dynamic>>> getNearbyAgrovets({
    required String region,
  }) async {
    try {
      final response = await _client
          .from('agrovets')
          .select()
          .eq('region', region)
          .eq('verified', true)
          .limit(10);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching agrovets: $e');
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

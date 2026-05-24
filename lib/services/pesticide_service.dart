// pesticide_service.dart
// Provides all data access methods for the Tanzania TPRI pesticide registry.
// All 208+ TPRI-registered pesticides are stored in Supabase and fetched here.

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PesticideService {
  static SupabaseClient get _db => Supabase.instance.client;

  // ── Fetch all pesticides from Supabase ──────────────────────────────────────
  // Returns every pesticide in the TPRI registry, ordered by brand name.
  static Future<List<Map<String, dynamic>>> getAllPesticides() async {
    try {
      final res = await _db
          .from('pesticides')
          .select()
          .order('brand_name');
      return (res as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('PesticideService.getAllPesticides error: $e');
      return [];
    }
  }

  // ── Fetch pesticides filtered by type ───────────────────────────────────────
  // type values: 'insecticide', 'fungicide', 'herbicide', 'acaricide', etc.
  // The 'category' column stores the type value (e.g. "insecticide").
  static Future<List<Map<String, dynamic>>> getPesticidesByType(
      String type) async {
    try {
      final res = await _db
          .from('pesticides')
          .select()
          .eq('category', type)
          .order('brand_name');
      return (res as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('PesticideService.getPesticidesByType error: $e');
      return [];
    }
  }

  // ── Fetch pesticides that target a specific crop ─────────────────────────────
  // target_crops is a Postgres TEXT[] array — uses the @> (contains) operator.
  static Future<List<Map<String, dynamic>>> getPesticidesByCrop(
      String cropName) async {
    try {
      final res = await _db
          .from('pesticides')
          .select()
          .contains('target_crops', [cropName])
          .order('brand_name');
      return (res as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('PesticideService.getPesticidesByCrop error: $e');
      return [];
    }
  }

  // ── Search pesticides by trade name or active ingredient ─────────────────────
  // Uses Supabase ilike (case-insensitive LIKE) on two columns.
  static Future<List<Map<String, dynamic>>> searchPesticides(
      String query) async {
    if (query.trim().isEmpty) return getAllPesticides();
    try {
      final q = '%$query%';
      final res = await _db
          .from('pesticides')
          .select()
          .or('brand_name.ilike.$q,active_ingredient.ilike.$q')
          .order('brand_name');
      return (res as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('PesticideService.searchPesticides error: $e');
      return [];
    }
  }

  // ── Fetch one pesticide by its database ID ───────────────────────────────────
  static Future<Map<String, dynamic>?> getPesticideById(int id) async {
    try {
      final res = await _db
          .from('pesticides')
          .select()
          .eq('id', id)
          .single();
      return Map<String, dynamic>.from(res as Map);
    } catch (e) {
      debugPrint('PesticideService.getPesticideById error: $e');
      return null;
    }
  }

  // ── Get pesticides relevant to a diagnosed disease + crop ───────────────────
  // Used by ResultsScreen after AI diagnosis to suggest treatments.
  // Matches on: pesticide type relevant to disease, crop in target_crops.
  static Future<List<Map<String, dynamic>>> getPesticidesByDisease(
    String diseaseName,
    String cropName,
  ) async {
    try {
      // Determine relevant pesticide type from disease keywords
      final lower = diseaseName.toLowerCase();
      String typeFilter;
      if (lower.contains('fungus') || lower.contains('blight') ||
          lower.contains('rust') || lower.contains('mold') ||
          lower.contains('kuvu') || lower.contains('ukungu')) {
        typeFilter = 'fungicide';
      } else if (lower.contains('weed') || lower.contains('gugu')) {
        typeFilter = 'herbicide';
      } else if (lower.contains('mite') || lower.contains('spider') ||
          lower.contains('utitiri')) {
        typeFilter = 'acaricide';
      } else {
        // Default to insecticide for most pest/disease queries
        typeFilter = 'insecticide';
      }

      // Normalise crop name to what's stored in target_crops array
      final cropKey = _normaliseCropName(cropName);

      // Try crop-specific first
      List<Map<String, dynamic>> results = [];
      if (cropKey.isNotEmpty) {
        final r = await _db
            .from('pesticides')
            .select()
            .eq('category', typeFilter)
            .contains('target_crops', [cropKey])
            .order('brand_name')
            .limit(5);
        results = (r as List).cast<Map<String, dynamic>>();
      }

      // Fall back to type-only if no crop-specific results
      if (results.isEmpty) {
        final r = await _db
            .from('pesticides')
            .select()
            .eq('category', typeFilter)
            .order('brand_name')
            .limit(5);
        results = (r as List).cast<Map<String, dynamic>>();
      }

      return results;
    } catch (e) {
      debugPrint('PesticideService.getPesticidesByDisease error: $e');
      return [];
    }
  }

  // ── Get restricted pesticides only ──────────────────────────────────────────
  // Restricted pesticides require special permits from TPHPA.
  static Future<List<Map<String, dynamic>>> getRestrictedPesticides() async {
    try {
      final res = await _db
          .from('pesticides')
          .select()
          .eq('category', 'restricted_herbicide')
          .order('brand_name');
      return (res as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('PesticideService.getRestrictedPesticides error: $e');
      return [];
    }
  }

  // ── Get pesticide type display label in Swahili ──────────────────────────────
  static String getTypeLabel(String? category) {
    switch (category) {
      case 'insecticide':            return 'Dawa ya Wadudu';
      case 'herbicide':              return 'Dawa ya Magugu';
      case 'fungicide':              return 'Dawa ya Kuvu';
      case 'acaricide':              return 'Dawa ya Utitiri';
      case 'plant_growth_regulator': return 'Dawa ya Ukuaji';
      case 'rodenticide':            return 'Dawa ya Panya';
      case 'avicide':                return 'Dawa ya Ndege';
      case 'nematicide':             return 'Dawa ya Minyoo';
      case 'restricted_herbicide':   return 'Marufuku';
      default:                       return 'Dawa ya Kilimo';
    }
  }

  // ── Get badge colour for pesticide type ──────────────────────────────────────
  static int getTypeColor(String? category) {
    switch (category) {
      case 'insecticide':            return 0xFF1565C0; // blue
      case 'herbicide':              return 0xFF2E7D32; // green
      case 'fungicide':              return 0xFFE65100; // orange
      case 'acaricide':              return 0xFFB71C1C; // red
      case 'plant_growth_regulator': return 0xFF6A1B9A; // purple
      case 'rodenticide':            return 0xFF4E342E; // brown
      case 'nematicide':             return 0xFF00695C; // teal
      case 'restricted_herbicide':   return 0xFFBF360C; // deep orange
      default:                       return 0xFF546E7A; // grey
    }
  }

  // ── Private: normalise crop name to database key ─────────────────────────────
  static String _normaliseCropName(String crop) {
    final lower = crop.toLowerCase().trim();
    if (lower.contains('mahindi') || lower.contains('maize')) return 'maize';
    if (lower.contains('nyanya') || lower.contains('tomato')) return 'tomato';
    if (lower.contains('maharagwe') || lower.contains('bean')) return 'beans';
    if (lower.contains('pamba') || lower.contains('cotton')) return 'cotton';
    if (lower.contains('kahawa') || lower.contains('coffee')) return 'coffee';
    if (lower.contains('tumbaku') || lower.contains('tobacco')) return 'tobacco';
    if (lower.contains('ngano') || lower.contains('wheat')) return 'wheat';
    if (lower.contains('mchele') || lower.contains('rice')) return 'rice';
    if (lower.contains('korosho') || lower.contains('cashew')) return 'cashew';
    if (lower.contains('ndizi') || lower.contains('banana')) return 'banana';
    if (lower.contains('muhogo') || lower.contains('cassava')) return 'cassava';
    return '';
  }
}

import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_keys.dart';

// Planet Labs satellite data service
// If no API key: returns realistic demo NDVI data for Tanzania
class PlanetService {
  static const String _baseUrl = 'https://api.planet.com/data/v1';

  static bool get hasKey => ApiKeys.hasPlanet;

  // Get NDVI for farm coordinates — returns map with ndvi value and metadata
  static Future<Map<String, dynamic>> getFarmNDVI({
    required double lat,
    required double lng,
    required double farmAcres,
  }) async {
    if (!hasKey) {
      return _demoNdviData(lat, lng);
    }

    try {
      // 1. Search for recent satellite imagery
      final searchResult = await _searchImagery(lat, lng);
      if (searchResult == null) return _demoNdviData(lat, lng);

      // 2. Get NDVI statistics for the scene
      final ndvi = await _getNdviStats(searchResult['id'] as String, lat, lng);
      return ndvi ?? _demoNdviData(lat, lng);
    } catch (e) {
      debugPrint('PlanetService error: $e');
      return _demoNdviData(lat, lng);
    }
  }

  static Future<Map<String, dynamic>?> _searchImagery(
      double lat, double lng) async {
    final body = {
      'item_types': ['PSScene'],
      'filter': {
        'type': 'AndFilter',
        'config': [
          {
            'type': 'GeometryFilter',
            'field_name': 'geometry',
            'config': {
              'type': 'Point',
              'coordinates': [lng, lat],
            },
          },
          {
            'type': 'DateRangeFilter',
            'field_name': 'acquired',
            'config': {
              'gte': DateTime.now()
                  .subtract(const Duration(days: 14))
                  .toIso8601String(),
              'lte': DateTime.now().toIso8601String(),
            },
          },
          {
            'type': 'RangeFilter',
            'field_name': 'cloud_cover',
            'config': {'lte': 0.3},
          },
        ],
      },
    };

    final response = await http
        .post(
          Uri.parse('$_baseUrl/quick-search'),
          headers: {
            'Authorization': 'api-key ${ApiKeys.planetApiKey}',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final features = (data['features'] as List?) ?? [];
      return features.isNotEmpty
          ? features.first as Map<String, dynamic>
          : null;
    }
    return null;
  }

  static Future<Map<String, dynamic>?> _getNdviStats(
      String sceneId, double lat, double lng) async {
    // Planet NDVI endpoint (requires Assets API + activated scene)
    final response = await http.get(
      Uri.parse('$_baseUrl/item-types/PSScene/items/$sceneId'),
      headers: {'Authorization': 'api-key ${ApiKeys.planetApiKey}'},
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final props = data['properties'] as Map<String, dynamic>?;
      return {
        'ndvi': _estimateNdviFromSatData(props),
        'scene_id': sceneId,
        'cloud_cover': props?['cloud_cover'] ?? 0.1,
        'acquired': props?['acquired'],
        'source': 'Planet Labs',
      };
    }
    return null;
  }

  static double _estimateNdviFromSatData(Map<String, dynamic>? props) {
    // Approximate NDVI from vegetation_percentage if NDVI band unavailable
    final veg = (props?['vegetation_percentage'] as num?)?.toDouble() ?? 0.5;
    return (veg * 0.7).clamp(0.1, 0.9);
  }

  // Realistic demo NDVI based on Tanzania geography and season
  static Map<String, dynamic> _demoNdviData(double lat, double lng) {
    final rng = Random(lat.toInt() * 100 + lng.toInt());
    final month = DateTime.now().month;

    // Tanzania rainy seasons: Mar-May (masika), Oct-Dec (vuli)
    final isRainySeason = (month >= 3 && month <= 5) || (month >= 10 && month <= 12);
    final baseNdvi = isRainySeason ? 0.55 : 0.38;
    final noise = (rng.nextDouble() - 0.5) * 0.12;
    final ndvi = (baseNdvi + noise).clamp(0.15, 0.85);

    final healthLabel = ndvi >= 0.6
        ? 'Mazao Mazuri Sana'
        : ndvi >= 0.4
            ? 'Mazao ya Wastani'
            : ndvi >= 0.25
                ? 'Mazao Dhaifu'
                : 'Mazao Mbaya — Hatua ya Haraka';

    return {
      'ndvi': double.parse(ndvi.toStringAsFixed(3)),
      'ndvi_label': healthLabel,
      'cloud_cover': rng.nextDouble() * 0.15,
      'acquired': DateTime.now()
          .subtract(Duration(days: rng.nextInt(3)))
          .toIso8601String(),
      'source': 'Demo (Planet key haipo)',
      'is_demo': true,
    };
  }

  // Historical NDVI trend (last 30 days)
  static List<Map<String, dynamic>> getDemoNdviTrend(
      double lat, double lng, int days) {
    final rng = Random(lat.toInt() * 10 + lng.toInt());
    final now = DateTime.now();
    final trend = <Map<String, dynamic>>[];

    for (int i = days; i >= 0; i -= 3) {
      final date = now.subtract(Duration(days: i));
      final growthFactor = 1.0 - (i / (days * 1.5));
      final base = 0.28 + (0.40 * growthFactor);
      final noise = (rng.nextDouble() - 0.5) * 0.08;
      final ndvi = (base + noise).clamp(0.1, 0.85);

      trend.add({
        'date': date.toIso8601String().substring(0, 10),
        'ndvi': double.parse(ndvi.toStringAsFixed(3)),
      });
    }
    return trend;
  }
}

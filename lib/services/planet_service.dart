import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PlanetService {
  static Future<dynamic> _proxy({
    required String method,
    required String path,
    Map<String, dynamic>? body,
  }) async {
    final res = await Supabase.instance.client.functions.invoke(
      'satellite-proxy',
      body: {
        'service': 'planet',
        'method': method,
        'path': path,
        if (body != null) 'body': body,
      },
    );
    return res.data;
  }

  static Future<Map<String, dynamic>> getFarmNDVI({
    required double lat,
    required double lng,
    required double farmAcres,
  }) async {
    try {
      final searchResult = await _searchImagery(lat, lng);
      if (searchResult == null) return _demoNdviData(lat, lng);

      final ndvi = await _getNdviStats(searchResult['id'] as String, lat, lng);
      return ndvi ?? _demoNdviData(lat, lng);
    } catch (e) {
      debugPrint('PlanetService error: $e');
      return _demoNdviData(lat, lng);
    }
  }

  static Future<Map<String, dynamic>?> _searchImagery(
      double lat, double lng) async {
    try {
      final data = await _proxy(
        method: 'POST',
        path: '/quick-search',
        body: {
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
        },
      );
      final features = ((data as Map<String, dynamic>)['features'] as List?) ?? [];
      return features.isNotEmpty ? features.first as Map<String, dynamic> : null;
    } catch (e) {
      debugPrint('PlanetService _searchImagery error: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> _getNdviStats(
      String sceneId, double lat, double lng) async {
    try {
      final data = await _proxy(
        method: 'GET',
        path: '/item-types/PSScene/items/$sceneId',
      );
      final props =
          (data as Map<String, dynamic>)['properties'] as Map<String, dynamic>?;
      return {
        'ndvi': _estimateNdviFromSatData(props),
        'scene_id': sceneId,
        'cloud_cover': props?['cloud_cover'] ?? 0.1,
        'acquired': props?['acquired'],
        'source': 'Planet Labs',
      };
    } catch (e) {
      debugPrint('PlanetService _getNdviStats error: $e');
      return null;
    }
  }

  static double _estimateNdviFromSatData(Map<String, dynamic>? props) {
    final veg = (props?['vegetation_percentage'] as num?)?.toDouble() ?? 0.5;
    return (veg * 0.7).clamp(0.1, 0.9);
  }

  static Map<String, dynamic> _demoNdviData(double lat, double lng) {
    final rng = Random(lat.toInt() * 100 + lng.toInt());
    final month = DateTime.now().month;
    final isRainySeason =
        (month >= 3 && month <= 5) || (month >= 10 && month <= 12);
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

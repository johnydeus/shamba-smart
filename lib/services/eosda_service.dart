import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:latlong2/latlong.dart';
import '../models/satellite_models.dart';

class EosdaService {
  static Future<dynamic> _proxy({
    required String method,
    required String path,
    Map<String, dynamic>? query,
    Map<String, dynamic>? body,
  }) async {
    final res = await Supabase.instance.client.functions.invoke(
      'satellite-proxy',
      body: {
        'service': 'eosda',
        'method': method,
        'path': path,
        if (query != null) 'query': query,
        if (body != null) 'body': body,
      },
    );
    return res.data;
  }

  // ── Create a polygon (field boundary) ─────────────────────────────────────

  Future<String> createPolygon({
    required String fieldName,
    required List<LatLng> coordinates,
  }) async {
    try {
      final coords = [
        ...coordinates.map((c) => [c.longitude, c.latitude]),
        [coordinates.first.longitude, coordinates.first.latitude],
      ];

      final data = await _proxy(
        method: 'POST',
        path: '/polygons',
        body: {
          'name': 'Shamba - $fieldName',
          'geo_json': {
            'type': 'Feature',
            'properties': {},
            'geometry': {
              'type': 'Polygon',
              'coordinates': [coords],
            },
          },
        },
      );
      return (data as Map<String, dynamic>)['id'] as String;
    } catch (e) {
      debugPrint('EOSDA createPolygon error: $e');
      return 'demo_polygon_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  // ── Fetch NDWI statistics ──────────────────────────────────────────────────

  Future<List<NdwiReading>> getNdwiStats({
    required String polygonId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (polygonId.startsWith('demo_')) return _demoNdwiReadings();

    try {
      final raw = await _proxy(
        method: 'GET',
        path: '/ndwi/statistics',
        query: {'polyid': polygonId},
      );
      final list = (raw as List?) ?? [];
      return list
          .map((e) => NdwiReading.fromJson(e as Map<String, dynamic>))
          .where((r) => r.date.isAfter(startDate) && r.date.isBefore(endDate))
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));
    } catch (e) {
      debugPrint('EOSDA getNdwiStats error: $e');
    }
    return _demoNdwiReadings();
  }

  // ── Fetch NDVI statistics ──────────────────────────────────────────────────

  Future<List<NdviReading>> getNdviStats({
    required String polygonId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (polygonId.startsWith('demo_')) return _demoNdviReadings();

    try {
      final raw = await _proxy(
        method: 'GET',
        path: '/ndvi/statistics',
        query: {'polyid': polygonId},
      );
      final list = (raw as List?) ?? [];
      return list
          .map((e) => NdviReading.fromJson(e as Map<String, dynamic>))
          .where((r) => r.date.isAfter(startDate) && r.date.isBefore(endDate))
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));
    } catch (e) {
      debugPrint('EOSDA getNdviStats error: $e');
    }
    return _demoNdviReadings();
  }

  // ── Fetch satellite image tile URL ─────────────────────────────────────────

  Future<String?> getNdviTileUrl({
    required String polygonId,
    required DateTime date,
  }) async {
    if (polygonId.startsWith('demo_')) return null;

    try {
      final start =
          date.subtract(const Duration(days: 7)).millisecondsSinceEpoch ~/ 1000;
      final end = date.millisecondsSinceEpoch ~/ 1000;

      final raw = await _proxy(
        method: 'GET',
        path: '/image/search',
        query: {
          'start': start.toString(),
          'end': end.toString(),
          'polyid': polygonId,
          'resolution': 'high',
        },
      );
      final list = (raw as List?) ?? [];
      if (list.isNotEmpty) {
        return (list.first as Map<String, dynamic>)['tile_url'] as String?;
      }
    } catch (e) {
      debugPrint('EOSDA getTileUrl error: $e');
    }
    return null;
  }

  // ── Fetch weather data for field ───────────────────────────────────────────

  Future<Map<String, dynamic>> getWeatherData({
    required String polygonId,
  }) async {
    if (polygonId.startsWith('demo_')) return _demoWeatherData();

    try {
      final data = await _proxy(
        method: 'GET',
        path: '/weather',
        query: {'polyid': polygonId},
      );
      return data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('EOSDA getWeatherData error: $e');
    }
    return _demoWeatherData();
  }

  // ── Demo data generators ───────────────────────────────────────────────────

  List<NdviReading> _demoNdviReadings() {
    final rng = Random(42);
    final now = DateTime.now();
    final readings = <NdviReading>[];

    for (int i = 30; i >= 0; i -= 3) {
      final date = now.subtract(Duration(days: i));
      final growthFactor = 1.0 - (i / 60.0);
      final base = 0.25 + (0.45 * growthFactor);
      final noise = (rng.nextDouble() - 0.5) * 0.08;
      final avg = (base + noise).clamp(0.1, 0.85);

      readings.add(NdviReading(
        date: date,
        average: double.parse(avg.toStringAsFixed(3)),
        min: double.parse((avg - 0.15).clamp(0.0, 1.0).toStringAsFixed(3)),
        max: double.parse((avg + 0.15).clamp(0.0, 1.0).toStringAsFixed(3)),
        cloudCover: rng.nextDouble() * 0.2,
      ));
    }
    return readings;
  }

  List<NdwiReading> _demoNdwiReadings() {
    final rng = Random(99);
    final now = DateTime.now();
    final readings = <NdwiReading>[];

    for (int i = 30; i >= 0; i -= 3) {
      final date = now.subtract(Duration(days: i));
      final base = -0.15 + (0.35 * (1.0 - i / 40.0));
      final noise = (rng.nextDouble() - 0.5) * 0.1;
      final avg = (base + noise).clamp(-0.4, 0.4);

      readings.add(NdwiReading(
        date: date,
        average: double.parse(avg.toStringAsFixed(3)),
        min: double.parse((avg - 0.1).clamp(-1.0, 1.0).toStringAsFixed(3)),
        max: double.parse((avg + 0.1).clamp(-1.0, 1.0).toStringAsFixed(3)),
        cloudCover: rng.nextDouble() * 0.2,
      ));
    }
    return readings;
  }

  Map<String, dynamic> _demoWeatherData() => {
        'main': {'temp': 27.4, 'humidity': 68, 'pressure': 1013},
        'rain': {'1h': 0.0},
        'wind': {'speed': 3.2},
        'weather': [
          {'description': 'partly cloudy'}
        ],
      };
}

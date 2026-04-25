import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/satellite_models.dart';

class EosdaService {
  static const String _baseUrl =
      'https://api.agromonitoring.com/agro/1.0';

  // API key injected at build time via --dart-define=EOSDA_API_KEY=xxx
  static const String _apiKey =
      String.fromEnvironment('EOSDA_API_KEY', defaultValue: '');

  bool get hasApiKey => _apiKey.isNotEmpty;

  // ── Create a polygon (field boundary) ─────────────────────────────────────

  Future<String> createPolygon({
    required String fieldName,
    required List<LatLng> coordinates,
  }) async {
    if (!hasApiKey) {
      // Return a demo ID when no key is configured
      return 'demo_polygon_${DateTime.now().millisecondsSinceEpoch}';
    }

    try {
      // GeoJSON requires the polygon to be closed (first = last point)
      final coords = [
        ...coordinates.map((c) => [c.longitude, c.latitude]),
        [coordinates.first.longitude, coordinates.first.latitude],
      ];

      final response = await http.post(
        Uri.parse('$_baseUrl/polygons?apikey=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': 'Shamba - $fieldName',
          'geo_json': {
            'type': 'Feature',
            'properties': {},
            'geometry': {
              'type': 'Polygon',
              'coordinates': [coords],
            },
          },
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['id'] as String;
      } else {
        debugPrint('EOSDA createPolygon error: ${response.statusCode}');
        return 'demo_polygon_${DateTime.now().millisecondsSinceEpoch}';
      }
    } catch (e) {
      debugPrint('EOSDA createPolygon exception: $e');
      return 'demo_polygon_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  // ── Fetch NDWI statistics (Water stress index) ────────────────────────────
  // NDWI = (Green − NIR) / (Green + NIR) — measures crop water content

  Future<List<NdwiReading>> getNdwiStats({
    required String polygonId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (!hasApiKey || polygonId.startsWith('demo_')) {
      return _demoNdwiReadings();
    }

    try {
      final response = await http.get(
        Uri.parse(
            '$_baseUrl/ndwi/statistics?polyid=$polygonId&apikey=$_apiKey'),
      );

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        return list
            .map((e) => NdwiReading.fromJson(e as Map<String, dynamic>))
            .where((r) =>
                r.date.isAfter(startDate) && r.date.isBefore(endDate))
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));
      }
    } catch (e) {
      debugPrint('EOSDA getNdwiStats exception: $e');
    }

    return _demoNdwiReadings();
  }

  // ── Fetch NDVI statistics ──────────────────────────────────────────────────

  Future<List<NdviReading>> getNdviStats({
    required String polygonId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // Always return demo data for demo polygon IDs or missing key
    if (!hasApiKey || polygonId.startsWith('demo_')) {
      return _demoNdviReadings();
    }

    try {
      final response = await http.get(
        Uri.parse(
            '$_baseUrl/ndvi/statistics?polyid=$polygonId&apikey=$_apiKey'),
      );

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        return list
            .map((e) => NdviReading.fromJson(e as Map<String, dynamic>))
            .where((r) =>
                r.date.isAfter(startDate) && r.date.isBefore(endDate))
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));
      }
    } catch (e) {
      debugPrint('EOSDA getNdviStats exception: $e');
    }

    return _demoNdviReadings();
  }

  // ── Fetch satellite image tile URL ─────────────────────────────────────────

  Future<String?> getNdviTileUrl({
    required String polygonId,
    required DateTime date,
  }) async {
    if (!hasApiKey || polygonId.startsWith('demo_')) return null;

    try {
      final start =
          (date.subtract(const Duration(days: 7)).millisecondsSinceEpoch ~/
              1000);
      final end = (date.millisecondsSinceEpoch ~/ 1000);

      final response = await http.get(
        Uri.parse(
            '$_baseUrl/image/search?start=$start&end=$end&polyid=$polygonId&apikey=$_apiKey&resolution=high'),
      );

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        if (list.isNotEmpty) {
          return list.first['tile_url'] as String?;
        }
      }
    } catch (e) {
      debugPrint('EOSDA getTileUrl exception: $e');
    }
    return null;
  }

  // ── Fetch weather data for field ───────────────────────────────────────────

  Future<Map<String, dynamic>> getWeatherData({
    required String polygonId,
  }) async {
    if (!hasApiKey || polygonId.startsWith('demo_')) {
      return _demoWeatherData();
    }

    try {
      final response = await http.get(
        Uri.parse(
            '$_baseUrl/weather?polyid=$polygonId&apikey=$_apiKey'),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('EOSDA getWeatherData exception: $e');
    }
    return _demoWeatherData();
  }

  // ── Demo data generators ───────────────────────────────────────────────────

  // Generates 30 days of realistic Tanzania maize crop NDVI data
  List<NdviReading> _demoNdviReadings() {
    final rng = Random(42); // fixed seed for consistency
    final now = DateTime.now();
    final readings = <NdviReading>[];

    // Simulate a growing crop: NDVI rises then plateaus
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

  // Demo NDWI — correlates with NDVI but reflects soil moisture separately
  List<NdwiReading> _demoNdwiReadings() {
    final rng = Random(99); // different seed from NDVI
    final now = DateTime.now();
    final readings = <NdwiReading>[];

    // NDWI pattern: starts moderately stressed, improves with rainfall simulation
    for (int i = 30; i >= 0; i -= 3) {
      final date = now.subtract(Duration(days: i));
      // NDWI for crops typically ranges -0.3 to 0.3
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
        'main': {
          'temp': 27.4,
          'humidity': 68,
          'pressure': 1013,
        },
        'rain': {'1h': 0.0},
        'wind': {'speed': 3.2},
        'weather': [
          {'description': 'partly cloudy'}
        ],
      };
}

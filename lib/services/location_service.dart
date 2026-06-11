import 'dart:async';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

class LocationService {
  static const double _minLat = -11.7;
  static const double _maxLat = -1.0;
  static const double _minLng = 29.3;
  static const double _maxLng = 40.4;

  // Default: Kilosa, Morogoro
  static const double defaultLat = -6.8;
  static const double defaultLng = 36.9;

  // ── Original single-reading method (backward compatible) ─────────────────
  static Future<Position> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception(
          'GPS imezimwa. Washa GPS kwenye mipangilio ya simu yako.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception(
            'Ruhusa ya GPS imekataliwa. Tafadhali ruhusu app kupata mahali.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      await ph.openAppSettings();
      throw Exception(
          'Ruhusa ya GPS imezuiwa kabisa. Tumekufungua Settings — '
          'washa ruhusa ya Mahali (Location) kwa Shamba Smart.');
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
    } on TimeoutException {
      throw Exception(
          'Muda umekwisha kupata GPS. Hakikisha uko mahali wazi na jaribu tena.');
    } catch (e) {
      throw Exception('Hitilafu ya GPS: ${e.toString()}');
    }
  }

  // Returns GPS or Tanzania default if unavailable (never throws)
  static Future<(double lat, double lng)> getLocationOrDefault() async {
    try {
      final pos = await getCurrentLocation();
      if (isInTanzania(pos.latitude, pos.longitude)) {
        return (pos.latitude, pos.longitude);
      }
    } catch (_) {}
    return (defaultLat, defaultLng);
  }

  // ── HIGH ACCURACY multi-reading method ────────────────────────────────────
  // Takes 3-5 readings, picks the most accurate, validates Tanzania bounds.
  // Use this for iSDAsoil/SoilGrids API calls.
  static Future<Map<String, dynamic>> getHighAccuracyLocation({
    int maxWaitSeconds = 30,
    double maxAcceptableAccuracyMetres = 50.0,
  }) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return {
        'success': false,
        'error': 'GPS imezimwa. Washa GPS kwenye mipangilio ya simu.',
        'error_type': 'service_disabled',
      };
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return {
        'success': false,
        'error': 'Ruhusa ya GPS haikupewa. '
            'Tafadhali washa GPS kwenye mipangilio.',
        'error_type': 'permission_denied',
      };
    }

    final readings = <Position>[];
    final completer = Completer<void>();
    StreamSubscription<Position>? sub;

    try {
      sub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 0,
        ),
      ).listen(
        (pos) {
          readings.add(pos);
          // Stop immediately if we get a very accurate fix (< 20m)
          if (pos.accuracy <= 20.0 || readings.length >= 5) {
            if (!completer.isCompleted) completer.complete();
          }
        },
        onError: (e) {
          if (!completer.isCompleted) completer.completeError(e);
        },
        cancelOnError: true,
      );

      // Wait for readings or timeout
      await Future.any([
        completer.future,
        Future.delayed(Duration(seconds: maxWaitSeconds)),
      ]);
    } catch (_) {
      // Stream failed — try one-shot fallback
    } finally {
      await sub?.cancel();
    }

    // Fallback: one-shot getCurrentPosition if stream yielded nothing
    if (readings.isEmpty) {
      try {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 15),
        );
        readings.add(pos);
      } catch (_) {
        return {
          'success': false,
          'error': 'Imeshindwa kupata GPS. Jaribu nje au mbali na majengo.',
          'error_type': 'no_readings',
        };
      }
    }

    // Sort by accuracy: lowest number = most precise
    readings.sort((a, b) => a.accuracy.compareTo(b.accuracy));
    final best = readings.first;

    // Average the top 3 readings for stability
    final top = readings.take(3).toList();
    final avgLat =
        top.map((p) => p.latitude).reduce((a, b) => a + b) / top.length;
    final avgLng =
        top.map((p) => p.longitude).reduce((a, b) => a + b) / top.length;

    // Tanzania boundary check
    if (!isInTanzania(best.latitude, best.longitude)) {
      return {
        'success': false,
        'error': 'Mahali pako haiko Tanzania. '
            'Angalia kama GPS inafanya kazi vizuri.',
        'error_type': 'outside_tanzania',
        'lat': best.latitude,
        'lng': best.longitude,
        'accuracy_metres': best.accuracy,
      };
    }

    final isAccurate = best.accuracy <= maxAcceptableAccuracyMetres;

    String accuracyLabel;
    String accuracyColor;
    if (best.accuracy <= 10) {
      accuracyLabel = 'Bora sana (${best.accuracy.round()}m)';
      accuracyColor = 'green';
    } else if (best.accuracy <= 30) {
      accuracyLabel = 'Nzuri (${best.accuracy.round()}m)';
      accuracyColor = 'green';
    } else if (best.accuracy <= 50) {
      accuracyLabel = 'Ya kutosha (${best.accuracy.round()}m)';
      accuracyColor = 'orange';
    } else {
      accuracyLabel = 'Chini (${best.accuracy.round()}m)';
      accuracyColor = 'red';
    }

    return {
      'success': true,
      'lat': best.latitude,
      'lng': best.longitude,
      'avg_lat': avgLat,
      'avg_lng': avgLng,
      // Use averaged coords when we have 3+ readings
      'recommended_lat': top.length >= 3 ? avgLat : best.latitude,
      'recommended_lng': top.length >= 3 ? avgLng : best.longitude,
      'accuracy_metres': best.accuracy,
      'is_accurate': isAccurate,
      'readings_taken': readings.length,
      'timestamp': DateTime.now().toIso8601String(),
      'altitude': best.altitude,
      'accuracy_label': accuracyLabel,
      'accuracy_color': accuracyColor,
    };
  }

  // ── Manual coordinate validation ──────────────────────────────────────────
  static Map<String, dynamic> validateManualCoordinates(
      double lat, double lng) {
    if (!isInTanzania(lat, lng)) {
      return {
        'success': false,
        'error': 'Kuratibu hizi ziko nje ya Tanzania. '
            'Latitudo: -11.7 hadi -1.0, Longitudo: 29.3 hadi 40.4',
      };
    }
    return {
      'success': true,
      'lat': lat,
      'lng': lng,
      'recommended_lat': lat,
      'recommended_lng': lng,
      'accuracy_metres': 0.0,
      'accuracy_label': 'Iliyowekwa mkono',
      'accuracy_color': 'blue',
      'is_manual': true,
      'is_accurate': true,
      'readings_taken': 0,
    };
  }

  static bool isInTanzania(double lat, double lng) =>
      lat >= _minLat && lat <= _maxLat && lng >= _minLng && lng <= _maxLng;

  // Haversine formula — distance in km between two GPS points
  static double calculateDistance(
      double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) *
            cos(_toRad(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  static double _toRad(double deg) => deg * pi / 180;

  static Stream<Position> positionStream() => Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 50,
        ),
      );

  // ── Region from approximate coordinates ──────────────────────────────────
  // Fine-grained Tanzania region lookup
  static String getRegionFromCoordinates(double lat, double lng) {
    final regions = [
      {
        'name': 'Dar es Salaam',
        'latMin': -7.1,
        'latMax': -6.5,
        'lngMin': 39.0,
        'lngMax': 39.6
      },
      {
        'name': 'Morogoro',
        'latMin': -9.5,
        'latMax': -5.8,
        'lngMin': 35.5,
        'lngMax': 38.5
      },
      {
        'name': 'Arusha',
        'latMin': -4.5,
        'latMax': -2.5,
        'lngMin': 35.5,
        'lngMax': 38.0
      },
      {
        'name': 'Kilimanjaro',
        'latMin': -4.2,
        'latMax': -2.8,
        'lngMin': 37.0,
        'lngMax': 38.2
      },
      {
        'name': 'Mbeya',
        'latMin': -9.8,
        'latMax': -7.5,
        'lngMin': 32.5,
        'lngMax': 35.5
      },
      {
        'name': 'Iringa',
        'latMin': -8.8,
        'latMax': -6.5,
        'lngMin': 34.5,
        'lngMax': 36.8
      },
      {
        'name': 'Dodoma',
        'latMin': -7.5,
        'latMax': -5.0,
        'lngMin': 35.0,
        'lngMax': 37.5
      },
      {
        'name': 'Mwanza',
        'latMin': -3.5,
        'latMax': -1.5,
        'lngMin': 31.5,
        'lngMax': 34.5
      },
      {
        'name': 'Tanga',
        'latMin': -5.5,
        'latMax': -3.5,
        'lngMin': 37.5,
        'lngMax': 40.0
      },
      {
        'name': 'Pwani',
        'latMin': -9.0,
        'latMax': -6.0,
        'lngMin': 38.5,
        'lngMax': 40.5
      },
      {
        'name': 'Ruvuma',
        'latMin': -11.7,
        'latMax': -9.0,
        'lngMin': 34.0,
        'lngMax': 38.5
      },
      {
        'name': 'Kigoma',
        'latMin': -6.5,
        'latMax': -3.5,
        'lngMin': 29.3,
        'lngMax': 31.8
      },
      {
        'name': 'Kagera',
        'latMin': -2.5,
        'latMax': -1.0,
        'lngMin': 30.5,
        'lngMax': 32.5
      },
      {
        'name': 'Mara',
        'latMin': -2.5,
        'latMax': -1.0,
        'lngMin': 33.5,
        'lngMax': 35.5
      },
      {
        'name': 'Tabora',
        'latMin': -7.5,
        'latMax': -4.0,
        'lngMin': 32.0,
        'lngMax': 35.5
      },
      {
        'name': 'Singida',
        'latMin': -7.5,
        'latMax': -4.5,
        'lngMin': 33.5,
        'lngMax': 36.0
      },
      {
        'name': 'Geita',
        'latMin': -3.5,
        'latMax': -2.0,
        'lngMin': 31.5,
        'lngMax': 33.0
      },
      {
        'name': 'Simiyu',
        'latMin': -3.5,
        'latMax': -2.0,
        'lngMin': 33.5,
        'lngMax': 35.0
      },
      {
        'name': 'Njombe',
        'latMin': -10.0,
        'latMax': -8.0,
        'lngMin': 34.5,
        'lngMax': 36.5
      },
      {
        'name': 'Katavi',
        'latMin': -7.5,
        'latMax': -5.5,
        'lngMin': 30.5,
        'lngMax': 33.0
      },
    ];

    for (final r in regions) {
      if (lat >= (r['latMin'] as num) &&
          lat <= (r['latMax'] as num) &&
          lng >= (r['lngMin'] as num) &&
          lng <= (r['lngMax'] as num)) {
        return r['name'] as String;
      }
    }
    return 'Tanzania';
  }

  // Backward-compatible alias used by existing screens
  static String regionFromCoords(double lat, double lng) {
    if (lat > -3.5) return 'Kaskazini (Arusha/Kilimanjaro)';
    if (lat > -5.5 && lng > 37.5) return 'Pwani / Tanga';
    if (lat > -5.5 && lng < 35) return 'Kigoma / Tabora';
    if (lat > -7.5 && lng > 37) return 'Morogoro';
    if (lat > -7.5 && lng < 35) return 'Tabora / Singida';
    if (lat < -8.5 && lng > 33) return 'Mbeya / Iringa';
    if (lat < -9.5) return 'Ruvuma / Mtwara / Lindi';
    if (lng < 32.5) return 'Kagera / Mwanza';
    return 'Dodoma / Kusini';
  }
}

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

  static Future<Position> getCurrentLocation() async {
    // 1. Check if device GPS is enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception(
          'GPS imezimwa. Washa GPS kwenye mipangilio ya simu yako.');
    }

    // 2. Check and request location permission
    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception(
            'Ruhusa ya GPS imekataliwa. Tafadhali ruhusu app kupata mahali.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Open device app settings so user can manually grant permission
      await ph.openAppSettings();
      throw Exception(
          'Ruhusa ya GPS imezuiwa kabisa. Tumekufungua Settings — '
          'washa ruhusa ya Mahali (Location) kwa Shamba Smart.');
    }

    // 3. Fetch high-accuracy position with 15-second timeout
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

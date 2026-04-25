import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/satellite_models.dart';
import '../services/eosda_service.dart';
import '../services/crop_analysis_service.dart';

const _kField        = 'ss_satellite_field';
const _kReadings     = 'ss_ndvi_readings';
const _kNdwiReadings = 'ss_ndwi_readings';

enum SatelliteStatus { idle, locating, fetching, analyzing, ready, error }

class SatelliteProvider extends ChangeNotifier {
  final EosdaService _eosda = EosdaService();
  late final CropAnalysisService _analyzer;

  FieldPolygon? _field;
  List<NdviReading> _ndviReadings = [];
  List<NdwiReading> _ndwiReadings = [];
  CropAnalysisReport? _report;
  SatelliteStatus _status = SatelliteStatus.idle;
  String _statusMessage = '';
  String _error = '';

  SatelliteProvider() {
    _analyzer = CropAnalysisService(_eosda);
  }

  FieldPolygon?          get field        => _field;
  List<NdviReading>      get ndviReadings => _ndviReadings;
  List<NdwiReading>      get ndwiReadings => _ndwiReadings;
  CropAnalysisReport?    get report       => _report;
  SatelliteStatus        get status       => _status;
  String                 get statusMessage => _statusMessage;
  String                 get error        => _error;
  bool                   get hasField     => _field != null;
  bool                   get isLoading    =>
      _status == SatelliteStatus.fetching   ||
      _status == SatelliteStatus.analyzing  ||
      _status == SatelliteStatus.locating;

  NdviReading? get latestNdvi =>
      _ndviReadings.isNotEmpty ? _ndviReadings.last : null;
  NdwiReading? get latestNdwi =>
      _ndwiReadings.isNotEmpty ? _ndwiReadings.last : null;

  // Load saved field + readings from SharedPreferences
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final fieldRaw = prefs.getString(_kField);
    if (fieldRaw != null) {
      _field = FieldPolygon.fromJson(
          jsonDecode(fieldRaw) as Map<String, dynamic>);
    }
    final readingsRaw = prefs.getString(_kReadings);
    if (readingsRaw != null) {
      final list = jsonDecode(readingsRaw) as List;
      _ndviReadings = list
          .map((e) => NdviReading.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    notifyListeners();
  }

  // Get GPS location and create a field polygon around it
  Future<void> createFieldFromGps({required String fieldName}) async {
    _setStatus(SatelliteStatus.locating, 'Inapata GPS...');

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setError('Huduma ya GPS imezimwa kwenye simu yako.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _setError('Ruhusa ya GPS ilikataliwa.');
          return;
        }
      }

      _setStatus(SatelliteStatus.locating, 'Inasubiri GPS...');

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      await _buildFieldFromCenter(
        fieldName: fieldName,
        center: LatLng(position.latitude, position.longitude),
      );
    } catch (e) {
      _setError('Hitilafu ya GPS: ${e.toString()}');
    }
  }

  // Create a field polygon from manually entered coordinates
  Future<void> createFieldFromCoordinates({
    required String fieldName,
    required LatLng center,
  }) async {
    await _buildFieldFromCenter(fieldName: fieldName, center: center);
  }

  // Build a roughly 1-hectare square polygon around a centre point
  Future<void> _buildFieldFromCenter({
    required String fieldName,
    required LatLng center,
  }) async {
    _setStatus(SatelliteStatus.fetching, 'Inaunda mipaka ya shamba...');

    // ~0.005 degrees ≈ 500m — a reasonable field boundary
    const offset = 0.0025;
    final lat = center.latitude;
    final lng = center.longitude;

    final coords = [
      LatLng(lat + offset, lng - offset),
      LatLng(lat + offset, lng + offset),
      LatLng(lat - offset, lng + offset),
      LatLng(lat - offset, lng - offset),
    ];

    // Register the polygon with EOSDA
    final polygonId = await _eosda.createPolygon(
      fieldName: fieldName,
      coordinates: coords,
    );

    final field = FieldPolygon(
      id: polygonId,
      name: fieldName,
      coordinates: coords,
      createdAt: DateTime.now(),
    );

    _field = field;
    await _saveField();

    // Immediately fetch NDVI data
    await fetchNdviData();
  }

  // Fetch NDVI + NDWI statistics for the saved field (both in parallel)
  Future<void> fetchNdviData() async {
    if (_field == null) return;
    _setStatus(SatelliteStatus.fetching, 'Inapakua data ya NDVI na NDWI...');

    try {
      final now = DateTime.now();
      final start = now.subtract(const Duration(days: 30));

      // Fetch NDVI and NDWI simultaneously
      final results = await Future.wait([
        _eosda.getNdviStats(polygonId: _field!.id, startDate: start, endDate: now),
        _eosda.getNdwiStats(polygonId: _field!.id, startDate: start, endDate: now),
      ]);

      _ndviReadings = results[0] as List<NdviReading>;
      _ndwiReadings = results[1] as List<NdwiReading>;

      await _saveReadings();
      _setStatus(SatelliteStatus.ready, '');
    } catch (e) {
      _setError('Hitilafu ya kupakua data: ${e.toString()}');
    }
  }

  // Run the full AI crop analysis
  Future<void> runAnalysis() async {
    if (_field == null) return;
    _setStatus(SatelliteStatus.analyzing,
        'Claude AI inachambua data ya satellite...');

    try {
      final report = await _analyzer.analyzeField(field: _field!);
      _report = report;
      _setStatus(SatelliteStatus.ready, '');
    } catch (e) {
      _setError('Hitilafu ya uchambuzi: ${e.toString()}');
    }
  }

  // Remove current field and reset
  Future<void> clearField() async {
    _field = null;
    _ndviReadings = [];
    _ndwiReadings = [];
    _report = null;
    _status = SatelliteStatus.idle;
    _error = '';
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kField);
    await prefs.remove(_kReadings);
    await prefs.remove(_kNdwiReadings);
    notifyListeners();
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  void _setStatus(SatelliteStatus s, String message) {
    _status = s;
    _statusMessage = message;
    _error = '';
    notifyListeners();
  }

  void _setError(String msg) {
    _status = SatelliteStatus.error;
    _error = msg;
    notifyListeners();
  }

  Future<void> _saveField() async {
    if (_field == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kField, jsonEncode(_field!.toJson()));
  }

  Future<void> _saveReadings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _kReadings,
        jsonEncode(_ndviReadings
            .map((r) => {
                  'dt': r.date.millisecondsSinceEpoch ~/ 1000,
                  'avg': r.average,
                  'min': r.min,
                  'max': r.max,
                  'cl': r.cloudCover,
                })
            .toList()));
  }
}

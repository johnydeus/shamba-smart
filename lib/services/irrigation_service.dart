import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'weather_service.dart';

// FAO Penman-Monteith simplified ETo — standard for Tanzania agricultural planning
class IrrigationService {
  static SupabaseClient get _db => Supabase.instance.client;

  // Crop coefficients (Kc) by growth stage — from FAO Irrigation Paper 56
  static const Map<String, Map<String, double>> _cropKc = {
    'mahindi': {'initial': 0.4, 'development': 0.8, 'mid': 1.15, 'late': 0.7},
    'nyanya': {'initial': 0.6, 'development': 0.9, 'mid': 1.15, 'late': 0.8},
    'maharagwe': {'initial': 0.4, 'development': 0.7, 'mid': 1.05, 'late': 0.9},
    'pilipili': {'initial': 0.6, 'development': 0.8, 'mid': 1.05, 'late': 0.9},
    'ndizi': {'initial': 0.5, 'development': 0.8, 'mid': 1.2, 'late': 1.1},
    'mchele': {'initial': 1.05, 'development': 1.1, 'mid': 1.2, 'late': 0.75},
    'muhogo': {'initial': 0.3, 'development': 0.6, 'mid': 0.8, 'late': 0.5},
    'alizeti': {'initial': 0.35, 'development': 0.75, 'mid': 1.15, 'late': 0.55},
    'viazi vitamu': {'initial': 0.5, 'development': 0.8, 'mid': 1.15, 'late': 0.65},
    'vitunguu': {'initial': 0.7, 'development': 0.8, 'mid': 1.05, 'late': 0.85},
    'default': {'initial': 0.5, 'development': 0.8, 'mid': 1.0, 'late': 0.8},
  };

  // Soil water-holding capacity (mm per 30cm depth)
  static const Map<String, double> _soilWhc = {
    'mchanga': 40.0,
    'sandy loam': 65.0,
    'tifutifu': 90.0,
    'loam': 90.0,
    'udongo mwekundu': 110.0,
    'clay loam': 110.0,
    'udongo mzito': 140.0,
    'clay': 140.0,
    'mfinyanzi': 140.0,
    'default': 80.0,
  };

  // Calculate daily water requirement in litres
  static Future<double> calculateDailyWater({
    required String cropName,
    required String growthStage,
    required String soilType,
    required double farmAcres,
    required double lat,
    required double lng,
  }) async {
    // 1. Get current weather for ETo calculation
    final weather = await WeatherService.getWeatherData(lat: lat, lng: lng);

    // 2. Calculate reference evapotranspiration (ETo) — simplified Penman-Monteith
    final eto = _calculateETo(
      temperature: weather.temperature,
      humidity: weather.humidity,
      windSpeed: weather.windSpeed,
      lat: lat,
    );

    // 3. Get crop coefficient for growth stage
    final cropKey = cropName.toLowerCase();
    final stageKey = growthStage.toLowerCase();
    final kcMap = _cropKc[cropKey] ?? _cropKc['default']!;
    final kc = kcMap[stageKey] ?? kcMap['mid']!;

    // 4. Calculate crop evapotranspiration (ETc = Kc × ETo)
    final etcMmPerDay = kc * eto;

    // 5. Convert to litres: 1mm × area_m2 = 1 litre
    final areaM2 = farmAcres * 4046.86; // 1 acre = 4046.86 m²
    final dailyLitres = etcMmPerDay * areaM2;

    debugPrint('Irrigation: ETo=${eto.toStringAsFixed(2)}mm, Kc=$kc, ETc=${etcMmPerDay.toStringAsFixed(2)}mm, ${dailyLitres.toStringAsFixed(0)}L/day');
    return dailyLitres;
  }

  // FAO Penman-Monteith simplified (Hargreaves variant when solar data unavailable)
  static double _calculateETo({
    required double temperature,
    required double humidity,
    required double windSpeed,
    required double lat,
  }) {
    // Estimate net radiation from latitude + season (MJ/m²/day)
    final doy = DateTime.now().difference(DateTime(DateTime.now().year)).inDays + 1;
    final rn = _estimateNetRadiation(lat, doy);

    // Saturation vapour pressure
    final es = 0.6108 * exp(17.27 * temperature / (temperature + 237.3));
    final ea = es * (humidity / 100.0);

    // Slope of vapour pressure curve
    final delta = 4098 * es / pow(temperature + 237.3, 2);

    // Psychrometric constant (kPa/°C) at ~900m altitude (Tanzania average)
    const gamma = 0.067;

    // Wind speed at 2m (approximate from 10m: u2 ≈ u10 × 0.748)
    final u2 = windSpeed * 0.748;

    // Penman-Monteith ETo (mm/day)
    final numerator = 0.408 * delta * rn + gamma * (900.0 / (temperature + 273.0)) * u2 * (es - ea);
    final denominator = delta + gamma * (1.0 + 0.34 * u2);
    final eto = (numerator / denominator).clamp(2.0, 12.0);

    return eto;
  }

  static double _estimateNetRadiation(double lat, int doy) {
    // Simplified net radiation estimate for Tanzania (MJ/m²/day)
    // Based on clear-sky radiation adjusted for latitude and season
    final latRad = lat.abs() * pi / 180;
    final dr = 1 + 0.033 * cos(2 * pi * doy / 365);
    final sd = 0.409 * sin(2 * pi * doy / 365 - 1.39);
    final ws = acos(-tan(latRad) * tan(sd));
    final ra = (24.0 * 60.0 / pi) * 0.0820 * dr *
        (ws * sin(latRad) * sin(sd) + cos(latRad) * cos(sd) * sin(ws));
    return ra * 0.5; // Approximate Rn as 50% of Ra (typical cloud factor)
  }

  // Generate a 7-day irrigation schedule
  static Future<Map<String, dynamic>> generateWeeklySchedule({
    required double dailyLitres,
    required String soilType,
    required double lat,
    required double lng,
  }) async {
    final forecast = await WeatherService.getWeeklyForecast(lat: lat, lng: lng);
    final whc = _soilWhc[soilType.toLowerCase()] ?? _soilWhc['default']!;

    final schedule = <Map<String, dynamic>>[];
    double soilMoisture = whc * 0.6; // Start at 60% field capacity

    for (int i = 0; i < 7; i++) {
      final day = i < forecast.length ? forecast[i] : _defaultDay(i);
      final rainLitres = (day['rain_mm'] as double) * 1000; // mm to L/m² × area
      final safeToSpray = day['safe_to_spray'] as bool;

      soilMoisture += rainLitres / 10; // simplified soil balance
      soilMoisture = soilMoisture.clamp(0, whc);

      final needsWater = soilMoisture < whc * 0.4;
      final irrigateToday = needsWater && safeToSpray;
      final litres = irrigateToday ? dailyLitres : 0.0;

      if (irrigateToday) soilMoisture += litres / 100;

      schedule.add({
        'day': i + 1,
        'date': day['date'],
        'irrigate': irrigateToday,
        'litres': litres.round(),
        'rain_expected_mm': day['rain_mm'],
        'safe_to_spray': safeToSpray,
        'reason': _scheduleReason(irrigateToday, safeToSpray, needsWater, day),
      });
    }

    final totalLitres = schedule.fold<int>(0, (sum, d) => sum + (d['litres'] as int));
    final irrigationDays = schedule.where((d) => d['irrigate'] as bool).length;

    return {
      'schedule': schedule,
      'total_litres_week': totalLitres,
      'irrigation_days': irrigationDays,
      'soil_type': soilType,
      'generated_at': DateTime.now().toIso8601String(),
    };
  }

  static String _scheduleReason(bool irrigate, bool safe, bool needs, Map day) {
    if (!needs) return '✅ Udongo una maji ya kutosha';
    if (!safe) return '💨 Upepo mkali au mvua — subiri';
    if ((day['rain_mm'] as double) > 5) return '🌧️ Mvua ya kutosha leo — usimwagilie';
    if (irrigate) return '💧 Mwagilia asubuhi (6am–8am)';
    return '⏳ Angalia hali ya hewa kesho';
  }

  static Map<String, dynamic> _defaultDay(int offset) {
    final date = DateTime.now().add(Duration(days: offset));
    return {
      'date': date.toIso8601String().substring(0, 10),
      'rain_mm': 0.0,
      'wind_speed': 8.0,
      'safe_to_spray': true,
    };
  }

  static Future<void> savePlanToSupabase({
    required String? farmerId,
    required String cropName,
    required String growthStage,
    required String soilType,
    required double farmAcres,
    required double dailyLitres,
    required Map<String, dynamic> scheduleJson,
  }) async {
    try {
      await _db.from('irrigation_plans').insert({
        'farmer_id': farmerId,
        'crop_name': cropName,
        'growth_stage': growthStage,
        'soil_type': soilType,
        'farm_acres': farmAcres,
        'method': 'sprinkler',
        'daily_litres': dailyLitres,
        'schedule_json': scheduleJson,
      });
    } catch (e) {
      debugPrint('IrrigationService save error: $e');
    }
  }

  // Human-readable irrigation tip
  static String irrigationTip(String cropName, String soilType) {
    final soil = soilType.toLowerCase();
    final isSandy = soil.contains('mchanga') || soil.contains('sandy');
    final isClay = soil.contains('mzito') || soil.contains('clay') || soil.contains('mfinyanzi');

    if (isSandy) {
      return 'Udongo wa mchanga haushiki maji — mwagilia mara nyingi (kila siku) kidogo kidogo.';
    } else if (isClay) {
      return 'Udongo mzito unashika maji vizuri — mwagilia kila siku 2-3 kwa wingi.';
    }
    return 'Mwagilia asubuhi mapema (6am-8am) ili kupunguza uvukizi.';
  }
}

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/weather_data.dart';

class WeatherService {
  static const String _baseUrl = 'https://api.open-meteo.com/v1/forecast';
  static SupabaseClient get _db => Supabase.instance.client;

  // Fetch current weather for GPS coordinates — free, no API key needed
  static Future<WeatherData> getWeatherData({
    required double lat,
    required double lng,
  }) async {
    try {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'latitude': lat.toStringAsFixed(4),
        'longitude': lng.toStringAsFixed(4),
        'current': [
          'temperature_2m',
          'apparent_temperature',
          'relative_humidity_2m',
          'wind_speed_10m',
          'precipitation_probability',
          'uv_index',
          'weather_code',
        ].join(','),
        'daily': 'precipitation_sum,wind_speed_10m_max',
        'timezone': 'Africa/Nairobi',
        'forecast_days': '3',
      });

      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final weather = WeatherData.fromJson(data);
        await _cacheToSupabase(weather, lat, lng);
        return weather;
      }
    } catch (e) {
      debugPrint('WeatherService error: $e');
    }

    return await _loadFromCache(lat, lng) ?? _demoWeather();
  }

  // Fetch 7-day forecast for irrigation scheduling
  static Future<List<Map<String, dynamic>>> getWeeklyForecast({
    required double lat,
    required double lng,
  }) async {
    try {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'latitude': lat.toStringAsFixed(4),
        'longitude': lng.toStringAsFixed(4),
        'daily': [
          'temperature_2m_max',
          'temperature_2m_min',
          'precipitation_sum',
          'wind_speed_10m_max',
          'precipitation_probability_max',
          'uv_index_max',
        ].join(','),
        'timezone': 'Africa/Nairobi',
        'forecast_days': '7',
      });

      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final daily = data['daily'] as Map<String, dynamic>;
        final dates = (daily['time'] as List).cast<String>();
        final maxTemps = (daily['temperature_2m_max'] as List).cast<num>();
        final minTemps = (daily['temperature_2m_min'] as List).cast<num>();
        final rain = (daily['precipitation_sum'] as List).cast<num?>();
        final wind = (daily['wind_speed_10m_max'] as List).cast<num>();
        final rainProb =
            (daily['precipitation_probability_max'] as List).cast<num>();
        final uv = (daily['uv_index_max'] as List).cast<num?>();

        return List.generate(dates.length, (i) => {
              'date': dates[i],
              'temp_max': maxTemps[i].toDouble(),
              'temp_min': minTemps[i].toDouble(),
              'rain_mm': (rain[i] ?? 0).toDouble(),
              'wind_speed': wind[i].toDouble(),
              'rain_probability': rainProb[i].toDouble(),
              'uv_index': (uv[i] ?? 5).toDouble(),
              'safe_to_spray':
                  wind[i] < 15 && rainProb[i] < 40 && maxTemps[i] < 35,
            });
      }
    } catch (e) {
      debugPrint('WeatherService weekly error: $e');
    }

    return _demoWeeklyForecast();
  }

  static Future<void> _cacheToSupabase(
      WeatherData w, double lat, double lng) async {
    try {
      await _db.from('weather_cache').insert(w.toSupabaseJson(lat, lng));
    } catch (_) {}
  }

  static Future<WeatherData?> _loadFromCache(double lat, double lng) async {
    try {
      final cutoff = DateTime.now().subtract(const Duration(hours: 3));
      final rows = await _db
          .from('weather_cache')
          .select()
          .gte('fetched_at', cutoff.toIso8601String())
          .order('fetched_at', ascending: false)
          .limit(1);

      if (rows.isNotEmpty) {
        return WeatherData.fromSupabase(
            Map<String, dynamic>.from(rows.first));
      }
    } catch (_) {}
    return null;
  }

  static WeatherData _demoWeather() => WeatherData(
        temperature: 27.4,
        apparentTemperature: 30.1,
        humidity: 68,
        windSpeed: 8.5,
        rainProbability: 20,
        uvIndex: 7.2,
        weatherCode: 2,
        fetchedAt: DateTime.now(),
      );

  static List<Map<String, dynamic>> _demoWeeklyForecast() {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final date = now.add(Duration(days: i));
      final rain = i == 2 || i == 5 ? 12.0 : 0.0;
      return {
        'date': date.toIso8601String().substring(0, 10),
        'temp_max': 28.0 + i * 0.3,
        'temp_min': 18.0 + i * 0.2,
        'rain_mm': rain,
        'wind_speed': 7.0 + i * 0.5,
        'rain_probability': rain > 0 ? 65.0 : 15.0,
        'uv_index': 7.0,
        'safe_to_spray': rain == 0,
      };
    });
  }
}

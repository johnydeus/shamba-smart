class WeatherData {
  final double temperature;
  final double apparentTemperature;
  final double humidity;
  final double windSpeed;
  final double rainProbability;
  final double uvIndex;
  final int weatherCode;
  final DateTime fetchedAt;

  const WeatherData({
    required this.temperature,
    required this.apparentTemperature,
    required this.humidity,
    required this.windSpeed,
    required this.rainProbability,
    required this.uvIndex,
    required this.weatherCode,
    required this.fetchedAt,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final current = json['current'] as Map<String, dynamic>? ?? json;
    return WeatherData(
      temperature: (current['temperature_2m'] as num?)?.toDouble() ?? 27.0,
      apparentTemperature:
          (current['apparent_temperature'] as num?)?.toDouble() ?? 27.0,
      humidity:
          (current['relative_humidity_2m'] as num?)?.toDouble() ?? 65.0,
      windSpeed: (current['wind_speed_10m'] as num?)?.toDouble() ?? 3.0,
      rainProbability:
          (current['precipitation_probability'] as num?)?.toDouble() ?? 20.0,
      uvIndex: (current['uv_index'] as num?)?.toDouble() ?? 5.0,
      weatherCode: (current['weather_code'] as num?)?.toInt() ?? 0,
      fetchedAt: DateTime.now(),
    );
  }

  factory WeatherData.fromSupabase(Map<String, dynamic> json) => WeatherData(
        temperature: (json['temperature'] as num?)?.toDouble() ?? 27.0,
        apparentTemperature:
            (json['temperature'] as num?)?.toDouble() ?? 27.0,
        humidity: (json['humidity'] as num?)?.toDouble() ?? 65.0,
        windSpeed: (json['wind_speed'] as num?)?.toDouble() ?? 3.0,
        rainProbability:
            (json['rain_probability'] as num?)?.toDouble() ?? 20.0,
        uvIndex: 6.0,
        weatherCode: 0,
        fetchedAt: DateTime.parse(
            json['fetched_at'] as String? ?? DateTime.now().toIso8601String()),
      );

  Map<String, dynamic> toSupabaseJson(double lat, double lng) => {
        'gps_lat': lat,
        'gps_lng': lng,
        'temperature': temperature,
        'humidity': humidity,
        'wind_speed': windSpeed,
        'rain_probability': rainProbability,
        'safe_to_spray': safeToSpray,
        'fetched_at': fetchedAt.toIso8601String(),
      };

  bool get safeToSpray =>
      windSpeed < 15.0 && rainProbability < 40.0 && temperature < 35.0;

  String get safeToSprayMessage {
    if (safeToSpray) return '✅ Salama kupulizia dawa leo';
    if (windSpeed >= 15.0) return '💨 Upepo mkali — usipulizie dawa (mwendo ${windSpeed.toStringAsFixed(0)} km/h)';
    if (rainProbability >= 40.0) {
      return '🌧️ Mvua inawezekana — subiri hali ya hewa iwe nzuri';
    }
    return '🌡️ Joto kali sana — pulizia asubuhi mapema (6am–9am)';
  }

  String get weatherDescription {
    if (weatherCode == 0) return 'Anga Safi';
    if (weatherCode <= 3) return 'Mawingu Kidogo';
    if (weatherCode <= 48) return 'Ukungu';
    if (weatherCode <= 67) return 'Mvua';
    if (weatherCode <= 77) return 'Theluji';
    if (weatherCode <= 82) return 'Mvua ya Muda';
    return 'Dhoruba';
  }

  String get temperatureCategory {
    if (temperature < 15) return 'Baridi';
    if (temperature < 25) return 'Wastani';
    if (temperature < 32) return 'Joto';
    return 'Joto Kali';
  }
}

class SoilDataModel {
  final double? ph;
  final double? clay;
  final double? sand;
  final double? silt;
  final double? nitrogen;
  final double? organicCarbon;
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  const SoilDataModel({
    this.ph,
    this.clay,
    this.sand,
    this.silt,
    this.nitrogen,
    this.organicCarbon,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  // Parse SoilGrids v2.0 API response
  // Each layer has a 'name' and 'depths' list; values are scaled integers
  factory SoilDataModel.fromSoilGridsJson(
      Map<String, dynamic> json, double lat, double lon) {
    final layers =
        (json['properties']?['layers'] as List?) ?? [];

    double? ph, clay, sand, silt, nitrogen, organicCarbon;

    for (final layer in layers) {
      final name = layer['name'] as String? ?? '';
      final depths = (layer['depths'] as List?) ?? [];
      if (depths.isEmpty) continue;

      final meanRaw = depths[0]['values']?['mean'];
      if (meanRaw == null) continue;
      final mean = (meanRaw as num).toDouble();

      switch (name) {
        case 'phh2o':
          ph = mean / 10; // 65 → 6.5 pH
          break;
        case 'clay':
          clay = mean / 10; // 250 → 25.0 %
          break;
        case 'sand':
          sand = mean / 10;
          break;
        case 'silt':
          silt = mean / 10;
          break;
        case 'nitrogen':
          nitrogen = mean / 100; // g/kg
          break;
        case 'soc':
          organicCarbon = mean / 10; // g/kg
          break;
      }
    }

    return SoilDataModel(
      ph: ph,
      clay: clay,
      sand: sand,
      silt: silt,
      nitrogen: nitrogen,
      organicCarbon: organicCarbon,
      latitude: lat,
      longitude: lon,
      timestamp: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'ph': ph,
        'clay': clay,
        'sand': sand,
        'silt': silt,
        'nitrogen': nitrogen,
        'organicCarbon': organicCarbon,
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': timestamp.toIso8601String(),
      };

  factory SoilDataModel.fromCacheJson(Map<String, dynamic> json) =>
      SoilDataModel(
        ph: (json['ph'] as num?)?.toDouble(),
        clay: (json['clay'] as num?)?.toDouble(),
        sand: (json['sand'] as num?)?.toDouble(),
        silt: (json['silt'] as num?)?.toDouble(),
        nitrogen: (json['nitrogen'] as num?)?.toDouble(),
        organicCarbon: (json['organicCarbon'] as num?)?.toDouble(),
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        timestamp: DateTime.parse(json['timestamp'] as String),
      );

  String get phCategory {
    if (ph == null) return 'Haijulikani';
    if (ph! < 5.5) return 'Tindikali Sana';
    if (ph! < 6.5) return 'Tindikali Kidogo';
    if (ph! <= 7.0) return 'Wastani Mzuri';
    if (ph! <= 7.5) return 'Alkali Kidogo';
    return 'Alkali Sana';
  }

  String get textureClass {
    final s = sand ?? 0;
    final c = clay ?? 0;
    if (s > 70) return 'Mchanga (Sandy)';
    if (c > 40) return 'Udongo Mzito (Clay)';
    if (s > 50 && c < 20) return 'Mchanga-Tifutifu (Sandy Loam)';
    if (c > 25 && c <= 40) return 'Udongo wa Kati (Clay Loam)';
    return 'Tifutifu (Loam)';
  }
}

class SoilData {
  final int? id;
  final double gpsLat;
  final double gpsLng;
  final double? ph;
  final double? nitrogen;
  final double? phosphorus;
  final double? potassium;
  final String? texture;
  final String source;
  final DateTime fetchedAt;

  const SoilData({
    this.id,
    required this.gpsLat,
    required this.gpsLng,
    this.ph,
    this.nitrogen,
    this.phosphorus,
    this.potassium,
    this.texture,
    this.source = 'iSDAsoil',
    required this.fetchedAt,
  });

  factory SoilData.fromJson(Map<String, dynamic> json) => SoilData(
        id: json['id'] as int?,
        gpsLat: (json['gps_lat'] as num).toDouble(),
        gpsLng: (json['gps_lng'] as num).toDouble(),
        ph: (json['ph'] as num?)?.toDouble(),
        nitrogen: (json['nitrogen'] as num?)?.toDouble(),
        phosphorus: (json['phosphorus'] as num?)?.toDouble(),
        potassium: (json['potassium'] as num?)?.toDouble(),
        texture: json['texture'] as String?,
        source: json['source'] as String? ?? 'iSDAsoil',
        fetchedAt: DateTime.parse(
            json['fetched_at'] as String? ?? DateTime.now().toIso8601String()),
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'gps_lat': gpsLat,
        'gps_lng': gpsLng,
        'ph': ph,
        'nitrogen': nitrogen,
        'phosphorus': phosphorus,
        'potassium': potassium,
        'texture': texture,
        'source': source,
        'fetched_at': fetchedAt.toIso8601String(),
      };

  String get phCategory {
    if (ph == null) return 'Haijulikani';
    if (ph! < 5.5) return 'Tindikali Sana';
    if (ph! < 6.0) return 'Tindikali Kidogo';
    if (ph! <= 7.0) return 'Nzuri (Neutral)';
    if (ph! <= 7.5) return 'Alkali Kidogo';
    return 'Alkali Sana';
  }

  String get fertiliserAdvice {
    if (ph == null) return '';
    if (ph! < 5.5) return 'Weka chokaa (lime) kg 200-500 kwa ekari moja kupandisha pH.';
    if (ph! > 7.5) return 'Ongeza sulfuri au mbolea ya ammonium kupungusha pH.';
    return 'pH yako ni nzuri kwa mazao mengi ya Tanzania.';
  }
}

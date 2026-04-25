class Farmer {
  final String id;
  final String phone;
  final String name;
  final String region;
  final String? district;
  final double? gpsLat;
  final double? gpsLng;
  final double farmAcres;
  final String? soilType;
  final String subscription;
  final String language;
  final DateTime createdAt;

  const Farmer({
    required this.id,
    required this.phone,
    required this.name,
    this.region = 'Morogoro',
    this.district,
    this.gpsLat,
    this.gpsLng,
    this.farmAcres = 1.0,
    this.soilType,
    this.subscription = 'free',
    this.language = 'sw',
    required this.createdAt,
  });

  factory Farmer.fromJson(Map<String, dynamic> json) => Farmer(
        id: json['id'] as String,
        phone: json['phone'] as String,
        name: json['name'] as String,
        region: json['region'] as String? ?? 'Morogoro',
        district: json['district'] as String?,
        gpsLat: (json['gps_lat'] as num?)?.toDouble(),
        gpsLng: (json['gps_lng'] as num?)?.toDouble(),
        farmAcres: (json['farm_acres'] as num?)?.toDouble() ?? 1.0,
        soilType: json['soil_type'] as String?,
        subscription: json['subscription'] as String? ?? 'free',
        language: json['language'] as String? ?? 'sw',
        createdAt: DateTime.parse(
            json['created_at'] as String? ?? DateTime.now().toIso8601String()),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'phone': phone,
        'name': name,
        'region': region,
        'district': district,
        'gps_lat': gpsLat,
        'gps_lng': gpsLng,
        'farm_acres': farmAcres,
        'soil_type': soilType,
        'subscription': subscription,
        'language': language,
        'created_at': createdAt.toIso8601String(),
      };

  Farmer copyWith({
    String? district,
    double? gpsLat,
    double? gpsLng,
    double? farmAcres,
    String? soilType,
    String? subscription,
  }) =>
      Farmer(
        id: id,
        phone: phone,
        name: name,
        region: region,
        district: district ?? this.district,
        gpsLat: gpsLat ?? this.gpsLat,
        gpsLng: gpsLng ?? this.gpsLng,
        farmAcres: farmAcres ?? this.farmAcres,
        soilType: soilType ?? this.soilType,
        subscription: subscription ?? this.subscription,
        language: language,
        createdAt: createdAt,
      );
}

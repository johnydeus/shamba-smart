class FarmModel {
  final String id;
  final String farmerId;
  final String name;
  final double? gpsLat;
  final double? gpsLng;
  final double acres;
  final List<String> crops;
  final String? soilType;
  final String region;
  final String? notes;
  final DateTime createdAt;

  const FarmModel({
    required this.id,
    required this.farmerId,
    required this.name,
    this.gpsLat,
    this.gpsLng,
    this.acres = 1.0,
    this.crops = const [],
    this.soilType,
    this.region = 'Morogoro',
    this.notes,
    required this.createdAt,
  });

  factory FarmModel.create({
    required String farmerId,
    required String name,
    double? gpsLat,
    double? gpsLng,
    double acres = 1.0,
    List<String> crops = const [],
    String region = 'Morogoro',
    String? notes,
  }) =>
      FarmModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        farmerId: farmerId,
        name: name,
        gpsLat: gpsLat,
        gpsLng: gpsLng,
        acres: acres,
        crops: crops,
        region: region,
        notes: notes,
        createdAt: DateTime.now(),
      );

  factory FarmModel.fromJson(Map<String, dynamic> j) => FarmModel(
        id: j['id'] as String,
        farmerId: j['farmerId'] as String,
        name: j['name'] as String,
        gpsLat: (j['gpsLat'] as num?)?.toDouble(),
        gpsLng: (j['gpsLng'] as num?)?.toDouble(),
        acres: (j['acres'] as num?)?.toDouble() ?? 1.0,
        crops: (j['crops'] as List?)?.cast<String>() ?? [],
        soilType: j['soilType'] as String?,
        region: j['region'] as String? ?? 'Morogoro',
        notes: j['notes'] as String?,
        createdAt: DateTime.parse(j['createdAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'farmerId': farmerId,
        'name': name,
        'gpsLat': gpsLat,
        'gpsLng': gpsLng,
        'acres': acres,
        'crops': crops,
        if (soilType != null) 'soilType': soilType,
        'region': region,
        if (notes != null) 'notes': notes,
        'createdAt': createdAt.toIso8601String(),
      };

  FarmModel copyWith({
    String? name,
    double? gpsLat,
    double? gpsLng,
    double? acres,
    List<String>? crops,
    String? soilType,
    String? region,
    String? notes,
  }) =>
      FarmModel(
        id: id,
        farmerId: farmerId,
        name: name ?? this.name,
        gpsLat: gpsLat ?? this.gpsLat,
        gpsLng: gpsLng ?? this.gpsLng,
        acres: acres ?? this.acres,
        crops: crops ?? this.crops,
        soilType: soilType ?? this.soilType,
        region: region ?? this.region,
        notes: notes ?? this.notes,
        createdAt: createdAt,
      );

  bool get hasLocation => gpsLat != null && gpsLng != null;
  String get cropsDisplay =>
      crops.isEmpty ? 'Hakuna mazao bado' : crops.join(', ');
  String get acresDisplay =>
      acres == 1.0 ? '1 ekari' : '${acres.toStringAsFixed(1)} ekari';
}

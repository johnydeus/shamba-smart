// Agrovet / agricultural institution in the directory.

/// Categories an agrovet can offer. `key` matches the DB `categories[]` values.
enum AgrovetCategory { fertilizer, seeds, pesticides, cropBuying, equipment, veterinary, advisory }

extension AgrovetCategoryX on AgrovetCategory {
  String get key => switch (this) {
        AgrovetCategory.fertilizer => 'fertilizer',
        AgrovetCategory.seeds      => 'seeds',
        AgrovetCategory.pesticides => 'pesticides',
        AgrovetCategory.cropBuying => 'crop_buying',
        AgrovetCategory.equipment  => 'equipment',
        AgrovetCategory.veterinary => 'veterinary',
        AgrovetCategory.advisory   => 'advisory',
      };

  String get labelSw => switch (this) {
        AgrovetCategory.fertilizer => 'Mbolea',
        AgrovetCategory.seeds      => 'Mbegu',
        AgrovetCategory.pesticides => 'Viuatilifu',
        AgrovetCategory.cropBuying => 'Kununua Mazao',
        AgrovetCategory.equipment  => 'Vifaa',
        AgrovetCategory.veterinary => 'Mifugo',
        AgrovetCategory.advisory   => 'Ushauri',
      };

  String get emoji => switch (this) {
        AgrovetCategory.fertilizer => '🧪',
        AgrovetCategory.seeds      => '🌱',
        AgrovetCategory.pesticides => '🐛',
        AgrovetCategory.cropBuying => '💰',
        AgrovetCategory.equipment  => '🚜',
        AgrovetCategory.veterinary => '🐄',
        AgrovetCategory.advisory   => '📋',
      };

  static AgrovetCategory? fromKey(String key) {
    for (final c in AgrovetCategory.values) {
      if (c.key == key) return c;
    }
    return null;
  }
}

class AgrovetModel {
  final String id;
  final String name;
  final String type; // government | private | cooperative
  final List<String> categories; // raw category keys
  final String region;
  final String? district;
  final String? ward;
  final String? physicalAddress;
  final String? description;
  final double? latitude;
  final double? longitude;
  final String? phone;
  final String? whatsapp;
  final String? email;
  final bool isVerified;
  final bool isSelfRegistered;
  final String source;

  const AgrovetModel({
    required this.id,
    required this.name,
    required this.type,
    required this.categories,
    required this.region,
    this.district,
    this.ward,
    this.physicalAddress,
    this.description,
    this.latitude,
    this.longitude,
    this.phone,
    this.whatsapp,
    this.email,
    this.isVerified = false,
    this.isSelfRegistered = false,
    this.source = 'self-registered',
  });

  bool get isGovernment => type == 'government';

  String get typeLabelSw => switch (type) {
        'government'  => 'Serikali',
        'cooperative' => 'Ushirika',
        _             => 'Binafsi',
      };

  List<AgrovetCategory> get categoryEnums =>
      categories.map(AgrovetCategoryX.fromKey).whereType<AgrovetCategory>().toList();

  factory AgrovetModel.fromJson(Map<String, dynamic> j) => AgrovetModel(
        id: j['id'].toString(),
        name: j['name'] as String? ?? 'Duka',
        type: j['type'] as String? ?? 'private',
        categories: (j['categories'] as List?)?.cast<String>() ?? const [],
        region: j['region'] as String? ?? '',
        district: j['district'] as String?,
        ward: j['ward'] as String?,
        physicalAddress: j['physical_address'] as String?,
        description: j['description'] as String?,
        latitude: (j['latitude'] as num?)?.toDouble(),
        longitude: (j['longitude'] as num?)?.toDouble(),
        phone: j['phone'] as String?,
        whatsapp: j['whatsapp'] as String?,
        email: j['email'] as String?,
        isVerified: j['is_verified'] as bool? ?? false,
        isSelfRegistered: j['is_self_registered'] as bool? ?? false,
        source: j['source'] as String? ?? 'self-registered',
      );

  Map<String, dynamic> toInsert({required String ownerId}) => {
        'name': name,
        'type': type,
        'categories': categories,
        'region': region,
        if (district != null) 'district': district,
        if (ward != null) 'ward': ward,
        if (physicalAddress != null) 'physical_address': physicalAddress,
        if (description != null) 'description': description,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (phone != null) 'phone': phone,
        if (whatsapp != null) 'whatsapp': whatsapp,
        if (email != null) 'email': email,
        'is_verified': false,
        'is_self_registered': true,
        'owner_id': ownerId,
        'source': 'self-registered',
      };
}

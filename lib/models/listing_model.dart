import '../models/user_model.dart';

// Category types for a listing
enum ListingType { mazao, dawa, mbegu, shamba, zana, usafiri }

extension ListingTypeX on ListingType {
  String get label => switch (this) {
        ListingType.mazao   => 'Mazao',
        ListingType.dawa    => 'Dawa',
        ListingType.mbegu   => 'Mbegu',
        ListingType.shamba  => 'Shamba',
        ListingType.zana    => 'Zana',
        ListingType.usafiri => 'Usafiri',
      };

  String get emoji => switch (this) {
        ListingType.mazao   => '🌽',
        ListingType.dawa    => '💊',
        ListingType.mbegu   => '🌱',
        ListingType.shamba  => '🏡',
        ListingType.zana    => '⚙️',
        ListingType.usafiri => '🚛',
      };

  static ListingType fromKey(String key) =>
      ListingType.values.firstWhere((t) => t.name == key,
          orElse: () => ListingType.mazao);
}

// Seller embedded in a listing
class SellerInfo {
  final String id;
  final String name;
  final UserRole role;
  final String colorHex;

  const SellerInfo({
    required this.id,
    required this.name,
    required this.role,
    required this.colorHex,
  });

  factory SellerInfo.fromJson(Map<String, dynamic> j) => SellerInfo(
        id: j['id'] as String,
        name: j['name'] as String,
        role: UserRoleX.fromKey(j['role'] as String),
        colorHex: j['colorHex'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'role': role.key,
        'colorHex': colorHex,
      };
}

// A single marketplace listing
class ListingModel {
  final String id;
  final ListingType type;
  final String title;
  final String description;
  final int price;          // TZS
  final String unit;        // kg, lita, pakiti, etc.
  final int quantityAvailable;
  final String location;
  final DateTime createdAt;
  final SellerInfo seller;
  final String badgeText;
  final String badgeColorHex;
  final String emoji;

  const ListingModel({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.price,
    required this.unit,
    required this.quantityAvailable,
    required this.location,
    required this.createdAt,
    required this.seller,
    required this.badgeText,
    required this.badgeColorHex,
    required this.emoji,
  });

  factory ListingModel.fromJson(Map<String, dynamic> j) => ListingModel(
        id: j['id'] as String,
        type: ListingTypeX.fromKey(j['type'] as String),
        title: j['title'] as String,
        description: j['description'] as String,
        price: (j['price'] as int),
        unit: j['unit'] as String,
        quantityAvailable: (j['quantityAvailable'] as int),
        location: j['location'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
        seller: SellerInfo.fromJson(
            j['seller'] as Map<String, dynamic>),
        badgeText: j['badgeText'] as String? ?? '',
        badgeColorHex: j['badgeColorHex'] as String? ?? '#43A047',
        emoji: j['emoji'] as String? ?? '📦',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'description': description,
        'price': price,
        'unit': unit,
        'quantityAvailable': quantityAvailable,
        'location': location,
        'createdAt': createdAt.toIso8601String(),
        'seller': seller.toJson(),
        'badgeText': badgeText,
        'badgeColorHex': badgeColorHex,
        'emoji': emoji,
      };

  factory ListingModel.fromSupabaseJson(Map<String, dynamic> j) =>
      ListingModel(
        id: j['id'] as String,
        type: ListingTypeX.fromKey(j['type'] as String),
        title: j['title'] as String,
        description: j['description'] as String? ?? '',
        price: (j['price'] as num).toInt(),
        unit: j['unit'] as String? ?? 'kg',
        quantityAvailable: j['quantity_available'] as int? ?? 1,
        location: j['location'] as String? ?? '',
        createdAt: DateTime.parse(j['created_at'] as String),
        seller: SellerInfo(
          id: j['seller_id'] as String,
          name: j['seller_name'] as String,
          role: UserRoleX.fromKey(j['seller_role'] as String? ?? 'mkulima'),
          colorHex: j['seller_color_hex'] as String? ?? '#2E7D32',
        ),
        badgeText: j['badge_text'] as String? ?? '',
        badgeColorHex: j['badge_color_hex'] as String? ?? '#43A047',
        emoji: j['emoji'] as String? ?? '📦',
      );

  Map<String, dynamic> toSupabaseJson() => {
        'id': id,
        'seller_id': seller.id,
        'seller_name': seller.name,
        'seller_role': seller.role.key,
        'seller_color_hex': seller.colorHex,
        'type': type.name,
        'title': title,
        'description': description,
        'price': price,
        'unit': unit,
        'quantity_available': quantityAvailable,
        'location': location,
        'emoji': emoji,
        'badge_text': badgeText,
        'badge_color_hex': badgeColorHex,
        'status': 'active',
        'created_at': createdAt.toIso8601String(),
      };
}

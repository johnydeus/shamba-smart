// A field officer (Afisa Kilimo) in the directory, backed by Supabase
// table `field_officers`.

class FieldOfficer {
  final String id;
  final String userId;
  final String fullName;
  final String title;
  final String region;
  final String wasifu;
  final List<String> crops;
  final int? visitFeeTzs;
  final String? phone;
  final String? whatsapp;
  final String? email;
  final double rating;
  final int ratingCount;
  final int farmersServed;
  final double? avgResponseHours;
  final bool verified;
  final String status; // pending | approved | (rejected)
  final DateTime? createdAt;

  const FieldOfficer({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.title,
    required this.region,
    required this.wasifu,
    this.crops = const [],
    this.visitFeeTzs,
    this.phone,
    this.whatsapp,
    this.email,
    this.rating = 0,
    this.ratingCount = 0,
    this.farmersServed = 0,
    this.avgResponseHours,
    this.verified = false,
    this.status = 'pending',
    this.createdAt,
  });

  bool get isNew => ratingCount == 0 && farmersServed == 0;

  factory FieldOfficer.fromJson(Map<String, dynamic> j) => FieldOfficer(
        id: j['id'].toString(),
        userId: (j['user_id'] ?? '').toString(),
        fullName: j['full_name'] as String? ?? 'Mtaalamu',
        title: j['title'] as String? ?? 'Afisa Kilimo',
        region: j['region'] as String? ?? '',
        wasifu: j['wasifu'] as String? ?? '',
        crops: (j['crops'] as List?)?.cast<String>() ?? const [],
        visitFeeTzs: (j['visit_fee_tzs'] as num?)?.toInt(),
        phone: j['phone'] as String?,
        whatsapp: j['whatsapp'] as String?,
        email: j['email'] as String?,
        rating: (j['rating'] as num?)?.toDouble() ?? 0,
        ratingCount: (j['rating_count'] as num?)?.toInt() ?? 0,
        farmersServed: (j['farmers_served'] as num?)?.toInt() ?? 0,
        avgResponseHours: (j['avg_response_hours'] as num?)?.toDouble(),
        verified: j['verified'] as bool? ?? false,
        status: j['status'] as String? ?? 'pending',
        createdAt: j['created_at'] != null
            ? DateTime.tryParse(j['created_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'full_name': fullName,
        'title': title,
        'region': region,
        'wasifu': wasifu,
        'crops': crops,
        'visit_fee_tzs': visitFeeTzs,
        'phone': phone,
        'whatsapp': whatsapp,
        'email': email,
        'rating': rating,
        'rating_count': ratingCount,
        'farmers_served': farmersServed,
        'avg_response_hours': avgResponseHours,
        'verified': verified,
        'status': status,
        'created_at': createdAt?.toIso8601String(),
      };

  /// Only the fields an officer may set on insert/update. We deliberately omit
  /// verified / status / rating / rating_count / farmers_served — the DB trigger
  /// ignores those, so we never send them.
  Map<String, dynamic> toOwnerWrite({required String userId}) => {
        'user_id': userId,
        'full_name': fullName,
        'title': title,
        'region': region,
        'wasifu': wasifu,
        'crops': crops,
        if (visitFeeTzs != null) 'visit_fee_tzs': visitFeeTzs,
        'phone': phone,
        'whatsapp': whatsapp,
        'email': email,
      };
}

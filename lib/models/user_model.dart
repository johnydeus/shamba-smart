// User roles supported by Shamba Smart.
// The former separate `duka`, `muuzaji` and `mwekezaji` roles are now merged
// into a single `biashara` role with an internal [BiasharaType] sub-type.
enum UserRole { mkulima, biashara, afisa }

// Sub-type of a Biashara account. Preserves the Duka (agrovet directory) and
// Mwekezaji / Muuzaji-Dalali distinctions without needing separate roles.
enum BiasharaType { duka, mwekezaji, muuzajiDalali }

enum ProductType { pesticides, fertilizers, seeds, tools, all }
enum InvestmentType { landLease, projectFunding, bulkPurchase, infrastructure }

extension UserRoleX on UserRole {
  String get key => name;

  String get label => switch (this) {
        UserRole.mkulima  => 'Mkulima',
        UserRole.biashara => 'Biashara',
        UserRole.afisa    => 'Afisa Kilimo',
      };

  String get shortLabel => switch (this) {
        UserRole.mkulima  => 'Mkulima',
        UserRole.biashara => 'Biashara',
        UserRole.afisa    => 'Afisa',
      };

  String get colorHex => switch (this) {
        UserRole.mkulima  => '#2E7D32',
        UserRole.biashara => '#C8860A',
        UserRole.afisa    => '#00695C',
      };

  // Legacy-tolerant: pre-merge accounts stored role='duka'/'muuzaji'/'mwekezaji'
  // in the DB and in cached profiles. Map those to `biashara` so old rows and
  // stale caches never crash or fall back to the wrong role.
  static UserRole fromKey(String key) {
    if (key == 'duka' || key == 'muuzaji' || key == 'mwekezaji') {
      return UserRole.biashara;
    }
    return UserRole.values.firstWhere((r) => r.key == key,
        orElse: () => UserRole.mkulima);
  }
}

extension BiasharaTypeX on BiasharaType {
  String get key => switch (this) {
        BiasharaType.duka          => 'duka',
        BiasharaType.mwekezaji     => 'mwekezaji',
        BiasharaType.muuzajiDalali => 'muuzaji_dalali',
      };

  String get label => switch (this) {
        BiasharaType.duka          => 'Duka la Dawa',
        BiasharaType.mwekezaji     => 'Mwekezaji',
        BiasharaType.muuzajiDalali => 'Muuzaji/Dalali',
      };

  // Accepts the new `biashara_type` values AND the legacy role keys, so a
  // sub-type can be reconstructed from either column during/after migration.
  static BiasharaType? fromKey(String? key) => switch (key) {
        'duka'           => BiasharaType.duka,
        'mwekezaji'      => BiasharaType.mwekezaji,
        'muuzaji_dalali' => BiasharaType.muuzajiDalali,
        'muuzaji'        => BiasharaType.muuzajiDalali,
        _                => null,
      };
}

class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;       // unique login identifier (replaces phone)
  final String password;
  final String region;
  final UserRole role;
  final DateTime joinedAt;
  int listingCount;
  int salesCount;

  // Mkulima fields
  final double? farmSize;
  final String? mainCrops;

  // Biashara sub-type (duka / mwekezaji / muuzaji_dalali). Null for non-biashara.
  final BiasharaType? biasharaType;

  // Duka fields
  final String? shopName;
  final String? productType;

  // Muuzaji fields
  final String? businessName;
  final String? cropsTraded;

  // Mwekezaji fields
  final String? investmentType;

  // Afisa Kilimo fields
  final String? organization;
  final String? badgeNumber;
  final String? district;

  // All roles this account holds — enables multi-role switching
  final List<UserRole> allRoles;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    required this.region,
    required this.role,
    required this.joinedAt,
    this.listingCount = 0,
    this.salesCount = 0,
    this.farmSize,
    this.mainCrops,
    this.biasharaType,
    this.shopName,
    this.productType,
    this.businessName,
    this.cropsTraded,
    this.investmentType,
    this.organization,
    this.badgeNumber,
    this.district,
    List<UserRole>? allRoles,
  }) : allRoles = allRoles ?? [role];

  String get displayName => '$firstName $lastName';

  String get initials =>
      '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'
          .toUpperCase();

  // Build UserModel from Supabase profiles table row (snake_case keys)
  factory UserModel.fromSupabase(Map<String, dynamic> j) => UserModel(
        id: j['id'] as String,
        firstName: j['first_name'] as String,
        lastName: j['last_name'] as String,
        email: j['email'] as String,
        password: '',
        region: j['region'] as String,
        role: UserRoleX.fromKey(j['role'] as String),
        joinedAt: DateTime.parse(j['joined_at'] as String),
        listingCount: (j['listing_count'] as int?) ?? 0,
        salesCount: (j['sales_count'] as int?) ?? 0,
        farmSize: (j['farm_size'] as num?)?.toDouble(),
        mainCrops: j['main_crops'] as String?,
        // Prefer the explicit biashara_type column; fall back to the (possibly
        // legacy) role key so rows read before the backfill still resolve.
        biasharaType: BiasharaTypeX.fromKey(j['biashara_type'] as String?) ??
            BiasharaTypeX.fromKey(j['role'] as String?),
        shopName: j['shop_name'] as String?,
        productType: j['product_type'] as String?,
        businessName: j['business_name'] as String?,
        cropsTraded: j['crops_traded'] as String?,
        investmentType: j['investment_type'] as String?,
        organization: j['organization'] as String?,
        badgeNumber: j['badge_number'] as String?,
        district: j['district'] as String?,
        // De-duplicate: legacy arrays may hold several business keys
        // (duka/muuzaji/mwekezaji) that all collapse to `biashara`.
        allRoles: (j['all_roles'] as List?)
            ?.map((r) => UserRoleX.fromKey(r as String))
            .toSet()
            .toList(),
      );

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
        id: j['id'] as String,
        firstName: j['firstName'] as String,
        lastName: j['lastName'] as String,
        // support old 'phone' key for existing saved users
        email: (j['email'] ?? j['phone'] ?? '') as String,
        password: j['password'] as String,
        region: j['region'] as String,
        role: UserRoleX.fromKey(j['role'] as String),
        joinedAt: DateTime.parse(j['joinedAt'] as String),
        listingCount: (j['listingCount'] as int?) ?? 0,
        salesCount: (j['salesCount'] as int?) ?? 0,
        farmSize: (j['farmSize'] as num?)?.toDouble(),
        mainCrops: j['mainCrops'] as String?,
        biasharaType: BiasharaTypeX.fromKey(j['biasharaType'] as String?) ??
            BiasharaTypeX.fromKey(j['role'] as String?),
        shopName: j['shopName'] as String?,
        productType: j['productType'] as String?,
        businessName: j['businessName'] as String?,
        cropsTraded: j['cropsTraded'] as String?,
        investmentType: j['investmentType'] as String?,
        organization: j['organization'] as String?,
        badgeNumber: j['badgeNumber'] as String?,
        district: j['district'] as String?,
        // Backward compat: existing users without allRoles default to [role].
        // De-duplicate so legacy business keys collapse to a single `biashara`.
        allRoles: (j['allRoles'] as List?)
            ?.map((r) => UserRoleX.fromKey(r as String))
            .toSet()
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'password': password,
        'region': region,
        'role': role.key,
        'joinedAt': joinedAt.toIso8601String(),
        'listingCount': listingCount,
        'salesCount': salesCount,
        if (farmSize != null) 'farmSize': farmSize,
        if (mainCrops != null) 'mainCrops': mainCrops,
        if (biasharaType != null) 'biasharaType': biasharaType!.key,
        if (shopName != null) 'shopName': shopName,
        if (productType != null) 'productType': productType,
        if (businessName != null) 'businessName': businessName,
        if (cropsTraded != null) 'cropsTraded': cropsTraded,
        if (investmentType != null) 'investmentType': investmentType,
        if (organization != null) 'organization': organization,
        if (badgeNumber != null) 'badgeNumber': badgeNumber,
        if (district != null) 'district': district,
        'allRoles': allRoles.map((r) => r.key).toList(),
      };
}

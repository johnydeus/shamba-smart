import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

const _kCachedProfile = 'ss_cached_profile';

class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;

  static SupabaseClient get _client => Supabase.instance.client;

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  // Restore session on app start — Supabase persists tokens across restarts
  Future<void> init() async {
    final session = _client.auth.currentSession;
    if (session == null) return;

    // Load cached profile instantly — app opens immediately with this.
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kCachedProfile);
    if (raw != null) {
      try {
        _currentUser =
            UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        notifyListeners();
      } catch (_) {}
    }

    // Refresh profile from network in the background — never blocks startup.
    // If offline, the cached profile above is sufficient.
    _fetchAndCacheProfile(session.user.id).catchError(
      (e) => debugPrint('AuthProvider background profile refresh: $e'),
    );
  }

  // Register new user — creates Supabase auth account + saves profile to DB
  Future<String?> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String region,
    required UserRole role,
    BiasharaType? biasharaType,
    double? farmSize,
    String? mainCrops,
    String? shopName,
    String? productType,
    String? businessName,
    String? cropsTraded,
    String? investmentType,
    String? organization,
    String? badgeNumber,
    String? district,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    if (!cleanEmail.contains('@') || !cleanEmail.contains('.')) {
      return 'Weka barua pepe sahihi (mfano: jina@gmail.com).';
    }
    if (password.length < 6) {
      return 'Nywila lazima iwe na herufi 6 au zaidi.';
    }

    try {
      final res =
          await _client.auth.signUp(email: cleanEmail, password: password);
      if (res.user == null) return 'Usajili haujafanikiwa. Jaribu tena.';

      final uid = res.user!.id;
      final now = DateTime.now();

      final displayName = '${firstName.trim()} ${lastName.trim()}'.trim();
      final extraInfo = mainCrops ?? shopName ?? businessName ?? '';

      // Write to profiles table (friend's new schema)
      try {
        await _client.from('profiles').insert({
          'id': uid,
          'first_name': firstName.trim(),
          'last_name': lastName.trim(),
          'email': cleanEmail,
          'region': region,
          'role': role.key,
          'biashara_type': biasharaType?.key,
          'joined_at': now.toIso8601String(),
          'listing_count': 0,
          'sales_count': 0,
          'farm_size': farmSize,
          'main_crops': mainCrops,
          'shop_name': shopName,
          'product_type': productType,
          'business_name': businessName,
          'crops_traded': cropsTraded,
          'investment_type': investmentType,
          'organization': organization,
          'badge_number': badgeNumber,
          'district': district,
          'all_roles': [role.key],
        });
      } catch (e) {
        debugPrint('profiles insert error (non-fatal): $e');
      }

      // Also write to farmers table so the user directory always finds them
      try {
        await _client.from('farmers').upsert({
          'id': uid,
          'phone': cleanEmail,
          'name': displayName,
          'region': region,
          'role': role.key,
          'color_hex': role.colorHex,
          'extra_info': extraInfo,
          'subscription': 'free',
          'language': 'sw',
          'created_at': now.toIso8601String(),
        });
      } catch (e) {
        debugPrint('farmers upsert error (non-fatal): $e');
      }

      _currentUser = UserModel(
        id: uid,
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        email: cleanEmail,
        password: '',
        region: region,
        role: role,
        joinedAt: now,
        farmSize: farmSize,
        mainCrops: mainCrops,
        biasharaType: biasharaType,
        shopName: shopName,
        productType: productType,
        businessName: businessName,
        cropsTraded: cropsTraded,
        investmentType: investmentType,
        organization: organization,
        badgeNumber: badgeNumber,
        district: district,
        allRoles: [role],
      );
      await _cacheProfile(_currentUser!);
      notifyListeners();
      return null;
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains('already registered') ||
          e.message.toLowerCase().contains('already exists') ||
          e.message.toLowerCase().contains('user already')) {
        return 'Barua pepe hii tayari imesajiliwa. Ingia badala yake.';
      }
      return 'Hitilafu: ${e.message}';
    } catch (e) {
      return 'Hitilafu: ${e.toString()}';
    }
  }

  // Login — uses Supabase auth then fetches profile from DB
  Future<String?> login(String email, String password) async {
    try {
      final res = await _client.auth.signInWithPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      if (res.user == null) {
        return 'Barua pepe au nywila si sahihi. Jaribu tena.';
      }
      await _fetchAndCacheProfile(res.user!.id);
      if (_currentUser == null) {
        return 'Wasifu wako haukupatikana. Wasiliana na msaada.';
      }
      notifyListeners();
      return null;
    } on AuthException {
      return 'Barua pepe au nywila si sahihi. Jaribu tena.';
    } catch (_) {
      return 'Hitilafu ya mtandao. Angalia muunganisho wako wa intaneti.';
    }
  }

  // Log out — clears Supabase session and local cache
  Future<void> logout() async {
    // Clear local state first so UI responds immediately
    _currentUser = null;
    notifyListeners();
    // Then clean up backend + cache (errors here must not block logout)
    try { await _client.auth.signOut(); } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kCachedProfile);
    } catch (_) {}
  }

  // Switch active role (user must already hold this role)
  Future<void> switchRole(UserRole newRole) async {
    if (_currentUser == null) return;
    if (!_currentUser!.allRoles.contains(newRole)) return;
    _currentUser = _rebuildUser(_currentUser!, activeRole: newRole);
    await _updateProfile({'role': newRole.key});
    notifyListeners();
  }

  // Add a new role to the current user's account
  Future<String?> addRole({
    required UserRole role,
    BiasharaType? biasharaType,
    String? shopName,
    String? productType,
    String? businessName,
    String? cropsTraded,
    String? investmentType,
    String? organization,
    String? badgeNumber,
    String? district,
  }) async {
    if (_currentUser == null) return 'Tafadhali ingia kwanza.';
    if (_currentUser!.allRoles.contains(role)) {
      return 'Una jukumu hili tayari kwenye akaunti yako.';
    }

    final updatedRoles = [..._currentUser!.allRoles, role];
    _currentUser = _rebuildUser(
      _currentUser!,
      allRoles: updatedRoles,
      biasharaType: biasharaType ?? _currentUser!.biasharaType,
      shopName: shopName ?? _currentUser!.shopName,
      productType: productType ?? _currentUser!.productType,
      businessName: businessName ?? _currentUser!.businessName,
      cropsTraded: cropsTraded ?? _currentUser!.cropsTraded,
      investmentType: investmentType ?? _currentUser!.investmentType,
      organization: organization ?? _currentUser!.organization,
      badgeNumber: badgeNumber ?? _currentUser!.badgeNumber,
      district: district ?? _currentUser!.district,
    );

    await _updateProfile({
      'all_roles': updatedRoles.map((r) => r.key).toList(),
      if (biasharaType != null) 'biashara_type': biasharaType.key,
      'shop_name': shopName,
      'product_type': productType,
      'business_name': businessName,
      'crops_traded': cropsTraded,
      'investment_type': investmentType,
      'organization': organization,
      'badge_number': badgeNumber,
      'district': district,
    });

    notifyListeners();
    return null;
  }

  Future<void> incrementListingCount() async {
    if (_currentUser == null) return;
    _currentUser!.listingCount++;
    await _updateProfile({'listing_count': _currentUser!.listingCount});
    notifyListeners();
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<void> _fetchAndCacheProfile(String userId) async {
    // 1. Try profiles table (friend's new schema)
    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle()
          .timeout(const Duration(seconds: 8));
      if (data != null) {
        _currentUser = UserModel.fromSupabase(data);
        await _cacheProfile(_currentUser!);
        notifyListeners();
        return;
      }
    } catch (e) {
      debugPrint('profiles table fetch error: $e');
    }

    // 2. Fall back to farmers table (existing schema)
    try {
      final data = await _client
          .from('farmers')
          .select()
          .eq('id', userId)
          .maybeSingle()
          .timeout(const Duration(seconds: 8));
      if (data != null) {
        // Reconstruct UserModel from farmers row
        final profileRaw = data['profile_json'] as String?;
        if (profileRaw != null && profileRaw.isNotEmpty) {
          final json = jsonDecode(profileRaw) as Map<String, dynamic>;
          json['id'] = userId;
          json['password'] = '';
          _currentUser = UserModel.fromJson(json);
        } else {
          final fullName = (data['name'] as String? ?? 'Mtumiaji').trim();
          final parts = fullName.split(' ');
          _currentUser = UserModel(
            id: userId,
            firstName: parts.isNotEmpty ? parts.first : 'Mtumiaji',
            lastName: parts.length > 1 ? parts.sublist(1).join(' ') : '',
            email: data['phone'] as String? ?? '',
            password: '',
            region: data['region'] as String? ?? '',
            role: UserRoleX.fromKey(data['role'] as String? ?? 'mkulima'),
            joinedAt: DateTime.tryParse(
                    data['created_at'] as String? ?? '') ??
                DateTime.now(),
          );
        }
        await _cacheProfile(_currentUser!);
        notifyListeners();
        return;
      }
    } catch (e) {
      debugPrint('farmers table fetch error: $e');
    }

    // 3. Last resort: build a minimal user from the auth session so login
    //    always succeeds even if both tables are missing/empty.
    final authUser = _client.auth.currentUser;
    if (authUser != null) {
      final email = authUser.email ?? '';
      _currentUser = UserModel(
        id: userId,
        firstName: email.split('@').first,
        lastName: '',
        email: email,
        password: '',
        region: '',
        role: UserRole.mkulima,
        joinedAt: DateTime.now(),
      );
      await _cacheProfile(_currentUser!);
      notifyListeners();
    }
  }

  Future<void> _updateProfile(Map<String, dynamic> fields) async {
    if (_currentUser == null) return;
    try {
      await _client
          .from('profiles')
          .update(fields)
          .eq('id', _currentUser!.id);
      await _cacheProfile(_currentUser!);
    } catch (e) {
      debugPrint('Error updating profile: $e');
    }
  }

  Future<void> _cacheProfile(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCachedProfile, jsonEncode(user.toJson()));
  }

  UserModel _rebuildUser(
    UserModel u, {
    UserRole? activeRole,
    List<UserRole>? allRoles,
    BiasharaType? biasharaType,
    String? shopName,
    String? productType,
    String? businessName,
    String? cropsTraded,
    String? investmentType,
    String? organization,
    String? badgeNumber,
    String? district,
  }) =>
      UserModel(
        id: u.id,
        firstName: u.firstName,
        lastName: u.lastName,
        email: u.email,
        password: u.password,
        region: u.region,
        role: activeRole ?? u.role,
        joinedAt: u.joinedAt,
        listingCount: u.listingCount,
        salesCount: u.salesCount,
        farmSize: u.farmSize,
        mainCrops: u.mainCrops,
        biasharaType: biasharaType ?? u.biasharaType,
        shopName: shopName ?? u.shopName,
        productType: productType ?? u.productType,
        businessName: businessName ?? u.businessName,
        cropsTraded: cropsTraded ?? u.cropsTraded,
        investmentType: investmentType ?? u.investmentType,
        organization: organization ?? u.organization,
        badgeNumber: badgeNumber ?? u.badgeNumber,
        district: district ?? u.district,
        allRoles: allRoles ?? u.allRoles,
      );
}

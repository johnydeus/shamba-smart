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

    // Show cached profile instantly while fetching fresh data
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kCachedProfile);
    if (raw != null) {
      try {
        _currentUser =
            UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        notifyListeners();
      } catch (_) {}
    }

    await _fetchAndCacheProfile(session.user.id);
  }

  // Register new user — creates Supabase auth account + saves profile to DB
  Future<String?> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String region,
    required UserRole role,
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

      await _client.from('profiles').insert({
        'id': uid,
        'first_name': firstName.trim(),
        'last_name': lastName.trim(),
        'email': cleanEmail,
        'region': region,
        'role': role.key,
        'joined_at': now.toIso8601String(),
        'listing_count': 0,
        'sales_count': 0,
        if (farmSize != null) 'farm_size': farmSize,
        if (mainCrops != null) 'main_crops': mainCrops,
        if (shopName != null) 'shop_name': shopName,
        if (productType != null) 'product_type': productType,
        if (businessName != null) 'business_name': businessName,
        if (cropsTraded != null) 'crops_traded': cropsTraded,
        if (investmentType != null) 'investment_type': investmentType,
        if (organization != null) 'organization': organization,
        if (badgeNumber != null) 'badge_number': badgeNumber,
        if (district != null) 'district': district,
        'all_roles': [role.key],
      });

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
    await _client.auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kCachedProfile);
    _currentUser = null;
    notifyListeners();
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
      if (shopName != null) 'shop_name': shopName,
      if (productType != null) 'product_type': productType,
      if (businessName != null) 'business_name': businessName,
      if (cropsTraded != null) 'crops_traded': cropsTraded,
      if (investmentType != null) 'investment_type': investmentType,
      if (organization != null) 'organization': organization,
      if (badgeNumber != null) 'badge_number': badgeNumber,
      if (district != null) 'district': district,
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
    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      _currentUser = UserModel.fromSupabase(data);
      await _cacheProfile(_currentUser!);
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching profile: $e');
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

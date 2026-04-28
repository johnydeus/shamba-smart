import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

const _kUsers   = 'ss_users';
const _kSession = 'last_user_id';

class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;
  List<UserModel> _users = [];

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  // Load users and auto-login from saved session on app start
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kUsers);
    if (raw != null) {
      final list = jsonDecode(raw) as List;
      _users = list
          .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    final lastId = prefs.getString(_kSession);
    if (lastId != null) {
      try {
        _currentUser = _users.firstWhere((u) => u.id == lastId);
      } catch (_) {}
    }

    notifyListeners();
  }

  // Register a new user — returns null on success, error message on failure
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

    final exists = _users.any((u) => u.email == cleanEmail);
    if (exists) {
      return 'Barua pepe hii tayari imesajiliwa. Ingia badala yake.';
    }

    if (password.length < 6) {
      return 'Nywila lazima iwe na herufi 6 au zaidi.';
    }

    final newUser = UserModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      email: cleanEmail,
      password: password,
      region: region,
      role: role,
      joinedAt: DateTime.now(),
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
    );

    _users.add(newUser);
    await _saveUsers();

    _currentUser = newUser;
    await _saveSession(newUser.id);
    notifyListeners();
    return null;
  }

  // Login by email + password — returns null on success, error on failure
  Future<String?> login(String email, String password) async {
    try {
      final user = _users.firstWhere(
        (u) =>
            u.email == email.trim().toLowerCase() &&
            u.password == password,
      );
      _currentUser = user;
      await _saveSession(user.id);
      notifyListeners();
      return null;
    } catch (_) {
      return 'Barua pepe au nywila si sahihi. Jaribu tena.';
    }
  }

  // Log out and clear session
  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kSession);
    notifyListeners();
  }

  // Switch active role (user must already have this role)
  Future<void> switchRole(UserRole newRole) async {
    if (_currentUser == null) return;
    if (!_currentUser!.allRoles.contains(newRole)) return;
    _currentUser = _rebuildUser(_currentUser!, activeRole: newRole);
    _updateUserInList(_currentUser!);
    await _saveUsers();
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
    _updateUserInList(_currentUser!);
    await _saveUsers();
    notifyListeners();
    return null;
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

  void _updateUserInList(UserModel updated) {
    final idx = _users.indexWhere((u) => u.id == updated.id);
    if (idx != -1) _users[idx] = updated;
  }

  // Increment listing count after user posts a new listing
  Future<void> incrementListingCount() async {
    if (_currentUser == null) return;
    _currentUser!.listingCount++;
    await _saveUsers();
    notifyListeners();
  }

  Future<void> _saveUsers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _kUsers, jsonEncode(_users.map((u) => u.toJson()).toList()));
  }

  Future<void> _saveSession(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSession, id);
  }
}

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

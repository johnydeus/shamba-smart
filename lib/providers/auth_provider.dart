import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

// Legacy keys — only ever READ, never written, so old installs can still
// restore their session one last time before migrating to Supabase Auth.
const _kLegacyUsers   = 'ss_users';
const _kLegacySession = 'last_user_id';

class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  static SupabaseClient get _sb => Supabase.instance.client;

  // ── Init ─────────────────────────────────────────────────────────────────────
  // supabase_flutter v2 automatically restores the JWT from secure storage on
  // every app start, so currentSession is non-null without any extra work.

  Future<void> init() async {
    // 1. Preferred: active Supabase Auth session (survives reinstalls on same
    //    device partition, and works on any device the user signs in on).
    final session = _sb.auth.currentSession;
    if (session != null) {
      await _loadProfileFromSupabase(session.user.id, session.user.email ?? '');
      notifyListeners();
      return;
    }

    // 2. Legacy: user registered before Supabase Auth was introduced.
    //    Restore from old SharedPreferences store once more; on next logout +
    //    re-login the Supabase Auth path takes over permanently.
    await _tryLegacySession();
    notifyListeners();

    _retryPendingProfileSync();
  }

  // ── Register ──────────────────────────────────────────────────────────────────

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
      final response = await _sb.auth.signUp(
        email: cleanEmail,
        password: password,
      );

      final authUser = response.user;
      if (authUser == null) {
        return 'Usajili haukufanikiwa. Jaribu tena baadaye.';
      }

      final newUser = UserModel(
        id: authUser.id,   // Supabase Auth UUID — works on every device
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        email: cleanEmail,
        password: '',      // never stored — Supabase Auth owns the credentials
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

      await _upsertProfile(newUser);
      _currentUser = newUser;
      notifyListeners();
      return null;

    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('already registered') || msg.contains('already exists') ||
          msg.contains('user already')) {
        return 'Barua pepe hii tayari imesajiliwa. Ingia badala yake.';
      }
      return 'Hitilafu ya usajili: ${e.message}';
    } catch (_) {
      return 'Hitilafu ya mtandao. Angalia intaneti na ujaribu tena.';
    }
  }

  // ── Login ─────────────────────────────────────────────────────────────────────

  Future<String?> login(String email, String password) async {
    try {
      final response = await _sb.auth.signInWithPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      final authUser = response.user;
      if (authUser == null) {
        return 'Barua pepe au nywila si sahihi. Jaribu tena.';
      }

      await _loadProfileFromSupabase(authUser.id, authUser.email ?? '');

      // Profile missing in farmers table — create a minimal one so the app works
      if (_currentUser == null) {
        final fallback = UserModel(
          id: authUser.id,
          firstName: (authUser.email ?? 'Mtumiaji').split('@').first,
          lastName: '',
          email: authUser.email ?? '',
          password: '',
          region: '',
          role: UserRole.mkulima,
          joinedAt: DateTime.now(),
        );
        await _upsertProfile(fallback);
        _currentUser = fallback;
      }

      notifyListeners();
      return null;

    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('invalid login') || msg.contains('invalid') ||
          msg.contains('wrong') || msg.contains('credentials')) {
        return 'Barua pepe au nywila si sahihi. Jaribu tena.';
      }
      if (msg.contains('email not confirmed')) {
        return 'Thibitisha barua pepe yako kwanza, kisha ujaribu kuingia.';
      }
      if (msg.contains('too many')) {
        return 'Majaribio mengi sana. Subiri dakika moja kisha jaribu tena.';
      }
      return 'Hitilafu ya kuingia: ${e.message}';
    } catch (_) {
      return 'Hitilafu ya mtandao. Angalia intaneti na ujaribu tena.';
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    _currentUser = null;
    notifyListeners();
    try {
      await _sb.auth.signOut();
    } catch (_) {}
    // Clear legacy session key so old-install users are fully signed out too
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLegacySession);
  }

  // ── Switch active role ────────────────────────────────────────────────────────

  Future<void> switchRole(UserRole newRole) async {
    if (_currentUser == null) return;
    if (!_currentUser!.allRoles.contains(newRole)) return;
    _currentUser = _rebuild(_currentUser!, activeRole: newRole);
    await _upsertProfile(_currentUser!);
    notifyListeners();
  }

  // ── Add a new role ────────────────────────────────────────────────────────────

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
    _currentUser = _rebuild(
      _currentUser!,
      allRoles: [..._currentUser!.allRoles, role],
      shopName: shopName ?? _currentUser!.shopName,
      productType: productType ?? _currentUser!.productType,
      businessName: businessName ?? _currentUser!.businessName,
      cropsTraded: cropsTraded ?? _currentUser!.cropsTraded,
      investmentType: investmentType ?? _currentUser!.investmentType,
      organization: organization ?? _currentUser!.organization,
      badgeNumber: badgeNumber ?? _currentUser!.badgeNumber,
      district: district ?? _currentUser!.district,
    );
    await _upsertProfile(_currentUser!);
    notifyListeners();
    return null;
  }

  // ── Increment listing count ───────────────────────────────────────────────────

  Future<void> incrementListingCount() async {
    if (_currentUser == null) return;
    _currentUser!.listingCount++;
    await _upsertProfile(_currentUser!);
    notifyListeners();
  }

  // ── Private: load profile from farmers table ──────────────────────────────────

  Future<void> _loadProfileFromSupabase(String uid, String email) async {
    try {
      final rows = await _sb
          .from('farmers')
          .select('profile_json, name, region, role, created_at')
          .eq('id', uid)
          .limit(1);

      final list = rows as List;
      if (list.isEmpty) return;

      final row = list.first as Map<String, dynamic>;
      final profileRaw = row['profile_json'] as String?;

      if (profileRaw != null && profileRaw.isNotEmpty) {
        final json = jsonDecode(profileRaw) as Map<String, dynamic>;
        // Always overwrite id/email/password from the live session — these
        // must never come from a cached JSON blob.
        json['id']       = uid;
        json['email']    = email;
        json['password'] = '';
        _currentUser = UserModel.fromJson(json);
        return;
      }

      // profile_json column not yet present or empty — build from basic columns
      final fullName = (row['name'] as String? ?? 'Mtumiaji').trim();
      final parts = fullName.split(' ');
      _currentUser = UserModel(
        id: uid,
        firstName: parts.isNotEmpty ? parts.first : 'Mtumiaji',
        lastName: parts.length > 1 ? parts.sublist(1).join(' ') : '',
        email: email,
        password: '',
        region: row['region'] as String? ?? '',
        role: UserRoleX.fromKey(row['role'] as String? ?? 'mkulima'),
        joinedAt: DateTime.tryParse(
                row['created_at'] as String? ?? '') ??
            DateTime.now(),
      );
    } catch (e) {
      debugPrint('AuthProvider._loadProfileFromSupabase error: $e');
      _currentUser = null;
      try { await _sb.auth.signOut(); } catch (_) {}
    }
  }

  // ── Private: write full profile to farmers table ──────────────────────────────

  Future<void> _upsertProfile(UserModel user) async {
    try {
      await _sb.from('farmers').upsert({
        'id':           user.id,
        'phone':        user.email,
        'name':         user.displayName,
        'region':       user.region,
        'role':         user.role.key,
        'color_hex':    user.role.colorHex,
        'extra_info':   user.mainCrops ?? user.shopName ??
                        user.businessName ?? '',
        'subscription': 'free',
        'language':     'sw',
        'created_at':   user.joinedAt.toIso8601String(),
        'profile_json': jsonEncode(user.toJson()),
      });
    } catch (e) {
      debugPrint('AuthProvider._upsertProfile error: $e');
    }
  }

  // ── Private: legacy SharedPreferences session restore ────────────────────────

  Future<void> _tryLegacySession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kLegacyUsers);
      if (raw == null) return;

      final list  = jsonDecode(raw) as List;
      final users = list
          .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
          .toList();

      final lastId = prefs.getString(_kLegacySession);
      if (lastId == null) return;

      try {
        _currentUser = users.firstWhere((u) => u.id == lastId);
      } catch (_) {}
    } catch (e) {
      debugPrint('AuthProvider._tryLegacySession error: $e');
    }
  }

  // ── Private: retry offline profile upserts ────────────────────────────────────

  Future<void> _retryPendingProfileSync() async {
    const kPending = 'ss_pending_sync';
    try {
      final conn = await Connectivity().checkConnectivity();
      if (conn == ConnectivityResult.none) return;

      final prefs   = await SharedPreferences.getInstance();
      final pending = prefs.getStringList(kPending) ?? [];
      if (pending.isEmpty) return;

      final rawUsers = prefs.getString(_kLegacyUsers);
      if (rawUsers == null) return;

      final users = (jsonDecode(rawUsers) as List)
          .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
          .toList();

      final synced = <String>[];
      for (final userId in pending) {
        try {
          final user = users.firstWhere((u) => u.id == userId);
          await _upsertProfile(user);
          synced.add(userId);
        } catch (_) {}
      }

      if (synced.isNotEmpty) {
        final remaining =
            pending.where((id) => !synced.contains(id)).toList();
        await prefs.setStringList(kPending, remaining);
      }
    } catch (e) {
      debugPrint('AuthProvider._retryPendingProfileSync error: $e');
    }
  }

  // ── Private: helper to rebuild UserModel ──────────────────────────────────────

  UserModel _rebuild(
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

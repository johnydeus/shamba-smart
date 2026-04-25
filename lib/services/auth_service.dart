import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static SupabaseClient get _client => Supabase.instance.client;

  // Create a new account with email and password
  static Future<String?> signUp({
    required String email,
    required String password,
  }) async {
    try {
      await _client.auth.signUp(email: email, password: password);
      return null; // null means success
    } catch (e) {
      return 'Hitilafu: ${e.toString()}';
    }
  }

  // Login with existing email and password
  static Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
      return null; // null means success
    } catch (e) {
      return 'Barua pepe au nywila si sahihi. Jaribu tena.';
    }
  }

  // Log the farmer out
  static Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // Check if a farmer is currently logged in
  static bool get isLoggedIn => _client.auth.currentUser != null;

  // Get the current logged-in user
  static User? get currentUser => _client.auth.currentUser;
}

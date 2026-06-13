import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiKeys {
  ApiKeys._();

  // Public keys — safe to ship in the APK; Supabase RLS enforces access control.
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnon => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  // All secret API keys have moved to Supabase Edge Functions.
  // Proxies always have the keys server-side — return true so feature gates pass.
  static bool get hasClaude => true;
  static bool get hasIsdaSoil => true;
  static bool get hasPlanet => true;
  static bool get hasCropHealth => true;
  static bool get hasPlantId => true;
}

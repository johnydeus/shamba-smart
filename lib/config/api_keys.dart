import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiKeys {
  ApiKeys._();

  static String get claude => dotenv.env['CLAUDE_API_KEY'] ?? '';
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnon => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  static String get isdaSoilToken => dotenv.env['ISDASOIL_TOKEN'] ?? '';
  static String get planetApiKey => dotenv.env['PLANET_API_KEY'] ?? '';
  static String get cropHealth => dotenv.env['CROP_HEALTH_KEY'] ?? '';
  static String get plantId => dotenv.env['PLANT_ID_KEY'] ?? '';

  static bool get hasClaude => claude.isNotEmpty;
  static bool get hasIsdaSoil =>
      isdaSoilToken.isNotEmpty && isdaSoilToken != 'your_isdasoil_key_here';
  static bool get hasPlanet =>
      planetApiKey.isNotEmpty &&
      planetApiKey != 'SKIP' &&
      planetApiKey != 'your_planet_key_or_SKIP';
  static bool get hasCropHealth =>
      cropHealth.isNotEmpty;
  static bool get hasPlantId =>
      plantId.isNotEmpty && plantId != 'your_plant_id_key_here';
}

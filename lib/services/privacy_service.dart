import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/privacy_settings.dart';

class PrivacyService {
  static SupabaseClient get _db => Supabase.instance.client;

  static Future<PrivacySettings> getSettings(String farmerId) async {
    try {
      final row = await _db
          .from('privacy_settings')
          .select()
          .eq('farmer_id', farmerId)
          .maybeSingle();
      if (row == null) return const PrivacySettings();
      return PrivacySettings.fromMap(row);
    } catch (_) {
      return const PrivacySettings();
    }
  }

  static Future<void> saveSettings(
      String farmerId, PrivacySettings settings) async {
    try {
      await _db.from('privacy_settings').upsert({
        'farmer_id': farmerId,
        ...settings.toMap(),
      });
    } catch (_) {}
  }

  static Future<void> createDefaultSettings(String farmerId) async {
    try {
      final existing = await _db
          .from('privacy_settings')
          .select('id')
          .eq('farmer_id', farmerId)
          .maybeSingle();
      if (existing != null) return;
      await _db.from('privacy_settings').insert({
        'farmer_id': farmerId,
        ...const PrivacySettings().toMap(),
      });
    } catch (_) {}
  }

  // Check if farmer A can message farmer B
  static Future<bool> canSendMessage({
    required String senderId,
    required String recipientId,
    required bool senderIsOfficer,
  }) async {
    try {
      final row = await _db
          .from('privacy_settings')
          .select('who_can_message')
          .eq('farmer_id', recipientId)
          .maybeSingle();
      if (row == null) return true;
      final perm = row['who_can_message'] as String? ?? 'everyone';
      if (perm == 'nobody') return false;
      if (perm == 'officers_only' && !senderIsOfficer) return false;
      return true;
    } catch (_) {
      return true;
    }
  }

  // Get display name respecting privacy settings
  static Future<String> getDisplayName({
    required String farmerId,
    required String realName,
    required String region,
    required bool viewerIsOfficer,
  }) async {
    try {
      final row = await _db
          .from('privacy_settings')
          .select('show_real_name')
          .eq('farmer_id', farmerId)
          .maybeSingle();
      final showReal = row?['show_real_name'] as bool? ?? true;
      if (showReal || viewerIsOfficer) return realName;
      return 'Mkulima wa $region';
    } catch (_) {
      return realName;
    }
  }

  // Export farmer's data as structured map
  static Future<Map<String, dynamic>> exportFarmerData(
      String farmerId) async {
    final data = <String, dynamic>{};
    try {
      final profile = await _db
          .from('profiles')
          .select()
          .eq('id', farmerId)
          .maybeSingle();
      data['profile'] = profile;

      final farms = await _db
          .from('farms')
          .select()
          .eq('farmer_id', farmerId);
      data['farms'] = farms;

      final diagnoses = await _db
          .from('diagnoses')
          .select()
          .eq('farmer_id', farmerId);
      data['diagnoses'] = diagnoses;

      final events = await _db
          .from('farm_events')
          .select()
          .eq('farmer_id', farmerId);
      data['farm_events'] = events;

      data['exported_at'] = DateTime.now().toIso8601String();
    } catch (_) {}
    return data;
  }

  // Permanently delete farmer account
  static Future<void> deleteAccount(String farmerId) async {
    final tables = [
      'privacy_settings',
      'farm_events',
      'farm_seasons',
      'ipm_records',
      'fertiliser_prescriptions',
      'spray_records',
      'price_alerts',
      'farmer_officer_links',
      'officer_ratings',
      'diagnoses',
      'farms',
    ];

    for (final table in tables) {
      try {
        await _db.from(table).delete().eq('farmer_id', farmerId);
      } catch (_) {}
    }

    try {
      await _db.from('profiles').delete().eq('id', farmerId);
    } catch (_) {}
  }
}

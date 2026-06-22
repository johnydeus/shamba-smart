import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/database/app_database.dart';
import '../models/field_officer.dart';

/// Reads the field-officer directory from Supabase `field_officers` and caches
/// it to local SQLite for offline-first viewing.
class FieldOfficerService {
  static SupabaseClient get _db => Supabase.instance.client;
  static final AppDatabase _local = AppDatabase();

  /// Directory: approved + pending officers (pending shown but unverified).
  /// Order: verified DESC, rating DESC, created_at DESC. Falls back to the
  /// local cache when offline / on error.
  static Future<List<FieldOfficer>> directory() async {
    try {
      final rows = await _db
          .from('field_officers')
          .select()
          .inFilter('status', ['approved', 'pending'])
          .order('verified', ascending: false)
          .order('rating', ascending: false)
          .order('created_at', ascending: false)
          .timeout(const Duration(seconds: 8));

      final list = (rows as List).cast<Map<String, dynamic>>();
      // Refresh the offline cache.
      await _local.cacheOfficers(list.map(jsonEncode).toList());
      return list.map(FieldOfficer.fromJson).toList();
    } catch (e) {
      debugPrint('FieldOfficerService.directory error (using cache): $e');
      return _fromCache();
    }
  }

  static Future<List<FieldOfficer>> _fromCache() async {
    try {
      final rows = await _local.cachedOfficers();
      return rows
          .map((r) => FieldOfficer.fromJson(
              jsonDecode(r) as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('FieldOfficerService cache read error: $e');
      return [];
    }
  }

  /// The current user's own officer profile, if they have one.
  static Future<FieldOfficer?> myProfile(String userId) async {
    try {
      final rows = await _db
          .from('field_officers')
          .select()
          .eq('user_id', userId)
          .limit(1)
          .timeout(const Duration(seconds: 8));
      if ((rows as List).isEmpty) return null;
      return FieldOfficer.fromJson(rows.first as Map<String, dynamic>);
    } catch (e) {
      debugPrint('FieldOfficerService.myProfile error: $e');
      return null;
    }
  }

  /// Create the caller's officer profile (verified=false, status='pending' set
  /// by the DB defaults/trigger — we never send those fields).
  static Future<void> create(FieldOfficer draft, {required String userId}) async {
    await _db
        .from('field_officers')
        .insert(draft.toOwnerWrite(userId: userId))
        .timeout(const Duration(seconds: 10));
  }

  /// Update the caller's own profile (RLS restricts to own row).
  static Future<void> update(FieldOfficer draft, {required String userId}) async {
    await _db
        .from('field_officers')
        .update(draft.toOwnerWrite(userId: userId))
        .eq('user_id', userId)
        .timeout(const Duration(seconds: 10));
  }
}

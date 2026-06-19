import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/agrovet_model.dart';

/// Real, DB-backed agrovet directory. Replaces the old AI-generated locator
/// (which hallucinated fake shops). Reads only verified entries from Supabase.
class AgrovetService {
  static SupabaseClient get _db => Supabase.instance.client;

  /// Fetch verified agrovets, optionally filtered by region and/or category.
  /// Every call is bounded by a timeout and fails soft (returns []).
  static Future<List<AgrovetModel>> fetch({
    String? region,
    String? category, // AgrovetCategory.key
  }) async {
    try {
      var query = _db.from('agrovets').select().eq('is_verified', true);
      if (region != null && region.isNotEmpty && region != 'Zote') {
        query = query.eq('region', region);
      }
      if (category != null && category.isNotEmpty) {
        query = query.contains('categories', [category]);
      }
      final rows = await query
          .order('name')
          .limit(200)
          .timeout(const Duration(seconds: 8));

      return (rows as List)
          .map((r) => AgrovetModel.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('AgrovetService.fetch error: $e');
      return [];
    }
  }

  /// The current user's own listing (verified or pending), if any.
  static Future<AgrovetModel?> myListing(String ownerId) async {
    try {
      final rows = await _db
          .from('agrovets')
          .select()
          .eq('owner_id', ownerId)
          .order('created_at', ascending: false)
          .limit(1)
          .timeout(const Duration(seconds: 8));
      if (rows.isEmpty) return null;
      return AgrovetModel.fromJson(rows.first);
    } catch (e) {
      debugPrint('AgrovetService.myListing error: $e');
      return null;
    }
  }

  /// Self-register a shop. Starts unverified (pending admin/officer approval).
  static Future<void> register(AgrovetModel draft, {required String ownerId}) async {
    await _db
        .from('agrovets')
        .insert(draft.toInsert(ownerId: ownerId))
        .timeout(const Duration(seconds: 10));
  }
}

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/listing_model.dart';

/// Supabase-backed listing sync (falls back gracefully if table missing).
class ListingService {
  static SupabaseClient get _db => Supabase.instance.client;

  static Future<List<ListingModel>> fetchAll() async {
    try {
      final rows = await _db
          .from('listings')
          .select()
          .eq('status', 'active')
          .order('created_at', ascending: false)
          .limit(100);

      return (rows as List)
          .map((r) => ListingModel.fromSupabaseJson(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('ListingService.fetchAll: $e');
      return [];
    }
  }

  static Future<void> upsert(ListingModel listing) async {
    try {
      await _db.from('listings').upsert(listing.toSupabaseJson());
    } catch (e) {
      debugPrint('ListingService.upsert: $e');
    }
  }

  static Future<void> delete(String id) async {
    try {
      await _db.from('listings').update({'status': 'deleted'}).eq('id', id);
    } catch (e) {
      debugPrint('ListingService.delete: $e');
    }
  }
}

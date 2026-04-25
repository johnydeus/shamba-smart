import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/farm_model.dart';

class FarmProvider extends ChangeNotifier {
  List<FarmModel> _farms = [];
  String? _currentFarmerId;

  static SupabaseClient get _db => Supabase.instance.client;

  List<FarmModel> get farms => _farms;

  // Load farms: local first (instant), then sync from Supabase in background
  Future<void> init(String farmerId) async {
    _currentFarmerId = farmerId;

    // 1. Load from SharedPreferences immediately (offline-first)
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('farms_$farmerId');
    if (raw != null) {
      final list = jsonDecode(raw) as List;
      _farms = list
          .map((e) => FarmModel.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      notifyListeners();
    }

    // 2. Sync from Supabase in background (picks up farms from other devices)
    _syncFromSupabase(farmerId);
  }

  Future<void> addFarm(FarmModel farm) async {
    _farms.insert(0, farm);
    await _saveLocally();
    notifyListeners();
    // Push to Supabase (non-blocking)
    _upsertToSupabase(farm);
  }

  Future<void> updateFarm(FarmModel updated) async {
    final idx = _farms.indexWhere((f) => f.id == updated.id);
    if (idx != -1) {
      _farms[idx] = updated;
      await _saveLocally();
      notifyListeners();
      _upsertToSupabase(updated);
    }
  }

  Future<void> deleteFarm(String farmId) async {
    _farms.removeWhere((f) => f.id == farmId);
    await _saveLocally();
    notifyListeners();
    _deleteFromSupabase(farmId);
  }

  // ── Local storage ─────────────────────────────────────────

  Future<void> _saveLocally() async {
    if (_currentFarmerId == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'farms_$_currentFarmerId',
      jsonEncode(_farms.map((f) => f.toJson()).toList()),
    );
  }

  // ── Supabase sync ─────────────────────────────────────────

  Future<void> _syncFromSupabase(String farmerId) async {
    try {
      final rows = await _db
          .from('farms')
          .select()
          .eq('farmer_id', farmerId)
          .order('created_at', ascending: false);

      if (rows.isEmpty) return;

      final remoteFarms = rows
          .map((r) => FarmModel.fromJson(_rowToJson(r)))
          .toList();

      // Merge: remote wins for any farm with same id
      final localIds = _farms.map((f) => f.id).toSet();
      for (final remote in remoteFarms) {
        if (!localIds.contains(remote.id)) {
          _farms.add(remote);
        }
      }
      _farms.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      await _saveLocally();
      notifyListeners();
    } catch (e) {
      debugPrint('FarmProvider Supabase sync error: $e');
    }
  }

  Future<void> _upsertToSupabase(FarmModel farm) async {
    try {
      await _db.from('farms').upsert({
        'id': farm.id,
        'farmer_id': farm.farmerId,
        'name': farm.name,
        'gps_lat': farm.gpsLat,
        'gps_lng': farm.gpsLng,
        'acres': farm.acres,
        'crops': farm.crops,
        'soil_type': farm.soilType,
        'region': farm.region,
        'notes': farm.notes,
        'created_at': farm.createdAt.toIso8601String(),
      });
    } catch (e) {
      debugPrint('FarmProvider upsert error: $e');
    }
  }

  Future<void> _deleteFromSupabase(String farmId) async {
    try {
      await _db.from('farms').delete().eq('id', farmId);
    } catch (e) {
      debugPrint('FarmProvider delete error: $e');
    }
  }

  // Convert Supabase snake_case row to camelCase JSON for FarmModel
  Map<String, dynamic> _rowToJson(Map<String, dynamic> row) => {
        'id': row['id'],
        'farmerId': row['farmer_id'],
        'name': row['name'],
        'gpsLat': row['gps_lat'],
        'gpsLng': row['gps_lng'],
        'acres': row['acres'],
        'crops': (row['crops'] as List?)?.cast<String>() ?? [],
        'soilType': row['soil_type'],
        'region': row['region'] ?? 'Morogoro',
        'notes': row['notes'],
        'createdAt': row['created_at'],
      };

  void clear() {
    _farms = [];
    _currentFarmerId = null;
    notifyListeners();
  }
}

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/crop_requirement.dart';

/// Fetches Tanzania crop requirements from Supabase ECOCROP seed data.
class CropRequirementService {
  static final CropRequirementService _instance = CropRequirementService._();
  factory CropRequirementService() => _instance;
  CropRequirementService._();

  static const _fallbackCrops = [
    CropRequirement(name: 'Mahindi', minPh: 5.5, maxPh: 7.5, growingDays: 120),
    CropRequirement(name: 'Nyanya', minPh: 5.5, maxPh: 7.0, growingDays: 90),
    CropRequirement(name: 'Maharagwe', minPh: 5.5, maxPh: 7.5, growingDays: 75),
    CropRequirement(name: 'Muhogo', minPh: 5.0, maxPh: 7.0, growingDays: 300),
    CropRequirement(name: 'Pamba', minPh: 5.5, maxPh: 8.0, growingDays: 180),
    CropRequirement(name: 'Mchele', minPh: 5.0, maxPh: 7.0, growingDays: 120),
    CropRequirement(name: 'Ndizi', minPh: 5.5, maxPh: 7.5, growingDays: 270),
    CropRequirement(name: 'Viazi vitamu', minPh: 5.5, maxPh: 6.5, growingDays: 120),
    CropRequirement(name: 'Alizeti', minPh: 6.0, maxPh: 7.5, growingDays: 100),
    CropRequirement(name: 'Mtama', minPh: 5.5, maxPh: 8.0, growingDays: 100),
    CropRequirement(name: 'Uwele', minPh: 6.0, maxPh: 8.0, growingDays: 90),
    CropRequirement(name: 'Pilipili hoho', minPh: 5.5, maxPh: 7.0, growingDays: 90),
  ];

  List<CropRequirement>? _cache;

  Future<List<CropRequirement>> fetchCrops() async {
    if (_cache != null) return _cache!;

    try {
      final rows = await Supabase.instance.client
          .from('crops')
          .select('name, min_ph, max_ph, growing_days, suitable_regions')
          .order('name');

      if ((rows as List).isNotEmpty) {
        _cache = rows
            .map((r) => CropRequirement.fromJson(Map<String, dynamic>.from(r)))
            .toList();
        return _cache!;
      }
    } catch (e) {
      debugPrint('CropRequirementService: using fallback — $e');
    }

    _cache = _fallbackCrops;
    return _cache!;
  }
}

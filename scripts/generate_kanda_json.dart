// Emits JSON seed files for the Supabase kanda tables from lib/data/*.dart.
// Run: dart run scripts/generate_kanda_json.dart
// ignore_for_file: avoid_relative_lib_imports
import 'dart:convert';
import 'dart:io';

import '../lib/data/crop_calendar_data.dart';
import '../lib/data/fertilizer_data.dart';
import '../lib/data/kanda_data.dart';

void main() {
  // crop_zone_data
  final zones = <Map<String, dynamic>>[];
  KandaData.zones.forEach((name, zone) {
    zones.add({
      'zone_name': zone['jinaEn'],
      'zone_name_sw': name,
      'regions': zone['regions'],
      'food_crops': zone['foodCrops'],
      'cash_crops': zone['cashCrops'],
      'ecology_notes': zone['maelezo'],
    });
  });

  // crop_production_guide
  final prod = <Map<String, dynamic>>[];
  for (final c in FertilizerData.crops) {
    final f = (c['fertilizers'] as Map).cast<String, dynamic>();
    double? amt(String k) {
      final v = f[k];
      if (v == null) return null;
      final a = FertilizerData.fertilizerAmount(v);
      return a > 0 ? a : null;
    }

    final seed = c['seedRateKgHa'] as List?;
    final plants = c['plantsPerHa'] as List?;
    final mat = c['maturityMonths'] as List?;
    final isTon = c['yieldUnit'] == 't/ha';
    prod.add({
      'crop_name_sw': c['jina'],
      'crop_name_en': c['jinaEn'],
      'spacing_row_m': c['spacingRow'],
      'spacing_plant_m': c['spacingPlant'],
      'seed_rate_kg_ha': seed == null
          ? null
          : ((seed[0] as num) + (seed[1] as num)) / 2.0,
      'fertilizer_dap_kg_ha': amt('DAP'),
      'fertilizer_urea_kg_ha': amt('UREA'),
      'fertilizer_tsp_kg_ha': amt('TSP'),
      'fertilizer_can_kg_ha': amt('CAN'),
      'fertilizer_npk_kg_ha': amt('NPK'),
      'yield_current_t_ha': isTon ? c['yieldNow'] : null,
      'yield_potential_t_ha': isTon ? c['yieldPotential'] : null,
      'plants_per_ha_min': plants?[0],
      'plants_per_ha_max': plants?[1],
      'maturity_months_min': mat?[0],
      'maturity_months_max': mat?[1],
    });
  }

  // crop_calendar
  final cal = <Map<String, dynamic>>[];
  for (final entry in CropCalendarData.calendar) {
    final regions = (entry['regions'] as List).cast<String>();
    final acts = (entry['activities'] as Map).cast<String, dynamic>();
    acts.forEach((act, months) {
      final m = (months as List).cast<int>();
      cal.add({
        'crop_name_sw': entry['zao'],
        'region': regions.isEmpty ? null : regions.join(', '),
        'zone_name': entry['kundi'],
        'activity': act,
        'months_active': m,
        'is_peak_month': m.first,
        'notes': entry['maelezo'],
      });
    });
  }

  // district_crop_guide
  final dist = <Map<String, dynamic>>[];
  KandaData.mikoa.forEach((mkoa, regionData) {
    final zone = KandaData.regionToZone[mkoa];
    final wilaya = (regionData['wilaya'] as Map).cast<String, dynamic>();
    wilaya.forEach((name, dRaw) {
      final d = (dRaw as Map).cast<String, dynamic>();
      final alt = d['mwinuko'] as List?;
      final rain = d['mvua'] as List?;
      final temp = d['joto'] as List?;
      final ph = d['ph'] as List?;
      dist.add({
        'mkoa': mkoa,
        'wilaya': name,
        'zone_name': zone,
        'priority_business_crops': d['biashara'],
        'priority_food_crops': d['chakula'],
        'other_business_crops': d['mengine'],
        'altitude_min_m': alt?[0],
        'altitude_max_m': alt?[1],
        'rainfall_min_mm': rain?[0],
        'rainfall_max_mm': rain?[1],
        'temperature_min_c': temp?[0],
        'temperature_max_c': temp?[1],
        'soil_ph_min': ph?[0],
        'soil_ph_max': ph?[1],
        'soil_type': d['udongo'],
      });
    });
  });

  final out = {
    'crop_zone_data': zones,
    'crop_production_guide': prod,
    'crop_calendar': cal,
    'district_crop_guide': dist,
  };
  out.forEach((table, rows) {
    File('scripts/seed_$table.json')
        .writeAsStringSync(jsonEncode(rows));
    stdout.writeln('$table: ${rows.length} rows');
  });
}

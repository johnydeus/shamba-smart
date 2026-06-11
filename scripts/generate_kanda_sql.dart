// Generates seed SQL for the kanda/calendar/production Supabase tables from
// the app's own data files. Run: dart run scripts/generate_kanda_sql.dart
// Output: scripts/kanda_seed.sql
// ignore_for_file: avoid_relative_lib_imports
import 'dart:io';

import '../lib/data/crop_calendar_data.dart';
import '../lib/data/fertilizer_data.dart';
import '../lib/data/kanda_data.dart';

String s(dynamic v) =>
    v == null ? 'NULL' : "'${v.toString().replaceAll("'", "''")}'";

String arr(List? v) => (v == null || v.isEmpty)
    ? 'NULL'
    : 'ARRAY[${v.map(s).join(',')}]::text[]';

String intArr(List? v) => (v == null || v.isEmpty)
    ? 'NULL'
    : 'ARRAY[${v.join(',')}]::int[]';

String n(dynamic v) => v == null ? 'NULL' : v.toString();

void main() {
  final buf = StringBuffer();
  buf.writeln('-- Seed data generated from lib/data/*.dart');
  buf.writeln(
      'TRUNCATE crop_zone_data, crop_production_guide, crop_calendar, district_crop_guide;');

  // ── crop_zone_data ──
  KandaData.zones.forEach((name, zone) {
    buf.writeln(
        'INSERT INTO crop_zone_data (zone_name, zone_name_sw, regions, food_crops, cash_crops, ecology_notes) VALUES '
        '(${s(zone['jinaEn'])}, ${s(name)}, ${arr(zone['regions'] as List)}, '
        '${arr(zone['foodCrops'] as List)}, ${arr(zone['cashCrops'] as List)}, '
        '${s(zone['maelezo'])});');
  });

  // ── crop_production_guide ──
  for (final c in FertilizerData.crops) {
    final f = (c['fertilizers'] as Map).cast<String, dynamic>();
    double? amt(String k) {
      final v = f[k];
      if (v == null) return null;
      final a = FertilizerData.fertilizerAmount(v);
      return a > 0 ? a : null;
    }

    final seed = c['seedRateKgHa'] as List?;
    final seedMid = seed == null
        ? null
        : ((seed[0] as num) + (seed[1] as num)) / 2.0;
    final plants = c['plantsPerHa'] as List?;
    final mat = c['maturityMonths'] as List?;
    final isTon = c['yieldUnit'] == 't/ha';

    buf.writeln(
        'INSERT INTO crop_production_guide (crop_name_sw, crop_name_en, spacing_row_m, spacing_plant_m, seed_rate_kg_ha, '
        'fertilizer_dap_kg_ha, fertilizer_urea_kg_ha, fertilizer_tsp_kg_ha, fertilizer_can_kg_ha, fertilizer_npk_kg_ha, '
        'yield_current_t_ha, yield_potential_t_ha, plants_per_ha_min, plants_per_ha_max, maturity_months_min, maturity_months_max) VALUES '
        '(${s(c['jina'])}, ${s(c['jinaEn'])}, ${n(c['spacingRow'])}, ${n(c['spacingPlant'])}, ${n(seedMid)}, '
        '${n(amt('DAP'))}, ${n(amt('UREA'))}, ${n(amt('TSP'))}, ${n(amt('CAN'))}, ${n(amt('NPK'))}, '
        '${isTon ? n(c['yieldNow']) : 'NULL'}, ${isTon ? n(c['yieldPotential']) : 'NULL'}, '
        '${n(plants?[0])}, ${n(plants?[1])}, ${n(mat?[0])}, ${n(mat?[1])});');
  }

  // ── crop_calendar ──
  for (final entry in CropCalendarData.calendar) {
    final regions = (entry['regions'] as List).cast<String>();
    final regionLabel = regions.isEmpty ? null : regions.join(', ');
    final acts = (entry['activities'] as Map).cast<String, dynamic>();
    acts.forEach((act, months) {
      final m = (months as List).cast<int>();
      buf.writeln(
          'INSERT INTO crop_calendar (crop_name_sw, region, zone_name, activity, months_active, is_peak_month, notes) VALUES '
          '(${s(entry['zao'])}, ${s(regionLabel)}, ${s(entry['kundi'])}, ${s(act)}, ${intArr(m)}, ${m.first}, ${s(entry['maelezo'])});');
    });
  }

  // ── district_crop_guide ──
  KandaData.mikoa.forEach((mkoa, regionData) {
    final zone = KandaData.regionToZone[mkoa];
    final wilaya = (regionData['wilaya'] as Map).cast<String, dynamic>();
    wilaya.forEach((name, dRaw) {
      final d = (dRaw as Map).cast<String, dynamic>();
      final alt = d['mwinuko'] as List?;
      final rain = d['mvua'] as List?;
      final temp = d['joto'] as List?;
      final ph = d['ph'] as List?;
      buf.writeln(
          'INSERT INTO district_crop_guide (mkoa, wilaya, zone_name, priority_business_crops, priority_food_crops, '
          'other_business_crops, other_food_crops, altitude_min_m, altitude_max_m, rainfall_min_mm, rainfall_max_mm, '
          'temperature_min_c, temperature_max_c, soil_ph_min, soil_ph_max, soil_type) VALUES '
          '(${s(mkoa)}, ${s(name)}, ${s(zone)}, ${arr(d['biashara'] as List?)}, ${arr(d['chakula'] as List?)}, '
          '${arr(d['mengine'] as List?)}, NULL, ${n(alt?[0])}, ${n(alt?[1])}, ${n(rain?[0])}, ${n(rain?[1])}, '
          '${n(temp?[0])}, ${n(temp?[1])}, ${n(ph?[0])}, ${n(ph?[1])}, ${s(d['udongo'])});');
    });
  });

  File('scripts/kanda_seed.sql').writeAsStringSync(buf.toString());
  stdout.writeln('Wrote scripts/kanda_seed.sql '
      '(${buf.toString().split('\n').length} lines)');
}

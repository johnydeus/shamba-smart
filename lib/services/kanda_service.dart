// KandaService — maps GPS coordinates to Tanzania ecological agriculture
// zones, regions and districts using official Ministry of Agriculture data
// (Wizara ya Kilimo, 2022).

import '../data/crop_production_data.dart';
import '../data/kanda_data.dart';

class KandaService {
  KandaService._();

  // ── GPS → region name ──────────────────────────────────────────────────────
  static String getRegionFromCoordinates(double lat, double lng) {
    for (final r in KandaData.regionBounds) {
      if (lat >= (r['latMin'] as num) &&
          lat <= (r['latMax'] as num) &&
          lng >= (r['lngMin'] as num) &&
          lng <= (r['lngMax'] as num)) {
        return r['name'] as String;
      }
    }
    return 'Morogoro'; // central fallback within Tanzania
  }

  // ── GPS → zone name ────────────────────────────────────────────────────────
  static String getZoneFromCoordinates(double lat, double lng) {
    final region = getRegionFromCoordinates(lat, lng);
    return KandaData.regionToZone[region] ?? 'Kanda ya Mashariki';
  }

  // ── Zone data ──────────────────────────────────────────────────────────────
  static Map<String, dynamic> getZoneData(String zoneName) {
    final zone = KandaData.zones[zoneName];
    if (zone == null) return {};
    return {'jina': zoneName, ...zone};
  }

  // ── District data ──────────────────────────────────────────────────────────
  static Map<String, dynamic> getDistrictData(String mkoa, String wilaya) {
    final district =
        (KandaData.mikoa[mkoa]?['wilaya'] as Map?)?[wilaya] as Map?;
    if (district == null) return {};
    return {
      'mkoa': mkoa,
      'wilaya': wilaya,
      'zone': KandaData.regionToZone[mkoa],
      ...Map<String, dynamic>.from(district),
    };
  }

  // Districts available for a region
  static List<String> districtsOf(String mkoa) {
    final wilaya = KandaData.mikoa[mkoa]?['wilaya'] as Map?;
    if (wilaya == null) return [];
    return wilaya.keys.cast<String>().toList();
  }

  // ── Recommended crops for a GPS location ───────────────────────────────────
  static List<String> getRecommendedCrops(
    double lat,
    double lng, {
    bool foodCropsOnly = false,
    bool cashCropsOnly = false,
  }) {
    final zoneName = getZoneFromCoordinates(lat, lng);
    final zone = KandaData.zones[zoneName];
    if (zone == null) return [];
    final food = (zone['foodCrops'] as List).cast<String>();
    final cash = (zone['cashCrops'] as List).cast<String>();
    if (foodCropsOnly) return List.of(food);
    if (cashCropsOnly) return List.of(cash);
    return [...food, ...cash];
  }

  // ── Yield data for a crop in a zone ────────────────────────────────────────
  // Returns {sasa, lengo, kipimo, ongezeko (% gap)} or {} if unknown.
  static Map<String, dynamic> getCropYield(String cropName, String zone) {
    final y = CropProductionData.yieldFor(cropName, zone);
    if (y == null) return {};
    final sasa = (y['sasa'] as num?)?.toDouble() ?? 0;
    final lengo = (y['lengo'] as num?)?.toDouble() ?? 0;
    final gainPct = sasa > 0 ? ((lengo - sasa) / sasa * 100).round() : 0;
    return {...y, 'ongezeko': gainPct};
  }
}

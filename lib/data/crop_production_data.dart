// ─────────────────────────────────────────────────────────────────────────────
// CROP PRODUCTION DATA — combined dataset for suitability scoring
//
// Ecology requirements (mvua mm/yr, mwinuko m, pH) are advisory agronomic
// ranges used to match crops against the official district ecology in
// Table 8 (Wizara ya Kilimo Tanzania, 2022).
// ─────────────────────────────────────────────────────────────────────────────

import 'crop_calendar_data.dart';
import 'fertilizer_data.dart';
import 'kanda_data.dart';

class CropProductionData {
  CropProductionData._();

  static const String source = 'Wizara ya Kilimo Tanzania, 2022';

  // ── Crop ecology requirements ──────────────────────────────────────────────
  // crop → {mvua: [min,max] mm, mwinuko: [min,max] m, ph: [min,max], emoji}
  static const Map<String, Map<String, dynamic>> ecology = {
    'Mahindi': {'mvua': [500, 1200], 'mwinuko': [0, 2400], 'ph': [5.5, 7.5], 'emoji': '🌽'},
    'Mpunga': {'mvua': [1000, 2000], 'mwinuko': [0, 1800], 'ph': [5.0, 7.5], 'emoji': '🍚'},
    'Mtama': {'mvua': [400, 800], 'mwinuko': [0, 1800], 'ph': [5.5, 8.5], 'emoji': '🌾'},
    'Uwele': {'mvua': [300, 700], 'mwinuko': [0, 1500], 'ph': [5.5, 8.0], 'emoji': '🌾'},
    'Ulezi': {'mvua': [500, 1000], 'mwinuko': [800, 2400], 'ph': [5.0, 7.5], 'emoji': '🌾'},
    'Ngano': {'mvua': [600, 1200], 'mwinuko': [1200, 2700], 'ph': [5.5, 7.5], 'emoji': '🌾'},
    'Shayiri': {'mvua': [500, 1000], 'mwinuko': [1300, 2700], 'ph': [5.5, 8.0], 'emoji': '🌾'},
    'Maharage': {'mvua': [600, 1200], 'mwinuko': [800, 2300], 'ph': [5.5, 7.0], 'emoji': '🫘'},
    'Kunde': {'mvua': [400, 800], 'mwinuko': [0, 1500], 'ph': [5.5, 7.5], 'emoji': '🫘'},
    'Dengu': {'mvua': [400, 800], 'mwinuko': [500, 2000], 'ph': [5.5, 8.0], 'emoji': '🫘'},
    'Choroko': {'mvua': [400, 800], 'mwinuko': [0, 1500], 'ph': [5.5, 8.0], 'emoji': '🫘'},
    'Mbaazi': {'mvua': [500, 1000], 'mwinuko': [0, 1800], 'ph': [5.0, 8.0], 'emoji': '🫘'},
    'Soya': {'mvua': [600, 1200], 'mwinuko': [200, 1800], 'ph': [5.5, 7.0], 'emoji': '🫘'},
    'Karanga': {'mvua': [500, 1000], 'mwinuko': [0, 1500], 'ph': [5.5, 7.0], 'emoji': '🥜'},
    'Njugu mawe': {'mvua': [400, 900], 'mwinuko': [0, 1500], 'ph': [5.0, 7.5], 'emoji': '🥜'},
    'Alizeti': {'mvua': [500, 900], 'mwinuko': [500, 2000], 'ph': [5.5, 8.0], 'emoji': '🌻'},
    'Ufuta': {'mvua': [500, 900], 'mwinuko': [0, 1200], 'ph': [5.5, 8.0], 'emoji': '🌱'},
    'Pamba': {'mvua': [600, 1000], 'mwinuko': [200, 1500], 'ph': [5.5, 8.5], 'emoji': '☁️'},
    'Kahawa': {'mvua': [1000, 2000], 'mwinuko': [900, 2000], 'ph': [5.0, 6.5], 'emoji': '☕'},
    'Chai': {'mvua': [1200, 2400], 'mwinuko': [1000, 2400], 'ph': [4.5, 6.0], 'emoji': '🍵'},
    'Korosho': {'mvua': [800, 1200], 'mwinuko': [0, 700], 'ph': [5.0, 7.0], 'emoji': '🌰'},
    'Muhogo': {'mvua': [750, 1500], 'mwinuko': [0, 1500], 'ph': [4.5, 7.0], 'emoji': '🍠'},
    'Viazi vitamu': {'mvua': [600, 1200], 'mwinuko': [0, 2000], 'ph': [5.0, 7.0], 'emoji': '🍠'},
    'Viazi mviringo': {'mvua': [800, 1400], 'mwinuko': [1500, 2800], 'ph': [5.0, 6.5], 'emoji': '🥔'},
    'Ndizi': {'mvua': [1000, 2400], 'mwinuko': [500, 2000], 'ph': [5.5, 7.5], 'emoji': '🍌'},
    'Nyanya': {'mvua': [600, 1300], 'mwinuko': [0, 2000], 'ph': [5.5, 7.5], 'emoji': '🍅'},
    'Vitunguu': {'mvua': [500, 1000], 'mwinuko': [500, 2000], 'ph': [6.0, 7.5], 'emoji': '🧅'},
    'Kabichi': {'mvua': [800, 1500], 'mwinuko': [800, 2500], 'ph': [5.5, 7.5], 'emoji': '🥬'},
    'Miwa': {'mvua': [1100, 2400], 'mwinuko': [0, 1500], 'ph': [5.0, 8.5], 'emoji': '🎋'},
    'Tumbaku': {'mvua': [500, 1000], 'mwinuko': [200, 1800], 'ph': [5.0, 6.5], 'emoji': '🍂'},
    'Zabibu': {'mvua': [400, 800], 'mwinuko': [500, 2000], 'ph': [6.0, 8.0], 'emoji': '🍇'},
    'Mkonge': {'mvua': [600, 1200], 'mwinuko': [0, 1500], 'ph': [5.5, 8.0], 'emoji': '🌵'},
    'Pareto': {'mvua': [800, 1400], 'mwinuko': [1700, 2700], 'ph': [5.0, 7.0], 'emoji': '🌼'},
    'Michikichi': {'mvua': [1500, 2400], 'mwinuko': [0, 900], 'ph': [4.5, 7.0], 'emoji': '🌴'},
    'Nazi': {'mvua': [1000, 2000], 'mwinuko': [0, 500], 'ph': [5.5, 8.0], 'emoji': '🥥'},
    'Nanasi': {'mvua': [800, 1500], 'mwinuko': [0, 1200], 'ph': [4.5, 6.5], 'emoji': '🍍'},
    'Papai': {'mvua': [800, 1800], 'mwinuko': [0, 1500], 'ph': [5.5, 7.0], 'emoji': '🥭'},
    'Embe': {'mvua': [600, 1500], 'mwinuko': [0, 1200], 'ph': [5.5, 7.5], 'emoji': '🥭'},
    'Michungwa': {'mvua': [800, 1500], 'mwinuko': [0, 1500], 'ph': [5.5, 7.0], 'emoji': '🍊'},
    'Parachichi': {'mvua': [1000, 1800], 'mwinuko': [800, 2200], 'ph': [5.0, 7.0], 'emoji': '🥑'},
    'Tikiti maji': {'mvua': [400, 800], 'mwinuko': [0, 1500], 'ph': [5.5, 7.5], 'emoji': '🍉'},
    'Matango': {'mvua': [600, 1200], 'mwinuko': [0, 1800], 'ph': [5.5, 7.5], 'emoji': '🥒'},
    'Bamia': {'mvua': [600, 1200], 'mwinuko': [0, 1500], 'ph': [5.8, 7.0], 'emoji': '🌶️'},
    'Karoti': {'mvua': [600, 1200], 'mwinuko': [800, 2400], 'ph': [5.5, 7.0], 'emoji': '🥕'},
    'Bilinganya': {'mvua': [600, 1200], 'mwinuko': [0, 1800], 'ph': [5.5, 7.0], 'emoji': '🍆'},
    'Tangawizi': {'mvua': [1200, 2400], 'mwinuko': [500, 1800], 'ph': [5.5, 6.5], 'emoji': '🫚'},
    'Vanila': {'mvua': [1500, 2400], 'mwinuko': [800, 1800], 'ph': [6.0, 7.0], 'emoji': '🌺'},
    'Kakao': {'mvua': [1200, 2400], 'mwinuko': [0, 1200], 'ph': [5.0, 7.5], 'emoji': '🍫'},
  };

  static String emojiFor(String crop) {
    final e = ecology[crop];
    if (e != null) return e['emoji'] as String;
    // Try partial match
    for (final entry in ecology.entries) {
      if (crop.toLowerCase().contains(entry.key.toLowerCase()) ||
          entry.key.toLowerCase().contains(crop.toLowerCase())) {
        return entry.value['emoji'] as String;
      }
    }
    return '🌱';
  }

  // Overlap fraction of crop requirement range vs district range (0..1)
  static double _overlap(List reqRaw, List? haveRaw) {
    if (haveRaw == null) return 0.5; // unknown district data → neutral
    final req = reqRaw.map((e) => (e as num).toDouble()).toList();
    final have = haveRaw.map((e) => (e as num).toDouble()).toList();
    final lo = req[0] > have[0] ? req[0] : have[0];
    final hi = req[1] < have[1] ? req[1] : have[1];
    if (hi <= lo) return 0;
    final reqSpan = req[1] - req[0];
    if (reqSpan <= 0) return 1;
    final frac = (hi - lo) / reqSpan;
    return frac > 1 ? 1 : frac;
  }

  // ── Suitability score (1-5) for a crop in a district ──────────────────────
  // Components: ecology overlap (rainfall, altitude, pH) + official priority
  // (district/zone crop lists) + planting-season timing.
  static Map<String, dynamic> suitability({
    required String crop,
    required String mkoa,
    required String wilaya,
    int? currentMonth,
  }) {
    final zoneName = KandaData.regionToZone[mkoa];
    final zone = zoneName != null ? KandaData.zones[zoneName] : null;
    final district =
        (KandaData.mikoa[mkoa]?['wilaya'] as Map?)?[wilaya] as Map?;

    final eco = ecology[crop];
    double ecoScore = 0.5;
    final reasons = <String>[];

    if (eco != null && district != null) {
      final mvua = _overlap(eco['mvua'] as List, district['mvua'] as List?);
      final alt = _overlap(eco['mwinuko'] as List, district['mwinuko'] as List?);
      final ph = district.containsKey('ph')
          ? _overlap(eco['ph'] as List, district['ph'] as List?)
          : 0.7;
      ecoScore = (mvua * 0.4) + (alt * 0.4) + (ph * 0.2);
      if (mvua > 0.6) reasons.add('Mvua inafaa');
      if (alt > 0.6) reasons.add('Mwinuko unafaa');
      if (ph > 0.6 && district.containsKey('ph')) reasons.add('pH ya udongo inafaa');
    }

    // Official priority bonus
    double priority = 0;
    bool isDistrictPriority = false;
    bool isZonePriority = false;
    if (district != null) {
      final bia = (district['biashara'] as List?)?.cast<String>() ?? [];
      final cha = (district['chakula'] as List?)?.cast<String>() ?? [];
      final extra = (district['mengine'] as List?)?.cast<String>() ?? [];
      if (bia.any((c) => _same(c, crop)) || cha.any((c) => _same(c, crop))) {
        priority += 1.0;
        isDistrictPriority = true;
        reasons.add('Zao la kipaumbele wilayani');
      } else if (extra.any((c) => _same(c, crop))) {
        priority += 0.5;
      }
    }
    if (zone != null) {
      final food = (zone['foodCrops'] as List).cast<String>();
      final cash = (zone['cashCrops'] as List).cast<String>();
      if (food.any((c) => _same(c, crop)) || cash.any((c) => _same(c, crop))) {
        priority += 0.5;
        isZonePriority = true;
        if (!isDistrictPriority) reasons.add('Zao la kipaumbele kandani');
      }
    }

    // Season timing bonus
    double season = 0;
    if (currentMonth != null) {
      final entry = CropCalendarData.entryFor(crop, mkoa);
      if (entry != null) {
        final planting =
            ((entry['activities'] as Map)['kupanda'] as List?) ?? [];
        if (planting.contains(currentMonth)) {
          season = 0.5;
          reasons.add('Sasa ni msimu wa kupanda');
        } else if (planting.contains(currentMonth % 12 + 1)) {
          season = 0.3;
          reasons.add('Msimu wa kupanda unakaribia');
        }
      }
    }

    // Combine: ecology (0-3) + priority (0-1.5) + season (0-0.5) → 1..5
    double raw = (ecoScore * 3.0) + priority + season;
    if (raw > 5) raw = 5;
    if (raw < 1) raw = 1;

    String badge;
    if (raw >= 4.0) {
      badge = 'INAFAA SANA';
    } else if (raw >= 3.0) {
      badge = 'INAFAA';
    } else {
      badge = 'INAWEZA';
    }

    return {
      'score': double.parse(raw.toStringAsFixed(1)),
      'stars': raw.round().clamp(1, 5),
      'badge': badge,
      'reasons': reasons,
      'isDistrictPriority': isDistrictPriority,
      'isZonePriority': isZonePriority,
      'ecology': eco,
      'zone': zoneName,
    };
  }

  static bool _same(String a, String b) {
    final x = a.toLowerCase().trim();
    final y = b.toLowerCase().trim();
    return x == y || x.contains(y) || y.contains(x);
  }

  // All candidate crops for ranking in a district: union of district priority
  // crops, zone crops and all ecology-known crops with fertilizer data.
  static List<String> candidateCrops(String mkoa, String wilaya) {
    final set = <String>{};
    final district =
        (KandaData.mikoa[mkoa]?['wilaya'] as Map?)?[wilaya] as Map?;
    if (district != null) {
      set.addAll((district['biashara'] as List?)?.cast<String>() ?? []);
      set.addAll((district['chakula'] as List?)?.cast<String>() ?? []);
      set.addAll((district['mengine'] as List?)?.cast<String>() ?? []);
    }
    final zoneName = KandaData.regionToZone[mkoa];
    final zone = zoneName != null ? KandaData.zones[zoneName] : null;
    if (zone != null) {
      set.addAll((zone['foodCrops'] as List).cast<String>());
      set.addAll((zone['cashCrops'] as List).cast<String>());
    }
    // Keep only crops we have ecology or production data for
    final known = set.where((c) =>
        ecology.containsKey(c) || FertilizerData.findCrop(c) != null).toList();
    known.sort();
    return known;
  }

  // Whether a crop is a cash crop in its zone
  static bool isCashCrop(String crop, String mkoa) {
    final zoneName = KandaData.regionToZone[mkoa];
    final zone = zoneName != null ? KandaData.zones[zoneName] : null;
    if (zone == null) return false;
    return (zone['cashCrops'] as List)
        .cast<String>()
        .any((c) => _same(c, crop));
  }

  // Yield record for crop in zone (falls back to Table 9 national values)
  static Map<String, dynamic>? yieldFor(String crop, String? zoneName) {
    if (zoneName != null) {
      final zone = KandaData.zones[zoneName];
      final yields = zone?['yields'] as Map<String, dynamic>?;
      if (yields != null) {
        for (final e in yields.entries) {
          if (_same(e.key, crop)) {
            return Map<String, dynamic>.from(e.value as Map);
          }
        }
      }
    }
    final t9 = FertilizerData.findCrop(crop);
    if (t9 != null) {
      return {
        'sasa': t9['yieldNow'],
        'lengo': t9['yieldPotential'],
        'kipimo': t9['yieldUnit'],
      };
    }
    return null;
  }

  // Current Tanzania season name for a given month
  static String seasonName(int month) {
    if (month >= 3 && month <= 5) return 'Masika';
    if (month >= 10 && month <= 12) return 'Vuli';
    return 'Kiangazi';
  }
}

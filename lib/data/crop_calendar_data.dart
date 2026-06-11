// ─────────────────────────────────────────────────────────────────────────────
// KALENDA YA KILIMO — Official Agricultural Calendar
//
// Chanzo: "Mwongozo wa Uzalishaji Mazao Kulingana na Kanda za Kilimo za
// Kiikolojia" — Wizara ya Kilimo Tanzania, Machi 2022
//
// Months are 1=Jan … 12=Dec. Activity month lists may wrap the year
// (e.g. [12, 1] = Dec-Jan).
// ─────────────────────────────────────────────────────────────────────────────

class CropCalendarData {
  CropCalendarData._();

  static const String source = 'Wizara ya Kilimo Tanzania, 2022';

  // Activity types with display colour + emoji
  static const Map<String, Map<String, dynamic>> activityTypes = {
    'kutayarisha': {
      'jina': 'Kutayarisha Shamba', 'emoji': '🚜', 'color': 0xFF795548,
    },
    'kupanda': {
      'jina': 'Kupanda', 'emoji': '🔴', 'color': 0xFFC62828,
    },
    'palizi': {
      'jina': 'Palizi', 'emoji': '🟡', 'color': 0xFFF9A825,
    },
    'mbolea': {
      'jina': 'Kuweka Mbolea', 'emoji': '🟣', 'color': 0xFF6A1B9A,
    },
    'visumbufu': {
      'jina': 'Kudhibiti Visumbufu', 'emoji': '⬜', 'color': 0xFF757575,
    },
    'kuvuna': {
      'jina': 'Kuvuna', 'emoji': '🟢', 'color': 0xFF2E7D32,
    },
    'kuhifadhi': {
      'jina': 'Kuhifadhi', 'emoji': '🩵', 'color': 0xFF4FC3F7,
    },
    'masoko': {
      'jina': 'Masoko', 'emoji': '🔵', 'color': 0xFF1565C0,
    },
  };

  // Region groups used by the official calendar
  static const List<String> zoneARegions = [
    'Mbeya', 'Ruvuma', 'Iringa', 'Njombe', 'Katavi', 'Rukwa', 'Kigoma',
    'Tabora', 'Lindi', 'Mtwara', 'Singida', 'Dodoma', 'Songwe',
  ];
  static const List<String> zoneBRegions = [
    'Tanga', 'Pwani', 'Kilimanjaro', 'Morogoro', 'Kagera', 'Arusha',
    'Manyara', 'Mara', 'Mwanza', 'Geita', 'Simiyu', 'Shinyanga',
    'Dar es Salaam',
  ];

  // ── CALENDAR ENTRIES ───────────────────────────────────────────────────────
  // Each entry: crop, regions (which regions it applies to), activities map
  // activity → list of months. Months derived from the official calendar;
  // intermediate activities follow the official Mahindi Zone A pattern.
  static const List<Map<String, dynamic>> calendar = [
    // ── MAHINDI ──
    {
      'zao': 'Mahindi', 'kundi': 'Zone A', 'regions': zoneARegions,
      'activities': {
        'kutayarisha': [12, 1],
        'kupanda': [1, 2],
        'palizi': [2, 3],
        'mbolea': [2, 3],
        'visumbufu': [3, 4],
        'kuvuna': [5, 6],
        'kuhifadhi': [6, 7],
        'masoko': [6, 7, 8],
      },
    },
    {
      'zao': 'Mahindi', 'kundi': 'Zone B', 'regions': zoneBRegions,
      'activities': {
        'kutayarisha': [2, 3],
        'kupanda': [3, 4],
        'palizi': [4, 5],
        'mbolea': [4, 5],
        'visumbufu': [5, 6],
        'kuvuna': [7, 8, 9],
        'kuhifadhi': [9, 10],
        'masoko': [9, 10, 11],
      },
    },
    // ── MPUNGA ──
    {
      'zao': 'Mpunga', 'kundi': 'Zone A', 'regions': zoneARegions,
      'activities': {
        'kutayarisha': [12, 1],
        'kupanda': [1, 2],
        'palizi': [2, 3],
        'mbolea': [2, 3],
        'visumbufu': [3, 4],
        'kuvuna': [6, 7],
        'masoko': [7, 8],
      },
    },
    {
      'zao': 'Mpunga', 'kundi': 'Zone B', 'regions': zoneBRegions,
      'activities': {
        'kutayarisha': [3, 4],
        'kupanda': [4, 5],
        'palizi': [5, 6],
        'mbolea': [5, 6],
        'visumbufu': [6, 7],
        'kuvuna': [8, 9, 10],
        'masoko': [10, 11],
      },
    },
    // ── MTAMA ──
    {
      'zao': 'Mtama',
      'regions': [
        'Mwanza', 'Geita', 'Shinyanga', 'Simiyu', 'Mara', 'Tabora',
        'Dodoma', 'Singida'
      ],
      'activities': {
        'kutayarisha': [11, 12],
        'kupanda': [12, 1],
        'palizi': [1, 2],
        'mbolea': [1, 2],
        'visumbufu': [3, 4],
        'kuvuna': [6, 7],
        'masoko': [7, 8],
      },
    },
    // ── ULEZI ──
    {
      'zao': 'Ulezi',
      'regions': [
        'Rukwa', 'Katavi', 'Mbeya', 'Singida', 'Ruvuma', 'Kigoma',
        'Tabora', 'Kilimanjaro'
      ],
      'activities': {
        'kutayarisha': [12],
        'kupanda': [1, 2],
        'palizi': [2, 3],
        'visumbufu': [3, 4],
        'kuvuna': [5, 6],
        'masoko': [6, 7],
      },
    },
    // ── NGANO ──
    {
      'zao': 'Ngano',
      'regions': ['Rukwa', 'Mbeya', 'Ruvuma', 'Manyara', 'Arusha'],
      'activities': {
        'kutayarisha': [12],
        'kupanda': [1, 2, 3],
        'palizi': [3, 4],
        'mbolea': [3, 4],
        'kuvuna': [6, 7],
        'masoko': [7, 8],
      },
    },
    // ── MUHOGO ──
    {
      'zao': 'Muhogo',
      'regions': [
        'Mbeya', 'Tabora', 'Ruvuma', 'Katavi', 'Rukwa', 'Kigoma', 'Lindi',
        'Mtwara', 'Tanga', 'Pwani', 'Mwanza', 'Geita', 'Simiyu',
        'Morogoro', 'Kagera', 'Mara'
      ],
      'maelezo': 'Huvunwa miezi 6-24 baada ya kupanda',
      'activities': {
        'kutayarisha': [10, 11],
        'kupanda': [11, 12, 1, 2],
        'palizi': [1, 2, 3],
        'visumbufu': [3, 4, 5],
        'kuvuna': [6, 7, 8],
        'masoko': [8, 9],
      },
    },
    // ── NDIZI ──
    {
      'zao': 'Ndizi',
      'regions': [
        'Mbeya', 'Mara', 'Kigoma', 'Kagera', 'Morogoro', 'Tanga', 'Rukwa',
        'Katavi', 'Kilimanjaro', 'Arusha', 'Manyara'
      ],
      'maelezo': 'Huzalishwa mwaka mzima; mavuno makuu Jul-Okt',
      'activities': {
        'kupanda': [11, 12, 1, 2, 3],
        'mbolea': [3, 4, 11, 12],
        'kuvuna': [7, 8, 9, 10],
        'masoko': [7, 8, 9, 10, 11],
      },
    },
    // ── MAHARAGE ──
    {
      'zao': 'Maharage', 'kundi': 'Zone A', 'regions': zoneARegions,
      'activities': {
        'kutayarisha': [12],
        'kupanda': [1, 2],
        'palizi': [2, 3],
        'visumbufu': [3, 4],
        'kuvuna': [5, 6],
        'masoko': [6, 7],
      },
    },
    {
      'zao': 'Maharage', 'kundi': 'Zone B', 'regions': zoneBRegions,
      'activities': {
        'kutayarisha': [2],
        'kupanda': [3, 4],
        'palizi': [4, 5],
        'visumbufu': [5, 6],
        'kuvuna': [8, 9],
        'masoko': [9, 10],
      },
    },
    // ── ALIZETI ──
    {
      'zao': 'Alizeti',
      'regions': [
        'Mbeya', 'Ruvuma', 'Iringa', 'Njombe', 'Rukwa', 'Katavi', 'Kigoma',
        'Tabora', 'Lindi', 'Mtwara', 'Singida', 'Dodoma'
      ],
      'activities': {
        'kutayarisha': [12],
        'kupanda': [1, 2],
        'palizi': [2, 3],
        'mbolea': [2, 3],
        'visumbufu': [3, 4],
        'kuvuna': [6, 7],
        'masoko': [7, 8],
      },
    },
    // ── KARANGA ──
    {
      'zao': 'Karanga',
      'regions': [],
      'activities': {
        'kutayarisha': [10, 11],
        'kupanda': [11, 12, 1],
        'palizi': [1, 2],
        'visumbufu': [2, 3],
        'kuvuna': [4, 5, 6],
        'masoko': [6, 7],
      },
    },
    // ── UFUTA ──
    {
      'zao': 'Ufuta',
      'regions': [],
      'activities': {
        'kutayarisha': [12],
        'kupanda': [1, 2],
        'palizi': [2, 3],
        'visumbufu': [3, 4],
        'kuvuna': [5, 6, 7],
        'masoko': [7, 8],
      },
    },
    // ── PAMBA ──
    {
      'zao': 'Pamba', 'kundi': 'Zone A',
      'regions': [
        'Mwanza', 'Geita', 'Simiyu', 'Shinyanga', 'Mara', 'Tabora',
        'Singida', 'Kigoma'
      ],
      'activities': {
        'kutayarisha': [10],
        'kupanda': [11, 12],
        'palizi': [12, 1],
        'mbolea': [12, 1],
        'visumbufu': [1, 2, 3],
        'kuvuna': [6, 7, 8],
        'masoko': [8, 9],
      },
    },
    {
      'zao': 'Pamba', 'kundi': 'Zone B',
      'regions': ['Morogoro', 'Kilimanjaro', 'Tanga', 'Arusha', 'Pwani'],
      'activities': {
        'kutayarisha': [2],
        'kupanda': [3, 4],
        'palizi': [4, 5],
        'mbolea': [4, 5],
        'visumbufu': [5, 6, 7],
        'kuvuna': [8, 9],
        'masoko': [9, 10],
      },
    },
    // ── CHAI ──
    {
      'zao': 'Chai',
      'regions': ['Iringa', 'Njombe', 'Mbeya', 'Tanga', 'Kagera'],
      'maelezo': 'Huvunwa mwaka mzima kila siku 5-7',
      'activities': {
        'kuvuna': [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
        'mbolea': [10, 11],
      },
    },
    // ── KAHAWA ──
    {
      'zao': 'Kahawa',
      'regions': [
        'Arusha', 'Kilimanjaro', 'Tanga', 'Mara', 'Mbeya', 'Iringa',
        'Njombe', 'Ruvuma', 'Morogoro'
      ],
      'maelezo': 'Mavuno makuu Jun-Sep',
      'activities': {
        'mbolea': [10, 11, 3, 4],
        'visumbufu': [1, 2, 3],
        'kuvuna': [6, 7, 8, 9],
        'masoko': [9, 10, 11],
      },
    },
    // ── KOROSHO ──
    {
      'zao': 'Korosho',
      'regions': ['Mtwara', 'Lindi', 'Ruvuma', 'Tanga', 'Morogoro', 'Pwani'],
      'activities': {
        'visumbufu': [6, 7, 8],
        'kuvuna': [9, 10, 11, 12, 1],
        'masoko': [10, 11, 12, 1, 2],
      },
    },
    // ── NYANYA ──
    {
      'zao': 'Nyanya',
      'regions': [],
      'maelezo': 'Mwaka mzima kwa umwagiliaji; kilele Mar-Jun na Sep-Dec',
      'activities': {
        'kupanda': [1, 2, 6, 7],
        'palizi': [2, 3, 7, 8],
        'mbolea': [2, 3, 7, 8],
        'visumbufu': [3, 4, 8, 9],
        'kuvuna': [3, 4, 5, 6, 9, 10, 11, 12],
        'masoko': [3, 4, 5, 6, 9, 10, 11, 12],
      },
    },
    // ── VITUNGUU ──
    {
      'zao': 'Vitunguu',
      'regions': [],
      'maelezo': 'Msimu mkuu Jun-Sep',
      'activities': {
        'kupanda': [3, 4, 5],
        'palizi': [5, 6],
        'mbolea': [5, 6],
        'kuvuna': [6, 7, 8, 9],
        'masoko': [8, 9, 10],
      },
    },
    // ── ZABIBU ──
    {
      'zao': 'Zabibu',
      'regions': ['Dodoma', 'Singida', 'Morogoro'],
      'activities': {
        'kupanda': [10, 11],
        'palizi': [12, 1],
        'mbolea': [12, 1],
        'kuvuna': [2, 3, 4, 5],
        'masoko': [3, 4, 5, 6],
      },
    },
  ];

  // All crops in the calendar
  static List<String> get cropNames =>
      calendar.map((e) => e['zao'] as String).toSet().toList();

  // Find the calendar entry for a crop in a given region.
  // Falls back to the first entry for the crop when no region match exists.
  static Map<String, dynamic>? entryFor(String crop, String region) {
    final entries =
        calendar.where((e) => e['zao'] == crop).toList();
    if (entries.isEmpty) return null;
    for (final e in entries) {
      final regions = (e['regions'] as List).cast<String>();
      if (regions.isEmpty || regions.contains(region)) return e;
    }
    return entries.first;
  }

  // Activities due for a crop+region during a given month (1-12)
  static Map<String, List<String>> activitiesForMonth(
      String crop, String region, int month) {
    final entry = entryFor(crop, region);
    if (entry == null) return {};
    final result = <String, List<String>>{};
    final acts = entry['activities'] as Map<String, dynamic>;
    final due = <String>[];
    acts.forEach((act, months) {
      if ((months as List).contains(month)) due.add(act);
    });
    if (due.isNotEmpty) result[crop] = due;
    return result;
  }
}

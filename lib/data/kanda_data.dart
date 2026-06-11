// ─────────────────────────────────────────────────────────────────────────────
// KANDA ZA KILIMO ZA KIIKOLOJIA — Tanzania Ecological Agriculture Zones
//
// Chanzo: "Mwongozo wa Uzalishaji Mazao Kulingana na Kanda za Kilimo za
// Kiikolojia" — Wizara ya Kilimo Tanzania, Machi 2022
// (signed by Minister Hussein M. Bashe)
// ─────────────────────────────────────────────────────────────────────────────

class KandaData {
  KandaData._();

  static const String source = 'Wizara ya Kilimo Tanzania, 2022';

  // ── 7 ECOLOGICAL ZONES ─────────────────────────────────────────────────────
  // yields: crop → {sasa: current t/ha, lengo: potential t/ha, kipimo: unit}
  static const Map<String, Map<String, dynamic>> zones = {
    'Kanda ya Kati': {
      'jinaEn': 'Central Zone',
      'emoji': '🌻',
      'color': 0xFFA0741B, // brown/gold
      'regions': ['Dodoma', 'Singida'],
      'foodCrops': ['Mtama', 'Uwele', 'Ulezi', 'Muhogo', 'Viazi vitamu'],
      'cashCrops': ['Zabibu', 'Alizeti', 'Karanga', 'Ufuta'],
      'yields': {
        'Alizeti': {'sasa': 1.20, 'lengo': 4.00, 'kipimo': 't/ha'},
        'Karanga': {'sasa': 0.93, 'lengo': 4.50, 'kipimo': 't/ha'},
        'Ufuta': {'sasa': 0.85, 'lengo': 3.00, 'kipimo': 't/ha'},
        'Mahindi': {'sasa': 0.89, 'lengo': 4.00, 'kipimo': 't/ha'},
        'Mpunga': {'sasa': 1.25, 'lengo': 5.00, 'kipimo': 't/ha'},
        'Mtama': {'sasa': 0.99, 'lengo': 5.00, 'kipimo': 't/ha'},
        'Uwele': {'sasa': 0.87, 'lengo': 3.00, 'kipimo': 't/ha'},
        'Ulezi': {'sasa': 1.19, 'lengo': 4.00, 'kipimo': 't/ha'},
        'Muhogo': {'sasa': 3.88, 'lengo': 60.00, 'kipimo': 't/ha'},
        'Viazi vitamu': {'sasa': 2.50, 'lengo': 20.00, 'kipimo': 't/ha'},
      },
    },
    'Kanda ya Ziwa': {
      'jinaEn': 'Lake Zone',
      'emoji': '🌊',
      'color': 0xFF0277BD, // blue
      'regions': ['Geita', 'Kagera', 'Mara', 'Mwanza', 'Shinyanga', 'Simiyu'],
      'foodCrops': [
        'Mpunga', 'Maharage', 'Ndizi', 'Mahindi', 'Mtama', 'Muhogo',
        'Viazi vitamu'
      ],
      'cashCrops': ['Pamba', 'Kahawa', 'Chai', 'Miwa', 'Dengu', 'Mbaazi'],
      'yields': {
        'Mpunga': {'sasa': 3.10, 'lengo': 6.00, 'kipimo': 't/ha'},
        'Ndizi': {'sasa': 4.79, 'lengo': 35.00, 'kipimo': 't/ha'},
        'Dengu': {'sasa': 0.88, 'lengo': 2.00, 'kipimo': 't/ha'},
        'Mahindi': {
          'sasa': 1.38, 'lengo': 4.00, 'kipimo': 't/ha',
          'maelezo': 'Mavuno bora: Kagera, Mara'
        },
        'Pamba': {'sasa': 0.60, 'lengo': 4.00, 'kipimo': 't/ha'},
        'Mtama': {'sasa': 1.28, 'lengo': 3.00, 'kipimo': 't/ha'},
        'Mbaazi': {'sasa': 1.18, 'lengo': 2.50, 'kipimo': 't/ha'},
        'Muhogo': {'sasa': 5.77, 'lengo': 60.00, 'kipimo': 't/ha'},
        'Viazi vitamu': {'sasa': 4.42, 'lengo': 20.00, 'kipimo': 't/ha'},
      },
    },
    'Kanda ya Kaskazini': {
      'jinaEn': 'Northern Zone',
      'emoji': '⛰️',
      'color': 0xFF2E7D32, // green
      'regions': ['Kilimanjaro', 'Arusha', 'Manyara'],
      'foodCrops': [
        'Mahindi', 'Mpunga', 'Ndizi', 'Mtama', 'Maharage',
        'Mazao ya bustani'
      ],
      'cashCrops': ['Kahawa', 'Ngano', 'Shayiri', 'Alizeti', 'Mbaazi', 'Maua'],
      'yields': {
        'Ngano': {'sasa': 1.43, 'lengo': 5.00, 'kipimo': 't/ha'},
        'Shayiri': {'sasa': 1.49, 'lengo': 3.00, 'kipimo': 't/ha'},
        'Alizeti': {'sasa': 1.27, 'lengo': 4.00, 'kipimo': 't/ha'},
        'Mahindi': {'sasa': 1.39, 'lengo': 6.00, 'kipimo': 't/ha'},
        'Kahawa': {'sasa': 0.32, 'lengo': 2.50, 'kipimo': 't/ha'},
        'Mbaazi': {'sasa': 0.93, 'lengo': 2.50, 'kipimo': 't/ha'},
        'Mpunga': {'sasa': 3.23, 'lengo': 6.00, 'kipimo': 't/ha'},
        'Ndizi': {'sasa': 7.34, 'lengo': 35.00, 'kipimo': 't/ha'},
      },
    },
    'Kanda ya Mashariki': {
      'jinaEn': 'Eastern Zone',
      'emoji': '🌴',
      'color': 0xFF00897B, // teal
      'regions': ['Morogoro', 'Pwani', 'Dar es Salaam', 'Tanga'],
      'foodCrops': [
        'Muhogo', 'Magimbi', 'Viazi vitamu', 'Mpunga', 'Mahindi',
        'Mbegu za mafuta'
      ],
      'cashCrops': [
        'Mkonge', 'Korosho', 'Miwa', 'Nazi', 'Machungwa', 'Embe',
        'Mbogamboga', 'Viungo', 'Vikolezo'
      ],
      'yields': {
        'Mpunga': {
          'sasa': 1.71, 'lengo': 6.00, 'kipimo': 't/ha',
          'kipaumbele': true
        },
        'Ufuta': {
          'sasa': 1.49, 'lengo': 2.50, 'kipimo': 't/ha',
          'kipaumbele': true
        },
        'Alizeti': {
          'sasa': 1.21, 'lengo': 4.00, 'kipimo': 't/ha',
          'kipaumbele': true
        },
        'Mahindi': {
          'sasa': 1.14, 'lengo': 6.00, 'kipimo': 't/ha',
          'kipaumbele': true
        },
        'Muhogo': {
          'sasa': 6.48, 'lengo': 60.00, 'kipimo': 't/ha',
          'kipaumbele': true
        },
        'Viazi vitamu': {
          'sasa': 5.23, 'lengo': 20.00, 'kipimo': 't/ha',
          'kipaumbele': true
        },
      },
    },
    'Kanda ya Magharibi': {
      'jinaEn': 'Western Zone',
      'emoji': '🌅',
      'color': 0xFFEF6C00, // orange
      'regions': ['Tabora', 'Kigoma'],
      'foodCrops': [
        'Mahindi', 'Muhogo', 'Viazi vitamu', 'Ndizi', 'Mikunde', 'Mpunga'
      ],
      'cashCrops': ['Kahawa', 'Tumbaku', 'Michikichi', 'Pamba', 'Tangawizi'],
      'yields': {
        'Muhogo': {'sasa': 5.74, 'lengo': 60.00, 'kipimo': 't/ha'},
        'Ndizi': {'sasa': 5.92, 'lengo': 35.00, 'kipimo': 't/ha'},
        'Mpunga': {'sasa': 2.60, 'lengo': 5.00, 'kipimo': 't/ha'},
        'Mahindi': {'sasa': 1.38, 'lengo': 6.00, 'kipimo': 't/ha'},
        'Karanga': {'sasa': 0.99, 'lengo': 4.50, 'kipimo': 't/ha'},
        'Mbaazi': {'sasa': 0.79, 'lengo': 2.50, 'kipimo': 't/ha'},
        'Kahawa': {'sasa': 0.39, 'lengo': 2.50, 'kipimo': 't/ha'},
        'Pamba': {'sasa': 0.47, 'lengo': 4.00, 'kipimo': 't/ha'},
        'Tumbaku': {'sasa': 1.26, 'lengo': 3.50, 'kipimo': 't/ha'},
        'Viazi vitamu': {'sasa': 4.88, 'lengo': 20.00, 'kipimo': 't/ha'},
      },
    },
    'Kanda ya Nyanda za Juu Kusini': {
      'jinaEn': 'Southern Highlands',
      'emoji': '🏔️',
      'color': 0xFF6A1B9A, // purple
      'regions': [
        'Iringa', 'Katavi', 'Mbeya', 'Njombe', 'Rukwa', 'Ruvuma', 'Songwe'
      ],
      'foodCrops': [
        'Mahindi', 'Mpunga', 'Maharage', 'Ngano', 'Viazi mviringo',
        'Muhogo', 'Mazao ya bustani'
      ],
      'cashCrops': ['Chai', 'Kahawa', 'Tumbaku', 'Pareto', 'Alizeti', 'Maua'],
      'yields': {
        'Muhogo': {'sasa': 5.96, 'lengo': 60.00, 'kipimo': 't/ha'},
        'Viazi mviringo': {'sasa': 7.29, 'lengo': 30.00, 'kipimo': 't/ha'},
        'Mpunga': {'sasa': 2.73, 'lengo': 5.00, 'kipimo': 't/ha'},
        'Mahindi': {'sasa': 1.76, 'lengo': 6.00, 'kipimo': 't/ha'},
        'Ngano': {'sasa': 0.81, 'lengo': 5.00, 'kipimo': 't/ha'},
        'Alizeti': {'sasa': 1.50, 'lengo': 4.00, 'kipimo': 't/ha'},
        'Tumbaku': {'sasa': 0.92, 'lengo': 3.50, 'kipimo': 't/ha'},
      },
    },
    'Kanda ya Kusini': {
      'jinaEn': 'Southern Zone',
      'emoji': '🥜',
      'color': 0xFFC62828, // red
      'regions': ['Mtwara', 'Lindi'],
      'maelezo': 'Pamoja na Wilaya ya Tunduru (Ruvuma)',
      'foodCrops': ['Muhogo', 'Mikunde ya jamii'],
      'cashCrops': [
        'Korosho', 'Nazi', 'Ufuta', 'Alizeti', 'Karanga',
        'Mazao ya bustani'
      ],
      'yields': {
        'Muhogo': {'sasa': 5.25, 'lengo': 60.00, 'kipimo': 't/ha'},
        'Mbaazi': {'sasa': 0.97, 'lengo': 2.50, 'kipimo': 't/ha'},
        'Mpunga': {'sasa': 1.30, 'lengo': 5.00, 'kipimo': 't/ha'},
        'Ufuta': {'sasa': 1.20, 'lengo': 2.50, 'kipimo': 't/ha'},
        'Alizeti': {'sasa': 1.00, 'lengo': 4.00, 'kipimo': 't/ha'},
        'Karanga': {'sasa': 1.35, 'lengo': 4.50, 'kipimo': 't/ha'},
        'Korosho': {'sasa': 8.0, 'lengo': 30.0, 'kipimo': 'kg/mti'},
      },
    },
  };

  // ── REGION → ZONE MAPPING ──────────────────────────────────────────────────
  static const Map<String, String> regionToZone = {
    'Dodoma': 'Kanda ya Kati',
    'Singida': 'Kanda ya Kati',
    'Geita': 'Kanda ya Ziwa',
    'Kagera': 'Kanda ya Ziwa',
    'Mara': 'Kanda ya Ziwa',
    'Mwanza': 'Kanda ya Ziwa',
    'Shinyanga': 'Kanda ya Ziwa',
    'Simiyu': 'Kanda ya Ziwa',
    'Kilimanjaro': 'Kanda ya Kaskazini',
    'Arusha': 'Kanda ya Kaskazini',
    'Manyara': 'Kanda ya Kaskazini',
    'Morogoro': 'Kanda ya Mashariki',
    'Pwani': 'Kanda ya Mashariki',
    'Dar es Salaam': 'Kanda ya Mashariki',
    'Tanga': 'Kanda ya Mashariki',
    'Tabora': 'Kanda ya Magharibi',
    'Kigoma': 'Kanda ya Magharibi',
    'Iringa': 'Kanda ya Nyanda za Juu Kusini',
    'Katavi': 'Kanda ya Nyanda za Juu Kusini',
    'Mbeya': 'Kanda ya Nyanda za Juu Kusini',
    'Njombe': 'Kanda ya Nyanda za Juu Kusini',
    'Rukwa': 'Kanda ya Nyanda za Juu Kusini',
    'Ruvuma': 'Kanda ya Nyanda za Juu Kusini',
    'Songwe': 'Kanda ya Nyanda za Juu Kusini',
    'Mtwara': 'Kanda ya Kusini',
    'Lindi': 'Kanda ya Kusini',
  };

  // ── REGION GPS BOUNDING BOXES ──────────────────────────────────────────────
  // Order matters: more specific/smaller regions are listed first so that the
  // first match wins when boxes overlap.
  static const List<Map<String, dynamic>> regionBounds = [
    {'name': 'Dar es Salaam', 'latMin': -7.1, 'latMax': -6.5, 'lngMin': 39.0, 'lngMax': 39.6},
    {'name': 'Kilimanjaro', 'latMin': -4.3, 'latMax': -2.8, 'lngMin': 36.9, 'lngMax': 38.2},
    {'name': 'Songwe', 'latMin': -9.6, 'latMax': -7.9, 'lngMin': 31.8, 'lngMax': 33.2},
    {'name': 'Njombe', 'latMin': -10.5, 'latMax': -8.2, 'lngMin': 33.8, 'lngMax': 35.8},
    {'name': 'Mtwara', 'latMin': -11.2, 'latMax': -10.0, 'lngMin': 38.0, 'lngMax': 40.5},
    {'name': 'Lindi', 'latMin': -10.5, 'latMax': -8.0, 'lngMin': 37.5, 'lngMax': 40.0},
    {'name': 'Simiyu', 'latMin': -3.8, 'latMax': -2.0, 'lngMin': 33.5, 'lngMax': 35.2},
    {'name': 'Geita', 'latMin': -3.6, 'latMax': -2.5, 'lngMin': 31.0, 'lngMax': 33.0},
    {'name': 'Mwanza', 'latMin': -3.3, 'latMax': -1.8, 'lngMin': 32.0, 'lngMax': 34.0},
    {'name': 'Mara', 'latMin': -2.6, 'latMax': -1.0, 'lngMin': 33.3, 'lngMax': 35.5},
    {'name': 'Kagera', 'latMin': -3.0, 'latMax': -1.0, 'lngMin': 30.3, 'lngMax': 32.2},
    {'name': 'Shinyanga', 'latMin': -4.3, 'latMax': -3.0, 'lngMin': 31.5, 'lngMax': 34.0},
    {'name': 'Katavi', 'latMin': -7.6, 'latMax': -5.5, 'lngMin': 30.3, 'lngMax': 32.4},
    {'name': 'Rukwa', 'latMin': -9.0, 'latMax': -6.9, 'lngMin': 30.2, 'lngMax': 32.5},
    {'name': 'Kigoma', 'latMin': -6.5, 'latMax': -3.5, 'lngMin': 29.3, 'lngMax': 31.5},
    {'name': 'Mbeya', 'latMin': -9.7, 'latMax': -7.7, 'lngMin': 32.2, 'lngMax': 34.4},
    {'name': 'Ruvuma', 'latMin': -11.7, 'latMax': -9.4, 'lngMin': 34.4, 'lngMax': 38.5},
    {'name': 'Iringa', 'latMin': -8.7, 'latMax': -6.8, 'lngMin': 33.8, 'lngMax': 36.5},
    {'name': 'Manyara', 'latMin': -5.5, 'latMax': -3.5, 'lngMin': 35.0, 'lngMax': 37.5},
    {'name': 'Arusha', 'latMin': -4.0, 'latMax': -2.0, 'lngMin': 35.0, 'lngMax': 37.0},
    {'name': 'Singida', 'latMin': -7.5, 'latMax': -3.8, 'lngMin': 33.5, 'lngMax': 35.5},
    {'name': 'Dodoma', 'latMin': -7.5, 'latMax': -4.8, 'lngMin': 35.0, 'lngMax': 37.0},
    {'name': 'Tabora', 'latMin': -7.3, 'latMax': -3.9, 'lngMin': 31.0, 'lngMax': 34.2},
    {'name': 'Tanga', 'latMin': -6.0, 'latMax': -4.0, 'lngMin': 37.4, 'lngMax': 39.3},
    {'name': 'Pwani', 'latMin': -8.2, 'latMax': -6.0, 'lngMin': 38.0, 'lngMax': 39.8},
    {'name': 'Morogoro', 'latMin': -10.0, 'latMax': -5.8, 'lngMin': 35.5, 'lngMax': 38.5},
  ];

  // ── TABLE 8: CROPS BY REGION AND DISTRICT ──────────────────────────────────
  // Each wilaya entry: biashara, chakula, mwinuko [m], mvua [mm], joto [°C],
  // ph (optional), udongo (optional), mengine (optional)
  static const Map<String, Map<String, dynamic>> mikoa = {
    'Arusha': {
      'wilaya': {
        'Arusha': {
          'biashara': ['Kahawa', 'Maua'],
          'chakula': ['Mahindi', 'Maharage', 'Ndizi', 'Viazi mviringo'],
          'mwinuko': [500, 1700], 'mvua': [800, 1200], 'joto': [15, 30],
          'ph': [5.0, 8.5], 'udongo': 'Tifutifu, kichanga, calcium',
          'mengine': ['Mazao ya bustani', 'Alizeti', 'Ufuta', 'Mikunde'],
        },
        'Karatu': {
          'biashara': ['Kahawa', 'Shayiri', 'Vitunguu maji'],
          'chakula': ['Mahindi', 'Maharage'],
          'mwinuko': [900, 2500], 'mvua': [200, 1400], 'joto': [10, 30],
          'ph': [4.0, 8.5],
        },
        'Longido': {
          'biashara': ['Ndizi', 'Vitunguu saumu'],
          'chakula': ['Mahindi', 'Maharage', 'Mtama'],
          'mwinuko': [500, 1700], 'mvua': [400, 1300], 'joto': [10, 30],
          'ph': [6.5, 8.5],
        },
        'Monduli': {
          'biashara': ['Kahawa', 'Ndizi', 'Vitunguu saumu', 'Mazao ya bustani'],
          'chakula': ['Mahindi', 'Mbaazi'],
          'mwinuko': [500, 2500], 'mvua': [200, 1400], 'joto': [5, 30],
          'ph': [5.0, 8.5],
        },
        'Ngorongoro': {
          'biashara': ['Mazao ya bustani'],
          'chakula': ['Mahindi', 'Mtama'],
          'mwinuko': [900, 2500], 'mvua': [400, 1400], 'joto': [5, 30],
          'ph': [4.5, 8.5],
        },
      },
    },
    'Dar es Salaam': {
      'wilaya': {
        'Ilala': _dsm, 'Kinondoni': _dsm, 'Temeke': _dsm,
      },
    },
    'Dodoma': {
      'wilaya': {
        'Bahi': _dodoma, 'Chamwino': _dodoma, 'Chemba': _dodoma,
        'Dodoma': _dodoma, 'Kondoa': _dodoma, 'Mpwapwa': _dodoma,
        'Kongwa': _dodoma,
      },
    },
    'Geita': {
      'wilaya': {
        'Bukombe': _geita, 'Chato': _geita, 'Geita': _geita,
        'Mbogwe': _geita, "Nyang'hwale": _geita,
      },
    },
    'Iringa': {
      'wilaya': {
        'Iringa': {
          'biashara': ['Alizeti', 'Vitunguu', 'Nyanya'],
          'chakula': ['Mahindi', 'Maharage'],
          'mwinuko': [400, 2300], 'mvua': [200, 1600], 'joto': [5, 27],
          'udongo': 'Kichanga, tifutifu, mfinyanzi',
        },
        'Kilolo': _kilolo,
        'Mufindi': _kilolo,
      },
    },
    'Kagera': {
      'wilaya': {
        'Biharamulo': _kagera, 'Bukoba': _kagera, 'Karagwe': _kagera,
        'Kyerwa': _kagera, 'Misenyi': _kagera, 'Muleba': _kagera,
        'Ngara': _kagera,
      },
    },
    'Katavi': {
      'wilaya': {
        'Mlele': _katavi, 'Tanganyika': _katavi, 'Mpanda': _katavi,
        'Mpimbwe': _katavi,
      },
    },
    'Kigoma': {
      'wilaya': {
        'Buhigwe': _kigoma, 'Kakonko': _kigoma, 'Kasulu': _kigoma,
        'Kibondo': _kigoma, 'Kigoma': _kigoma, 'Uvinza': _kigoma,
      },
    },
    'Kilimanjaro': {
      'wilaya': {
        'Hai': _kilimanjaro, 'Moshi': _kilimanjaro, 'Mwanga': _kilimanjaro,
        'Rombo': _kilimanjaro, 'Same': _kilimanjaro, 'Siha': _kilimanjaro,
      },
    },
    'Lindi': {
      'wilaya': {
        'Kilwa': _lindi, 'Lindi': _lindi, 'Liwale': _lindi,
        'Nachingwea': _lindi, 'Ruangwa': _lindi,
      },
    },
    'Manyara': {
      'wilaya': {
        'Babati': _manyara, 'Hanang': _manyara, 'Kiteto': _manyara,
        'Mbulu': _manyara, 'Simanjiro': _manyara,
      },
    },
    'Mara': {
      'wilaya': {
        'Bunda': _mara, 'Butiama': _mara, 'Musoma': _mara, 'Rorya': _mara,
        'Serengeti': _mara, 'Tarime': _mara,
      },
    },
    'Mbeya': {
      'wilaya': {
        'Busekelo': _mbeya, 'Chunya': _mbeya, 'Kyela': _mbeya,
        'Mbarali': _mbeya, 'Mbeya': _mbeya, 'Rungwe': _mbeya,
      },
    },
    'Morogoro': {
      'wilaya': {
        'Gairo': _morogoroW, 'Ifakara': _kilombero, 'Kilombero': _kilombero,
        'Kilosa': {
          'biashara': ['Mkonge', 'Mpunga', 'Korosho'],
          'chakula': ['Mahindi', 'Mikunde'],
          'mwinuko': [200, 2300], 'mvua': [800, 1600], 'joto': [15, 30],
          'ph': [4.0, 7.0],
          'udongo': 'Tifutifu, kichanga, mfinyanzi mweusi',
        },
        'Malinyi': _kilombero, 'Morogoro': _morogoroW,
        'Mvomero': _morogoroW, 'Ulanga': _kilombero,
      },
    },
    'Mtwara': {
      'wilaya': {
        'Masasi': _mtwara, 'Mtwara': _mtwara, 'Nanyamba': _mtwara,
        'Nanyumbu': _mtwara, 'Newala': _mtwara, 'Tandahimba': _mtwara,
      },
    },
    'Mwanza': {
      'wilaya': {
        'Buchosa': _mwanza, 'Ilemela': _mwanza, 'Kwimba': _mwanza,
        'Magu': _mwanza, 'Misungwi': _mwanza, 'Mwanza': _mwanza,
        'Sengerema': _mwanza, 'Ukerewe': _mwanza,
      },
    },
    'Njombe': {
      'wilaya': {
        'Ludewa': _njombe, 'Makete': _njombe, 'Njombe': _njombe,
        "Wanging'ombe": _njombe,
      },
    },
    'Pwani': {
      'wilaya': {
        'Bagamoyo': _pwani, 'Chalinze': _pwani, 'Kibaha': _pwani,
        'Kisarawe': _pwani, 'Mafia': _pwani, 'Mkuranga': _pwani,
        'Rufiji': _pwani,
      },
    },
    'Rukwa': {
      'wilaya': {
        'Kalambo': _rukwa, 'Nkasi': _rukwa, 'Sumbawanga': _rukwa,
      },
    },
    'Ruvuma': {
      'wilaya': {
        'Madaba': _ruvuma, 'Mbinga': _ruvuma, 'Namtumbo': _ruvuma,
        'Nyasa': _ruvuma, 'Songea': _ruvuma, 'Tunduru': _ruvuma,
      },
    },
    'Shinyanga': {
      'wilaya': {
        'Kahama': _shinyanga, 'Kishapu': _shinyanga, 'Msalala': _shinyanga,
        'Shinyanga': _shinyanga, 'Ushetu': _shinyanga,
      },
    },
    'Simiyu': {
      'wilaya': {
        'Bariadi': _simiyu, 'Busega': _simiyu, 'Itilima': _simiyu,
        'Maswa': _simiyu, 'Meatu': _simiyu,
      },
    },
    'Singida': {
      'wilaya': {
        'Ikungi': _singida, 'Iramba': _singida, 'Itigi': _singida,
        'Manyoni': _singida, 'Mkalama': _singida, 'Singida': _singida,
      },
    },
    'Songwe': {
      'wilaya': {
        'Ileje': _songwe, 'Mbozi': _songwe, 'Momba': _songwe,
      },
    },
    'Tabora': {
      'wilaya': {
        'Igunga': _tabora, 'Kaliua': _tabora, 'Nzega': _tabora,
        'Sikonge': _tabora, 'Tabora': _tabora, 'Urambo': _tabora,
      },
    },
    'Tanga': {
      'wilaya': {
        'Bumbuli': _tanga, 'Handeni': _tanga, 'Kilindi': _tanga,
        'Korogwe': _tanga, 'Lushoto': _tanga, 'Mkinga': _tanga,
        'Muheza': _tanga, 'Pangani': _tanga, 'Tanga': _tanga,
      },
    },
  };
}

// ── Region-level Table 8 data (shared by all districts in the region) ────────

const Map<String, dynamic> _dsm = {
  'biashara': ['Tikiti maji', 'Maembe', 'Muhogo'],
  'chakula': ['Muhogo', 'Viazi vitamu'],
  'mwinuko': [0, 500], 'mvua': [800, 1200], 'joto': [25, 35],
  'ph': [5.0, 7.0], 'udongo': 'Kichanga, chumvi, tifutifu, mfinyanzi',
};

const Map<String, dynamic> _dodoma = {
  'biashara': ['Zabibu', 'Ufuta', 'Alizeti', 'Karanga'],
  'chakula': ['Mtama', 'Uwele', 'Muhogo', 'Njugu mawe'],
  'mwinuko': [500, 2300], 'mvua': [200, 1000], 'joto': [15, 30],
  'udongo': 'Mwekundu, kichanga, tifutifu',
};

const Map<String, dynamic> _geita = {
  'biashara': ['Pamba'],
  'chakula': ['Mahindi', 'Muhogo'],
  'mwinuko': [900, 1800], 'mvua': [600, 1400], 'joto': [10, 30],
  'ph': [4.0, 8.5],
};

const Map<String, dynamic> _kilolo = {
  'biashara': ['Chai', 'Pareto'],
  'chakula': ['Mahindi', 'Maharage', 'Viazi mviringo'],
  'mwinuko': [400, 2300], 'mvua': [600, 1600], 'joto': [2, 30],
  'ph': [4.0, 7.0],
};

const Map<String, dynamic> _kagera = {
  'biashara': ['Kahawa', 'Ndizi', 'Vanila', 'Chai'],
  'chakula': ['Ndizi', 'Mikunde', 'Mahindi'],
  'mwinuko': [1100, 1800], 'mvua': [600, 1400], 'joto': [10, 30],
  'ph': [4.0, 7.0], 'udongo': 'Mchanganyiko, tifutifu, kichanga',
};

const Map<String, dynamic> _katavi = {
  'biashara': ['Tumbaku', 'Karanga', 'Ufuta', 'Mchikichi'],
  'chakula': ['Mpunga', 'Viazi vitamu', 'Mahindi', 'Maharage'],
  'mwinuko': [800, 2300], 'mvua': [600, 1400], 'joto': [10, 30],
  'ph': [5.0, 7.0],
};

const Map<String, dynamic> _kigoma = {
  'biashara': ['Kahawa', 'Michikichi', 'Tangawizi', 'Tumbaku'],
  'chakula': ['Mahindi', 'Mikunde', 'Ndizi', 'Muhogo', 'Mpunga'],
  'mwinuko': [800, 1700], 'mvua': [600, 1200], 'joto': [18, 30],
  'ph': [5.0, 7.0],
};

const Map<String, dynamic> _kilimanjaro = {
  'biashara': ['Kahawa', 'Mazao ya bustani', 'Ngano', 'Maua'],
  'chakula': ['Mahindi', 'Maharage', 'Ndizi', 'Mpunga'],
  'mwinuko': [500, 3500], 'mvua': [400, 1400], 'joto': [5, 31],
  'ph': [5.0, 8.5], 'udongo': 'Volcano, kichanga, tifutifu',
};

const Map<String, dynamic> _lindi = {
  'biashara': ['Ufuta', 'Korosho', 'Nazi'],
  'chakula': ['Muhogo', 'Mpunga', 'Mtama', 'Viazi vitamu'],
  'mwinuko': [200, 1000], 'mvua': [800, 1200], 'joto': [20, 28],
  'ph': [5.5, 7.0], 'udongo': 'Tifutifu, mchanga, mfinyanzi',
};

const Map<String, dynamic> _manyara = {
  'biashara': ['Mbaazi', 'Alizeti', 'Ngano', 'Shayiri'],
  'chakula': ['Mahindi', 'Mpunga', 'Maharage', 'Mikunde'],
  'mwinuko': [700, 2500], 'mvua': [200, 1400], 'joto': [10, 28],
};

const Map<String, dynamic> _mara = {
  'biashara': ['Pamba', 'Mpunga', 'Chai', 'Kahawa'],
  'chakula': ['Mtama', 'Muhogo', 'Ulezi', 'Mahindi'],
  'mwinuko': [1000, 2300], 'mvua': [400, 1600], 'joto': [10, 30],
  'ph': [4.0, 8.5],
};

const Map<String, dynamic> _mbeya = {
  'biashara': ['Chai', 'Kakao', 'Kahawa', 'Mpunga', 'Alizeti'],
  'chakula': ['Mahindi', 'Maharage', 'Viazi mviringo', 'Ndizi'],
  'mwinuko': [500, 2700], 'mvua': [200, 2400], 'joto': [5, 30],
  'ph': [4.0, 7.0],
};

const Map<String, dynamic> _morogoroW = {
  'biashara': ['Mkonge', 'Miwa', 'Mazao ya bustani', 'Viungo'],
  'chakula': ['Muhogo', 'Mahindi', 'Mikunde'],
  'mwinuko': [200, 2300], 'mvua': [800, 1600], 'joto': [15, 30],
  'ph': [4.0, 7.0],
};

const Map<String, dynamic> _kilombero = {
  'biashara': ['Miwa', 'Mpunga', 'Kakao'],
  'chakula': ['Mpunga', 'Mikunde'],
  'mwinuko': [200, 2300], 'mvua': [800, 1600], 'joto': [15, 30],
  'ph': [4.0, 7.0],
};

const Map<String, dynamic> _mtwara = {
  'biashara': ['Korosho', 'Ufuta', 'Choroko', 'Soya'],
  'chakula': ['Muhogo', 'Mbaazi', 'Mpunga', 'Mtama'],
  'mwinuko': [0, 500], 'mvua': [800, 1000], 'joto': [12, 35],
  'ph': [5.0, 7.0],
};

const Map<String, dynamic> _mwanza = {
  'biashara': ['Pamba', 'Mpunga', 'Dengu', 'Choroko', 'Kahawa'],
  'chakula': ['Mpunga', 'Mahindi', 'Muhogo', 'Mtama'],
  'mwinuko': [800, 1800], 'mvua': [600, 1400], 'joto': [10, 30],
  'ph': [5.0, 7.0],
};

const Map<String, dynamic> _njombe = {
  'biashara': ['Chai', 'Pareto', 'Viazi mviringo', 'Alizeti'],
  'chakula': ['Mahindi', 'Mpunga', 'Maharage', 'Ngano'],
  'mwinuko': [500, 2700], 'mvua': [600, 2000], 'joto': [1, 25],
  'ph': [4.0, 7.0],
};

const Map<String, dynamic> _pwani = {
  'biashara': ['Korosho', 'Nanasi', 'Miwa', 'Nazi', 'Ufuta'],
  'chakula': ['Muhogo', 'Mtama', 'Mpunga', 'Mahindi'],
  'mwinuko': [0, 1000], 'mvua': [800, 1400], 'joto': [19, 31],
  'ph': [5.0, 7.0],
};

const Map<String, dynamic> _rukwa = {
  'biashara': ['Mahindi', 'Alizeti', 'Ngano', 'Viazi mviringo'],
  'chakula': ['Mahindi', 'Maharage', 'Mpunga'],
  'mwinuko': [800, 2300], 'mvua': [1000, 1400], 'joto': [10, 30],
  'ph': [5.0, 7.0],
};

const Map<String, dynamic> _ruvuma = {
  'biashara': ['Kahawa', 'Soya', 'Alizeti', 'Korosho', 'Ufuta'],
  'chakula': ['Mahindi', 'Maharage', 'Mtama', 'Mikunde'],
  'mwinuko': [300, 2300], 'mvua': [500, 1600], 'joto': [5, 35],
  'ph': [4.0, 7.0],
};

const Map<String, dynamic> _shinyanga = {
  'biashara': ['Pamba', 'Mpunga', 'Alizeti', 'Dengu', 'Choroko'],
  'chakula': ['Mahindi', 'Mtama', 'Viazi vitamu', 'Uwele'],
  'mwinuko': [900, 1300], 'mvua': [300, 1000], 'joto': [15, 30],
  'ph': [5.0, 9.0],
};

const Map<String, dynamic> _simiyu = {
  'biashara': ['Pamba', 'Dengu', 'Choroko', 'Mikunde'],
  'chakula': ['Mahindi', 'Mtama', 'Mpunga', 'Uwele'],
  'mwinuko': [900, 2500], 'mvua': [600, 1400], 'joto': [10, 30],
  'ph': [4.5, 9.0],
};

const Map<String, dynamic> _singida = {
  'biashara': ['Alizeti', 'Vitunguu', 'Tumbaku', 'Karanga'],
  'chakula': ['Mtama', 'Mahindi', 'Uwele', 'Muhogo'],
  'mwinuko': [900, 2500], 'mvua': [200, 1200], 'joto': [10, 30],
  'ph': [4.0, 9.0],
};

const Map<String, dynamic> _songwe = {
  'biashara': ['Kakao', 'Kahawa', 'Parachichi', 'Alizeti'],
  'chakula': ['Mahindi', 'Maharage', 'Mpunga'],
  'mwinuko': [500, 2400], 'mvua': [1000, 2400], 'joto': [5, 25],
  'ph': [4.0, 8.0],
};

const Map<String, dynamic> _tabora = {
  'biashara': ['Pamba', 'Tumbaku', 'Alizeti'],
  'chakula': ['Mpunga', 'Mahindi', 'Mtama'],
  'mwinuko': [800, 1800], 'mvua': [200, 1400], 'joto': [15, 30],
  'ph': [4.0, 9.0],
};

const Map<String, dynamic> _tanga = {
  'biashara': ['Chai', 'Mkonge', 'Matunda', 'Viungo', 'Mazao ya bustani'],
  'chakula': ['Mahindi', 'Muhogo', 'Maharage', 'Ndizi'],
  'mwinuko': [0, 2000], 'mvua': [400, 1400], 'joto': [10, 31],
  'ph': [4.0, 8.5],
};

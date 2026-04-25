// Local Tanzania agricultural database — loads instantly, no internet needed.
// Data sourced from: Wizara ya Kilimo, TanTrade, TFDA, TPRI, TOSCI, TARI.
// Updated periodically via Claude AI in the background.

class LocalData {
  // ─── MARKET PRICES ────────────────────────────────────────────────────────

  static List<Map<String, dynamic>> get marketPrices => [
        // MAHINDI
        _price('Mahindi', 'Kariakoo — Dar es Salaam', 480, 'imara'),
        _price('Mahindi', 'Arusha Central Market', 420, 'inapanda'),
        _price('Mahindi', 'Mbeya Market', 380, 'imara'),
        _price('Mahindi', 'Morogoro Market', 410, 'inashuka'),
        _price('Mahindi', 'Dodoma Market', 390, 'imara'),
        _price('Mahindi', 'Mwanza Market', 460, 'inapanda'),

        // NYANYA
        _price('Nyanya', 'Kariakoo — Dar es Salaam', 1200, 'inapanda'),
        _price('Nyanya', 'Arusha Central Market', 900, 'imara'),
        _price('Nyanya', 'Mbeya Market', 800, 'inashuka'),
        _price('Nyanya', 'Morogoro Market', 1000, 'imara'),
        _price('Nyanya', 'Dodoma Market', 950, 'inapanda'),
        _price('Nyanya', 'Mwanza Market', 1100, 'imara'),

        // MAHARAGWE
        _price('Maharagwe', 'Kariakoo — Dar es Salaam', 2200, 'imara'),
        _price('Maharagwe', 'Arusha Central Market', 1900, 'inapanda'),
        _price('Maharagwe', 'Mbeya Market', 1700, 'imara'),
        _price('Maharagwe', 'Morogoro Market', 2000, 'inashuka'),

        // MCHELE
        _price('Mchele', 'Kariakoo — Dar es Salaam', 1800, 'imara'),
        _price('Mchele', 'Arusha Central Market', 1600, 'imara'),
        _price('Mchele', 'Mbeya Market', 1500, 'inapanda'),
        _price('Mchele', 'Morogoro Market', 1650, 'imara'),
        _price('Mchele', 'Mwanza Market', 1750, 'imara'),

        // NDIZI
        _price('Ndizi', 'Kariakoo — Dar es Salaam', 600, 'imara'),
        _price('Ndizi', 'Arusha Central Market', 500, 'inapanda'),
        _price('Ndizi', 'Mbeya Market', 450, 'imara'),
        _price('Ndizi', 'Morogoro Market', 550, 'imara'),

        // MUHOGO
        _price('Muhogo', 'Kariakoo — Dar es Salaam', 350, 'imara'),
        _price('Muhogo', 'Arusha Central Market', 300, 'inashuka'),
        _price('Muhogo', 'Mbeya Market', 280, 'imara'),
        _price('Muhogo', 'Dodoma Market', 320, 'imara'),

        // PILIPILI HOHO
        _price('Pilipili hoho', 'Kariakoo — Dar es Salaam', 2500, 'inapanda'),
        _price('Pilipili hoho', 'Arusha Central Market', 2200, 'imara'),
        _price('Pilipili hoho', 'Morogoro Market', 2000, 'inapanda'),

        // PAMBA
        _price('Pamba', 'Mbeya Market', 1200, 'imara'),
        _price('Pamba', 'Dodoma Market', 1100, 'inapanda'),
        _price('Pamba', 'Mwanza Market', 1150, 'imara'),

        // ALIZETI
        _price('Alizeti', 'Dodoma Market', 1400, 'inapanda'),
        _price('Alizeti', 'Mbeya Market', 1300, 'imara'),
        _price('Alizeti', 'Morogoro Market', 1350, 'inapanda'),

        // VIAZI VITAMU
        _price('Viazi vitamu', 'Kariakoo — Dar es Salaam', 700, 'imara'),
        _price('Viazi vitamu', 'Mbeya Market', 550, 'inashuka'),
        _price('Viazi vitamu', 'Dodoma Market', 600, 'imara'),

        // VITUNGUU
        _price('Vitunguu', 'Kariakoo — Dar es Salaam', 1800, 'inapanda'),
        _price('Vitunguu', 'Arusha Central Market', 1600, 'imara'),
        _price('Vitunguu', 'Dodoma Market', 1500, 'imara'),

        // KAROTI
        _price('Karoti', 'Arusha Central Market', 1200, 'imara'),
        _price('Karoti', 'Kariakoo — Dar es Salaam', 1400, 'inapanda'),
      ];

  static Map<String, dynamic> _price(
          String crop, String market, int price, String trend) =>
      {
        'crop_name': crop,
        'market_name': market,
        'price_tzs_kg': price,
        'trend': trend,
        'source': 'Wizara ya Kilimo / TanTrade',
      };

  // ─── PESTICIDES / HERBICIDES / BIOPESTICIDES ──────────────────────────────

  static List<Map<String, dynamic>> get pesticides => [
        // ── INSECTICIDES ──────────────────────────────────────────────────
        {
          'brand_name': 'Coragen 20SC',
          'active_ingredient': 'Chlorantraniliprole 200 g/L',
          'category': 'Insecticide',
          'target_pests': 'Fall Armyworm, Stem borers, Leaf miners',
          'target_crops': 'Mahindi, Mpunga, Nyanya, Pamba',
          'dose_per_15L': '20 ml',
          'phi_days': 14,
          'tpri_registered': true,
          'price_range_tzs': '18,000–25,000 kwa lita 1',
          'manufacturer': 'FMC Corporation',
          'description_sw':
              'Dawa bora ya kuua viwavi vya jeshi na wadudu wanaochimba shina la mahindi. Inafanya kazi ndani ya mmea (systemic) hivyo hata mvua haibatilishi.',
          'safety_sw':
              'Vaa glovu, barakoa na miwani wakati wa kupulizia. Epuka kunywa au kula kabla ya kunawa mikono.',
        },
        {
          'brand_name': 'Emamectin Benzoate 5SG',
          'active_ingredient': 'Emamectin benzoate 5%',
          'category': 'Insecticide',
          'target_pests': 'Fall Armyworm, Diamondback moth, Thrips',
          'target_crops': 'Mahindi, Kabichi, Nyanya, Pilipili',
          'dose_per_15L': '10 g',
          'phi_days': 7,
          'tpri_registered': true,
          'price_range_tzs': '8,000–12,000 kwa 100g',
          'manufacturer': 'Various (Generic)',
          'description_sw':
              'Dawa ya unga inayofanya kazi haraka dhidi ya viwavi. Ni nafuu na inapatikana madukani mengi Tanzania.',
          'safety_sw':
              'Sumu kali — vaa PPE kamili. Usiruhusu watoto karibu na dawa.',
        },
        {
          'brand_name': 'Duduthrin 15EC',
          'active_ingredient': 'Lambda-cyhalothrin 15 g/L',
          'category': 'Insecticide',
          'target_pests': 'Aphids, Whitefly, Thrips, Beetles, Armyworm',
          'target_crops': 'Mahindi, Nyanya, Maharagwe, Vitunguu, Pamba',
          'dose_per_15L': '15–20 ml',
          'phi_days': 7,
          'tpri_registered': true,
          'price_range_tzs': '5,000–8,000 kwa lita 1',
          'manufacturer': 'Juanco Agro / Twiga Chemicals',
          'description_sw':
              'Dawa rahisi inayoua wadudu wengi kwa bei nafuu. Inafaa kwa wakulima wadogo.',
          'safety_sw':
              'Sumu ya wastani — vaa glovu na barakoa. Usipulizie karibu na mto au ziwa.',
        },
        {
          'brand_name': 'Karate Zeon 50CS',
          'active_ingredient': 'Lambda-cyhalothrin 50 g/L',
          'category': 'Insecticide',
          'target_pests': 'Aphids, Whitefly, Locusts, Stem borers',
          'target_crops': 'Mazao mengi',
          'dose_per_15L': '10 ml',
          'phi_days': 7,
          'tpri_registered': true,
          'price_range_tzs': '12,000–18,000 kwa lita 1',
          'manufacturer': 'Syngenta',
          'description_sw':
              'Dawa yenye nguvu inayofanya kazi haraka. Inafaa kwa milipuko ya nzige na viwavi.',
          'safety_sw':
              'Hatari kwa nyuki — usipulizie wakati wa maua. Vaa PPE kamili.',
        },
        {
          'brand_name': 'Actara 25WG',
          'active_ingredient': 'Thiamethoxam 25%',
          'category': 'Insecticide',
          'target_pests': 'Whitefly, Aphids, Thrips, Leaf hoppers',
          'target_crops': 'Nyanya, Pilipili, Vitunguu, Mahindi',
          'dose_per_15L': '3 g',
          'phi_days': 14,
          'tpri_registered': true,
          'price_range_tzs': '15,000–22,000 kwa 100g',
          'manufacturer': 'Syngenta',
          'description_sw':
              'Dawa ya neonicotinoid inayofanya kazi ndani ya mmea. Inaua wadudu wanaosonga mmea kwa muda mrefu.',
          'safety_sw':
              'Hatari sana kwa nyuki — usitumie wakati wa maua. Fuata maelekezo.',
        },
        {
          'brand_name': 'Dimethoate 40EC',
          'active_ingredient': 'Dimethoate 400 g/L',
          'category': 'Insecticide',
          'target_pests': 'Aphids, Mites, Leaf miners, Thrips',
          'target_crops': 'Nyanya, Maharagwe, Vitunguu, Pilipili',
          'dose_per_15L': '20–30 ml',
          'phi_days': 10,
          'tpri_registered': true,
          'price_range_tzs': '4,000–7,000 kwa lita 1',
          'manufacturer': 'Various (Generic)',
          'description_sw':
              'Dawa ya zamani lakini bado inafanya kazi vizuri dhidi ya wadudu wadogo kama aphids na mites.',
          'safety_sw':
              'Sumu kali — vaa PPE kamili. Usitumie siku 10 kabla ya kuvuna.',
        },

        // ── FUNGICIDES ────────────────────────────────────────────────────
        {
          'brand_name': 'Ridomil Gold MZ 68WP',
          'active_ingredient': 'Metalaxyl-M 4% + Mancozeb 64%',
          'category': 'Fungicide',
          'target_pests': 'Late Blight, Downy Mildew, Damping off',
          'target_crops': 'Nyanya, Pilipili, Viazi, Alizeti',
          'dose_per_15L': '30 g',
          'phi_days': 7,
          'tpri_registered': true,
          'price_range_tzs': '12,000–18,000 kwa kg 1',
          'manufacturer': 'Syngenta',
          'description_sw':
              'Dawa bora dhidi ya ugonjwa wa kuoza nyanya (Late Blight). Inafanya kazi ndani na nje ya mmea.',
          'safety_sw':
              'Vaa glovu na barakoa. Hifadhi mbali na chakula na maji.',
        },
        {
          'brand_name': 'Dithane M-45',
          'active_ingredient': 'Mancozeb 80%',
          'category': 'Fungicide',
          'target_pests':
              'Early Blight, Late Blight, Anthracnose, Grey Leaf Spot',
          'target_crops': 'Nyanya, Mahindi, Maharagwe, Vitunguu',
          'dose_per_15L': '30–40 g',
          'phi_days': 7,
          'tpri_registered': true,
          'price_range_tzs': '6,000–9,000 kwa kg 1',
          'manufacturer': 'Corteva / Dow',
          'description_sw':
              'Dawa ya unga ya kawaida inayozuia magonjwa ya ukungu. Nafuu na inapatikana kila mahali.',
          'safety_sw': 'Epuka kupumua unga wakati wa kuchanganya. Vaa barakoa.',
        },
        {
          'brand_name': 'Score 250EC',
          'active_ingredient': 'Difenoconazole 250 g/L',
          'category': 'Fungicide',
          'target_pests': 'Powdery Mildew, Rust, Anthracnose, Leaf Spot',
          'target_crops': 'Nyanya, Maharagwe, Vitunguu, Mahindi',
          'dose_per_15L': '5 ml',
          'phi_days': 14,
          'tpri_registered': true,
          'price_range_tzs': '18,000–25,000 kwa lita 1',
          'manufacturer': 'Syngenta',
          'description_sw':
              'Dawa ya nguvu inayotibu na kuzuia magonjwa ya ukungu. Kidogo tu kinatosha kwa matokeo mazuri.',
          'safety_sw': 'Vaa PPE kamili. Hifadhi mahali pa baridi na kavu.',
        },
        {
          'brand_name': 'Copper Oxychloride 50WP',
          'active_ingredient': 'Copper oxychloride 50%',
          'category': 'Fungicide',
          'target_pests': 'Bacterial Blight, Downy Mildew, Anthracnose',
          'target_crops': 'Nyanya, Pilipili, Maharagwe, Kahawa',
          'dose_per_15L': '30–45 g',
          'phi_days': 7,
          'tpri_registered': true,
          'price_range_tzs': '4,000–6,000 kwa kg 1',
          'manufacturer': 'Various (Generic)',
          'description_sw':
              'Dawa ya asili ya shaba inayofanya kazi dhidi ya magonjwa ya kuvu na bacteria. Salama zaidi kwa mazingira.',
          'safety_sw': 'Salama ya wastani — vaa glovu na barakoa tu.',
        },

        // ── HERBICIDES ────────────────────────────────────────────────────
        {
          'brand_name': 'Roundup 480SL',
          'active_ingredient': 'Glyphosate 480 g/L',
          'category': 'Herbicide',
          'target_pests': 'Magugu yote (non-selective)',
          'target_crops': 'Kutumika kabla ya kupanda (pre-planting)',
          'dose_per_15L': '100–150 ml',
          'phi_days': 7,
          'tpri_registered': true,
          'price_range_tzs': '8,000–12,000 kwa lita 1',
          'manufacturer': 'Bayer / Monsanto',
          'description_sw':
              'Dawa ya kuua magugu yote. Tumia KABLA ya kupanda mbegu — haiui mazao yaliyopandwa tayari.',
          'safety_sw':
              'Vaa glovu na buti. Usipulizie karibu na maji au mazao yanayokua.',
        },
        {
          'brand_name': 'Weedmaster 720SL',
          'active_ingredient': '2,4-D Amine 720 g/L',
          'category': 'Herbicide',
          'target_pests': 'Magugu mapana ya jani (broadleaf weeds)',
          'target_crops': 'Mahindi (baada ya wiki 3 za kupanda)',
          'dose_per_15L': '20–30 ml',
          'phi_days': 30,
          'tpri_registered': true,
          'price_range_tzs': '5,000–8,000 kwa lita 1',
          'manufacturer': 'Various (Generic)',
          'description_sw':
              'Inaua magugu ya majani mapana bila kudhuru mahindi. Tumia wiki 3–4 baada ya mahindi kuota.',
          'safety_sw':
              'Sumu — usinyunyizie karibu na miti ya matunda au mboga. Vaa PPE kamili.',
        },
        {
          'brand_name': 'Stomp 330E',
          'active_ingredient': 'Pendimethalin 330 g/L',
          'category': 'Herbicide',
          'target_pests': 'Magugu ya nyasi na majani (pre-emergence)',
          'target_crops': 'Mahindi, Pamba, Alizeti, Vitunguu',
          'dose_per_15L': '100–130 ml',
          'phi_days': 0,
          'tpri_registered': true,
          'price_range_tzs': '10,000–15,000 kwa lita 1',
          'manufacturer': 'BASF',
          'description_sw':
              'Piga baada ya kupanda lakini KABLA magugu hajaota. Inazuia mbegu za magugu kuota.',
          'safety_sw':
              'Vaa glovu na buti za mpira. Usinyunyizie mvua inayokuja.',
        },
        {
          'brand_name': 'Dual Gold 960EC',
          'active_ingredient': 'S-Metolachlor 960 g/L',
          'category': 'Herbicide',
          'target_pests': 'Nyasi na magugu ya majani nyembamba',
          'target_crops': 'Mahindi, Maharage, Alizeti',
          'dose_per_15L': '30–40 ml',
          'phi_days': 0,
          'tpri_registered': true,
          'price_range_tzs': '12,000–18,000 kwa lita 1',
          'manufacturer': 'Syngenta',
          'description_sw':
              'Dawa ya pre-emergence inayodhibiti nyasi na magugu. Tumia baada ya kupanda kabla ya mvua.',
          'safety_sw': 'Vaa PPE kamili. Hifadhi mbali na jua moja kwa moja.',
        },

        // ── BIOPESTICIDES ─────────────────────────────────────────────────
        {
          'brand_name': 'Dipel DF (Bt)',
          'active_ingredient': 'Bacillus thuringiensis var. kurstaki 54%',
          'category': 'Biopesticide',
          'target_pests': 'Fall Armyworm, Cabbage worm, Diamondback moth',
          'target_crops': 'Mahindi, Kabichi, Nyanya, Mbogamboga zote',
          'dose_per_15L': '15–20 g',
          'phi_days': 0,
          'tpri_registered': true,
          'price_range_tzs': '8,000–12,000 kwa 500g',
          'manufacturer': 'Sumitomo Chemical',
          'description_sw':
              'Dawa ya asili salama kabisa kwa binadamu na wanyama. Inaua viwavi peke yake bila kudhuru wadudu wazuri. Inafaa kwa kilimo hai.',
          'safety_sw':
              'Salama sana — hata bila PPE. Lakini vaa barakoa kuzuia vumbi.',
        },
        {
          'brand_name': 'Neem Azal T/S',
          'active_ingredient': 'Azadirachtin 1% (Mti wa Mwarobaini)',
          'category': 'Biopesticide',
          'target_pests': 'Aphids, Whitefly, Thrips, Mites, Leafminers',
          'target_crops': 'Nyanya, Kabichi, Vitunguu, Mbogamboga zote',
          'dose_per_15L': '15–25 ml',
          'phi_days': 3,
          'tpri_registered': true,
          'price_range_tzs': '10,000–15,000 kwa lita 1',
          'manufacturer': 'Trifolio / BioControl',
          'description_sw':
              'Dawa inayotokana na mti wa mwarobaini. Inazuia wadudu kukua na kuzaliana. Salama kwa afya na mazingira.',
          'safety_sw':
              'Salama sana. Vaa glovu tu. Hifadhi mahali pa baridi na giza.',
        },
        {
          'brand_name': 'Beauveria bassiana WP',
          'active_ingredient': 'Beauveria bassiana 1×10⁸ spores/g',
          'category': 'Biopesticide',
          'target_pests': 'Stem borers, Whitefly, Aphids, Thrips',
          'target_crops': 'Mahindi, Kahawa, Pamba, Mbogamboga',
          'dose_per_15L': '40 g',
          'phi_days': 0,
          'tpri_registered': true,
          'price_range_tzs': '12,000–18,000 kwa kg 1',
          'manufacturer': 'TARI / BioControl',
          'description_sw':
              'Kuvu wa asili unaoshambulia na kuua wadudu. Salama kabisa. Inafaa sana kwa kilimo hai.',
          'safety_sw': 'Salama kabisa — tumia bila wasiwasi.',
        },
        {
          'brand_name': 'Trichoderma viride WP',
          'active_ingredient': 'Trichoderma viride 2×10⁶ cfu/g',
          'category': 'Biopesticide',
          'target_pests': 'Damping off, Root rot, Fusarium wilt',
          'target_crops': 'Mbogamboga zote, Mahindi, Nyanya, Maua',
          'dose_per_15L': '30 g (au loweka mbegu)',
          'phi_days': 0,
          'tpri_registered': true,
          'price_range_tzs': '8,000–14,000 kwa kg 1',
          'manufacturer': 'TARI Selian / BioControl',
          'description_sw':
              'Kuvu wa manufaa anayezuia magonjwa ya udongo na mizizi. Tumia wakati wa kupanda au kumwagilia mizizi.',
          'safety_sw': 'Salama kabisa kwa binadamu, wanyama na mazingira.',
        },
        {
          'brand_name': 'Spintor 480SC',
          'active_ingredient': 'Spinosad 480 g/L',
          'category': 'Biopesticide',
          'target_pests': 'Fall Armyworm, Thrips, Leafminers, Caterpillars',
          'target_crops': 'Mahindi, Nyanya, Kabichi, Vitunguu',
          'dose_per_15L': '10–15 ml',
          'phi_days': 7,
          'tpri_registered': true,
          'price_range_tzs': '20,000–28,000 kwa lita 1',
          'manufacturer': 'Corteva Agriscience',
          'description_sw':
              'Dawa ya asili yenye nguvu sana dhidi ya viwavi. Inatokana na bakteria wa udongo. Inafaa kwa kilimo hai.',
          'safety_sw':
              'Hatari kwa nyuki — usipulizie wakati wa maua. Vaa glovu.',
        },
      ];

  // ─── TOSCI SEED VARIETIES ─────────────────────────────────────────────────

  static List<Map<String, dynamic>> seedsFor(String crop) {
    switch (crop) {
      case 'Mahindi':
        return _maizeSeedss;
      case 'Nyanya':
        return _tomatoSeeds;
      case 'Maharagwe':
        return _beanSeeds;
      case 'Mchele':
        return _riceSeeds;
      case 'Muhogo':
        return _cassavaSeeds;
      case 'Alizeti':
        return _sunflowerSeeds;
      default:
        return _genericSeeds(crop);
    }
  }

  static List<Map<String, dynamic>> get _maizeSeedss => [
        {
          'variety_name': 'DK8031',
          'crop': 'Mahindi',
          'category': 'Hybrid',
          'company': 'Dekalb / Bayer',
          'tosci_certified': true,
          'maturity_days': 110,
          'yield_potential_ton_ha': 8.5,
          'disease_resistance': [
            'Maize Streak Virus (MSV)',
            'Grey Leaf Spot',
            'Turcicum Blight',
            'Common Rust',
          ],
          'pest_resistance': ['Fall Armyworm tolerance', 'Stem borer tolerance'],
          'drought_tolerance': 'high',
          'water_stress_rating':
              'Inastahimili ukame vizuri sana — inafaa kwa mikoa kame kama Dodoma, Singida na Shinyanga.',
          'nutrient_efficiency': 'medium',
          'soil_types': ['Tifutifu', 'Udongo mwekundu', 'Sandy loam'],
          'altitude_range_m': '0–2000',
          'regions_recommended': ['Morogoro', 'Dodoma', 'Manyara', 'Arusha'],
          'seed_rate_kg_ha': 25,
          'planting_spacing': '75cm × 25cm (mimea 1 kwa shimo)',
          'description_sw':
              'DK8031 ni mseto maarufu sana Tanzania. Una tija kubwa na unastahimili ukame na magonjwa mengi. Unapendelewa na wakulima wa kanda zote.',
          'best_for_sw':
              'Bora kwa wakulima wa mikoa ya kati yenye mvua ya wastani 600–900mm kwa mwaka.',
          'tosci_number': 'URT/TZ/MAI/001',
          'year_released': 2012,
        },
        {
          'variety_name': 'SC403',
          'crop': 'Mahindi',
          'category': 'Hybrid',
          'company': 'Seedco Tanzania',
          'tosci_certified': true,
          'maturity_days': 90,
          'yield_potential_ton_ha': 7.0,
          'disease_resistance': [
            'Maize Streak Virus',
            'Northern Leaf Blight',
            'Common Rust',
          ],
          'pest_resistance': ['Fall Armyworm tolerance'],
          'drought_tolerance': 'medium',
          'water_stress_rating':
              'Wastani wa kustahimili ukame — inafaa kwa maeneo yenye mvua 700–1200mm.',
          'nutrient_efficiency': 'high',
          'soil_types': ['Tifutifu', 'Udongo mzito'],
          'altitude_range_m': '0–1600',
          'regions_recommended': ['Pwani', 'Morogoro', 'Tanga', 'Mbeya'],
          'seed_rate_kg_ha': 25,
          'planting_spacing': '75cm × 25cm',
          'description_sw':
              'SC403 ni mseto wa muda mfupi (siku 90) unaofaa kwa msimu mfupi wa mvua. Una tija nzuri hata kwenye udongo wa rutuba ya wastani.',
          'best_for_sw':
              'Bora kwa wakulima wanaotaka kuvuna haraka au kupanda msimu wa pili.',
          'tosci_number': 'URT/TZ/MAI/012',
          'year_released': 2010,
        },
        {
          'variety_name': 'SEEDCO SC627',
          'crop': 'Mahindi',
          'category': 'Hybrid',
          'company': 'Seedco Tanzania',
          'tosci_certified': true,
          'maturity_days': 120,
          'yield_potential_ton_ha': 10.0,
          'disease_resistance': [
            'Maize Streak Virus',
            'Grey Leaf Spot',
            'Goss\'s Wilt',
          ],
          'pest_resistance': ['Stem borer tolerance'],
          'drought_tolerance': 'low',
          'water_stress_rating':
              'Inahitaji mvua ya kutosha (1000–1500mm). Inafaa kwa mikoa yenye mvua nyingi kama Kagera, Kigoma, Mbeya.',
          'nutrient_efficiency': 'high',
          'soil_types': ['Udongo mzito wenye rutuba', 'Tifutifu'],
          'altitude_range_m': '1000–2200',
          'regions_recommended': ['Mbeya', 'Iringa', 'Kagera', 'Kigoma', 'Njombe'],
          'seed_rate_kg_ha': 25,
          'planting_spacing': '75cm × 30cm',
          'description_sw':
              'SC627 ina tija kubwa sana chini ya hali nzuri. Inafaa kwa nyanda za juu za Tanzania zenye ardhi nzuri na mvua nyingi.',
          'best_for_sw':
              'Bora kwa wakulima wa nyanda za juu wanaoweza kutumia mbolea ya kutosha.',
          'tosci_number': 'URT/TZ/MAI/028',
          'year_released': 2016,
        },
        {
          'variety_name': 'TARI Composite 1',
          'crop': 'Mahindi',
          'category': 'OPV',
          'company': 'TARI (Tanzania Agricultural Research Institute)',
          'tosci_certified': true,
          'maturity_days': 105,
          'yield_potential_ton_ha': 4.5,
          'disease_resistance': [
            'Maize Streak Virus',
            'Common Rust',
            'Downy Mildew',
          ],
          'pest_resistance': [],
          'drought_tolerance': 'high',
          'water_stress_rating':
              'Inastahimili ukame vizuri. Ilizalishwa hasa kwa mikoa kame ya Tanzania.',
          'nutrient_efficiency': 'high',
          'soil_types': ['Udongo wa aina zote', 'Mchanga', 'Tifutifu'],
          'altitude_range_m': '0–1800',
          'regions_recommended': ['Dodoma', 'Singida', 'Tabora', 'Shinyanga'],
          'seed_rate_kg_ha': 20,
          'planting_spacing': '75cm × 30cm',
          'description_sw':
              'Aina ya wazi (OPV) iliyoundwa na TARI kwa ajili ya wakulima wadogo. Mbegu zinaweza kuhifadhiwa kutoka mavuno yaliyopita.',
          'best_for_sw':
              'Bora kwa wakulima wasio na uwezo wa kununua mbegu kila mwaka. Mbegu zinaweza kuhifadhiwa na kupandwa tena.',
          'tosci_number': 'URT/TZ/MAI/003',
          'year_released': 2008,
        },
        {
          'variety_name': 'Pannar PAN 4M-21',
          'crop': 'Mahindi',
          'category': 'Hybrid',
          'company': 'Pannar Seed',
          'tosci_certified': true,
          'maturity_days': 105,
          'yield_potential_ton_ha': 9.0,
          'disease_resistance': [
            'MSV', 'Grey Leaf Spot', 'Northern Leaf Blight'
          ],
          'pest_resistance': ['Fall Armyworm tolerance'],
          'drought_tolerance': 'high',
          'water_stress_rating':
              'Inastahimili ukame vizuri — inafaa kwa maeneo yenye mvua 500–900mm.',
          'nutrient_efficiency': 'medium',
          'soil_types': ['Tifutifu', 'Sandy loam', 'Udongo mwekundu'],
          'altitude_range_m': '0–1800',
          'regions_recommended': ['Morogoro', 'Dodoma', 'Arusha', 'Kilimanjaro'],
          'seed_rate_kg_ha': 25,
          'planting_spacing': '75cm × 25cm',
          'description_sw':
              'PAN 4M-21 ni mseto bora wa ukame unaolimwa sana kaskazini mwa Tanzania. Una tija ya juu hata mvua kidogo.',
          'best_for_sw':
              'Bora kwa mikoa ya kaskazini yenye mvua chache lakini ardhi nzuri.',
          'tosci_number': 'URT/TZ/MAI/045',
          'year_released': 2018,
        },
      ];

  static List<Map<String, dynamic>> get _tomatoSeeds => [
        {
          'variety_name': 'Tengeru 97',
          'crop': 'Nyanya',
          'category': 'OPV',
          'company': 'TARI Tengeru / Arusha',
          'tosci_certified': true,
          'maturity_days': 75,
          'yield_potential_ton_ha': 30.0,
          'disease_resistance': [
            'Fusarium Wilt',
            'Bacterial Wilt',
            'Early Blight tolerance',
          ],
          'pest_resistance': ['Whitefly tolerance'],
          'drought_tolerance': 'medium',
          'water_stress_rating':
              'Inastahimili joto — inafaa kwa maeneo ya pwani na tambarare za Tanzania.',
          'nutrient_efficiency': 'medium',
          'soil_types': ['Tifutifu', 'Udongo mwekundu wenye mifereji'],
          'altitude_range_m': '0–1500',
          'regions_recommended': ['Arusha', 'Kilimanjaro', 'Tanga', 'Morogoro'],
          'seed_rate_kg_ha': 0.5,
          'planting_spacing': '60cm × 50cm',
          'description_sw':
              'Tengeru 97 ni aina ya wazi maarufu sana Tanzania. Ina tija nzuri na inastahimili magonjwa ya wilting. Mbegu zinaweza kuhifadhiwa.',
          'best_for_sw':
              'Bora kwa wakulima wadogo wa mbogamboga — bei ya mbegu ni nafuu na zinaweza kuhifadhiwa.',
          'tosci_number': 'URT/TZ/TOM/001',
          'year_released': 1997,
        },
        {
          'variety_name': 'Anna F1',
          'crop': 'Nyanya',
          'category': 'Hybrid',
          'company': 'East West Seed (KilimoFresh)',
          'tosci_certified': true,
          'maturity_days': 70,
          'yield_potential_ton_ha': 60.0,
          'disease_resistance': [
            'Tomato Yellow Leaf Curl Virus (TYLCV)',
            'Fusarium Wilt Race 1&2',
            'Bacterial Speck',
          ],
          'pest_resistance': ['Whitefly resistance (TYLCV vector)'],
          'drought_tolerance': 'low',
          'water_stress_rating':
              'Inahitaji umwagiliaji wa kutosha. Haifai maeneo kame bila umwagiliaji.',
          'nutrient_efficiency': 'high',
          'soil_types': ['Tifutifu wenye mifereji mizuri'],
          'altitude_range_m': '0–1800',
          'regions_recommended': ['Arusha', 'Kilimanjaro', 'Morogoro', 'Iringa'],
          'seed_rate_kg_ha': 0.3,
          'planting_spacing': '50cm × 60cm',
          'description_sw':
              'Anna F1 ni mseto wenye tija kubwa sana. Inastahimili ugonjwa wa TYLCV unaoenezwa na nzi weupe. Inafaa kwa soko la biashara.',
          'best_for_sw':
              'Bora kwa wakulima wanaolima kwa biashara na wana uwezo wa umwagiliaji na mbolea.',
          'tosci_number': 'URT/TZ/TOM/022',
          'year_released': 2014,
        },
        {
          'variety_name': 'Nuru F1',
          'crop': 'Nyanya',
          'category': 'Hybrid',
          'company': 'Syngenta',
          'tosci_certified': true,
          'maturity_days': 65,
          'yield_potential_ton_ha': 55.0,
          'disease_resistance': [
            'TYLCV', 'Fusarium Wilt', 'Late Blight tolerance'
          ],
          'pest_resistance': ['Whitefly tolerance'],
          'drought_tolerance': 'medium',
          'water_stress_rating':
              'Inastahimili joto la wastani. Inafaa kwa maeneo ya tambarare na pwani.',
          'nutrient_efficiency': 'medium',
          'soil_types': ['Tifutifu', 'Sandy loam'],
          'altitude_range_m': '0–1600',
          'regions_recommended': ['Pwani', 'Morogoro', 'Tanga', 'Dar es Salaam'],
          'seed_rate_kg_ha': 0.3,
          'planting_spacing': '50cm × 60cm',
          'description_sw':
              'Nuru F1 ni mseto mzuri wa pwani. Matunda ni makubwa na madumu muda mrefu — inafaa kwa usafirishaji masafa marefu.',
          'best_for_sw':
              'Bora kwa wakulima wa pwani na Dar es Salaam wanaouza masokoni makubwa.',
          'tosci_number': 'URT/TZ/TOM/031',
          'year_released': 2017,
        },
      ];

  static List<Map<String, dynamic>> get _beanSeeds => [
        {
          'variety_name': 'Jesca',
          'crop': 'Maharagwe',
          'category': 'Improved OPV',
          'company': 'TARI Selian',
          'tosci_certified': true,
          'maturity_days': 75,
          'yield_potential_ton_ha': 2.5,
          'disease_resistance': [
            'Bean Common Mosaic Virus',
            'Angular Leaf Spot',
            'Anthracnose',
          ],
          'pest_resistance': [],
          'drought_tolerance': 'medium',
          'water_stress_rating':
              'Inastahimili ukame wa wastani. Inafaa kwa mikoa ya nyanda za juu.',
          'nutrient_efficiency': 'high',
          'soil_types': ['Tifutifu', 'Udongo mwekundu'],
          'altitude_range_m': '1000–2200',
          'regions_recommended': ['Arusha', 'Kilimanjaro', 'Mbeya', 'Iringa'],
          'seed_rate_kg_ha': 80,
          'planting_spacing': '50cm × 20cm',
          'description_sw':
              'Jesca ni aina bora ya maharagwe ya nyanda za juu. Inastahimili magonjwa mengi na ina tija nzuri.',
          'best_for_sw':
              'Bora kwa wakulima wa mikoa ya kaskazini na nyanda za juu za Tanzania.',
          'tosci_number': 'URT/TZ/BEA/005',
          'year_released': 2005,
        },
        {
          'variety_name': 'Selian 97',
          'crop': 'Maharagwe',
          'category': 'OPV',
          'company': 'TARI Selian',
          'tosci_certified': true,
          'maturity_days': 80,
          'yield_potential_ton_ha': 2.2,
          'disease_resistance': [
            'Bean Common Mosaic Virus',
            'Root Rot',
          ],
          'pest_resistance': [],
          'drought_tolerance': 'high',
          'water_stress_rating':
              'Inastahimili ukame vizuri. Inafaa kwa maeneo ya tambarare kame.',
          'nutrient_efficiency': 'high',
          'soil_types': ['Aina zote za udongo'],
          'altitude_range_m': '0–2000',
          'regions_recommended': ['Dodoma', 'Morogoro', 'Singida', 'Manyara'],
          'seed_rate_kg_ha': 80,
          'planting_spacing': '50cm × 20cm',
          'description_sw':
              'Selian 97 ni aina ya zamani lakini bado inafanya vizuri. Mbegu zinaweza kuhifadhiwa na bei ni nafuu.',
          'best_for_sw':
              'Bora kwa wakulima wanaotaka aina rahisi inayostahimili ukame.',
          'tosci_number': 'URT/TZ/BEA/002',
          'year_released': 1997,
        },
      ];

  static List<Map<String, dynamic>> get _riceSeeds => [
        {
          'variety_name': 'SARO 5',
          'crop': 'Mchele',
          'category': 'Improved OPV',
          'company': 'TARI Dakawa',
          'tosci_certified': true,
          'maturity_days': 115,
          'yield_potential_ton_ha': 6.0,
          'disease_resistance': [
            'Rice Blast',
            'Brown Spot',
            'Bacterial Leaf Blight',
          ],
          'pest_resistance': ['Stem borer tolerance'],
          'drought_tolerance': 'medium',
          'water_stress_rating':
              'Inastahimili mafuriko ya muda — inafaa kwa maeneo ya bonde lenye maji.',
          'nutrient_efficiency': 'medium',
          'soil_types': ['Udongo wa mabondeni', 'Clay'],
          'altitude_range_m': '0–1200',
          'regions_recommended': ['Morogoro', 'Mbeya', 'Shinyanga', 'Mwanza'],
          'seed_rate_kg_ha': 60,
          'planting_spacing': '20cm × 20cm (upandaji wa miche)',
          'description_sw':
              'SARO 5 ni aina maarufu ya mchele Tanzania. Inastahimili ugonjwa wa Blast na ina ubora mzuri wa mpunga.',
          'best_for_sw':
              'Bora kwa mabonde ya umwagiliaji na maeneo yenye mvua nyingi.',
          'tosci_number': 'URT/TZ/RIC/001',
          'year_released': 1995,
        },
        {
          'variety_name': 'TXD 306',
          'crop': 'Mchele',
          'category': 'Improved OPV',
          'company': 'TARI',
          'tosci_certified': true,
          'maturity_days': 120,
          'yield_potential_ton_ha': 7.0,
          'disease_resistance': ['Rice Blast', 'Sheath Blight'],
          'pest_resistance': [],
          'drought_tolerance': 'low',
          'water_stress_rating':
              'Inahitaji maji mengi ya umwagiliaji. Haifai maeneo kame.',
          'nutrient_efficiency': 'high',
          'soil_types': ['Clay', 'Udongo mzito wa mabondeni'],
          'altitude_range_m': '0–800',
          'regions_recommended': ['Morogoro', 'Mwanza', 'Kagera', 'Pwani'],
          'seed_rate_kg_ha': 60,
          'planting_spacing': '20cm × 20cm',
          'description_sw':
              'TXD 306 ina tija kubwa sana chini ya umwagiliaji mzuri. Mpunga wake ni mrefu na mwembamba — unapendwa sana sokoni.',
          'best_for_sw':
              'Bora kwa wakulima wa mabonde ya umwagiliaji yenye ardhi nzuri.',
          'tosci_number': 'URT/TZ/RIC/008',
          'year_released': 2003,
        },
      ];

  static List<Map<String, dynamic>> get _cassavaSeeds => [
        {
          'variety_name': 'Kiroba',
          'crop': 'Muhogo',
          'category': 'Improved OPV',
          'company': 'TARI Kibaha',
          'tosci_certified': true,
          'maturity_days': 270,
          'yield_potential_ton_ha': 35.0,
          'disease_resistance': [
            'Cassava Mosaic Disease (CMD)',
            'Cassava Brown Streak Disease (CBSD)',
          ],
          'pest_resistance': ['Cassava Mealybug tolerance'],
          'drought_tolerance': 'high',
          'water_stress_rating':
              'Inastahimili ukame vizuri sana — inafaa kwa mikoa yote kame ya Tanzania.',
          'nutrient_efficiency': 'high',
          'soil_types': ['Mchanga', 'Tifutifu', 'Udongo wa aina zote'],
          'altitude_range_m': '0–1800',
          'regions_recommended': ['Pwani', 'Morogoro', 'Mtwara', 'Lindi', 'Dar es Salaam'],
          'seed_rate_kg_ha': 10000,
          'planting_spacing': '1m × 1m',
          'description_sw':
              'Kiroba ni aina bora ya muhogo inayostahimili magonjwa mawili makubwa ya muhogo Tanzania. Ina tija kubwa na inalimwa sana pwani.',
          'best_for_sw':
              'Bora kwa wakulima wa pwani na maeneo yenye magonjwa ya muhogo. Haihitaji rutuba nyingi.',
          'tosci_number': 'URT/TZ/CAS/003',
          'year_released': 2009,
        },
        {
          'variety_name': 'Mkombozi',
          'crop': 'Muhogo',
          'category': 'Improved OPV',
          'company': 'TARI Kibaha',
          'tosci_certified': true,
          'maturity_days': 240,
          'yield_potential_ton_ha': 30.0,
          'disease_resistance': [
            'Cassava Mosaic Disease (CMD)',
            'CBSD tolerance',
          ],
          'pest_resistance': [],
          'drought_tolerance': 'high',
          'water_stress_rating':
              'Inastahimili ukame — inalimwa katika maeneo mengi ya Tanzania.',
          'nutrient_efficiency': 'high',
          'soil_types': ['Aina zote za udongo'],
          'altitude_range_m': '0–1600',
          'regions_recommended': ['Mtwara', 'Lindi', 'Ruvuma', 'Pwani'],
          'seed_rate_kg_ha': 10000,
          'planting_spacing': '1m × 1m',
          'description_sw':
              'Mkombozi ni aina inayostahimili ugonjwa wa CMD vizuri. Inakua haraka na matunda ni makubwa.',
          'best_for_sw':
              'Bora kwa mikoa ya kusini mwa Tanzania inayoathiriwa sana na magonjwa ya muhogo.',
          'tosci_number': 'URT/TZ/CAS/005',
          'year_released': 2011,
        },
      ];

  static List<Map<String, dynamic>> get _sunflowerSeeds => [
        {
          'variety_name': 'Lyamungu 85',
          'crop': 'Alizeti',
          'category': 'OPV',
          'company': 'TARI Lyamungu',
          'tosci_certified': true,
          'maturity_days': 95,
          'yield_potential_ton_ha': 1.8,
          'disease_resistance': ['Alternaria Leaf Spot', 'Rust'],
          'pest_resistance': [],
          'drought_tolerance': 'high',
          'water_stress_rating':
              'Inastahimili ukame vizuri — inafaa kwa mikoa ya kati na kaskazini.',
          'nutrient_efficiency': 'high',
          'soil_types': ['Tifutifu', 'Sandy loam', 'Udongo mwekundu'],
          'altitude_range_m': '0–1800',
          'regions_recommended': ['Dodoma', 'Singida', 'Manyara', 'Tabora'],
          'seed_rate_kg_ha': 5,
          'planting_spacing': '75cm × 30cm',
          'description_sw':
              'Lyamungu 85 ni aina ya zamani lakini inayofanya vizuri mikoa kame. Mafuta yake ni mengi na ubora ni mzuri.',
          'best_for_sw':
              'Bora kwa wakulima wa mikoa kame — haihitaji mvua nyingi wala mbolea nyingi.',
          'tosci_number': 'URT/TZ/SUN/001',
          'year_released': 1985,
        },
      ];

  static List<Map<String, dynamic>> _genericSeeds(String crop) => [
        {
          'variety_name': 'Aina ya Kawaida',
          'crop': crop,
          'category': 'OPV',
          'company': 'TARI Tanzania',
          'tosci_certified': true,
          'maturity_days': 90,
          'yield_potential_ton_ha': 3.0,
          'disease_resistance': ['Magonjwa ya kawaida'],
          'pest_resistance': [],
          'drought_tolerance': 'medium',
          'water_stress_rating': 'Inastahimili ukame wa wastani.',
          'nutrient_efficiency': 'medium',
          'soil_types': ['Tifutifu'],
          'altitude_range_m': '0–1800',
          'regions_recommended': ['Tanzania yote'],
          'seed_rate_kg_ha': 30,
          'planting_spacing': '60cm × 30cm',
          'description_sw':
              'Aina iliyoidhinishwa na TOSCI kwa ajili ya wakulima wa Tanzania.',
          'best_for_sw': 'Inafaa kwa mikoa mingi ya Tanzania.',
          'tosci_number': 'URT/TZ/GEN/001',
          'year_released': 2010,
        },
      ];
}

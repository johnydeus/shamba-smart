import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:supabase_flutter/supabase_flutter.dart';

// This service asks Claude for live Tanzania agricultural data
// and caches results in Supabase so the app works offline too
class DataSyncService {
  static const String _model = 'claude-sonnet-4-5';
  static SupabaseClient get _db => Supabase.instance.client;

  static Future<Map<String, dynamic>> _invokeClaude(
      Map<String, dynamic> payload) async {
    final res = await _db.functions.invoke('claude-proxy', body: payload);
    return res.data as Map<String, dynamic>;
  }

  // ─── MARKET PRICES ────────────────────────────────────────────────────────

  // Ask Claude for current Tanzania crop prices, return list of price objects
  static Future<List<Map<String, dynamic>>> fetchLiveMarketPrices() async {
    final prompt = '''
You are a Tanzania agricultural market expert with access to data from
Wizara ya Kilimo (Ministry of Agriculture), TanTrade, and regional markets.

Provide CURRENT approximate wholesale market prices for major crops in Tanzania.
Use today's seasonal context. Return ONLY valid JSON array, no other text:

[
  {
    "crop_name": "Mahindi",
    "market_name": "Kariakoo - Dar es Salaam",
    "price_tzs_kg": 450,
    "trend": "stable",
    "source": "Wizara ya Kilimo / TanTrade"
  }
]

Include ALL these crops: Mahindi, Nyanya, Maharagwe, Pilipili hoho, Ndizi,
Mchele, Muhogo, Pamba, Alizeti, Viazi vitamu, Vitunguu, Karoti

Include ALL these markets: Kariakoo (Dar es Salaam), Arusha Central Market,
Mbeya Market, Morogoro Market, Dodoma Market, Mwanza Market

Trend values: "inapanda" (rising), "inashuka" (falling), "imara" (stable)
Prices must be realistic TZS per kg wholesale prices for Tanzania 2025.
''';

    try {
      final data = await _invokeClaude({
        'model': _model,
        'max_tokens': 2048,
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
      });
      final content = data['content'][0]['text'] as String;
      final clean =
          content.replaceAll('```json', '').replaceAll('```', '').trim();
      final list = jsonDecode(clean) as List;
      final prices = list.cast<Map<String, dynamic>>();
      await _cachePricesToSupabase(prices);
      return prices;
    } catch (e) {
      debugPrint('DataSyncService prices error: $e');
    }

    // Fallback: load from Supabase cache
    return _loadPricesFromSupabase();
  }

  // Save Claude prices to Supabase market_prices table
  static Future<void> _cachePricesToSupabase(
      List<Map<String, dynamic>> prices) async {
    try {
      for (final p in prices) {
        await _db.from('market_prices').upsert({
          'crop_name': p['crop_name'],
          'market_name': p['market_name'],
          'price_tzs_kg': p['price_tzs_kg'],
          'trend': p['trend'] ?? 'imara',
          'source': p['source'] ?? 'Claude AI / Wizara ya Kilimo',
          'price_date': DateTime.now().toIso8601String().substring(0, 10),
        });
      }
    } catch (e) {
      debugPrint('Cache prices error: $e');
    }
  }

  // Load cached prices from Supabase
  static Future<List<Map<String, dynamic>>> _loadPricesFromSupabase() async {
    try {
      final response = await _db
          .from('market_prices')
          .select()
          .order('crop_name')
          .limit(100);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  // ─── PESTICIDES / HERBICIDES / BIOPESTICIDES ──────────────────────────────

  // Ask Claude for TFDA/TPRI registered Tanzania pesticides
  static Future<List<Map<String, dynamic>>> fetchPesticidesDatabase() async {
    final prompt = '''
You are a Tanzania pesticide regulatory expert with complete knowledge of
TFDA (Tanzania Food and Drugs Authority) and TPRI (Tropical Pesticides Research
Institute) registered agrochemicals approved for use in Tanzania.

Return a comprehensive JSON array of registered pesticides, herbicides,
fungicides, and biopesticides available to smallholder farmers in Tanzania.
Return ONLY valid JSON, no other text:

[
  {
    "brand_name": "Coragen 20SC",
    "active_ingredient": "Chlorantraniliprole 200g/L",
    "category": "Insecticide",
    "target_pests": "Fall Armyworm, Stem borers",
    "target_crops": "Mahindi, Mpunga",
    "dose_per_15L": "20ml",
    "phi_days": 14,
    "tpri_registered": true,
    "price_range_tzs": "15000-20000 kwa lita 1",
    "manufacturer": "FMC Corporation",
    "description_sw": "Dawa ya kuua viwavi na wadudu wanaochimba shina",
    "safety_sw": "Vaa glovu na barakoa wakati wa kupulizia"
  }
]

Categories must be EXACTLY one of: "Insecticide", "Fungicide", "Herbicide", "Biopesticide"

Include at least:
- 8 Insecticides (including for Fall Armyworm, aphids, whitefly, thrips)
- 6 Fungicides (including for late blight, early blight, grey mould)
- 6 Herbicides (pre-emergent and post-emergent for maize, rice, vegetables)
- 5 Biopesticides (Bt, neem, Beauveria, Trichoderma, spinosad)

All must be products actually registered and available in Tanzania.
All description_sw and safety_sw must be in Swahili.
''';

    try {
      final data = await _invokeClaude({
        'model': _model,
        'max_tokens': 4096,
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
      });
      final content = data['content'][0]['text'] as String;
      final clean =
          content.replaceAll('```json', '').replaceAll('```', '').trim();
      final list = jsonDecode(clean) as List;
      return list.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('DataSyncService pesticides error: $e');
    }
    return [];
  }

  // ─── AGROVETS ─────────────────────────────────────────────────────────────

  // Swahili labels for category keys stored in agrovets.categories[]
  static const Map<String, String> _categorySw = {
    'fertilizer': 'Mbolea',
    'seeds': 'Mbegu',
    'pesticides': 'Viuatilifu',
    'crop_buying': 'Kununua Mazao',
    'equipment': 'Vifaa',
    'veterinary': 'Mifugo',
    'advisory': 'Ushauri',
  };

  // Fetch REAL verified agrovets from the database (replaces the previous
  // AI-generated list, which invented shops and phone numbers). Returns empty
  // if none are loaded yet — we never fabricate entries.
  static Future<List<Map<String, dynamic>>> fetchAgrovets(
      String region) async {
    try {
      final rows = await _db
          .from('agrovets')
          .select()
          .eq('is_verified', true)
          .eq('region', region)
          .order('name')
          .timeout(const Duration(seconds: 8));

      return (rows as List).map((r) {
        final cats = (r['categories'] as List?)?.cast<String>() ?? const [];
        final products =
            cats.map((c) => _categorySw[c] ?? c).join(', ');
        return <String, dynamic>{
          'shop_name': r['name'],
          'region': r['region'],
          'area': r['ward'] ?? r['district'] ?? '',
          'phone': r['phone'] ?? '',
          'products': products,
          'verified': r['is_verified'] == true,
        };
      }).toList();
    } catch (e) {
      debugPrint('DataSyncService agrovets error: $e');
    }
    return [];
  }

  // ─── TOSCI SEED VARIETIES ─────────────────────────────────────────────────

  // Maps Swahili crop names (used in the UI) to English keys in seed_varieties table
  static const Map<String, String> _cropSwToEn = {
    'Mahindi': 'maize',       'Mchele': 'rice',         'Ngano': 'wheat',
    'Mtama': 'sorghum',       'Uwele': 'millet',        'Ulezi': 'finger millet',
    'Shayiri': 'barley',      'Maharagwe': 'beans',     'Choroko': 'cowpea',
    'Karanga': 'groundnut',   'Soya': 'soybean',        'Mbaazi': 'pigeon pea',
    'Kunde': 'cowpea',        'Nyanya': 'tomato',       'Kabichi': 'cabbage',
    'Sukuma wiki': 'kale',    'Vitunguu': 'onion',      'Pilipili hoho': 'pepper',
    'Pilipili manga': 'pepper','Karoti': 'carrot',       'Bamia': 'okra',
    'Tango': 'cucumber',      'Mchicha': 'spinach',     'Tikiti maji': 'watermelon',
    'Njegere': 'peas',        'Maharage ya Kata': 'beans',
    'Muhogo': 'cassava',      'Viazi vitamu': 'sweet potato', 'Viazi': 'potato',
    'Ndizi': 'banana',        'Embe': 'mango',          'Papai': 'papaya',
    'Nanasi': 'pineapple',    'Avokado': 'avocado',     'Marakuja': 'passion fruit',
    'Pamba': 'cotton',        'Alizeti': 'sunflower',   'Kahawa': 'coffee',
    'Chai': 'tea',            'Korosho': 'cashew',      'Miwa': 'sugarcane',
    'Tumbaku': 'tobacco',
  };

  // Cached copy of the bundled TOSCI dataset (1,199 varieties)
  static List<Map<String, dynamic>>? _bundledSeeds;

  // Fetch TOSCI seed varieties — Supabase first, bundled asset offline fallback
  static Future<List<Map<String, dynamic>>> fetchSeedVarieties({
    required String cropName,
  }) async {
    // Map Swahili crop name to English key used in the database
    final enKey = _cropSwToEn[cropName] ?? cropName.toLowerCase();

    // Primary: Supabase seed_varieties table
    try {
      final res = await _db
          .from('seed_varieties')
          .select()
          .or('crop_type_en.eq.$enKey,crop_type_sw.ilike.%$cropName%')
          .order('variety_name')
          .limit(300);

      final rows = (res as List).cast<Map<String, dynamic>>();
      if (rows.isNotEmpty) {
        return rows.map((r) => _mapSeedRow(r, cropName)).toList();
      }
    } catch (e) {
      debugPrint('DataSyncService.fetchSeedVarieties error: $e');
    }

    // Fallback: bundled TOSCI dataset (works fully offline)
    return _seedsFromBundle(cropName, enKey);
  }

  // Load + filter the bundled TOSCI dataset shipped with the app
  static Future<List<Map<String, dynamic>>> _seedsFromBundle(
      String cropName, String enKey) async {
    try {
      if (_bundledSeeds == null) {
        final raw = await rootBundle
            .loadString('assets/data/tosci_seed_varieties.json');
        _bundledSeeds =
            (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      }
      final cropLower = cropName.toLowerCase();
      return _bundledSeeds!
          .where((r) =>
              r['crop_type_en'] == enKey ||
              (r['crop_type_sw'] as String? ?? '')
                  .toLowerCase()
                  .contains(cropLower))
          .map((r) => _mapSeedRow(r, cropName))
          .toList();
    } catch (e) {
      debugPrint('DataSyncService bundled seeds error: $e');
      return [];
    }
  }

  // Map a TOSCI DB/asset row to the shape the seed card widget expects
  static Map<String, dynamic> _mapSeedRow(
      Map<String, dynamic> r, String cropName) {
    final droughtBool = r['drought_tolerant'];
    final String droughtTol = droughtBool == true
        ? 'high'
        : droughtBool == false
            ? 'low'
            : 'medium';

    // Yield: prefer grain_yield_min (from TOSCI detail), fallback kg/acre
    double? yieldTonHa;
    final grainYieldMin = r['grain_yield_min'];
    final yieldKg = r['yield_kg_per_acre'];
    if (grainYieldMin != null) {
      yieldTonHa = (grainYieldMin as num).toDouble();
    } else if (yieldKg != null) {
      yieldTonHa = (yieldKg as num).toDouble() * 0.00247;
    }

    // Regions: prefer suitable_regions (TOSCI detail), fallback recommended_regions
    final regionsSuitable = r['suitable_regions'];
    final regionsOld = r['recommended_regions'];
    final List<String> regionList = regionsSuitable is List
        ? regionsSuitable.cast<String>()
        : regionsOld is List
            ? regionsOld.cast<String>()
            : <String>[];

    // Disease resistant: stored as List or null
    final dis = r['disease_resistant'];
    final List<String> disList =
        dis is List ? dis.cast<String>() : <String>[];

    // Company: prefer registrant (TOSCI), fallback breeder
    final company = (r['registrant'] as String?)?.isNotEmpty == true
        ? r['registrant']
        : r['breeder'] ?? '';

    return {
      'variety_name':           r['variety_name'] ?? '',
      'crop':                   cropName,
      'company':                company,
      'tosci_certified':        r['tosci_certified'] ?? true,
      'maturity_days':          r['maturity_days'],
      'yield_potential_ton_ha': yieldTonHa != null
          ? double.parse(yieldTonHa.toStringAsFixed(1))
          : null,
      'drought_tolerance':      droughtTol,
      'disease_resistance':     disList,
      'pest_resistance':        <String>[],
      'regions_recommended':    regionList,
      'source_url':             r['source_url'] ?? '',
      'category':               'OPV',
      'description_sw':         r['distinctive_characters'] as String? ?? '',
      'special_attributes':     r['special_attributes'] as String? ?? '',
      'best_for_sw':            '',
      'altitude_range_m':       r['altitude_range'] as String? ?? '',
      'year_released':          r['registration_year'],
      'grain_yield':            r['grain_yield'],
      'detail_url':             r['detail_url'],
      'crop_scientific':        r['crop_scientific'],
    };
  }
}

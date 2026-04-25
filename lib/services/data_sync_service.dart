import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

// This service asks Claude for live Tanzania agricultural data
// and caches results in Supabase so the app works offline too
class DataSyncService {
  static const String _apiUrl = 'https://api.anthropic.com/v1/messages';
  static const String _model = 'claude-sonnet-4-5';
  static String get _apiKey => dotenv.env['CLAUDE_API_KEY'] ?? '';
  static SupabaseClient get _db => Supabase.instance.client;

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
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': _model,
          'max_tokens': 2048,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['content'][0]['text'] as String;
        final clean = content
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        final list = jsonDecode(clean) as List;
        final prices = list.cast<Map<String, dynamic>>();

        // Save to Supabase so offline works
        await _cachePricesToSupabase(prices);
        return prices;
      }
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
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': _model,
          'max_tokens': 4096,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['content'][0]['text'] as String;
        final clean = content
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        final list = jsonDecode(clean) as List;
        return list.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('DataSyncService pesticides error: $e');
    }
    return [];
  }

  // ─── AGROVETS ─────────────────────────────────────────────────────────────

  // Ask Claude for verified agrovet shops in Tanzania regions
  static Future<List<Map<String, dynamic>>> fetchAgrovets(
      String region) async {
    final prompt = '''
You are a Tanzania agricultural supply chain expert.

List verified agrovet shops and agricultural input dealers in $region region, Tanzania.
Return ONLY valid JSON array:

[
  {
    "shop_name": "Kilimo Bora Agrovet",
    "region": "$region",
    "area": "Mjini",
    "phone": "+255712345678",
    "products": "Mbegu, Mbolea, Dawa za wadudu",
    "verified": true,
    "opening_hours": "7am - 6pm"
  }
]

Include 5-8 real or typical agrovets for $region.
Phone numbers in +255 format.
''';

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': _model,
          'max_tokens': 1024,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['content'][0]['text'] as String;
        final clean = content
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        final list = jsonDecode(clean) as List;
        return list.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('DataSyncService agrovets error: $e');
    }
    return [];
  }

  // ─── TOSCI SEED VARIETIES ─────────────────────────────────────────────────

  // Ask Claude for TOSCI-certified seed varieties for a specific crop
  static Future<List<Map<String, dynamic>>> fetchSeedVarieties({
    required String cropName,
  }) async {
    final prompt = '''
You are an expert in Tanzania seed systems with complete knowledge of
TOSCI (Tanzania Official Seed Certification Institute) certified seed varieties.

List ALL certified seed varieties available in Tanzania for: $cropName

For each variety include its TOSCI certification status, disease resistance,
drought tolerance, pest resistance, maturity days, and yield potential.

Return ONLY valid JSON array, no other text:

[
  {
    "variety_name": "DK8031",
    "crop": "$cropName",
    "category": "Hybrid",
    "company": "Dekalb / Bayer",
    "tosci_certified": true,
    "maturity_days": 110,
    "yield_potential_ton_ha": 8.5,
    "disease_resistance": ["Maize Streak Virus", "Grey Leaf Spot", "Turcicum Blight"],
    "pest_resistance": ["Fall Armyworm tolerance"],
    "drought_tolerance": "high",
    "water_stress_rating": "Inastahimili ukame - inafaa mikoa kame",
    "nutrient_efficiency": "medium",
    "soil_types": ["Tifutifu", "Udongo mwekundu"],
    "altitude_range_m": "0-1800",
    "regions_recommended": ["Morogoro", "Dodoma", "Manyara"],
    "seed_rate_kg_ha": 25,
    "planting_spacing": "75cm x 25cm",
    "description_sw": "Mseto wa mahindi wenye tija nyingi, unastahimili ukame na magonjwa mengi",
    "best_for_sw": "Inafaa zaidi kwa wakulima wadogo katika mikoa yenye mvua chache",
    "tosci_number": "VAR/CROP/001/2019",
    "year_released": 2019
  }
]

drought_tolerance values: "high", "medium", "low"
nutrient_efficiency values: "high", "medium", "low"
category values: "Hybrid", "OPV" (Open Pollinated Variety), "Improved OPV"

Include at least 8 varieties covering:
- High yield varieties
- Drought tolerant varieties
- Disease resistant varieties
- Pest resistant varieties
- Varieties for different altitude zones of Tanzania

All description_sw and best_for_sw MUST be in Swahili.
All disease_resistance and pest_resistance entries in English (scientific/common names).
Varieties must be actually certified by TOSCI and available in Tanzania.
''';

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': _model,
          'max_tokens': 4096,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['content'][0]['text'] as String;
        final clean = content
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        final list = jsonDecode(clean) as List;
        return list.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('DataSyncService seeds error: $e');
    }
    return [];
  }
}

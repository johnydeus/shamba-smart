import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ClaudeService {
  // Claude API endpoint
  static const String _apiUrl = 'https://api.anthropic.com/v1/messages';
  static const String _model = 'claude-sonnet-4-5';

  // Read API key safely from .env file
  static String get _apiKey => dotenv.env['CLAUDE_API_KEY'] ?? '';

  // Analyse a photo — handles disease, weed, or insect pest detection
  static Future<Map<String, dynamic>> analyseLeafPhoto({
    required File imageFile,
    required String cropName,
    String scanType = 'ugonjwa', // 'ugonjwa' | 'magugu' | 'wadudu'
  }) async {
    final imageBytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(imageBytes);

    final extension = imageFile.path.split('.').last.toLowerCase();
    final mediaType = extension == 'png' ? 'image/png' : 'image/jpeg';

    final prompt = _buildPhotoPrompt(cropName, scanType);

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
            {
              'role': 'user',
              'content': [
                {
                  'type': 'image',
                  'source': {
                    'type': 'base64',
                    'media_type': mediaType,
                    'data': base64Image,
                  },
                },
                {
                  'type': 'text',
                  'text': prompt,
                },
              ],
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['content'][0]['text'] as String;

        // Remove any markdown code fences Claude might add
        final cleanJson = content
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();

        return jsonDecode(cleanJson) as Map<String, dynamic>;
      } else {
        return {
          'error': true,
          'message': 'Hitilafu ya mtandao. Jaribu tena.',
          'is_healthy': false,
        };
      }
    } catch (e) {
      return {
        'error': true,
        'message': 'Hitilafu: ${e.toString()}',
        'is_healthy': false,
      };
    }
  }

  // Build the correct prompt based on what the farmer is scanning for
  static String _buildPhotoPrompt(String cropName, String scanType) {
    const jsonTemplate = '''
{
  "disease_name_en": "English name",
  "disease_name_sw": "Jina kwa Kiswahili",
  "confidence": 0.0,
  "severity": "low or medium or high or critical",
  "affected_crop": "cropName",
  "description_sw": "Maelezo kwa Kiswahili",
  "immediate_action_sw": "Hatua ya haraka kwa Kiswahili",
  "pesticide_1_name": "Jina la dawa",
  "pesticide_1_dose": "Kipimo kwa dumu la lita 15",
  "pesticide_1_type": "chemical or organic or herbicide or insecticide",
  "pesticide_2_name": "Dawa ya pili au Hakuna",
  "pesticide_2_dose": "Kipimo kwa dumu la lita 15",
  "pesticide_2_type": "chemical or organic or herbicide or insecticide",
  "days_until_critical": 0,
  "is_healthy": false
}''';

    if (scanType == 'magugu') {
      return '''
You are an expert weed scientist specialising in East African smallholder farming in Tanzania.
A farmer has photographed a plant growing in or near their $cropName field.

Identify the weed in the image and respond ONLY with a valid JSON object — no other text:

$jsonTemplate

Rules:
- disease_name_sw = weed name in Swahili (e.g. "Striga / Mgalagala")
- disease_name_en = scientific name of the weed
- description_sw = brief description of the weed and why it is harmful
- immediate_action_sw = exactly how to remove or control this weed RIGHT NOW
- pesticide_1_name = the correct herbicide registered in Tanzania (TPRI) for this weed
- pesticide_1_type must be "herbicide"
- pesticide_2_name = second herbicide option or alternative organic method
- If no weed is visible (just crop), set is_healthy to true
- confidence = 0.0 to 1.0
- severity = how badly it will harm the crop if left untreated
- All Swahili fields must be in simple Swahili
''';
    }

    if (scanType == 'wadudu') {
      return '''
You are an expert entomologist specialising in crop pest management for East African smallholder farmers in Tanzania.
A farmer has photographed damage or an insect on their $cropName crop.

Identify the insect pest in the image and respond ONLY with a valid JSON object — no other text:

$jsonTemplate

Rules:
- disease_name_sw = pest name in Swahili (e.g. "Viwavi wa Jeshi", "Inzi Weupe")
- disease_name_en = scientific name of the pest
- description_sw = brief description of the pest, how it feeds, and what damage it causes
- immediate_action_sw = exactly what the farmer must do TODAY to stop this pest
- pesticide_1_name = the best insecticide registered in Tanzania (TPRI) for this pest
- pesticide_1_type must be "insecticide"
- pesticide_2_name = second option (organic/biopesticide preferred as alternative)
- If no pest damage is visible, set is_healthy to true
- confidence = 0.0 to 1.0
- severity = how urgently the farmer must act (low/medium/high/critical)
- Mark is_healthy false even for early-stage infestations
- All Swahili fields must be in simple Swahili understandable by a rural farmer
''';
    }

    // Default: disease scan (ugonjwa)
    return '''
You are an expert agricultural pathologist specialising in East African smallholder farming.
A farmer in Tanzania has photographed this leaf from their $cropName crop.

Analyse the image carefully and respond ONLY with a valid JSON object — no other text:

$jsonTemplate

Rules:
- Only recommend pesticides/fungicides registered in Tanzania (TPRI)
- All description fields must be in Swahili
- confidence must be a decimal between 0.0 and 1.0
- If the leaf looks healthy, set is_healthy to true
- pesticide_1_type = "fungicide" for fungal diseases, "bactericide" for bacterial
''';
  }

  // Explain a Plant.id disease/pest diagnosis in Swahili with Tanzania context
  static Future<Map<String, dynamic>> explainDiagnosisInSwahili({
    required String cropName,
    required String scanType,
    required String diseaseName,
    required double confidence,
    required String description,
    required String chemicalTreatment,
    required String biologicalTreatment,
    required String prevention,
    String? mkulimaContext,
    String? region,
  }) async {
    const jsonTemplate = '''
{
  "disease_name_en": "English name",
  "disease_name_sw": "Jina kwa Kiswahili",
  "confidence": 0.0,
  "severity": "low or medium or high or critical",
  "affected_crop": "cropName",
  "description_sw": "Maelezo kwa Kiswahili",
  "immediate_action_sw": "Hatua ya haraka kwa Kiswahili",
  "pesticide_1_name": "Jina la dawa iliyosajiliwa Tanzania",
  "pesticide_1_dose": "Kipimo kwa dumu la lita 15",
  "pesticide_1_type": "fungicide or bactericide or insecticide or organic",
  "pesticide_2_name": "Dawa ya pili au Hakuna",
  "pesticide_2_dose": "Kipimo au Hakuna",
  "pesticide_2_type": "fungicide or bactericide or insecticide or organic",
  "days_until_critical": 0,
  "is_healthy": false
}''';

    final typeLabel = scanType == 'wadudu' ? 'mdudu/wadudu' : 'ugonjwa';
    final regionLine = region != null && region.isNotEmpty
        ? 'Farmer region: $region (Tanzania)\n'
        : '';
    final mkulimaLine = mkulimaContext != null && mkulimaContext.isNotEmpty
        ? '\nOn-device Mkulima AI pre-scan (use to cross-check and enrich advice):\n$mkulimaContext\n'
        : '';
    final prompt = '''
You are an agricultural advisor for smallholder farmers in Tanzania.
${regionLine}Plant.id (a specialized agricultural vision AI) has identified the following $typeLabel on a $cropName crop:

Identified: $diseaseName
Confidence: ${(confidence * 100).toStringAsFixed(0)}%
Description: $description
Chemical treatment options: $chemicalTreatment
Biological/organic treatment: $biologicalTreatment
Prevention: $prevention
$mkulimaLine
Use this information to generate region-specific advice for a Tanzanian farmer. Respond ONLY with a valid JSON object:

$jsonTemplate

Rules:
- confidence: use ${confidence.toStringAsFixed(2)}
- affected_crop: "$cropName"
- disease_name_sw: translate/localize the disease name to Swahili
- description_sw: explain in simple Swahili what this disease/pest is and what damage it causes
- immediate_action_sw: what the farmer must do TODAY, in simple Swahili
- Only recommend pesticides/fungicides registered in Tanzania (TPRI list)
- Use the provided treatment info as a guide but adapt to products available in Tanzania
- severity: estimate how urgent this is (low/medium/high/critical)
- days_until_critical: how many days before irreversible crop loss if untreated (0 = unknown)
- is_healthy: false
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
            {'role': 'user', 'content': prompt},
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['content'][0]['text'] as String;
        final cleanJson =
            content.replaceAll('```json', '').replaceAll('```', '').trim();
        return jsonDecode(cleanJson) as Map<String, dynamic>;
      }
      return {
        'error': true,
        'message': 'Hitilafu ya mtandao. Jaribu tena.',
        'is_healthy': false,
      };
    } catch (e) {
      return {
        'error': true,
        'message': 'Hitilafu: ${e.toString()}',
        'is_healthy': false,
      };
    }
  }

  // Explain a Plant.id weed identification in Swahili with Tanzania context
  static Future<Map<String, dynamic>> explainWeedInSwahili({
    required String cropName,
    required String weedScientificName,
    required List<String> weedCommonNames,
    required double confidence,
    required String description,
    String? region,
  }) async {
    const jsonTemplate = '''
{
  "disease_name_en": "Scientific name of weed",
  "disease_name_sw": "Jina la gugu kwa Kiswahili",
  "confidence": 0.0,
  "severity": "low or medium or high or critical",
  "affected_crop": "cropName",
  "description_sw": "Maelezo ya gugu na madhara yake kwa Kiswahili",
  "immediate_action_sw": "Jinsi ya kuondoa/kudhibiti gugu hili SASA kwa Kiswahili",
  "pesticide_1_name": "Herbicide iliyosajiliwa Tanzania (TPRI)",
  "pesticide_1_dose": "Kipimo kwa dumu la lita 15",
  "pesticide_1_type": "herbicide",
  "pesticide_2_name": "Mbinu ya pili ya kikaboni au Hakuna",
  "pesticide_2_dose": "Maelezo ya matumizi au Hakuna",
  "pesticide_2_type": "organic or herbicide",
  "days_until_critical": 0,
  "is_healthy": false
}''';

    final commonNamesStr =
        weedCommonNames.isNotEmpty ? weedCommonNames.join(', ') : 'unknown';
    final prompt = '''
You are a weed scientist and agricultural advisor for smallholder farmers in Tanzania.
Plant.id (a specialized plant identification AI) has identified a weed in a $cropName field:

Scientific name: $weedScientificName
Common names: $commonNamesStr
Confidence: ${(confidence * 100).toStringAsFixed(0)}%
Description: $description

Use this information to advise a Tanzanian farmer. Respond ONLY with a valid JSON object:

$jsonTemplate

Rules:
- confidence: use ${confidence.toStringAsFixed(2)}
- affected_crop: "$cropName"
- disease_name_sw: the weed's Swahili or local name (e.g. "Striga / Mgalagala"), or transliteration
- description_sw: explain in simple Swahili what this weed is, how it competes with $cropName, and the harm it causes
- immediate_action_sw: practical steps to remove or control this weed TODAY
- pesticide_1_name: the correct herbicide registered in Tanzania (TPRI) for this weed type
- pesticide_1_type must be "herbicide"
- pesticide_2_name: organic/manual alternative or second herbicide option
- severity: how much will this weed harm the $cropName crop if left untreated
- days_until_critical: estimated days until yield loss becomes significant (0 = unknown)
- is_healthy: false
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
            {'role': 'user', 'content': prompt},
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['content'][0]['text'] as String;
        final cleanJson =
            content.replaceAll('```json', '').replaceAll('```', '').trim();
        return jsonDecode(cleanJson) as Map<String, dynamic>;
      }
      return {
        'error': true,
        'message': 'Hitilafu ya mtandao. Jaribu tena.',
        'is_healthy': false,
      };
    } catch (e) {
      return {
        'error': true,
        'message': 'Hitilafu: ${e.toString()}',
        'is_healthy': false,
      };
    }
  }

  // Diagnose by text symptoms (no photo needed — for offline/text-only situations)
  static Future<Map<String, dynamic>> diagnoseBySymptoms({
    required String cropName,
    required String symptomsDescription,
    String region = 'Tanzania',
  }) async {
    final prompt = '''
Wewe ni mtaalamu wa kilimo wa Tanzania anayejua magonjwa, wadudu, magugu na matatizo yote ya mazao.

Mkulima kutoka $region anaelezea tatizo lake kwenye zao la $cropName:
"$symptomsDescription"

Changanua maelezo haya kwa makini na jibu ONLY kwa JSON hii (hakuna maandishi mengine):

{
  "threat_type": "ugonjwa au wadudu au magugu au lishe au hali_ya_hewa",
  "disease_name_en": "Jina la kisayansi au la Kiingereza",
  "disease_name_sw": "Jina kwa Kiswahili",
  "confidence": 0.0,
  "severity": "low au medium au high au critical",
  "affected_crop": "$cropName",
  "description_sw": "Maelezo mafupi ya tatizo kwa Kiswahili",
  "immediate_action_sw": "Hatua ya HARAKA kufanya SASA kwa Kiswahili",
  "pesticide_1_name": "Jina la dawa inayofaa (au 'Hakuna' kama si wadudu/ugonjwa)",
  "pesticide_1_dose": "Kipimo kwa dumu la lita 15",
  "pesticide_1_type": "chemical au organic au none",
  "pesticide_2_name": "Dawa ya pili au 'Hakuna'",
  "pesticide_2_dose": "Kipimo kwa dumu la lita 15",
  "pesticide_2_type": "chemical au organic au none",
  "prevention_sw": "Jinsi ya kuzuia tatizo hili mara ya pili kwa Kiswahili",
  "days_until_critical": 0,
  "is_healthy": false
}

Kanuni:
- Pendekeza tu dawa zilizosajiliwa Tanzania (TPRI/TFDA)
- Kama ni magugu: andika herbicide inayofaa na wakati wa kupuliza
- Kama ni nzige/wadudu mkubwa: andika HATUA ZA DHARURA kwanza
- Kama ni upungufu wa virutubisho: pendekeza mbolea sahihi
- confidence ni nambari kati ya 0.0 na 1.0
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
            {'role': 'user', 'content': prompt},
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['content'][0]['text'] as String;
        final cleanJson = content
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        return jsonDecode(cleanJson) as Map<String, dynamic>;
      } else {
        return {
          'error': true,
          'message': 'Hitilafu ya mtandao. Jaribu tena.',
          'is_healthy': false,
        };
      }
    } catch (e) {
      return {
        'error': true,
        'message': 'Hitilafu: ${e.toString()}',
        'is_healthy': false,
      };
    }
  }

  // Generate irrigation advice based on soil + weather context
  static Future<String> generateIrrigationAdvice({
    required Map<String, dynamic> soilData,
    required Map<String, dynamic> weatherData,
    required String cropName,
    required String growthStage,
    required double farmAcres,
  }) async {
    final prompt = '''
Wewe ni mtaalamu wa umwagiliaji wa kilimo Tanzania.

Taarifa za shamba:
- Zao: $cropName (hatua ya ukuaji: $growthStage)
- Ukubwa wa shamba: $farmAcres ekari
- Hali ya udongo: pH=${soilData['ph'] ?? 'haijulikani'}, Nitrogen=${soilData['nitrogen'] ?? 'haijulikani'}, Texture=${soilData['texture'] ?? 'haijulikani'}
- Hali ya hewa: Joto=${weatherData['temperature'] ?? 27}°C, Unyevu=${weatherData['humidity'] ?? 65}%, Upepo=${weatherData['wind_speed'] ?? 8}km/h, Mvua=${weatherData['rain_probability'] ?? 20}%

Toa ushauri wa umwagiliaji kwa Kiswahili rahisi:
1. Kiasi cha maji kinachohitajika kwa siku (lita)
2. Nyakati nzuri za kumwagilia
3. Dalili za kukosa au kuzidi maji
4. Onyo lolote kuhusu hali ya hewa ya leo

Jibu kwa maneno mafupi yanayofaa simu (si zaidi ya mistari 8).
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
          'max_tokens': 400,
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['content'][0]['text'] as String;
      }
    } catch (_) {}

    return 'Mwagilia $cropName asubuhi (6am–8am) ili kupunguza uvukizi.\n'
        'Kiasi: karibu lita ${(farmAcres * 1000).round()} kwa siku moja.\n'
        'Dalili za kukosa maji: majani kunyauka mchana.';
  }

  // Ask Claude a farming question in Swahili — used in the Expert Forum
  static Future<String> askFarmingQuestion({
    required String question,
    required String cropContext,
    required String regionContext,
  }) async {
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
          'max_tokens': 512,
          'system':
              'You are a helpful agricultural advisor for smallholder farmers in Tanzania. '
              'Always respond in simple Swahili. '
              'The farmer grows $cropContext in $regionContext. '
              'Give practical, affordable advice. '
              'Only recommend products available in Tanzania.',
          'messages': [
            {
              'role': 'user',
              'content': question,
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['content'][0]['text'] as String;
      } else {
        return 'Samahani, kuna hitilafu. Jaribu tena baadaye.';
      }
    } catch (e) {
      return 'Hitilafu ya mtandao: ${e.toString()}';
    }
  }

  // Generate full crop advisory from soil data — used in Soil screen
  static Future<String> getCropAdvisory({
    required double ph,
    required String texture,
    required double? nitrogen,
    required double? organicCarbon,
    required String region,
    required double lat,
    required double lng,
  }) async {
    final nText  = nitrogen     != null ? '${nitrogen.toStringAsFixed(2)} g/kg' : 'haijapimwa';
    final socText = organicCarbon != null ? '${organicCarbon.toStringAsFixed(1)} g/kg' : 'haijapimwa';

    final prompt = '''
Mkulima kutoka eneo la $region (GPS: $lat, $lng) ana data hii ya udongo:
- pH ya udongo: $ph
- Muundo wa udongo (Texture): $texture
- Nitrojeni (N): $nText
- Kaboni ya Udongo (SOC): $socText

Toa ushauri kamili wa kilimo kwa lugha ya Kiswahili rahisi ukijumuisha:

1. 🌱 MAZAO BORA (orodha mazao 5 yanayofaa udongo huu na mkoa huu wa Tanzania)
2. 📅 RATIBA YA KILIMO (miezi ya kupanda, kupalilia, na kuvuna kwa kila zao kuu)
3. 🌧️ MVUA NA MSIMU (misimu ya mvua inayotarajiwa maeneo hayo na jinsi ya kuitumia)
4. 💧 UMWAGILIAJI (kama mvua haitoshi, zao lipi linahitaji umwagiliaji na mara ngapi)
5. 🌿 MATAYARISHO YA SHAMBA (jinsi ya kuandaa udongo huu kabla ya kupanda)
6. ⚠️ TAHADHARI (mambo ya kuangalia kulingana na hali ya udongo huu)

Jibu liwe fupi, la vitendo, na linafaa kwa mkulima mdogo wa Tanzania.
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
          'max_tokens': 1200,
          'system':
              'Wewe ni mtaalamu wa kilimo wa Tanzania mwenye uzoefu wa miaka 20. '
              'Unajua hali ya hewa, udongo, na mazao ya kila mkoa wa Tanzania. '
              'Daima jibu kwa Kiswahili rahisi kinachoeleweka kwa mkulima wa kawaida. '
              'Toa ushauri wa vitendo unaoweza kutekelezwa na mkulima mdogo.',
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['content'][0]['text'] as String;
      }
      return 'Samahani, kuna hitilafu ya kupata ushauri. Jaribu tena.';
    } catch (e) {
      return 'Hitilafu ya mtandao: ${e.toString()}';
    }
  }
}

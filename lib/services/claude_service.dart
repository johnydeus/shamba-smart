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

  // Analyse a leaf photo — returns a Map with disease details
  static Future<Map<String, dynamic>> analyseLeafPhoto({
    required File imageFile,
    required String cropName,
  }) async {
    // Convert the photo file to a base64 text string
    final imageBytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(imageBytes);

    // Detect if image is PNG or JPEG
    final extension = imageFile.path.split('.').last.toLowerCase();
    final mediaType = extension == 'png' ? 'image/png' : 'image/jpeg';

    // The prompt we send to Claude — tells it exactly what to do
    final prompt = '''
You are an expert agricultural pathologist specialising in East African smallholder farming.
A farmer in Tanzania has photographed this leaf from their $cropName crop.

Analyse the image carefully and respond ONLY with a valid JSON object — no other text:

{
  "disease_name_en": "English disease name",
  "disease_name_sw": "Jina la ugonjwa kwa Kiswahili",
  "confidence": 0.0,
  "severity": "low or medium or high or critical",
  "affected_crop": "$cropName",
  "description_sw": "Maelezo mafupi kwa Kiswahili",
  "immediate_action_sw": "Hatua ya haraka kwa Kiswahili",
  "pesticide_1_name": "Brand name of first pesticide",
  "pesticide_1_dose": "Dose per 15L sprayer",
  "pesticide_1_type": "chemical or organic",
  "pesticide_2_name": "Brand name of second pesticide",
  "pesticide_2_dose": "Dose per 15L sprayer",
  "pesticide_2_type": "chemical or organic",
  "days_until_critical": 0,
  "is_healthy": false
}

Rules:
- Only recommend pesticides registered in Tanzania (TPRI)
- All description fields must be in Swahili
- confidence must be a decimal between 0.0 and 1.0
- If the leaf looks healthy, set is_healthy to true
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
}

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_keys.dart';
import 'claude_service.dart';

class PlantIdService {
  // crop.health — disease + pest detection (ugonjwa + wadudu)
  static const String _cropHealthUrl =
      'https://crop.kindwise.com/api/v1/identification';
  // plant.id — plant/weed species identification (magugu)
  static const String _plantIdUrl =
      'https://api.plant.id/v3/identification';

  static Future<Map<String, dynamic>> analysePhoto({
    required File imageFile,
    required String cropName,
    required String scanType,
  }) async {
    if (scanType == 'magugu') {
      if (!ApiKeys.hasPlantId) {
        return {
          'error': true,
          'message':
              'Kugundua magugu kunahitaji plant.id API key. Weka PLANT_ID_KEY kwenye .env',
          'is_healthy': false,
        };
      }
      return _identifyWeed(imageFile, cropName);
    }

    // ugonjwa + wadudu — both use crop.health
    if (!ApiKeys.hasCropHealth) {
      return {
        'error': true,
        'message':
            'CROP_HEALTH_KEY haijasanidiwa. Weka key kwenye .env',
        'is_healthy': false,
      };
    }
    return _detectCropHealth(imageFile, cropName, scanType);
  }

  // ── Disease + Pest detection via crop.health API ──────────────────────────

  static Future<Map<String, dynamic>> _detectCropHealth(
    File imageFile,
    String cropName,
    String scanType,
  ) async {
    final base64Image = await _toBase64(imageFile);

    try {
      final response = await http.post(
        Uri.parse(_cropHealthUrl),
        headers: {
          'Api-Key': ApiKeys.cropHealth,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'images': [base64Image],
          'similar_images': false,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return _parseCropHealthAndExplain(data, cropName, scanType);
      }

      return _apiError(response.statusCode);
    } catch (e) {
      return _networkError(e);
    }
  }

  static Future<Map<String, dynamic>> _parseCropHealthAndExplain(
    Map<String, dynamic> data,
    String cropName,
    String scanType,
  ) async {
    final result = (data['result'] as Map<String, dynamic>?) ?? {};

    final isHealthyMap = result['is_healthy'] as Map<String, dynamic>?;
    final isHealthy = isHealthyMap?['binary'] == true;
    final healthyProb =
        (isHealthyMap?['probability'] as num?)?.toDouble() ?? 0.0;

    if (isHealthy) {
      return {'is_healthy': true, 'confidence': healthyProb};
    }

    final disease = (result['disease'] as Map<String, dynamic>?) ?? {};
    final suggestions = (disease['suggestions'] as List<dynamic>?) ?? [];

    if (suggestions.isEmpty) {
      return {'is_healthy': true, 'confidence': 0.5};
    }

    final top = suggestions[0] as Map<String, dynamic>;
    final diseaseName = (top['name'] as String?) ?? '';
    final probability = (top['probability'] as num?)?.toDouble() ?? 0.0;
    final details = (top['details'] as Map<String, dynamic>?) ?? {};
    final treatment = (details['treatment'] as Map<String, dynamic>?) ?? {};

    return ClaudeService.explainDiagnosisInSwahili(
      cropName: cropName,
      scanType: scanType,
      diseaseName: diseaseName,
      confidence: probability,
      description: (details['description'] as String?) ?? '',
      chemicalTreatment: (treatment['chemical'] as String?) ?? '',
      biologicalTreatment: (treatment['biological'] as String?) ?? '',
      prevention: (treatment['prevention'] as String?) ?? '',
    );
  }

  // ── Weed identification via plant.id API ──────────────────────────────────

  static Future<Map<String, dynamic>> _identifyWeed(
    File imageFile,
    String cropName,
  ) async {
    final base64Image = await _toBase64(imageFile);

    try {
      final response = await http.post(
        Uri.parse(_plantIdUrl),
        headers: {
          'Api-Key': ApiKeys.plantId,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'images': [base64Image],
          'similar_images': false,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return _parseWeedAndExplain(data, cropName);
      }

      return _apiError(response.statusCode);
    } catch (e) {
      return _networkError(e);
    }
  }

  static Future<Map<String, dynamic>> _parseWeedAndExplain(
    Map<String, dynamic> data,
    String cropName,
  ) async {
    final result = (data['result'] as Map<String, dynamic>?) ?? {};

    final isPlantMap = result['is_plant'] as Map<String, dynamic>?;
    if (isPlantMap?['binary'] != true) {
      return {
        'error': true,
        'message':
            'Picha hii haikuonekana kuwa mmea. Piga picha ya gugu wazi zaidi.',
        'is_healthy': false,
      };
    }

    final classification =
        (result['classification'] as Map<String, dynamic>?) ?? {};
    final suggestions =
        (classification['suggestions'] as List<dynamic>?) ?? [];

    if (suggestions.isEmpty) {
      return {
        'error': true,
        'message': 'Mmea haukutambuliwa. Piga picha tena karibu zaidi.',
        'is_healthy': false,
      };
    }

    final top = suggestions[0] as Map<String, dynamic>;
    final plantName = (top['name'] as String?) ?? '';
    final probability = (top['probability'] as num?)?.toDouble() ?? 0.0;
    final details = (top['details'] as Map<String, dynamic>?) ?? {};
    final commonNames =
        ((details['common_names'] as List<dynamic>?) ?? []).cast<String>();
    final descMap = details['description'];
    final description = descMap is Map
        ? ((descMap['value'] as String?) ?? '')
        : (descMap as String?) ?? '';

    return ClaudeService.explainWeedInSwahili(
      cropName: cropName,
      weedScientificName: plantName,
      weedCommonNames: commonNames,
      confidence: probability,
      description: description,
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static Future<String> _toBase64(File imageFile) async {
    final ext = imageFile.path.split('.').last.toLowerCase();
    final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
    final bytes = await imageFile.readAsBytes();
    return 'data:$mime;base64,${base64Encode(bytes)}';
  }

  static Map<String, dynamic> _apiError(int statusCode) => {
        'error': true,
        'message':
            'Kindwise ilirudisha hitilafu ($statusCode). Jaribu tena baadaye.',
        'is_healthy': false,
      };

  static Map<String, dynamic> _networkError(Object e) => {
        'error': true,
        'message': 'Hitilafu ya mtandao: ${e.toString()}',
        'is_healthy': false,
      };
}

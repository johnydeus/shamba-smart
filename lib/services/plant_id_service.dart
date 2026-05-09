import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_keys.dart';

class PlantIdService {
  static const String _cropHealthUrl =
      'https://crop.kindwise.com/api/v1/identification';
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
          'message': 'PLANT_ID_KEY haijasanidiwa kwenye .env',
          'is_healthy': false,
        };
      }
      return _identifyWeed(imageFile, cropName);
    }

    if (!ApiKeys.hasCropHealth) {
      return {
        'error': true,
        'message': 'CROP_HEALTH_KEY haijasanidiwa kwenye .env',
        'is_healthy': false,
      };
    }
    return _detectCropHealth(imageFile, cropName, scanType);
  }

  // ── Disease + Pest via crop.health ────────────────────────────────────────

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
          'details': [
            'description',
            'treatment',
            'cause',
            'common_names',
            'classification',
          ],
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return _parseCropHealth(
          jsonDecode(response.body) as Map<String, dynamic>,
          cropName,
          scanType,
        );
      }
      return _apiError(response.statusCode, response.body);
    } catch (e) {
      return _networkError(e);
    }
  }

  static Map<String, dynamic> _parseCropHealth(
    Map<String, dynamic> data,
    String cropName,
    String scanType,
  ) {
    final result = (data['result'] as Map<String, dynamic>?) ?? {};

    final isHealthyMap = result['is_healthy'] as Map<String, dynamic>?;
    final isHealthy = isHealthyMap?['binary'] == true;
    final healthyProb = (isHealthyMap?['probability'] as num?)?.toDouble() ?? 0.0;

    if (isHealthy) return {'is_healthy': true, 'confidence': healthyProb};

    final suggestions =
        ((result['disease'] as Map?)??{})['suggestions'] as List? ?? [];
    if (suggestions.isEmpty) return {'is_healthy': true, 'confidence': 0.5};

    final top = suggestions[0] as Map<String, dynamic>;
    final diseaseName = (top['name'] as String?) ?? '';
    final probability = (top['probability'] as num?)?.toDouble() ?? 0.0;
    final details = (top['details'] as Map<String, dynamic>?) ?? {};
    final treatment = (details['treatment'] as Map<String, dynamic>?) ?? {};
    final description = (details['description'] as String?) ?? '';
    final chemical = (treatment['chemical'] as String?) ?? '';
    final biological = (treatment['biological'] as String?) ?? '';
    final prevention = (treatment['prevention'] as String?) ?? '';

    final cause = (details['cause'] as String?) ?? '';
    final commonNames =
        ((details['common_names'] as List?) ?? []).cast<String>();

    // Auto-detect if it's a pest based on classification
    final classification =
        ((details['classification'] as List?) ?? []).cast<String>();
    final isPest = classification
        .any((c) => c.toLowerCase().contains('insect') ||
            c.toLowerCase().contains('pest') ||
            c.toLowerCase().contains('arthropod') ||
            c.toLowerCase().contains('mite'));
    final effectiveScanType =
        isPest ? 'wadudu' : scanType;

    return {
      'disease_name_en': diseaseName,
      'disease_name_sw': diseaseName,
      'common_names': commonNames,
      'confidence': probability,
      'severity': _severity(probability),
      'affected_crop': cropName,
      'scan_type': effectiveScanType,
      'description_sw': description.isNotEmpty ? description : '',
      'cause_sw': cause.isNotEmpty ? cause : '',
      'immediate_action_sw': _buildAction(chemical, biological, effectiveScanType),
      'chemical_treatment': chemical,
      'biological_treatment': biological,
      'prevention_treatment': prevention,
      'pesticide_1_name': _firstSentence(chemical),
      'pesticide_1_dose': 'Fuata kipimo kilichoandikwa kwenye dawa',
      'pesticide_1_type': effectiveScanType == 'wadudu' ? 'insecticide' : 'fungicide',
      'pesticide_2_name': biological.isNotEmpty ? _firstSentence(biological) : 'Hakuna',
      'pesticide_2_dose': biological.isNotEmpty ? '' : '',
      'pesticide_2_type': 'organic',
      'days_until_critical': 0,
      'is_healthy': false,
    };
  }

  // ── Weeds via plant.id ────────────────────────────────────────────────────

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
          'details': [
            'common_names',
            'description',
            'taxonomy',
            'treatment',
          ],
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return _parseWeed(
          jsonDecode(response.body) as Map<String, dynamic>,
          cropName,
        );
      }
      return _apiError(response.statusCode, response.body);
    } catch (e) {
      return _networkError(e);
    }
  }

  static Map<String, dynamic> _parseWeed(
    Map<String, dynamic> data,
    String cropName,
  ) {
    final result = (data['result'] as Map<String, dynamic>?) ?? {};

    final isPlant =
        (result['is_plant'] as Map<String, dynamic>?)?['binary'] == true;
    if (!isPlant) {
      return {
        'error': true,
        'message': 'Picha hii haikuonekana kuwa mmea. Piga tena karibu zaidi.',
        'is_healthy': false,
      };
    }

    final suggestions =
        ((result['classification'] as Map?)??{})['suggestions'] as List? ?? [];
    if (suggestions.isEmpty) {
      return {
        'error': true,
        'message': 'Mmea haukutambuliwa. Piga picha tena.',
        'is_healthy': false,
      };
    }

    final top = suggestions[0] as Map<String, dynamic>;
    final plantName = (top['name'] as String?) ?? '';
    final probability = (top['probability'] as num?)?.toDouble() ?? 0.0;
    final details = (top['details'] as Map<String, dynamic>?) ?? {};
    final commonNames =
        ((details['common_names'] as List?) ?? []).cast<String>();
    final descMap = details['description'];
    final description = descMap is Map
        ? ((descMap['value'] as String?) ?? '')
        : (descMap as String?) ?? '';

    final displayName =
        commonNames.isNotEmpty ? '${commonNames.first} ($plantName)' : plantName;

    return {
      'disease_name_en': plantName,
      'disease_name_sw': displayName,
      'confidence': probability,
      'severity': _severity(probability),
      'affected_crop': cropName,
      'description_sw': description.isNotEmpty
          ? description
          : 'Gugu hili linaweza kuathiri mavuno ya $cropName yako.',
      'immediate_action_sw':
          'Ng\'oa gugu hili mapema kabla halijatoa mbegu. '
          'Tumia herbicide inayofaa kwa $cropName — wasiliana na duka la kilimo karibu nawe.',
      'pesticide_1_name': 'Herbicide inayofaa kwa $cropName',
      'pesticide_1_dose': 'Fuata kipimo kilichoandikwa kwenye dawa',
      'pesticide_1_type': 'herbicide',
      'pesticide_2_name': 'Kupalilia kwa mkono au jembe',
      'pesticide_2_dose': 'Kabla halijatoa mbegu',
      'pesticide_2_type': 'organic',
      'days_until_critical': 0,
      'is_healthy': false,
    };
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static String _severity(double prob) {
    if (prob >= 0.80) return 'high';
    if (prob >= 0.55) return 'medium';
    return 'low';
  }

  static String _buildAction(
      String chemical, String biological, String scanType) {
    if (chemical.isNotEmpty) return _firstSentence(chemical);
    if (biological.isNotEmpty) return _firstSentence(biological);
    final label = scanType == 'wadudu' ? 'mdudu' : 'ugonjwa';
    return 'Wasiliana na mtaalamu wa kilimo kuhusu $label huu.';
  }

  static String _firstSentence(String text) {
    if (text.isEmpty) return 'Hakuna';
    final dot = text.indexOf('.');
    final end = dot > 0 && dot < 120 ? dot : text.length.clamp(0, 120);
    return text.substring(0, end).trim();
  }

  static Future<String> _toBase64(File imageFile) async {
    final ext = imageFile.path.split('.').last.toLowerCase();
    final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
    final bytes = await imageFile.readAsBytes();
    return 'data:$mime;base64,${base64Encode(bytes)}';
  }

  static Map<String, dynamic> _apiError(int statusCode, [String? body]) {
    String detail = '';
    if (body != null && body.isNotEmpty) {
      try {
        final decoded = jsonDecode(body) as Map<String, dynamic>;
        detail = ' — ${decoded['description'] ?? decoded['error'] ?? ''}';
      } catch (_) {
        if (body.length < 200) detail = ' — $body';
      }
    }
    return {
      'error': true,
      'message': 'Hitilafu $statusCode$detail.',
      'is_healthy': false,
    };
  }

  static Map<String, dynamic> _networkError(Object e) => {
        'error': true,
        'message': 'Hitilafu ya mtandao: ${e.toString()}',
        'is_healthy': false,
      };
}

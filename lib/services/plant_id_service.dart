import 'dart:convert';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'claude_service.dart';

class PlantIdService {
  static Future<Map<String, dynamic>> analysePhoto({
    required File imageFile,
    required String cropName,
    required String scanType,
    String? mkulimaContext,
    String? region,
  }) async {
    if (scanType == 'magugu') {
      return _identifyWeed(imageFile, cropName, region: region);
    }
    return _detectCropHealth(
      imageFile,
      cropName,
      scanType,
      mkulimaContext: mkulimaContext,
      region: region,
    );
  }

  // ── Disease + Pest detection via crop.health API ──────────────────────────

  static Future<Map<String, dynamic>> _detectCropHealth(
    File imageFile,
    String cropName,
    String scanType, {
    String? mkulimaContext,
    String? region,
  }) async {
    final base64Image = await _toBase64(imageFile);

    try {
      final res = await Supabase.instance.client.functions.invoke(
        'plant-id-proxy',
        body: {
          'service': 'crop_health',
          'images': [base64Image],
          'similar_images': false,
        },
      );

      final data = res.data as Map<String, dynamic>;
      return _parseCropHealthAndExplain(
        data,
        cropName,
        scanType,
        mkulimaContext: mkulimaContext,
        region: region,
      );
    } catch (e) {
      return _networkError(e);
    }
  }

  static Future<Map<String, dynamic>> _parseCropHealthAndExplain(
    Map<String, dynamic> data,
    String cropName,
    String scanType, {
    String? mkulimaContext,
    String? region,
  }) async {
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
      mkulimaContext: mkulimaContext,
      region: region,
    );
  }

  // ── Weed identification via plant.id API ──────────────────────────────────

  static Future<Map<String, dynamic>> _identifyWeed(
    File imageFile,
    String cropName, {
    String? region,
  }) async {
    final base64Image = await _toBase64(imageFile);

    try {
      final res = await Supabase.instance.client.functions.invoke(
        'plant-id-proxy',
        body: {
          'service': 'plant_id',
          'images': [base64Image],
          'similar_images': false,
        },
      );

      final data = res.data as Map<String, dynamic>;
      return _parseWeedAndExplain(data, cropName, region: region);
    } catch (e) {
      return _networkError(e);
    }
  }

  static Future<Map<String, dynamic>> _parseWeedAndExplain(
    Map<String, dynamic> data,
    String cropName, {
    String? region,
  }) async {
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
      region: region,
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static Future<String> _toBase64(File imageFile) async {
    final ext = imageFile.path.split('.').last.toLowerCase();
    final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
    final bytes = await imageFile.readAsBytes();
    return 'data:$mime;base64,${base64Encode(bytes)}';
  }

  static Map<String, dynamic> _networkError(Object e) => {
        'error': true,
        'message': 'Hitilafu ya mtandao: ${e.toString()}',
        'is_healthy': false,
      };
}

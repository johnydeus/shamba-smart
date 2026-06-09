import 'dart:io';
import '../../../services/mkulima_service.dart';

/// Thin wrapper over MkulimaService for the scan analysis pipeline.
class MkulimaEngine {
  static final MkulimaEngine _instance = MkulimaEngine._();
  factory MkulimaEngine() => _instance;
  MkulimaEngine._();

  final MkulimaService _service = MkulimaService();

  Future<void> ensureReady() => _service.initialize();

  Future<MkulimaResult?> analyze(File imageFile) => _service.analyze(imageFile);

  /// Build a diagnosis map from on-device results when cloud is unavailable.
  Map<String, dynamic> diagnosisFromMkulima(
    MkulimaResult result,
    String cropName,
  ) {
    if (result.isHealthy) {
      return {
        'is_healthy': true,
        'confidence': result.confidence,
        'affected_crop': cropName,
        'source': 'mkulima_offline',
      };
    }

    return {
      'disease_name_en': result.jinaEn,
      'disease_name_sw': result.jinaSw,
      'confidence': result.confidence,
      'severity': _ukaliToSeverity(result.ukali),
      'affected_crop': cropName,
      'description_sw': result.dalili,
      'immediate_action_sw': result.hatuaYaHaraka.isNotEmpty
          ? result.hatuaYaHaraka
          : result.dawa,
      'pesticide_1_name': result.dawa,
      'pesticide_1_dose': 'Fuata maelekezo ya duka la pembejeo',
      'pesticide_1_type': 'fungicide',
      'pesticide_2_name': result.dawaAsili.isNotEmpty ? result.dawaAsili : 'Hakuna',
      'pesticide_2_dose': 'Hakuna',
      'pesticide_2_type': 'organic',
      'days_until_critical': result.isUrgent ? 3 : 7,
      'prevention_sw': result.kinga,
      'is_healthy': false,
      'source': 'mkulima_offline',
      'threat_type': 'ugonjwa',
    };
  }

  String _ukaliToSeverity(String ukali) {
    final lower = ukali.toLowerCase();
    if (lower.contains('hatari') || lower.contains('juu sana')) return 'critical';
    if (lower.contains('juu')) return 'high';
    if (lower.contains('wastani')) return 'medium';
    return 'low';
  }
}

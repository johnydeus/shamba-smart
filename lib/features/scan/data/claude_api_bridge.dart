import 'dart:convert';
import 'dart:io';
import '../../../config/api_keys.dart';
import '../../../core/database/app_database.dart';
import '../../../services/claude_service.dart';
import '../../../services/mkulima_service.dart';
import '../../../services/plant_id_service.dart';
import '../../../services/supabase_service.dart';

/// Online enrichment — Plant.id when keys exist, otherwise Claude vision directly.
class ClaudeApiBridge {
  static final ClaudeApiBridge _instance = ClaudeApiBridge._();
  factory ClaudeApiBridge() => _instance;
  ClaudeApiBridge._();

  final AppDatabase _db = AppDatabase();

  bool _hasSpecialistApi(String scanType) => switch (scanType) {
        'magugu' => ApiKeys.hasPlantId && ApiKeys.hasClaude,
        _ => ApiKeys.hasCropHealth && ApiKeys.hasClaude,
      };

  Future<Map<String, dynamic>> enrichOnline({
    required File imageFile,
    required String cropName,
    required String scanType,
    MkulimaResult? mkulimaResult,
    String? region,
  }) async {
    if (!ApiKeys.hasClaude) {
      return {
        'error': true,
        'message': 'CLAUDE_API_KEY haijasanidiwa kwenye .env',
        'is_healthy': false,
      };
    }

    // Prefer Plant.id / crop.health when keys are configured.
    if (_hasSpecialistApi(scanType)) {
      return PlantIdService.analysePhoto(
        imageFile: imageFile,
        cropName: cropName,
        scanType: scanType,
        mkulimaContext: mkulimaResult?.toClaudeContext(),
        region: region,
      );
    }

    // Fallback: Claude vision only (works with CLAUDE_API_KEY alone).
    final diagnosis = await ClaudeService.analyseLeafPhoto(
      imageFile: imageFile,
      cropName: cropName,
      scanType: scanType,
      mkulimaContext: mkulimaResult?.toClaudeContext(),
      region: region,
    );
    diagnosis['source'] = 'claude_vision';
    return diagnosis;
  }

  Future<void> queueEnrichment({
    required String imagePath,
    required String cropName,
    required String scanType,
    Map<String, dynamic>? mkulimaJson,
    double? gpsLat,
    double? gpsLng,
    String? region,
  }) async {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    await _db.enqueueOutbox(
      id: id,
      type: 'scan_enrichment',
      payloadJson: jsonEncode({
        'image_path': imagePath,
        'crop_name': cropName,
        'scan_type': scanType,
        'mkulima_json': mkulimaJson,
        'gps_lat': gpsLat,
        'gps_lng': gpsLng,
        'region': region,
      }),
    );
  }

  Future<bool> processOutboxItem(Map<String, dynamic> item) async {
    if (!ApiKeys.hasClaude) return false;

    final payload =
        jsonDecode(item['payload_json'] as String) as Map<String, dynamic>;
    final imagePath = payload['image_path'] as String?;
    if (imagePath == null || !File(imagePath).existsSync()) return true;

    final cropName = payload['crop_name'] as String? ?? 'Mahindi';
    final scanType = payload['scan_type'] as String? ?? 'ugonjwa';
    final region = payload['region'] as String?;

    MkulimaResult? mkulimaResult;
    final mkulimaJson = payload['mkulima_json'] as Map<String, dynamic>?;
    if (mkulimaJson != null) {
      mkulimaResult = _mkulimaFromJson(mkulimaJson);
    }

    final diagnosis = await enrichOnline(
      imageFile: File(imagePath),
      cropName: cropName,
      scanType: scanType,
      mkulimaResult: mkulimaResult,
      region: region,
    );

    if (diagnosis['error'] == true) return false;

    await SupabaseService.saveDiagnosis(
      cropName: cropName,
      claudeResponse: diagnosis,
      photoPath: imagePath,
      gpsLat: (payload['gps_lat'] as num?)?.toDouble(),
      gpsLng: (payload['gps_lng'] as num?)?.toDouble(),
      mkulimaResult: mkulimaResult,
    );
    return true;
  }

  MkulimaResult? _mkulimaFromJson(Map<String, dynamic> json) {
    try {
      return MkulimaResult(
        diseaseKey: json['disease_key'] as String? ?? '',
        confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
        diseaseData: Map<String, dynamic>.from(
          json['disease_data'] as Map? ?? {},
        ),
        top3: List<Map<String, dynamic>>.from(
          (json['top3'] as List?)
                  ?.map((e) => Map<String, dynamic>.from(e as Map)) ??
              [],
        ),
      );
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic>? mkulimaToJson(MkulimaResult? r) {
    if (r == null) return null;
    return {
      'disease_key': r.diseaseKey,
      'confidence': r.confidence,
      'disease_data': r.diseaseData,
      'top3': r.top3,
    };
  }
}

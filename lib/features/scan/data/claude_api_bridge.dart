import 'dart:convert';
import 'dart:io';
import '../../../config/api_keys.dart';
import '../../../config/feature_flags.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/image_upload_helper.dart';
import '../../../services/claude_service.dart';
import '../../../services/gemini_scan_service.dart';
import '../../../services/mkulima_service.dart';
import '../../../services/plant_id_service.dart';
import '../../../services/supabase_service.dart';
import 'gemini_scan_translator.dart';
import 'scan_taxonomy.dart';

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
    // FLAG ON: all image CLASSIFICATION goes to Gemini (gemini-proxy), then is
    // translated into the existing diagnosis-map keys. Claude/Plant.id are NOT
    // used for classification. FLAG OFF (default): the original path below runs
    // byte-for-byte unchanged.
    if (FeatureFlags.useGeminiScan) {
      return _classifyWithGemini(
        imageFile: imageFile,
        cropName: cropName,
        scanType: scanType,
      );
    }

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

  // ── Gemini classification path (only when FeatureFlags.useGeminiScan) ───────
  static String _problemType(String scanType) => switch (scanType) {
        'magugu' => 'weed',
        'wadudu' => 'pest',
        'lishe' => 'nutrient_deficiency',
        _ => 'disease',
      };

  Future<Map<String, dynamic>> _classifyWithGemini({
    required File imageFile,
    required String cropName,
    required String scanType,
  }) async {
    await ScanTaxonomy().ensureLoaded();
    final base64 = await ImageUploadHelper.optimisedBase64ForScan(imageFile);
    final problemType = _problemType(scanType);

    // Auto-detect: resolve the crop first, then lock to its taxonomy. If the
    // crop can't be identified confidently, return the safe fallback (the
    // farmer is asked to pick manually — never guessed).
    var crop = cropName;
    if (crop == kAutoCrop) {
      final detected = await GeminiScanService.detectCrop(
        imageBase64: base64,
        candidates: ScanTaxonomy().diseaseCrops(),
      );
      if (detected == null) {
        return {'unclear': true, 'is_healthy': false};
      }
      crop = detected;
    }
    // Diseases stay taxonomy-locked (closed list). Pests/weeds use OPEN
    // detection: an empty list tells gemini-proxy to identify the real
    // species from its own knowledge (same "never invent / Unknown if unsure"
    // rule) instead of being forced to pick a disease name.
    final allowed = problemType == 'disease'
        ? ScanTaxonomy().allowedLabelsForCrop(crop)
        : const <String>[];

    // Flash-Lite first; auto-escalate to Flash on low-confidence/Unknown/
    // flagged/poor-but-usable (one retry, cost-controlled).
    final routing = await GeminiScanService.classifyWithRouting(
      imageBase64: base64,
      cropType: crop,
      problemType: problemType,
      allowedLabels: allowed,
    );

    if (routing.state == ScanRoutingState.error) {
      return {
        'error': true,
        'message': 'Uchunguzi wa picha umeshindwa. Jaribu tena.',
        'is_healthy': false,
      };
    }
    if (routing.state == ScanRoutingState.needsExpert) {
      return {
        'needs_expert': true,
        'is_healthy': false,
        'source': 'gemini-${routing.tier}',
        'final_label': 'Unknown',
        'escalation_reason': routing.escalationReason,
      };
    }

    final g = routing.gemini;
    final localized =
        ScanTaxonomy().localizeByEnglish((g['top_prediction'] as String?) ?? '');
    final map = GeminiScanTranslator.toDiagnosisMap(
      g,
      cropName: crop,
      scanType: scanType,
      tier: routing.tier,
      localized: localized,
    );
    map['routing_state'] =
        routing.state == ScanRoutingState.uncertain ? 'uncertain' : 'confident';
    map['escalation_reason'] = routing.escalationReason;
    return map;
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

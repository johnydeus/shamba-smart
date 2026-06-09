import 'dart:io';
import '../../../config/api_keys.dart';
import '../../../core/network/connectivity_service.dart';
import '../../../services/mkulima_service.dart';
import '../domain/scan_request.dart';
import '../domain/scan_result.dart';
import 'claude_api_bridge.dart';
import 'mkulima_engine.dart';

/// Orchestrates on-device Mkulima AI with cloud fallback / enrichment queue.
class ScanAnalysisService {
  static final ScanAnalysisService _instance = ScanAnalysisService._();
  factory ScanAnalysisService() => _instance;
  ScanAnalysisService._();

  final MkulimaEngine _mkulima = MkulimaEngine();
  final ClaudeApiBridge _bridge = ClaudeApiBridge();
  final ConnectivityService _connectivity = ConnectivityService();

  Future<ScanResult> analyze(ScanRequest request) async {
    final imageFile = File(request.imagePath);
    final isUgonjwa = request.scanType == 'ugonjwa';

    // Run connectivity check and Mkulima in parallel for ugonjwa scans.
    final onlineFuture = _connectivity.checkNow();
    final mkulimaFuture =
        isUgonjwa ? _mkulima.analyze(imageFile) : Future.value(null);

    final results = await Future.wait([onlineFuture, mkulimaFuture]);
    final isOnline = results[0] as bool;
    final mkulimaResult = results[1] as MkulimaResult?;

    final hasCloudKeys = request.scanType == 'magugu'
        ? ApiKeys.hasPlantId && ApiKeys.hasClaude
        : ApiKeys.hasCropHealth && ApiKeys.hasClaude;

    // Offline or missing API keys — use Mkulima-only for ugonjwa.
    if ((!isOnline || !hasCloudKeys) && isUgonjwa && mkulimaResult != null) {
      final diagnosis =
          _mkulima.diagnosisFromMkulima(mkulimaResult, request.cropName);

      if (!isOnline && hasCloudKeys) {
        await _bridge.queueEnrichment(
          imagePath: request.imagePath,
          cropName: request.cropName,
          scanType: request.scanType,
          mkulimaJson: ClaudeApiBridge.mkulimaToJson(mkulimaResult),
          gpsLat: request.gpsLat,
          gpsLng: request.gpsLng,
          region: request.region,
        );
      }

      return ScanResult(
        diagnosis: diagnosis,
        imagePath: request.imagePath,
        cropName: request.cropName,
        scanType: request.scanType,
        mkulimaResult: mkulimaResult,
        source: !isOnline ? ScanSource.queued : ScanSource.mkulimaOnly,
        queuedForEnrichment: !isOnline && hasCloudKeys,
        gpsLat: request.gpsLat,
        gpsLng: request.gpsLng,
      );
    }

    // Online cloud path.
    if (isOnline && hasCloudKeys) {
      final cloudDiagnosis = await _bridge.enrichOnline(
        imageFile: imageFile,
        cropName: request.cropName,
        scanType: request.scanType,
        mkulimaResult: mkulimaResult,
        region: request.region,
      );

      if (cloudDiagnosis['error'] != true) {
        return ScanResult(
          diagnosis: cloudDiagnosis,
          imagePath: request.imagePath,
          cropName: request.cropName,
          scanType: request.scanType,
          mkulimaResult: mkulimaResult,
          source: mkulimaResult != null ? ScanSource.hybrid : ScanSource.cloud,
          gpsLat: request.gpsLat,
          gpsLng: request.gpsLng,
        );
      }

      // Cloud failed — fall back to Mkulima if available.
      if (mkulimaResult != null) {
        return ScanResult(
          diagnosis: _mkulima.diagnosisFromMkulima(mkulimaResult, request.cropName),
          imagePath: request.imagePath,
          cropName: request.cropName,
          scanType: request.scanType,
          mkulimaResult: mkulimaResult,
          source: ScanSource.mkulimaOnly,
          gpsLat: request.gpsLat,
          gpsLng: request.gpsLng,
        );
      }

      return ScanResult(
        diagnosis: cloudDiagnosis,
        imagePath: request.imagePath,
        cropName: request.cropName,
        scanType: request.scanType,
        source: ScanSource.cloud,
        gpsLat: request.gpsLat,
        gpsLng: request.gpsLng,
      );
    }

    // No Mkulima (magugu/wadudu) and offline — return error.
    return ScanResult(
      diagnosis: {
        'error': true,
        'message':
            'Hakuna mtandao. Gundua ugonjwa unafanya kazi bila mtandao — magugu na wadudu wanahitaji mtandao.',
        'is_healthy': false,
      },
      imagePath: request.imagePath,
      cropName: request.cropName,
      scanType: request.scanType,
      source: ScanSource.mkulimaOnly,
      gpsLat: request.gpsLat,
      gpsLng: request.gpsLng,
    );
  }
}

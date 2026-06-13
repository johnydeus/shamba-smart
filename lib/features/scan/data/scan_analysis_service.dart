import 'dart:io';
import '../../../config/api_keys.dart';
import '../../../core/network/connectivity_service.dart';
import '../../../services/mkulima_service.dart';
import '../domain/scan_request.dart';
import '../domain/scan_result.dart';
import 'claude_api_bridge.dart';
import 'mkulima_engine.dart';

/// Mkulima AI is the primary disease scanner; cloud APIs enrich when online.
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

    final isOnline = await _connectivity.checkNow();
    final hasCloud = ApiKeys.hasClaude;

    // ── Disease scans: Mkulima AI first ─────────────────────────────────────
    if (isUgonjwa) {
      final mkulimaResult = await _mkulima.analyze(imageFile);

      if (mkulimaResult != null) {
        // Gate rejection: show farmer-friendly message, skip cloud fallback.
        if (mkulimaResult.isRejected) {
          return ScanResult(
            diagnosis: {
              'error': true,
              'message': mkulimaResult.rejectionReason ??
                  'Mkulima AI ilikataa picha hii. Jaribu tena.',
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

        final diagnosis =
            _mkulima.diagnosisFromMkulima(mkulimaResult, request.cropName);

        Map<String, dynamic>? cloudEnrichment;
        var queued = false;

        if (isOnline && hasCloud) {
          cloudEnrichment = await _bridge.enrichOnline(
            imageFile: imageFile,
            cropName: request.cropName,
            scanType: request.scanType,
            mkulimaResult: mkulimaResult,
            region: request.region,
          );
          if (cloudEnrichment['error'] == true) {
            cloudEnrichment = null;
          }
        } else if (!isOnline && hasCloud) {
          await _bridge.queueEnrichment(
            imagePath: request.imagePath,
            cropName: request.cropName,
            scanType: request.scanType,
            mkulimaJson: ClaudeApiBridge.mkulimaToJson(mkulimaResult),
            gpsLat: request.gpsLat,
            gpsLng: request.gpsLng,
            region: request.region,
          );
          queued = true;
        }

        return ScanResult(
          diagnosis: diagnosis,
          imagePath: request.imagePath,
          cropName: request.cropName,
          scanType: request.scanType,
          mkulimaResult: mkulimaResult,
          source: cloudEnrichment != null
              ? ScanSource.hybrid
              : (queued ? ScanSource.queued : ScanSource.mkulimaOnly),
          queuedForEnrichment: queued,
          gpsLat: request.gpsLat,
          gpsLng: request.gpsLng,
          cloudEnrichment: cloudEnrichment,
        );
      }

      // Mkulima unavailable — fall back to cloud if possible.
      if (isOnline && hasCloud) {
        final cloudDiagnosis = await _bridge.enrichOnline(
          imageFile: imageFile,
          cropName: request.cropName,
          scanType: request.scanType,
          region: request.region,
        );
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

      return ScanResult(
        diagnosis: {
          'error': true,
          'message':
              'Mkulima AI haikupatikana. Hakikisha model iko kwenye simu na jaribu tena.',
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

    // ── Weeds & pests: online cloud only (Mkulima does not cover these) ───────
    if (isOnline && hasCloud) {
      final cloudDiagnosis = await _bridge.enrichOnline(
        imageFile: imageFile,
        cropName: request.cropName,
        scanType: request.scanType,
        region: request.region,
      );
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

    return ScanResult(
      diagnosis: {
        'error': true,
        'message': !hasCloud
            ? 'Weka CLAUDE_API_KEY kwenye .env kwa uchunguzi wa magugu/wadudu.'
            : 'Hakuna mtandao. Gundua ugonjwa (Mkulima AI) inafanya kazi bila mtandao — magugu na wadudu wanahitaji mtandao.',
        'is_healthy': false,
      },
      imagePath: request.imagePath,
      cropName: request.cropName,
      scanType: request.scanType,
      source: ScanSource.cloud,
      gpsLat: request.gpsLat,
      gpsLng: request.gpsLng,
    );
  }
}

import 'dart:io';
import '../../../config/api_keys.dart';
import '../../../core/network/connectivity_service.dart';
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

  /// Fast Mkulima-only scan — returns in <500 ms with no network usage.
  ///
  /// For `ugonjwa` (disease) scans this is the FIRST stage of the two-stage
  /// pipeline. `scan_screen.dart` calls this, navigates to ResultsScreen
  /// immediately, then ResultsScreen fires [ClaudeService.verifyDiagnosis]
  /// in the background to produce the trusted final result.
  ///
  /// Returns:
  /// - `ScanResult` with `mkulimaResult` populated on success
  /// - `ScanResult` with `error: true` when the image is not a plant
  /// - `null` when the model is unavailable
  Future<ScanResult?> mkulimaOnlyAnalyze(ScanRequest request,
      {bool bypassPlantGate = false}) async {
    final imageFile = File(request.imagePath);

    final mkulimaResult =
        await _mkulima.analyze(imageFile, bypassPlantGate: bypassPlantGate);

    // Model not loaded (first launch race / init failure)
    if (mkulimaResult == null) {
      return ScanResult(
        diagnosis: {
          'error': true,
          'message': 'Mkulima AI haikupatikana. Jaribu tena.',
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

    // Gate 1: not a plant. Tagged so scan_screen can ASK the farmer (they may
    // have intentionally photographed a cob/fruit/stem) instead of hard-blocking.
    if (mkulimaResult.isRejected &&
        mkulimaResult.diseaseKey == 'rejected_no_plant') {
      return ScanResult(
        diagnosis: {
          'error': true,
          'gate1_no_plant': true,
          'message': mkulimaResult.rejectionReason ??
              'Hii haionekani kama mmea wa kilimo. '
                  'Piga picha ya jani la zao lako.',
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

    // Gate 2 (low confidence) or normal result — both proceed to Claude.
    // Build a preliminary diagnosis map so ResultsScreen can show something
    // immediately. When Mkulima was low-confidence, show a holding message.
    final Map<String, dynamic> prelimDiagnosis;
    if (mkulimaResult.isRejected) {
      // Low-confidence — don't show a wrong disease name; just say "verifying"
      prelimDiagnosis = {
        'is_healthy': false,
        'disease_name_sw': 'Inahakikiwa...',
        'disease_name_en': 'Verifying...',
        'confidence': mkulimaResult.confidence,
        'severity': 'low',
        'description_sw': 'Mkulima AI haikuwa na uhakika wa kutosha. '
            'Claude anaangalia picha kwa makini zaidi.',
        'source': 'mkulima_low_confidence',
      };
    } else {
      prelimDiagnosis =
          _mkulima.diagnosisFromMkulima(mkulimaResult, request.cropName);
    }

    return ScanResult(
      diagnosis: prelimDiagnosis,
      imagePath: request.imagePath,
      cropName: request.cropName,
      scanType: request.scanType,
      // Pass mkulimaResult only when it's not rejected, so ResultsScreen
      // knows whether to show the Mkulima AI card.
      mkulimaResult: mkulimaResult.isRejected ? null : mkulimaResult,
      source: ScanSource.mkulimaOnly,
      gpsLat: request.gpsLat,
      gpsLng: request.gpsLng,
    );
  }

  Future<bool> isOnline() => _connectivity.checkNow();

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

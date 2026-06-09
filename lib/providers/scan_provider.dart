import 'package:flutter/foundation.dart';
import '../features/scan/data/scan_analysis_service.dart';
import '../features/scan/domain/scan_request.dart';
import '../features/scan/domain/scan_result.dart';
import '../services/supabase_service.dart';

enum ScanPhase { idle, mkulima, cloud, saving, complete, error }

class ScanProvider extends ChangeNotifier {
  final ScanAnalysisService _service = ScanAnalysisService();

  ScanPhase _phase = ScanPhase.idle;
  String _statusMessage = '';
  ScanResult? _lastResult;
  String? _errorMessage;

  ScanPhase get phase => _phase;
  String get statusMessage => _statusMessage;
  ScanResult? get lastResult => _lastResult;
  String? get errorMessage => _errorMessage;
  bool get isBusy =>
      _phase == ScanPhase.mkulima ||
      _phase == ScanPhase.cloud ||
      _phase == ScanPhase.saving;

  Future<ScanResult?> analyze(ScanRequest request) async {
    _phase = ScanPhase.mkulima;
    _statusMessage = request.scanType == 'ugonjwa'
        ? 'Mkulima AI inachunguza picha...'
        : 'Inaandaa uchunguzi...';
    _errorMessage = null;
    notifyListeners();

    try {
      _phase = ScanPhase.cloud;
      _statusMessage = 'Inachambua picha...';
      notifyListeners();

      final result = await _service.analyze(request);
      _lastResult = result;

      if (result.hasError && result.mkulimaResult == null) {
        _phase = ScanPhase.error;
        _errorMessage = result.diagnosis['message'] as String?;
        notifyListeners();
        return result;
      }

      _phase = ScanPhase.saving;
      _statusMessage = 'Inahifadhi matokeo...';
      notifyListeners();

      await SupabaseService.saveDiagnosis(
        cropName: request.cropName,
        claudeResponse: result.diagnosis,
        photoPath: request.imagePath,
        gpsLat: request.gpsLat,
        gpsLng: request.gpsLng,
        mkulimaResult: result.mkulimaResult,
      );

      _phase = ScanPhase.complete;
      _statusMessage = '';
      notifyListeners();
      return result;
    } catch (e) {
      _phase = ScanPhase.error;
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  void reset() {
    _phase = ScanPhase.idle;
    _statusMessage = '';
    _lastResult = null;
    _errorMessage = null;
    notifyListeners();
  }
}

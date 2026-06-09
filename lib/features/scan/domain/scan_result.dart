import '../../../services/mkulima_service.dart';

enum ScanSource { mkulimaOnly, cloud, hybrid, queued }

class ScanResult {
  /// Primary diagnosis — for ugonjwa this comes from Mkulima AI when available.
  final Map<String, dynamic> diagnosis;
  final String imagePath;
  final String cropName;
  final String scanType;
  final MkulimaResult? mkulimaResult;
  final ScanSource source;
  final bool queuedForEnrichment;
  final double? gpsLat;
  final double? gpsLng;

  /// Optional online enrichment (Claude / Plant.id) — never replaces Mkulima.
  final Map<String, dynamic>? cloudEnrichment;

  const ScanResult({
    required this.diagnosis,
    required this.imagePath,
    required this.cropName,
    required this.scanType,
    this.mkulimaResult,
    required this.source,
    this.queuedForEnrichment = false,
    this.gpsLat,
    this.gpsLng,
    this.cloudEnrichment,
  });

  bool get hasError => diagnosis['error'] == true;
  bool get isHealthy => diagnosis['is_healthy'] == true;
  bool get isMkulimaPrimary => mkulimaResult != null && scanType == 'ugonjwa';

  String get sourceLabel {
    if (isMkulimaPrimary) {
      if (queuedForEnrichment) {
        return 'Mkulima AI — ushauri wa ziada utakuja mtandaoni urudipo';
      }
      if (cloudEnrichment != null && cloudEnrichment!['error'] != true) {
        return 'Mkulima AI + Ushauri wa Mtandaoni';
      }
      return 'Mkulima AI — Bila Mtandao';
    }
    final cloudSource = diagnosis['source'] as String?;
    if (cloudSource == 'claude_vision') return 'Claude Vision';
    return switch (source) {
      ScanSource.mkulimaOnly => 'Mkulima AI',
      ScanSource.cloud => 'Plant.id + Claude',
      ScanSource.hybrid => 'Mkulima AI + Claude',
      ScanSource.queued => 'Mkulima AI (Inasubiri mtandao)',
    };
  }
}

import '../../../services/mkulima_service.dart';

enum ScanSource { mkulimaOnly, cloud, hybrid, queued }

class ScanResult {
  final Map<String, dynamic> diagnosis;
  final String imagePath;
  final String cropName;
  final String scanType;
  final MkulimaResult? mkulimaResult;
  final ScanSource source;
  final bool queuedForEnrichment;
  final double? gpsLat;
  final double? gpsLng;

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
  });

  bool get hasError => diagnosis['error'] == true;
  bool get isHealthy => diagnosis['is_healthy'] == true;

  String get sourceLabel => switch (source) {
        ScanSource.mkulimaOnly => 'Mkulima AI (Bila Mtandao)',
        ScanSource.cloud => 'Plant.id + Claude',
        ScanSource.hybrid => 'Mkulima AI + Claude',
        ScanSource.queued => 'Mkulima AI (Inasubiri mtandao)',
      };
}

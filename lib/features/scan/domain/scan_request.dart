class ScanRequest {
  final String imagePath;
  final String cropName;
  final String scanType;
  final double? gpsLat;
  final double? gpsLng;
  final String? region;

  const ScanRequest({
    required this.imagePath,
    required this.cropName,
    required this.scanType,
    this.gpsLat,
    this.gpsLng,
    this.region,
  });
}

class CropRequirement {
  final String name;
  final double? minPh;
  final double? maxPh;
  final int? growingDays;
  final String? suitableRegions;

  const CropRequirement({
    required this.name,
    this.minPh,
    this.maxPh,
    this.growingDays,
    this.suitableRegions,
  });

  factory CropRequirement.fromJson(Map<String, dynamic> json) =>
      CropRequirement(
        name: json['name'] as String? ?? '',
        minPh: (json['min_ph'] as num?)?.toDouble(),
        maxPh: (json['max_ph'] as num?)?.toDouble(),
        growingDays: json['growing_days'] as int?,
        suitableRegions: json['suitable_regions'] as String?,
      );
}

class CropSuitability {
  final CropRequirement crop;
  final double score;
  final String reason;

  const CropSuitability({
    required this.crop,
    required this.score,
    required this.reason,
  });
}

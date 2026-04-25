class Disease {
  final int? id;
  final String diseaseNameEn;
  final String? diseaseNameSw;
  final String affectedCrop;
  final String? symptomsSw;
  final String? severityLevel;
  final String source;

  const Disease({
    this.id,
    required this.diseaseNameEn,
    this.diseaseNameSw,
    required this.affectedCrop,
    this.symptomsSw,
    this.severityLevel,
    this.source = 'PlantVillage',
  });

  factory Disease.fromJson(Map<String, dynamic> json) => Disease(
        id: json['id'] as int?,
        diseaseNameEn: json['disease_name_en'] as String,
        diseaseNameSw: json['disease_name_sw'] as String?,
        affectedCrop: json['affected_crop'] as String,
        symptomsSw: json['symptoms_sw'] as String?,
        severityLevel: json['severity_level'] as String?,
        source: json['source'] as String? ?? 'PlantVillage',
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'disease_name_en': diseaseNameEn,
        'disease_name_sw': diseaseNameSw,
        'affected_crop': affectedCrop,
        'symptoms_sw': symptomsSw,
        'severity_level': severityLevel,
        'source': source,
      };

  String get displayName => diseaseNameSw ?? diseaseNameEn;
}

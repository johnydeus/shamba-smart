import 'package:latlong2/latlong.dart';

// ── NDWI (Normalized Difference Water Index) ──────────────────────────────────
// Formula: NDWI = (Green − NIR) / (Green + NIR)
// Range: −1.0 to +1.0
// Positive values → water presence / good crop hydration
// Negative values → water stress / dry vegetation

enum NdwiHealthStatus { wellWatered, adequate, slightStress, moderateStress, severeStress }

extension NdwiHealthStatusX on NdwiHealthStatus {
  String get labelSw => switch (this) {
        NdwiHealthStatus.wellWatered     => 'Maji Mengi',
        NdwiHealthStatus.adequate        => 'Maji Ya Kutosha',
        NdwiHealthStatus.slightStress    => 'Mkazo Mdogo',
        NdwiHealthStatus.moderateStress  => 'Mkazo wa Wastani',
        NdwiHealthStatus.severeStress    => 'Mkazo Mkali',
      };

  // NDWI colour scale: dark blue → red
  int get colorValue => switch (this) {
        NdwiHealthStatus.wellWatered     => 0xFF0D47A1, // deep blue
        NdwiHealthStatus.adequate        => 0xFF1976D2, // medium blue
        NdwiHealthStatus.slightStress    => 0xFF81D4FA, // light blue
        NdwiHealthStatus.moderateStress  => 0xFFFF6F00, // orange
        NdwiHealthStatus.severeStress    => 0xFFB71C1C, // red
      };

  String get irrigationAdvice => switch (this) {
        NdwiHealthStatus.wellWatered =>
            'Maji ya kutosha. Punguza umwagiliaji ili kuepuka kuoza kwa mizizi.',
        NdwiHealthStatus.adequate =>
            'Hali ya maji ipo sawa. Endelea na umwagiliaji wa kawaida.',
        NdwiHealthStatus.slightStress =>
            'Ongeza umwagiliaji kidogo — lita 20% zaidi kwa siku.',
        NdwiHealthStatus.moderateStress =>
            'Mwagilia mara mbili kwa siku — asubuhi na jioni.',
        NdwiHealthStatus.severeStress =>
            '🚨 Hatari! Mmea unakufa kwa ukame. Mwagilia SASA HIVI.',
      };
}

// NDWI reading — one data point in time
class NdwiReading {
  final DateTime date;
  final double average;   // NDWI average across the field
  final double min;
  final double max;
  final double cloudCover;

  const NdwiReading({
    required this.date,
    required this.average,
    required this.min,
    required this.max,
    required this.cloudCover,
  });

  // Classify water status from NDWI value
  NdwiHealthStatus get healthStatus => switch (average) {
        >= 0.2  => NdwiHealthStatus.wellWatered,
        >= 0.05 => NdwiHealthStatus.adequate,
        >= -0.1 => NdwiHealthStatus.slightStress,
        >= -0.2 => NdwiHealthStatus.moderateStress,
        _       => NdwiHealthStatus.severeStress,
      };

  // Water content percentage (0–100) derived from NDWI
  double get waterContentPercent =>
      ((average + 1.0) / 2.0 * 100).clamp(0, 100);

  factory NdwiReading.fromJson(Map<String, dynamic> j) => NdwiReading(
        date: DateTime.fromMillisecondsSinceEpoch(
            (j['dt'] as int) * 1000),
        average: (j['avg'] as num? ?? 0).toDouble(),
        min: (j['min'] as num? ?? 0).toDouble(),
        max: (j['max'] as num? ?? 0).toDouble(),
        cloudCover: (j['cl'] as num? ?? 0).toDouble(),
      );
}

// ── NDVI health classification ────────────────────────────────────────────────

enum NdviHealthStatus { excellent, good, moderate, poor, veryPoor }

extension NdviHealthStatusX on NdviHealthStatus {
  String get labelSw => switch (this) {
        NdviHealthStatus.excellent => 'Bora Sana',
        NdviHealthStatus.good     => 'Nzuri',
        NdviHealthStatus.moderate => 'Wastani',
        NdviHealthStatus.poor     => 'Mbaya',
        NdviHealthStatus.veryPoor => 'Mbaya Sana',
      };

  // NDVI colour: dark green → red
  int get colorValue => switch (this) {
        NdviHealthStatus.excellent => 0xFF1B5E20,
        NdviHealthStatus.good     => 0xFF43A047,
        NdviHealthStatus.moderate => 0xFFF9A825,
        NdviHealthStatus.poor     => 0xFFE65100,
        NdviHealthStatus.veryPoor => 0xFFB71C1C,
      };
}

// ── Field polygon ─────────────────────────────────────────────────────────────

class FieldPolygon {
  final String id;
  final String name;
  final List<LatLng> coordinates;
  final DateTime createdAt;

  const FieldPolygon({
    required this.id,
    required this.name,
    required this.coordinates,
    required this.createdAt,
  });

  factory FieldPolygon.fromJson(Map<String, dynamic> j) => FieldPolygon(
        id: j['id'] as String,
        name: j['name'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
        coordinates: (j['coordinates'] as List)
            .map((c) => LatLng(
                  (c['lat'] as num).toDouble(),
                  (c['lng'] as num).toDouble(),
                ))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        'coordinates': coordinates
            .map((c) => {'lat': c.latitude, 'lng': c.longitude})
            .toList(),
      };

  // Centre point of the polygon
  LatLng get center {
    final lat =
        coordinates.map((c) => c.latitude).reduce((a, b) => a + b) /
            coordinates.length;
    final lng =
        coordinates.map((c) => c.longitude).reduce((a, b) => a + b) /
            coordinates.length;
    return LatLng(lat, lng);
  }
}

// ── NDVI reading (one data point) ────────────────────────────────────────────

class NdviReading {
  final DateTime date;
  final double average;
  final double min;
  final double max;
  final double cloudCover;

  const NdviReading({
    required this.date,
    required this.average,
    required this.min,
    required this.max,
    required this.cloudCover,
  });

  NdviHealthStatus get healthStatus => switch (average) {
        >= 0.6 => NdviHealthStatus.excellent,
        >= 0.4 => NdviHealthStatus.good,
        >= 0.2 => NdviHealthStatus.moderate,
        >= 0.0 => NdviHealthStatus.poor,
        _      => NdviHealthStatus.veryPoor,
      };

  factory NdviReading.fromJson(Map<String, dynamic> j) => NdviReading(
        date: DateTime.fromMillisecondsSinceEpoch(
            (j['dt'] as int) * 1000),
        average: (j['avg'] as num? ?? 0).toDouble(),
        min: (j['min'] as num? ?? 0).toDouble(),
        max: (j['max'] as num? ?? 0).toDouble(),
        cloudCover: (j['cl'] as num? ?? 0).toDouble(),
      );
}

// ── Analysis sub-models ───────────────────────────────────────────────────────

class SoilAnalysis {
  final String status;
  final double moistureLevel;
  final String texture;
  final Map<String, String> nutrientLevels;

  const SoilAnalysis({
    required this.status,
    required this.moistureLevel,
    required this.texture,
    required this.nutrientLevels,
  });
}

class WaterStressAnalysis {
  final String level;
  final double stressIndex;      // 0 = no stress, 1 = severe stress
  final String recommendation;
  final NdwiReading? ndwiReading; // real NDWI reading if available

  const WaterStressAnalysis({
    required this.level,
    required this.stressIndex,
    required this.recommendation,
    this.ndwiReading,
  });
}

class NutrientDeficiency {
  final String nutrient;
  final String severity;
  final String symptoms;
  final String treatment;

  const NutrientDeficiency({
    required this.nutrient,
    required this.severity,
    required this.symptoms,
    required this.treatment,
  });
}

class NutrientAnalysis {
  final List<NutrientDeficiency> deficiencies;
  final String overallStatus;

  const NutrientAnalysis({
    required this.deficiencies,
    required this.overallStatus,
  });
}

class DetectedThreat {
  final String name;
  final String type;
  final String severity;
  final String description;
  final List<String> treatments;

  const DetectedThreat({
    required this.name,
    required this.type,
    required this.severity,
    required this.description,
    required this.treatments,
  });
}

class PestDiseaseAnalysis {
  final List<DetectedThreat> threats;
  final String riskLevel;

  const PestDiseaseAnalysis({
    required this.threats,
    required this.riskLevel,
  });
}

// ── Full crop analysis report ─────────────────────────────────────────────────

class CropAnalysisReport {
  final String fieldId;
  final DateTime generatedAt;
  final double overallHealthScore;
  final NdviReading latestNdvi;
  final NdwiReading? latestNdwi;   // NDWI water stress reading
  final SoilAnalysis soilAnalysis;
  final WaterStressAnalysis waterStress;
  final NutrientAnalysis nutrients;
  final PestDiseaseAnalysis pestDisease;
  final List<String> recommendations;
  final String aiSummary;

  const CropAnalysisReport({
    required this.fieldId,
    required this.generatedAt,
    required this.overallHealthScore,
    required this.latestNdvi,
    this.latestNdwi,
    required this.soilAnalysis,
    required this.waterStress,
    required this.nutrients,
    required this.pestDisease,
    required this.recommendations,
    required this.aiSummary,
  });
}

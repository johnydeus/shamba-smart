import '../../../models/soil_data_model.dart';
import '../domain/crop_requirement.dart';

/// Scores crops against soil pH and nutrient levels for Tanzania farmers.
class SoilCropMatcher {
  static List<CropSuitability> match({
    required SoilDataModel soil,
    required List<CropRequirement> crops,
    String? farmerRegion,
  }) {
    final results = <CropSuitability>[];

    for (final crop in crops) {
      double score = 0;
      final reasons = <String>[];

      // pH fit (50% weight)
      if (soil.ph != null && crop.minPh != null && crop.maxPh != null) {
        if (soil.ph! >= crop.minPh! && soil.ph! <= crop.maxPh!) {
          score += 50;
          reasons.add('pH ${soil.ph!.toStringAsFixed(1)} inafaa');
        } else {
          final dist = soil.ph! < crop.minPh!
              ? crop.minPh! - soil.ph!
              : soil.ph! - crop.maxPh!;
          score += (50 - dist * 15).clamp(0, 50);
          reasons.add('pH haifai kabisa');
        }
      } else {
        score += 25;
      }

      // Nitrogen (25% weight)
      if (soil.nitrogen != null) {
        if (soil.nitrogen! >= 0.8) {
          score += 25;
          reasons.add('Nitrojeni nzuri');
        } else if (soil.nitrogen! >= 0.5) {
          score += 15;
          reasons.add('Nitrojeni wastani');
        } else {
          score += 5;
          reasons.add('Nitrojeni chini');
        }
      } else {
        score += 12;
      }

      // Organic carbon (15% weight)
      if (soil.organicCarbon != null) {
        if (soil.organicCarbon! >= 15) {
          score += 15;
          reasons.add('Kaboni nzuri');
        } else if (soil.organicCarbon! >= 10) {
          score += 10;
        } else {
          score += 3;
          reasons.add('Ongeza mbolea ya asili');
        }
      } else {
        score += 8;
      }

      // Region match (10% weight)
      if (farmerRegion != null &&
          crop.suitableRegions != null &&
          crop.suitableRegions!.isNotEmpty) {
        if (crop.suitableRegions!
            .toLowerCase()
            .contains(farmerRegion.toLowerCase())) {
          score += 10;
          reasons.add('Inafaa $farmerRegion');
        }
      } else {
        score += 5;
      }

      results.add(CropSuitability(
        crop: crop,
        score: score.clamp(0, 100),
        reason: reasons.take(2).join(' · '),
      ));
    }

    results.sort((a, b) => b.score.compareTo(a.score));
    return results;
  }
}

import 'package:flutter/material.dart';
import '../../features/soil/data/crop_requirement_service.dart';
import '../../features/soil/data/soil_crop_matcher.dart';
import '../../models/soil_data_model.dart';
import '../../services/soil_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shamba_card.dart';
import '../../screens/soil_screen.dart';
import 'crop_suitability_chart.dart';
import 'soil_nutrient_chart.dart';

/// Compact soil summary for the profile page.
class SoilProfileSummaryCard extends StatefulWidget {
  final String? farmerRegion;

  const SoilProfileSummaryCard({super.key, this.farmerRegion});

  @override
  State<SoilProfileSummaryCard> createState() => _SoilProfileSummaryCardState();
}

class _SoilProfileSummaryCardState extends State<SoilProfileSummaryCard> {
  SoilDataModel? _soil;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cached = await SoilService.getCachedResult();
    if (!mounted) return;
    setState(() {
      _soil = cached;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const ShambaCard(
        child: SizedBox(
          height: 80,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
    }

    if (_soil == null) {
      return ShambaCard(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SoilScreen()),
        ),
        child: const Row(
          children: [
            Icon(Icons.landscape_outlined, color: AppColors.primary, size: 32),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chunguza Udongo wa Shamba',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Pata data za pH na virutubisho kwa GPS',
                    style: TextStyle(fontSize: 13, color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textHint),
          ],
        ),
      );
    }

    return FutureBuilder(
      future: CropRequirementService().fetchCrops(),
      builder: (context, snapshot) {
        final crops = snapshot.data ?? [];
        final matches = SoilCropMatcher.match(
          soil: _soil!,
          crops: crops,
          farmerRegion: widget.farmerRegion,
        );

        return ShambaCard(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SoilScreen()),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.eco_outlined, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Hali ya Udongo',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const Spacer(),
                  if (_soil!.ph != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(
                        'pH ${_soil!.ph!.toStringAsFixed(1)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              SoilNutrientChart(soil: _soil!),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Mazao Yanayofaa',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppSpacing.sm),
              CropSuitabilityChart(matches: matches, maxItems: 3),
            ],
          ),
        );
      },
    );
  }
}

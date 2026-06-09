import 'package:flutter/material.dart';
import '../../features/soil/domain/crop_requirement.dart';
import '../../theme/app_theme.dart';

/// Horizontal bar chart showing crop suitability scores.
class CropSuitabilityChart extends StatelessWidget {
  final List<CropSuitability> matches;
  final int maxItems;

  const CropSuitabilityChart({
    super.key,
    required this.matches,
    this.maxItems = 5,
  });

  Color _scoreColor(double score) {
    if (score >= 70) return AppColors.success;
    if (score >= 45) return AppColors.warning;
    return AppColors.critical;
  }

  @override
  Widget build(BuildContext context) {
    final top = matches.take(maxItems).toList();
    if (top.isEmpty) return const SizedBox.shrink();

    return Column(
      children: top.map((m) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Row(
            children: [
              SizedBox(
                width: 90,
                child: Text(
                  m.crop.name,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: m.score / 100,
                    minHeight: 8,
                    backgroundColor: AppColors.divider,
                    valueColor: AlwaysStoppedAnimation(_scoreColor(m.score)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${m.score.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _scoreColor(m.score),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

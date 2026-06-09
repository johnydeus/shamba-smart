import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../models/soil_data_model.dart';
import '../../theme/app_theme.dart';

/// Bar chart for soil pH, nitrogen, and organic carbon.
class SoilNutrientChart extends StatelessWidget {
  final SoilDataModel soil;

  const SoilNutrientChart({super.key, required this.soil});

  @override
  Widget build(BuildContext context) {
    final bars = <BarChartGroupData>[];
    final labels = <String>[];

    void addBar(int x, String label, double? value, double max) {
      if (value == null) return;
      labels.add(label);
      bars.add(
        BarChartGroupData(
          x: x,
          barRods: [
            BarChartRodData(
              toY: (value / max * 100).clamp(4, 100),
              color: AppColors.primary,
              width: 20,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ],
        ),
      );
    }

    addBar(0, 'pH', soil.ph, 14);
    addBar(1, 'N', soil.nitrogen != null ? soil.nitrogen! * 10 : null, 20);
    addBar(2, 'SOC', soil.organicCarbon, 30);

    if (bars.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 160,
      child: BarChart(
        BarChartData(
          maxY: 100,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      labels[i],
                      style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: bars,
        ),
      ),
    );
  }
}

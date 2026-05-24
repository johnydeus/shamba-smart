import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

enum BadgeType { healthy, warning, critical, info, neutral }

class StatusBadge extends StatelessWidget {
  final String label;
  final BadgeType type;
  final bool showDot;

  const StatusBadge({
    super.key,
    required this.label,
    required this.type,
    this.showDot = true,
  });

  static BadgeType fromSeverity(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'low':
        return BadgeType.healthy;
      case 'medium':
        return BadgeType.warning;
      case 'high':
      case 'critical':
        return BadgeType.critical;
      default:
        return BadgeType.neutral;
    }
  }

  (Color bg, Color fg) get _colors => switch (type) {
        BadgeType.healthy => (AppColors.successBg, AppColors.success),
        BadgeType.warning => (AppColors.warningBg, AppColors.warning),
        BadgeType.critical => (AppColors.criticalBg, AppColors.critical),
        BadgeType.info => (AppColors.infoBg, AppColors.info),
        BadgeType.neutral => (AppColors.surfaceVariant, AppColors.textTertiary),
      };

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 4,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

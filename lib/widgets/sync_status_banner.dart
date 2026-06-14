import 'package:flutter/material.dart';
import '../core/sync/sync_coordinator.dart';
import '../core/sync/sync_status.dart';
import '../theme/app_theme.dart';

class SyncStatusBanner extends StatelessWidget {
  const SyncStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SyncCoordinator(),
      builder: (context, _) {
        final status = SyncCoordinator().status;
        if (status.state == SyncState.idle && !status.hasPending) {
          return const SizedBox.shrink();
        }

        final (icon, text, color) = switch (status.state) {
          SyncState.offline => (
              Icons.wifi_off_rounded,
              status.hasPending
                  ? 'Hauna intaneti — ujumbe ${status.pendingCount} utumwe baadaye'
                  : 'Hauna intaneti. Baadhi ya huduma zinapatikana bila intaneti.',
              AppColors.warning,
            ),
          SyncState.syncing => (
              Icons.sync,
              'Inasawazisha data...',
              AppColors.info,
            ),
          SyncState.pending => (
              Icons.schedule,
              '${status.pendingCount} inasubiri kutumwa',
              AppColors.info,
            ),
          SyncState.idle when status.hasPending => (
              Icons.schedule,
              '${status.pendingCount} inasubiri kutumwa',
              AppColors.info,
            ),
          _ => (Icons.check_circle_outline, '', AppColors.success),
        };

        if (text.isEmpty) return const SizedBox.shrink();

        return Material(
          color: color.withValues(alpha: 0.12),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 13,
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

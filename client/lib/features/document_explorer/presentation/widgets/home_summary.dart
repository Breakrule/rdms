import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../documents/domain/models/document_item.dart';
import '../../../documents/presentation/providers/document_providers.dart';
import '../home_layout.dart';

class HomeSummary extends ConsumerWidget {
  const HomeSummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final summaryAsync = ref.watch(documentSummaryProvider);
    final currentSyncStatus =
        ref.watch(documentFilterProvider.select((s) => s.syncStatus));
    final size = MediaQuery.sizeOf(context);
    final isCompact = HomeLayout.fromWidth(size.width) == HomeLayoutMode.compact;

    final statusColors = theme.extension<RdmsStatusColors>() ??
        (isDark ? RdmsStatusColors.dark : RdmsStatusColors.light);

    return summaryAsync.when(
      data: (summary) {
        final pills = [
          (
            label: 'Semua',
            count: summary.total,
            icon: Icons.folder_copy_outlined,
            activeColor: theme.colorScheme.primary,
            activeContainer: theme.colorScheme.primaryContainer,
            filterKey: 'ALL',
            isActive: currentSyncStatus == 'ALL',
          ),
          (
            label: 'Lokal Saja',
            count: summary.localOnly,
            icon: Icons.inventory_2_outlined,
            activeColor: const Color(0xFF475569),
            activeContainer: const Color(0xFFF1F5F9),
            filterKey: DocumentSyncStatus.localOnly.name,
            isActive: currentSyncStatus == DocumentSyncStatus.localOnly.name,
          ),
          (
            label: 'Drive',
            count: summary.synced,
            icon: Icons.cloud_done_outlined,
            activeColor: statusColors.success,
            activeContainer: statusColors.successContainer,
            filterKey: DocumentSyncStatus.synced.name,
            isActive: currentSyncStatus == DocumentSyncStatus.synced.name,
          ),
          if (summary.attention > 0)
            (
              label: 'Perlu Perhatian',
              count: summary.attention,
              icon: Icons.warning_amber_rounded,
              activeColor: statusColors.warning,
              activeContainer: statusColors.warningContainer,
              filterKey: DocumentSyncStatus.error.name,
              isActive: currentSyncStatus == DocumentSyncStatus.error.name,
            ),
        ];

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? AppTheme.space16 : AppTheme.space24,
            vertical: AppTheme.space8,
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final pill in pills) ...[
                  Padding(
                    padding: const EdgeInsets.only(right: AppTheme.space8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        final notifier =
                            ref.read(documentFilterProvider.notifier);
                        if (pill.filterKey == 'ALL') {
                          notifier.setSyncStatus('ALL');
                        } else {
                          notifier.setSyncStatus(
                            currentSyncStatus == pill.filterKey
                                ? 'ALL'
                                : pill.filterKey,
                          );
                        }
                      },
                      child: AnimatedContainer(
                        duration: AppTheme.durationFeedback,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: pill.isActive
                              ? (isDark
                                  ? pill.activeContainer.withValues(alpha: 0.3)
                                  : pill.activeContainer)
                              : (isDark
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFFF8FAFC)),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: pill.isActive
                                ? pill.activeColor
                                : theme.dividerColor.withValues(alpha: 0.15),
                            width: pill.isActive ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              pill.icon,
                              size: 14,
                              color: pill.isActive
                                  ? pill.activeColor
                                  : theme.colorScheme.onSurface
                                      .withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              pill.label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: pill.isActive
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: pill.isActive
                                    ? pill.activeColor
                                    : theme.colorScheme.onSurface
                                        .withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: pill.isActive
                                    ? pill.activeColor.withValues(alpha: 0.18)
                                    : theme.colorScheme.onSurface
                                        .withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${pill.count}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: pill.isActive
                                      ? pill.activeColor
                                      : theme.colorScheme.onSurface
                                          .withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

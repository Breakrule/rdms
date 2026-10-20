import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../documents/presentation/providers/document_providers.dart';

class HomeStatusBar extends ConsumerWidget {
  const HomeStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statusColors =
        theme.extension<RdmsStatusColors>() ??
        (theme.brightness == Brightness.dark
            ? RdmsStatusColors.dark
            : RdmsStatusColors.light);

    final syncProgressAsync = ref.watch(syncProgressStreamProvider);

    final isProgressRunning =
        syncProgressAsync.asData?.value.isRunning ?? false;
    final progress = syncProgressAsync.asData?.value;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isProgressRunning && progress != null) ...[
          Container(
            margin: const EdgeInsets.symmetric(
              horizontal: AppTheme.space16,
              vertical: AppTheme.space8,
            ),
            padding: const EdgeInsets.all(AppTheme.space12),
            decoration: BoxDecoration(
              color: statusColors.infoContainer,
              borderRadius: BorderRadius.circular(AppTheme.radiusControl),
              border: Border.all(
                color: statusColors.info.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: statusColors.info,
                      ),
                    ),
                    const SizedBox(width: AppTheme.space8),
                    Expanded(
                      child: Text(
                        'Memproses antrean: ${progress.completed + progress.failed}/${progress.total} berkas'
                        '${progress.failed > 0 ? ' (${progress.failed} gagal)' : ''}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusColors.info,
                        ),
                      ),
                    ),
                    Text(
                      '${(progress.percentage * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: statusColors.info,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.space8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.space4),
                  child: LinearProgressIndicator(
                    value: progress.percentage,
                    minHeight: 4,
                    backgroundColor: statusColors.info.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation(statusColors.info),
                  ),
                ),
                if (progress.currentItemTitle != null &&
                    progress.currentItemTitle!.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.space4),
                  Text(
                    'Mengunggah: ${progress.currentItemTitle}',
                    style: TextStyle(
                      fontSize: 11,
                      color: statusColors.info.withValues(alpha: 0.8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

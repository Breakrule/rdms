import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models/document_item.dart';
import 'document_visuals.dart';

class SyncStatusBadge extends StatelessWidget {
  final DocumentSyncStatus status;
  final VoidCallback? onRetry;

  const SyncStatusBadge({super.key, required this.status, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final meta = DocumentVisuals.getStatusMeta(context, status);
    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    Widget iconWidget;
    if (status == DocumentSyncStatus.syncing && !disableAnimations) {
      iconWidget = SizedBox(
        width: 12,
        height: 12,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(meta.foreground),
        ),
      );
    } else {
      iconWidget = Icon(meta.icon, size: 14, color: meta.foreground);
    }

    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: meta.background,
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
        border: Border.all(color: meta.foreground.withValues(alpha: 0.25)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            iconWidget,
            const SizedBox(width: AppTheme.space4),
            Text(
              meta.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: meta.foreground,
              ),
            ),
            if (status == DocumentSyncStatus.error && onRetry != null) ...[
              const SizedBox(width: AppTheme.space4),
              Icon(Icons.refresh_rounded, size: 12, color: meta.foreground),
            ],
          ],
        ),
      ),
    );

    if (status == DocumentSyncStatus.error && onRetry != null) {
      return InkWell(
        onTap: onRetry,
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
        child: Tooltip(message: 'Klik untuk mengunggah ulang', child: content),
      );
    }

    return Tooltip(message: meta.description, child: content);
  }
}

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../../../metrics/presentation/productivity_summary_screen.dart';
import '../../../recovery/presentation/recovery_screen.dart';
import '../../../sync_center/presentation/sync_center_screen.dart';
import '../providers/document_providers.dart';
import 'bulk_import_screen.dart';
import 'cloud_sync_settings_modal.dart';

class SidebarUtilitySection extends ConsumerWidget {
  final VoidCallback? onOpenCloudSettings;
  final bool isDrawer;

  const SidebarUtilitySection({
    super.key,
    this.onOpenCloudSettings,
    this.isDrawer = false,
  });

  void _closeDrawer(BuildContext context) {
    if (isDrawer && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _exportRegisterCsv(BuildContext context, WidgetRef ref) async {
    final dir = await FilePicker.getDirectoryPath(
      dialogTitle: 'Tujuan file register CSV',
    );
    if (dir == null || !context.mounted) return;

    final filter = ref.read(documentFilterProvider);
    final sortKey = switch (ref.read(documentSortProvider)) {
      DocumentSort.newest => 'newest',
      DocumentSort.oldest => 'oldest',
      DocumentSort.titleAscending => 'title',
      DocumentSort.documentDateDescending => 'docDate',
    };
    final docs = await ref
        .read(documentRepositoryProvider)
        .watchDocumentPage(
          sortBy: sortKey,
          limit: 100000,
          category: filter.category,
          fiscalYear: filter.fiscalYear,
          syncStatus: filter.syncStatus,
          favoriteOnly: filter.favoriteOnly,
          tagName: filter.tag,
          collectionId: filter.collectionId,
          search: filter.searchQuery.trim().isEmpty
              ? null
              : filter.searchQuery.trim(),
        )
        .first;
    if (!context.mounted) return;
    final tagsByDoc = ref.read(documentTagIndexProvider).value ??
        const <String, Set<String>>{};
    final file = await ref.read(documentExportServiceProvider).exportRegister(
          destination: Directory(dir),
          documents: docs,
          tagsByDocument: tagsByDoc,
        );
    if (context.mounted) {
      CustomToast.show(
        context,
        title: 'Register Diekspor',
        message: '${docs.length} baris ditulis ke ${file.path}',
        type: ToastType.success,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 8, 4),
          child: Text(
            'ALAT & PENGATURAN',
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        _CompactMenuTile(
          icon: Icons.sync_alt_rounded,
          iconColor: const Color(0xFF0284C7),
          title: 'Pusat Sinkronisasi',
          onTap: () {
            _closeDrawer(context);
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const SyncCenterScreen(),
              ),
            );
          },
        ),
        _CompactMenuTile(
          icon: Icons.cloud_sync_outlined,
          iconColor: const Color(0xFF0F52BA),
          title: 'Pengaturan Cloud',
          onTap: () {
            _closeDrawer(context);
            if (onOpenCloudSettings != null) {
              onOpenCloudSettings!();
            } else {
              showDialog(
                context: context,
                builder: (_) => const CloudSyncSettingsModal(),
              );
            }
          },
        ),
        _CompactMenuTile(
          icon: Icons.playlist_add_rounded,
          iconColor: const Color(0xFF7C3AED),
          title: 'Impor Massal',
          onTap: () {
            _closeDrawer(context);
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const BulkImportScreen(),
              ),
            );
          },
        ),
        _CompactMenuTile(
          icon: Icons.table_view_rounded,
          iconColor: const Color(0xFF059669),
          title: 'Ekspor Register (CSV)',
          onTap: () {
            _closeDrawer(context);
            _exportRegisterCsv(context, ref);
          },
        ),
        _CompactMenuTile(
          icon: Icons.folder_open_rounded,
          iconColor: const Color(0xFFD97706),
          title: 'Folder Penyimpanan',
          onTap: () async {
            _closeDrawer(context);
            final selectedDir = await FilePicker.getDirectoryPath(
              dialogTitle: 'Pilih Folder Dokumen',
            );
            if (selectedDir != null && selectedDir.isNotEmpty) {
              await ref
                  .read(storagePathProvider.notifier)
                  .updatePath(selectedDir);
              if (context.mounted) {
                CustomToast.show(
                  context,
                  title: 'Folder Diperbarui',
                  message: 'Lokasi penyimpanan dokumen berhasil dialihkan.',
                  type: ToastType.success,
                );
              }
            }
          },
        ),
        _CompactMenuTile(
          icon: Icons.inventory_2_outlined,
          iconColor: const Color(0xFFE11D48),
          title: 'Pulihkan & Backup',
          onTap: () {
            _closeDrawer(context);
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const RecoveryScreen(),
              ),
            );
          },
        ),
        // Rev.2 P0.4: the metric self-view. Reached from the utility section
        // rather than the main toolbar because it is an occasional read, not a
        // daily action — and because the toolbar is already at its responsive
        // limit on a 320px phone (homepage_redesign_test guards that).
        _CompactMenuTile(
          icon: Icons.insights_rounded,
          iconColor: const Color(0xFF4F46E5),
          title: 'Ringkasan Produktivitas',
          onTap: () {
            _closeDrawer(context);
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ProductivitySummaryScreen(),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _CompactMenuTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final VoidCallback onTap;

  const _CompactMenuTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusChip),
          onTap: onTap,
          hoverColor: theme.colorScheme.primary.withValues(alpha: 0.06),
          splashColor: theme.colorScheme.primary.withValues(alpha: 0.12),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.space8,
              vertical: 5,
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    icon,
                    size: 14,
                    color: iconColor,
                  ),
                ),
                const SizedBox(width: AppTheme.space8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.85),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

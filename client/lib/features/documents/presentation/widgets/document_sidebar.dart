import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart'
    show Collection, SavedView, Tag;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../../../recovery/presentation/recovery_screen.dart';
import '../../../sync_center/presentation/sync_center_screen.dart';
import '../providers/document_providers.dart';
import 'bulk_import_screen.dart';
import 'cloud_sync_settings_modal.dart';
import 'document_visuals.dart';

class DocumentSidebar extends ConsumerWidget {
  final VoidCallback? onBulkSync;
  final VoidCallback? onOpenCloudSettings;
  final bool isDrawer;

  const DocumentSidebar({
    super.key,
    this.onBulkSync,
    this.onOpenCloudSettings,
    this.isDrawer = false,
  });

  static const List<String> defaultCategories = [
    'ALL',
    'SK',
    'Laporan',
    'Notula',
    'Teknis',
    'Peraturan',
  ];

  /// Favorites shortcut, tag filters, collection filters, and saved
  /// views (Phase 4.3 / 4.7). Each row composes with the existing
  /// category/year/status filters rather than replacing them.
  List<Widget> _organizationSections(
    BuildContext context,
    WidgetRef ref,
    DocumentFilterState filterState,
  ) {
    final theme = Theme.of(context);
    final tags = ref.watch(tagsListProvider).value ?? const <Tag>[];
    final collections =
        ref.watch(collectionsListProvider).value ?? const <Collection>[];
    final savedViews =
        ref.watch(savedViewsProvider).value ?? const <SavedView>[];
    final favoriteCount = ref.watch(favoriteCountProvider).value ?? 0;

    Widget header(String label, {VoidCallback? onAdd}) => Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 8, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (onAdd != null)
                IconButton(
                  tooltip: 'Tambah',
                  iconSize: 16,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.add_rounded),
                  onPressed: onAdd,
                ),
            ],
          ),
        );

    Widget row({
      required IconData icon,
      required String title,
      required bool active,
      String? trailing,
      VoidCallback? onTap,
      VoidCallback? onLongPress,
    }) =>
        ListTile(
          dense: true,
          tileColor: active ? theme.colorScheme.primaryContainer : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusChip),
          ),
          leading: Icon(icon, size: 16, color: active ? theme.colorScheme.primary : null),
          title: Text(title,
              style: const TextStyle(fontSize: 12.5),
              overflow: TextOverflow.ellipsis),
          trailing: trailing == null
              ? null
              : Text(trailing, style: const TextStyle(fontSize: 11)),
          onTap: onTap,
          onLongPress: onLongPress,
        );

    void closeDrawer() {
      if (isDrawer && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }

    return [
      header('TAYANGAN'),
      row(
        icon: filterState.favoriteOnly
            ? Icons.star_rounded
            : Icons.star_border_rounded,
        title: 'Favorit',
        trailing: '$favoriteCount',
        active: filterState.favoriteOnly,
        onTap: () {
          ref
              .read(documentFilterProvider.notifier)
              .setFavoriteOnly(!filterState.favoriteOnly);
          closeDrawer();
        },
      ),
      if (tags.isNotEmpty) ...[
        header('TAG'),
        for (final tag in tags)
          row(
            icon: Icons.label_outline_rounded,
            title: tag.name,
            active: filterState.tag == tag.name,
            onTap: () {
              ref
                  .read(documentFilterProvider.notifier)
                  .setTag(filterState.tag == tag.name ? null : tag.name);
              closeDrawer();
            },
            onLongPress: () async {
              final yes = await _confirm(context, 'Hapus tag "${tag.name}"?',
                  'Tag dilepas dari semua dokumen; berkas tidak terhapus.');
              if (yes == true) {
                await ref
                    .read(organizationRepositoryProvider)
                    .deleteTag(tag.id);
              }
            },
          ),
      ],
      if (collections.isNotEmpty) ...[
        header('KOLEKSI', onAdd: () => _promptNewCollection(context, ref)),
        for (final c in collections)
          row(
            icon: Icons.folder_copy_outlined,
            title: c.name,
            active: filterState.collectionId == c.id,
            onTap: () {
              ref
                  .read(documentFilterProvider.notifier)
                  .setCollection(filterState.collectionId == c.id
                      ? null
                      : c.id);
              closeDrawer();
            },
            onLongPress: () async {
              final yes = await _confirm(context, 'Hapus koleksi "${c.name}"?',
                  'Dokumen anggotanya tetap ada di library.');
              if (yes == true) {
                await ref
                    .read(organizationRepositoryProvider)
                    .deleteCollection(c.id);
              }
            },
          ),
      ],
      if (savedViews.isNotEmpty)
        header(
          'TAYANGAN TERSIMPAN',
          onAdd: () => _saveCurrentView(context, ref, filterState),
        ),
      for (final v in savedViews)
        row(
          icon: Icons.bookmark_outline_rounded,
          title: v.name,
          active: false,
          onTap: () {
            final state = DocumentFilterState.fromJson(
                jsonDecode(v.stateJson) as Map<String, dynamic>);
            ref.read(documentFilterProvider.notifier).replaceAll(state);
            closeDrawer();
          },
          onLongPress: () async {
            final yes = await _confirm(context, 'Hapus tampilan "${v.name}"?', '');
            if (yes == true) {
              await ref
                  .read(organizationRepositoryProvider)
                  .deleteSavedView(v.id);
            }
          },
        ),
    ];
  }

  /// Compact utility & system tools section (moved up into primary list).
  List<Widget> _utilitySections(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    void closeDrawer() {
      if (isDrawer && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }

    return [
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
          closeDrawer();
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
          closeDrawer();
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
          closeDrawer();
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
          closeDrawer();
          _exportRegisterCsv(context, ref);
        },
      ),
      _CompactMenuTile(
        icon: Icons.folder_open_rounded,
        iconColor: const Color(0xFFD97706),
        title: 'Folder Penyimpanan',
        onTap: () async {
          closeDrawer();
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
          closeDrawer();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const RecoveryScreen(),
            ),
          );
        },
      ),
    ];
  }

  Future<bool?> _confirm(BuildContext context, String title, String body) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: body.isEmpty ? null : Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Hapus')),
        ],
      ),
    );
  }

  Future<void> _promptNewCollection(BuildContext context, WidgetRef ref,
      {bool isCollection = true}) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isCollection ? 'Koleksi Baru' : 'Tag Baru'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: isCollection ? 120 : 60,
          decoration: InputDecoration(labelText: isCollection ? 'Nama koleksi' : 'Nama tag'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Buat')),
        ],
      ),
    );
    final name = controller.text.trim();
    controller.dispose();
    if (confirmed != true || name.isEmpty || !context.mounted) return;
    final org = ref.read(organizationRepositoryProvider);
    if (isCollection) {
      await org.createCollection(name);
    } else {
      final docs = ref.read(selectedDocumentsProvider);
      if (docs.isNotEmpty) {
        await org.addTagToDocuments(name, docs.map((d) => d.id).toList());
      }
    }
  }

  Future<void> _saveCurrentView(
      BuildContext context, WidgetRef ref, DocumentFilterState current) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Simpan Tampilan Saat Ini'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 80,
          decoration: const InputDecoration(labelText: 'Nama tampilan'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Simpan')),
        ],
      ),
    );
    final name = controller.text.trim();
    controller.dispose();
    if (confirmed != true || name.isEmpty) return;
    await ref
        .read(organizationRepositoryProvider)
        .saveView(name, jsonEncode(current.toJson()));
  }

  /// Phase 4.7: export the currently visible (filtered) document list
  /// as a formula-safe UTF-8 CSV register. Offline; touches only local
  /// metadata.
  Future<void> _exportRegisterCsv(BuildContext context, WidgetRef ref) async {
    final dir = await FilePicker.getDirectoryPath(
      dialogTitle: 'Tujuan file register CSV',
    );
    if (dir == null || !context.mounted) return;
    // Export the FULL filtered set, not just the loaded page: the list is
    // paginated in SQLite now (Phase 5.6).
    final filter = ref.read(documentFilterProvider);
    final sortKey = switch (ref.read(documentSortProvider)) {
      DocumentSort.newest => 'newest',
      DocumentSort.oldest => 'oldest',
      DocumentSort.titleAscending => 'title',
      DocumentSort.documentDateDescending => 'docDate',
    };
    final docs = await ref.read(documentRepositoryProvider).watchDocumentPage(
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
        ).first;
    if (!context.mounted) return;
    final tagsByDoc =
        ref.read(documentTagIndexProvider).value ?? const <String, Set<String>>{};
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
    final themeMode = ref.watch(themeModeProvider);
    final filterState = ref.watch(documentFilterProvider);
    final selectedCategory = filterState.category;
    final totalActive = ref.watch(activeDocumentCountProvider).value ?? 0;
    final categoryCounts =
        ref.watch(documentCategoryCountsProvider).value ??
            const <String, int>{};

    // Build unique category list: show ALL, currently selected category, and categories with active documents
    final categories = <String>['ALL'];
    for (final cat in defaultCategories) {
      if (cat != 'ALL') {
        final count = categoryCounts[cat] ?? 0;
        if (count > 0 || selectedCategory == cat) {
          categories.add(cat);
        }
      }
    }
    for (final cat in categoryCounts.keys) {
      if (!categories.contains(cat) && (categoryCounts[cat] ?? 0) > 0) {
        categories.add(cat);
      }
    }

    return Material(
      color: theme.colorScheme.surface,
      child: Container(
        width: 256,
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header / Branding
            SafeArea(
              bottom: false,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space20,
                  vertical: AppTheme.space16,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: theme.dividerColor.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusControl,
                        ),
                        color: theme.colorScheme.primary,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        'assets/images/icon.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.shield_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'RDMS',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Ultimate',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'Ruang Kerja Lokal',
                            style: theme.textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Navigation List (Categories)
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space12,
                  vertical: AppTheme.space8,
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.space8,
                      vertical: AppTheme.space6,
                    ),
                    child: Text(
                      'KATEGORI DOKUMEN',
                      style: theme.textTheme.labelSmall?.copyWith(
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  ...categories.map((cat) {
                    final isSelected = selectedCategory == cat;
                    final meta = DocumentVisuals.getCategoryMeta(cat);
                    final count = cat == 'ALL'
                        ? totalActive
                        : (categoryCounts[cat] ?? 0);

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: ListTile(
                        dense: true,
                        tileColor: isSelected
                            ? theme.colorScheme.primaryContainer
                            : Colors.transparent,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.space12,
                          vertical: 0,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusChip,
                          ),
                        ),
                        leading: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : meta.containerColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            meta.icon,
                            size: 16,
                            color: isSelected
                                ? Colors.white
                                : meta.color,
                          ),
                        ),
                        title: Text(
                          cat == 'ALL' ? 'Semua Dokumen' : cat,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isSelected
                                ? theme.colorScheme.onPrimaryContainer
                                : null,
                          ),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colorScheme.primary.withValues(
                                    alpha: 0.15,
                                  )
                                : theme.colorScheme.surfaceContainerHighest
                                      .withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$count',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface.withValues(
                                      alpha: 0.6,
                                    ),
                            ),
                          ),
                        ),
                        onTap: () {
                          ref
                              .read(documentFilterProvider.notifier)
                              .setCategory(cat);
                          if (isDrawer && Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          }
                        },
                      ),
                    );
                  }),

                  // ---- Phase 4.3/4.7 organization sections --------
                  ..._organizationSections(context, ref, filterState),

                  // ---- Compact utilities moved up from bottom --------
                  ..._utilitySections(context, ref),
                ],
              ),
            ),

            // Footer: Compact Theme Mode Selector
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space12,
                  vertical: AppTheme.space8,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: theme.dividerColor.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(AppTheme.space4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusControl),
                    border: Border.all(
                      color: theme.dividerColor.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Row(
                    children: [
                      _ThemeModePill(
                        label: 'Sistem',
                        icon: Icons.brightness_auto_rounded,
                        isSelected: themeMode == ThemeMode.system,
                        activeColor: const Color(0xFF3B82F6),
                        onTap: () => ref
                            .read(themeModeProvider.notifier)
                            .setThemeMode(ThemeMode.system),
                      ),
                      const SizedBox(width: AppTheme.space4),
                      _ThemeModePill(
                        label: 'Terang',
                        icon: Icons.light_mode_rounded,
                        isSelected: themeMode == ThemeMode.light,
                        activeColor: const Color(0xFFF59E0B),
                        onTap: () => ref
                            .read(themeModeProvider.notifier)
                            .setThemeMode(ThemeMode.light),
                      ),
                      const SizedBox(width: AppTheme.space4),
                      _ThemeModePill(
                        label: 'Gelap',
                        icon: Icons.dark_mode_rounded,
                        isSelected: themeMode == ThemeMode.dark,
                        activeColor: const Color(0xFF818CF8),
                        onTap: () => ref
                            .read(themeModeProvider.notifier)
                            .setThemeMode(ThemeMode.dark),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeModePill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  const _ThemeModePill({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusChip),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.surface
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppTheme.radiusChip),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 13,
                      color: isSelected
                          ? activeColor
                          : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
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

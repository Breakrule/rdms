import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/dummy_data_seeder.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../../domain/models/document_item.dart';
import '../providers/document_providers.dart';
import 'document_list_item.dart';

class DocumentListView extends ConsumerWidget {
  final VoidCallback onOpenAddDocument;
  final VoidCallback onOpenCommandPalette;
  final void Function(DocumentItem doc)? onSelectDocument;

  const DocumentListView({
    super.key,
    required this.onOpenAddDocument,
    required this.onOpenCommandPalette,
    this.onSelectDocument,
  });

  Future<void> _handleRefresh(BuildContext context, WidgetRef ref) async {
    ref.read(homeOperationProvider.notifier).setRefreshing(true);
    try {
      final summary = await ref
          .read(syncQueueServiceProvider)
          .reconcileAllDocuments();
      if (context.mounted) {
        if (summary.totalChecked == 0) {
          CustomToast.show(
            context,
            title: 'Daftar Diperbarui',
            message: 'Daftar dokumen telah dimuat ulang.',
            type: ToastType.info,
          );
        } else if (summary.markedInaccessible > 0 || summary.markedRenamed > 0) {
          CustomToast.show(
            context,
            title: 'Status Sinkronisasi Diperbarui',
            message:
                '${summary.markedInaccessible} berkas tidak dapat diakses di Drive, ${summary.markedRenamed} berubah nama.',
            type: ToastType.warning,
          );
        } else if (summary.isUnreachable) {
          CustomToast.show(
            context,
            title: 'Pemeriksaan Tidak Lengkap',
            message: 'Tidak dapat memeriksa Google Drive (offline atau belum terhubung). Status lokal dipertahankan.',
            type: ToastType.info,
          );
        } else {
          CustomToast.show(
            context,
            title: 'Status Diperiksa',
            message:
                '${summary.verifiedSynced} berkas terverifikasi di Google Drive.',
            type: ToastType.success,
          );
        }
      }
    } finally {
      ref.read(homeOperationProvider.notifier).setRefreshing(false);
    }
  }

  void _handleSelectDocument(WidgetRef ref, DocumentItem doc) {
    if (onSelectDocument != null) {
      onSelectDocument!(doc);
    } else {
      ref.read(selectedDocumentProvider.notifier).select(doc);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final docsAsync = ref.watch(documentsListStreamProvider);
    final totalActive = ref.watch(activeDocumentCountProvider).value ?? 0;
    final filterState = ref.watch(documentFilterProvider);
    final selectedId = ref.watch(selectedDocumentProvider.select((d) => d?.id));
    final selectedDocs = ref.watch(selectedDocumentsProvider);

    final content = docsAsync.when(
      skipLoadingOnReload: true,
      data: (docs) {
        if (docs.isEmpty) {
          final isDatabaseEmpty = totalActive == 0;
          return RefreshIndicator(
            onRefresh: () => _handleRefresh(context, ref),
            color: theme.colorScheme.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  AppTheme.space24,
                  AppTheme.space48,
                  AppTheme.space24,
                  AppTheme.space48 + MediaQuery.paddingOf(context).bottom,
                ),
                alignment: Alignment.center,
                child: _buildEmptyState(
                  context,
                  ref,
                  isDatabaseEmpty: isDatabaseEmpty,
                  filterState: filterState,
                  onOpenAddDocument: onOpenAddDocument,
                ),
              ),
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final textScale = MediaQuery.textScalerOf(context).scale(1.0);
            final isStacked = constraints.maxWidth < 840 || textScale > 1.3;

            return RefreshIndicator(
              onRefresh: () => _handleRefresh(context, ref),
              color: theme.colorScheme.primary,
              // Phase 5.6: request the next page from SQLite as the user
              // nears the bottom, so only a page is ever materialized
              // instead of the whole library (the large-library freeze).
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  final metrics = notification.metrics;
                  if (metrics.axis == Axis.vertical &&
                      metrics.pixels >= metrics.maxScrollExtent - 480 &&
                      ref.read(documentListHasMoreProvider)) {
                    ref.read(documentListLimitProvider.notifier).loadMore();
                  }
                  return false;
                },
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.only(
                    bottom: AppTheme.space48 +
                        MediaQuery.paddingOf(context).bottom +
                        32,
                  ),
                  itemCount: docs.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    color: theme.dividerColor.withValues(alpha: 0.08),
                  ),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    return DocumentListItem(
                      key: ValueKey(doc.id),
                      doc: doc,
                      isSelected: selectedId == doc.id,
                      isStacked: isStacked,
                      onSelect: (selectedDoc) =>
                          _handleSelectDocument(ref, selectedDoc),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
      loading: () => _buildLoadingSkeleton(context),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: AppTheme.space16),
              Text(
                'Terjadi kesalahan saat memuat dokumen',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppTheme.space8),
              Text(
                '$err',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: AppTheme.space16),
              FilledButton.icon(
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Coba Lagi'),
                onPressed: () {
                  ref.invalidate(documentsListStreamProvider);
                  ref.invalidate(documentSummaryStreamProvider);
                  ref.invalidate(filteredDocumentCountProvider);
                },
              ),
            ],
          ),
        ),
      ),
    );

    // Phase 4.6: the action bar states the exact count and names scope,
    // and every action operates on [selectedDocumentsProvider] (live
    // documents, not stale ids).
    return Column(
      children: [
        if (selectedDocs.isNotEmpty) _SelectionActionBar(documents: selectedDocs),
        Expanded(child: content),
      ],
    );
  }
}

class _SelectionActionBar extends ConsumerWidget {
  final List<DocumentItem> documents;

  const _SelectionActionBar({required this.documents});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.secondaryContainer,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space12,
            vertical: AppTheme.space4,
          ),
          child: Row(
            children: [
              Icon(Icons.checklist_rounded, size: 18, color: theme.colorScheme.onSecondaryContainer),
              const SizedBox(width: AppTheme.space8),
              Expanded(
                child: Text(
                  '${documents.length} dokumen terpilih',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.label_outline_rounded, size: 16),
                label: const Text('Tag'),
                onPressed: () => _applyTag(context, ref),
              ),
              TextButton.icon(
                icon: const Icon(Icons.cloud_upload_outlined, size: 16),
                label: const Text('Cadangkan'),
                onPressed: () => _queueBackup(context, ref),
              ),
              TextButton.icon(
                icon: const Icon(Icons.download_rounded, size: 16),
                label: const Text('Ekspor Berkas'),
                onPressed: () => _exportFiles(context, ref),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
                icon: const Icon(Icons.delete_outline_rounded, size: 16),
                label: const Text('Ke Sampah'),
                onPressed: () => _moveToTrash(context, ref),
              ),
              IconButton(
                tooltip: 'Batal pilih',
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: () => ref.read(documentSelectionProvider.notifier).clear(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _applyTag(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Pasang tag ke ${documents.length} dokumen'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 60,
          decoration: const InputDecoration(labelText: 'Nama tag'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Pasang')),
        ],
      ),
    );
    final name = controller.text.trim().toLowerCase();
    controller.dispose();
    if (confirmed != true || name.isEmpty || !context.mounted) return;
    await ref.read(organizationRepositoryProvider).addTagToDocuments(
      name,
      documents.map((d) => d.id).toList(),
    );
    if (context.mounted) {
      CustomToast.show(
        context,
        title: 'Tag dipasang',
        message: '"$name" ditambahkan ke ${documents.length} dokumen.',
        type: ToastType.success,
      );
    }
  }

  Future<void> _queueBackup(BuildContext context, WidgetRef ref) async {
    final binding = await ref.read(syncAccountBindingProvider.future);
    final queue = ref.read(syncQueueServiceProvider);
    var count = 0;
    for (final d in documents) {
      if (d.syncStatus == DocumentSyncStatus.localOnly ||
          d.syncStatus == DocumentSyncStatus.error) {
        await queue.enqueueUpload(doc: d, accountBinding: binding);
        count++;
      }
    }
    if (context.mounted) {
      CustomToast.show(
        context,
        title: 'Antrean Cadangan',
        message: '$count dari ${documents.length} dokumen diantrekan.',
        type: ToastType.info,
      );
    }
    unawaited(queue.processQueue(accountBinding: binding));
  }

  Future<void> _exportFiles(BuildContext context, WidgetRef ref) async {
    final dir = await FilePicker.getDirectoryPath(
      dialogTitle: 'Tujuan ekspor berkas terpilih',
    );
    if (dir == null || !context.mounted) return;
    final summary = await ref
        .read(documentExportServiceProvider)
        .exportFiles(destination: Directory(dir), documents: documents);
    if (context.mounted) {
      CustomToast.show(
        context,
        title: 'Ekspor Berkas',
        message: '${summary.copied} disalin, ${summary.missing} tidak ditemukan.',
        type: summary.missing == 0 ? ToastType.success : ToastType.warning,
      );
    }
  }

  Future<void> _moveToTrash(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pindahkan ke Tempat Sampah?'),
        content: Text(
          '${documents.length} dokumen akan dipindahkan ke tempat sampah lokal '
          'dan tetap bisa dipulihkan. Salinan Google Drive tidak terpengaruh.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Pindahkan'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final repo = ref.read(documentRepositoryProvider);
    for (final d in documents) {
      await repo.trashDocument(d.id);
    }
    final currentSelected = ref.read(selectedDocumentProvider);
    if (currentSelected != null && documents.any((d) => d.id == currentSelected.id)) {
      ref.read(selectedDocumentProvider.notifier).clear();
    }
    ref.read(documentSelectionProvider.notifier).clear();
    if (context.mounted) {
      CustomToast.show(
        context,
        title: 'Dipindahkan ke Tempat Sampah',
        message: '${documents.length} dokumen bisa dipulihkan dari Pulihkan & Backup.',
        type: ToastType.info,
      );
    }
  }
}

// Phase 4.6 restructure note: these two render helpers are now
// top-level functions (the selection action bar lives in its own class
// between the widget body and them). Behaviour is unchanged.
Widget _buildEmptyState(
  BuildContext context,
  WidgetRef ref, {
  required bool isDatabaseEmpty,
  required DocumentFilterState filterState,
  required VoidCallback onOpenAddDocument,
}) {
    final theme = Theme.of(context);

    if (isDatabaseEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.folder_open_rounded,
              size: 36,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: AppTheme.space16),
          Text(
            'Belum ada dokumen',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppTheme.space8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Text(
              'Dokumen yang diimpor akan disimpan secara lokal di perangkat Anda dan dapat dicadangkan ke Google Drive.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: AppTheme.space24),
          Wrap(
            spacing: AppTheme.space12,
            runSpacing: AppTheme.space8,
            alignment: WrapAlignment.center,
            children: [
              FilledButton.icon(
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Tambah Dokumen'),
                onPressed: onOpenAddDocument,
              ),
              if (kDebugMode)
                OutlinedButton.icon(
                  icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                  label: const Text('Muat Dokumen Contoh'),
                  onPressed: () async {
                    final repo = ref.read(documentRepositoryProvider);
                    final count = await DummyDataSeeder.seedDocuments(repo);
                    if (context.mounted) {
                      CustomToast.show(
                        context,
                        title: 'Dokumen Contoh Dimuat',
                        message: '$count dokumen contoh berhasil ditambahkan',
                        type: ToastType.success,
                      );
                    }
                  },
                ),
            ],
          ),
        ],
      );
    }

    if (filterState.searchQuery.isNotEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 56,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: AppTheme.space16),
          Text(
            'Dokumen tidak ditemukan',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppTheme.space8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Text(
              'Tidak ada dokumen yang cocok dengan kata kunci "${filterState.searchQuery}".',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: AppTheme.space16),
          Wrap(
            spacing: AppTheme.space12,
            children: [
              OutlinedButton(
                onPressed: () {
                  ref.read(documentFilterProvider.notifier).clearSearchQuery();
                },
                child: const Text('Hapus Pencarian'),
              ),
              if (filterState.hasActiveFilters)
                TextButton(
                  onPressed: () {
                    ref.read(documentFilterProvider.notifier).resetFilters();
                  },
                  child: const Text('Reset Filter Lainnya'),
                ),
            ],
          ),
        ],
      );
    }

    // Filter-only empty result
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.filter_alt_off_rounded,
          size: 56,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
        ),
        const SizedBox(height: AppTheme.space16),
        Text(
          'Tidak ada dokumen untuk filter ini',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppTheme.space8),
        Text(
          'Coba ubah atau reset filter kategori, tahun, atau status sinkronisasi.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: AppTheme.space16),
        FilledButton.icon(
          icon: const Icon(Icons.restart_alt_rounded, size: 18),
          label: const Text('Reset Filter'),
          onPressed: () {
            ref.read(documentFilterProvider.notifier).resetFilters();
          },
        ),
      ],
    );
  }

  Widget _buildLoadingSkeleton(BuildContext context) {
    final theme = Theme.of(context);
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      separatorBuilder: (_, _) =>
          Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.08)),
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space16,
            vertical: AppTheme.space12,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.4,
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusControl),
                ),
              ),
              const SizedBox(width: AppTheme.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 16,
                      width: 220,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 12,
                      width: 140,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.space12),
              Container(
                height: 24,
                width: 80,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.3,
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

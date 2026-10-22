import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../../domain/models/document_item.dart';
import '../providers/document_providers.dart';
import 'document_empty_state.dart';
import 'document_list_item.dart';
import 'multi_select_action_bar.dart';

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
    final hasSelection =
        ref.watch(documentSelectionProvider.select((s) => s.isNotEmpty));

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
                child: DocumentEmptyState(
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
        if (hasSelection) const _MultiSelectBarConsumer(),
        Expanded(child: content),
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
}

class _MultiSelectBarConsumer extends ConsumerWidget {
  const _MultiSelectBarConsumer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDocs = ref.watch(selectedDocumentsProvider);
    if (selectedDocs.isEmpty) return const SizedBox.shrink();
    return MultiSelectActionBar(documents: selectedDocs);
  }
}


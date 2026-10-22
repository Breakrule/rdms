import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/dummy_data_seeder.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../providers/document_providers.dart';

class DocumentEmptyState extends ConsumerWidget {
  final bool isDatabaseEmpty;
  final DocumentFilterState filterState;
  final VoidCallback onOpenAddDocument;

  const DocumentEmptyState({
    super.key,
    required this.isDatabaseEmpty,
    required this.filterState,
    required this.onOpenAddDocument,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
}

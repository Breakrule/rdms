import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models/document_item.dart';
import '../providers/document_providers.dart';
import 'document_visuals.dart';

class DocumentToolbar extends ConsumerStatefulWidget {
  final FocusNode searchFocusNode;
  final VoidCallback onOpenCommandPalette;
  final int visibleCount;

  const DocumentToolbar({
    super.key,
    required this.searchFocusNode,
    required this.onOpenCommandPalette,
    required this.visibleCount,
  });

  @override
  ConsumerState<DocumentToolbar> createState() => _DocumentToolbarState();
}

class _DocumentToolbarState extends ConsumerState<DocumentToolbar> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    final initialQuery = ref.read(documentFilterProvider).searchQuery;
    _searchController = TextEditingController(text: initialQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) =>
          _FilterBottomSheet(onClose: () => Navigator.of(ctx).pop()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filterState = ref.watch(documentFilterProvider);
    final sortState = ref.watch(documentSortProvider);
    final isCompact = MediaQuery.sizeOf(context).width < 600;

    // Sync external query changes to text field controller
    if (_searchController.text != filterState.searchQuery) {
      _searchController.value = _searchController.value.copyWith(
        text: filterState.searchQuery,
        selection: TextSelection.collapsed(
          offset: filterState.searchQuery.length,
        ),
      );
    }

    int activeFilterCount = 0;
    if (filterState.category != 'ALL') activeFilterCount++;
    if (filterState.fiscalYear != null) activeFilterCount++;
    if (filterState.syncStatus != 'ALL') activeFilterCount++;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? AppTheme.space16 : AppTheme.space24,
        vertical: AppTheme.space8,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Row 1: Search + Sort + Command Palette Shortcut + Compact Filter Button
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: widget.searchFocusNode,
                  decoration: InputDecoration(
                    hintText: 'Cari judul, nomor, atau teks dokumen…',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: filterState.searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            tooltip: 'Hapus Pencarian',
                            onPressed: () {
                              _searchController.clear();
                              ref
                                  .read(documentFilterProvider.notifier)
                                  .clearSearchQuery();
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  onChanged: (val) {
                    ref
                        .read(documentFilterProvider.notifier)
                        .setSearchQuery(val);
                  },
                ),
              ),
              const SizedBox(width: AppTheme.space8),
              if (isCompact) ...[
                Badge(
                  isLabelVisible: activeFilterCount > 0,
                  label: Text('$activeFilterCount'),
                  child: IconButton.outlined(
                    icon: const Icon(Icons.filter_list_rounded, size: 20),
                    tooltip: 'Filter Dokumen',
                    onPressed: () => _openFilterSheet(context),
                  ),
                ),
                const SizedBox(width: AppTheme.space8),
                IconButton.outlined(
                  icon: const Icon(Icons.terminal_rounded, size: 20),
                  tooltip: 'Command Palette (Ctrl+K)',
                  onPressed: widget.onOpenCommandPalette,
                ),
              ] else ...[
                // Sort Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(AppTheme.radiusControl),
                    border: Border.all(color: theme.dividerColor.withValues(alpha: 0.15)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<DocumentSort>(
                      value: sortState,
                      isDense: true,
                      borderRadius: BorderRadius.circular(AppTheme.radiusControl),
                      items: DocumentSort.values.map((sort) {
                        return DropdownMenuItem(
                          value: sort,
                          child: Text(
                            sort.label,
                            style: const TextStyle(fontSize: 12.5),
                          ),
                        );
                      }).toList(),
                      onChanged: (newSort) {
                        if (newSort != null) {
                          ref
                              .read(documentSortProvider.notifier)
                              .setSort(newSort);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.space8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.terminal_rounded, size: 16),
                  label: const Text('Ctrl+K'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  onPressed: widget.onOpenCommandPalette,
                ),
              ],
            ],
          ),

          // Row 2: Removable Active Filter Chips & Reset
          if (filterState.hasActiveFilters) ...[
            const SizedBox(height: AppTheme.space8),
            Wrap(
              spacing: AppTheme.space8,
              runSpacing: AppTheme.space4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (filterState.category != 'ALL')
                  Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text('Kategori: ${filterState.category}'),
                    deleteIcon: const Icon(Icons.close_rounded, size: 14),
                    onDeleted: () {
                      ref
                          .read(documentFilterProvider.notifier)
                          .setCategory('ALL');
                    },
                  ),
                if (filterState.fiscalYear != null)
                  Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text('Tahun: ${filterState.fiscalYear}'),
                    deleteIcon: const Icon(Icons.close_rounded, size: 14),
                    onDeleted: () {
                      ref
                          .read(documentFilterProvider.notifier)
                          .setFiscalYear(null);
                    },
                  ),
                if (filterState.syncStatus != 'ALL')
                  Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text(
                      'Status: ${_formatStatusName(context, filterState.syncStatus)}',
                    ),
                    deleteIcon: const Icon(Icons.close_rounded, size: 14),
                    onDeleted: () {
                      ref
                          .read(documentFilterProvider.notifier)
                          .setSyncStatus('ALL');
                    },
                  ),
                ActionChip(
                  visualDensity: VisualDensity.compact,
                  label: const Text('Reset Filter'),
                  avatar: const Icon(Icons.restart_alt_rounded, size: 14),
                  onPressed: () {
                    ref
                        .read(documentFilterProvider.notifier)
                        .resetFilters();
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatStatusName(BuildContext context, String statusKey) {
    try {
      final statusEnum = DocumentSyncStatus.values.firstWhere(
        (e) => e.name == statusKey,
      );
      return DocumentVisuals.getStatusMeta(context, statusEnum).label;
    } catch (_) {
      return statusKey;
    }
  }
}

class _FilterBottomSheet extends ConsumerWidget {
  final VoidCallback onClose;

  const _FilterBottomSheet({required this.onClose});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final filter = ref.watch(documentFilterProvider);
    final allDocs = ref.watch(allDocumentsStreamProvider).asData?.value ?? [];

    // Derive available categories
    final availableCategories = {
      'ALL',
      'SK',
      'Laporan',
      'Notula',
      'Teknis',
      'Surat Keputusan',
      'Peraturan',
    };
    if (filter.category.isNotEmpty) {
      availableCategories.add(filter.category);
    }
    for (final doc in allDocs) {
      if (doc.category.isNotEmpty) availableCategories.add(doc.category);
    }

    // Derive available fiscal years
    final availableYears = <int>{DateTime.now().year};
    if (filter.fiscalYear != null) {
      availableYears.add(filter.fiscalYear!);
    }
    for (final doc in allDocs) {
      if (doc.fiscalYear > 0) availableYears.add(doc.fiscalYear);
    }
    final sortedYears = availableYears.toList()..sort((a, b) => b.compareTo(a));

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter Dokumen',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  ref.read(documentFilterProvider.notifier).resetFilters();
                },
                child: const Text('Reset'),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: AppTheme.space8),

          // Categories
          Text('Kategori', style: theme.textTheme.labelMedium),
          const SizedBox(height: AppTheme.space4),
          DropdownButtonFormField<String>(
            initialValue: filter.category,
            isDense: true,
            items: availableCategories.map((cat) {
              return DropdownMenuItem(
                value: cat,
                child: Text(cat == 'ALL' ? 'Semua Kategori' : cat),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                ref.read(documentFilterProvider.notifier).setCategory(val);
              }
            },
          ),
          const SizedBox(height: AppTheme.space12),

          // Fiscal Year
          Text('Tahun Anggaran', style: theme.textTheme.labelMedium),
          const SizedBox(height: AppTheme.space4),
          DropdownButtonFormField<int?>(
            initialValue: filter.fiscalYear,
            isDense: true,
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('Semua Tahun'),
              ),
              ...sortedYears.map((year) {
                return DropdownMenuItem<int?>(
                  value: year,
                  child: Text('Tahun $year'),
                );
              }),
            ],
            onChanged: (val) {
              ref.read(documentFilterProvider.notifier).setFiscalYear(val);
            },
          ),
          const SizedBox(height: AppTheme.space12),

          // Sync Status
          Text('Status Sinkronisasi', style: theme.textTheme.labelMedium),
          const SizedBox(height: AppTheme.space4),
          DropdownButtonFormField<String>(
            initialValue: filter.syncStatus,
            isDense: true,
            items: [
              const DropdownMenuItem(value: 'ALL', child: Text('Semua Status')),
              ...DocumentSyncStatus.values.map((status) {
                return DropdownMenuItem(
                  value: status.name,
                  child: Text(
                    DocumentVisuals.getStatusMeta(context, status).label,
                  ),
                );
              }),
            ],
            onChanged: (val) {
              if (val != null) {
                ref.read(documentFilterProvider.notifier).setSyncStatus(val);
              }
            },
          ),
          const SizedBox(height: AppTheme.space24),

          FilledButton(onPressed: onClose, child: const Text('Selesai')),
        ],
      ),
    );
  }
}

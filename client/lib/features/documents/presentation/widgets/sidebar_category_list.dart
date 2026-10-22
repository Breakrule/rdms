import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models/document_categories.dart';
import 'document_visuals.dart';

class SidebarCategoryList extends StatelessWidget {
  final String selectedCategory;
  final int totalActive;
  final Map<String, int> categoryCounts;
  final ValueChanged<String> onSelectCategory;

  const SidebarCategoryList({
    super.key,
    required this.selectedCategory,
    required this.totalActive,
    required this.categoryCounts,
    required this.onSelectCategory,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Build unique category list: show ALL, currently selected category, and categories with active documents
    final categories = <String>['ALL'];
    for (final cat in DocumentCategories.defaultKeys) {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
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
          final count =
              cat == 'ALL' ? totalActive : (categoryCounts[cat] ?? 0);

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
                  color: isSelected ? Colors.white : meta.color,
                ),
              ),
              title: Text(
                cat == 'ALL' ? 'Semua Dokumen' : cat,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.w500,
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
              onTap: () => onSelectCategory(cat),
            ),
          );
        }),
      ],
    );
  }
}

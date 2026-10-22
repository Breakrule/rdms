import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/document_providers.dart';
import 'sidebar_category_list.dart';
import 'sidebar_organization_section.dart';
import 'sidebar_theme_selector.dart';
import 'sidebar_utility_section.dart';

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

  static const List<String> defaultCategories = DocumentCategories.defaultKeys;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final filterState = ref.watch(documentFilterProvider);
    final selectedCategory = filterState.category;
    final totalActive = ref.watch(activeDocumentCountProvider).value ?? 0;
    final categoryCounts =
        ref.watch(documentCategoryCountsProvider).value ??
            const <String, int>{};

    return Material(
      color: theme.colorScheme.surface,
      child: Container(
        width: 256,
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(
              color: theme.dividerColor.withValues(alpha: 0.1),
            ),
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

            // Navigation List (Categories + Organization + Utilities)
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space12,
                  vertical: AppTheme.space8,
                ),
                children: [
                  SidebarCategoryList(
                    selectedCategory: selectedCategory,
                    totalActive: totalActive,
                    categoryCounts: categoryCounts,
                    onSelectCategory: (cat) {
                      ref
                          .read(documentFilterProvider.notifier)
                          .setCategory(cat);
                      if (isDrawer && Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                  SidebarOrganizationSection(isDrawer: isDrawer),
                  SidebarUtilitySection(
                    onOpenCloudSettings: onOpenCloudSettings,
                    isDrawer: isDrawer,
                  ),
                ],
              ),
            ),

            // Footer: Theme Mode Selector
            const SidebarThemeSelector(),
          ],
        ),
      ),
    );
  }
}

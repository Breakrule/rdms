import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../documents/presentation/providers/document_providers.dart';

class HomeHeader extends ConsumerWidget {
  final VoidCallback onOpenAddDocument;
  final VoidCallback onTriggerBulkUpload;
  final VoidCallback onOpenCloudSettings;
  final VoidCallback? onOpenDrawer;

  const HomeHeader({
    super.key,
    required this.onOpenAddDocument,
    required this.onTriggerBulkUpload,
    required this.onOpenCloudSettings,
    this.onOpenDrawer,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final operationState = ref.watch(homeOperationProvider);
    final isBusy = operationState.isAnyOperationActive;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final textScale = MediaQuery.textScalerOf(context).scale(1.0);
        final effectiveWidth =
            availableWidth / (textScale > 1.0 ? textScale : 1.0);
        final isCompact = effectiveWidth < 600;
        final isDrawer = onOpenDrawer != null;

        final isDark = theme.brightness == Brightness.dark;
        final overlayStyle = SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: isDark
              ? Brightness.light
              : Brightness.dark,
        );

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: overlayStyle,
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: theme.dividerColor.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: SafeArea(
              bottom: false,
              left: false,
              right: false,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? AppTheme.space16 : AppTheme.space24,
                  vertical: isCompact ? AppTheme.space12 : AppTheme.space16,
                ),
                child: Row(
                  children: [
                    if (isDrawer) ...[
                      IconButton(
                        icon: const Icon(Icons.menu_rounded),
                        tooltip: 'Buka Menu',
                        onPressed: onOpenDrawer,
                      ),
                      const SizedBox(width: AppTheme.space8),
                    ],
                    Expanded(
                      child: Text(
                        'Pusat Dokumen',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppTheme.space8),

                    if (isCompact) ...[
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded),
                        tooltip: 'Menu Lainnya',
                        onSelected: (val) {
                          if (val == 'toggle_theme') {
                            ref.read(themeModeProvider.notifier).toggleTheme();
                          }
                          if (val == 'bulk_upload') onTriggerBulkUpload();
                          if (val == 'cloud_settings') onOpenCloudSettings();
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'toggle_theme',
                            child: Row(
                              children: [
                                Icon(
                                  themeMode == ThemeMode.light
                                      ? Icons.light_mode_rounded
                                      : (themeMode == ThemeMode.dark
                                          ? Icons.dark_mode_rounded
                                          : Icons.brightness_auto_rounded),
                                  size: 18,
                                  color: themeMode == ThemeMode.light
                                      ? const Color(0xFFF59E0B)
                                      : (themeMode == ThemeMode.dark
                                          ? const Color(0xFF818CF8)
                                          : null),
                                ),
                                const SizedBox(width: AppTheme.space12),
                                Text(
                                  switch (themeMode) {
                                    ThemeMode.system => 'Ganti Tema (Sistem)',
                                    ThemeMode.light => 'Ganti Tema (Terang)',
                                    ThemeMode.dark => 'Ganti Tema (Gelap)',
                                  },
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'bulk_upload',
                            enabled: !isBusy,
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.cloud_upload_outlined,
                                  size: 18,
                                  color: Color(0xFF059669),
                                ),
                                SizedBox(width: AppTheme.space12),
                                Text('Unggah Semua'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'cloud_settings',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.cloud_sync_outlined,
                                  size: 18,
                                  color: Color(0xFF0F52BA),
                                ),
                                SizedBox(width: AppTheme.space12),
                                Text('Pengaturan Cloud'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: availableWidth * 0.65,
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Animated theme switch button with micro-animation
                              IconButton.outlined(
                                icon: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 250),
                                  transitionBuilder: (child, anim) => RotationTransition(
                                    turns: Tween<double>(begin: 0.8, end: 1.0).animate(anim),
                                    child: ScaleTransition(scale: anim, child: child),
                                  ),
                                  child: Icon(
                                    themeMode == ThemeMode.light
                                        ? Icons.light_mode_rounded
                                        : (themeMode == ThemeMode.dark
                                            ? Icons.dark_mode_rounded
                                            : Icons.brightness_auto_rounded),
                                    key: ValueKey(themeMode),
                                    size: 18,
                                    color: themeMode == ThemeMode.light
                                        ? const Color(0xFFF59E0B)
                                        : (themeMode == ThemeMode.dark
                                            ? const Color(0xFF818CF8)
                                            : theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                                  ),
                                ),
                                tooltip: switch (themeMode) {
                                  ThemeMode.system => 'Tema: Ikuti Sistem (Klik untuk beralih)',
                                  ThemeMode.light => 'Tema: Terang (Klik untuk beralih)',
                                  ThemeMode.dark => 'Tema: Gelap (Klik untuk beralih)',
                                },
                                onPressed: () =>
                                    ref.read(themeModeProvider.notifier).toggleTheme(),
                              ),
                              const SizedBox(width: AppTheme.space8),

                              IconButton.outlined(
                                icon: const Icon(
                                  Icons.cloud_sync_outlined,
                                  size: 18,
                                  color: Color(0xFF0F52BA),
                                ),
                                tooltip: 'Pengaturan Cloud',
                                onPressed: onOpenCloudSettings,
                              ),
                              const SizedBox(width: AppTheme.space8),
                              OutlinedButton.icon(
                                icon: operationState.isBulkUploading
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.cloud_upload_outlined,
                                        size: 18,
                                        color: Color(0xFF059669),
                                      ),
                                label: const Text('Unggah Semua'),
                                onPressed: isBusy ? null : onTriggerBulkUpload,
                              ),
                              const SizedBox(width: AppTheme.space12),
                              FilledButton.icon(
                                icon: const Icon(Icons.add_rounded, size: 18),
                                label: const Text('Tambah Dokumen'),
                                onPressed: onOpenAddDocument,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

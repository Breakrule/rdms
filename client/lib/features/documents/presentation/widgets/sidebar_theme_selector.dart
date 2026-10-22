import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_provider.dart';

class SidebarThemeSelector extends ConsumerWidget {
  const SidebarThemeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeProvider);

    return SafeArea(
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
            borderRadius: BorderRadius.circular(AppTheme.radiusControl),
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/documents/presentation/providers/document_providers.dart';

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _storageKey = 'app_theme_mode';

  @override
  ThemeMode build() {
    _loadPersisted();
    return ThemeMode.system;
  }

  Future<void> _loadPersisted() async {
    try {
      final tokenStorage = ref.read(tokenStorageServiceProvider);
      final saved = await tokenStorage.getCustomKey(_storageKey);
      if (saved == 'light') {
        state = ThemeMode.light;
      } else if (saved == 'dark') {
        state = ThemeMode.dark;
      } else if (saved == 'system') {
        state = ThemeMode.system;
      }
    } catch (e) {
      debugPrint('Failed to load persisted theme mode: $e');
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    try {
      final tokenStorage = ref.read(tokenStorageServiceProvider);
      await tokenStorage.setCustomKey(_storageKey, mode.name);
    } catch (e) {
      debugPrint('Failed to persist theme mode: $e');
    }
  }

  void toggleTheme() {
    final next = switch (state) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
    setThemeMode(next);
  }
}

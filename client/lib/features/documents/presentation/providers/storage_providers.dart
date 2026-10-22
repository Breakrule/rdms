import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/interfaces/i_backup_service.dart';
import '../../../../core/services/interfaces/i_storage_service.dart';
import '../../../../core/services/library_backup_service.dart';
import '../../../../core/services/library_integrity_service.dart';
import '../../../../core/services/storage_service.dart';
import 'database_providers.dart';

/// Storage service provider. The persistent resolver is wired to
/// [storageRootServiceProvider] so a restart lands on the same directory
/// the user chose. Test code can override either provider independently.
final storageServiceProvider = Provider<IStorageService>((ref) {
  final rootService = ref.watch(storageRootServiceProvider);
  return LocalStorageService(
    persistentPathResolver: () async {
      try {
        return await rootService.activePath();
      } catch (_) {
        return null;
      }
    },
  );
});

/// Backup export/import (Phase 1.5 / 1.6).
final libraryBackupServiceProvider = Provider<IBackupService>((ref) {
  return LibraryBackupService(
    db: ref.watch(databaseProvider),
    journal: ref.watch(operationJournalProvider),
  );
});

/// Health check (Phase 1.7).
final libraryIntegrityServiceProvider = Provider<LibraryIntegrityService>((ref) {
  return LibraryIntegrityService(
    db: ref.watch(databaseProvider),
    journal: ref.watch(operationJournalProvider),
  );
});

/// Custom storage directory path state
class StoragePathNotifier extends AsyncNotifier<String> {
  @override
  Future<String> build() async {
    final storageService = ref.watch(storageServiceProvider);
    return storageService.getStorageDirectoryPath();
  }

  /// Points future imports at [newPath] AND persists the choice so a
  /// restart reopens the same library. Phase 1.2 safe relocation is a
  /// separate concern (copy + verify + swap); this only changes the
  /// destination for NEW imports.
  Future<void> updatePath(String newPath) async {
    state = const AsyncValue.loading();
    try {
      final storageService = ref.read(storageServiceProvider);
      await storageService.setCustomBasePath(newPath);
      final rootService = ref.read(storageRootServiceProvider);
      await rootService.setActivePath(newPath);
      state = AsyncValue.data(newPath);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final storagePathProvider = AsyncNotifierProvider<StoragePathNotifier, String>(
  StoragePathNotifier.new,
);

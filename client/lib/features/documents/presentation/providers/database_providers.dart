import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/services/operation_journal.dart';
import '../../../../core/services/storage_root_service.dart';

/// Database instance provider
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

/// Storage-roots table service. [LocalStorageService] resolves its
/// active path through this so a user's chosen folder survives restart
/// (Phase 1.1 acceptance criterion).
final storageRootServiceProvider = Provider<StorageRootService>((ref) {
  return StorageRootService(ref.watch(databaseProvider));
});

/// Durable journal for file-mutating operations (Phase 1.3).
final operationJournalProvider = Provider<OperationJournal>((ref) {
  return OperationJournal(ref.watch(databaseProvider));
});

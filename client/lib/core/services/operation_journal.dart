import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';

/// Kind of file-mutating operation the journal tracks.
enum OperationKind { import, backup, restore, purge, relocation }

/// Lifecycle state of a journaled operation.
///
/// [pending] and [inProgress] are "open"; anything left in these states
/// after a restart indicates an interruption and is surfaced by
/// LibraryIntegrityService.
enum OperationStatus { pending, inProgress, complete, failed, rolledBack }

/// Durable journal for file-mutating operations (Phase 1.3).
///
/// Written BEFORE the file operation starts and updated AFTER it
/// finishes. A crash between the two leaves an open row that
/// [openOperations] returns so the UI can offer to clean up staged files
/// or retry the operation, instead of silently orphaning them.
class OperationJournal {
  final AppDatabase _db;
  static const _uuid = Uuid();

  OperationJournal(this._db);

  Future<String> begin({
    required OperationKind kind,
    String? documentId,
    String? sourcePath,
    String? stagedPath,
    String? targetPath,
    String? checksum,
  }) async {
    final id = _uuid.v4();
    await _db.into(_db.localOperations).insert(
          LocalOperationsCompanion.insert(
            id: id,
            kind: kind.name,
            status: OperationStatus.pending.name,
            documentId: Value(documentId),
            sourcePath: Value(sourcePath),
            stagedPath: Value(stagedPath),
            targetPath: Value(targetPath),
            checksum: Value(checksum),
          ),
        );
    return id;
  }

  Future<void> markInProgress(String id) => _update(id, OperationStatus.inProgress);

  Future<void> complete(String id) => _update(id, OperationStatus.complete);

  Future<void> fail(String id, String error) =>
      _update(id, OperationStatus.failed, error: error);

  Future<void> rolledBack(String id) => _update(id, OperationStatus.rolledBack);

  Future<void> _update(String id, OperationStatus status, {String? error}) async {
    await (_db.update(_db.localOperations)..where((t) => t.id.equals(id))).write(
      LocalOperationsCompanion(
        status: Value(status.name),
        errorMessage: error != null ? Value(error) : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Operations still in pending or inProgress state.
  Future<List<LocalOperation>> openOperations() {
    return (_db.select(_db.localOperations)
          ..where((t) => t.status.isIn(<String>[
                OperationStatus.pending.name,
                OperationStatus.inProgress.name,
              ])))
        .get();
  }
}

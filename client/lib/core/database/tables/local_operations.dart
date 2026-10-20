import 'package:drift/drift.dart';

/// Journal of file-mutating operations.
///
/// Written BEFORE the file change and updated AFTER success, so a crash
/// between the two states leaves a `pending` or `in_progress` row that
/// LibraryIntegrityService can detect on next start. Phase 1 uses it for
/// imports (1.3) and export/restore runs (1.5/1.6); Phase 1.2 safe
/// relocation and future background workers extend it.
///
/// The columns are intentionally generic:
/// - [kind] is the operation type (import | relocate | backup | restore |
///   purge | trash).
/// - [status] is the lifecycle state.
/// - [documentId] links the operation to the metadata row when relevant.
/// - [sourcePath] is where a file came from (user's original file for an
///   import, previous storage root for a relocation).
/// - [stagedPath] is the temporary location used during a two-phase write.
/// - [targetPath] is the intended final managed location.
/// - [checksum] is SHA-256 of the content this operation is meant to
///   commit; used to verify the staged file matches before activation.
class LocalOperations extends Table {
  TextColumn get id => text()(); // UUID v4
  TextColumn get kind => text()();
  TextColumn get status => text()(); // pending|in_progress|complete|failed|rolled_back
  TextColumn get documentId => text().nullable()();
  TextColumn get sourcePath => text().nullable()();
  TextColumn get stagedPath => text().nullable()();
  TextColumn get targetPath => text().nullable()();
  TextColumn get checksum => text().nullable()();
  TextColumn get errorMessage => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

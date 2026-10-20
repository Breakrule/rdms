import 'package:drift/drift.dart';

/// Per-destination, per-document sync state (Phase 2.1).
///
/// Replaces the previous single-value `sync_status` semantics for
/// replica tracking: a document can be `current` on Drive yet
/// `retryableFailure` on the backend, and the badge/UI must show both
/// independently. `local_documents.sync_status` remains for the
/// coarse-grained queue indicator (so existing UI keeps working) but the
/// source of truth for "is the file on Drive?" is this table.
///
/// Status values:
/// - `disabled`   - destination not configured (no token / no backend URL)
/// - `pending`    - changes exist that the destination has not acknowledged
/// - `running`    - a job is currently leased for this pair
/// - `current`    - destination acknowledged revisionAck + hashAck
/// - `retryableFailure` - last attempt failed with a transient error
/// - `blocked`    - permanent error (auth, validation) that needs user action
/// - `conflict`   - server rejected a stale baseRevision (Phase 2.6)
class DocumentReplicas extends Table {
  TextColumn get id => text()();
  TextColumn get documentId => text()();

  /// drive | backend
  TextColumn get destination => text()();

  TextColumn get status => text().withDefault(const Constant('pending'))();

  /// The revision number this destination acknowledged.
  IntColumn get revisionAck => integer().withDefault(const Constant(0))();

  /// The content hash this destination acknowledged. Metadata-only
  /// changes do not alter the content hash.
  TextColumn get contentHashAck => text().nullable()();

  /// Provider-side identifier once the destination has accepted an
  /// upload (Drive fileId for `drive`, server document UUID for
  /// `backend`).
  TextColumn get remoteId => text().nullable()();

  /// The remote file name the destination currently knows about.
  /// Kept separate from [local_documents.fileName] so a remote rename
  /// does not rewrite the physical file name (Phase 2.7).
  TextColumn get remoteName => text().nullable()();

  DateTimeColumn get lastVerifiedAt => dateTime().nullable()();
  TextColumn get errorRedacted => text().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {documentId, destination},
      ];
}

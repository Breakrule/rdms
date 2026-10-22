import 'package:drift/drift.dart';

/// Reference-counted content store (Rev. 2 Phase P1.1).
///
/// WHY THIS TABLE EXISTS. Before versions, one document owned one managed file
/// and deleting the document deleted the file (`storage_service.dart:184-196`,
/// called from `drift_document_repository.dart:289`). With immutable versions
/// two versions can legitimately share identical bytes, so that unconditional
/// delete becomes data loss: purging version 3 would erase the bytes version 5
/// is still using. This table is the guard, and it is plan risk **R-03** — the
/// only irreversible risk in the plan, which is why P1.1 lands before any
/// version-creating code.
///
/// TWO PATHS, DELIBERATELY. `legacyPath` carries the pre-P1 flat managed file
/// (`[DATE]_[TITLE]_[UUID].ext`) so adopting an existing library as version 1
/// moves **zero bytes**. `relativePath` is the new content-addressed layout
/// `blobs/<sha256[0:2]>/<sha256>`, used for every version created from P1 on.
/// Exactly one of the two is set. Bulk-migrating legacy files was rejected: it
/// would invalidate `localFilePath` everywhere and break the integrity service
/// and the relocation journal (plan §2.2.1).
class ContentBlobs extends Table {
  TextColumn get id => text()(); // UUID

  /// Content hash the blob is named by. Unique across the library: two
  /// documents with identical bytes share one blob on purpose.
  TextColumn get sha256Hash => text()();

  TextColumn get relativePath => text().nullable()();
  TextColumn get legacyPath => text().nullable()();

  IntColumn get sizeBytes => integer()();
  TextColumn get mimeType => text()();

  /// Number of live references. Maintenance is the store's job, not the
  /// caller's — see `ContentBlobStore`.
  IntColumn get refCount => integer().withDefault(const Constant(0))();

  /// Set by P4.2 once the blob is stored encrypted. False in P1.
  BoolColumn get encrypted => boolean().withDefault(const Constant(false))();

  /// Bytes that are referenced but not present locally, because the only copy
  /// is a provider revision (plan risk R-04). Never deleted implicitly.
  BoolColumn get localAvailable =>
      boolean().withDefault(const Constant(true))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [{sha256Hash}];
}

/// Immutable content versions (Rev. 2 Phase P1.2).
///
/// A VERSION IS NOT A REVISION. `LocalDocuments.baseRevision` is the sync
/// concurrency token from Phase 2.6 — it advances on ANY accepted mutation,
/// including a title edit that changes no bytes. A version is an immutable
/// content identity with its own blob, author, and note. Conflating them would
/// (a) break the shipped `baseRevision` optimistic-locking protocol and
/// (b) mint a phantom version on every metadata edit. That is plan risk
/// **R-02**, and `document_versioning_test.dart` asserts the separation.
///
/// Restore is additive: restoring v3 while v7 is current creates v8. Versions
/// 4-6 are never destroyed, because PRD F4 asks for restore AND for "a history
/// of all document versions" in the same breath.
class DocumentVersions extends Table {
  TextColumn get id => text()(); // UUID — the version identity

  /// The stable document this version belongs to.
  TextColumn get documentId => text()();

  /// Profile/workspace scope. Defaults to the personal workspace so a
  /// single-user install need not supply it, and so Appendix T's shared
  /// workspaces become a migration rather than a rewrite (plan §2.2.4).
  TextColumn get workspaceId =>
      text().withDefault(
        const Constant('00000000-0000-4000-8000-000000000001'),
      )();

  IntColumn get versionNumber => integer()();

  /// Which version this one was derived from, for the lineage view.
  TextColumn get parentVersionId => text().nullable()();

  /// Redundant with the blob on purpose: a version must remain describing its
  /// content even if the blob row is later evicted from local storage.
  TextColumn get sha256Hash => text()();

  TextColumn get blobId => text()();

  /// File name and description AS THEY WERE when this version was current, so
  /// history shows what the record was called then rather than now.
  TextColumn get fileName => text()();
  TextColumn get originalFileName => text().nullable()();
  IntColumn get fileSizeBytes => integer()();
  TextColumn get mimeType => text()();
  TextColumn get metadataSnapshot => text()(); // JSON

  /// `local` | `gdrive` | `none` — where the owner's bytes additionally exist.
  /// The server never resolves these; it only tells another of the same user's
  /// devices which of their own accounts to look in (plan §2.2.1).
  TextColumn get originBackend =>
      text().withDefault(const Constant('local'))();

  /// Provider-side revision id (e.g. Google Drive revisionId). Best-effort:
  /// provider retention is bounded, so this is a pointer, not a guarantee.
  TextColumn get providerVersionRef => text().nullable()();

  /// True when this version's bytes are on this device.
  BoolColumn get localAvailable =>
      boolean().withDefault(const Constant(true))();

  /// True when the user has NOT opted this document into cloud backup.
  BoolColumn get localOnly => boolean().withDefault(const Constant(true))();

  TextColumn get changeNote => text().nullable()();

  /// How the version came to exist: import | replaced | restored |
  /// external_modification. Enumerated, not free text.
  TextColumn get origin => text().withDefault(const Constant('import'))();

  /// Local device/profile attribution label. NOT an audit identity —
  /// see plan verdict V-3 (a personal timeline is not evidence-grade audit).
  TextColumn get createdByDevice => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Tombstone, added here rather than in a later version so the change feed
  /// (P2.1) has something to tombstone against.
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [{documentId, versionNumber}];
}

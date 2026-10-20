import 'package:drift/drift.dart';

/// Table representing locally stored documents and sync metadata.
class LocalDocuments extends Table {
  TextColumn get id => text()(); // UUID v4
  TextColumn get title => text().withLength(min: 1, max: 255)();
  TextColumn get documentNumber => text().nullable()();
  TextColumn get category => text()(); // SK, Laporan, Notula, Teknis, etc.
  DateTimeColumn get documentDate => dateTime()();
  IntColumn get fiscalYear => integer()();
  TextColumn get localFilePath => text()();
  TextColumn get fileName => text()();
  IntColumn get fileSizeBytes => integer()();
  TextColumn get mimeType => text()();
  TextColumn get sha256Hash => text()();
  TextColumn get extractedText => text().nullable()();

  // Status: local_only, queued, syncing, synced, error
  TextColumn get syncStatus => text().withDefault(const Constant('local_only'))();
  TextColumn get gdriveFileId => text().nullable()();
  TextColumn get remoteBackendId => text().nullable()();

  /// Soft-delete marker introduced in Phase 1.4. When non-null the row
  /// lives in the local recycle bin: watch/search/count default to
  /// excluding it, and the managed file remains on disk so [restore]
  /// can re-activate the row without touching binaries or Drive IDs.
  /// Permanent removal (purge) sets this to a real timestamp AND
  /// schedules the managed file for deletion via the operation journal.
  DateTimeColumn get trashedAt => dateTime().nullable()();

  /// Monotonic local revision counter (Phase 2.6). Advanced on every
  /// metadata-only change so the server can distinguish "same content,
  /// new description" from a hash-only reconcile.
  IntColumn get baseRevision => integer().withDefault(const Constant(1))();

  /// Opaque account binding captured when the document first enters a
  /// sync destination. Phase 2.3 refuses to process queued jobs whose
  /// [accountBinding] no longer matches the signed-in user.
  TextColumn get accountBinding => text().nullable()();

  /// Phase 4.3 per-device favorite marker. Device-local by design:
  /// favorites are a viewing preference, not shared record data, so
  /// they never enter the sync payload or the portable manifest.
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();

  /// Phase 4.1 free-form note surfaced in details and replicated via
  /// the v2 payload. Distinct from extractedText (document body text).
  TextColumn get notes => text().nullable()();

  /// Phase 4.4 the file's name BEFORE it was renamed to the managed
  /// convention. fileName stays authoritative for the on-disk layout;
  /// this is user-facing provenance and belongs in the backup manifest.
  TextColumn get originalFileName => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

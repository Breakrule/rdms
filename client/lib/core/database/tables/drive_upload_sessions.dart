import 'package:drift/drift.dart';

/// Persists a Google Drive resumable-upload session so a restart can
/// resume where it left off (Phase 2.4).
///
/// The [sessionUri] is the URL Google returned when the session was
/// initiated; posting subsequent chunks or querying the current offset
/// to that URI is the ONLY way to resume. It is treated as a secret:
/// it is scoped to the caller's OAuth session and time-limited, so it
/// is stored here (and only here) and never written into
/// `sync_jobs.revisionPayload` or the portable backup manifest.
///
/// [bytesAcknowledged] is the last byte offset Google confirmed via a
/// 200/206/308 Range response. On resume, [SyncQueueService] queries
/// the session URI to reconcile any drift between what we thought was
/// sent and what Google actually received.
class DriveUploadSessions extends Table {
  TextColumn get id => text()(); // UUID v4
  TextColumn get jobId => text()(); // FK-ish: sync_jobs.id
  TextColumn get documentId => text()();
  TextColumn get sessionUri => text()();
  IntColumn get bytesAcknowledged => integer().withDefault(const Constant(0))();
  IntColumn get totalBytes => integer()();

  /// open | complete | expired | aborted
  TextColumn get status => text().withDefault(const Constant('open'))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

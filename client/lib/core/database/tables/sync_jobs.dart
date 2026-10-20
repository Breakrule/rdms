import 'package:drift/drift.dart';

/// Durable transactional outbox for file-mutating sync operations
/// (Phase 2.2).
///
/// Written in the SAME SQLite transaction that mutates the document row,
/// so a metadata edit or new import always leaves a job behind. A worker
/// claims jobs via a time-boxed lease; unclaimed or expired-lease rows
/// are picked up on next start.
///
/// [accountBinding] is intentionally a required, opaque identifier of
/// the destination account the job was created for. Phase 2.3 refuses to
/// run a job under a different account, so signing out and back in as a
/// second user cannot accidentally upload user-one files to user-two
/// Drive.
///
/// [revisionPayload] is a JSON blob the worker uses to reconstruct the
/// request (metadata patch, Drive file name, etc.). Sensitive values
/// (tokens, session URIs) NEVER live here — session URIs are stored in
/// `drive_upload_sessions`.
///
/// [errorRedacted] is a client-side message with credentials and
/// absolute paths stripped before saving.
class SyncJobs extends Table {
  TextColumn get id => text()(); // UUID v4 == operationUuid on server
  TextColumn get documentId => text()();
  TextColumn get destination => text()(); // drive | backend
  TextColumn get kind => text()(); // upload | rename | trash | delete | metadata

  /// pending | leased | complete | blocked
  TextColumn get status => text().withDefault(const Constant('pending'))();

  IntColumn get attempts => integer().withDefault(const Constant(0))();

  /// The earliest time a worker may re-claim this job. Advanced by the
  /// retry/backoff policy; set to NULL for immediate eligibility.
  DateTimeColumn get nextRetryAt => dateTime().nullable()();

  /// A leased job carries the moment its lease expires so a crashed
  /// worker does not strand the row forever.
  DateTimeColumn get leasedUntil => dateTime().nullable()();

  TextColumn get accountBinding => text()();

  /// Local revision the job will present as baseRevision when it runs.
  /// A mismatch on the server side yields `conflict` and blocks further
  /// retries until the user resolves (Phase 2.6).
  IntColumn get baseRevision => integer().withDefault(const Constant(0))();

  TextColumn get contentHash => text().nullable()();
  TextColumn get revisionPayload => text().nullable()();
  TextColumn get errorRedacted => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

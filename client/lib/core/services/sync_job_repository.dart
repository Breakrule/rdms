import 'dart:math';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';

enum JobDestination { drive, backend }

enum JobKind { upload, rename, trash, delete, metadata }

enum JobStatus { pending, leased, complete, blocked }

/// Durable job outbox (Phase 2.2 / 2.3).
///
/// Every file-mutating action queues a job here in the SAME SQLite
/// transaction that changes the document row, so a crash between the two
/// can never leave the document updated but the sync unqueued.
///
/// Workers claim a job by atomically flipping `status: pending -> leased`
/// with a bounded [leasedUntil]. If the process dies, the lease expires
/// and [recoverExpiredLeases] puts the job back into pending on next
/// start. [failTransient] applies capped exponential backoff with jitter
/// so a flaky network does not burn through retries.
///
/// Account binding is enforced at claim time: [claimNextEligible] filters
/// by `accountBinding`, so signing out and back in as another user
/// cannot pick up the previous user's queued work.
class SyncJobRepository {
  final AppDatabase _db;
  static const _uuid = Uuid();
  static const _rngSeed = 42;

  SyncJobRepository(this._db);

  /// Insert a new job. Callers MUST run this inside the same transaction
  /// as the document mutation that motivated it.
  Future<String> enqueue({
    required String documentId,
    required JobDestination destination,
    required JobKind kind,
    required String accountBinding,
    required int baseRevision,
    String? contentHash,
    String? revisionPayload,
  }) async {
    final id = _uuid.v4();
    await _db.into(_db.syncJobs).insert(
          SyncJobsCompanion.insert(
            id: id,
            documentId: documentId,
            destination: destination.name,
            kind: kind.name,
            status: const Value('pending'),
            accountBinding: accountBinding,
            baseRevision: Value(baseRevision),
            contentHash: Value(contentHash),
            revisionPayload: Value(revisionPayload),
          ),
        );
    return id;
  }

  /// Atomically claim one eligible job for [accountBinding].
  /// Returns null if nothing is due.
  Future<SyncJob?> claimNextEligible(String accountBinding, {Duration lease = const Duration(minutes: 2)}) async {
    final now = DateTime.now();
    final leaseUntil = now.add(lease);

    return _db.transaction(() async {
      final candidate = await (_db.select(_db.syncJobs)
            ..where((t) => t.accountBinding.equals(accountBinding))
            ..where((t) => t.status.isIn(const ['pending']))
            ..where((t) => t.nextRetryAt.isNull() | t.nextRetryAt.isBiggerOrEqualValue(now).not())
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
            ..limit(1))
          .getSingleOrNull();
      if (candidate == null) return null;
      await (_db.update(_db.syncJobs)..where((t) => t.id.equals(candidate.id))).write(
        SyncJobsCompanion(
          status: const Value('leased'),
          leasedUntil: Value(leaseUntil),
          attempts: Value(candidate.attempts + 1),
          updatedAt: Value(now),
        ),
      );
      return (_db.select(_db.syncJobs)..where((t) => t.id.equals(candidate.id)))
          .getSingle();
    });
  }

  Future<void> complete(String id) async {
    await (_db.update(_db.syncJobs)..where((t) => t.id.equals(id))).write(
      SyncJobsCompanion(
        status: const Value('complete'),
        leasedUntil: const Value(null),
        errorRedacted: const Value(null),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Transient failure (network, 429, 5xx). Applies capped exponential
  /// backoff with jitter so concurrent workers do not stampede the same
  /// endpoint on the next tick.
  Future<void> failTransient(
    String id,
    String errorRedacted, {
    int attemptsSoFar = 1,
    Duration maxBackoff = const Duration(minutes: 15),
  }) async {
    final baseSeconds = min(2 << min(attemptsSoFar, 10), 300);
    final jitter = Random(id.hashCode ^ _rngSeed).nextInt(30);
    final delay = Duration(seconds: baseSeconds + jitter);
    final capped = delay > maxBackoff ? maxBackoff : delay;
    await (_db.update(_db.syncJobs)..where((t) => t.id.equals(id))).write(
      SyncJobsCompanion(
        status: const Value('pending'),
        leasedUntil: const Value(null),
        nextRetryAt: Value(DateTime.now().add(capped)),
        errorRedacted: Value(errorRedacted),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Permanent failure (401 / validation). Blocks the job so a user
  /// action (reconnect / edit / discard) is required before it runs
  /// again.
  Future<void> failPermanent(String id, String errorRedacted) async {
    await (_db.update(_db.syncJobs)..where((t) => t.id.equals(id))).write(
      SyncJobsCompanion(
        status: const Value('blocked'),
        leasedUntil: const Value(null),
        errorRedacted: Value(errorRedacted),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Called on startup / resume. Any job whose lease has expired goes
  /// back into the pending pool so the new process can pick it up.
  Future<int> recoverExpiredLeases() async {
    final now = DateTime.now();
    return (_db.update(_db.syncJobs)
          ..where((t) => t.status.equals('leased'))
          ..where((t) => t.leasedUntil.isSmallerOrEqualValue(now)))
        .write(
      SyncJobsCompanion(
        status: const Value('pending'),
        leasedUntil: const Value(null),
        nextRetryAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  Future<List<SyncJob>> listOpen({String? accountBinding}) {
    final q = _db.select(_db.syncJobs)
      ..where((t) => t.status.isIn(const ['pending', 'leased']));
    if (accountBinding != null) {
      q.where((t) => t.accountBinding.equals(accountBinding));
    }
    q.orderBy([(t) => OrderingTerm.asc(t.createdAt)]);
    return q.get();
  }

  Future<List<SyncJob>> listBlocked() {
    return (_db.select(_db.syncJobs)
          ..where((t) => t.status.equals('blocked'))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();
  }

  Stream<List<SyncJob>> watchOpen({String? accountBinding}) {
    final q = _db.select(_db.syncJobs)
      ..where((t) => t.status.isIn(const ['pending', 'leased', 'blocked']));
    if (accountBinding != null) {
      q.where((t) => t.accountBinding.equals(accountBinding));
    }
    q.orderBy([(t) => OrderingTerm.asc(t.createdAt)]);
    return q.watch();
  }

  Future<int> countByStatus(JobStatus status) async {
    final count = _db.syncJobs.id.count();
    final q = _db.selectOnly(_db.syncJobs)..addColumns([count]);
    q.where(_db.syncJobs.status.equals(status.name));
    return (await q.map((r) => r.read(count)).getSingle()) ?? 0;
  }

  /// Manual retry: reset attempts/backoff and requeue a blocked job.
  Future<void> retry(String id) async {
    await (_db.update(_db.syncJobs)..where((t) => t.id.equals(id))).write(
      SyncJobsCompanion(
        status: const Value('pending'),
        attempts: const Value(0),
        nextRetryAt: const Value(null),
        leasedUntil: const Value(null),
        errorRedacted: const Value(null),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> cancel(String id) async {
    await (_db.delete(_db.syncJobs)..where((t) => t.id.equals(id))).go();
  }
}

/// Convenience for callers that build job predicates.
extension JobStatusName on JobStatus {
  String get dbValue => name;
}

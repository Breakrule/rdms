import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import 'sync_job_repository.dart' show JobDestination;

enum ReplicaStatus {
  disabled,
  pending,
  running,
  current,
  retryableFailure,
  blocked,
  conflict,
}

/// Per-destination, per-document replica state (Phase 2.1 / 2.7).
///
/// Replaces the previous one-value-syncs-for-everything model. A row
/// here means "the destination knows about this document"; its absence
/// means "we have never touched this destination for this document."
///
/// [upsert] is the only write path so a document cannot end up with two
/// rows per (documentId, destination) pair. [remoteName] is stored
/// separately from `local_documents.fileName` so a Drive-side rename
/// does not rewrite the physical filename (Phase 2.7).
class DocumentReplicaRepository {
  final AppDatabase _db;
  static const _uuid = Uuid();

  DocumentReplicaRepository(this._db);

  Future<void> upsert({
    required String documentId,
    required JobDestination destination,
    required ReplicaStatus status,
    int revisionAck = 0,
    String? contentHashAck,
    String? remoteId,
    String? remoteName,
    DateTime? lastVerifiedAt,
    String? errorRedacted,
  }) async {
    final existing = await (_db.select(_db.documentReplicas)
          ..where((t) => t.documentId.equals(documentId))
          ..where((t) => t.destination.equals(destination.name))
          ..limit(1))
        .getSingleOrNull();
    final now = DateTime.now();
    if (existing == null) {
      await _db.into(_db.documentReplicas).insert(
            DocumentReplicasCompanion.insert(
              id: _uuid.v4(),
              documentId: documentId,
              destination: destination.name,
              status: Value(status.name),
              revisionAck: Value(revisionAck),
              contentHashAck: Value(contentHashAck),
              remoteId: Value(remoteId),
              remoteName: Value(remoteName),
              lastVerifiedAt: Value(lastVerifiedAt ?? now),
              errorRedacted: Value(errorRedacted),
              updatedAt: Value(now),
            ),
          );
    } else {
      await (_db.update(_db.documentReplicas)..where((t) => t.id.equals(existing.id))).write(
        DocumentReplicasCompanion(
          status: Value(status.name),
          revisionAck: Value(revisionAck),
          contentHashAck: Value(contentHashAck ?? existing.contentHashAck),
          remoteId: Value(remoteId ?? existing.remoteId),
          remoteName: Value(remoteName ?? existing.remoteName),
          lastVerifiedAt: Value(lastVerifiedAt ?? now),
          errorRedacted: Value(errorRedacted),
          updatedAt: Value(now),
        ),
      );
    }
  }

  Future<DocumentReplica?> get(String documentId, JobDestination destination) {
    return (_db.select(_db.documentReplicas)
          ..where((t) => t.documentId.equals(documentId))
          ..where((t) => t.destination.equals(destination.name))
          ..limit(1))
        .getSingleOrNull();
  }

  Stream<List<DocumentReplica>> watchAll() => _db.select(_db.documentReplicas).watch();

  Future<int> countByStatus(ReplicaStatus status, JobDestination destination) async {
    final count = _db.documentReplicas.id.count();
    final q = _db.selectOnly(_db.documentReplicas)..addColumns([count]);
    q.where(_db.documentReplicas.status.equals(status.name));
    q.where(_db.documentReplicas.destination.equals(destination.name));
    return (await q.map((r) => r.read(count)).getSingle()) ?? 0;
  }

  /// Aggregate a per-destination rollup for the Sync Center summary card.
  Future<ReplicaRollup> rollup(JobDestination destination) async {
    final rows = await (_db.select(_db.documentReplicas)
          ..where((t) => t.destination.equals(destination.name)))
        .get();
    int current = 0, pending = 0, failed = 0, blocked = 0, conflict = 0;
    for (final r in rows) {
      switch (r.status) {
        case 'current':
          current++;
          break;
        case 'pending':
        case 'running':
          pending++;
          break;
        case 'retryableFailure':
          failed++;
          break;
        case 'blocked':
        case 'disabled':
          blocked++;
          break;
        case 'conflict':
          conflict++;
          break;
      }
    }
    return ReplicaRollup(
      destination: destination,
      total: rows.length,
      current: current,
      pending: pending,
      failed: failed,
      blocked: blocked,
      conflict: conflict,
    );
  }
}

class ReplicaRollup {
  final JobDestination destination;
  final int total;
  final int current;
  final int pending;
  final int failed;
  final int blocked;
  final int conflict;

  const ReplicaRollup({
    required this.destination,
    required this.total,
    required this.current,
    required this.pending,
    required this.failed,
    required this.blocked,
    required this.conflict,
  });
}

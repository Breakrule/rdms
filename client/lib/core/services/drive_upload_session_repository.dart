import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';

/// Persists Drive resumable-upload sessions so a restart can continue
/// the upload rather than re-uploading from byte 0 (Phase 2.4).
class DriveUploadSessionRepository {
  final AppDatabase _db;
  static const _uuid = Uuid();

  DriveUploadSessionRepository(this._db);

  Future<String> create({
    required String jobId,
    required String documentId,
    required String sessionUri,
    required int totalBytes,
  }) async {
    final id = _uuid.v4();
    await _db.into(_db.driveUploadSessions).insert(
          DriveUploadSessionsCompanion.insert(
            id: id,
            jobId: jobId,
            documentId: documentId,
            sessionUri: sessionUri,
            totalBytes: totalBytes,
            status: const Value('open'),
          ),
        );
    return id;
  }

  Future<DriveUploadSession?> forJob(String jobId) {
    return (_db.select(_db.driveUploadSessions)
          ..where((t) => t.jobId.equals(jobId))
          ..where((t) => t.status.equals('open'))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<void> advance({required String id, required int bytesAcknowledged}) async {
    await (_db.update(_db.driveUploadSessions)..where((t) => t.id.equals(id))).write(
      DriveUploadSessionsCompanion(
        bytesAcknowledged: Value(bytesAcknowledged),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> markComplete(String id) => _setStatus(id, 'complete');
  Future<void> markExpired(String id) => _setStatus(id, 'expired');
  Future<void> markAborted(String id) => _setStatus(id, 'aborted');

  Future<void> _setStatus(String id, String status) async {
    await (_db.update(_db.driveUploadSessions)..where((t) => t.id.equals(id))).write(
      DriveUploadSessionsCompanion(
        status: Value(status),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Sessions that were left mid-upload before a crash. Called on startup
  /// so a resume path can pick them up.
  Future<List<DriveUploadSession>> openSessions() {
    return (_db.select(_db.driveUploadSessions)
          ..where((t) => t.status.equals('open')))
        .get();
  }
}

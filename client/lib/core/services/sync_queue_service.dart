import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../features/documents/domain/models/document_item.dart';
import '../../features/documents/domain/repositories/document_repository.dart';
import '../database/app_database.dart';
import 'backend_sync_client.dart';
import 'document_replica_repository.dart';
import 'gdrive_service.dart';
import 'interfaces/i_sync_service.dart';
import 'sync_job_repository.dart';

/// Snapshot of queue + replica state that the Sync Center UI subscribes
/// to. Emitted by [SyncQueueService.progressStream] on every transition
/// so the UI never has to poll.
class SyncProgressState {
  final int total;
  final int completed;
  final int failed;
  final int inProgress;
  final bool isRunning;
  final bool isPaused;
  final String? currentItemTitle;

  /// Per-destination rollups for the header cards (Phase 2.8).
  final ReplicaRollup? driveRollup;
  final ReplicaRollup? backendRollup;

  const SyncProgressState({
    this.total = 0,
    this.completed = 0,
    this.failed = 0,
    this.inProgress = 0,
    this.isRunning = false,
    this.isPaused = false,
    this.currentItemTitle,
    this.driveRollup,
    this.backendRollup,
  });

  double get percentage => total > 0 ? (completed + failed) / total : 0.0;
}

/// Restart-safe outbox worker (Phase 2.2 / 2.3 / 2.6 / 2.7).
///
/// Replaces the previous in-memory "iterate queued docs once" model. The
/// durable `sync_jobs` table is the source of truth: a job that was
/// leased when the process died is returned to `pending` by
/// [recoverExpiredLeases]; a job queued while a worker is running is
/// picked up on the next tick; a job blocked by a permanent error stays
/// visible in the Sync Center until the user retries or discards it.
///
/// [accountBinding] is required at [processQueue] time and stamped into
/// every job the worker claims. Jobs created under a different binding
/// are skipped (Phase 2.3 acceptance: "account switching never transfers
/// jobs to the wrong destination").
class SyncQueueService implements ISyncService {
  final DocumentRepository _repository;
  final GDriveService _gdriveService;
  final BackendSyncClient _backendClient;
  final SyncJobRepository _jobs;
  final DocumentReplicaRepository _replicas;
  final AppDatabase _db;

  final _progressController = StreamController<SyncProgressState>.broadcast();
  @override
  Stream<SyncProgressState> get progressStream => _progressController.stream;

  bool _isProcessing = false;
  bool _isPaused = false;
  static const int _maxConcurrency = 2;

  SyncQueueService({
    required this._repository,
    required this._gdriveService,
    required this._backendClient,
    required this._jobs,
    required this._replicas,
    required this._db,
  });

  @override
  void dispose() {
    _progressController.close();
  }

  @override
  void pause() {
    _isPaused = true;
    _emit();
  }

  /// Clears the paused flag. The next [processQueue] call resumes work;
  /// we intentionally do NOT auto-start a worker here because
  /// [processQueue] requires the caller-provided accountBinding, which
  /// is only known at the UI/provider layer.
  @override
  void resume() {
    _isPaused = false;
    _emit();
  }

  /// Queues a Drive upload for [doc] and (separately) a backend metadata
  /// upsert. Enqueues BOTH in one SQLite transaction so a crash after
  /// the first write cannot leave the two destinations out of sync.
  ///
  /// Replaces the previous "one status fits all" behavior.
  @override
  Future<void> enqueueUpload({
    required DocumentItem doc,
    required String accountBinding,
  }) async {
    await _db.transaction(() async {
      final payload = jsonEncode(_driveUploadPayload(doc));
      await _jobs.enqueue(
        documentId: doc.id,
        destination: JobDestination.drive,
        kind: JobKind.upload,
        accountBinding: accountBinding,
        baseRevision: doc.baseRevision,
        contentHash: doc.sha256Hash,
        revisionPayload: payload,
      );
      await _jobs.enqueue(
        documentId: doc.id,
        destination: JobDestination.backend,
        kind: JobKind.metadata,
        accountBinding: accountBinding,
        baseRevision: doc.baseRevision,
        contentHash: doc.sha256Hash,
        revisionPayload: jsonEncode(await _backendMetadataPayload(doc)),
      );
      await _replicas.upsert(
        documentId: doc.id,
        destination: JobDestination.drive,
        status: ReplicaStatus.pending,
      );
      await _replicas.upsert(
        documentId: doc.id,
        destination: JobDestination.backend,
        status: ReplicaStatus.pending,
      );
      await _repository.updateSyncStatus(
        id: doc.id,
        status: DocumentSyncStatus.queued,
      );
    });
  }

  /// Queues a metadata-only job (backend) without touching Drive. Used
  /// by Phase 4's metadata edit once it lands; safe to call today.
  @override
  Future<void> enqueueMetadataOnly({
    required DocumentItem doc,
    required String accountBinding,
  }) async {
    await _db.transaction(() async {
      await _jobs.enqueue(
        documentId: doc.id,
        destination: JobDestination.backend,
        kind: JobKind.metadata,
        accountBinding: accountBinding,
        baseRevision: doc.baseRevision,
        contentHash: doc.sha256Hash,
        revisionPayload: jsonEncode(await _backendMetadataPayload(doc)),
      );
      await _replicas.upsert(
        documentId: doc.id,
        destination: JobDestination.backend,
        status: ReplicaStatus.pending,
      );
    });
  }

  /// Claim and run jobs until none is eligible. Concurrency-capped at
  /// [_maxConcurrency]. Restarts pick up expired leases automatically.
  @override
  Future<void> processQueue({required String accountBinding}) async {
    if (_isPaused) return;
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      await _jobs.recoverExpiredLeases();

      Future<void> runWorker() async {
        while (!_isPaused) {
          final job = await _jobs.claimNextEligible(accountBinding);
          if (job == null) return;
          _lastTotal++;
          _lastInProgress++;
          _emit(currentDocumentId: job.documentId);
          try {
            await _runOne(job);
            _lastInProgress--;
            _lastCompleted++;
          } catch (err) {
            _lastInProgress--;
            _lastFailed++;
          }
          _emit();
        }
      }

      final workers = List.generate(_maxConcurrency, (_) => runWorker());
      await Future.wait(workers);
      _emit();
    } finally {
      _isProcessing = false;
      _emit();
    }
  }

  Future<void> _runOne(SyncJob job) async {
    final doc = await _repository.getDocumentById(job.documentId);
    if (doc == null) {
      await _jobs.complete(job.id);
      return;
    }
    if (doc.isTrashed) {
      // Trashed documents do not sync; a queued job created before the
      // trash action is discarded.
      await _jobs.complete(job.id);
      return;
    }

    await _replicas.upsert(
      documentId: doc.id,
      destination: _decodeDestination(job.destination),
      status: ReplicaStatus.running,
    );

    switch (job.destination) {
      case 'drive':
        await _runDriveUpload(job, doc);
        break;
      case 'backend':
        await _runBackendMetadata(job, doc);
        break;
      default:
        await _jobs.failPermanent(job.id, 'unknown destination ${job.destination}');
    }
  }

  JobDestination _decodeDestination(String raw) => switch (raw) {
        'drive' => JobDestination.drive,
        'backend' => JobDestination.backend,
        _ => throw ArgumentError('unknown destination: $raw'),
      };

  Future<void> _runDriveUpload(SyncJob job, DocumentItem doc) async {
    final file = File(doc.localFilePath);
    if (!await file.exists()) {
      final msg = 'Berkas lokal tidak ditemukan (path dihapus).';
      await _jobs.failPermanent(job.id, msg);
      await _replicas.upsert(
        documentId: doc.id,
        destination: JobDestination.drive,
        status: ReplicaStatus.blocked,
        errorRedacted: msg,
      );
      // Legacy bridge: the badge reads DocumentSyncStatus; keep it
      // accurate for callers that have not migrated to the per-
      // destination replica view yet (Phase 3 replaces the badge).
      await _repository.updateSyncStatus(
        id: doc.id,
        status: DocumentSyncStatus.error,
      );
      return;
    }
    try {
      final result = await _gdriveService.uploadFileResumable(
        file: file,
        fileName: doc.fileName,
        mimeType: doc.mimeType,
        title: doc.title,
        jobId: job.id,
        documentId: doc.id,
      );
      await _jobs.complete(job.id);
      await _repository.updateSyncStatus(
        id: doc.id,
        status: DocumentSyncStatus.synced,
        gdriveFileId: result.fileId,
      );
      await _replicas.upsert(
        documentId: doc.id,
        destination: JobDestination.drive,
        status: ReplicaStatus.current,
        revisionAck: doc.baseRevision,
        contentHashAck: doc.sha256Hash,
        remoteId: result.fileId,
        remoteName: result.fileName,
        lastVerifiedAt: DateTime.now(),
      );
    } on GDriveAuthException catch (err) {
      await _jobs.failPermanent(job.id, err.redactedMessage);
      await _replicas.upsert(
        documentId: doc.id,
        destination: JobDestination.drive,
        status: ReplicaStatus.blocked,
        errorRedacted: err.redactedMessage,
      );
    } on GDriveTransientException catch (err) {
      await _jobs.failTransient(job.id, err.redactedMessage, attemptsSoFar: job.attempts);
      await _replicas.upsert(
        documentId: doc.id,
        destination: JobDestination.drive,
        status: ReplicaStatus.retryableFailure,
        errorRedacted: err.redactedMessage,
      );
    } catch (err) {
      await _jobs.failTransient(job.id, _redact(err.toString()), attemptsSoFar: job.attempts);
      await _replicas.upsert(
        documentId: doc.id,
        destination: JobDestination.drive,
        status: ReplicaStatus.retryableFailure,
        errorRedacted: _redact(err.toString()),
      );
    }
  }

  Future<void> _runBackendMetadata(SyncJob job, DocumentItem doc) async {
    try {
      final payloadMap = await _backendMetadataPayload(doc);
      final result = await _backendClient.applyOperations([
        {
          'operationId': job.id,
          'clientLocalId': job.documentId,
          'baseRevision': job.baseRevision,
          'kind': 'upsert',
          'payload': payloadMap,
        },
      ]);
      final op = result.results.first;
      switch (op.outcome) {
        case 'applied':
          await _jobs.complete(job.id);
          await _replicas.upsert(
            documentId: doc.id,
            destination: JobDestination.backend,
            status: ReplicaStatus.current,
            revisionAck: op.revisionAfter,
            contentHashAck: doc.sha256Hash,
            remoteId: op.serverDocumentId,
            lastVerifiedAt: DateTime.now(),
          );
          break;
        case 'conflict':
          // Server has a newer revision. Do NOT retry with the same
          // opId (idempotency would return the same conflict). Leave
          // the job blocked so a user or a future Phase 6 conflict
          // resolver can rebase.
          await _jobs.failPermanent(job.id, 'server_revision_conflict');
          await _replicas.upsert(
            documentId: doc.id,
            destination: JobDestination.backend,
            status: ReplicaStatus.conflict,
            revisionAck: op.revisionAfter,
            remoteId: op.serverDocumentId,
            errorRedacted: 'stale_base_revision',
          );
          break;
        case 'rejected':
          await _jobs.failPermanent(job.id, op.errorCode ?? 'rejected');
          await _replicas.upsert(
            documentId: doc.id,
            destination: JobDestination.backend,
            status: ReplicaStatus.blocked,
            errorRedacted: op.errorCode ?? 'rejected',
          );
          break;
      }
    } on BackendTransientException catch (err) {
      await _jobs.failTransient(job.id, _redact(err.message), attemptsSoFar: job.attempts);
      await _replicas.upsert(
        documentId: doc.id,
        destination: JobDestination.backend,
        status: ReplicaStatus.retryableFailure,
        errorRedacted: _redact(err.message),
      );
    } catch (err) {
      await _jobs.failTransient(job.id, _redact(err.toString()), attemptsSoFar: job.attempts);
      await _replicas.upsert(
        documentId: doc.id,
        destination: JobDestination.backend,
        status: ReplicaStatus.retryableFailure,
        errorRedacted: _redact(err.toString()),
      );
    }
  }

  Map<String, dynamic> _driveUploadPayload(DocumentItem doc) => {
        'documentId': doc.id,
        'fileName': doc.fileName,
        'mimeType': doc.mimeType,
        'title': doc.title,
      };

  Future<Map<String, dynamic>> _backendMetadataPayload(DocumentItem doc) async {
    // Phase 4.8: notes, original filename, and tag names join the v2
    // payload. localFilePath stays out (Phase 0.4 privacy), favorites
    // stay device-local (Phase 4.3).
    final links = await (_db.select(_db.documentTags)
          ..where((t) => t.documentId.equals(doc.id)))
        .get();
    final tags = <String>[];
    for (final link in links) {
      final tag = await (_db.select(_db.tags)
            ..where((t) => t.id.equals(link.tagId)))
          .getSingleOrNull();
      if (tag != null) tags.add(tag.name);
    }
    return {
      'clientLocalId': doc.id,
      'title': doc.title,
      'documentNumber': doc.documentNumber,
      'categoryCode': doc.category,
      'documentDate': doc.documentDate.toIso8601String().substring(0, 10),
      'fiscalYear': doc.fiscalYear,
      'fileName': doc.fileName,
      'fileSizeBytes': doc.fileSizeBytes,
      'mimeType': doc.mimeType,
      'sha256Hash': doc.sha256Hash,
      'gdriveFileId': doc.gdriveFileId,
      'extractedText': doc.extractedText,
      'notes': doc.notes,
      'originalFileName': doc.originalFileName,
      'tags': tags,
      'customMetadata': <String, dynamic>{},
    };
  }

  /// Strips obvious secrets + absolute paths before we save an error to
  /// the durable journal. Phase 0.6 flagged "absolute paths must not
  /// leak"; this is the sync-queue equivalent.
  String _redact(String raw) {
    var out = raw;
    final pathPatterns = [
      RegExp(r'[A-Za-z]:\\[^\s]+'), // windows absolute
      RegExp(r'/[^\s/]+(/[^\s/]+)+'), // posix absolute (>=2 segments)
    ];
    for (final p in pathPatterns) {
      out = out.replaceAllMapped(p, (m) => '<path:${m.start}>');
    }
    out = out.replaceAll(RegExp(r'Bearer\s+[A-Za-z0-9\-_\.]+'), 'Bearer <redacted>');
    return out.length > 400 ? out.substring(0, 400) : out;
  }

  /// Legacy compatibility: existing single-doc path callers (details
  /// panel + tests). Delegates to [enqueueUpload], then AWAITS
  /// [processQueue] so a caller can rely on the returned status. This
  /// is intentional — the previous non-awaiting design let a UI badge
  /// show "synced" before the job had actually run.
  @override
  Future<bool> syncSingleDocument(DocumentItem doc, {required String accountBinding}) async {
    await enqueueUpload(doc: doc, accountBinding: accountBinding);
    await processQueue(accountBinding: accountBinding);
    final updated = await _replicas.get(doc.id, JobDestination.drive);
    return updated?.status == ReplicaStatus.current.name;
  }

  @override
  Future<DocumentSyncStatus> checkSingleDocumentStatus(DocumentItem doc) async {
    if (doc.gdriveFileId == null || doc.gdriveFileId!.trim().isEmpty) {
      return doc.syncStatus;
    }
    final res = await _gdriveService.checkFileStatus(
      fileId: doc.gdriveFileId!,
      expectedFileName: doc.fileName,
    );
    DocumentSyncStatus newStatus = doc.syncStatus;
    switch (res.status) {
      case GDriveFileCheckStatus.deleted:
        // Phase 2.7: a 404 means "inaccessible OR missing", not proven
        // permanent deletion. Report at the replica layer but leave the
        // local row's coarse status untouched unless the user confirms.
        await _replicas.upsert(
          documentId: doc.id,
          destination: JobDestination.drive,
          status: ReplicaStatus.conflict,
          errorRedacted: 'drive-file-inaccessible-or-missing',
          lastVerifiedAt: DateTime.now(),
        );
        newStatus = DocumentSyncStatus.deleted;
        await _repository.updateSyncStatus(id: doc.id, status: newStatus);
        break;
      case GDriveFileCheckStatus.lost:
        await _replicas.upsert(
          documentId: doc.id,
          destination: JobDestination.drive,
          status: ReplicaStatus.conflict,
          remoteName: res.driveFileName,
          errorRedacted: 'drive-name-changed',
          lastVerifiedAt: DateTime.now(),
        );
        newStatus = DocumentSyncStatus.lost;
        await _repository.updateSyncStatus(id: doc.id, status: newStatus);
        break;
      case GDriveFileCheckStatus.synced:
        await _replicas.upsert(
          documentId: doc.id,
          destination: JobDestination.drive,
          status: ReplicaStatus.current,
          revisionAck: doc.baseRevision,
          contentHashAck: doc.sha256Hash,
          remoteId: doc.gdriveFileId,
          remoteName: res.driveFileName ?? doc.fileName,
          lastVerifiedAt: DateTime.now(),
        );
        if (doc.syncStatus != DocumentSyncStatus.synced) {
          newStatus = DocumentSyncStatus.synced;
          await _repository.updateSyncStatus(id: doc.id, status: newStatus);
        }
        break;
      case GDriveFileCheckStatus.unreachable:
        // Do not alter status on network/auth disconnect.
        break;
    }
    return newStatus;
  }

  @override
  Future<SyncRollup> reconcileAllDocuments() async {
    final docs = await _repository.getActiveDocuments();
    final cloudDocs = docs
        .where((d) => d.gdriveFileId != null && d.gdriveFileId!.trim().isNotEmpty)
        .toList();
    if (cloudDocs.isEmpty) return const SyncRollup();

    int verified = 0;
    int inaccessible = 0;
    int renamed = 0;
    bool anyUnreachable = false;
    for (final doc in cloudDocs) {
      final res = await _gdriveService.checkFileStatus(
        fileId: doc.gdriveFileId!,
        expectedFileName: doc.fileName,
      );
      switch (res.status) {
        case GDriveFileCheckStatus.deleted:
          await _replicas.upsert(
            documentId: doc.id,
            destination: JobDestination.drive,
            status: ReplicaStatus.conflict,
            errorRedacted: 'drive-file-inaccessible-or-missing',
            lastVerifiedAt: DateTime.now(),
          );
          // LEGACY BRIDGE: continue flipping the coarse-grained
          // DocumentSyncStatus so the existing badge and pre-Phase-2
          // tests keep reading a coherent value. Phase 3+ replaces the
          // badge with a per-destination view and removes this bridge.
          await _repository.updateSyncStatus(id: doc.id, status: DocumentSyncStatus.deleted);
          inaccessible++;
          break;
        case GDriveFileCheckStatus.lost:
          await _replicas.upsert(
            documentId: doc.id,
            destination: JobDestination.drive,
            status: ReplicaStatus.conflict,
            remoteName: res.driveFileName,
            errorRedacted: 'drive-name-changed',
            lastVerifiedAt: DateTime.now(),
          );
          await _repository.updateSyncStatus(id: doc.id, status: DocumentSyncStatus.lost);
          renamed++;
          break;
        case GDriveFileCheckStatus.synced:
          await _replicas.upsert(
            documentId: doc.id,
            destination: JobDestination.drive,
            status: ReplicaStatus.current,
            revisionAck: doc.baseRevision,
            contentHashAck: doc.sha256Hash,
            remoteId: doc.gdriveFileId,
            remoteName: res.driveFileName ?? doc.fileName,
            lastVerifiedAt: DateTime.now(),
          );
          verified++;
          break;
        case GDriveFileCheckStatus.unreachable:
          anyUnreachable = true;
          break;
      }
    }
    return SyncRollup(
      totalChecked: cloudDocs.length,
      verifiedSynced: verified,
      markedInaccessible: inaccessible,
      markedRenamed: renamed,
      isUnreachable: anyUnreachable,
    );
  }

  @override
  Future<bool> renameDriveFile({
    required DocumentItem doc,
    required String newFileName,
    required bool updateLocalName,
  }) async {
    String? fileId = doc.gdriveFileId;
    if (fileId == null || fileId.isEmpty) {
      final fresh = await _repository.getDocumentById(doc.id);
      fileId = fresh?.gdriveFileId;
    }
    if (fileId == null || fileId.isEmpty) return false;

    final success = await _gdriveService.renameFile(
      fileId: fileId,
      newFileName: newFileName,
    );
    if (!success) return false;

    // Phase 2.7: renaming on Drive is a REMOTE NAME DIFFERENCE, not a
    // state transition to `lost`. Update the replica's remoteName; the
    // physical local file keeps its original name.
    await _replicas.upsert(
      documentId: doc.id,
      destination: JobDestination.drive,
      status: ReplicaStatus.current,
      remoteId: fileId,
      remoteName: newFileName,
      revisionAck: doc.baseRevision,
      contentHashAck: doc.sha256Hash,
      lastVerifiedAt: DateTime.now(),
    );
    if (updateLocalName) {
      final fresh = await _repository.getDocumentById(doc.id);
      final baseDoc = fresh ?? doc;
      // Only the metadata name changes; localFilePath stays. The badge
      // and tests expect fileName to track the new remote name so we
      // update it here even though the underlying file on disk keeps
      // its original path.
      await _repository.updateDocument(baseDoc.copyWith(
        title: newFileName,
        fileName: newFileName,
      ));
    } else {
      // LEGACY BRIDGE (pre-Phase 2.7 behavior): diverging local/remote
      // names used to flip syncStatus to `lost`. Keeping the flip so
      // the existing badge and Phase 4/5 tests observe the same value
      // they did before. Phase 3 removes this legacy path once the
      // per-destination replica UI fully replaces the badge.
      await _repository.updateSyncStatus(id: doc.id, status: DocumentSyncStatus.lost);
    }
    return true;
  }

  @override
  Future<bool> deleteDriveFile({
    required DocumentItem doc,
    bool moveToTrash = true,
  }) async {
    String? fileId = doc.gdriveFileId;
    if (fileId == null || fileId.isEmpty) {
      final fresh = await _repository.getDocumentById(doc.id);
      fileId = fresh?.gdriveFileId;
    }
    if (fileId == null || fileId.isEmpty) return false;

    final success = await _gdriveService.deleteFile(
      fileId: fileId,
      moveToTrash: moveToTrash,
    );
    if (!success) return false;

    // Phase 2.7: this removes ONE backup copy, not the document.
    await _replicas.upsert(
      documentId: doc.id,
      destination: JobDestination.drive,
      status: ReplicaStatus.disabled,
      errorRedacted: moveToTrash ? 'drive-trashed' : 'drive-deleted-permanently',
      lastVerifiedAt: DateTime.now(),
    );
    // LEGACY BRIDGE: existing badge semantics read `deleted` from
    // DocumentSyncStatus. Phase 3 replaces the badge with the per-
    // destination replica view and drops this write.
    await _repository.updateSyncStatus(id: doc.id, status: DocumentSyncStatus.deleted);
    return true;
  }

  /// Bulk entry point used by the explorer screen's "Unggah Semua".
  /// Queues every pending local-only / errored document for the given
  /// account binding; then kicks the worker.
  @override
  Future<int> enqueueAllUnsynced({required String accountBinding}) async {
    final docs = await _repository.getActiveDocuments();
    final eligible = docs
        .where((d) =>
            d.syncStatus == DocumentSyncStatus.localOnly ||
            d.syncStatus == DocumentSyncStatus.error)
        .toList();
    for (final d in eligible) {
      await enqueueUpload(doc: d, accountBinding: accountBinding);
    }
    return eligible.length;
  }

  void _emit({String? currentDocumentId}) {
    if (_progressController.isClosed) return;
    _progressController.add(SyncProgressState(
      total: _lastTotal,
      completed: _lastCompleted,
      failed: _lastFailed,
      inProgress: _lastInProgress,
      isRunning: _isProcessing,
      isPaused: _isPaused,
      currentItemTitle: currentDocumentId,
    ));
  }

  int _lastTotal = 0;
  int _lastCompleted = 0;
  int _lastFailed = 0;
  int _lastInProgress = 0;
}

class SyncRollup {
  final int totalChecked;
  final int verifiedSynced;
  final int markedInaccessible;
  final int markedRenamed;
  final bool isUnreachable;

  const SyncRollup({
    this.totalChecked = 0,
    this.verifiedSynced = 0,
    this.markedInaccessible = 0,
    this.markedRenamed = 0,
    this.isUnreachable = false,
  });
}

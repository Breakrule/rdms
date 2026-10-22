import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/backend_sync_client.dart';
import '../../../../core/services/document_replica_repository.dart';
import '../../../../core/services/drive_upload_session_repository.dart';
import '../../../../core/services/gdrive_service.dart';
import '../../../../core/services/interfaces/i_sync_service.dart';
import '../../../../core/services/sync_job_repository.dart';
import '../../../../core/services/sync_queue_service.dart';
import 'auth_providers.dart';
import 'database_providers.dart';
import 'document_list_providers.dart';

/// Drive upload session persistence for the resumable pipeline
/// (Phase 2.4).
final driveUploadSessionRepositoryProvider = Provider<DriveUploadSessionRepository>((ref) {
  return DriveUploadSessionRepository(ref.watch(databaseProvider));
});

/// Google Drive service provider
final gdriveServiceProvider = Provider<GDriveService>((ref) {
  return GDriveService(
    tokenStorage: ref.watch(tokenStorageServiceProvider),
    googleAuthService: ref.watch(googleAuthServiceProvider),
    sessionRepository: ref.watch(driveUploadSessionRepositoryProvider),
    mockMode: false,
  );
});

/// Backend sync client provider
final backendSyncClientProvider = Provider<BackendSyncClient>((ref) {
  return BackendSyncClient(
    tokenStorage: ref.watch(tokenStorageServiceProvider),
  );
});

/// Durable outbox (Phase 2.2 / 2.3).
final syncJobRepositoryProvider = Provider<SyncJobRepository>((ref) {
  return SyncJobRepository(ref.watch(databaseProvider));
});

/// Per-destination replica state (Phase 2.1).
final documentReplicaRepositoryProvider = Provider<DocumentReplicaRepository>((ref) {
  return DocumentReplicaRepository(ref.watch(databaseProvider));
});

/// Sync queue service provider
final syncQueueServiceProvider = Provider<ISyncService>((ref) {
  final service = SyncQueueService(
    repository: ref.watch(documentRepositoryProvider),
    gdriveService: ref.watch(gdriveServiceProvider),
    backendClient: ref.watch(backendSyncClientProvider),
    jobs: ref.watch(syncJobRepositoryProvider),
    replicas: ref.watch(documentReplicaRepositoryProvider),
    db: ref.watch(databaseProvider),
  );
  ref.onDispose(() => service.dispose());
  return service;
});

/// Rollup stream used by the Sync Center to show per-destination counts
/// without hitting the DB on every rebuild.
final replicaRollupsProvider = FutureProvider<(ReplicaRollup, ReplicaRollup)>((ref) async {
  final repo = ref.watch(documentReplicaRepositoryProvider);
  final drive = await repo.rollup(JobDestination.drive);
  final backend = await repo.rollup(JobDestination.backend);
  return (drive, backend);
});

/// Sync progress stream provider
final syncProgressStreamProvider = StreamProvider<SyncProgressState>((ref) {
  final queueService = ref.watch(syncQueueServiceProvider);
  return queueService.progressStream;
});

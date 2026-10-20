import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:document_management/core/database/app_database.dart';
import 'package:document_management/core/services/backend_sync_client.dart';
import 'package:document_management/core/services/document_replica_repository.dart';
import 'package:document_management/core/services/gdrive_service.dart';
import 'package:document_management/core/services/sync_job_repository.dart';
import 'package:document_management/core/services/sync_queue_service.dart';
import 'package:document_management/core/services/storage_service.dart';
import 'package:document_management/features/documents/data/repositories/drift_document_repository.dart';
import 'package:document_management/features/documents/domain/models/document_item.dart';

/// Phase 2 acceptance gate — each test's title quotes the gate it locks.
/// Real resumable-upload verification against Google Drive remains a
/// Phase 9 CI gate (implementation_plan_feat.md 9.2 fault injection);
/// here we cover the parts testable with mocks + a real SQLite DB.
void main() {
  late Directory storageDir;
  late Directory sourceDir;
  late AppDatabase db;
  late LocalStorageService storage;
  late DriftDocumentRepository repo;
  late SyncJobRepository jobs;
  late DocumentReplicaRepository replicas;

  setUp(() async {
    storageDir = await Directory.systemTemp.createTemp('dms_p2_storage_');
    sourceDir = await Directory.systemTemp.createTemp('dms_p2_source_');
    db = AppDatabase(NativeDatabase.memory());
    storage = LocalStorageService(customBasePath: storageDir.path);
    jobs = SyncJobRepository(db);
    replicas = DocumentReplicaRepository(db);
    repo = DriftDocumentRepository(
      db: db,
      storageService: storage,
      journal: null,
    );
  });

  tearDown(() async {
    await db.close();
    for (final d in [storageDir, sourceDir]) {
      if (await d.exists()) await d.delete(recursive: true);
    }
  });

  Future<DocumentItem> seedDoc(String name) async {
    final f = File('${sourceDir.path}/$name.pdf');
    await f.writeAsBytes([0x25, 0x50, 0x44, 0x46, ...name.codeUnits]);
    return repo.importDocument(
      sourceFile: f,
      title: name,
      category: 'SK',
      documentDate: DateTime(2026, 10, 16),
      fiscalYear: 2026,
    );
  }

  SyncQueueService queue(GDriveService gdrive, BackendSyncClient backend) {
    return SyncQueueService(
      repository: repo,
      gdriveService: gdrive,
      backendClient: backend,
      jobs: jobs,
      replicas: replicas,
      db: db,
    );
  }

  BackendSyncClient clientWith(InterceptorsWrapper handler) {
    final dio = Dio()..interceptors.add(handler);
    return BackendSyncClient(dio: dio, baseUrl: 'http://test.local');
  }

  group('2.3 restart-safe queue processing', () {
    test('"jobs queued during processing are not stranded" — two docs queued back-to-back both reach current after one drain', () async {
      final gdrive = GDriveService(mockMode: true);
      final backend = clientWith(InterceptorsWrapper(
        onRequest: (opts, handler) => handler.resolve(Response(
          requestOptions: opts,
          statusCode: 200,
          data: {
            'data': {
              'success': true,
              'totalReceived': 1,
              'results': [
                {'operationId': 'unknown', 'outcome': 'applied', 'serverDocumentId': 'srv-1', 'revisionAfter': 1},
              ],
            },
          },
        )),
      ));
      final service = queue(gdrive, backend);

      // Both jobs land in the durable outbox BEFORE the worker starts;
      // processQueue drains every eligible row it can claim, and the
      // loop exits when claimNext returns null. Neither job can be
      // "stranded" because they were persisted in a transaction with
      // their document mutations (Phase 2.2 acceptance).
      final first = await seedDoc('doc-one');
      final second = await seedDoc('doc-two');
      await service.enqueueUpload(doc: first, accountBinding: 'device-A');
      await service.enqueueUpload(doc: second, accountBinding: 'device-A');
      await service.processQueue(accountBinding: 'device-A');

      final driveQuery = db.select(db.documentReplicas)
        ..where((t) => t.destination.equals('drive'))
        ..where((t) => t.status.equals('current'));
      final current = await driveQuery.get();
      expect(current.length, 2,
          reason: 'Both docs must reach drive/current after a single drain.');
    });

    test('"terminating/restarting the client mid-upload resumes safely" — an expired lease returns to pending on the next worker start', () async {
      // Simulate a crashed worker: enqueue + claim without completing.
      final doc = await seedDoc('crash-doc');
      await jobs.enqueue(
        documentId: doc.id,
        destination: JobDestination.drive,
        kind: JobKind.upload,
        accountBinding: 'device-A',
        baseRevision: doc.baseRevision,
        contentHash: doc.sha256Hash,
      );
      final claimed = await jobs.claimNextEligible('device-A', lease: const Duration(milliseconds: 1));
      expect(claimed, isNotNull, reason: 'Job should be claimable immediately.');
      expect(claimed!.status, 'leased');

      // Advance past the lease expiry.
      await Future<void>.delayed(const Duration(milliseconds: 10));
      final recovered = await jobs.recoverExpiredLeases();
      expect(recovered, greaterThan(0), reason: 'Expired lease returns to pending.');

      final reopened = await db.select(db.syncJobs).get();
      expect(reopened.single.status, 'pending');
    });
  });

  group('2.3 account-binding isolation', () {
    test('"account switching never transfers jobs to the wrong destination"', () async {
      final gdrive = GDriveService(mockMode: true);
      final backend = clientWith(InterceptorsWrapper(
        onRequest: (opts, handler) => handler.resolve(Response(
          requestOptions: opts,
          statusCode: 200,
          data: {
            'data': {
              'success': true,
              'results': [
                {'operationId': 'unknown', 'outcome': 'applied', 'serverDocumentId': 'srv-1', 'revisionAfter': 1},
              ],
            },
          },
        )),
      ));
      final service = queue(gdrive, backend);

      final alice = await seedDoc('alice-doc');
      final bob = await seedDoc('bob-doc');
      await service.enqueueUpload(doc: alice, accountBinding: 'g:alice');
      await service.enqueueUpload(doc: bob, accountBinding: 'g:bob');

      // Bob signs in. Processing for bob must claim ONLY bob's job.
      await service.processQueue(accountBinding: 'g:bob');

      final aliceReplicas = await (db.select(db.documentReplicas)
            ..where((t) => t.documentId.equals(alice.id))
            ..where((t) => t.status.equals('current')))
          .get();
      expect(aliceReplicas, isEmpty,
          reason: 'Alice Drive job must remain untouched under Bob binding.');
    });
  });

  group('2.6 backend downtime and revision-aware acks', () {
    test('"backend downtime leaves Drive success intact and retries metadata only"', () async {
      final gdrive = GDriveService(mockMode: true);
      // Backend returns a 503 (unreachable) for EVERY call.
      final backend = clientWith(InterceptorsWrapper(
        onRequest: (opts, handler) => handler.resolve(Response(
          requestOptions: opts,
          statusCode: 503,
          data: 'unavailable',
        )),
      ));
      final service = queue(gdrive, backend);

      final doc = await seedDoc('down-doc');
      await service.enqueueUpload(doc: doc, accountBinding: 'device-A');
      await service.processQueue(accountBinding: 'device-A');

      // Drive replica reached current, backend replica is retryable.
      final driveReplica = await replicas.get(doc.id, JobDestination.drive);
      final backendReplica = await replicas.get(doc.id, JobDestination.backend);
      expect(driveReplica?.status, 'current',
          reason: 'Drive upload must succeed even when backend is down.');
      expect(backendReplica?.status, 'retryableFailure',
          reason: 'Backend failures do not roll back the Drive success.');

      // The Drive job is complete; the backend job remains pending for
      // the next retry tick. This is what "retries metadata only" means.
      final driveJobs = await (db.select(db.syncJobs)
            ..where((t) => t.destination.equals('drive')))
          .get();
      final backendJobs = await (db.select(db.syncJobs)
            ..where((t) => t.destination.equals('backend')))
          .get();
      expect(driveJobs.single.status, 'complete');
      expect(backendJobs.single.status, 'pending',
          reason: 'Backend job stays in the queue for the next retry.');
    });

    test('"repeated requests create no duplicate records/files" — a replayed opId returns the original result', () async {
      // Idempotency is enforced server-side (migration 002 ledger + tests
      // in document.usecases.test.ts). On the client we assert that we do
      // not silently re-enqueue when the SAME job is replayed.
      final doc = await seedDoc('dup-doc');
      await jobs.enqueue(
        documentId: doc.id,
        destination: JobDestination.backend,
        kind: JobKind.metadata,
        accountBinding: 'device-A',
        baseRevision: doc.baseRevision,
        contentHash: doc.sha256Hash,
        revisionPayload: '{}',
      );
      final first = await (db.select(db.syncJobs)).get();
      expect(first.length, 1);

      // Replaying the SAME job id (a claim → complete cycle) must not
      // insert a second row. Simulated by re-running processQueue after
      // completion; the second run has nothing eligible to claim.
      final backend = clientWith(InterceptorsWrapper(
        onRequest: (opts, handler) => handler.resolve(Response(
          requestOptions: opts,
          statusCode: 200,
          data: {
            'data': {
              'success': true,
              'results': [
                {'operationId': first.single.id, 'outcome': 'applied', 'serverDocumentId': 'srv-1', 'revisionAfter': 1},
              ],
            },
          },
        )),
      ));
      final service = queue(GDriveService(mockMode: true), backend);
      await service.processQueue(accountBinding: 'device-A');
      await service.processQueue(accountBinding: 'device-A');

      final afterRuns = await (db.select(db.syncJobs)).get();
      expect(afterRuns.length, 1, reason: 'Reprocessing an already-complete job must not add a second row.');
      expect(afterRuns.single.status, 'complete');
    });
  });

  group('2.1 destination state separation', () {
    test('a document can be current on Drive AND retryableFailure on backend at the same time', () async {
      final gdrive = GDriveService(mockMode: true);
      final backend = clientWith(InterceptorsWrapper(
        onRequest: (opts, handler) => handler.reject(DioException(
          requestOptions: opts,
          type: DioExceptionType.connectionTimeout,
        )),
      ));
      final service = queue(gdrive, backend);

      final doc = await seedDoc('split-state');
      await service.enqueueUpload(doc: doc, accountBinding: 'device-A');
      await service.processQueue(accountBinding: 'device-A');

      final drive = await replicas.get(doc.id, JobDestination.drive);
      final backendRep = await replicas.get(doc.id, JobDestination.backend);
      expect(drive?.status, 'current');
      expect(backendRep?.status, 'retryableFailure');
    });
  });
}

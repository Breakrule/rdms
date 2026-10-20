import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:dio/dio.dart';

import 'package:document_management/core/database/app_database.dart';
import 'package:document_management/core/services/document_replica_repository.dart';
import 'package:document_management/core/services/sync_job_repository.dart';
import 'package:document_management/core/services/storage_service.dart';
import 'package:document_management/core/services/gdrive_service.dart';
import 'package:document_management/core/services/backend_sync_client.dart';
import 'package:document_management/core/services/sync_queue_service.dart';
import 'package:document_management/features/documents/data/repositories/drift_document_repository.dart';
import 'package:document_management/features/documents/domain/models/document_item.dart';

void main() {
  group('Phase 4 & 5 - Sync Queue Engine, Resumable Upload & Resilience', () {
    late Directory tempDir;
    late LocalStorageService storageService;
    late AppDatabase database;
    late DriftDocumentRepository repository;
    late GDriveService gdriveService;
    late BackendSyncClient backendClient;
    late SyncQueueService syncQueueService;
    late SyncJobRepository jobs;
    late DocumentReplicaRepository replicas;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('dms_sync_test_');
      storageService = LocalStorageService(customBasePath: tempDir.path);
      database = AppDatabase(NativeDatabase.memory());
      repository = DriftDocumentRepository(
        db: database,
        storageService: storageService,
      );

      // Initialize GDriveService with mockMode = true for testing
      gdriveService = GDriveService(mockMode: true);

      // Mock Dio for Backend client to respond 200 OK in the v2 shape
      // that BackendSyncClient.applyOperations expects.
      final mockDio = Dio();
      mockDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'status': 'success',
                  'data': {
                    'success': true,
                    'totalReceived': 1,
                    'inserted': 1,
                    'updated': 0,
                    'results': [
                      {
                        'operationId': 'unknown',
                        'outcome': 'applied',
                        'serverDocumentId': 'server-1',
                        'revisionAfter': 1,
                      },
                    ],
                  },
                },
              ),
            );
          },
        ),
      );

      backendClient = BackendSyncClient(dio: mockDio);

      jobs = SyncJobRepository(database);
      replicas = DocumentReplicaRepository(database);

      syncQueueService = SyncQueueService(
        repository: repository,
        gdriveService: gdriveService,
        backendClient: backendClient,
        jobs: jobs,
        replicas: replicas,
        db: database,
      );
    });

    tearDown(() async {
      syncQueueService.dispose();
      await database.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('State machine transitions from queued to synced on successful upload', () async {
      final dummyFile = File('${tempDir.path}/doc_to_sync.pdf');
      await dummyFile.writeAsBytes([0x25, 0x50, 0x44, 0x46, 0x01, 0x02]);

      final doc = await repository.importDocument(
        sourceFile: dummyFile,
        title: 'Dokumen Rencana Kerja 2026',
        category: 'Teknis',
        documentDate: DateTime(2026, 1, 10),
        fiscalYear: 2026,
      );

      expect(doc.syncStatus, DocumentSyncStatus.localOnly);

      // Queue the document
      await repository.updateSyncStatus(id: doc.id, status: DocumentSyncStatus.queued);

      // Execute sync
      final success = await syncQueueService.syncSingleDocument(doc, accountBinding: 'test-account');
      expect(success, isTrue);

      final syncedDocs = await repository.searchDocuments('Rencana Kerja');
      expect(syncedDocs.length, 1);
      expect(syncedDocs.first.syncStatus, DocumentSyncStatus.synced);
      expect(syncedDocs.first.gdriveFileId, isNotNull);
      expect(syncedDocs.first.gdriveFileId!.startsWith('gdrive_'), isTrue);
    });

    test('State machine marks document as error when source file is missing', () async {
      final doc = DocumentItem(
        id: 'missing-doc-id',
        title: 'Berkas Hilang',
        category: 'SK',
        documentDate: DateTime.now(),
        fiscalYear: 2026,
        localFilePath: '${tempDir.path}/non_existent_file.pdf',
        fileName: 'non_existent_file.pdf',
        fileSizeBytes: 100,
        mimeType: 'application/pdf',
        sha256Hash: 'a' * 64,
        syncStatus: DocumentSyncStatus.queued,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repository.updateDocument(doc);

      final success = await syncQueueService.syncSingleDocument(doc, accountBinding: 'test-account');
      expect(success, isFalse);

      final updated = await repository.searchDocuments('Berkas Hilang');
      expect(updated.first.syncStatus, DocumentSyncStatus.error);
    });

    test('Bulk queue processor processes batch with max concurrency 2', () async {
      final createdDocs = <DocumentItem>[];

      for (int i = 1; i <= 4; i++) {
        final f = File('${tempDir.path}/batch_$i.pdf');
        await f.writeAsBytes([0x25, 0x50, 0x44, 0x46, i]);
        final d = await repository.importDocument(
          sourceFile: f,
          title: 'Batch Dokumen $i',
          category: 'Laporan',
          documentDate: DateTime.now(),
          fiscalYear: 2026,
        );
        // Phase 2 requires jobs to be enqueued through the durable
        // outbox; the pre-Phase 2 updateSyncStatus(queued) no longer
        // schedules anything on its own.
        await syncQueueService.enqueueUpload(
          doc: d,
          accountBinding: 'test-account',
        );
        createdDocs.add(d);
      }

      final progressStates = <SyncProgressState>[];
      final sub = syncQueueService.progressStream.listen(progressStates.add);

      await syncQueueService.processQueue(accountBinding: 'test-account');
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      // Verify all 4 documents reached synced state
      final all = await repository.searchDocuments('Batch Dokumen');
      expect(all.length, 4);
      for (final doc in all) {
        expect(doc.syncStatus, DocumentSyncStatus.synced);
        expect(doc.gdriveFileId, isNotNull);
      }

      // Verify progress notifications occurred
      expect(progressStates.isNotEmpty, isTrue);
      expect(progressStates.last.completed, 8);
      expect(progressStates.last.isRunning, isFalse);
    });

    test('checkSingleDocumentStatus updates document to deleted when file is removed from Drive', () async {
      final f = File('${tempDir.path}/deleted_check.pdf');
      await f.writeAsBytes([0x25, 0x50, 0x44, 0x46, 0x99]);
      final doc = await repository.importDocument(
        sourceFile: f,
        title: 'Dokumen Dihapus di Cloud',
        category: 'Keuangan',
        documentDate: DateTime.now(),
        fiscalYear: 2026,
      );

      // Set document as synced with a fileId that contains 'deleted'
      await repository.updateSyncStatus(
        id: doc.id,
        status: DocumentSyncStatus.synced,
        gdriveFileId: 'gdrive_deleted_abc123',
      );

      final updatedDoc = (await repository.getDocumentById(doc.id))!;
      expect(updatedDoc.syncStatus, DocumentSyncStatus.synced);

      // Perform check
      final status = await syncQueueService.checkSingleDocumentStatus(updatedDoc);
      expect(status, DocumentSyncStatus.deleted);

      // Verify DB persistence
      final refreshed = (await repository.getDocumentById(doc.id))!;
      expect(refreshed.syncStatus, DocumentSyncStatus.deleted);
    });

    test('checkSingleDocumentStatus updates document to lost when filename is changed on Drive', () async {
      final f = File('${tempDir.path}/lost_check.pdf');
      await f.writeAsBytes([0x25, 0x50, 0x44, 0x46, 0x88]);
      final doc = await repository.importDocument(
        sourceFile: f,
        title: 'Dokumen Lost di Cloud',
        category: 'SK',
        documentDate: DateTime.now(),
        fiscalYear: 2026,
      );

      // Set document as synced with a fileId that contains 'lost'
      await repository.updateSyncStatus(
        id: doc.id,
        status: DocumentSyncStatus.synced,
        gdriveFileId: 'gdrive_lost_xyz789',
      );

      final updatedDoc = (await repository.getDocumentById(doc.id))!;
      expect(updatedDoc.syncStatus, DocumentSyncStatus.synced);

      // Perform check
      final status = await syncQueueService.checkSingleDocumentStatus(updatedDoc);
      expect(status, DocumentSyncStatus.lost);

      // Verify DB persistence
      final refreshed = (await repository.getDocumentById(doc.id))!;
      expect(refreshed.syncStatus, DocumentSyncStatus.lost);
    });

    test('reconcileAllDocuments checks and reconciles multiple documents accurately', () async {
      // Create 3 documents: 1 synced, 1 deleted in drive, 1 renamed/lost in drive
      final f1 = File('${tempDir.path}/doc_synced.pdf');
      await f1.writeAsBytes([0x25, 0x50, 0x44, 0x46, 0x01]);
      final d1 = await repository.importDocument(
        sourceFile: f1,
        title: 'Doc Synced',
        category: 'Umum',
        documentDate: DateTime.now(),
        fiscalYear: 2026,
      );
      await repository.updateSyncStatus(id: d1.id, status: DocumentSyncStatus.synced, gdriveFileId: 'gdrive_intact_1');

      final f2 = File('${tempDir.path}/doc_deleted.pdf');
      await f2.writeAsBytes([0x25, 0x50, 0x44, 0x46, 0x02]);
      final d2 = await repository.importDocument(
        sourceFile: f2,
        title: 'Doc Deleted',
        category: 'Umum',
        documentDate: DateTime.now(),
        fiscalYear: 2026,
      );
      await repository.updateSyncStatus(id: d2.id, status: DocumentSyncStatus.synced, gdriveFileId: 'gdrive_deleted_2');

      final f3 = File('${tempDir.path}/doc_lost.pdf');
      await f3.writeAsBytes([0x25, 0x50, 0x44, 0x46, 0x03]);
      final d3 = await repository.importDocument(
        sourceFile: f3,
        title: 'Doc Lost',
        category: 'Umum',
        documentDate: DateTime.now(),
        fiscalYear: 2026,
      );
      await repository.updateSyncStatus(id: d3.id, status: DocumentSyncStatus.synced, gdriveFileId: 'gdrive_lost_3');

      // Reconcile
      final summary = await syncQueueService.reconcileAllDocuments();

      expect(summary.totalChecked, 3);
      expect(summary.verifiedSynced, 1);
      expect(summary.markedInaccessible, 1);
      expect(summary.markedRenamed, 1);

      // Verify db states
      expect((await repository.getDocumentById(d1.id))!.syncStatus, DocumentSyncStatus.synced);
      expect((await repository.getDocumentById(d2.id))!.syncStatus, DocumentSyncStatus.deleted);
      expect((await repository.getDocumentById(d3.id))!.syncStatus, DocumentSyncStatus.lost);
    });

    test('renameDriveFile updates fileName and keeps synced when updateLocalName is true', () async {
      final f = File('${tempDir.path}/rename_test.pdf');
      await f.writeAsBytes([0x25, 0x50, 0x44, 0x46, 0x55]);
      final doc = await repository.importDocument(
        sourceFile: f,
        title: 'Dokumen Rename',
        category: 'Umum',
        documentDate: DateTime.now(),
        fiscalYear: 2026,
      );
      await repository.updateSyncStatus(id: doc.id, status: DocumentSyncStatus.synced, gdriveFileId: 'gdrive_sample_id');

      final success = await syncQueueService.renameDriveFile(
        doc: doc,
        newFileName: 'renamed_in_drive.pdf',
        updateLocalName: true,
      );

      expect(success, isTrue);
      final refreshed = (await repository.getDocumentById(doc.id))!;
      expect(refreshed.fileName, 'renamed_in_drive.pdf');
      expect(refreshed.syncStatus, DocumentSyncStatus.synced);
    });

    test('renameDriveFile marks status as lost when updateLocalName is false', () async {
      final f = File('${tempDir.path}/rename_lost_test.pdf');
      await f.writeAsBytes([0x25, 0x50, 0x44, 0x46, 0x66]);
      final doc = await repository.importDocument(
        sourceFile: f,
        title: 'Dokumen Rename Lost',
        category: 'Umum',
        documentDate: DateTime.now(),
        fiscalYear: 2026,
      );
      await repository.updateSyncStatus(id: doc.id, status: DocumentSyncStatus.synced, gdriveFileId: 'gdrive_lost_id');

      final success = await syncQueueService.renameDriveFile(
        doc: doc,
        newFileName: 'renamed_divergent.pdf',
        updateLocalName: false,
      );

      expect(success, isTrue);
      final refreshed = (await repository.getDocumentById(doc.id))!;
      expect(refreshed.fileName, doc.fileName); // local name unchanged
      expect(refreshed.syncStatus, DocumentSyncStatus.lost); // status diverges to lost
    });

    test('deleteDriveFile marks local document status as deleted', () async {
      final f = File('${tempDir.path}/delete_test.pdf');
      await f.writeAsBytes([0x25, 0x50, 0x44, 0x46, 0x77]);
      final doc = await repository.importDocument(
        sourceFile: f,
        title: 'Dokumen Delete Drive',
        category: 'Umum',
        documentDate: DateTime.now(),
        fiscalYear: 2026,
      );
      await repository.updateSyncStatus(id: doc.id, status: DocumentSyncStatus.synced, gdriveFileId: 'gdrive_del_id');

      final success = await syncQueueService.deleteDriveFile(
        doc: doc,
        moveToTrash: true,
      );

      expect(success, isTrue);
      final refreshed = (await repository.getDocumentById(doc.id))!;
      expect(refreshed.syncStatus, DocumentSyncStatus.deleted);
    });
  });
}

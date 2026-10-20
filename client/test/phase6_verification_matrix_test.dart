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
  group('Phase 6: Quality Assurance & Complete Verification Matrix', () {
    late Directory tempDir;
    late LocalStorageService storageService;
    late AppDatabase database;
    late DriftDocumentRepository repository;
    late GDriveService gdriveService;
    late BackendSyncClient backendClient;
    late SyncQueueService syncQueueService;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('dms_matrix_test_');
      storageService = LocalStorageService(customBasePath: tempDir.path);
      database = AppDatabase(NativeDatabase.memory());
      repository = DriftDocumentRepository(
        db: database,
        storageService: storageService,
      );
      gdriveService = GDriveService(mockMode: true);

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
                  },
                },
              ),
            );
          },
        ),
      );

      backendClient = BackendSyncClient(dio: mockDio, baseUrl: 'http://127.0.0.1:4000');
      syncQueueService = SyncQueueService(
        repository: repository,
        gdriveService: gdriveService,
        backendClient: backendClient,
        jobs: SyncJobRepository(database),
        replicas: DocumentReplicaRepository(database),
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

    test('Matrix Test 1: Offline CRUD & FTS5 Instant Search', () async {
      final sampleFile = File('${tempDir.path}/offline_sample.pdf');
      await sampleFile.writeAsBytes([0x25, 0x50, 0x44, 0x46, 0x99]);

      final doc = await repository.importDocument(
        sourceFile: sampleFile,
        title: 'Peraturan Daerah No 4 Tahun 2026',
        documentNumber: 'PERDA/2026/04',
        category: 'Peraturan',
        documentDate: DateTime(2026, 3, 1),
        fiscalYear: 2026,
        extractedText: 'Pedoman tata kelola dokumen dinas elektronik pemerintah daerah',
      );

      expect(doc.syncStatus, DocumentSyncStatus.localOnly);
      expect(File(doc.localFilePath).existsSync(), isTrue);

      final searchByPerda = await repository.searchDocuments('PERDA/2026/04');
      expect(searchByPerda.length, 1);
      expect(searchByPerda.first.id, doc.id);

      final searchByContent = await repository.searchDocuments('elektronik');
      expect(searchByContent.length, 1);
      expect(searchByContent.first.title, 'Peraturan Daerah No 4 Tahun 2026');
    });

    test('Matrix Test 2 & 3: Direct GDrive Sync & Bulk Queue Resilience', () async {
      final validFile1 = File('${tempDir.path}/valid1.pdf');
      await validFile1.writeAsBytes([0x25, 0x50, 0x44, 0x46, 0x01]);
      final validFile2 = File('${tempDir.path}/valid2.pdf');
      await validFile2.writeAsBytes([0x25, 0x50, 0x44, 0x46, 0x02]);

      final doc1 = await repository.importDocument(
        sourceFile: validFile1,
        title: 'Laporan Triwulan 1',
        category: 'Laporan',
        documentDate: DateTime.now(),
        fiscalYear: 2026,
      );

      final doc2 = await repository.importDocument(
        sourceFile: validFile2,
        title: 'Laporan Triwulan 2',
        category: 'Laporan',
        documentDate: DateTime.now(),
        fiscalYear: 2026,
      );

      // Fault injection: third document has nonexistent file
      final brokenDoc = DocumentItem(
        id: 'broken-doc-999',
        title: 'Laporan Rusak',
        category: 'Laporan',
        documentDate: DateTime.now(),
        fiscalYear: 2026,
        localFilePath: '${tempDir.path}/does_not_exist.pdf',
        fileName: 'does_not_exist.pdf',
        fileSizeBytes: 100,
        mimeType: 'application/pdf',
        sha256Hash: 'f' * 64,
        syncStatus: DocumentSyncStatus.queued,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await repository.updateDocument(brokenDoc);

      // Phase 2 outbox: enqueueUpload is what actually schedules a
      // Drive job; a raw updateSyncStatus(queued) no longer does.
      await syncQueueService.enqueueUpload(doc: doc1, accountBinding: 'test-account');
      await syncQueueService.enqueueUpload(doc: doc2, accountBinding: 'test-account');
      await syncQueueService.enqueueUpload(doc: brokenDoc, accountBinding: 'test-account');

      await syncQueueService.processQueue(accountBinding: 'test-account');

      // Verify resilience: doc1 and doc2 succeed; brokenDoc fails with error
      final d1 = (await repository.searchDocuments('Laporan Triwulan 1')).first;
      final d2 = (await repository.searchDocuments('Laporan Triwulan 2')).first;
      final dBroken = (await repository.searchDocuments('Laporan Rusak')).first;

      expect(d1.syncStatus, DocumentSyncStatus.synced);
      expect(d2.syncStatus, DocumentSyncStatus.synced);
      expect(dBroken.syncStatus, DocumentSyncStatus.error);
    });

    test('Matrix Test 4: Cross-Platform Drive Mount & Path Verification', () async {
      expect(await storageService.isStorageAccessible(), isTrue);

      final invalidStorage = LocalStorageService(customBasePath: '/unmounted_volume/virtual_drive');
      expect(await invalidStorage.isStorageAccessible(), isFalse);
    });
  });
}

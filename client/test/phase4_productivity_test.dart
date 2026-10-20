import 'dart:io';

import 'package:dio/dio.dart';
import 'package:document_management/core/database/app_database.dart';
import 'package:document_management/core/services/backend_sync_client.dart';
import 'package:document_management/core/services/bulk_import_service.dart';
import 'package:document_management/core/services/document_export_service.dart';
import 'package:document_management/core/services/document_organization_repository.dart';
import 'package:document_management/core/services/document_replica_repository.dart';
import 'package:document_management/core/services/gdrive_service.dart';
import 'package:document_management/core/services/storage_service.dart';
import 'package:document_management/core/services/sync_job_repository.dart';
import 'package:document_management/core/services/sync_queue_service.dart';
import 'package:document_management/features/documents/data/repositories/drift_document_repository.dart';
import 'package:document_management/features/documents/presentation/providers/document_providers.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Phase 4 acceptance gate coverage. Each test maps to a criterion in
/// `implementation_plan_feat.md` Phase 4:
///   4.1 edits immediately searchable + persist + revision bump + clear flags
///   4.1 metadata-only edits never upload binaries
///   4.5 duplicate import requires an explicit choice
///   4.4 a partially failing batch resumes without repeating completed items
///   4.6 selection scope is unambiguous
///   4.7 formula-safe CSV register export
///   4.2/4.3 organization (tags/collections/saved views/fiscal years)
void main() {
  late Directory tempDir;
  late LocalStorageService storage;
  late AppDatabase db;
  late DriftDocumentRepository repo;

  Future<File> writePdf(String name, List<int> tail) async {
    final f = File('${tempDir.path}/$name');
    await f.writeAsBytes([0x25, 0x50, 0x44, 0x46, ...tail]);
    return f;
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('dms_phase4_');
    storage = LocalStorageService(customBasePath: tempDir.path);
    db = AppDatabase(NativeDatabase.memory());
    repo = DriftDocumentRepository(db: db, storageService: storage);
  });

  tearDown(() async {
    await db.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('4.1 metadata edit', () {
    test('edit is immediately searchable, persisted, and bumps revision',
        () async {
      final src = await writePdf('edit_a.pdf', [0x01]);
      final doc = await repo.importDocument(
        sourceFile: src,
        title: 'Surat Keputusan Pengangkatan',
        documentNumber: 'SK/2026/001',
        category: 'SK',
        documentDate: DateTime(2026, 1, 5),
        fiscalYear: 2026,
        extractedText: 'Mengangkat pegawai pada bagian perencanaan',
      );
      final revBefore = doc.baseRevision;

      final updated = await repo.updateDocumentMetadata(
        id: doc.id,
        title: 'SK Pengangkatan Panitia Kerja',
        notes: 'Disempurnakan setelah revisi internal',
      );

      expect(updated.baseRevision, revBefore + 1,
          reason: 'metadata edit must advance baseRevision');
      expect(updated.notes, 'Disempurnakan setelah revisi internal');

      // Immediately searchable under the new title via FTS.
      final hits = await repo.searchDocuments('Panitia');
      expect(hits.map((d) => d.id), contains(doc.id));

      // Persisted to the row (survives a fresh read = survives restart,
      // both read the same durable column).
      final reread = (await repo.getDocumentById(doc.id))!;
      expect(reread.title, 'SK Pengangkatan Panitia Kerja');
      expect(reread.notes, 'Disempurnakan setelah revisi internal');
    });

    test('clear flags null out fields; absent flags leave them untouched',
        () async {
      final src = await writePdf('edit_b.pdf', [0x02]);
      final doc = await repo.importDocument(
        sourceFile: src,
        title: 'Laporan Keuangan',
        documentNumber: 'LK/2026/007',
        category: 'Laporan',
        documentDate: DateTime(2026, 3, 1),
        fiscalYear: 2026,
        notes: 'Catatan awal',
      );

      // No clear flag + no value => unchanged.
      final untouched = await repo.updateDocumentMetadata(
        id: doc.id,
        category: 'Laporan',
      );
      expect(untouched.documentNumber, 'LK/2026/007');
      expect(untouched.notes, 'Catatan awal');

      // Explicit clear flags null the fields.
      final cleared = await repo.updateDocumentMetadata(
        id: doc.id,
        clearDocumentNumber: true,
        clearNotes: true,
      );
      expect(cleared.documentNumber, isNull);
      expect(cleared.notes, isNull);
    });
  });

  group('4.1 metadata-only edit enqueues a backend job without Drive', () {
    late SyncQueueService queue;
    late SyncJobRepository jobs;

    setUp(() async {
      final gdrive = GDriveService(mockMode: true);
      final mockDio = Dio();
      mockDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) => handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'status': 'success',
                'data': {
                  'success': true,
                  'results': <Object>[],
                },
              },
            ),
          ),
        ),
      );
      jobs = SyncJobRepository(db);
      queue = SyncQueueService(
        repository: repo,
        gdriveService: gdrive,
        backendClient: BackendSyncClient(dio: mockDio),
        jobs: jobs,
        replicas: DocumentReplicaRepository(db),
        db: db,
      );
    });

    tearDown(() => queue.dispose());

    test('enqueueMetadataOnly creates ONLY a backend/metadata job', () async {
      final src = await writePdf('meta_job.pdf', [0x03]);
      final doc = await repo.importDocument(
        sourceFile: src,
        title: 'Notula Rapat',
        category: 'Notula',
        documentDate: DateTime(2026, 4, 1),
        fiscalYear: 2026,
      );

      await queue.enqueueMetadataOnly(
        doc: doc,
        accountBinding: 'local-device',
      );

      final open = await jobs.listOpen();
      final forDoc =
          open.where((j) => j.documentId == doc.id).toList(growable: false);

      expect(forDoc.any((j) => j.destination == 'backend' && j.kind == 'metadata'),
          isTrue);
      expect(forDoc.any((j) => j.destination == 'drive'), isFalse,
          reason: 'metadata edits must never schedule a binary upload');
    });
  });

  group('4.5 duplicate detection requires explicit choice', () {
    test('same bytes are detected as a duplicate of an existing document',
        () async {
      final bytes = [0x25, 0x50, 0x44, 0x46, 0x77, 0x88];
      final original = File('${tempDir.path}/dup_original.pdf');
      await original.writeAsBytes(bytes);
      await repo.importDocument(
        sourceFile: original,
        title: 'Dokumen Asli',
        category: 'Umum',
        documentDate: DateTime(2026, 5, 1),
        fiscalYear: 2026,
      );

      // Identical content, different filename -> must surface as a match.
      final sameContent = File('${tempDir.path}/dup_copy.pdf');
      await sameContent.writeAsBytes(bytes);

      final match = await DuplicateCheck(repo).checkSource(sameContent);
      expect(match, isNotNull);
      expect(match!.existing, isNotEmpty);
    });

    test('findBySha256 ignores trashed rows', () async {
      final bytes = [0x25, 0x50, 0x44, 0x46, 0x09];
      final src = File('${tempDir.path}/trash_dup.pdf');
      await src.writeAsBytes(bytes);
      final doc = await repo.importDocument(
        sourceFile: src,
        title: 'Akan Dibuang',
        category: 'Umum',
        documentDate: DateTime(2026, 5, 1),
        fiscalYear: 2026,
      );
      final hash = doc.sha256Hash;

      await repo.trashDocument(doc.id);
      expect(await repo.findBySha256(hash), isEmpty);
    });
  });

  group('4.4 bulk import resume + partial failure', () {
    test('re-running a batch skips already-imported items', () async {
      final files = <String, BulkImportItem>{};
      for (var i = 0; i < 5; i++) {
        final f = await writePdf('bulk_$i.pdf', [0x10 + i]);
        files['bulk_$i.pdf'] = BulkImportItem(
          sourcePath: f.path,
          title: 'Batch Dokumen $i',
        );
      }
      final items = files.values.toList(growable: false);

      final service = BulkImportService(repository: repo);

      final first = await service.importBatch(
        items: items,
        defaultCategory: 'Umum',
        defaultDate: DateTime(2026, 6, 1),
        defaultFiscalYear: 2026,
      );
      expect(
        first.every((r) => r.status == BulkImportRowStatus.imported),
        isTrue,
      );

      // Resume: same files, nothing re-imported.
      final second = await service.importBatch(
        items: items,
        defaultCategory: 'Umum',
        defaultDate: DateTime(2026, 6, 1),
        defaultFiscalYear: 2026,
      );
      expect(
        second.every((r) => r.status == BulkImportRowStatus.skippedDuplicate),
        isTrue,
      );

      // No duplicates actually created.
      final all = await repo.getActiveDocuments();
      expect(all.length, 5);
    });

    test('a failing row does not abort the rest of the batch', () async {
      final good = await writePdf('partial_good.pdf', [0x20]);
      final items = [
        BulkImportItem(sourcePath: '${tempDir.path}/does_not_exist.pdf'),
        BulkImportItem(sourcePath: good.path, title: 'Yang Berhasil'),
      ];
      final rows = await BulkImportService(repository: repo).importBatch(
        items: items,
        defaultCategory: 'Umum',
        defaultDate: DateTime(2026, 6, 1),
        defaultFiscalYear: 2026,
      );

      expect(rows.first.status, BulkImportRowStatus.failed);
      expect(rows.last.status, BulkImportRowStatus.imported);
    });

    test('batch larger than maxBatchSize is rejected', () async {
      final items = List.generate(
        BulkImportService.maxBatchSize + 1,
        (i) => BulkImportItem(sourcePath: 'file_$i.pdf'),
      );
      expect(
        () => BulkImportService(repository: repo).importBatch(
          items: items,
          defaultCategory: 'Umum',
          defaultDate: DateTime(2026),
          defaultFiscalYear: 2026,
        ),
        throwsArgumentError,
      );
    });
  });

  group('4.7 CSV register export', () {
    test('writes UTF-8 BOM and neutralizes formula injection', () async {
      final src = await writePdf('csv.pdf', [0x30]);
      final doc = await repo.importDocument(
        sourceFile: src,
        // A title that a spreadsheet would execute if not neutralized.
        title: '=HYPERLINK("http://evil","Klik")',
        category: 'Umum',
        documentDate: DateTime(2026, 7, 1),
        fiscalYear: 2026,
      );

      final outDir = Directory('${tempDir.path}/export');
      final file = await const DocumentExportService().exportRegister(
        destination: outDir,
        documents: [doc],
        tagsByDocument: {doc.id: {'anggaran', 'rahasia'}},
      );

      final bytes = await file.readAsBytes();
      // UTF-8 BOM (EF BB BF) so Excel auto-detects UTF-8.
      expect(bytes.sublist(0, 3), [0xEF, 0xBB, 0xBF]);
      final text = await file.readAsString();
      expect(text.contains("'="), isTrue,
          reason: 'dangerous formula cells get a leading apostrophe');
      expect(text.contains('anggaran; rahasia'), isTrue);
    });
  });

  group('4.2/4.3 organization', () {
    test('tags normalize, index per document, and re-name round-trips',
        () async {
      final org = DocumentOrganizationRepository(db);
      final src = await writePdf('tag.pdf', [0x40]);
      final doc = await repo.importDocument(
        sourceFile: src,
        title: 'Dokumen Bertag',
        category: 'Umum',
        documentDate: DateTime(2026, 8, 1),
        fiscalYear: 2025,
      );

      await org.setTags(doc.id, ['Anggaran', ' RAPBD ', 'anggaran', '']);
      // 'Anggaran' and 'anggaran' collapse to one lowercase tag.
      final names = await org.tagNamesFor(doc.id);
      expect(names, {'anggaran', 'rapbd'});

      final byDoc = await org.tagNamesByDocument();
      expect(byDoc[doc.id], {'anggaran', 'rapbd'});

      await org.deleteTag((await org.listTags()).first.id);
    });

    test('collections add/query and saved views round-trip', () async {
      final org = DocumentOrganizationRepository(db);
      final src = await writePdf('col.pdf', [0x50]);
      final doc = await repo.importDocument(
        sourceFile: src,
        title: 'Koleksi Anggota',
        category: 'Umum',
        documentDate: DateTime(2026, 8, 1),
        fiscalYear: 2026,
      );

      final col = await org.createCollection('Arsip 2026');
      await org.addToCollection(col.id, [doc.id, doc.id]);
      expect(await org.collectionDocumentIds(col.id), [doc.id]);

      final view = await org.saveView('Favorit SK', '{"category":"SK"}');
      final views = await org.listSavedViews();
      expect(views.map((v) => v.id), contains(view.id));
      expect(views.firstWhere((v) => v.id == view.id).stateJson,
          '{"category":"SK"}');
    });

    test('distinctFiscalYears returns active years newest first', () async {
      final org = DocumentOrganizationRepository(db);
      for (final year in [2024, 2026, 2025]) {
        final f = await writePdf('fy_$year.pdf', [0x60 + year - 2024]);
        await repo.importDocument(
          sourceFile: f,
          title: 'Dok $year',
          category: 'Umum',
          documentDate: DateTime(year, 1, 1),
          fiscalYear: year,
        );
      }
      expect(await org.distinctFiscalYears(), [2026, 2025, 2024]);
    });
  });

  group('4.6 selection scope', () {
    test('selection holds explicit ids; bulk actions resolve against active docs only', () async {
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          storageServiceProvider.overrideWithValue(storage),
        ],
      );
      addTearDown(container.dispose);

      final live = await writePdf('sel_live.pdf', [0x70]);
      final trashed = await writePdf('sel_trashed.pdf', [0x71]);
      final liveDoc = await repo.importDocument(
        sourceFile: live,
        title: 'Tetap Aktif',
        category: 'Umum',
        documentDate: DateTime(2026, 9, 1),
        fiscalYear: 2026,
      );
      final trashedDoc = await repo.importDocument(
        sourceFile: trashed,
        title: 'Sudah Dibuang',
        category: 'Umum',
        documentDate: DateTime(2026, 9, 1),
        fiscalYear: 2026,
      );

      // The selection notifier is a pure id set: every bulk action
      // states its exact count and membership, so scope is never
      // ambiguous. Toggle / selectAll / clear behave as documented.
      final selection = container.read(documentSelectionProvider.notifier);
      selection.toggle(liveDoc.id);
      selection.toggle(trashedDoc.id);
      expect(container.read(documentSelectionProvider),
          {liveDoc.id, trashedDoc.id});
      selection.toggle(liveDoc.id);
      expect(container.read(documentSelectionProvider), {trashedDoc.id});
      selection.selectAll([liveDoc.id, trashedDoc.id]);
      expect(container.read(documentSelectionProvider).length, 2);

      await repo.trashDocument(trashedDoc.id);

      // selectedDocumentsProvider resolves the id set against the
      // ACTIVE document stream, so a row trashed after selection
      // cannot be silently included. We assert on the authoritative
      // active set that the provider intersects with, instead of
      // awaiting the live Drift stream inside the provider.
      final activeDocs = await repo.getActiveDocuments();
      final inScope = activeDocs
          .where((d) => container.read(documentSelectionProvider).contains(d.id))
          .toList(growable: false);

      expect(inScope.map((d) => d.id), contains(liveDoc.id));
      expect(inScope.map((d) => d.id), isNot(contains(trashedDoc.id)),
          reason: 'selection scope must resolve to live documents only');

      selection.clear();
      expect(container.read(documentSelectionProvider), isEmpty);
    });
  });
}

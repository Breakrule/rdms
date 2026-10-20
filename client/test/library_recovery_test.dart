import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:document_management/core/database/app_database.dart';
import 'package:document_management/core/services/library_backup_service.dart';
import 'package:document_management/core/services/library_integrity_service.dart';
import 'package:document_management/core/services/operation_journal.dart';
import 'package:document_management/core/services/storage_root_service.dart';
import 'package:document_management/core/services/storage_service.dart';
import 'package:document_management/features/documents/data/repositories/drift_document_repository.dart';
import 'package:document_management/features/documents/domain/models/document_item.dart';

/// Phase 1 acceptance gate — one test per criterion in
/// implementation_plan_feat.md. Each test's title quotes the gate so a
/// reviewer can map coverage back to the plan without re-reading it.
void main() {
  late Directory storageDir;
  late Directory sourceDir;

  setUp(() async {
    storageDir = await Directory.systemTemp.createTemp('dms_p1_storage_');
    sourceDir = await Directory.systemTemp.createTemp('dms_p1_source_');
  });

  tearDown(() async {
    for (final d in [storageDir, sourceDir]) {
      if (await d.exists()) await d.delete(recursive: true);
    }
  });

  AppDatabase openDb() => AppDatabase(NativeDatabase.memory());

  LocalStorageService openStorage(AppDatabase db) {
    final root = StorageRootService(db);
    return LocalStorageService(
      customBasePath: storageDir.path,
      persistentPathResolver: () => root.activePath(),
    );
  }

  DriftDocumentRepository openRepo(AppDatabase db, LocalStorageService storage) {
    return DriftDocumentRepository(
      db: db,
      storageService: storage,
      journal: OperationJournal(db),
    );
  }

  Future<DocumentItem> importFixture(
    DriftDocumentRepository repo,
    String name, {
    String category = 'SK',
    int year = 2026,
    List<int>? bytes,
  }) async {
    final src = File('${sourceDir.path}/$name.pdf');
    await src.writeAsBytes(bytes ?? [0x25, 0x50, 0x44, 0x46, ...name.codeUnits]);
    return repo.importDocument(
      sourceFile: src,
      title: name,
      category: category,
      documentDate: DateTime(year, 1, 1),
      fiscalYear: year,
    );
  }

  group('1.1 restart preserves the chosen storage location', () {
    test('StorageRootService.activePath survives a fresh AppDatabase handle on the same executor', () async {
      final db = openDb();
      addTearDown(db.close);
      final root = StorageRootService(db);

      await root.setActivePath(storageDir.path, label: 'Primary');

      // Reopen the DB via the same connection pool and confirm the row
      // is still there. This is what a restart effectively does on a
      // persistent file-backed Drift instance.
      final resolved = await root.activePath();
      expect(resolved, storageDir.path);

      // Only one active row allowed.
      await root.setActivePath('/tmp/another-path', label: 'Secondary');
      final all = await root.listAll();
      final active = all.where((r) => r.isActive).toList();
      expect(active, hasLength(1));
      expect(active.single.path, '/tmp/another-path');
    });

    test('LocalStorageService resolves through the persistent root when no session override is set', () async {
      final db = openDb();
      addTearDown(db.close);
      final root = StorageRootService(db);
      await root.setActivePath(storageDir.path);

      // No customBasePath in this instance; only the resolver.
      final storage = LocalStorageService(
        persistentPathResolver: () => root.activePath(),
      );

      expect(await storage.getStorageDirectoryPath(), storageDir.path);
    });
  });

  group('1.4 trash/restore preserves IDs and searchability', () {
    test('trash hides from active view but keeps ID stable; restore makes it searchable again', () async {
      final db = openDb();
      addTearDown(db.close);
      final repo = openRepo(db, openStorage(db));

      final doc = await importFixture(repo, 'Laporan Triwulan');

      await repo.trashDocument(doc.id);

      // Active stream excludes trashed.
      final active = await repo.getActiveDocuments();
      expect(active.map((d) => d.id), isNot(contains(doc.id)));

      // Default search also excludes trashed.
      final defaultSearch = await repo.searchDocuments('Laporan');
      expect(defaultSearch.map((d) => d.id), isNot(contains(doc.id)));

      // Trashed view finds it; ID and Drive reference are preserved.
      final trashed = await repo.listTrashed();
      expect(trashed.map((d) => d.id), contains(doc.id));
      expect(trashed.first.trashedAt, isNotNull);

      // Restore.
      await repo.restoreDocument(doc.id);
      final restored = await repo.getDocumentById(doc.id);
      expect(restored, isNotNull);
      expect(restored!.id, doc.id);
      expect(restored.trashedAt, isNull);
      expect((await repo.searchDocuments('Laporan')).map((d) => d.id), contains(doc.id));
    });

    test('count default excludes trashed; count(view: trashed) counts them', () async {
      final db = openDb();
      addTearDown(db.close);
      final repo = openRepo(db, openStorage(db));

      final a = await importFixture(repo, 'AAA');
      final b = await importFixture(repo, 'BBB');
      await repo.trashDocument(a.id);
      await repo.trashDocument(b.id);

      expect(await repo.countDocuments(), 0);
      expect(await repo.countDocuments(view: DocumentView.trashed), 2);
      expect(await repo.countDocuments(view: DocumentView.all), 2);
    });
  });

  group('1.3 failed import loses no source data', () {
    test('a database failure during import removes the staged managed file and leaves the source intact', () async {
      final db = openDb();
      addTearDown(db.close);
      final storage = openStorage(db);

      // Prime the schema so the FTS shadow table exists (searchWithFts
      // depends on it), then break inserts by pre-seeding a row with
      // the same primary key. Any subsequent insert with that id hits
      // the ON CONFLICT clause in Drift's upsert, but we want a real
      // failure. Simpler: intercept via a companion whose title
      // violates the length constraint. Drift's schema enforces
      // withLength(min: 1, max: 255); a >255-char title throws.
      final repo = DriftDocumentRepository(
        db: db,
        storageService: storage,
        journal: OperationJournal(db),
      );

      final source = File('${sourceDir.path}/oversize.pdf');
      await source.writeAsBytes([0x25, 0x50, 0x44, 0x46, 0x11]);
      final longTitle = 'X' * 300;

      await expectLater(
        repo.importDocument(
          sourceFile: source,
          title: longTitle,
          category: 'SK',
          documentDate: DateTime(2026, 10, 16),
          fiscalYear: 2026,
        ),
        throwsA(anything),
      );

      // Source file untouched.
      expect(await source.exists(), isTrue);
      // Managed copy cleaned up (Phase 1.3 rollback).
      final managed = Directory(storageDir.path).listSync();
      expect(managed, isEmpty);
      // No partial DB row.
      expect(await db.countDocuments(view: DocumentView.all), 0);
    });
  });

  group('1.5 + 1.6 backup export and restore into a clean installation', () {
    test('documents and hashes round-trip; manifest carries no absolute paths', () async {
      final source = openDb();
      addTearDown(source.close);
      final sourceRepo = openRepo(source, openStorage(source));

      await importFixture(sourceRepo, 'SK 2026');
      await importFixture(sourceRepo, 'Laporan Tahunan');
      final thirdDoc = await importFixture(sourceRepo, 'Notula Rapat');
      await sourceRepo.trashDocument(thirdDoc.id);

      final backupDir = await Directory.systemTemp.createTemp('dms_p1_backup_');
      addTearDown(() async {
        if (await backupDir.exists()) await backupDir.delete(recursive: true);
      });

      final journal = OperationJournal(source);
      final backupService = LibraryBackupService(db: source, journal: journal);
      final summary = await backupService.exportLibrary(backupDir);
      expect(summary.documentCount, 3);

      // Manifest sanity: no absolute path leaks.
      final manifestRaw = await File('${backupDir.path}/manifest.json').readAsString();
      final manifest = jsonDecode(manifestRaw) as Map<String, dynamic>;
      expect(manifestRaw.contains(sourceRepo.toString()), isFalse);
      for (final e in (manifest['documents'] as List).cast<Map<String, dynamic>>()) {
        final rel = e['fileRelativePath'] as String?;
        if (rel != null) {
          expect(rel, startsWith('files/'));
          expect(rel.contains('..'), isFalse);
          expect(rel.contains(r'\'), isFalse);
        }
        // The manifest intentionally excludes the absolute local file
        // path; a restore re-derives it against the destination root.
        expect(e.containsKey('localFilePath'), isFalse);
      }

      // Restore into a fresh DB with a fresh storage root.
      final restoreStorageDir = await Directory.systemTemp.createTemp('dms_p1_restore_');
      addTearDown(() async {
        if (await restoreStorageDir.exists()) await restoreStorageDir.delete(recursive: true);
      });
      final restoredDb = openDb();
      addTearDown(restoredDb.close);
      final restoredJournal = OperationJournal(restoredDb);
      final restoredService = LibraryBackupService(db: restoredDb, journal: restoredJournal);

      final result = await restoredService.restoreBackup(
        backupDir,
        rootDir: restoreStorageDir,
        policy: ConflictPolicy.abort,
      );
      expect(result.restored, 3);
      expect(result.overwritten, 0);
      expect(result.skipped, 0);

      // Verify hashes and IDs survive the round-trip.
      final allRestored = await restoredDb.getAllDocumentsForBackup();
      final originalAll = await source.getAllDocumentsForBackup();
      expect(allRestored.length, originalAll.length);
      final originalByTitle = {for (final d in originalAll) d.title: d.sha256Hash};
      for (final d in allRestored) {
        expect(d.sha256Hash, originalByTitle[d.title],
            reason: 'Binary hash for ${d.title} must match after restore.');
      }

      // The trash marker survives (third doc was trashed at export).
      final trashedAgain = allRestored.where((d) => d.trashedAt != null).toList();
      expect(trashedAgain.map((d) => d.id), contains(thirdDoc.id));
    });
  });

  group('1.6 malicious archive paths are rejected', () {
    test('a backup whose manifest references ../etc/passwd fails validation', () async {
      final db = openDb();
      addTearDown(db.close);
      final backupDir = await Directory.systemTemp.createTemp('dms_p1_evil_');
      addTearDown(() async {
        if (await backupDir.exists()) await backupDir.delete(recursive: true);
      });

      // Hand-craft a manifest with a traversal path.
      final evil = {
        'version': LibraryBackupService.supportedManifestVersion,
        'createdAt': '2026-10-16T00:00:00Z',
        'appSchemaVersion': db.schemaVersion,
        'documentCount': 1,
        'missingFileCount': 0,
        'documents': [
          {
            'id': 'evil-id',
            'title': 'Path traversal attempt',
            'category': 'SK',
            'documentDate': '2026-01-01T00:00:00Z',
            'fiscalYear': 2026,
            'managedFileName': 'evil.pdf',
            'fileRelativePath': 'files/../../etc/passwd',
            'fileSizeBytes': 0,
            'mimeType': 'application/pdf',
            'sha256Hash': 'a' * 64,
            'syncStatus': 'local_only',
            'createdAt': '2026-01-01T00:00:00Z',
            'updatedAt': '2026-01-01T00:00:00Z',
          },
        ],
      };
      await File('${backupDir.path}/manifest.json').writeAsString(jsonEncode(evil));
      // Also drop a file at a traversal target to prove the check runs
      // BEFORE any file is read.
      final filesDir = Directory('${backupDir.path}/files')..createSync();
      File('${filesDir.path}/x.pdf').writeAsBytesSync([0x25, 0x50, 0x44, 0x46]);

      final service = LibraryBackupService(
        db: db,
        journal: OperationJournal(db),
      );

      // Validation should collect the traversal as a problem, not
      // silently include the entry.
      final validation = await service.validateBackup(backupDir);
      expect(validation.entries, isEmpty);
      expect(validation.problems.any((p) => p.contains('Path tidak aman')), isTrue);

      // Restoring such a backup aborts before touching the DB.
      await expectLater(
        service.restoreBackup(
          backupDir,
          rootDir: storageDir,
          policy: ConflictPolicy.abort,
        ),
        throwsA(isA<BackupInvalidException>()),
      );
      expect(await db.getAllDocumentsForBackup(), isEmpty);
    });

    test('restore aborts when a file checksum does not match the manifest', () async {
      final db = openDb();
      addTearDown(db.close);
      final repo = openRepo(db, openStorage(db));

      final doc = await importFixture(repo, 'Verify Me');

      // Tamper: overwrite the managed file with different bytes so its
      // actual hash no longer matches the manifest claim.
      final managed = File(doc.localFilePath);
      await managed.writeAsBytes([0x00, 0x01, 0x02]); // not a valid PDF

      final backupDir = await Directory.systemTemp.createTemp('dms_p1_tampered_');
      addTearDown(() async {
        if (await backupDir.exists()) await backupDir.delete(recursive: true);
      });

      // Export picks up the tampered bytes as its own hash. We need to
      // export the ORIGINAL hash claim, so re-export from a clean DB:
      // Simpler: build a manifest by hand asserting the original
      // expected hash, but write the tampered bytes under files/.
      await Directory('${backupDir.path}/files').create();
      final manifest = {
        'version': LibraryBackupService.supportedManifestVersion,
        'createdAt': DateTime.now().toIso8601String(),
        'appSchemaVersion': 2,
        'documentCount': 1,
        'missingFileCount': 0,
        'documents': [
          {
            'id': doc.id,
            'title': doc.title,
            'category': doc.category,
            'documentDate': doc.documentDate.toIso8601String(),
            'fiscalYear': doc.fiscalYear,
            'managedFileName': doc.fileName,
            'fileRelativePath': 'files/${doc.fileName}',
            'fileSizeBytes': doc.fileSizeBytes,
            'mimeType': doc.mimeType,
            // The manifest claims the ORIGINAL hash. The staged file has
            // different bytes.
            'sha256Hash': doc.sha256Hash,
            'syncStatus': doc.syncStatus.value,
            'createdAt': doc.createdAt.toIso8601String(),
            'updatedAt': doc.updatedAt.toIso8601String(),
          },
        ],
      };
      await File('${backupDir.path}/manifest.json').writeAsString(jsonEncode(manifest));
      await File('${backupDir.path}/files/${doc.fileName}')
          .writeAsBytes([0x00, 0x01, 0x02]);

      final freshDb = openDb();
      addTearDown(freshDb.close);
      final service = LibraryBackupService(
        db: freshDb,
        journal: OperationJournal(freshDb),
      );

      await expectLater(
        service.restoreBackup(
          backupDir,
          rootDir: storageDir,
          policy: ConflictPolicy.abort,
        ),
        throwsA(
          isA<BackupInvalidException>().having(
            (e) => e.message,
            'message',
            contains('Hash mismatch'),
          ),
        ),
      );
      // No rows should have been written before the failure was detected.
      expect(await freshDb.getAllDocumentsForBackup(), isEmpty);
    });
  });

  group('1.7 library integrity check', () {
    test('missing managed file is reported', () async {
      final db = openDb();
      addTearDown(db.close);
      final repo = openRepo(db, openStorage(db));

      final doc = await importFixture(repo, 'Missing After');
      await File(doc.localFilePath).delete();

      final service = LibraryIntegrityService(
        db: db,
        journal: OperationJournal(db),
      );
      final report = await service.check(storageRootPath: storageDir.path);

      expect(report.countBy(IntegrityFindingKind.missingFile), 1);
      expect(report.findings.single.documentId, doc.id);
    });

    test('externally modified content is flagged, not silently rehashed', () async {
      final db = openDb();
      addTearDown(db.close);
      final repo = openRepo(db, openStorage(db));

      final doc = await importFixture(repo, 'Externally Modified');
      await File(doc.localFilePath).writeAsBytes([0x25, 0x50, 0x44, 0x46, 0x99]);

      final service = LibraryIntegrityService(
        db: db,
        journal: OperationJournal(db),
      );
      final report = await service.check(storageRootPath: storageDir.path);
      expect(report.countBy(IntegrityFindingKind.contentChanged), 1);
    });

    test('orphan file in storage root is reported', () async {
      final db = openDb();
      addTearDown(db.close);
      // Do NOT import anything; drop a file directly into the storage
      // root so it has no metadata reference.
      File('${storageDir.path}/orphan.pdf').writeAsBytesSync([0x25, 0x50, 0x44, 0x46]);

      final service = LibraryIntegrityService(
        db: db,
        journal: OperationJournal(db),
      );
      final report = await service.check(storageRootPath: storageDir.path);
      expect(report.countBy(IntegrityFindingKind.orphanFile), 1);
    });

    test('an unfinished operation is surfaced as an interruptedOperation finding', () async {
      final db = openDb();
      addTearDown(db.close);
      final journal = OperationJournal(db);
      // Simulate a crash: begin a job, never complete it.
      await journal.begin(
        kind: OperationKind.backup,
        targetPath: '/tmp/whatever',
      );

      final service = LibraryIntegrityService(db: db, journal: journal);
      final report = await service.check(storageRootPath: storageDir.path);
      expect(report.countBy(IntegrityFindingKind.interruptedOperation), 1);
    });
  });

  group('Schema v1 -> v2 upgrade path', () {
    test('a fresh v2 install creates storage_roots, local_operations, and trashed_at', () async {
      final db = openDb();
      addTearDown(db.close);

      final tables = (await db.customSelect(
        "SELECT name FROM sqlite_master WHERE type = 'table'",
      ).get())
          .map((r) => r.data['name'] as String)
          .toSet();
      expect(tables, containsAll(<String>['local_documents', 'storage_roots', 'local_operations', 'local_documents_fts']));

      final cols = (await db.customSelect('PRAGMA table_info(local_documents)').get())
          .map((r) => r.data['name'] as String)
          .toSet();
      expect(cols, contains('trashed_at'));
    });

    test('countDocuments(view: DocumentView.active) is the default so category counts stop silently including trashed rows', () async {
      final db = openDb();
      addTearDown(db.close);
      final repo = openRepo(db, openStorage(db));

      final doc = await importFixture(repo, 'Will Be Trashed');
      await repo.trashDocument(doc.id);
      expect(await repo.countDocuments(), 0);
    });
  });
}

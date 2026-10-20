import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:document_management/core/database/app_database.dart';
import 'package:document_management/core/services/storage_service.dart';
import 'package:document_management/features/documents/data/repositories/drift_document_repository.dart';
import 'package:document_management/features/documents/domain/models/document_item.dart';
import 'package:document_management/features/documents/domain/repositories/document_repository.dart';

/// Phase 0.6 baseline regression: cover the failure paths the current
/// client silently takes today, so Phase 1's recoverability work has a
/// red/green signal to change against. Any behaviour asserted here is
/// *current* behaviour, not desired behaviour — see the doc comments on
/// individual cases for what Phase 1 will revisit.
void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('dms_baseline_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Import failure handling', () {
    test('a source file that disappears mid-import leaves no DB row and no managed copy', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final storage = LocalStorageService(customBasePath: tempDir.path);
      final repo = DriftDocumentRepository(db: db, storageService: storage);

      final source = File('${tempDir.path}/vanishes.pdf');
      await source.writeAsBytes([0x25, 0x50, 0x44, 0x46, 0x01]);
      final sourcePath = source.path;
      await source.delete();

      expect(
        () => repo.importDocument(
          sourceFile: File(sourcePath),
          title: 'Vanishing',
          category: 'SK',
          documentDate: DateTime(2026, 10, 16),
          fiscalYear: 2026,
        ),
        throwsA(isA<FileSystemException>()),
      );

      final count = await db.countDocuments();
      expect(count, 0, reason: 'A failed copy must not insert a metadata row.');
      final managed = Directory(tempDir.path).listSync();
      expect(managed, isEmpty, reason: 'A failed copy must not leave a partial managed file.');
    });

    test('an import with a valid source persists both the managed file and the DB row', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final storage = LocalStorageService(customBasePath: tempDir.path);
      final repo = DriftDocumentRepository(db: db, storageService: storage);

      final source = File('${tempDir.path}/happy.pdf');
      await source.writeAsBytes([0x25, 0x50, 0x44, 0x46, 0x02]);

      final doc = await repo.importDocument(
        sourceFile: source,
        title: 'Laporan Tahunan',
        category: 'Laporan',
        documentDate: DateTime(2026, 10, 16),
        fiscalYear: 2026,
      );

      expect(File(doc.localFilePath).existsSync(), isTrue);
      expect(await db.countDocuments(), 1);
    });
  });

  group('Delete failure handling (current behaviour)', () {
    test('when the managed file cannot be removed, the DB row is still deleted today', () async {
      // KNOWN GAP: this is the P0 issue implementation_plan_feat.md
      // Phase 1.4 addresses with a local recycle bin. The test locks in
      // the current behaviour so Phase 1 flips it intentionally, not by
      // accident.
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final storage = LocalStorageService(customBasePath: tempDir.path);
      final repo = DriftDocumentRepository(db: db, storageService: storage);

      final source = File('${tempDir.path}/orphan.pdf');
      await source.writeAsBytes([0x25, 0x50, 0x44, 0x46, 0x03]);
      final doc = await repo.importDocument(
        sourceFile: source,
        title: 'Orphan Risk',
        category: 'SK',
        documentDate: DateTime(2026, 10, 16),
        fiscalYear: 2026,
      );

      // Remove the managed file from disk so deleteManagedFile returns
      // false (file.exists() fails first).
      await File(doc.localFilePath).delete();

      await repo.deleteDocument(doc.id);

      expect(await db.countDocuments(), 0,
          reason: 'Metadata deletion currently proceeds even when file removal failed.');
    });
  });

  group('Combined filter and sort composition', () {
    test('category + fiscalYear + syncStatus + searchQuery intersect on real rows', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final storage = LocalStorageService(customBasePath: tempDir.path);
      final DocumentRepository repo = DriftDocumentRepository(db: db, storageService: storage);

      Future<void> seed({
        required String id,
        required String title,
        required String category,
        required int year,
        required DocumentSyncStatus status,
      }) async {
        final source = File('${tempDir.path}/seed-$id.pdf');
        await source.writeAsBytes([0x25, 0x50, 0x44, 0x46, id.hashCode & 0xff]);
        final doc = await repo.importDocument(
          sourceFile: source,
          title: title,
          category: category,
          documentDate: DateTime(year, 1, 1),
          fiscalYear: year,
        );
        await repo.updateSyncStatus(id: doc.id, status: status);
      }

      await seed(id: 'a', title: 'Laporan 2025 SK', category: 'SK', year: 2025, status: DocumentSyncStatus.localOnly);
      await seed(id: 'b', title: 'Laporan 2026 SK', category: 'SK', year: 2026, status: DocumentSyncStatus.synced);
      await seed(id: 'c', title: 'Laporan 2026 Teknis', category: 'Teknis', year: 2026, status: DocumentSyncStatus.synced);

      final all = await repo.getAllDocuments();
      expect(all.length, 3);

      // Compose filters the same way documentsListStreamProvider does:
      // FTS first, then category/year/status on top of the match set.
      final ftsMatches = await repo.searchDocuments('Laporan');
      final ftsIds = ftsMatches.map((d) => d.id).toSet();
      final combined = all
          .where((d) => ftsIds.contains(d.id))
          .where((d) => d.category == 'SK')
          .where((d) => d.fiscalYear == 2026)
          .where((d) => d.syncStatus == DocumentSyncStatus.synced)
          .toList();

      expect(combined.length, 1);
      expect(combined.single.title, 'Laporan 2026 SK');

      // Sanity: with only the year filter, we get two SK entries and one
      // Teknis entry — proves the additional filters are narrowing
      // rather than accidentally excluding everything.
      final onlyYearFilter = all.where((d) => d.fiscalYear == 2026).toList();
      expect(onlyYearFilter.length, 2);
    });

    test('sort orders produce expected permutations on createdAt', () async {
      // Insert rows directly with explicit distinct createdAt values so
      // the assertion is not affected by Windows clock tick resolution
      // (three consecutive DateTime.now() calls can land on the same
      // 15ms tick via drift_document_repository.importDocument).
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      final base = DateTime.utc(2026, 10, 16, 10, 0, 0);
      Future<void> insert({
        required String id,
        required String title,
        required Duration offset,
      }) async {
        await db.upsertDocument(
          LocalDocumentsCompanion.insert(
            id: id,
            title: title,
            category: 'SK',
            documentDate: base,
            fiscalYear: 2026,
            localFilePath: '/tmp/sort-$id.pdf',
            fileName: 'sort-$id.pdf',
            fileSizeBytes: 10,
            mimeType: 'application/pdf',
            sha256Hash: 'b' * 64,
            createdAt: Value(base.add(offset)),
          ),
        );
      }

      await insert(id: 'doc-alpha', title: 'alpha', offset: Duration.zero);
      await insert(id: 'doc-beta', title: 'beta', offset: const Duration(minutes: 1));
      await insert(id: 'doc-gamma', title: 'gamma', offset: const Duration(minutes: 2));

      final rows = await (db.select(db.localDocuments)).get();

      final newestFirst = [...rows]..sort((a, b) {
        final c = b.createdAt.compareTo(a.createdAt);
        return c != 0 ? c : b.id.compareTo(a.id);
      });
      final oldestFirst = [...rows]..sort((a, b) {
        final c = a.createdAt.compareTo(b.createdAt);
        return c != 0 ? c : a.id.compareTo(b.id);
      });
      final titleAsc = [...rows]..sort((a, b) {
        final c = a.title.toLowerCase().compareTo(b.title.toLowerCase());
        return c != 0 ? c : a.id.compareTo(b.id);
      });

      expect(newestFirst.map((d) => d.title).toList(), ['gamma', 'beta', 'alpha']);
      expect(oldestFirst.map((d) => d.title).toList(), ['alpha', 'beta', 'gamma']);
      expect(titleAsc.map((d) => d.title).toList(), ['alpha', 'beta', 'gamma']);
    });
  });

  group('Large-text handling', () {
    test('a 5000-character extractedText is indexed and matched by FTS', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final storage = LocalStorageService(customBasePath: tempDir.path);
      final repo = DriftDocumentRepository(db: db, storageService: storage);

      final source = File('${tempDir.path}/big.pdf');
      await source.writeAsBytes([0x25, 0x50, 0x44, 0x46, 0x09]);

      final filler = List<String>.filled(500, 'kata-pekerja-administrasi').join(' ');
      expect(filler.length, greaterThan(5000));

      final doc = await repo.importDocument(
        sourceFile: source,
        title: 'Notula Panjang',
        category: 'Notula',
        documentDate: DateTime(2026, 10, 16),
        fiscalYear: 2026,
        extractedText: filler,
      );

      final matches = await repo.searchDocuments('administrasi');
      expect(matches.map((d) => d.id), contains(doc.id));
    });
  });
}

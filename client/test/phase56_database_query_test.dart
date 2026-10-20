import 'dart:io';

import 'package:document_management/core/database/app_database.dart';
import 'package:document_management/core/services/document_organization_repository.dart';
import 'package:document_management/core/services/storage_service.dart';
import 'package:document_management/features/documents/data/repositories/drift_document_repository.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

/// Phase 5.6 acceptance: filtering, ordering with a stable id tie-breaker,
/// and paging all happen in SQLite; counts and single-row selection reads
/// too. These replace the old full-library Dart materialization that froze
/// large libraries.
void main() {
  late Directory tempDir;
  late AppDatabase db;
  late DriftDocumentRepository repo;
  late DocumentOrganizationRepository org;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('p56_');
    db = AppDatabase(NativeDatabase.memory());
    repo = DriftDocumentRepository(
      db: db,
      storageService: LocalStorageService(customBasePath: tempDir.path),
    );
    org = DocumentOrganizationRepository(db);
  });

  tearDown(() async {
    await db.close();
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  Future<String> addDoc({
    required String title,
    String category = 'SK',
    int year = 2026,
    String status = 'local_only',
    DateTime? createdAt,
    bool favorite = false,
    String? extractedText,
  }) async {
    final id = const Uuid().v4();
    final when = createdAt ?? DateTime(2026, 1, 1);
    await db.upsertDocument(LocalDocumentsCompanion.insert(
      id: id,
      title: title,
      category: category,
      documentDate: when,
      fiscalYear: year,
      localFilePath: '${tempDir.path}/$id.bin',
      fileName: '$id.bin',
      fileSizeBytes: 1,
      mimeType: 'application/pdf',
      sha256Hash: id,
      syncStatus: Value(status),
      isFavorite: Value(favorite),
      extractedText: Value(extractedText),
      createdAt: Value(when),
      updatedAt: Value(when),
    ));
    return id;
  }

  group('watchDocumentPage', () {
    test('filters by category and status in the database', () async {
      await addDoc(title: 'SK Satu', category: 'SK');
      await addDoc(title: 'SK Dua', category: 'SK');
      await addDoc(title: 'Laporan Tiga', category: 'Laporan');
      await addDoc(title: 'Synced Four', category: 'SK', status: 'synced');

      final sk = await repo
          .watchDocumentPage(sortBy: 'newest', limit: 100, category: 'SK')
          .first;
      expect(sk.length, 3);
      expect(sk.every((d) => d.category == 'SK'), isTrue);

      final synced = await repo
          .watchDocumentPage(sortBy: 'newest', limit: 100, syncStatus: 'synced')
          .first;
      expect(synced.map((d) => d.title), ['Synced Four']);
    });

    test('orders newest vs oldest deterministically', () async {
      await addDoc(title: 'Older', createdAt: DateTime(2025, 1, 1));
      await addDoc(title: 'Newer', createdAt: DateTime(2026, 6, 1));
      await addDoc(title: 'Middle', createdAt: DateTime(2026, 3, 1));

      final newest = await repo
          .watchDocumentPage(sortBy: 'newest', limit: 100)
          .first;
      expect(newest.map((d) => d.title), ['Newer', 'Middle', 'Older']);

      final oldest =
          await repo.watchDocumentPage(sortBy: 'oldest', limit: 100).first;
      expect(oldest.map((d) => d.title), ['Older', 'Middle', 'Newer']);
    });

    test('title sort is case-insensitive', () async {
      await addDoc(title: 'banana');
      await addDoc(title: 'Apple');
      await addDoc(title: 'cherry');
      final byTitle =
          await repo.watchDocumentPage(sortBy: 'title', limit: 100).first;
      expect(byTitle.map((d) => d.title), ['Apple', 'banana', 'cherry']);
    });

    test('LIMIT/OFFSET pages without skipping or repeating', () async {
      final ids = <String>[];
      for (var i = 0; i < 7; i++) {
        // distinct timestamps keep the newest ordering unambiguous
        ids.add(await addDoc(
          title: 'Doc $i',
          createdAt: DateTime(2026, 1, 1).add(Duration(minutes: i)),
        ));
      }

      final page1 = await repo.watchDocumentPage(sortBy: 'newest', limit: 3).first;
      final page2 =
          await repo.watchDocumentPage(sortBy: 'newest', limit: 3, offset: 3).first;
      final page3 =
          await repo.watchDocumentPage(sortBy: 'newest', limit: 3, offset: 6).first;

      expect(page1.length, 3);
      expect(page2.length, 3);
      expect(page3.length, 1);

      final combined = <String>{
        ...page1.map((d) => d.id),
        ...page2.map((d) => d.id),
        ...page3.map((d) => d.id),
      };
      expect(combined.length, 7, reason: 'no duplicates across pages');
      // newest first: page1 holds the 3 most recent inserts
      expect(page1.first.id, ids.last);
    });

    test('filters by favorite', () async {
      await addDoc(title: 'Fav One', favorite: true);
      await addDoc(title: 'Fav Two', favorite: true);
      await addDoc(title: 'Plain');
      final favs = await repo
          .watchDocumentPage(sortBy: 'newest', limit: 100, favoriteOnly: true)
          .first;
      expect(favs.length, 2);
    });

    test('filters by tag name (EXISTS subquery, one row per doc)', () async {
      final a = await addDoc(title: 'Tagged A');
      final b = await addDoc(title: 'Tagged B');
      await addDoc(title: 'Untagged');
      await org.setTags(a, ['penting', 'arsip']);
      await org.setTags(b, ['penting']);

      final hasil = await repo
          .watchDocumentPage(sortBy: 'newest', limit: 100, tagName: 'penting')
          .first;
      expect(hasil.map((d) => d.id).toSet(), {a, b});
    });

    test('filters by collection', () async {
      final a = await addDoc(title: 'Col A');
      await addDoc(title: 'Col B');
      final col = await org.createCollection('Arsip 2026');
      await org.addToCollection(col.id, [a]);

      final inCol = await repo
          .watchDocumentPage(sortBy: 'newest', limit: 100, collectionId: col.id)
          .first;
      expect(inCol.map((d) => d.id), [a]);
    });

    test('searches via FTS and counts match', () async {
      await addDoc(title: 'Laporan Keuangan Daerah');
      await addDoc(title: 'Notula Rapat', extractedText: 'kegiatan infrastruktur desa');
      await addDoc(title: 'Surat Biasa');

      final hits = await repo
          .watchDocumentPage(sortBy: 'newest', limit: 100, search: 'Keuangan')
          .first;
      expect(hits.map((d) => d.title), ['Laporan Keuangan Daerah']);

      final count = await repo.watchDocumentCount(search: 'Keuangan').first;
      expect(count, 1);
    });

    test('excludes trashed rows', () async {
      final a = await addDoc(title: 'Active Doc');
      final b = await addDoc(title: 'To Trash');
      await repo.trashDocument(b);

      final page = await repo.watchDocumentPage(sortBy: 'newest', limit: 100).first;
      expect(page.map((d) => d.id), [a]);

      final count = await repo.watchDocumentCount().first;
      expect(count, 1);
    });
  });

  group('aggregates and single-row reads', () {
    test('category counts group active docs', () async {
      await addDoc(title: 'SK 1', category: 'SK');
      await addDoc(title: 'SK 2', category: 'SK');
      await addDoc(title: 'Lap 1', category: 'Laporan');
      final counts = await repo.watchCategoryCounts().first;
      expect(counts['SK'], 2);
      expect(counts['Laporan'], 1);
    });

    test('status summary tallies by status', () async {
      await addDoc(title: 'A', status: 'local_only');
      await addDoc(title: 'B', status: 'local_only');
      await addDoc(title: 'C', status: 'synced');
      await addDoc(title: 'D', status: 'error');
      final s = await repo.watchStatusSummary().first;
      expect(s.total, 4);
      expect(s.localOnly, 2);
      expect(s.synced, 1);
      expect(s.attention, 1);
    });

    test('empty library summary is all-zero, not null', () async {
      final s = await repo.watchStatusSummary().first;
      expect(s.total, 0);
      expect(s.attention, 0);
    });

    test('watchDocumentById resolves one row; null when purged', () async {
      final a = await addDoc(title: 'Detail A');
      final doc = await repo.watchDocumentById(a).first;
      expect(doc?.title, 'Detail A');

      await repo.deleteDocument(a);
      final gone = await repo.watchDocumentById(a).first;
      expect(gone, isNull);
    });

    test('watchDocumentsByIds excludes trashed and empty short-circuits',
        () async {
      final a = await addDoc(title: 'Sel A');
      final b = await addDoc(title: 'Sel B');
      await addDoc(title: 'Sel C');
      await repo.trashDocument(b);

      final selected = await repo.watchDocumentsByIds([a, b]).first;
      expect(selected.map((d) => d.id), [a]);

      final empty = await repo.watchDocumentsByIds(const <String>[]).first;
      expect(empty, isEmpty);
    });
  });
}

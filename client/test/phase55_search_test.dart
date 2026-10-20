import 'dart:io';

import 'package:document_management/core/database/app_database.dart';
import 'package:document_management/core/services/storage_service.dart';
import 'package:document_management/features/documents/data/repositories/drift_document_repository.dart';
import 'package:document_management/features/documents/domain/search_query.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

void main() {
  group('parseDocumentQuery (Phase 5.5 combination)', () {
    test('parses multiple prefixes and leftover words together', () {
      final q = parseDocumentQuery(
        'tahun:2026 kategori:SK nomor:001/X/2026 laporan tahunan',
      );
      expect(q.fiscalYear, 2026);
      expect(q.category, 'SK');
      expect(q.documentNumber, '001/X/2026');
      expect(q.text, 'laporan tahunan');
    });

    test('recognises tipe/berkas/tag and lowercases tag', () {
      final q = parseDocumentQuery(
        'tipe:application/pdf berkas:rapbd tag:Penting',
      );
      expect(q.mimeType, 'application/pdf');
      expect(q.fileName, 'rapbd');
      expect(q.tag, 'penting');
      expect(q.text, isEmpty);
    });

    test('date bounds are inclusive local-day millis', () {
      final q = parseDocumentQuery('dari:2026-01-01 ke:2026-01-31');
      expect(
        q.dateFromMillis,
        DateTime(2026, 1, 1).millisecondsSinceEpoch,
      );
      expect(
        q.dateToMillis,
        DateTime(2026, 1, 31)
                .add(const Duration(days: 1))
                .millisecondsSinceEpoch -
            1,
      );
    });

    test("'nama: is a back-compat text alias; unknown prefix stays a word", () {
      final q = parseDocumentQuery('nama:surat warna:merah');
      expect(q.text, 'surat warna:merah');
    });

    test('leading colon is treated as plain text', () {
      final q = parseDocumentQuery(':weird');
      expect(q.text, ':weird');
    });

    test('invalid year/date are ignored, not crashed', () {
      final q = parseDocumentQuery('tahun:abc dari:not-a-date');
      expect(q.fiscalYear, isNull);
      expect(q.dateFromMillis, isNull);
    });
  });

  group('DB facets (Phase 5.5)', () {
    late Directory tempDir;
    late AppDatabase db;
    late DriftDocumentRepository repo;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('p55_');
      db = AppDatabase(NativeDatabase.memory());
      repo = DriftDocumentRepository(
        db: db,
        storageService: LocalStorageService(customBasePath: tempDir.path),
      );
    });

    tearDown(() async {
      await db.close();
      if (tempDir.existsSync()) await tempDir.delete(recursive: true);
    });

    Future<String> addDoc({
      required String title,
      String? documentNumber,
      String mimeType = 'application/pdf',
      String? fileName,
      String? originalFileName,
      DateTime? documentDate,
    }) async {
      final id = const Uuid().v4();
      final when = documentDate ?? DateTime(2026, 1, 1);
      await db.upsertDocument(LocalDocumentsCompanion.insert(
        id: id,
        title: title,
        category: 'SK',
        documentDate: when,
        fiscalYear: 2026,
        localFilePath: '${tempDir.path}/$id.bin',
        fileName: fileName ?? '$id.bin',
        fileSizeBytes: 1,
        mimeType: mimeType,
        sha256Hash: id,
        documentNumber: Value(documentNumber),
        originalFileName: Value(originalFileName),
        createdAt: Value(when),
        updatedAt: Value(when),
      ));
      return id;
    }

    test('exact document number', () async {
      final a = await addDoc(title: 'A', documentNumber: 'SK/001/2026');
      await addDoc(title: 'B', documentNumber: 'SK/002/2026');
      final hits = await repo
          .watchDocumentPage(
            sortBy: 'newest',
            limit: 100,
            documentNumber: 'SK/001/2026',
          )
          .first;
      expect(hits.map((d) => d.id), [a]);
    });

    test('mime type facet', () async {
      final png = await addDoc(title: 'P', mimeType: 'image/png');
      await addDoc(title: 'Q', mimeType: 'application/pdf');
      final hits = await repo
          .watchDocumentPage(sortBy: 'newest', limit: 100, mimeType: 'image/png')
          .first;
      expect(hits.map((d) => d.id), [png]);
    });

    test('filename LIKE matches managed OR original name', () async {
      final a = await addDoc(
        title: 'A',
        fileName: '20261010_managed_abcd.pdf',
        originalFileName: 'surat_rapbd_asli.pdf',
      );
      await addDoc(title: 'B', fileName: '20261011_other.pdf');

      final byManaged = await repo
          .watchDocumentPage(sortBy: 'newest', limit: 100, fileNameLike: 'managed')
          .first;
      expect(byManaged.map((d) => d.id), [a]);

      final byOriginal = await repo
          .watchDocumentPage(sortBy: 'newest', limit: 100, fileNameLike: 'rapbd_asli')
          .first;
      expect(byOriginal.map((d) => d.id), [a],
          reason: 'original_file_name is searched too');
    });

    test('document-date range uses epoch millis', () async {
      final jan = await addDoc(
        title: 'Jan',
        documentDate: DateTime(2026, 1, 10),
      );
      final jun = await addDoc(
        title: 'Jun',
        documentDate: DateTime(2026, 6, 10),
      );

      final after = await repo
          .watchDocumentPage(
            sortBy: 'newest',
            limit: 100,
            dateFromMillis: DateTime(2026, 5, 1).millisecondsSinceEpoch,
          )
          .first;
      expect(after.map((d) => d.id), [jun]);

      final before = await repo
          .watchDocumentPage(
            sortBy: 'newest',
            limit: 100,
            dateToMillis: DateTime(2026, 2, 1).millisecondsSinceEpoch,
          )
          .first;
      expect(before.map((d) => d.id), [jan]);
    });

    test('facets combine with an FTS word', () async {
      final a = await addDoc(
        title: 'Laporan Keuangan Daerah',
        documentNumber: 'LK/2026/07',
        mimeType: 'application/pdf',
      );
      await addDoc(title: 'Laporan lainnya', documentNumber: 'LK/2026/08');

      final combined = await repo
          .watchDocumentPage(
            sortBy: 'newest',
            limit: 100,
            documentNumber: 'LK/2026/07',
            mimeType: 'application/pdf',
            search: 'Keuangan',
          )
          .first;
      expect(combined.map((d) => d.id), [a]);
    });
  });
}

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';

import 'package:document_management/core/utils/file_sanitizer.dart';
import 'package:document_management/core/utils/hash_util.dart';
import 'package:document_management/core/utils/mime_detector.dart';
import 'package:document_management/core/services/storage_service.dart';
import 'package:document_management/core/database/app_database.dart';
import 'package:document_management/features/documents/data/repositories/drift_document_repository.dart';
import 'package:document_management/features/documents/domain/models/document_item.dart';

void main() {
  group('Phase 1 - Utilities & Sanitization', () {
    test('FileSanitizer removes path traversal and illegal characters', () {
      final dirtyName = '../../../etc/passwd:secret*doc?.pdf';
      final clean = FileSanitizer.sanitizeFileName(dirtyName);
      expect(clean.contains('..'), isFalse);
      expect(clean.contains(':'), isFalse);
      expect(clean.contains('*'), isFalse);
      expect(clean.contains('?'), isFalse);
      expect(clean.contains('/'), isFalse);
    });

    test('FileSanitizer formats managed naming correctly', () {
      final date = DateTime(2026, 10, 13);
      final formatted = FileSanitizer.formatManagedFileName(
        date: date,
        title: 'SK Pengangkatan Pegawai/2026',
        uuid: 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
        originalExtension: '.pdf',
      );
      expect(formatted.startsWith('20261013_SK_Pengangkatan_Pegawai_2026_a1b2c3d4'), isTrue);
      expect(formatted.endsWith('.pdf'), isTrue);
    });

    test('MimeDetector detects true PDF and PNG magic headers', () {
      final pdfBytes = Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x35]);
      expect(MimeDetector.detectMimeType(pdfBytes), 'application/pdf');

      final pngBytes = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
      expect(MimeDetector.detectMimeType(pngBytes), 'image/png');
    });

    test('HashUtil calculates correct SHA-256', () {
      final bytes = Uint8List.fromList('hello-dms-world'.codeUnits);
      final hash = HashUtil.calculateBytesSha256(bytes);
      expect(hash.length, 64);
    });
  });

  group('Phase 1 - LocalStorageService & Drift with FTS5', () {
    late Directory tempDir;
    late LocalStorageService storageService;
    late AppDatabase database;
    late DriftDocumentRepository repository;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('dms_test_');
      storageService = LocalStorageService(customBasePath: tempDir.path);
      database = AppDatabase(NativeDatabase.memory());
      repository = DriftDocumentRepository(
        db: database,
        storageService: storageService,
      );
    });

    tearDown(() async {
      await database.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('Stores file locally and generates valid metadata and checksum', () async {
      final dummyFile = File('${tempDir.path}/test_source.pdf');
      // write mock PDF header
      await dummyFile.writeAsBytes([0x25, 0x50, 0x44, 0x46, 0x31, 0x32, 0x33]);

      final doc = await repository.importDocument(
        sourceFile: dummyFile,
        title: 'Laporan Keuangan Q3',
        documentNumber: '001/KEU/2026',
        category: 'Laporan',
        documentDate: DateTime(2026, 9, 30),
        fiscalYear: 2026,
        extractedText: 'Realisasi anggaran belanja daerah kuartal 3 tahun 2026 telah mencapai target',
      );

      expect(doc.id, isNotEmpty);
      expect(doc.syncStatus, DocumentSyncStatus.localOnly);
      expect(doc.mimeType, 'application/pdf');
      expect(File(doc.localFilePath).existsSync(), isTrue);
      expect(doc.sha256Hash.length, 64);
    });

    test('FTS5 virtual table full-text search indexes documents properly', () async {
      final file1 = File('${tempDir.path}/sk1.pdf');
      await file1.writeAsBytes([0x25, 0x50, 0x44, 0x46]);
      final file2 = File('${tempDir.path}/notula.pdf');
      await file2.writeAsBytes([0x25, 0x50, 0x44, 0x46]);

      await repository.importDocument(
        sourceFile: file1,
        title: 'SK Tim Reformasi Birokrasi',
        documentNumber: 'SK/2026/044',
        category: 'SK',
        documentDate: DateTime(2026, 1, 15),
        fiscalYear: 2026,
        extractedText: 'Menetapkan susunan panitia kerja reformasi birokrasi dan akuntabilitas kinerja',
      );

      await repository.importDocument(
        sourceFile: file2,
        title: 'Notula Rapat Koordinasi Anggaran',
        documentNumber: 'NOT/2026/012',
        category: 'Notula',
        documentDate: DateTime(2026, 2, 10),
        fiscalYear: 2026,
        extractedText: 'Pembahasan alokasi sarana prasarana teknologi informasi',
      );

      // Search keyword in title
      final searchTitle = await repository.searchDocuments('Reformasi');
      expect(searchTitle.length, 1);
      expect(searchTitle.first.title, 'SK Tim Reformasi Birokrasi');

      // Search keyword in extractedText
      final searchText = await repository.searchDocuments('akuntabilitas');
      expect(searchText.length, 1);
      expect(searchText.first.title, 'SK Tim Reformasi Birokrasi');

      // Search keyword in documentNumber
      final searchDocNum = await repository.searchDocuments('NOT/2026/012');
      expect(searchDocNum.length, 1);
      expect(searchDocNum.first.category, 'Notula');
    });

    test('Detects storage unmount or path unavailability', () async {
      expect(await storageService.isStorageAccessible(), isTrue);

      final unmountedService = LocalStorageService(customBasePath: 'Z:/non_existent_drive/sub');
      expect(await unmountedService.isStorageAccessible(), isFalse);
    });
  });
}

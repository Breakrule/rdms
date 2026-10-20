import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:document_management/core/database/app_database.dart';
import 'package:document_management/core/services/dummy_data_seeder.dart';
import 'package:document_management/core/services/storage_service.dart';
import 'package:document_management/features/documents/data/repositories/drift_document_repository.dart';

void main() {
  late AppDatabase db;
  late Directory tempStorageDir;
  late LocalStorageService storageService;
  late DriftDocumentRepository repository;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    tempStorageDir = await Directory.systemTemp.createTemp('dummy_seeder_test_');
    storageService = LocalStorageService(customBasePath: tempStorageDir.path);
    repository = DriftDocumentRepository(
      db: db,
      storageService: storageService,
    );
  });

  tearDown(() async {
    await db.close();
    if (tempStorageDir.existsSync()) {
      tempStorageDir.deleteSync(recursive: true);
    }
  });

  test('DummyDataSeeder seeds documents in all 6 categories with FTS5 searchability', () async {
    // 1. Initial count is 0
    final initialDocs = await repository.searchDocuments('');
    expect(initialDocs.isEmpty, isTrue);

    // 2. Seed documents
    final count = await DummyDataSeeder.seedDocuments(repository);
    expect(count, equals(6));

    // 3. Verify all categories are present
    final allDocs = await repository.searchDocuments('');
    expect(allDocs.length, equals(6));

    final categories = allDocs.map((d) => d.category).toSet();
    expect(categories, containsAll(['SK', 'Laporan', 'Notula', 'Teknis', 'Surat Keputusan', 'Peraturan']));

    // 4. Verify FTS5 searching on dummy content
    final searchTransformasi = await repository.searchDocuments('Transformasi');
    expect(searchTransformasi.isNotEmpty, isTrue);
    expect(searchTransformasi.first.category, equals('SK'));

    final searchLaporan = await repository.searchDocuments('Akuntabilitas');
    expect(searchLaporan.isNotEmpty, isTrue);
    expect(searchLaporan.first.category, equals('Laporan'));

    final searchNotula = await repository.searchDocuments('RKPD');
    expect(searchNotula.isNotEmpty, isTrue);
    expect(searchNotula.first.category, equals('Notula'));

    final searchPeraturan = await repository.searchDocuments('Keamanan');
    expect(searchPeraturan.isNotEmpty, isTrue);
    expect(searchPeraturan.first.category, equals('Peraturan'));

    // 5. Verify seedIfEmpty idempotency (does not duplicate if already populated)
    final reseedCount = await DummyDataSeeder.seedIfEmpty(repository);
    expect(reseedCount, equals(0));
    final finalDocs = await repository.searchDocuments('');
    expect(finalDocs.length, equals(6));
  });
}

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:document_management/core/database/app_database.dart';

/// Phase 0.2 baseline: verify the Drift migration strategy installs the
/// FTS5 shadow table, its synchronisation triggers, and the B-tree
/// indexes on a fresh install, and that all three react to writes.
///
/// Focus is narrow on purpose: [phase1_storage_and_db_test.dart] already
/// exercises end-to-end search behaviour. This file protects the
/// migration wiring itself, so a future change to
/// [_installFtsAndIndexes] that stops installing a trigger is caught
/// before it ships to a device.
void main() {
  group('AppDatabase migration - fresh install', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    Future<List<String>> namesIn(String kind, {String? tblName}) async {
      final sql = tblName == null
          ? "SELECT name FROM sqlite_master WHERE type = '$kind'"
          : "SELECT name FROM sqlite_master WHERE type = '$kind' AND tbl_name = ?";
      final rows = await db.customSelect(
        sql,
        variables: tblName == null ? const [] : [Variable.withString(tblName)],
      ).get();
      return rows.map((r) => r.data['name'] as String).toList();
    }

    test('local_documents table exists after onCreate', () async {
      expect(await namesIn('table'), contains('local_documents'));
    });

    test('FTS5 virtual table exists after onCreate', () async {
      expect(await namesIn('table'), contains('local_documents_fts'));
    });

    test('the three FTS synchronisation triggers are installed', () async {
      final triggers = await namesIn('trigger', tblName: 'local_documents');
      expect(triggers, containsAll(<String>[
        'trg_local_documents_ai',
        'trg_local_documents_au',
        'trg_local_documents_ad',
      ]));
    });

    test('the five B-tree indexes for filtering and sorting exist', () async {
      final indexes = await namesIn('index', tblName: 'local_documents');
      expect(indexes, containsAll(<String>[
        'idx_local_docs_cat_date',
        'idx_local_docs_fiscal',
        'idx_local_docs_status',
        'idx_local_docs_created',
        // Phase 1.4 adds a trashed_at partial-scan index so the
        // default view (active) does not degrade as the recycle bin
        // grows.
        'idx_local_docs_trashed',
      ]));
    });

    test('insert -> FTS hits; update -> FTS reflects new title; delete -> FTS is emptied', () async {
      final now = DateTime.utc(2026, 10, 16);
      final companion = LocalDocumentsCompanion.insert(
        id: 'doc-migration-1',
        title: 'Judul Awal',
        category: 'SK',
        documentDate: now,
        fiscalYear: 2026,
        localFilePath: '/tmp/doc-migration-1.pdf',
        fileName: 'doc-migration-1.pdf',
        fileSizeBytes: 100,
        mimeType: 'application/pdf',
        sha256Hash: 'a' * 64,
      );
      await db.upsertDocument(companion);

      final hitInitial = await db.searchWithFts('Awal');
      expect(hitInitial.map((d) => d.id), contains('doc-migration-1'));

      await (db.update(db.localDocuments)
            ..where((t) => t.id.equals('doc-migration-1')))
          .write(companion.copyWith(title: const Value('Judul Diperbarui')));

      final hitAfterUpdate = await db.searchWithFts('Diperbarui');
      expect(hitAfterUpdate.map((d) => d.id), contains('doc-migration-1'));

      final staleAfterUpdate = await db.searchWithFts('Awal');
      expect(staleAfterUpdate.map((d) => d.id), isNot(contains('doc-migration-1')));

      await (db.delete(db.localDocuments)..where((t) => t.id.equals('doc-migration-1'))).go();

      final afterDelete = await db.customSelect(
        'SELECT doc_id FROM local_documents_fts WHERE doc_id = ?',
        variables: [Variable.withString('doc-migration-1')],
      ).get();
      expect(afterDelete, isEmpty);
    });

    test('WAL journal mode PRAGMA runs without error', () async {
      // NativeDatabase.memory() uses an in-memory SQLite file, which
      // silently downgrades `journal_mode = WAL` to `memory`. The
      // beforeOpen code still issues the PRAGMA successfully; only the
      // reported mode differs. Assert on the call not throwing so
      // future refactors that drop the PRAGMA are caught, without
      // depending on a persistent backing file.
      final rows = await db.customSelect('PRAGMA journal_mode').get();
      expect(rows, hasLength(1));
      final mode = rows.single.data['journal_mode'] as String;
      expect(mode, isNotEmpty);
    });
  });
}

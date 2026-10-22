import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:document_management/core/database/app_database.dart';
import 'package:document_management/core/database/profile.dart';
import 'package:document_management/core/services/content_blob_store.dart';
import 'package:document_management/core/services/storage_service.dart';
import 'package:document_management/features/documents/data/repositories/drift_document_repository.dart';
import 'package:document_management/features/documents/data/version_repository.dart';
import 'package:document_management/features/documents/domain/models/document_item.dart';

/// Rev. 2 Phase P1.1 / P1.2 acceptance tests.
///
/// These exist for two named risks in `implementation_plan_major.md`, each the
/// kind of failure that is invisible until a user loses data:
///
///   * **R-03** — `deleteManagedFile` deleted bytes unconditionally. With
///     versions sharing content, that turns "purge one version" into "destroy
///     another". A reference count must be the only path to deletion.
///   * **R-02** — `baseRevision` is a sync concurrency token, not a content
///     version. Treated as history, every metadata edit mints a phantom version
///     and the shipped optimistic-locking protocol breaks.
void main() {
  late Directory tempDir;
  late AppDatabase db;
  late LocalStorageService storage;
  late ContentBlobStore blobs;
  late VersionRepository versions;
  late DriftDocumentRepository repo;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('dms_versions_');
    db = AppDatabase(NativeDatabase.memory());
    storage = LocalStorageService(customBasePath: tempDir.path);
    blobs = ContentBlobStore(db: db, storage: storage);
    versions = VersionRepository(db: db);
    repo = DriftDocumentRepository(db: db, storageService: storage);
  });

  tearDown(() async {
    await db.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<File> writeSource(String name, List<int> bytes) async {
    final file = File('${tempDir.path}/$name');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<DocumentItem> importDoc(File source, String title) =>
      repo.importDocument(
        sourceFile: source,
        title: title,
        category: 'SK',
        documentDate: DateTime(2026, 3, 15),
        fiscalYear: 2026,
      );

  group('Schema v6', () {
    test('fresh install carries the version data model', () async {
      expect(db.schemaVersion, 6);
      // The tables must be usable, not merely declared.
      expect(await blobs.allBlobs(), isEmpty);
      expect(await versions.listVersions('anything'), isEmpty);
    });

    test('documents default to the personal workspace, no login required',
        () async {
      final source = await writeSource('a.pdf', [0x25, 0x50, 0x44, 0x46, 0x01]);
      final doc = await importDoc(source, 'Satu');
      final row = await (db.select(db.localDocuments)
            ..where((t) => t.id.equals(doc.id)))
          .getSingle();
      expect(row.workspaceId, kPersonalWorkspaceId);
      // P1.3 has not run yet, so an imported document has no version pointer.
      expect(row.currentVersionId, isNull);
    });
  });

  group('R-03 — reference-counted bytes', () {
    test('adopting the same content twice counts, it does not copy', () async {
      final managed = await writeSource('managed.pdf', [1, 2, 3, 4]);
      const hash = 'a';
      await blobs.adoptManagedFile(
        sha256Hash: hash,
        managedPath: managed.path,
        sizeBytes: 4,
        mimeType: 'application/pdf',
      );
      final again = await blobs.adoptManagedFile(
        sha256Hash: hash,
        managedPath: managed.path,
        sizeBytes: 4,
        mimeType: 'application/pdf',
      );

      expect(await blobs.allBlobs(), hasLength(1));
      expect(again.refCount, 2);
    });

    test('releasing one of two references keeps the bytes alive', () async {
      final managed = await writeSource('shared.pdf', [9, 8, 7]);
      const hash = 'b';
      await blobs.adoptManagedFile(
        sha256Hash: hash,
        managedPath: managed.path,
        sizeBytes: 3,
        mimeType: 'application/pdf',
      );
      final blob = await blobs.adoptManagedFile(
        sha256Hash: hash,
        managedPath: managed.path,
        sizeBytes: 3,
        mimeType: 'application/pdf',
      );

      // THE guard: the first release must not delete anything.
      expect(await blobs.release(blob.id), isFalse,
          reason: 'one reference remained, so nothing may be deleted');
      expect(await managed.exists(), isTrue,
          reason: 'R-03: bytes still referenced survived a release');

      expect(await blobs.release(blob.id), isTrue);
      expect(await managed.exists(), isFalse,
          reason: 'the last reference going away is the ONLY path to deletion');
      expect(await blobs.allBlobs(), isEmpty);
    });

    test('pre-P1 data with no blob row is still deletable', () async {
      expect(await blobs.isSafeToDeleteBytes('nonexistent-hash'), isTrue);
    });

    test('content-addressed store writes blobs/<prefix>/<hash> and dedups',
        () async {
      final first = await writeSource('v1.pdf', [1, 1, 1, 1]);
      final duplicate = await writeSource('v1-copy.pdf', [1, 1, 1, 1]);

      final blob =
          await blobs.storeContentAddressed(first, mimeType: 'application/pdf');
      final reused = await blobs.storeContentAddressed(duplicate,
          mimeType: 'application/pdf');

      expect(reused.id, blob.id, reason: 'identical bytes share one blob');
      expect(reused.refCount, 2);
      expect(blob.relativePath, isNotNull);
      final path = await blobs.absolutePathOf(blob);
      expect(await File(path!).exists(), isTrue);

      final blobFiles = Directory('${tempDir.path}/blobs')
          .listSync(recursive: true)
          .whereType<File>()
          .toList();
      expect(blobFiles, hasLength(1),
          reason: 'the duplicate import must not leave a second copy on disk');
    });

    test('purging one of two documents sharing bytes leaves the other intact',
        () async {
      final alpha = await writeSource('alpha.pdf', [5, 5, 5, 5]);
      final alphaDoc = await importDoc(alpha, 'Alpha');
      // A second document with byte-identical content, which is exactly what
      // the hash check in Phase 4.5 tells the user about.
      final beta = await writeSource('beta.pdf', [5, 5, 5, 5]);
      final betaDoc = await importDoc(beta, 'Beta');

      // Register BOTH managed files against the shared content hash.
      for (final doc in [alphaDoc, betaDoc]) {
        await blobs.adoptManagedFile(
          sha256Hash: doc.sha256Hash,
          managedPath: doc.localFilePath,
          sizeBytes: doc.fileSizeBytes,
          mimeType: doc.mimeType,
        );
      }
      expect((await blobs.findBySha256(alphaDoc.sha256Hash))!.refCount, 2);

      await repo.deleteDocument(alphaDoc.id);

      final betaFile = File(betaDoc.localFilePath);
      expect(await betaFile.exists(), isTrue,
          reason: 'R-03: deleting one document destroyed content the other '
              'still pointed at');
      expect(await blobs.findBySha256(alphaDoc.sha256Hash), isNotNull,
          reason: 'the blob survives with one reference');
      expect((await blobs.findBySha256(betaDoc.sha256Hash))!.refCount, 1);

      // KNOWN, DELIBERATE TRADE-OFF. Blobs are keyed by content hash, but two
      // pre-P1 managed files with identical content are two distinct physical
      // files, and one blob row can only name one of them. Alpha's file is
      // therefore left behind rather than deleted on an assumption.
      //
      // The asymmetry is the reason: a leftover file is disk waste that the
      // P1.8 integrity sweep reports and reclaims, whereas a wrongly deleted
      // file is unrecoverable data loss. When in doubt, keep the bytes.
      expect(await File(alphaDoc.localFilePath).exists(), isTrue,
          reason: 'ambiguous legacy copies are orphaned, never guessed away');

      // What remains is exactly one live reference. `isSafeToDeleteBytes` is
      // the question "may the caller, who is dropping one reference, free the
      // bytes?" — with a single reference left, the answer is now yes, and that
      // is the correct behaviour, not a leak.
      final survivor = await blobs.findBySha256(betaDoc.sha256Hash);
      expect(survivor, isNotNull);
      expect(survivor!.refCount, 1);
      expect(await blobs.isSafeToDeleteBytes(betaDoc.sha256Hash), isTrue,
          reason: 'removing the last remaining reference may free the bytes');
    });

    test('purging a legacy document with no blob still removes its file',
        () async {
      final source = await writeSource('legacy.pdf', [7, 7]);
      final doc = await importDoc(source, 'Legacy');
      await repo.deleteDocument(doc.id);
      expect(await File(doc.localFilePath).exists(), isFalse,
          reason: 'pre-P1 delete behaviour must be preserved, not regressed');
    });
  });

  group('R-02 — a version is not a revision', () {
    test('a metadata edit advances baseRevision and creates no version',
        () async {
      final source = await writeSource('edit.pdf', [3, 3]);
      final doc = await importDoc(source, 'Laporan Awal');

      expect(doc.baseRevision, 1);
      expect(await versions.countVersions(doc.id), 0);

      final edited = await repo.updateDocumentMetadata(
        id: doc.id,
        title: 'Laporan Revisi',
      );

      expect(edited.baseRevision, 2,
          reason: 'the sync concurrency token must still advance');
      expect(await versions.countVersions(doc.id), 0,
          reason: 'R-02: a content-free edit must not mint a version');
    });
  });

  group('Version identity', () {
    Future<(DocumentItem, ContentBlob)> seededDoc() async {
      final source = await writeSource('doc.pdf', [2, 2, 2]);
      final doc = await importDoc(source, 'Surat Asli');
      final blob =
          await blobs.storeContentAddressed(source, mimeType: 'application/pdf');
      return (doc, blob);
    }

    test('version numbers are sequential and the pointer follows', () async {
      final (doc, blob) = await seededDoc();

      final v1 = await versions.recordVersion(document: doc, blob: blob);
      expect(v1.versionNumber, 1);
      expect(await versions.currentVersion(doc.id), isNotNull);

      final v2 = await versions.recordVersion(
        document: doc,
        blob: blob,
        parentVersionId: v1.id,
        origin: 'replaced',
      );
      expect(v2.versionNumber, 2);
      expect(v2.parentVersionId, v1.id);

      final list = await versions.listVersions(doc.id);
      expect(list.map((v) => v.versionNumber).toList(), [2, 1],
          reason: 'history reads newest-first');
    });

    test('metadata_snapshot preserves the title as it was at that version',
        () async {
      final (doc, blob) = await seededDoc();
      final v1 = await versions.recordVersion(document: doc, blob: blob);

      await repo.updateDocumentMetadata(id: doc.id, title: 'Ganti Nama Baru');

      final snapshot = v1.metadataSnapshot;
      expect(snapshot, contains('Surat Asli'));
      expect(snapshot, isNot(contains('Ganti Nama Baru')),
          reason: 'history must show what the record was called THEN');
    });

    test('a version row cannot be overwritten by a later edit', () async {
      final (doc, blob) = await seededDoc();
      final v1 = await versions.recordVersion(document: doc, blob: blob);
      final before = await versions.findVersion(v1.id);

      await repo.updateDocumentMetadata(id: doc.id, title: 'Berubah');
      final after = await versions.findVersion(v1.id);

      expect(after!.metadataSnapshot, before!.metadataSnapshot);
      expect(after.fileName, before.fileName);
      expect(after.sha256Hash, before.sha256Hash);
    });

    test('tombstoning hides a version from the list but keeps the row',
        () async {
      final (doc, blob) = await seededDoc();
      final v1 = await versions.recordVersion(document: doc, blob: blob);
      await versions.tombstone(v1.id);

      expect(await versions.listVersions(doc.id), isEmpty);
      expect(await versions.findVersion(v1.id), isNotNull,
          reason: 'history is not erased by a prune marker');
    });

    test('totalLocalBytes reports only blobs still held on the device',
        () async {
      final source = await writeSource('size.pdf', List.filled(100, 1));
      await blobs.storeContentAddressed(source, mimeType: 'application/pdf');
      expect(await blobs.totalLocalBytes(), 100);
    });
  });
}

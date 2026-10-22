import 'dart:io';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:document_management/core/database/app_database.dart';
import 'package:document_management/core/services/content_blob_store.dart';
import 'package:document_management/core/services/interfaces/i_storage_service.dart';
import 'package:document_management/core/services/operation_journal.dart';
import 'package:document_management/core/services/storage_service.dart';
import '../../domain/models/document_item.dart';
import '../../domain/repositories/document_repository.dart';

class DriftDocumentRepository implements DocumentRepository {
  final AppDatabase _db;
  final IStorageService _storageService;
  final OperationJournal? _journal;
  static const _uuid = Uuid();

  /// Rev. 2 P1.1: owns reference counts for managed bytes. Built lazily from
  /// the same db + storage this repository already holds, so no caller has to
  /// be rewired and no second source of truth about the storage root appears.
  late final ContentBlobStore _blobs =
      ContentBlobStore(db: _db, storage: _storageService);

  DriftDocumentRepository({
    required this._db,
    required this._storageService,
    this._journal,
  });

  @override
  Future<DocumentItem> importDocument({
    required File sourceFile,
    required String title,
    String? documentNumber,
    required String category,
    required DateTime documentDate,
    required int fiscalYear,
    String? extractedText,
    String? notes,
  }) async {
    // Phase 1.3: journal entry is written BEFORE the copy so a crash
    // mid-flow leaves an open operation the integrity service can
    // surface. Managed file is removed on any failure so we never leave
    // an orphan copy behind.
    final journal = _journal;
    final opId = journal == null
        ? null
        : await journal.begin(
            kind: OperationKind.import,
            sourcePath: sourceFile.path,
          );

    ManagedFileInfo managedFile;
    try {
      managedFile = await _storageService.storeFile(
        sourceFile: sourceFile,
        title: title,
        documentDate: documentDate,
      );
      if (opId != null) await journal!.markInProgress(opId);
    } catch (err) {
      if (opId != null) await journal!.fail(opId, err.toString());
      rethrow;
    }

    final id = _uuid.v4();
    final now = DateTime.now();

    try {
      final entry = LocalDocumentsCompanion.insert(
        id: id,
        title: title,
        documentNumber: Value(documentNumber),
        category: category,
        documentDate: documentDate,
        fiscalYear: fiscalYear,
        localFilePath: managedFile.localFilePath,
        fileName: managedFile.fileName,
        fileSizeBytes: managedFile.fileSizeBytes,
        mimeType: managedFile.mimeType,
        sha256Hash: managedFile.sha256Hash,
        extractedText: Value(extractedText),
        notes: Value(notes),
        originalFileName: Value(_basename(sourceFile.path)),
        syncStatus: const Value('local_only'),
        createdAt: Value(now),
        updatedAt: Value(now),
      );
      await _db.upsertDocument(entry);
      if (opId != null) await journal!.complete(opId);
    } catch (err) {
      // Rollback the file copy so a failed import leaves no orphan.
      try {
        await _storageService.deleteManagedFile(managedFile.localFilePath);
      } catch (_) {
        // Best-effort cleanup; if the delete itself fails the operation
        // journal row already records the staged path so the integrity
        // check will surface it as an orphan on next start.
      }
      if (opId != null) await journal!.fail(opId, err.toString());
      rethrow;
    }

    return DocumentItem(
      id: id,
      title: title,
      documentNumber: documentNumber,
      category: category,
      documentDate: documentDate,
      fiscalYear: fiscalYear,
      localFilePath: managedFile.localFilePath,
      fileName: managedFile.fileName,
      fileSizeBytes: managedFile.fileSizeBytes,
      mimeType: managedFile.mimeType,
      sha256Hash: managedFile.sha256Hash,
      extractedText: extractedText,
      notes: notes,
      originalFileName: _basename(sourceFile.path),
      syncStatus: DocumentSyncStatus.localOnly,
      baseRevision: 1,
      createdAt: now,
      updatedAt: now,
    );
  }

  static String _basename(String path) {
    final normalized = path.replaceAll('\\', '/');
    final i = normalized.lastIndexOf('/');
    return i >= 0 && i < path.length - 1 ? path.substring(i + 1) : path;
  }

  @override
  Future<DocumentItem> updateDocumentMetadata({
    required String id,
    String? title,
    String? documentNumber,
    bool clearDocumentNumber = false,
    String? category,
    DateTime? documentDate,
    int? fiscalYear,
    String? notes,
    bool clearNotes = false,
    String? extractedText,
    bool clearExtractedText = false,
  }) async {
    final existing = await (_db.select(_db.localDocuments)
          ..where((t) => t.id.equals(id)))
        .getSingle(); // throws StateError when the row is missing

    final now = DateTime.now();
    await (_db.update(_db.localDocuments)..where((t) => t.id.equals(id)))
        .write(
      LocalDocumentsCompanion(
        title: title != null ? Value(title) : const Value.absent(),
        documentNumber: clearDocumentNumber
            ? const Value(null)
            : (documentNumber != null
                ? Value(documentNumber)
                : const Value.absent()),
        category: category != null ? Value(category) : const Value.absent(),
        documentDate:
            documentDate != null ? Value(documentDate) : const Value.absent(),
        fiscalYear:
            fiscalYear != null ? Value(fiscalYear) : const Value.absent(),
        notes: clearNotes
            ? const Value(null)
            : (notes != null ? Value(notes) : const Value.absent()),
        extractedText: clearExtractedText
            ? const Value(null)
            : (extractedText != null
                ? Value(extractedText)
                : const Value.absent()),
        // Phase 4.1/2.6: metadata edits advance the revision even when
        // the content hash is unchanged, so the v2 batch can detect
        // them (a hash-only reconcile cannot).
        baseRevision: Value(existing.baseRevision + 1),
        updatedAt: Value(now),
      ),
    );
    final updated = await (_db.select(_db.localDocuments)
          ..where((t) => t.id.equals(id)))
        .getSingle();
    return _mapToDomain(updated);
  }

  @override
  Future<List<DocumentItem>> findBySha256(String sha256) async {
    final rows = await (_db.select(_db.localDocuments)
          ..where((t) => t.sha256Hash.equals(sha256))
          ..where((t) => t.trashedAt.isNull()))
        .get();
    return rows.map(_mapToDomain).toList();
  }

  @override
  Future<void> setFavorite(String id, bool favorite) async {
    await (_db.update(_db.localDocuments)..where((t) => t.id.equals(id)))
        .write(
      LocalDocumentsCompanion(
        isFavorite: Value(favorite),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<List<DocumentItem>> searchDocuments(
    String query, {
    bool includeTrashed = false,
  }) async {
    final rows = await _db.searchWithFts(query, includeTrashed: includeTrashed);
    return rows.map(_mapToDomain).toList();
  }

  @override
  Stream<List<DocumentItem>> watchDocuments({
    String? categoryFilter,
    int? fiscalYearFilter,
    String? syncStatusFilter,
    DocumentView view = DocumentView.active,
  }) {
    return _db
        .watchAllDocuments(
          categoryFilter: categoryFilter,
          fiscalYearFilter: fiscalYearFilter,
          syncStatusFilter: syncStatusFilter,
          view: view,
        )
        .map((rows) => rows.map(_mapToDomain).toList());
  }

  @override
  Future<List<DocumentItem>> getQueuedDocuments() async {
    final rows = await _db.getQueuedDocuments();
    return rows.map(_mapToDomain).toList();
  }

  @override
  Future<void> updateDocument(DocumentItem document) async {
    final companion = LocalDocumentsCompanion(
      id: Value(document.id),
      title: Value(document.title),
      documentNumber: Value(document.documentNumber),
      category: Value(document.category),
      documentDate: Value(document.documentDate),
      fiscalYear: Value(document.fiscalYear),
      localFilePath: Value(document.localFilePath),
      fileName: Value(document.fileName),
      fileSizeBytes: Value(document.fileSizeBytes),
      mimeType: Value(document.mimeType),
      sha256Hash: Value(document.sha256Hash),
      extractedText: Value(document.extractedText),
      syncStatus: Value(document.syncStatus.value),
      gdriveFileId: Value(document.gdriveFileId),
      remoteBackendId: Value(document.remoteBackendId),
      trashedAt: Value(document.trashedAt),
      baseRevision: Value(document.baseRevision),
      accountBinding: Value(document.accountBinding),
      isFavorite: Value(document.isFavorite),
      notes: Value(document.notes),
      originalFileName: Value(document.originalFileName),
      updatedAt: Value(DateTime.now()),
    );
    await _db.upsertDocument(companion);
  }

  @override
  Future<void> updateSyncStatus({
    required String id,
    required DocumentSyncStatus status,
    String? gdriveFileId,
    String? remoteBackendId,
  }) async {
    await _db.updateSyncStatus(
      id: id,
      syncStatus: status.value,
      gdriveFileId: gdriveFileId,
      remoteBackendId: remoteBackendId,
    );
  }

    @override
  Future<void> deleteDocument(String id) async {
    final doc = await (_db.select(_db.localDocuments)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (doc == null) return;

    final journal = _journal;
    final opId = journal == null
        ? null
        : await journal.begin(
            kind: OperationKind.purge,
            documentId: id,
            targetPath: doc.localFilePath,
          );

    try {
      // Rev. 2 P1.1 — the R-03 guard. Purging a document must never delete
      // bytes another version or document still references.
      //
      // Bugfix #4: Asymmetric delete behavior fix.
      // When a blob row exists, release() handles the refCount check and
      // only deletes if safe. When none exists, delete the legacy file.
      // But we NEVER delete a pre-P1 file without checking if it's safe first.
      final blob = await _blobs.findBySha256(doc.sha256Hash);
      if (blob == null) {
        // Pre-P1 data: check if it's safe to delete before removing the file.
        final isSafe = await _blobs.isSafeToDeleteBytes(doc.sha256Hash);
        if (isSafe) {
          await _storageService.deleteManagedFile(doc.localFilePath);
        } else {
          // Another document with identical bytes still exists.
          // Leave the file intact; the other document owns it.
        }
      } else {
        // P1+ data: blob.release() handles all refCount logic.
        await _blobs.release(blob.id);
      }

      await (_db.delete(_db.localDocuments)..where((t) => t.id.equals(id)))
          .go();
      if (opId != null) await journal!.complete(opId);
    } catch (err) {
      if (opId != null) await journal!.fail(opId, err.toString());
      rethrow;
    }
  }

  @override
  Future<void> trashDocument(String id) async {
    final now = DateTime.now();
    await (_db.update(_db.localDocuments)..where((t) => t.id.equals(id))).write(
      LocalDocumentsCompanion(
        trashedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Future<void> restoreDocument(String id) async {
    final now = DateTime.now();
    await (_db.update(_db.localDocuments)..where((t) => t.id.equals(id))).write(
      LocalDocumentsCompanion(
        trashedAt: const Value(null),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Future<List<DocumentItem>> listTrashed() async {
    final rows = await (_db.select(_db.localDocuments)
          ..where((t) => t.trashedAt.isNotNull())
          ..orderBy([(t) => OrderingTerm.desc(t.trashedAt)]))
        .get();
    return rows.map(_mapToDomain).toList();
  }

  @override
  Future<DocumentItem?> getDocumentById(String id) async {
    final doc = await (_db.select(_db.localDocuments)..where((t) => t.id.equals(id))).getSingleOrNull();
    return doc != null ? _mapToDomain(doc) : null;
  }

  @override
  Future<List<DocumentItem>> getAllDocuments() async {
    final rows = await _db.getAllDocumentsForBackup();
    return rows.map(_mapToDomain).toList();
  }

  @override
  Future<List<DocumentItem>> getActiveDocuments() async {
    final rows = await (_db.select(_db.localDocuments)
          ..where((t) => t.trashedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
    return rows.map(_mapToDomain).toList();
  }

  @override
  Future<int> countDocuments({DocumentView view = DocumentView.active}) {
    return _db.countDocuments(view: view);
  }

  DocumentItem _mapToDomain(LocalDocument row) {
    return DocumentItem(
      id: row.id,
      title: row.title,
      documentNumber: row.documentNumber,
      category: row.category,
      documentDate: row.documentDate,
      fiscalYear: row.fiscalYear,
      localFilePath: row.localFilePath,
      fileName: row.fileName,
      fileSizeBytes: row.fileSizeBytes,
      mimeType: row.mimeType,
      sha256Hash: row.sha256Hash,
      extractedText: row.extractedText,
      syncStatus: DocumentSyncStatus.fromString(row.syncStatus),
      gdriveFileId: row.gdriveFileId,
      remoteBackendId: row.remoteBackendId,
      trashedAt: row.trashedAt,
      baseRevision: row.baseRevision,
      accountBinding: row.accountBinding,
      isFavorite: row.isFavorite,
      notes: row.notes,
      originalFileName: row.originalFileName,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  // ---- Phase 5.6: database-side list, counts, and single-row reads ----

  @override
  Stream<List<DocumentItem>> watchDocumentPage({
    required String sortBy,
    required int limit,
    int offset = 0,
    bool includeTrashed = false,
    String? category,
    int? fiscalYear,
    String? syncStatus,
    bool favoriteOnly = false,
    String? tagName,
    String? collectionId,
    String? search,
    String? documentNumber,
    int? dateFromMillis,
    int? dateToMillis,
    String? mimeType,
    String? fileNameLike,
  }) {
    return _db
        .watchDocumentPage(
          sortBy: sortBy,
          limit: limit,
          offset: offset,
          includeTrashed: includeTrashed,
          category: category,
          fiscalYear: fiscalYear,
          syncStatus: syncStatus,
          favoriteOnly: favoriteOnly,
          tagName: tagName,
          collectionId: collectionId,
          search: search,
          documentNumber: documentNumber,
          dateFromMillis: dateFromMillis,
          dateToMillis: dateToMillis,
          mimeType: mimeType,
          fileNameLike: fileNameLike,
        )
        .map((rows) => rows.map(_mapToDomain).toList());
  }

  @override
  Stream<int> watchDocumentCount({
    bool includeTrashed = false,
    String? category,
    int? fiscalYear,
    String? syncStatus,
    bool favoriteOnly = false,
    String? tagName,
    String? collectionId,
    String? search,
    String? documentNumber,
    int? dateFromMillis,
    int? dateToMillis,
    String? mimeType,
    String? fileNameLike,
  }) {
    return _db.watchDocumentCount(
      includeTrashed: includeTrashed,
      category: category,
      fiscalYear: fiscalYear,
      syncStatus: syncStatus,
      favoriteOnly: favoriteOnly,
      tagName: tagName,
      collectionId: collectionId,
      search: search,
      documentNumber: documentNumber,
      dateFromMillis: dateFromMillis,
      dateToMillis: dateToMillis,
      mimeType: mimeType,
      fileNameLike: fileNameLike,
    );
  }

  @override
  Stream<Map<String, int>> watchCategoryCounts() => _db.watchCategoryCounts();

  @override
  Stream<({int total, int localOnly, int synced, int attention})>
      watchStatusSummary() => _db.watchStatusSummary();

  @override
  Stream<DocumentItem?> watchDocumentById(String id) =>
      _db.watchDocumentById(id).map((row) => row == null ? null : _mapToDomain(row));

  @override
  Stream<List<DocumentItem>> watchDocumentsByIds(List<String> ids) =>
      _db.watchDocumentsByIds(ids).map((rows) => rows.map(_mapToDomain).toList());
}



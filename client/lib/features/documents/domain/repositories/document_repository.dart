import 'dart:io';
import '../../../../core/database/app_database.dart' show DocumentView;
import '../models/document_item.dart';

abstract class DocumentRepository {
  /// Import and index new file from disk.
  ///
  /// Phase 1.3 contract: if the metadata write fails, the managed file
  /// copy is rolled back so a failed import cannot orphan a file in the
  /// storage root. If the process crashes *between* the copy and the DB
  /// write, the operation-journal entry surfaces on next start via
  /// LibraryIntegrityService so the user can clean up.
  Future<DocumentItem> importDocument({
    required File sourceFile,
    required String title,
    String? documentNumber,
    required String category,
    required DateTime documentDate,
    required int fiscalYear,
    String? extractedText,
    String? notes,
  });

  /// Phase 4.1 metadata edit. Advances [DocumentItem.baseRevision] so
  /// the v2 batch endpoint can detect conflicts, persists the change
  /// atomically, and returns the updated item. It does NOT enqueue
  /// anything itself: the caller decides whether a metadata-only sync
  /// job is warranted (via SyncQueueService.enqueueMetadataOnly), and
  /// no Drive job is ever created from this path — editing metadata
  /// must not re-upload the binary.
  ///
  /// Nullable fields ([documentNumber], [notes], [extractedText]) use
  /// explicit clear flags so "leave unchanged" is distinguishable from
  /// "clear to null".
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
  });

  /// Phase 4.5 duplicate detection: existing NON-trashed documents
  /// whose content hash equals [sha256] (same bytes may legitimately
  /// belong to different records, so callers choose per case).
  Future<List<DocumentItem>> findBySha256(String sha256);

  /// Search documents with full-text search (FTS5).
  /// [includeTrashed] defaults to false; pass true to search the local
  /// recycle bin too.
  Future<List<DocumentItem>> searchDocuments(
    String query, {
    bool includeTrashed = false,
  });

  /// Watch live stream of documents with optional filtering.
  /// [view] defaults to [DocumentView.active] so browsing excludes
  /// recycled rows.
  Stream<List<DocumentItem>> watchDocuments({
    String? categoryFilter,
    int? fiscalYearFilter,
    String? syncStatusFilter,
    DocumentView view = DocumentView.active,
  });

  /// Retrieve documents currently queued for synchronization.
  /// Trashed rows are excluded.
  Future<List<DocumentItem>> getQueuedDocuments();

  /// Update document record
  Future<void> updateDocument(DocumentItem document);

  /// Update sync state
  Future<void> updateSyncStatus({
    required String id,
    required DocumentSyncStatus status,
    String? gdriveFileId,
    String? remoteBackendId,
  });

  /// Hard delete: removes the metadata row AND the managed file. Kept
  /// for Phase 1's "purge from recycle bin" path and for callers that
  /// intentionally want permanent removal. Ordinary "delete" from the
  /// UI now routes through [trashDocument].
  Future<void> deleteDocument(String id);

  /// Soft delete: marks the row as trashed. The managed file stays on
  /// disk so [restoreDocument] can bring the row back without touching
  /// binaries or the Drive ID.
  Future<void> trashDocument(String id);

  /// Clears the trash marker. IDs, Drive linkage, and file paths remain
  /// stable (Phase 1.4 acceptance criterion).
  Future<void> restoreDocument(String id);

  /// Lists every currently trashed row, newest trash time first.
  Future<List<DocumentItem>> listTrashed();

  /// Get document by ID
  Future<DocumentItem?> getDocumentById(String id);

  /// Retrieve all documents in database, including trashed rows. Used
  /// by backup export. Prefer [getActiveDocuments] for user-facing
  /// flows.
  Future<List<DocumentItem>> getAllDocuments();

  /// Retrieve every non-trashed document.
  Future<List<DocumentItem>> getActiveDocuments();

  /// Get total count of documents in database. [view] controls trashed
  /// visibility; default is active-only so the summary and category
  /// counts stop silently including recycled rows.
  Future<int> countDocuments({DocumentView view = DocumentView.active});

  /// Phase 4.3 favorite toggle (device-local; never synced).
  Future<void> setFavorite(String id, bool favorite);

  // ---- Phase 5.6: database-side list, counts, and single-row reads ----
  //
  // These replace the old pattern of materializing the entire library on
  // the main isolate and filtering/sorting it in Dart. Filtering, ordering
  // with a stable id tie-breaker, and paging all happen in SQLite.

  /// One page of documents matching the filter, ordered by [sortBy]
  /// ('newest' | 'oldest' | 'title' | 'docDate'), LIMIT/OFFSET applied in
  /// SQL. The list provider watches this directly.
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
  });

  /// Total number of documents matching the same filter, for paging and
  /// the empty-state distinction (library empty vs filter yields nothing).
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
  });

  /// Active-document counts grouped by category code (sidebar).
  Stream<Map<String, int>> watchCategoryCounts();

  /// Summary tallies computed in the database (total/localOnly/synced/
  /// attention), never by scanning every row in Dart.
  Stream<({int total, int localOnly, int synced, int attention})>
      watchStatusSummary();

  /// Watch a single document by id (detail panel), so opening a record
  /// does not depend on the full library stream.
  Stream<DocumentItem?> watchDocumentById(String id);

  /// Watch the live rows for a set of selected ids, in stable order.
  Stream<List<DocumentItem>> watchDocumentsByIds(List<String> ids);
}

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../domain/models/document_item.dart';

/// Creates and reads immutable content versions (Rev. 2 Phase P1.2).
///
/// Deliberately separate from `DriftDocumentRepository`: document identity and
/// version identity are different responsibilities, and keeping them apart is
/// what makes the R-02 guarantee testable — a metadata edit must advance
/// `baseRevision` without ever producing a version row.
///
/// Version numbers are allocated inside the write transaction so two callers
/// racing cannot both claim the same number; the `(document_id,
/// version_number)` unique key is the backstop, not the mechanism.
class VersionRepository {
  final AppDatabase _db;

  VersionRepository({required this._db});

  static const _uuid = Uuid();

  /// Appends the next version for [document] and points the document at it.
  ///
  /// [origin] is an enumerated reason — `import`, `replaced`, `restored`,
  /// `external_modification` — never free text, so the history screen can label
  /// an entry without rendering anything user-authored.
  Future<DocumentVersion> recordVersion({
    required DocumentItem document,
    required ContentBlob blob,
    String? parentVersionId,
    String? changeNote,
    String origin = 'import',
    String? providerVersionRef,
    String? createdByDevice,
  }) async {
    return _db.transaction(() async {
      final next = await _nextVersionNumber(document.id);
      final now = DateTime.now();
      final id = _uuid.v4();

      await _db.into(_db.documentVersions).insert(
            DocumentVersionsCompanion.insert(
              id: id,
              documentId: document.id,
              versionNumber: next,
              parentVersionId: Value(parentVersionId),
              sha256Hash: blob.sha256Hash,
              blobId: blob.id,
              fileName: document.fileName,
              originalFileName: Value(document.originalFileName),
              fileSizeBytes: document.fileSizeBytes,
              mimeType: document.mimeType,
              metadataSnapshot: jsonEncode(_snapshotOf(document)),
              originBackend: const Value('local'),
              providerVersionRef: Value(providerVersionRef),
              localAvailable: Value(blob.localAvailable),
              localOnly: Value(document.gdriveFileId == null),
              changeNote: Value(changeNote),
              origin: Value(origin),
              createdByDevice: Value(createdByDevice),
              createdAt: Value(now),
            ),
          );

      // Moving the current pointer is the only mutation this method makes to
      // the document row, and it is separate from `baseRevision` on purpose:
      // a NEW VERSION always changes the content, so the content hash moved,
      // and the sync revision is advanced by whatever path queued this job.
      await (_db.update(_db.localDocuments)
            ..where((t) => t.id.equals(document.id)))
          .write(LocalDocumentsCompanion(
        currentVersionId: Value(id),
        updatedAt: Value(now),
      ));

      // Read back the row just inserted rather than going through
      // `currentVersion`, whose contract is nullable (a pre-P1 document has no
      // version yet). Inside this transaction the row certainly exists, and
      // `getSingle` states that instead of papering over it with `!`.
      return await (_db.select(_db.documentVersions)
            ..where((t) => t.id.equals(id)))
          .getSingle();
    });
  }

  /// All live versions, newest first. Tombstoned versions are excluded so a
  /// pruned entry cannot resurface in the timeline.
  Future<List<DocumentVersion>> listVersions(String documentId) =>
      (_db.select(_db.documentVersions)
            ..where((t) => t.documentId.equals(documentId))
            ..where((t) => t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.desc(t.versionNumber)]))
          .get();

  Future<DocumentVersion?> findVersion(String versionId) =>
      (_db.select(_db.documentVersions)
            ..where((t) => t.id.equals(versionId)))
          .getSingleOrNull();

  /// The version the document currently points at, or null for a pre-P1
  /// document that has never had a version recorded.
  Future<DocumentVersion?> currentVersion(String documentId) async {
    final doc = await (_db.select(_db.localDocuments)
          ..where((t) => t.id.equals(documentId)))
        .getSingleOrNull();
    final versionId = doc?.currentVersionId;
    if (versionId == null) return null;
    return findVersion(versionId);
  }

  Future<int> countVersions(String documentId) async {
    final rows = await _db.customSelect(
      'SELECT COUNT(*) AS c FROM document_versions '
      'WHERE document_id = ? AND deleted_at IS NULL',
      variables: [Variable.withString(documentId)],
    ).get();
    return (rows.first.data['c'] as int?) ?? 0;
  }

  /// Soft-delete marker only. Versions are NEVER hard-deleted from here: the
  /// bytes they describe stay until the blob's reference count says otherwise
  /// (R-03), and the row stays so history keeps showing that a version existed.
  Future<void> tombstone(String versionId) =>
      (_db.update(_db.documentVersions)
            ..where((t) => t.id.equals(versionId)))
          .write(DocumentVersionsCompanion(deletedAt: Value(DateTime.now())));

  Future<int> _nextVersionNumber(String documentId) async {
    final rows = await _db.customSelect(
      'SELECT COALESCE(MAX(version_number), 0) AS top FROM document_versions '
      'WHERE document_id = ?',
      variables: [Variable.withString(documentId)],
    ).get();
    return ((rows.first.data['top'] as int?) ?? 0) + 1;
  }

  /// The description as it stood at this moment, so history can show what the
  /// record was called THEN. Excludes anything that could leak content search
  /// into a snapshot diff view unexpectedly.
  Map<String, Object?> _snapshotOf(DocumentItem document) => {
        'title': document.title,
        'documentNumber': document.documentNumber,
        'category': document.category,
        'documentDate': document.documentDate.toIso8601String(),
        'fiscalYear': document.fiscalYear,
      };
}

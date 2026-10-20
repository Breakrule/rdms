enum DocumentSyncStatus {
  localOnly('local_only'),
  queued('queued'),
  syncing('syncing'),
  synced('synced'),
  error('error'),
  deleted('deleted'),
  lost('lost');

  final String value;
  const DocumentSyncStatus(this.value);

  String get label {
    switch (this) {
      case DocumentSyncStatus.localOnly:
        return 'Lokal Saja';
      case DocumentSyncStatus.queued:
        return 'Dalam Antrean';
      case DocumentSyncStatus.syncing:
        return 'Menyinkronkan';
      case DocumentSyncStatus.synced:
        return 'Tersinkron';
      case DocumentSyncStatus.error:
        return 'Gagal Sinkron';
      case DocumentSyncStatus.deleted:
        return 'Dihapus di Drive';
      case DocumentSyncStatus.lost:
        return 'Lost (Nama Berubah)';
    }
  }

  static DocumentSyncStatus fromString(String val) {
    return DocumentSyncStatus.values.firstWhere(
      (e) => e.value == val,
      orElse: () => DocumentSyncStatus.localOnly,
    );
  }
}

/// Domain entity representing a government/office document.
class DocumentItem {
  final String id;
  final String title;
  final String? documentNumber;
  final String category; // SK, Laporan, Notula, Teknis, etc.
  final DateTime documentDate;
  final int fiscalYear;
  final String localFilePath;
  final String fileName;
  final int fileSizeBytes;
  final String mimeType;
  final String sha256Hash;
  final String? extractedText;
  final DocumentSyncStatus syncStatus;
  final String? gdriveFileId;
  final String? remoteBackendId;
  /// Non-null when the row lives in the local recycle bin (Phase 1.4).
  /// Browsing, counting, and searching exclude trashed rows by default;
  /// the recovery screen reads through [DocumentView.trashed]. The
  /// managed file stays on disk so [restoreDocument] can re-activate
  /// the row without touching binaries or Drive IDs.
  final DateTime? trashedAt;
  /// Monotonic revision counter used by the v2 batch endpoint to
  /// detect conflicts (Phase 2.6). Advanced locally on every
  /// metadata edit; the server maintains its own copy.
  final int baseRevision;
  /// Opaque identifier of the account this document is bound to for
  /// sync purposes. `null` means "not yet bound" and blocks queue
  /// claim on that document until the user resolves an account.
  final String? accountBinding;
  /// Phase 4.3 device-local favorite marker. Never included in sync
  /// payloads or the portable backup manifest.
  final bool isFavorite;
  /// Phase 4.1 free-form note; replicated via the v2 payload.
  final String? notes;
  /// Phase 4.4 user-facing original name before managed renaming.
  final String? originalFileName;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isTrashed => trashedAt != null;

  const DocumentItem({
    required this.id,
    required this.title,
    this.documentNumber,
    required this.category,
    required this.documentDate,
    required this.fiscalYear,
    required this.localFilePath,
    required this.fileName,
    required this.fileSizeBytes,
    required this.mimeType,
    required this.sha256Hash,
    this.extractedText,
    this.syncStatus = DocumentSyncStatus.localOnly,
    this.gdriveFileId,
    this.remoteBackendId,
    this.trashedAt,
    this.baseRevision = 1,
    this.accountBinding,
    this.isFavorite = false,
    this.notes,
    this.originalFileName,
    required this.createdAt,
    required this.updatedAt,
  });

  DocumentItem copyWith({
    String? id,
    String? title,
    String? documentNumber,
    String? category,
    DateTime? documentDate,
    int? fiscalYear,
    String? localFilePath,
    String? fileName,
    int? fileSizeBytes,
    String? mimeType,
    String? sha256Hash,
    String? extractedText,
    DocumentSyncStatus? syncStatus,
    String? gdriveFileId,
    String? remoteBackendId,
    DateTime? trashedAt,
    int? baseRevision,
    String? accountBinding,
    bool? isFavorite,
    String? notes,
    bool clearNotes = false,
    String? originalFileName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DocumentItem(
      id: id ?? this.id,
      title: title ?? this.title,
      documentNumber: documentNumber ?? this.documentNumber,
      category: category ?? this.category,
      documentDate: documentDate ?? this.documentDate,
      fiscalYear: fiscalYear ?? this.fiscalYear,
      localFilePath: localFilePath ?? this.localFilePath,
      fileName: fileName ?? this.fileName,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      mimeType: mimeType ?? this.mimeType,
      sha256Hash: sha256Hash ?? this.sha256Hash,
      extractedText: extractedText ?? this.extractedText,
      syncStatus: syncStatus ?? this.syncStatus,
      gdriveFileId: gdriveFileId ?? this.gdriveFileId,
      remoteBackendId: remoteBackendId ?? this.remoteBackendId,
      // trashedAt uses a sentinel-free convention: pass DateTime.now()
      // to trash, pass a value that equals epoch to explicitly clear
      // via copyWith, or leave it absent to keep the existing value.
      // Repository code that needs to clear trashedAt calls
      // DocumentRepository.restoreDocument, not copyWith.
      trashedAt: trashedAt ?? this.trashedAt,
      baseRevision: baseRevision ?? this.baseRevision,
      accountBinding: accountBinding ?? this.accountBinding,
      isFavorite: isFavorite ?? this.isFavorite,
      // notes follows an explicit-clear convention: pass
      // clearNotes: true to blank it, otherwise the value is kept
      // (copyWith cannot distinguish "absent" from "null" for
      // nullable String).
      notes: clearNotes ? null : (notes ?? this.notes),
      originalFileName: originalFileName ?? this.originalFileName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

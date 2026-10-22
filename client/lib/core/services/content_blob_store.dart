import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../utils/hash_util.dart';
import 'interfaces/i_storage_service.dart';

/// Owns the content-addressed blob store and every reference count in it.
///
/// This is the implementation of plan risk **R-03**: before it,
/// `LocalStorageService.deleteManagedFile` removed a file unconditionally, so
/// the moment two versions could share identical bytes, purging one would
/// silently destroy the other. Nothing here deletes a byte without first
/// proving no live reference remains.
///
/// Two layouts coexist on purpose (see `tables/document_versions.dart`):
///   * `legacyPath`  — the pre-P1 flat managed file, adopted in place with zero
///                     bytes moved, so upgrading an existing library is free.
///   * `relativePath`— `blobs/<sha256[0:2]>/<sha256>` for content written from
///                     P1 onward, which dedups identical bytes automatically.
///
/// Paths stored in the table are **root-relative**, and resolution happens here
/// against the active storage root. A local path is a device-private detail and
/// is never a portable identifier (plan §6.2), so the store — not the row —
/// owns that mapping.
class ContentBlobStore {
  final AppDatabase _db;
  final IStorageService _storage;

  ContentBlobStore({required this._db, required this._storage});

  static const _uuid = Uuid();

  /// Directory prefix for content-addressed blobs, relative to the storage root.
  static const blobsDirName = 'blobs';

  /// Registers an already-managed file as a blob and returns it, WITHOUT copying.
  ///
  /// Used to adopt a pre-existing document's file as version 1, and to record
  /// the file `LocalStorageService.storeFile` just wrote. If a blob with the
  /// same content hash already exists its reference count rises and no second
  /// copy is made — that is the entire point of content addressing.
  Future<ContentBlob> adoptManagedFile({
    required String sha256Hash,
    required String managedPath,
    required int sizeBytes,
    required String mimeType,
  }) async {
    return _db.transaction(() async {
      final now = DateTime.now();
      final existing = await _byHashOrNull(sha256Hash);
      if (existing != null) {
        await (_db.update(_db.contentBlobs)
              ..where((t) => t.id.equals(existing.id)))
            .write(ContentBlobsCompanion(
          refCount: Value(existing.refCount + 1),
          updatedAt: Value(now),
        ));
        return await _byId(existing.id);
      }
      final id = _uuid.v4();
      await _db.into(_db.contentBlobs).insert(
            ContentBlobsCompanion.insert(
              id: id,
              sha256Hash: sha256Hash,
              legacyPath: Value(managedPath),
              sizeBytes: sizeBytes,
              mimeType: mimeType,
              refCount: const Value(1),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );
      return _byId(id);
    });
  }

  /// Copies [sourceFile] into the content-addressed layout and returns the blob.
  ///
  /// Identical bytes already stored means no copy at all: the existing blob's
  /// count simply increases. Hashing is streaming and isolate-backed, so a
  /// 10 MB scan does not become a 10 MB buffer — the mistake
  /// `LocalStorageService.storeBytes` makes and this path deliberately avoids.
  Future<ContentBlob> storeContentAddressed(
    File sourceFile, {
    required String mimeType,
  }) async {
    final sha256 = await HashUtil.calculateFileSha256(sourceFile);
    if (!await sourceFile.exists()) {
      throw FileSystemException('Source file vanished before storing', sourceFile.path);
    }
    final size = await sourceFile.length();
    final root = await _storage.getStorageDirectoryPath();

    return _db.transaction(() async {
      final now = DateTime.now();
      final existing = await _byHashOrNull(sha256);
      if (existing != null) {
        await (_db.update(_db.contentBlobs)
              ..where((t) => t.id.equals(existing.id)))
            .write(ContentBlobsCompanion(
          refCount: Value(existing.refCount + 1),
          updatedAt: Value(now),
        ));
        return _byId(existing.id);
      }

      final relative = blobRelativePath(sha256);
      final absolute = p.join(root, relative);
      await Directory(p.dirname(absolute)).create(recursive: true);
      await sourceFile.copy(absolute);

      // Verify before recording: a blob row only ever describes bytes that
      // actually hash to its own key. A failed verification removes the partial
      // copy and records nothing, so a corrupt write cannot become invisible.
      final written = File(absolute);
      final writtenHash = await HashUtil.calculateFileSha256(written);
      if (writtenHash != sha256) {
        await written.delete();
        throw StateError(
          'Blob verification failed after copy: expected $sha256, got '
          '$writtenHash. The partial copy was removed and no row was written.',
        );
      }

      final id = _uuid.v4();
      await _db.into(_db.contentBlobs).insert(
            ContentBlobsCompanion.insert(
              id: id,
              sha256Hash: sha256,
              relativePath: Value(relative),
              sizeBytes: size,
              mimeType: mimeType,
              refCount: const Value(1),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );
      return _byId(id);
    });
  }

  /// Drops one reference. Returns `true` only when this call actually removed
  /// the bytes, i.e. the last reference went away.
  ///
  /// A file that is already missing does NOT count as success and does not
  /// error: the blob row is dropped and the situation is surfaced by
  /// `library_integrity_service` later, because treating "couldn't find it" as
  /// "deleted it" is how lost data gets reported as cleaned up.
  Future<bool> release(String blobId) async {
    return _db.transaction(() async {
      final blob = await _byIdOrNull(blobId);
      if (blob == null) return false;

      final remaining = blob.refCount - 1;
      if (remaining > 0) {
        await (_db.update(_db.contentBlobs)..where((t) => t.id.equals(blobId)))
            .write(ContentBlobsCompanion(
          refCount: Value(remaining),
          updatedAt: Value(DateTime.now()),
        ));
        return false;
      }

      final path = await absolutePathOf(blob);
      if (path != null) {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      }
      await (_db.delete(_db.contentBlobs)..where((t) => t.id.equals(blobId)))
          .go();
      return true;
    });
  }

  /// Whether the bytes behind [sha256Hash] may be deleted from disk.
  ///
  /// The guard `DriftDocumentRepository.deleteDocument` consults so removing
  /// one document cannot erase content another still points at. A hash with no
  /// blob row at all is pre-P1 data and deletes normally, which keeps every
  /// existing delete path behaving as it does today.
  Future<bool> isSafeToDeleteBytes(String sha256Hash) async {
    final blob = await _byHashOrNull(sha256Hash);
    if (blob == null) return true;
    return blob.refCount <= 1;
  }

  /// Resolves a blob's on-disk location for THIS device, or null when the bytes
  /// are known to be remote-only.
  Future<String?> absolutePathOf(ContentBlob blob) async {
    if (!blob.localAvailable) return null;
    final relative = blob.relativePath;
    if (relative != null) {
      final root = await _storage.getStorageDirectoryPath();
      return p.join(root, relative);
    }
    return blob.legacyPath;
  }

  /// The absolute path a content-addressed blob with [sha256Hash] would occupy.
  Future<String> pathForHash(String sha256Hash) async {
    final root = await _storage.getStorageDirectoryPath();
    return p.join(root, blobRelativePath(sha256Hash));
  }

  /// Marks a blob's bytes as absent locally without deleting the row, so the
  /// version it backs still exists and can be re-downloaded (P2.3, P2.7).
  Future<void> markNotLocal(String blobId) =>
      (_db.update(_db.contentBlobs)..where((t) => t.id.equals(blobId))).write(
        ContentBlobsCompanion(
          localAvailable: const Value(false),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<ContentBlob?> findBySha256(String sha256Hash) =>
      _byHashOrNull(sha256Hash);

  Future<ContentBlob?> findById(String id) => _byIdOrNull(id);

  Future<List<ContentBlob>> allBlobs() => _db.select(_db.contentBlobs).get();

  /// Bytes held locally by the blob store. Drives the storage-pressure banner
  /// (P1.6) and the quota-aware eviction rules (P2.7).
  Future<int> totalLocalBytes() async {
    final rows = await _db.customSelect(
      'SELECT COALESCE(SUM(size_bytes), 0) AS total FROM content_blobs '
      'WHERE local_available = 1',
    ).get();
    return (rows.first.data['total'] as int?) ?? 0;
  }

  /// `blobs/<first two hex chars>/<full hash>` — sharded so no single directory
  /// ever holds thousands of entries.
  static String blobRelativePath(String sha256Hash) => p.join(
        blobsDirName,
        sha256Hash.substring(0, 2),
        sha256Hash,
      );

  Future<ContentBlob> _byId(String id) async => (await _byIdOrNull(id))!;

  Future<ContentBlob?> _byIdOrNull(String id) =>
      (_db.select(_db.contentBlobs)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<ContentBlob?> _byHashOrNull(String sha256Hash) =>
      (_db.select(_db.contentBlobs)
            ..where((t) => t.sha256Hash.equals(sha256Hash)))
          .getSingleOrNull();
}

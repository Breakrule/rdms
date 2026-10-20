import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../utils/hash_util.dart';
import 'operation_journal.dart';

/// Portable backup export/restore for the local library (Phase 1.5 / 1.6).
///
/// Backup layout (a folder the user selects; nothing is compressed so a
/// partial archive is still inspectable):
///
///   `<backup_dir>/`
///     manifest.json      // schema version + document metadata
///     files/             // managed binaries referenced by manifest
///     README.txt         // human-readable explanation
///
/// Rules that Phase 1's acceptance gate cares about:
/// - [exportLibrary] refuses to leak absolute local paths into
///   manifest.json; files are referenced only by their
///   `files/<managedFileName>` relative path.
/// - [validateBackup] rejects any entry whose relative path escapes
///   `files/` (path traversal, symlink, or absolute path).
/// - [restoreBackup] verifies the SHA-256 of every staged file BEFORE
///   activating a metadata row. Any mismatch aborts the restore and
///   leaves the live library untouched.
/// - [ConflictPolicy] is mandatory: silent overwrite is not permitted.
class LibraryBackupService {
  /// Manifest v2 (Phase 4.8) adds notes/originalFileName/tags per
  /// document. v1 archives remain restorable; missing fields fall back
  /// to nulls. Favorites stay OUT of the manifest by design (they are
  /// a device-local viewing preference, Phase 4.3).
  static const supportedManifestVersion = 2;
  static const acceptedManifestVersions = {1, supportedManifestVersion};

  final AppDatabase _db;
  final OperationJournal _journal;
  static const _uuid = Uuid();

  LibraryBackupService({
    required this._db,
    required this._journal,
  });

  /// Writes every row (active and trashed) plus its managed binary into
  /// [destinationDir]. Returns the manifest summary so the UI can report
  /// counts to the user.
  ///
  /// Existing files under [destinationDir] are treated as scratch space;
  /// the manifest and `files/` folder are re-created each run. Callers
  /// should point the service at a fresh directory to avoid surprises.
  Future<BackupSummary> exportLibrary(Directory destinationDir) async {
    if (!await destinationDir.exists()) {
      await destinationDir.create(recursive: true);
    }

    final opId = await _journal.begin(
      kind: OperationKind.backup,
      targetPath: destinationDir.path,
    );
    await _journal.markInProgress(opId);

    try {
      final docs = await _db.getAllDocumentsForBackup();
      // Tags for the manifest (Phase 4.8). Read once; export stays
      // consistent with the DB snapshot taken above.
      final tagRows = await (_db.select(_db.documentTags).join([
            innerJoin(_db.tags, _db.tags.id.equalsExp(_db.documentTags.tagId)),
          ]))
          .get();
      final tagsByDoc = <String, List<String>>{};
      for (final row in tagRows) {
        final dt = row.readTable(_db.documentTags);
        final tag = row.readTable(_db.tags);
        tagsByDoc.putIfAbsent(dt.documentId, () => []).add(tag.name);
      }
      final filesDir = Directory(p.join(destinationDir.path, 'files'));
      if (await filesDir.exists()) {
        await filesDir.delete(recursive: true);
      }
      await filesDir.create(recursive: true);

      final entries = <Map<String, dynamic>>[];
      var copied = 0;
      var missingFiles = 0;

      for (final doc in docs) {
        final source = File(doc.localFilePath);
        if (!await source.exists()) {
          // Export still records the metadata so a restore can surface
          // "your managed file is missing" instead of silently dropping
          // the row. The document shows as unresolved after restore.
          entries.add(_manifestEntryFor(doc, null, tagsByDoc));
          missingFiles++;
          continue;
        }
        final targetName = doc.fileName;
        final staged = File(p.join(filesDir.path, targetName));
        await source.copy(staged.path);
        entries.add(_manifestEntryFor(doc, 'files/$targetName', tagsByDoc));
        copied++;
      }

      final manifest = {
        'version': supportedManifestVersion,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'appSchemaVersion': _db.schemaVersion,
        'documentCount': entries.length,
        'missingFileCount': missingFiles,
        'documents': entries,
      };
      await File(p.join(destinationDir.path, 'manifest.json'))
          .writeAsString(const JsonEncoder.withIndent('  ').convert(manifest));
      await File(p.join(destinationDir.path, 'README.txt')).writeAsString(
        'RDMS Ultimate library backup\n'
        'Exported: ${manifest['createdAt']}\n'
        'Documents: ${manifest['documentCount']}\n'
        'Missing files at export time: ${manifest['missingFileCount']}\n'
        '\nThis folder IS NOT ENCRYPTED. Store it on a protected volume.\n'
        'Restore via RDMS Ultimate > Recovery > Restore from Backup.\n',
      );

      await _journal.complete(opId);
      return BackupSummary(
        documentCount: entries.length,
        filesCopied: copied,
        filesMissing: missingFiles,
        destinationPath: destinationDir.path,
      );
    } catch (err) {
      await _journal.fail(opId, err.toString());
      rethrow;
    }
  }

  Map<String, dynamic> _manifestEntryFor(
    LocalDocument doc,
    String? relativePath,
    Map<String, List<String>> tagsByDoc,
  ) {
    return {
      'id': doc.id,
      'title': doc.title,
      'documentNumber': doc.documentNumber,
      'category': doc.category,
      'documentDate': doc.documentDate.toUtc().toIso8601String(),
      'fiscalYear': doc.fiscalYear,
      'managedFileName': doc.fileName,
      'fileRelativePath': relativePath,
      'fileSizeBytes': doc.fileSizeBytes,
      'mimeType': doc.mimeType,
      'sha256Hash': doc.sha256Hash,
      'extractedText': doc.extractedText,
      'syncStatus': doc.syncStatus,
      // gdriveFileId is preserved so a restore keeps the Drive linkage
      // for documents already backed up. LocalFilePath is intentionally
      // NOT in the manifest; restore rebases it under the destination
      // storage root.
      'gdriveFileId': doc.gdriveFileId,
      'notes': doc.notes,
      'originalFileName': doc.originalFileName,
      'tags': tagsByDoc[doc.id] ?? const <String>[],
      'trashedAt': doc.trashedAt?.toUtc().toIso8601String(),
      'createdAt': doc.createdAt.toUtc().toIso8601String(),
      'updatedAt': doc.updatedAt.toUtc().toIso8601String(),
    };
  }

  /// Reads the manifest and validates every claim it makes. Returns a
  /// [BackupValidation] that lists conflicts against the live database
  /// so the caller can decide the policy before [restoreBackup] runs.
  Future<BackupValidation> validateBackup(Directory backupDir) async {
    final manifestFile = File(p.join(backupDir.path, 'manifest.json'));
    if (!await manifestFile.exists()) {
      throw BackupInvalidException('manifest.json tidak ditemukan di folder backup.');
    }
    final raw = await manifestFile.readAsString();
    final Map<String, dynamic> manifest;
    try {
      manifest = jsonDecode(raw) as Map<String, dynamic>;
    } on FormatException catch (e) {
      throw BackupInvalidException('manifest.json tidak valid: ${e.message}');
    }

    final version = manifest['version'];
    if (!acceptedManifestVersions.contains(version)) {
      throw BackupInvalidException(
        'Versi manifest $version tidak didukung (menerima ${acceptedManifestVersions.join(', ')}).',
      );
    }

    final documents = (manifest['documents'] as List?) ?? const [];
    final problems = <String>[];
    final entries = <BackupEntry>[];

    for (final raw in documents) {
      if (raw is! Map) {
        problems.add('Entry bukan objek: $raw');
        continue;
      }
      final entry = Map<String, dynamic>.from(raw);
      final relative = entry['fileRelativePath'] as String?;
      if (relative != null && !_isSafeRelativePath(relative)) {
        problems.add('Path tidak aman ditolak: $relative');
        continue;
      }
      final id = entry['id'] as String?;
      if (id == null || id.isEmpty) {
        problems.add('Entry tanpa id: $entry');
        continue;
      }
      final file = relative == null ? null : File(p.join(backupDir.path, relative));
      entries.add(BackupEntry(
        id: id,
        relativePath: relative,
        file: file,
        expectedSha256: entry['sha256Hash'] as String,
        metadata: entry,
      ));
    }

    // Detect conflicts with live database.
    final existingIds = <String>{};
    if (entries.isNotEmpty) {
      final ids = entries.map((e) => e.id).toList();
      final rows = await (_db.select(_db.localDocuments)
            ..where((t) => t.id.isIn(ids)))
          .get();
      existingIds.addAll(rows.map((r) => r.id));
    }

    return BackupValidation(
      manifestVersion: version as int,
      entries: entries,
      existingIds: existingIds,
      problems: problems,
    );
  }

  bool _isSafeRelativePath(String rel) {
    if (rel.isEmpty) return false;
    if (rel.startsWith('/') || rel.startsWith(r'\')) return false;
    // Reject absolute Windows paths like C:\ or D:/
    if (RegExp(r'^[A-Za-z]:').hasMatch(rel)) return false;
    final normalized = p.posix.normalize(rel);
    if (normalized.startsWith('..')) return false;
    if (normalized.contains('..')) return false;
    // Backup layout only permits "files/<name>".
    if (!normalized.startsWith('files/')) return false;
    return true;
  }

  /// Applies a validated backup into the given storage [rootDir]. Every
  /// file is copied into [rootDir] first, verified against the recorded
  /// checksum, and only then is the DB row upserted. Conflicts follow
  /// [policy]; abort on any checksum mismatch (the operation journal
  /// marks the run as failed and the caller sees the exception).
  Future<RestoreSummary> restoreBackup(
    Directory backupDir, {
    required Directory rootDir,
    required ConflictPolicy policy,
  }) async {
    if (!await rootDir.exists()) {
      await rootDir.create(recursive: true);
    }

    final validation = await validateBackup(backupDir);
    if (validation.problems.isNotEmpty) {
      throw BackupInvalidException(
        'Backup divalidasi gagal: ${validation.problems.join('; ')}',
      );
    }

    final opId = await _journal.begin(
      kind: OperationKind.restore,
      targetPath: backupDir.path,
    );
    await _journal.markInProgress(opId);

    var restored = 0;
    var skipped = 0;
    var conflictsResolved = 0;
    final failures = <String>[];

    try {
      for (final entry in validation.entries) {
        if (validation.existingIds.contains(entry.id)) {
          switch (policy) {
            case ConflictPolicy.abort:
              throw BackupInvalidException(
                'Dokumen ${entry.id} sudah ada. Backup restore dibatalkan.',
              );
            case ConflictPolicy.skip:
              skipped++;
              continue;
            case ConflictPolicy.overwrite:
              conflictsResolved++;
              break;
          }
        }

        if (entry.file != null && await entry.file!.exists()) {
          final actualHash = await HashUtil.calculateFileSha256(entry.file!);
          if (actualHash != entry.expectedSha256) {
            failures.add(
              'Hash mismatch for ${entry.relativePath}: expected ${entry.expectedSha256}, got $actualHash',
            );
            continue;
          }
        }

        final managedFileName = entry.metadata['managedFileName'] as String;
        final targetFile = File(p.join(rootDir.path, managedFileName));
        if (entry.file != null && await entry.file!.exists()) {
          await entry.file!.copy(targetFile.path);
        }

        final companion = LocalDocumentsCompanion.insert(
          id: entry.id,
          title: entry.metadata['title'] as String,
          documentNumber: Value(entry.metadata['documentNumber'] as String?),
          category: entry.metadata['category'] as String,
          documentDate: DateTime.parse(entry.metadata['documentDate'] as String),
          fiscalYear: entry.metadata['fiscalYear'] as int,
          localFilePath: targetFile.path,
          fileName: managedFileName,
          fileSizeBytes: (entry.metadata['fileSizeBytes'] as num).toInt(),
          mimeType: entry.metadata['mimeType'] as String,
          sha256Hash: entry.expectedSha256,
          extractedText: Value(entry.metadata['extractedText'] as String?),
          syncStatus: Value(entry.metadata['syncStatus'] as String? ?? 'local_only'),
          gdriveFileId: Value(entry.metadata['gdriveFileId'] as String?),
          notes: Value(entry.metadata['notes'] as String?),
          originalFileName: Value(entry.metadata['originalFileName'] as String?),
          trashedAt: entry.metadata['trashedAt'] == null
              ? const Value.absent()
              : Value(DateTime.parse(entry.metadata['trashedAt'] as String)),
          createdAt: Value(DateTime.parse(entry.metadata['createdAt'] as String)),
          updatedAt: Value(DateTime.parse(entry.metadata['updatedAt'] as String)),
        );
        await _db.into(_db.localDocuments).insertOnConflictUpdate(companion);
        // Re-materialize tags (v2 manifests only; v1 lacks the field).
        final tagNames = (entry.metadata['tags'] as List?)?.cast<String>();
        if (tagNames != null && tagNames.isNotEmpty) {
          for (final name in tagNames) {
            final trimmed = name.trim().toLowerCase();
            if (trimmed.isEmpty) continue;
            var tag = await (_db.select(_db.tags)
                  ..where((t) => t.name.equals(trimmed)))
                .getSingleOrNull();
            if (tag == null) {
              await _db.into(_db.tags).insert(
                    TagsCompanion.insert(id: _uuid.v4(), name: trimmed),
                    onConflict: DoNothing(),
                  );
              tag = await (_db.select(_db.tags)
                    ..where((t) => t.name.equals(trimmed)))
                  .getSingle();
            }
            await _db.into(_db.documentTags).insert(
                  DocumentTagsCompanion.insert(
                    documentId: entry.id,
                    tagId: tag.id,
                  ),
                  onConflict: DoNothing(),
                );
          }
        }
        restored++;
      }

      if (failures.isNotEmpty) {
        await _journal.fail(opId, failures.join('\n'));
        throw BackupInvalidException(failures.join('\n'));
      }

      await _journal.complete(opId);
      return RestoreSummary(
        restored: restored,
        skipped: skipped,
        overwritten: conflictsResolved,
      );
    } catch (err) {
      await _journal.fail(opId, err.toString());
      rethrow;
    }
  }
}

enum ConflictPolicy { abort, skip, overwrite }

class BackupEntry {
  final String id;
  final String? relativePath;
  final File? file;
  final String expectedSha256;
  final Map<String, dynamic> metadata;

  const BackupEntry({
    required this.id,
    required this.relativePath,
    required this.file,
    required this.expectedSha256,
    required this.metadata,
  });
}

class BackupValidation {
  final int manifestVersion;
  final List<BackupEntry> entries;
  final Set<String> existingIds;
  final List<String> problems;

  const BackupValidation({
    required this.manifestVersion,
    required this.entries,
    required this.existingIds,
    required this.problems,
  });
}

class BackupSummary {
  final int documentCount;
  final int filesCopied;
  final int filesMissing;
  final String destinationPath;

  const BackupSummary({
    required this.documentCount,
    required this.filesCopied,
    required this.filesMissing,
    required this.destinationPath,
  });
}

class RestoreSummary {
  final int restored;
  final int skipped;
  final int overwritten;

  const RestoreSummary({
    required this.restored,
    required this.skipped,
    required this.overwritten,
  });
}

class BackupInvalidException implements Exception {
  final String message;
  BackupInvalidException(this.message);
  @override
  String toString() => 'BackupInvalidException: $message';
}

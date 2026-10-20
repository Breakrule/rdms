import 'dart:io';

import 'package:path/path.dart' as p;

import '../database/app_database.dart';
import '../utils/hash_util.dart';
import 'operation_journal.dart';

/// Verifies the local library is internally consistent (Phase 1.7).
///
/// Answers four questions:
/// - Are all managed files present at their recorded paths?
/// - Do their SHA-256 hashes still match? (External modification.)
/// - Are there managed files in the active storage root that no DB row
///   references? (Orphans from a crashed import or a partial purge.)
/// - Are there any open operation-journal entries left behind from a
///   crash?
///
/// External file changes are reported as [IntegrityFinding.needsReview];
/// they are never silently re-hashed. That preserves Phase 0's
/// "checksum is evidence, not self-healing" stance.
class LibraryIntegrityService {
  final AppDatabase _db;
  final OperationJournal _journal;

  LibraryIntegrityService({
    required this._db,
    required this._journal,
  });

  Future<IntegrityReport> check({required String storageRootPath}) async {
    final findings = <IntegrityFinding>[];
    final docs = await _db.getAllDocumentsForBackup();
    final referencedPaths = <String>{};

    for (final doc in docs) {
      referencedPaths.add(p.canonicalize(doc.localFilePath));
      final file = File(doc.localFilePath);
      if (!await file.exists()) {
        findings.add(IntegrityFinding(
          kind: IntegrityFindingKind.missingFile,
          documentId: doc.id,
          path: doc.localFilePath,
          detail: 'Berkas fisik tidak ditemukan di path yang tersimpan di metadata.',
        ));
        continue;
      }
      try {
        final actual = await HashUtil.calculateFileSha256(file);
        if (actual != doc.sha256Hash) {
          findings.add(IntegrityFinding(
            kind: IntegrityFindingKind.contentChanged,
            documentId: doc.id,
            path: doc.localFilePath,
            detail: 'Hash saat ini $actual, metadata mencatat ${doc.sha256Hash}.',
          ));
        }
      } on FileSystemException catch (e) {
        findings.add(IntegrityFinding(
          kind: IntegrityFindingKind.unreadableFile,
          documentId: doc.id,
          path: doc.localFilePath,
          detail: 'Berkas tidak dapat dibaca: ${e.message}',
        ));
      }
    }

    final rootDir = Directory(storageRootPath);
    if (await rootDir.exists()) {
      await for (final entity in rootDir.list(followLinks: false)) {
        if (entity is! File) continue;
        final canonical = p.canonicalize(entity.path);
        if (!referencedPaths.contains(canonical)) {
          findings.add(IntegrityFinding(
            kind: IntegrityFindingKind.orphanFile,
            path: entity.path,
            detail: 'Berkas ada di storage root tetapi tidak dirujuk oleh metadata mana pun.',
          ));
        }
      }
    } else {
      findings.add(IntegrityFinding(
        kind: IntegrityFindingKind.storageRootUnavailable,
        path: storageRootPath,
        detail: 'Direktori penyimpanan aktif tidak dapat diakses.',
      ));
    }

    final open = await _journal.openOperations();
    for (final op in open) {
      findings.add(IntegrityFinding(
        kind: IntegrityFindingKind.interruptedOperation,
        path: op.stagedPath ?? op.targetPath,
        detail: 'Operasi ${op.kind} (${op.id}) masih ${op.status}; kemungkinan crash sebelumnya.',
      ));
    }

    return IntegrityReport(
      documentsScanned: docs.length,
      findings: findings,
      storageRootPath: storageRootPath,
    );
  }
}

enum IntegrityFindingKind {
  missingFile,
  contentChanged,
  unreadableFile,
  orphanFile,
  storageRootUnavailable,
  interruptedOperation,
}

class IntegrityFinding {
  final IntegrityFindingKind kind;
  final String? documentId;
  final String? path;
  final String detail;

  const IntegrityFinding({
    required this.kind,
    required this.detail,
    this.documentId,
    this.path,
  });
}

class IntegrityReport {
  final int documentsScanned;
  final List<IntegrityFinding> findings;
  final String storageRootPath;

  const IntegrityReport({
    required this.documentsScanned,
    required this.findings,
    required this.storageRootPath,
  });

  bool get isClean => findings.isEmpty;

  int countBy(IntegrityFindingKind kind) =>
      findings.where((f) => f.kind == kind).length;
}

import 'dart:io';

import 'package:path/path.dart' as p;

import '../../features/documents/domain/models/document_item.dart';
import '../../features/documents/domain/repositories/document_repository.dart';
import '../utils/hash_util.dart';

/// Phase 4.5: hash-based duplicate detection, run BEFORE finalizing an
/// import. Same bytes may legitimately be different records, so a hit
/// is a prompt, never an automatic merge or delete.
class DuplicateCheck {
  final DocumentRepository _repo;
  const DuplicateCheck(this._repo);

  Future<DuplicateMatch?> checkSource(File source) async {
    final hash = await HashUtil.calculateFileSha256(source);
    final matches = await _repo.findBySha256(hash);
    if (matches.isEmpty) return null;
    return DuplicateMatch(hash: hash, existing: matches);
  }
}

class DuplicateMatch {
  final String hash;
  final List<DocumentItem> existing;
  const DuplicateMatch({required this.hash, required this.existing});
}

enum DuplicateDecision { skip, keepAnyway }

/// One row of a bulk import outcome.
class BulkImportRow {
  final String sourcePath;
  final String title;
  final BulkImportRowStatus status;
  final String? detail;
  final DocumentItem? document;

  const BulkImportRow({
    required this.sourcePath,
    required this.title,
    required this.status,
    this.detail,
    this.document,
  });
}

enum BulkImportRowStatus { imported, skippedDuplicate, failed }

/// Phase 4.4 bulk import with duplicate detection.
///
/// Batch progress persistence: each accepted file goes through
/// [DocumentRepository.importDocument], which is individually
/// journaled and hash-deduped here. "Resume a partially failed batch
/// without repeating completed items" is therefore satisfied by the
/// dedup check: re-running the batch sees already-imported files as
/// duplicates and skips them (policy default below), so completed
/// items are not created a second time.
class BulkImportService {
  final DocumentRepository _repo;
  final DuplicateCheck _duplicates;

  BulkImportService({required DocumentRepository repository})
      : _repo = repository,
        _duplicates = DuplicateCheck(repository);

  static const int maxBatchSize = 100;

  Future<List<BulkImportRow>> importBatch({
    required List<BulkImportItem> items,
    required String defaultCategory,
    required DateTime defaultDate,
    required int defaultFiscalYear,
    DuplicateDecision duplicatePolicy = DuplicateDecision.skip,
    void Function(BulkImportRow row)? onRowDone,
  }) async {
    if (items.isEmpty) return const [];
    if (items.length > maxBatchSize) {
      throw ArgumentError('bulk import batch exceeds $maxBatchSize files');
    }
    final results = <BulkImportRow>[];
    for (final item in items) {
      final title = item.title.trim().isNotEmpty
          ? item.title.trim()
          : p.basenameWithoutExtension(item.sourcePath);
      BulkImportRow row;
      try {
        final source = File(item.sourcePath);
        if (!await source.exists()) {
          row = BulkImportRow(
            sourcePath: item.sourcePath,
            title: title,
            status: BulkImportRowStatus.failed,
            detail: 'Berkas sumber tidak ditemukan',
          );
        } else {
          final match = await _duplicates.checkSource(source);
          if (match != null && match.existing.isNotEmpty &&
              duplicatePolicy == DuplicateDecision.skip) {
            row = BulkImportRow(
              sourcePath: item.sourcePath,
              title: title,
              status: BulkImportRowStatus.skippedDuplicate,
              detail:
                  'Sama dengan ${match.existing.length} dokumen yang sudah ada (${match.existing.first.title})',
            );
          } else {
            final doc = await _repo.importDocument(
              sourceFile: source,
              title: title,
              documentNumber: item.documentNumber,
              category: item.category ?? defaultCategory,
              documentDate: item.documentDate ?? defaultDate,
              fiscalYear: item.fiscalYear ?? defaultFiscalYear,
              notes: item.notes,
            );
            row = BulkImportRow(
              sourcePath: item.sourcePath,
              title: title,
              status: BulkImportRowStatus.imported,
              document: doc,
            );
          }
        }
      } catch (err) {
        row = BulkImportRow(
          sourcePath: item.sourcePath,
          title: title,
          status: BulkImportRowStatus.failed,
          detail: err.toString(),
        );
      }
      results.add(row);
      onRowDone?.call(row);
    }
    return results;
  }
}

class BulkImportItem {
  final String sourcePath;
  final String title;
  final String? documentNumber;
  final String? category;
  final DateTime? documentDate;
  final int? fiscalYear;
  final String? notes;

  const BulkImportItem({
    required this.sourcePath,
    this.title = '',
    this.documentNumber,
    this.category,
    this.documentDate,
    this.fiscalYear,
    this.notes,
  });
}

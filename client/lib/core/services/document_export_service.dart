import 'dart:io';

import 'package:path/path.dart' as p;

import '../../features/documents/domain/models/document_item.dart';

/// CSV document-register export (Phase 4.7) and file-copy export
/// (Phase 4.6). Offline-capable: only local metadata + managed files.
class DocumentExportService {
  const DocumentExportService();

  static const _csvHeader = [
    'Judul',
    'Nomor Dokumen',
    'Kategori',
    'Tanggal Dokumen',
    'Tahun Anggaran',
    'Nama Berkas',
    'Ukuran (bayt)',
    'Tipe MIME',
    'Status Sinkron',
    'Tag',
    'Catatan',
    'SHA-256',
  ];

  /// Writes a UTF-8-BOM CSV of [documents]. Every cell is neutralized
  /// against spreadsheet formula injection: values beginning with
  /// `=`, `+`, `-`, `@`, tab, or CR get a leading `'` prefix, per
  /// OWASP guidance, because a register CSV is routinely opened in
  /// Excel where `=HYPERLINK(...)` in a "title" cell executes.
  Future<File> exportRegister({
    required Directory destination,
    required List<DocumentItem> documents,
    Map<String, Set<String>> tagsByDocument = const {},
    String? filename,
  }) async {
    if (!await destination.exists()) {
      await destination.create(recursive: true);
    }
    final ts = DateTime.now();
    final name = filename ??
        'rdms_register_${ts.year}${_pad(ts.month)}${_pad(ts.day)}_${_pad(ts.hour)}${_pad(ts.minute)}.csv';
    final file = File(p.join(destination.path, name));
    final rows = [
      _csvHeader,
      for (final d in documents)
        [
          d.title,
          d.documentNumber ?? '',
          d.category,
          '${d.documentDate.year}-${_pad(d.documentDate.month)}-${_pad(d.documentDate.day)}',
          '${d.fiscalYear}',
          d.originalFileName ?? d.fileName,
          '${d.fileSizeBytes}',
          d.mimeType,
          d.syncStatus.label,
          (tagsByDocument[d.id] ?? const <String>{}).join('; '),
          d.notes ?? '',
          d.sha256Hash,
        ],
    ];
    final sink = StringBuffer('\uFEFF'); // BOM so Excel detects UTF-8
    for (final row in rows) {
      sink.write(row.map(_escapeCell).join(','));
      sink.write('\r\n');
    }
    await file.writeAsString(sink.toString());
    return file;
  }

  static String _escapeCell(String raw) {
    var value = raw;
    if (value.isNotEmpty &&
        (value.startsWith('=') ||
            value.startsWith('+') ||
            value.startsWith('-') ||
            value.startsWith('@') ||
            value.startsWith('\t') ||
            value.startsWith('\r'))) {
      value = "'$value";
    }
    return '"${value.replaceAll('"', '""')}"';
  }

  static String _pad(int v) => v.toString().padLeft(2, '0');

  /// Copies the managed files of [documents] into [destination] under
  /// their managed names. Returns copied/missing counts. Used by the
  /// multi-select "Export berkas terpilih" action.
  Future<FilesExportSummary> exportFiles({
    required Directory destination,
    required List<DocumentItem> documents,
  }) async {
    if (!await destination.exists()) {
      await destination.create(recursive: true);
    }
    var copied = 0;
    var missing = 0;
    for (final d in documents) {
      final source = File(d.localFilePath);
      if (!await source.exists()) {
        missing++;
        continue;
      }
      await source.copy(p.join(destination.path, d.fileName));
      copied++;
    }
    return FilesExportSummary(copied: copied, missing: missing);
  }
}

class FilesExportSummary {
  final int copied;
  final int missing;
  const FilesExportSummary({required this.copied, required this.missing});
}

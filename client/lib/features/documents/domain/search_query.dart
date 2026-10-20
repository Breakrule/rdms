/// Phase 5.5 search-query parsing: turn a free-text query that mixes
/// `prefix:value` tokens with plain words into a single structured filter,
/// so the command palette can honour MULTIPLE prefixes at once instead of
/// only the first one. All recognised prefixes compose; the leftover words
/// become the FTS text.
///
/// Supported prefixes (Indonesian, matching the existing palette):
///   tahun:    fiscal year (int)
///   kategori: category code
///   status:   sync status name (localOnly/synced/...)
///   nomor:    exact document number
///   tipe:     exact MIME type
///   berkas:   managed OR original filename (substring)
///   tag:      tag name (case-insensitive)
///   dari:     inclusive document-date lower bound (YYYY-MM-DD)
///   ke:       inclusive document-date upper bound (YYYY-MM-DD)
///
/// `value` is taken as the token after the colon (no spaces inside a value;
/// multi-word plain text is treated as search words).
class DocumentQuery {
  final String text;
  final int? fiscalYear;
  final String? category;
  final String? syncStatus;
  final String? documentNumber;
  final String? mimeType;
  final String? fileName;
  final String? tag;
  final int? dateFromMillis;
  final int? dateToMillis;

  const DocumentQuery({
    this.text = '',
    this.fiscalYear,
    this.category,
    this.syncStatus,
    this.documentNumber,
    this.mimeType,
    this.fileName,
    this.tag,
    this.dateFromMillis,
    this.dateToMillis,
  });

  bool get isEmpty =>
      text.isEmpty &&
      fiscalYear == null &&
      category == null &&
      syncStatus == null &&
      documentNumber == null &&
      mimeType == null &&
      fileName == null &&
      tag == null &&
      dateFromMillis == null &&
      dateToMillis == null;
}

DocumentQuery parseDocumentQuery(String rawQuery) {
  final parts = rawQuery.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty);

  String? fiscalYear;
  String? category;
  String? syncStatus;
  String? documentNumber;
  String? mimeType;
  String? fileName;
  String? tag;
  int? fromMillis;
  int? toMillis;
  final words = <String>[];

  for (final part in parts) {
    final sep = part.indexOf(':');
    // A leading ':' or no ':' at all means it is a plain search word.
    if (sep <= 0) {
      words.add(part);
      continue;
    }
    final key = part.substring(0, sep).toLowerCase();
    final value = part.substring(sep + 1).trim();
    if (value.isEmpty) {
      words.add(part);
      continue;
    }
    switch (key) {
      case 'tahun':
        fiscalYear = value;
        break;
      case 'kategori':
        category = value;
        break;
      case 'status':
        syncStatus = value;
        break;
      case 'nomor':
        documentNumber = value;
        break;
      case 'tipe':
        mimeType = value;
        break;
      case 'berkas':
        fileName = value;
        break;
      case 'tag':
        tag = value.toLowerCase();
        break;
      case 'dari':
        fromMillis = _startOfDay(value)?.millisecondsSinceEpoch;
        break;
      case 'ke':
        // inclusive end: the whole day
        final day = _startOfDay(value);
        toMillis = day == null
            ? null
            : day.add(const Duration(days: 1)).millisecondsSinceEpoch - 1;
        break;
      case 'nama':
        // Back-compat alias: 'nama:' behaves as plain search text.
        words.add(value);
        break;
      default:
        words.add(part);
    }
  }

  return DocumentQuery(
    text: words.join(' ').trim(),
    fiscalYear: int.tryParse(fiscalYear ?? ''),
    category: category,
    syncStatus: syncStatus,
    documentNumber: documentNumber,
    mimeType: mimeType,
    fileName: fileName,
    tag: tag,
    dateFromMillis: fromMillis,
    dateToMillis: toMillis,
  );
}

/// Parses `YYYY-MM-DD` into a LOCAL midnight DateTime (Drift stores
/// DateTimes as epoch millis, so bounds must be built the same way the
/// values were written). Returns null on an unparseable value.
DateTime? _startOfDay(String value) {
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
  if (match == null) return null;
  final y = int.parse(match.group(1)!);
  final m = int.parse(match.group(2)!);
  final d = int.parse(match.group(3)!);
  if (m < 1 || m > 12 || d < 1 || d > 31) return null;
  return DateTime(y, m, d);
}

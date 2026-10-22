/// Metric vocabulary for Rev. 2 Phase P0.
///
/// The point of these enums is that **there is no free-text field anywhere in
/// the metrics API**. Privacy prohibitions written as prose get violated by
/// the next caller who needs "just one extra field"; the way to make
/// `docs/METRICS.md` §1.1 true is an interface that cannot accept a title, a
/// filename, a query, or a message in the first place.
///
/// Every enum here maps to a short, stable string stored in
/// `usage_counters.context`. Renaming an enum value is a data-format change —
/// add a new value instead of repurposing an old one.
library;

/// Events the app records. Values are stored verbatim in `usage_counters.event`.
enum MetricEvent {
  sessionStart('session_start'),
  searchExecuted('search_executed'),
  searchAbandoned('search_abandoned'),
  documentOpened('document_opened'),
  duplicateDetected('duplicate_detected'),
  metadataEdited('metadata_edited'),
  integrityFinding('integrity_finding'),
  versionOpened('version_opened'),
  handoverExported('handover_exported'),
  errorShown('error_shown');

  const MetricEvent(this.value);
  final String value;
}

/// Where a search or open originated. Lets M2 distinguish palette search from
/// sidebar browsing without recording what was typed.
enum MetricSource {
  palette('palette'),
  listSearch('list_search'),
  sidebar('sidebar'),
  tag('tag'),
  collection('collection'),
  list('list'),
  detail('detail'),
  external('external'),
  unknown('unknown');

  const MetricSource(this.value);
  final String value;
}

/// Coarse MIME family. Deliberately NOT the full type — `application/pdf` and
/// `image/jpeg` are enough, because the exact subtype can encode provenance.
enum MimeFamily {
  pdf('pdf'),
  image('image'),
  spreadsheet('spreadsheet'),
  document('document'),
  other('other');

  const MimeFamily(this.value);
  final String value;

  static MimeFamily fromMimeType(String mimeType) {
    final lower = mimeType.toLowerCase();
    if (lower == 'application/pdf') return MimeFamily.pdf;
    if (lower.startsWith('image/')) return MimeFamily.image;
    if (lower.contains('spreadsheet') ||
        lower.contains('excel') ||
        lower == 'text/csv') {
      return MimeFamily.spreadsheet;
    }
    if (lower.contains('word') ||
        lower.contains('document') ||
        lower == 'text/plain') {
      return MimeFamily.document;
    }
    return MimeFamily.other;
  }
}

/// Outcome of the duplicate check (PRD metric 3, `duplicate_filed`).
/// `skip` and `openExisting` are reserved for the bulk-import flow; today's
/// single-import dialog (Phase 4.5) only offers cancel / keep separate.
enum DuplicateAction {
  cancel('cancel'),
  skip('skip'),
  openExisting('open_existing'),
  keepSeparate('keep_separate');

  const DuplicateAction(this.value);
  final String value;
}

/// Which field a metadata edit touched (PRD metric 3, `misfiled`).
enum EditedField {
  title('title'),
  documentNumber('document_number'),
  category('category'),
  documentDate('document_date'),
  fiscalYear('fiscal_year'),
  notes('notes'),
  tags('tags');

  const EditedField(this.value);
  final String value;
}

/// Integrity finding kind (PRD metric 3, `document_lost`).
enum IntegrityKind {
  missing('missing'),
  changed('changed'),
  orphan('orphan'),
  inaccessibleRoot('inaccessible_root');

  const IntegrityKind(this.value);
  final String value;
}

/// Bounded error vocabulary. Replaces any attempt to log a message string.
enum MetricErrorCode {
  storageUnavailable('storage_unavailable'),
  importFailed('import_failed'),
  backupFailed('backup_failed'),
  restoreFailed('restore_failed'),
  syncBlocked('sync_blocked'),
  authFailed('auth_failed'),
  fileUnopenable('file_unopenable'),
  dbError('db_error'),
  unknown('unknown');

  const MetricErrorCode(this.value);
  final String value;
}

/// Whether the opened document's bytes were on the device. Two values, so
/// `document_opened` can distinguish "open from cache" from "open from cloud"
/// without recording which cloud or which file.
enum Availability {
  local('local'),
  remoteOnly('remote_only');

  const Availability(this.value);
  final String value;
}

/// Every string permitted in `usage_counters.context`, derived from the enums
/// above. This is the enforcement mechanism for `docs/METRICS.md` §1.1: the
/// column accepts a token from this set or nothing at all, so a caller cannot
/// pass a title, filename, query, path, or error message even by accident.
///
/// If a new qualifier is genuinely needed, add an enum value — never widen the
/// column to free text.
final Set<String> kMetricContextAllowlist = {
  for (final v in MetricSource.values) v.value,
  for (final v in MimeFamily.values) v.value,
  for (final v in DuplicateAction.values) v.value,
  for (final v in EditedField.values) v.value,
  for (final v in IntegrityKind.values) v.value,
  for (final v in MetricErrorCode.values) v.value,
  for (final v in Availability.values) v.value,
};

/// Validates a comma-joined context string, throwing when any token is outside
/// the allowlist. Returns the canonical form.
String validateMetricContext(List<String> tokens) {
  if (tokens.isEmpty) return '';
  for (final token in tokens) {
    if (!kMetricContextAllowlist.contains(token)) {
      throw InvalidMetricException(
        'context token "$token" is not part of the metric vocabulary. '
        'Add an enum value to metric_event.dart rather than passing a raw '
        'string — this guard is what keeps document content out of counters.',
      );
    }
  }
  return tokens.join(',');
}

/// UUID shape check for the identifier fields. Stops a caller from smuggling a
/// filename into `documentId` / `sessionId`, which are strings by design.
final RegExp _uuidPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

String? validateMetricId(String? value, String field) {
  if (value == null) return null;
  if (!_uuidPattern.hasMatch(value)) {
    throw InvalidMetricException(
      '$field must be a UUID; got a value that is not one. Identifiers in '
      'counters are random, never derived from user data.',
    );
  }
  return value;
}

/// Raised when a caller attempts to record something the metric contract
/// forbids. Fails loudly in development instead of silently storing content.
class InvalidMetricException implements Exception {
  final String reason;
  InvalidMetricException(this.reason);

  @override
  String toString() => 'InvalidMetricException: $reason';
}

/// Shape of a recorded counter row, used by [MetricsService] and its tests.
class MetricRecord {
  final MetricEvent event;
  final DateTime occurredAt;
  final String workspaceId;
  final String? sessionId;
  final String? documentId;
  final int? latencyMs;
  final int? countValue;
  final String? context;

  const MetricRecord({
    required this.event,
    required this.occurredAt,
    required this.workspaceId,
    this.sessionId,
    this.documentId,
    this.latencyMs,
    this.countValue,
    this.context,
  });
}

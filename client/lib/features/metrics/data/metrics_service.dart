import 'dart:async';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/profile.dart';
import '../../metrics/domain/metric_event.dart';

/// Records local usage counters and answers the metric queries in
/// `docs/METRICS.md` §2.
///
/// Design rules, all load-bearing:
///
/// 1. **Nothing is ever transmitted from this class.** Writing a row is local
///    and reversible; sending is a separate, opt-in decision (P0.5) that must
///    go through an aggregator which strips identifiers.
/// 2. **Recording must never break the feature it is observing.** Every public
///    `record*` method swallows its own failures. A metrics bug that took a
///    document open down with it would be a worse outcome than the missing
///    number, and the plan's byte-safety invariants outrank telemetry.
/// 3. **Content cannot be passed in.** Enforced by [validateMetricContext] and
///    [validateMetricId] rather than by review, so a later caller cannot
///    regress the privacy contract by accident. Those validators throw; the
///    `record*` wrappers convert that into a dropped row.
class MetricsService {
  final AppDatabase _db;
  final String workspaceId;

  /// Injectable clock so latency is testable without racing a stopwatch.
  final DateTime Function() _now;

  MetricsService({
    required this._db,
    String? workspaceId,
    DateTime Function()? clock,
  })  : workspaceId = workspaceId ?? kPersonalWorkspaceId,
        _now = clock ?? DateTime.now;

  static const _uuid = Uuid();

  /// Stable for the life of the process. Groups search → open pairs for M2.
  final String sessionId = _uuid.v4();

  /// When the most recent search produced results, and how many. Used both to
  /// compute time-to-open and to detect an abandoned search when the user
  /// fires a new query without opening anything.
  DateTime? _lastSearchCompletedAt;
  int _lastSearchResultCount = 0;

  /// Off unless the user enabled reporting (P0.5). Controls only the
  /// `pending_report` flag; this class never sends anything either way.
  bool reportingEnabled = false;

  // ------------------------------------------------------------- recording

  Future<void> recordSessionStart() => _guard(() async {
        await _insert(_row(event: MetricEvent.sessionStart));
      });

  /// A search produced [resultCount] rows in [latencyMs].
  Future<void> recordSearchExecuted({
    required MetricSource source,
    required int resultCount,
    required int latencyMs,
  }) =>
      _guard(() async {
        // An unanswered previous search is an abandonment, per
        // docs/METRICS.md §2 M2.
        if (_lastSearchCompletedAt != null && _lastSearchResultCount > 0) {
          await _insert(_row(
            event: MetricEvent.searchAbandoned,
            contextTokens: [source.value],
            countValue: _lastSearchResultCount,
          ));
        }
        _lastSearchCompletedAt = _now();
        _lastSearchResultCount = resultCount;

        await _insert(_row(
          event: MetricEvent.searchExecuted,
          contextTokens: [source.value],
          latencyMs: latencyMs,
          countValue: resultCount,
        ));
      });

  /// A filter change or browse that ran a query with no text in it. Recorded
  /// as `search_executed` with `result_count` set and no latency claim.
  Future<void> recordFilterApplied({
    required MetricSource source,
    required int resultCount,
    int latencyMs = 0,
  }) =>
      recordSearchExecuted(
        source: source,
        resultCount: resultCount,
        latencyMs: latencyMs,
      );

  Future<void> recordDocumentOpened({
    required String mimeType,
    required MetricSource source,
    required bool localAvailable,
    String? documentId,
  }) =>
      _guard(() async {
        int? timeToOpenMs;
        if (_lastSearchCompletedAt != null) {
          final elapsed = _now().difference(_lastSearchCompletedAt!).inMilliseconds;
          timeToOpenMs = elapsed < 0 ? 0 : elapsed;
          // Answered: this search led somewhere, so it is not an abandonment.
          _lastSearchCompletedAt = null;
          _lastSearchResultCount = 0;
        }

        await _insert(_row(
          event: MetricEvent.documentOpened,
          documentId: documentId,
          latencyMs: timeToOpenMs,
          contextTokens: [
            source.value,
            MimeFamily.fromMimeType(mimeType).value,
            (localAvailable ? Availability.local : Availability.remoteOnly)
                .value,
          ],
        ));
      });

  Future<void> recordDuplicateDetected({required DuplicateAction action}) =>
      _guard(() async {
        await _insert(_row(
          event: MetricEvent.duplicateDetected,
          contextTokens: [action.value],
        ));
      });

  /// [daysSinceCreated] is an integer rather than a timestamp, so the "edited
  /// within 7 days" rule in M3 is computable without storing when a document
  /// was created.
  Future<void> recordMetadataEdited({
    required EditedField field,
    required int daysSinceCreated,
    String? documentId,
  }) =>
      _guard(() async {
        await _insert(_row(
          event: MetricEvent.metadataEdited,
          documentId: documentId,
          countValue: daysSinceCreated < 0 ? 0 : daysSinceCreated,
          contextTokens: [field.value],
        ));
      });

  Future<void> recordIntegrityFinding({
    required IntegrityKind kind,
    String? documentId,
  }) =>
      _guard(() async {
        await _insert(_row(
          event: MetricEvent.integrityFinding,
          documentId: documentId,
          contextTokens: [kind.value],
        ));
      });

  /// Opened a version that is not the current one — the
  /// `superseded_version_distributed` error class P1 exists to prevent.
  /// `count_value` is 1 when the version WAS current, so the rate is
  /// computable as 1 - (sum / count).
  Future<void> recordVersionOpened({
    required bool isCurrent,
    String? documentId,
  }) =>
      _guard(() async {
        await _insert(_row(
          event: MetricEvent.versionOpened,
          documentId: documentId,
          countValue: isCurrent ? 1 : 0,
        ));
      });

  Future<void> recordHandoverExported({required int versionCount}) =>
      _guard(() async {
        await _insert(_row(
          event: MetricEvent.handoverExported,
          countValue: versionCount,
        ));
      });

  Future<void> recordError({required MetricErrorCode code}) =>
      _guard(() async {
        await _insert(_row(
          event: MetricEvent.errorShown,
          contextTokens: [code.value],
        ));
      });

  // --------------------------------------------------------------- queries

  /// M1 local proxy: distinct calendar days with any recorded activity.
  ///
  /// MEASURED, NOT ASSUMED: this Drift mapping stores a `DateTimeColumn` as
  /// **seconds since epoch** (`typeof(occurred_at) = integer`,
  /// `occurred_at = 1792661400` for 2026-10-22T09:30Z). So the correct
  /// expression is `DATE(occurred_at, 'unixepoch')`. Both alternatives were
  /// tried and are wrong: `DATE(occurred_at)` returns NULL because SQLite
  /// reads the integer as a Julian day number, and
  /// `DATE(occurred_at / 1000, 'unixepoch')` silently returns 1970-01-21 for
  /// every row — which is how a whole-group rollup collapsed to `1`.
  ///
  /// Range predicates stay safe because `Variable.withDateTime` serialises
  /// with the same mapping; only the raw date function needs the unit.
  Future<int> daysActive30d() async {
    final rows = await _db.customSelect(
      'SELECT COUNT(DISTINCT DATE(occurred_at, \'unixepoch\')) AS days '
      'FROM usage_counters '
      'WHERE occurred_at >= ? AND workspace_id = ?',
      variables: [
        Variable.withDateTime(_since(30)),
        Variable.withString(workspaceId),
      ],
    ).get();
    return (rows.first.data['days'] as int?) ?? 0;
  }

  /// M2: median milliseconds from a completed search to the open it produced.
  /// `document_opened.latency_ms` is populated only when a search preceded it.
  Future<int?> medianTimeToOpen30d() => _medianOf(
        event: MetricEvent.documentOpened,
        requireLatency: true,
      );

  /// M2 supporting figure: median query latency as measured by the DB layer.
  Future<int?> medianSearchLatency30d() => _medianOf(
        event: MetricEvent.searchExecuted,
        requireLatency: false,
      );

  /// M3: per-event counts. Reported per category and never blended into one
  /// number — docs/METRICS.md §2 M3 explains why a blended figure is
  /// unfalsifiable.
  Future<Map<MetricEvent, int>> eventCounts30d() async {
    final rows = await _db.customSelect(
      'SELECT event, COUNT(*) AS c FROM usage_counters '
      'WHERE occurred_at >= ? AND workspace_id = ? GROUP BY event',
      variables: [
        Variable.withDateTime(_since(30)),
        Variable.withString(workspaceId),
      ],
    ).get();
    final byName = {for (final e in MetricEvent.values) e.value: e};
    final result = <MetricEvent, int>{};
    for (final row in rows) {
      final event = byName[row.data['event'] as String?];
      if (event != null) {
        result[event] = (row.data['c'] as int?) ?? 0;
      }
    }
    return result;
  }

  /// Rows recorded **for this profile**. Scoped by workspace on purpose:
  /// a second profile's counters must never appear in this view, and P2.5
  /// profile partitioning depends on every query honouring the scope.
  Future<int> totalRows() => _count(
        'SELECT COUNT(*) AS c FROM usage_counters WHERE workspace_id = ?',
        [Variable.withString(workspaceId)],
      );

  /// Counterpart of [totalRows] for the "nothing leaves the device" assertion:
  /// stays 0 on a default install, because `pending_report` is only ever set
  /// when the user opted in.
  Future<int> pendingReportRows() => _count(
        'SELECT COUNT(*) AS c FROM usage_counters '
        'WHERE pending_report = 1 AND workspace_id = ?',
        [Variable.withString(workspaceId)],
      );

  /// Bounded retention sweep. Counters are cheap but unbounded growth is the
  /// N3 risk in the plan; 180 days keeps every 30-day window comparable while
  /// leaving a season of history for trend review.
  Future<int> pruneOlderThanDays(int days) {
    final cutoff = _since(days);
    return (_db.delete(_db.usageCounters)
          ..where((t) => t.occurredAt.isSmallerThanValue(cutoff)))
        .go();
  }

  // -------------------------------------------------------------- internals

  DateTime _since(int days) => _now().subtract(Duration(days: days));

  Future<int> _count(String sql, [List<Variable> vars = const []]) async {
    final rows = await _db.customSelect(sql, variables: vars).get();
    return (rows.first.data['c'] as int?) ?? 0;
  }

  Future<int?> _medianOf({
    required MetricEvent event,
    required bool requireLatency,
  }) async {
    final where = requireLatency
        ? 'event = ? AND latency_ms IS NOT NULL AND occurred_at >= ? AND workspace_id = ?'
        : 'event = ? AND occurred_at >= ? AND workspace_id = ?';
    final rows = await _db.customSelect(
      'SELECT latency_ms FROM usage_counters WHERE $where ORDER BY latency_ms',
      variables: [
        Variable.withString(event.value),
        Variable.withDateTime(_since(30)),
        Variable.withString(workspaceId),
      ],
    ).get();
    final values = rows
        .map((r) => r.data['latency_ms'] as int?)
        .whereType<int>()
        .toList();
    if (values.isEmpty) return null;
    return values[values.length ~/ 2];
  }

  /// Builds a row. Validation happens here, before any write, so an
  /// out-of-vocabulary value can never reach the table.
  UsageCountersCompanion _row({
    required MetricEvent event,
    List<String> contextTokens = const [],
    String? documentId,
    int? latencyMs,
    int? countValue,
  }) {
    final context = validateMetricContext(contextTokens);
    return UsageCountersCompanion.insert(
      id: _uuid.v4(),
      event: event.value,
      occurredAt: _now(),
      workspaceId: Value(workspaceId),
      sessionId: Value(sessionId),
      documentId: Value(validateMetricId(documentId, 'documentId')),
      // Latency is only ever an integer this class computed, never UI text; a
      // negative value means a clock adjustment, so clamp rather than store it.
      latencyMs: Value(latencyMs == null ? null : (latencyMs < 0 ? 0 : latencyMs)),
      countValue: Value(countValue),
      context: Value(context.isEmpty ? null : context),
      pendingReport: Value(reportingEnabled),
    );
  }

  Future<void> _insert(UsageCountersCompanion row) =>
      _db.into(_db.usageCounters).insert(row);

  /// Runs [action] and discards failures. Telemetry observes the app; it must
  /// never be able to break it — including the contract-violation path, which
  /// is a programming error to be caught in `p0_metrics_test.dart`, not a
  /// runtime exception to be shown to a user.
  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      // InvalidMetricException, disk full, DB busy, closed database during
      // test teardown. Deliberately silent.
    }
  }
}


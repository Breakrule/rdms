import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/documents/presentation/providers/database_providers.dart';
import '../data/metrics_service.dart';
import '../domain/metric_event.dart';

/// Resolves the local metrics service.
///
/// Deliberately a plain [Provider] that is only ever reached with
/// `ref.read(...)` at an interaction site — never watched from a `build()`
/// method. Watching it would put a database-backed dependency into the home
/// screen's build path, which `test/homepage_redesign_test.dart` builds while
/// overriding only the document stream. `metricsServiceProvider` itself is
/// cheap to construct (Drift's executor opens lazily), but keeping the access
/// pattern explicit avoids that class of surprise entirely.
final metricsServiceProvider = Provider<MetricsService>((ref) {
  final service = MetricsService(db: ref.watch(databaseProvider));
  return service;
});

/// Everything Ringkasan Produktivitas renders, resolved in one pass so the
/// screen has a single async state instead of six independent spinners.
///
/// A null figure means "not enough data yet", which the screen must say out
/// loud rather than render as 0 — a zero reads as "you are slow", when the
/// truth is "nothing has been measured".
final productivitySummaryProvider =
    FutureProvider<ProductivitySummary>((ref) async {
  final metrics = ref.watch(metricsServiceProvider);
  final counts = await metrics.eventCounts30d();
  return ProductivitySummary(
    daysActive: await metrics.daysActive30d(),
    medianTimeToOpenMs: await metrics.medianTimeToOpen30d(),
    medianSearchLatencyMs: await metrics.medianSearchLatency30d(),
    searches: counts[MetricEvent.searchExecuted] ?? 0,
    abandonedSearches: counts[MetricEvent.searchAbandoned] ?? 0,
    openedDocuments: counts[MetricEvent.documentOpened] ?? 0,
    duplicatesDetected: counts[MetricEvent.duplicateDetected] ?? 0,
    integrityFindings: counts[MetricEvent.integrityFinding] ?? 0,
    metadataEdits: counts[MetricEvent.metadataEdited] ?? 0,
    rowsStored: await metrics.totalRows(),
    pendingReportRows: await metrics.pendingReportRows(),
  );
});

/// The 30-day local window. Immutable value passed to the summary screen.
class ProductivitySummary {
  final int daysActive;
  final int? medianTimeToOpenMs;
  final int? medianSearchLatencyMs;
  final int searches;
  final int abandonedSearches;
  final int openedDocuments;
  final int duplicatesDetected;
  final int integrityFindings;
  final int metadataEdits;
  final int rowsStored;
  final int pendingReportRows;

  const ProductivitySummary({
    required this.daysActive,
    required this.medianTimeToOpenMs,
    required this.medianSearchLatencyMs,
    required this.searches,
    required this.abandonedSearches,
    required this.openedDocuments,
    required this.duplicatesDetected,
    required this.integrityFindings,
    required this.metadataEdits,
    required this.rowsStored,
    required this.pendingReportRows,
  });

  /// Percentage of searches that led somewhere. Falls back to null when there
  /// is no search yet — again, "unknown" and "0 %" are different statements.
  double? get searchSuccessRate => searches == 0
      ? null
      : ((searches - abandonedSearches) / searches).clamp(0.0, 1.0);

  static const ProductivitySummary empty = ProductivitySummary(
    daysActive: 0,
    medianTimeToOpenMs: null,
    medianSearchLatencyMs: null,
    searches: 0,
    abandonedSearches: 0,
    openedDocuments: 0,
    duplicatesDetected: 0,
    integrityFindings: 0,
    metadataEdits: 0,
    rowsStored: 0,
    pendingReportRows: 0,
  );
}

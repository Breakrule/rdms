// The application's metric call sites, gathered in one place.
//
// Centralising them here (rather than scattering `ref.read(metricsProvider)`
// through widgets) keeps `docs/METRICS.md` §4.2 honest: this file IS the list
// of what is measured. Anything not here is not measured, and the gap is
// visible instead of implied.
//
// Every function is fire-and-forget. None of them await the write, because an
// interaction handler should not carry database latency for telemetry's
// benefit — MetricsService already swallows its own failures.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/documents/domain/models/document_item.dart';
import '../../documents/presentation/widgets/duplicate_check_dialog.dart';
import '../domain/metric_event.dart';
import '../presentation/metrics_providers.dart';

/// A search ran and returned [resultCount] rows in [latencyMs].
void emitSearchExecuted(
  WidgetRef ref, {
  required MetricSource source,
  required int resultCount,
  required int latencyMs,
}) {
  ref.read(metricsServiceProvider).recordSearchExecuted(
        source: source,
        resultCount: resultCount,
        latencyMs: latencyMs,
      );
}

/// The user opened a document. [localAvailable] must be passed in by the
/// caller rather than probed here: an emitter that does file IO would put
/// storage latency into the click handler.
void emitDocumentOpened(
  WidgetRef ref,
  DocumentItem doc, {
  MetricSource source = MetricSource.list,
  bool? localAvailable,
}) {
  ref.read(metricsServiceProvider).recordDocumentOpened(
        mimeType: doc.mimeType,
        source: source,
        localAvailable: localAvailable ?? true,
        documentId: doc.id,
      );
}

/// The duplicate check (Phase 4.5) hit and the user decided. `keep_separate`
/// is the `duplicate_filed` error class in docs/METRICS.md §2 M3; `cancel` is
/// the check doing its job.
void emitDuplicateDecision(WidgetRef ref, DuplicateChoice? choice) {
  final action = switch (choice) {
    DuplicateChoice.keepSeparate => DuplicateAction.keepSeparate,
    DuplicateChoice.cancel => DuplicateAction.cancel,
    null => DuplicateAction.cancel,
  };
  ref.read(metricsServiceProvider).recordDuplicateDetected(action: action);
}

/// Metadata was saved. [daysSinceCreated] drives the `misfiled` rule
/// (category/classification corrected within 7 days of import).
void emitMetadataEdited(
  WidgetRef ref, {
  required DocumentItem document,
  required List<EditedField> fields,
}) {
  final days = DateTime.now().difference(document.createdAt).inDays;
  final metrics = ref.read(metricsServiceProvider);
  for (final field in fields) {
    metrics.recordMetadataEdited(
      field: field,
      daysSinceCreated: days,
      documentId: document.id,
    );
  }
}

/// An integrity sweep reported findings (the `document_lost` error class).
void emitIntegrityFindings(WidgetRef ref, {required int missing, required int changed}) {
  final metrics = ref.read(metricsServiceProvider);
  if (missing > 0) {
    metrics.recordIntegrityFinding(kind: IntegrityKind.missing);
  }
  if (changed > 0) {
    metrics.recordIntegrityFinding(kind: IntegrityKind.changed);
  }
}

/// A user-visible failure occurred. Only a bounded code is recorded — never
/// the exception message, which in this app routinely contains file paths.
void emitError(WidgetRef ref, MetricErrorCode code) {
  ref.read(metricsServiceProvider).recordError(code: code);
}

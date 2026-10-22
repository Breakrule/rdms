import 'package:drift/drift.dart';

/// Local usage counters (Rev. 2 Phase P0.3).
///
/// Rows are written on the device and read back to compute the PRD's success
/// metrics for the person holding it — see `docs/METRICS.md`. There is no
/// server counterpart in P0–P6: reporting is opt-in (P0.5) and off by default,
/// so this table is the only place this data exists.
///
/// PRIVACY CONTRACT — `usage_counters` must never be able to hold document
/// content. It is enforced structurally rather than by convention: every
/// column here is either an identifier, a timestamp, an integer, or a bounded
/// enum string produced by `features/metrics/domain/metric_event.dart`. There
/// is no free-text column for a caller to stuff a title, filename, query, or
/// error message into. `client/test/p0_metrics_test.dart` asserts this.
class UsageCounters extends Table {
  TextColumn get id => text()(); // UUID

  /// Owning local profile. Defaults to the personal workspace so a single-user
  /// install never has to supply it; P2.5 profile partitioning relies on this.
  ///
  /// The value is a literal, not `kPersonalWorkspaceId`, because drift_dev
  /// copies this expression into the generated file, which does not import
  /// `core/database/profile.dart`. `p0_metrics_test.dart` asserts the literal
  /// and the constant stay identical, so the duplication cannot silently drift.
  TextColumn get workspaceId =>
      text().withDefault(
        const Constant('00000000-0000-4000-8000-000000000001'),
      )();

  /// `MetricEvent.value` — fixed vocabulary, not a namespace for new strings.
  TextColumn get event => text()();

  DateTimeColumn get occurredAt => dateTime()();

  /// Groups `search_executed` with the following `document_opened` so M2 can
  /// compute time-to-open. Random UUID, stripped before any report leaves
  /// the device.
  TextColumn get sessionId => text().nullable()();

  /// Random document UUID. Local analysis only (e.g. "never opened in 90
  /// days"); MUST be dropped by the aggregator that builds a P0.5 report.
  TextColumn get documentId => text().nullable()();

  /// Query/operation latency in milliseconds.
  IntColumn get latencyMs => integer().nullable()();

  /// Result count, version count, token count — an integer with meaning
  /// given by `event`.
  IntColumn get countValue => integer().nullable()();

  /// A `MetricSource`/`DuplicateAction`/`EditedField`/`IntegrityKind`/
  /// `MetricErrorCode`/`MimeFamily` value. Bounded and enumerated.
  TextColumn get context => text().nullable()();

  /// Set only while the user has opted in to reporting. Nothing is sent
  /// unless this is true AND the opt-in switch is on.
  BoolColumn get pendingReport =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

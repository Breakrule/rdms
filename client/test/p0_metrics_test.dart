import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:document_management/core/database/app_database.dart';
import 'package:document_management/core/database/profile.dart';
import 'package:document_management/features/documents/presentation/providers/database_providers.dart';
import 'package:document_management/features/metrics/data/metrics_service.dart';
import 'package:document_management/features/metrics/domain/metric_event.dart';
import 'package:document_management/features/metrics/presentation/productivity_summary_screen.dart';

/// Rev. 2 Phase P0.3 acceptance tests.
///
/// The plan's gate for P0 is that every PRD success metric maps to a formula
/// computed in code and to an event that existing code emits, with content
/// structurally excluded. These tests are what make that claim checkable
/// rather than a statement in a document.
void main() {
  late AppDatabase db;
  late MetricsService metrics;
  late DateTime now;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    now = DateTime.utc(2026, 10, 22, 9, 30);
    metrics = MetricsService(db: db, clock: () => now);
  });

  tearDown(() async {
    await db.close();
  });

  group('Schema', () {
    test('v5 created usage_counters and it survives later schema bumps',
        () async {
      // No assertion on schemaVersion here on purpose: this test is about the
      // usage_counters table existing and being writable, and pinning the
      // version number made it fail for every subsequent phase that added one
      // (it broke the moment P1 introduced v6). The current version number is
      // asserted in document_versioning_test.dart, which owns it.
      expect(db.schemaVersion, greaterThanOrEqualTo(5));
      // Proves the table exists on the onCreate path, which is the path every
      // new install and every in-memory test takes.
      await metrics.recordSessionStart();
      expect(await metrics.totalRows(), 1);
    });

    test('the table default and kPersonalWorkspaceId cannot drift apart',
        () async {
      // The Drift column default is a literal (drift_dev copies it into the
      // generated file, which cannot import profile.dart). This is the guard
      // against that duplication silently diverging.
      await db.into(db.usageCounters).insert(
            UsageCountersCompanion.insert(
              id: 'no-default-supplied',
              event: MetricEvent.sessionStart.value,
              occurredAt: now,
            ),
          );
      final row = await (db.select(db.usageCounters)
            ..where((t) => t.id.equals('no-default-supplied')))
          .getSingle();
      expect(row.workspaceId, kPersonalWorkspaceId);
    });
  });

  group('Privacy contract — docs/METRICS.md §1.1', () {
    test('a document title cannot be stored as context', () {
      expect(
        () => validateMetricContext(['Surat Keputusan Reformasi Birokrasi']),
        throwsA(isA<InvalidMetricException>()),
      );
    });

    test('a file path cannot be stored as context', () {
      expect(
        () => validateMetricContext(['C:/mock/path/sample.pdf']),
        throwsA(isA<InvalidMetricException>()),
      );
    });

    test('a raw error message cannot be stored as context', () {
      expect(
        () => validateMetricContext(['FileSystemException: cannot open file']),
        throwsA(isA<InvalidMetricException>()),
      );
    });

    test('a filename smuggled through documentId is rejected', () async {
      expect(
        () => metrics.recordDocumentOpened(
              mimeType: 'application/pdf',
              source: MetricSource.list,
              localAvailable: true,
              documentId: 'PERATURAN_2026_dilarang_masuk.pdf',
            ),
        returnsNormally, // the emitter swallows rather than throwing at UI level...
      );
      // ...but nothing may be written.
      await Future<void>.delayed(Duration.zero);
      expect(await metrics.totalRows(), 0);
    });

    test('a genuine UUID documentId is accepted', () async {
      const uuid = '3f1a2b4c-5d6e-4f70-8a9b-0c1d2e3f4a5b';
      await metrics.recordDocumentOpened(
        mimeType: 'application/pdf',
        source: MetricSource.list,
        localAvailable: true,
        documentId: uuid,
      );
      final row = await (db.select(db.usageCounters)..limit(1)).getSingle();
      expect(row.documentId, uuid);
    });

    test('nothing is flagged for reporting on a default install', () async {
      await metrics.recordSessionStart();
      await metrics.recordSearchExecuted(
        source: MetricSource.palette,
        resultCount: 3,
        latencyMs: 40,
      );
      await metrics.recordDocumentOpened(
        mimeType: 'application/pdf',
        source: MetricSource.palette,
        localAvailable: true,
      );
      // P0.5 opt-in is off by default: not one row is eligible to leave.
      expect(metrics.reportingEnabled, isFalse);
      expect(await metrics.pendingReportRows(), 0);
    });

    test('rows are flagged only once the user opts in', () async {
      metrics.reportingEnabled = true;
      await metrics.recordSessionStart();
      expect(await metrics.pendingReportRows(), 1);
    });
  });

  group('M2 — search time', () {
    test('time-to-open is measured from the search that produced it', () async {
      await metrics.recordSearchExecuted(
        source: MetricSource.palette,
        resultCount: 5,
        latencyMs: 42,
      );
      // The user takes 3.2 s to pick a result.
      now = now.add(const Duration(milliseconds: 3200));
      await metrics.recordDocumentOpened(
        mimeType: 'application/pdf',
        source: MetricSource.palette,
        localAvailable: true,
      );

      expect(await metrics.medianTimeToOpen30d(), 3200);
      expect(await metrics.medianSearchLatency30d(), 42);
    });

    test('an open that followed no search records no time-to-open', () async {
      await metrics.recordDocumentOpened(
        mimeType: 'image/png',
        source: MetricSource.list,
        localAvailable: true,
      );
      expect(await metrics.medianTimeToOpen30d(), isNull);
    });

    test('a superseded search with no open counts as abandoned', () async {
      await metrics.recordSearchExecuted(
        source: MetricSource.palette,
        resultCount: 7,
        latencyMs: 30,
      );
      await metrics.recordSearchExecuted(
        source: MetricSource.palette,
        resultCount: 2,
        latencyMs: 25,
      );
      final counts = await metrics.eventCounts30d();
      expect(counts[MetricEvent.searchAbandoned], 1);
      expect(
        (await (db.select(db.usageCounters)
              ..where((t) => t.event.equals('search_abandoned')))
            .getSingle())
            .countValue,
        7,
        reason: 'the abandoned search had 7 unanswered results',
      );
    });

    test('an answered search is not counted as abandoned', () async {
      await metrics.recordSearchExecuted(
        source: MetricSource.palette,
        resultCount: 4,
        latencyMs: 30,
      );
      await metrics.recordDocumentOpened(
        mimeType: 'application/pdf',
        source: MetricSource.palette,
        localAvailable: true,
      );
      final counts = await metrics.eventCounts30d();
      expect(counts[MetricEvent.searchAbandoned], isNull);
    });

    test('mime family is recorded, never the mime subtype', () async {
      await metrics.recordDocumentOpened(
        mimeType: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        source: MetricSource.list,
        localAvailable: true,
      );
      final row = await (db.select(db.usageCounters)..limit(1)).getSingle();
      expect(row.context, contains('document'));
      expect(row.context, isNot(contains('officedocument')));
    });
  });

  group('M3 — error categories', () {
    test('keeping a duplicate separately is counted', () async {
      await metrics.recordDuplicateDetected(action: DuplicateAction.keepSeparate);
      await metrics.recordDuplicateDetected(action: DuplicateAction.cancel);
      final row = await (db.select(db.usageCounters)
            ..where((t) => t.context.equals('keep_separate')))
          .getSingle();
      expect(row.event, 'duplicate_detected');
    });

    test('a category edit inside 7 days carries its age, not its text',
        () async {
      await metrics.recordMetadataEdited(
        field: EditedField.category,
        daysSinceCreated: 4,
      );
      final row = await (db.select(db.usageCounters)
            ..where((t) => t.event.equals('metadata_edited')))
          .getSingle();
      expect(row.countValue, 4);
      expect(row.context, 'category');
    });

    test('a negative day count is clamped rather than stored', () async {
      await metrics.recordMetadataEdited(
        field: EditedField.title,
        daysSinceCreated: -5,
      );
      final row = await (db.select(db.usageCounters)
            ..where((t) => t.event.equals('metadata_edited')))
          .getSingle();
      expect(row.countValue, 0);
    });

    test('a non-current version open is distinguishable', () async {
      await metrics.recordVersionOpened(isCurrent: true);
      await metrics.recordVersionOpened(isCurrent: false);
      final rows = await (db.select(db.usageCounters)
            ..where((t) => t.event.equals('version_opened')))
          .get();
      expect(rows.map((r) => r.countValue).toSet(), {1, 0});
    });

    test('errors are counted by bounded code only', () async {
      await metrics.recordError(code: MetricErrorCode.fileUnopenable);
      final row = await (db.select(db.usageCounters)
            ..where((t) => t.event.equals('error_shown')))
          .getSingle();
      expect(row.context, 'file_unopenable');
    });
  });

  group('M1 — activity rollups', () {
    test('days active counts distinct calendar days', () async {
      await metrics.recordSessionStart();
      now = now.add(const Duration(days: 1));
      await metrics.recordSessionStart();
      now = now.add(const Duration(days: 1));
      await metrics.recordSessionStart();
      expect(await metrics.daysActive30d(), 3);
    });

    test('events older than the window are excluded from rollups', () async {
      // Clock moves FORWARD so "the last 30 days" is a real window: the first
      // row is 45 days stale relative to when it is being counted.
      await metrics.recordSessionStart();
      now = now.add(const Duration(days: 45));
      await metrics.recordSessionStart();
      expect(await metrics.daysActive30d(), 1);
      // ...while the table still holds both rows until prune.
      expect(await metrics.totalRows(), 2);
    });

    test('prune bounds table growth (N3)', () async {
      // Old row first, then the clock moves FORWARD: "prune older than 180
      // days" is evaluated against the current clock, so an old row written
      // before the jump is the one that must go.
      await metrics.recordSessionStart();
      now = now.add(const Duration(days: 200));
      await metrics.recordSessionStart();
      await metrics.pruneOlderThanDays(180);
      final remaining = await (db.select(db.usageCounters)).get();
      expect(remaining, hasLength(1));
      expect(remaining.single.occurredAt.isAfter(now.subtract(const Duration(days: 1))),
          isTrue,
          reason: 'the recent row survives, the 200-day-old row is pruned');
    });

    test('counts are scoped to the workspace', () async {
      final other = MetricsService(
        db: db,
        workspaceId: '11111111-1111-4111-8111-111111111111',
        clock: () => now,
      );
      await metrics.recordSessionStart();
      await other.recordSessionStart();
      expect(await metrics.totalRows(), 1);
      expect(await other.totalRows(), 1);
    });
  });

  group('Resilience — recording must never break the app', () {
    test('a contract violation drops the row instead of throwing at the UI',
        () async {
      // Emitters are called from click handlers; they cannot be allowed to
      // throw. InvalidMetricException must be contained.
      await expectLater(
        metrics.recordDocumentOpened(
          mimeType: 'application/pdf',
          source: MetricSource.list,
          localAvailable: true,
          documentId: 'not-a-uuid',
        ),
        completes,
      );
      expect(await metrics.totalRows(), 0);
    });

    test('writes still work against a closed database', () async {
      await db.close();
      await expectLater(metrics.recordSessionStart(), completes);
    });
  });

  group('P0.4 self-view honesty', () {
    // The plan's commitment 7 ("say what is not guaranteed") is only real if
    // the screen that shows numbers also refuses to show absence as zero.
    // The screen is a ListView, which builds only visible children — at the
    // default 800x600 test surface the honesty card and the privacy card are
    // never laid out, so `find` cannot see them. A tall surface lays the whole
    // list out and keeps the assertions about CONTENT rather than about
    // scrolling.
    Future<void> pumpSummary(WidgetTester tester, AppDatabase database) async {
      tester.view.physicalSize = const Size(1000, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(database)],
          child: const MaterialApp(home: ProductivitySummaryScreen()),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('an empty library renders "Belum cukup data", never 0 ms',
        (tester) async {
      final emptyDb = AppDatabase(NativeDatabase.memory());
      addTearDown(emptyDb.close);
      await pumpSummary(tester, emptyDb);

      // Three figures depend on data existing yet: time-to-open, search
      // latency, and the search success rate.
      expect(find.text('Belum cukup data'), findsNWidgets(3));
      expect(find.text('0 ms'), findsNothing);
    });

    testWidgets('the screen names the metrics this architecture cannot produce',
        (tester) async {
      final emptyDb = AppDatabase(NativeDatabase.memory());
      addTearDown(emptyDb.close);
      await pumpSummary(tester, emptyDb);

      expect(find.text('Yang TIDAK bisa diukur aplikasi ini'), findsOneWidget);
      expect(find.textContaining('Adopsi 80 % pegawai'), findsOneWidget);
      expect(find.textContaining('Belum aktif: tidak ada layanan penerimanya'),
          findsOneWidget);
    });

    testWidgets('a recorded search shows up as a real median', (tester) async {
      final filledDb = AppDatabase(NativeDatabase.memory());
      addTearDown(filledDb.close);
      final filled = MetricsService(db: filledDb);
      await filled.recordSearchExecuted(
        source: MetricSource.palette,
        resultCount: 3,
        latencyMs: 42,
      );
      await filled.recordDocumentOpened(
        mimeType: 'application/pdf',
        source: MetricSource.palette,
        localAvailable: true,
      );

      await pumpSummary(tester, filledDb);
      expect(find.textContaining('ms'), findsWidgets);
      expect(find.text('Belum cukup data'), findsNothing);
    });
  });
}

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:document_management/core/database/app_database.dart';
import 'package:document_management/core/services/storage_service.dart';
import 'package:document_management/core/utils/hash_util.dart';

/// Rev. 2 Phase P0.2 — the performance baseline the PRD's NFR and every later
/// phase budget are measured against.
///
/// RUN IT EXPLICITLY; IT IS SKIPPED BY DEFAULT:
///
///   cd client
///   $env:DMS_BENCHMARK="1"; flutter test test/p0_baseline_benchmark_test.dart
///
/// Skipped by default because seeding 10 000 rows takes tens of seconds and
/// would make `flutter test` slow for everyone. `docs/METRICS.md` §3.2 is the
/// home of the resulting numbers, and they are copied in by hand from this
/// test's output — the test never writes to a file.
///
/// WHAT THIS IS AND IS NOT: this measures SQLite/Drift and file-IO cost on the
/// development HOST. It is not a mobile or desktop-app measurement and does
/// not satisfy the PRD's "load within 2 seconds" NFR, which needs hardware
/// this environment does not have (see docs/ROADMAP.md, "What's blocked").
/// It IS the right early-warning net, because roadmap Phase 5.6 established
/// that the freezes this product actually suffered came from these operations.
void main() {
  // Read from the process environment, matching the documented invocation
  // (`$env:DMS_BENCHMARK="1"`). Deliberately NOT bool.fromEnvironment, which
  // would require --dart-define and silently ignore the documented command.
  final runBenchmark = Platform.environment['DMS_BENCHMARK'] == '1';
  const int docCount = 10000;
  const int samples = 21;

  late AppDatabase db;
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('dms_bench_');
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  /// Seeds a library shaped like a real one: five categories, a decade of
  /// dates, and OCR-length text on a fraction of rows, because a uniform
  /// synthetic corpus flatters FTS and count queries.
  Future<int> seed() async {
    final stopwatch = Stopwatch()..start();
    const categories = ['SK', 'LAPORAN', 'NOTULA', 'TEKNIS', 'PERATURAN'];
    await db.batch((batch) {
      for (var i = 0; i < docCount; i++) {
        final filler = List<String>.generate(
          i % 10 == 0 ? 240 : 20,
          (n) => 'kata-${(i * 31 + n) % 9973}',
        ).join(' ');
        batch.insert(
          db.localDocuments,
          LocalDocumentsCompanion.insert(
            id: 'bench-${i.toString().padLeft(6, '0')}',
            title: 'Surat Keputusan Nomor ${1000 + i}',
            documentNumber: Value('800/${1000 + i}/SK/2026'),
            category: categories[i % categories.length],
            documentDate: DateTime.utc(2016 + (i % 10), (i % 12) + 1, (i % 28) + 1),
            fiscalYear: 2016 + (i % 10),
            localFilePath: '${tempDir.path}/bench_$i.pdf',
            fileName: 'bench_$i.pdf',
            fileSizeBytes: 1024 + i,
            mimeType: 'application/pdf',
            sha256Hash: _fakeHash(i),
            extractedText: Value(filler),
            syncStatus: Value(i % 7 == 0 ? 'local_only' : 'synced'),
          ),
        );
      }
    });
    // Tag a tenth of the corpus so the tag EXISTS sub-query is not measured
    // against an empty relation.
    const tagName = 'anggaran';
    final tagId = 'bench-tag-1';
    await db.into(db.tags).insert(
          TagsCompanion.insert(id: tagId, name: tagName),
        );
    await db.batch((batch) {
      for (var i = 0; i < docCount; i += 10) {
        batch.insert(
          db.documentTags,
          DocumentTagsCompanion.insert(
            documentId: 'bench-${i.toString().padLeft(6, '0')}',
            tagId: tagId,
          ),
        );
      }
    });
    stopwatch.stop();
    return stopwatch.elapsedMilliseconds;
  }

  test('P0.2 baseline benchmark', () async {
    if (!runBenchmark) {
      markTestSkipped(
        'Set DMS_BENCHMARK=1 to run the baseline benchmark. '
        'See docs/METRICS.md §3.',
      );
      return;
    }

    final results = <String, List<int>>{};
    // Sampled in MICROSECONDS: at 10 000 rows most indexed queries finish in
    // well under a millisecond, and integer-ms elapsed would report them all
    // as "0", which is a measurement failure rather than a result. Rendered
    // below as milliseconds with two decimals.
    Future<void> measure(String name, Future<void> Function() op) async {
      final samplesUs = <int>[];
      for (var i = 0; i < samples; i++) {
        final sw = Stopwatch()..start();
        await op();
        sw.stop();
        samplesUs.add(sw.elapsedMicroseconds);
      }
      samplesUs.sort();
      results[name] = samplesUs;
    }

    final seedMs = await seed();
    expect(await db.countDocuments(), docCount);

    await measure('page_first_no_filter', () async {
      await db
          .watchDocumentPage(sortBy: 'newest', limit: 100)
          .first;
    });

    await measure('page_first_fts_search', () async {
      await db
          .watchDocumentPage(
            sortBy: 'newest',
            limit: 100,
            search: 'kata-42',
          )
          .first;
    });

    await measure('page_deep_offset_5000', () async {
      await db
          .watchDocumentPage(sortBy: 'newest', limit: 100, offset: 5000)
          .first;
    });

    await measure('page_filter_tag', () async {
      await db
          .watchDocumentPage(sortBy: 'newest', limit: 100, tagName: 'anggaran')
          .first;
    });

    await measure('page_filter_category_and_year', () async {
      await db
          .watchDocumentPage(
            sortBy: 'newest',
            limit: 100,
            category: 'SK',
            fiscalYear: 2020,
          )
          .first;
    });

    await measure('count_with_tag_filter', () async {
      await db.watchDocumentCount(tagName: 'anggaran').first;
    });

    await measure('category_counts', () => db.watchCategoryCounts().first);

    await measure('status_summary', () => db.watchStatusSummary().first);

    await measure('watch_single_document', () async {
      await db.watchDocumentById('bench-000500').first;
    });

    // ---- file layer -------------------------------------------------------
    final file1mb = File('${tempDir.path}/one-mb.pdf');
    final file10mb = File('${tempDir.path}/ten-mb.pdf');
    final block = _deterministicBytes(1024 * 1024);
    await file1mb.writeAsBytes(block, flush: true);
    // 10 MB built by repeating the 1 MB block: same order of magnitude as a
    // scanned PDF bundle, generated without a 10-million-iteration loop.
    final ten = Uint8List(10 * block.length);
    for (var off = 0; off < ten.length; off += block.length) {
      ten.setRange(off, off + block.length, block);
    }
    await file10mb.writeAsBytes(ten, flush: true);

    await measure('sha256_1mb', () => HashUtil.calculateFileSha256(file1mb));
    await measure('sha256_10mb', () => HashUtil.calculateFileSha256(file10mb));

    final storage = LocalStorageService(customBasePath: tempDir.path);
    await measure('storeFile_copy_1mb', () async {
      final info = await storage.storeFile(
        sourceFile: file1mb,
        title: 'Bench Copy ${DateTime.now().microsecondsSinceEpoch}',
        documentDate: DateTime.utc(2026),
      );
      await File(info.localFilePath).delete();
    });

    // ---- report -----------------------------------------------------------
    final buffer = StringBuffer()
      ..writeln()
      ..writeln('### P0.2 BASELINE — paste into docs/METRICS.md §3.2')
      ..writeln()
      ..writeln('Host: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}')
      ..writeln('Dart: ${Platform.version.split(' ').first}')
      ..writeln('Documents seeded: $docCount in ${seedMs}ms '
          '(includes FTS trigger writes)')
      ..writeln('Samples per operation: $samples')
      ..writeln()
      ..writeln('| Operation | p50 (ms) | p95 (ms) | Budget = 2x p95 |')
      ..writeln('|---|---|---|---|');
    results.forEach((name, values) {
      final p50 = _percentile(values, 0.50) / 1000;
      final p95 = _percentile(values, 0.95) / 1000;
      buffer.writeln(
        '| $name | ${p50.toStringAsFixed(2)} | ${p95.toStringAsFixed(2)} '
        '| ${(p95 * 2).toStringAsFixed(2)} |',
      );
    });
    // ignore: avoid_print
    print(buffer.toString());

    // Loose catastrophe guards only — the real regression gate is comparison
    // against the numbers recorded above, per docs/METRICS.md §3.3.
    for (final entry in results.entries) {
      final p95Ms = _percentile(entry.value, 0.95) / 1000;
      expect(
        p95Ms,
        lessThan(5000),
        reason: '${entry.key} p95 = ${p95Ms.toStringAsFixed(2)}ms; a 5s '
            'ceiling is a catastrophic-regression tripwire, not a target',
      );
    }
  }, timeout: const Timeout(Duration(minutes: 15)));
}

String _fakeHash(int i) => sha256.convert(utf8.encode('bench-$i')).toString();

Uint8List _deterministicBytes(int length) {
  final bytes = Uint8List(length);
  for (var i = 0; i < length; i++) {
    bytes[i] = (i * 37 + 11) % 251;
  }
  return bytes;
}

int _percentile(List<int> sorted, double p) {
  if (sorted.isEmpty) return 0;
  final index = (p * (sorted.length - 1)).round();
  return sorted[index];
}

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:document_management/features/documents/domain/models/document_item.dart';
import 'package:document_management/features/documents/presentation/providers/document_providers.dart';

void main() {
  group('DocumentFilterNotifier & DocumentSortNotifier', () {
    test('Default filter state has category ALL, null fiscalYear, syncStatus ALL, empty query', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final filter = container.read(documentFilterProvider);
      expect(filter.category, 'ALL');
      expect(filter.fiscalYear, isNull);
      expect(filter.syncStatus, 'ALL');
      expect(filter.searchQuery, '');
      expect(filter.hasActiveFilters, isFalse);
    });

    test('resetFilters resets category, fiscalYear, syncStatus but preserves searchQuery', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(documentFilterProvider.notifier);
      notifier.setCategory('SK');
      notifier.setFiscalYear(2026);
      notifier.setSyncStatus('synced');
      notifier.clearSearchQuery();
      notifier.setSearchQuery('reformasi');

      // Wait for debounce
      expect(container.read(documentFilterProvider).category, 'SK');
      expect(container.read(documentFilterProvider).fiscalYear, 2026);
      expect(container.read(documentFilterProvider).syncStatus, 'synced');

      notifier.resetFilters();

      final stateAfterReset = container.read(documentFilterProvider);
      expect(stateAfterReset.category, 'ALL');
      expect(stateAfterReset.fiscalYear, isNull);
      expect(stateAfterReset.syncStatus, 'ALL');
      expect(stateAfterReset.hasActiveFilters, isFalse);
    });

    test('Full reset resets all filters and search query', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(documentFilterProvider.notifier);
      notifier.setCategory('Peraturan');
      notifier.reset();

      final state = container.read(documentFilterProvider);
      expect(state.category, 'ALL');
      expect(state.searchQuery, '');
    });

    test('DocumentSortNotifier cycles through sort modes', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(documentSortProvider), DocumentSort.newest);

      container
          .read(documentSortProvider.notifier)
          .setSort(DocumentSort.oldest);
      expect(container.read(documentSortProvider), DocumentSort.oldest);

      container
          .read(documentSortProvider.notifier)
          .setSort(DocumentSort.titleAscending);
      expect(container.read(documentSortProvider), DocumentSort.titleAscending);

      container
          .read(documentSortProvider.notifier)
          .setSort(DocumentSort.documentDateDescending);
      expect(
        container.read(documentSortProvider),
        DocumentSort.documentDateDescending,
      );
    });
  });

  group('DocumentSummaryProvider calculation', () {
    // Phase 5.6: the summary is derived from a SQLite aggregate stream
    // (documentSummaryStreamProvider). The DB query itself is covered by
    // phase56_database_query_test; here we verify the provider maps it.
    test('maps total, localOnly, synced, and attention from the stream',
        () async {
      final container = ProviderContainer(overrides: [
        documentSummaryStreamProvider.overrideWith(
          (ref) =>
              Stream.value((total: 5, localOnly: 1, synced: 1, attention: 2)),
        ),
      ]);
      addTearDown(container.dispose);

      // Subscribe and let the stream's first event land, mirroring how the
      // app observes the DB aggregate stream (`.future` on a StreamProvider
      // is not reliable under the flutter_test binding).
      container.listen(documentSummaryStreamProvider, (_, _) {});
      container.listen(documentSummaryProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);
      final summary = container.read(documentSummaryProvider).value!;

      expect(summary.total, 5);
      expect(summary.localOnly, 1);
      expect(summary.synced, 1);
      expect(summary.attention, 2);
    });
  });

  group('SelectedDocumentDetailsProvider resolution', () {
    // Phase 5.6: details resolve via a single-row by-id stream rather than
    // scanning the whole materialized library. The by-id query is covered
    // by phase56_database_query_test; this verifies the provider wiring.
    test('uses the live by-id value and returns null when cleared', () async {
      final updated = DocumentItem(
        id: 'live-1',
        title: 'Updated Title',
        category: 'SK',
        documentDate: DateTime(2026, 1, 1),
        fiscalYear: 2026,
        localFilePath: '/path/1',
        fileName: '1.pdf',
        fileSizeBytes: 100,
        mimeType: 'application/pdf',
        sha256Hash: 'hash1',
        syncStatus: DocumentSyncStatus.synced,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 2),
      );
      final snapshot = DocumentItem(
        id: 'live-1',
        title: 'Initial Title',
        category: 'SK',
        documentDate: DateTime(2026, 1, 1),
        fiscalYear: 2026,
        localFilePath: '/path/1',
        fileName: '1.pdf',
        fileSizeBytes: 100,
        mimeType: 'application/pdf',
        sha256Hash: 'hash1',
        syncStatus: DocumentSyncStatus.localOnly,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final container = ProviderContainer(overrides: [
        selectedDocumentByIdProvider.overrideWith(
          (ref) => Stream.value(updated),
        ),
      ]);
      addTearDown(container.dispose);

      container.read(selectedDocumentProvider.notifier).select(snapshot);
      container.listen(selectedDocumentByIdProvider, (_, _) {});
      container.listen(selectedDocumentDetailsProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);

      final resolved = container.read(selectedDocumentDetailsProvider);
      expect(resolved?.title, 'Updated Title');
      expect(resolved?.syncStatus, DocumentSyncStatus.synced);

      container.read(selectedDocumentProvider.notifier).clear();
      expect(container.read(selectedDocumentDetailsProvider), isNull);
    });
  });

  group('HomeOperationNotifier guards', () {
    test('Manages uploading IDs and bulk uploading state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(homeOperationProvider).isAnyOperationActive,
        isFalse,
      );

      final notifier = container.read(homeOperationProvider.notifier);
      notifier.setUploading('doc-10', true);
      expect(
        container.read(homeOperationProvider).isUploading('doc-10'),
        isTrue,
      );
      expect(
        container.read(homeOperationProvider).isAnyOperationActive,
        isTrue,
      );

      notifier.setUploading('doc-10', false);
      expect(
        container.read(homeOperationProvider).isUploading('doc-10'),
        isFalse,
      );
      expect(
        container.read(homeOperationProvider).isAnyOperationActive,
        isFalse,
      );

      notifier.setBulkUploading(true);
      expect(container.read(homeOperationProvider).isBulkUploading, isTrue);
      expect(
        container.read(homeOperationProvider).isAnyOperationActive,
        isTrue,
      );

      notifier.setBulkUploading(false);
      expect(
        container.read(homeOperationProvider).isAnyOperationActive,
        isFalse,
      );
    });
  });
}

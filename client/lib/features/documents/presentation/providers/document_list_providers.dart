import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart' show DocumentView;
import '../../data/repositories/drift_document_repository.dart';
import '../../domain/models/document_filter_state.dart';
import '../../domain/models/document_item.dart';
import '../../domain/repositories/document_repository.dart';
import 'database_providers.dart';
import 'document_filter_providers.dart';
import 'storage_providers.dart';

/// Repository provider
final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  return DriftDocumentRepository(
    db: ref.watch(databaseProvider),
    storageService: ref.watch(storageServiceProvider),
    journal: ref.watch(operationJournalProvider),
  );
});

/// Unfiltered document stream provider representing the entire local database state
final allDocumentsStreamProvider = StreamProvider<List<DocumentItem>>((ref) {
  final repo = ref.watch(documentRepositoryProvider);
  return repo.watchDocuments(
    categoryFilter: 'ALL',
    fiscalYearFilter: null,
    syncStatusFilter: 'ALL',
  );
});

/// Stream of rows currently in the local recycle bin (Phase 1.4).
/// Newest trashed first, matching the underlying DB order.
final trashedDocumentsStreamProvider = StreamProvider<List<DocumentItem>>((ref) {
  final repo = ref.watch(documentRepositoryProvider);
  return repo.watchDocuments(view: DocumentView.trashed);
});

/// Per-category document counts, memoized against the unfiltered stream.
/// Previously the sidebar recomputed this O(n) loop inside `build()` on
/// every rebuild (which also fires on filter/tag/view changes), so a
/// 300-1000 document library re-tallied repeatedly. Computing it once per
/// actual data change removes that redundant work.
final documentCategoryCountsProvider = StreamProvider<Map<String, int>>(
  (ref) => ref.watch(documentRepositoryProvider).watchCategoryCounts(),
);

/// Document summary metrics computed from the unfiltered local source
class DocumentSummary {
  final int total;
  final int localOnly;
  final int synced;
  final int attention;

  const DocumentSummary({
    required this.total,
    required this.localOnly,
    required this.synced,
    required this.attention,
  });

  const DocumentSummary.empty()
    : total = 0,
      localOnly = 0,
      synced = 0,
      attention = 0;
}

final documentSummaryStreamProvider =
    StreamProvider<({int total, int localOnly, int synced, int attention})>(
  (ref) => ref.watch(documentRepositoryProvider).watchStatusSummary(),
);

/// Summary tallies computed in SQLite. The old version looped every
/// materialized row in Dart on each library change.
final documentSummaryProvider = Provider<AsyncValue<DocumentSummary>>((ref) {
  return ref.watch(documentSummaryStreamProvider).whenData(
    (c) => DocumentSummary(
      total: c.total,
      localOnly: c.localOnly,
      synced: c.synced,
      attention: c.attention,
    ),
  );
});

/// Page size for the database-backed list. Grows by one page as the user
/// scrolls (Phase 5.6) so the UI never materializes the whole library.
const int kDocumentListPageSize = 100;

class DocumentListLimitNotifier extends Notifier<int> {
  @override
  int build() => kDocumentListPageSize;

  void loadMore() => state += kDocumentListPageSize;
}

final documentListLimitProvider =
    NotifierProvider<DocumentListLimitNotifier, int>(
      DocumentListLimitNotifier.new,
    );

String _documentSortKey(DocumentSort sort) => switch (sort) {
      DocumentSort.newest => 'newest',
      DocumentSort.oldest => 'oldest',
      DocumentSort.titleAscending => 'title',
      DocumentSort.documentDateDescending => 'docDate',
    };

String? _effectiveSearch(DocumentFilterState filter) {
  final q = filter.searchQuery.trim();
  return q.isEmpty ? null : q;
}

/// Live document page. Filtering, ordering (stable id tie-breaker), and
/// LIMIT/OFFSET all execute in SQLite — no full-library Dart materialization
/// or sort. This is the Phase 5.6 cure for the large-library freeze.
final documentsListStreamProvider = StreamProvider<List<DocumentItem>>((ref) {
  final filter = ref.watch(documentFilterProvider);
  final sort = ref.watch(documentSortProvider);
  final limit = ref.watch(documentListLimitProvider);
  return ref.watch(documentRepositoryProvider).watchDocumentPage(
        sortBy: _documentSortKey(sort),
        limit: limit,
        category: filter.category,
        fiscalYear: filter.fiscalYear,
        syncStatus: filter.syncStatus,
        favoriteOnly: filter.favoriteOnly,
        tagName: filter.tag,
        collectionId: filter.collectionId,
        search: _effectiveSearch(filter),
      );
});

/// Total active documents (no filter). Drives the "library is empty" vs
/// "filter yields nothing" distinction without watching the whole table.
final activeDocumentCountProvider = StreamProvider<int>(
  (ref) => ref.watch(documentRepositoryProvider).watchDocumentCount(),
);

/// Count matching the CURRENT filter, for "load more" and result totals.
final filteredDocumentCountProvider = StreamProvider<int>((ref) {
  final filter = ref.watch(documentFilterProvider);
  return ref.watch(documentRepositoryProvider).watchDocumentCount(
        category: filter.category,
        fiscalYear: filter.fiscalYear,
        syncStatus: filter.syncStatus,
        favoriteOnly: filter.favoriteOnly,
        tagName: filter.tag,
        collectionId: filter.collectionId,
        search: _effectiveSearch(filter),
      );
});

/// Whether pages remain beyond what the list has loaded.
final documentListHasMoreProvider = Provider<bool>((ref) {
  final total = ref.watch(filteredDocumentCountProvider).value ?? 0;
  final loaded =
      ref.watch(documentsListStreamProvider).asData?.value.length ?? 0;
  return loaded < total;
});

/// Favorite count for the sidebar shortcut, computed in SQLite.
final favoriteCountProvider = StreamProvider<int>(
  (ref) => ref.watch(documentRepositoryProvider).watchDocumentCount(
        favoriteOnly: true,
      ),
);

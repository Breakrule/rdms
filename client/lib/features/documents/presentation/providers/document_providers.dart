import 'dart:async';

import 'package:drift/drift.dart' show OrderingTerm, innerJoin;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/services/bulk_import_service.dart';
import '../../../../core/services/document_export_service.dart';
import '../../../../core/services/document_organization_repository.dart';
import '../../../../core/services/document_replica_repository.dart';
import '../../../../core/services/drive_upload_session_repository.dart';
import '../../../../core/services/library_backup_service.dart';
import '../../../../core/services/library_integrity_service.dart';
import '../../../../core/services/operation_journal.dart';
import '../../../../core/services/storage_root_service.dart';
import '../../../../core/services/sync_job_repository.dart';
import '../../../../core/services/storage_service.dart';
import '../../domain/models/document_item.dart';
import '../../domain/repositories/document_repository.dart';
import '../../data/repositories/drift_document_repository.dart';

import '../../../../core/services/token_storage_service.dart';
import '../../../../core/services/gdrive_service.dart';
import '../../../../core/services/backend_sync_client.dart';
import '../../../../core/services/sync_queue_service.dart';
import '../../../../core/services/google_auth_service.dart';

/// Database instance provider
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

/// Storage-roots table service. [LocalStorageService] resolves its
/// active path through this so a user's chosen folder survives restart
/// (Phase 1.1 acceptance criterion).
final storageRootServiceProvider = Provider<StorageRootService>((ref) {
  return StorageRootService(ref.watch(databaseProvider));
});

/// Durable journal for file-mutating operations (Phase 1.3).
final operationJournalProvider = Provider<OperationJournal>((ref) {
  return OperationJournal(ref.watch(databaseProvider));
});

/// Token storage service provider
final tokenStorageServiceProvider = Provider<TokenStorageService>((ref) {
  return TokenStorageService();
});

/// Google Auth service provider
final googleAuthServiceProvider = Provider<GoogleAuthService>((ref) {
  return GoogleAuthService(
    tokenStorage: ref.watch(tokenStorageServiceProvider),
  );
});

/// Google Drive service provider
final gdriveServiceProvider = Provider<GDriveService>((ref) {
  return GDriveService(
    tokenStorage: ref.watch(tokenStorageServiceProvider),
    googleAuthService: ref.watch(googleAuthServiceProvider),
    sessionRepository: ref.watch(driveUploadSessionRepositoryProvider),
    mockMode: false,
  );
});

/// Drive upload session persistence for the resumable pipeline
/// (Phase 2.4).
final driveUploadSessionRepositoryProvider = Provider<DriveUploadSessionRepository>((ref) {
  return DriveUploadSessionRepository(ref.watch(databaseProvider));
});

/// Backend sync client provider
final backendSyncClientProvider = Provider<BackendSyncClient>((ref) {
  return BackendSyncClient(
    tokenStorage: ref.watch(tokenStorageServiceProvider),
  );
});

/// Sync queue service provider
final syncQueueServiceProvider = Provider<SyncQueueService>((ref) {
  final service = SyncQueueService(
    repository: ref.watch(documentRepositoryProvider),
    gdriveService: ref.watch(gdriveServiceProvider),
    backendClient: ref.watch(backendSyncClientProvider),
    jobs: ref.watch(syncJobRepositoryProvider),
    replicas: ref.watch(documentReplicaRepositoryProvider),
    db: ref.watch(databaseProvider),
  );
  ref.onDispose(() => service.dispose());
  return service;
});

/// Durable outbox (Phase 2.2 / 2.3).
final syncJobRepositoryProvider = Provider<SyncJobRepository>((ref) {
  return SyncJobRepository(ref.watch(databaseProvider));
});

/// Per-destination replica state (Phase 2.1).
final documentReplicaRepositoryProvider = Provider<DocumentReplicaRepository>((ref) {
  return DocumentReplicaRepository(ref.watch(databaseProvider));
});

/// Rollup stream used by the Sync Center to show per-destination counts
/// without hitting the DB on every rebuild.
final replicaRollupsProvider = FutureProvider<(ReplicaRollup, ReplicaRollup)>((ref) async {
  final repo = ref.watch(documentReplicaRepositoryProvider);
  final drive = await repo.rollup(JobDestination.drive);
  final backend = await repo.rollup(JobDestination.backend);
  return (drive, backend);
});

/// Stable identifier of the account the current sync worker is bound
/// to (Phase 2.3). Signed-in Google users get `g:<userId>`; when no
/// account is connected the app falls back to `local-device`, which is
/// still persisted so jobs queued while offline are picked up by the
/// SAME worker on restart (and are NOT picked up if a different Google
/// account is signed in later).
final syncAccountBindingProvider = FutureProvider<String>((ref) async {
  final google = ref.watch(googleAuthServiceProvider);
  final user = google.currentUser;
  if (user != null) return 'g:${user.id}';
  // Silent-restore may reveal a user; try once.
  try {
    final restored = await google.signInSilently();
    if (restored != null) return 'g:${restored.id}';
  } catch (_) {
    // Ignore; fall through to local-device.
  }
  return 'local-device';
});

/// Sync progress stream provider
final syncProgressStreamProvider = StreamProvider<SyncProgressState>((ref) {
  final queueService = ref.watch(syncQueueServiceProvider);
  return queueService.progressStream;
});

/// Storage service provider. The persistent resolver is wired to
/// [storageRootServiceProvider] so a restart lands on the same directory
/// the user chose. Test code can override either provider independently.
final storageServiceProvider = Provider<LocalStorageService>((ref) {
  final rootService = ref.watch(storageRootServiceProvider);
  return LocalStorageService(
    persistentPathResolver: () async {
      try {
        return await rootService.activePath();
      } catch (_) {
        return null;
      }
    },
  );
});

/// Backup export/import (Phase 1.5 / 1.6).
final libraryBackupServiceProvider = Provider<LibraryBackupService>((ref) {
  return LibraryBackupService(
    db: ref.watch(databaseProvider),
    journal: ref.watch(operationJournalProvider),
  );
});

/// Health check (Phase 1.7).
final libraryIntegrityServiceProvider = Provider<LibraryIntegrityService>((ref) {
  return LibraryIntegrityService(
    db: ref.watch(databaseProvider),
    journal: ref.watch(operationJournalProvider),
  );
});

/// Phase 4 organization CRUD (categories/tags/collections/saved views).
final organizationRepositoryProvider = Provider<DocumentOrganizationRepository>((ref) {
  return DocumentOrganizationRepository(ref.watch(databaseProvider));
});

/// Phase 4.7 register CSV + file export.
final documentExportServiceProvider = Provider<DocumentExportService>((ref) {
  return const DocumentExportService();
});

/// Phase 4.4 bulk import.
final bulkImportServiceProvider = Provider<BulkImportService>((ref) {
  return BulkImportService(repository: ref.watch(documentRepositoryProvider));
});

/// documentId -> tag names, live. Powers list chips, tag filters, and
/// CSV export enrichment (Phase 4.3/4.7).
final documentTagIndexProvider = StreamProvider<Map<String, Set<String>>>((ref) {
  final db = ref.watch(databaseProvider);
  final query = db.select(db.documentTags).join([
    innerJoin(db.tags, db.tags.id.equalsExp(db.documentTags.tagId)),
  ]);
  return query.watch().map((rows) {
    final out = <String, Set<String>>{};
    for (final row in rows) {
      final dt = row.readTable(db.documentTags);
      final tag = row.readTable(db.tags);
      out.putIfAbsent(dt.documentId, () => <String>{}).add(tag.name);
    }
    return out;
  });
});

/// collectionId -> member document ids, live (Phase 4.3).
final collectionIndexProvider = StreamProvider<Map<String, Set<String>>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.collectionItems).watch().map((rows) {
    final out = <String, Set<String>>{};
    for (final r in rows) {
      out.putIfAbsent(r.collectionId, () => <String>{}).add(r.documentId);
    }
    return out;
  });
});

final tagsListProvider = StreamProvider<List<Tag>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.tags)..orderBy([(t) => OrderingTerm.asc(t.name)])).watch();
});

final categoriesListProvider = StreamProvider<List<DocumentCategory>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.documentCategories)
        ..where((t) => t.archived.equals(false))
        ..orderBy([(t) => OrderingTerm.asc(t.name)]))
      .watch();
});

final collectionsListProvider = StreamProvider<List<Collection>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.collections)..orderBy([(t) => OrderingTerm.asc(t.name)])).watch();
});

final savedViewsProvider = StreamProvider<List<SavedView>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.savedViews)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();
});

final fiscalYearsProvider = FutureProvider<List<int>>((ref) async {
  final derived = await ref.watch(organizationRepositoryProvider).distinctFiscalYears();
  final current = DateTime.now().year;
  final all = {...derived, current, current + 1}.toList()..sort((a, b) => b.compareTo(a));
  return all;
});

/// Repository provider
final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  return DriftDocumentRepository(
    db: ref.watch(databaseProvider),
    storageService: ref.watch(storageServiceProvider),
    journal: ref.watch(operationJournalProvider),
  );
});

/// Sorting options for document explorer
enum DocumentSort {
  newest,
  oldest,
  titleAscending,
  documentDateDescending;

  String get label => switch (this) {
    DocumentSort.newest => 'Terbaru',
    DocumentSort.oldest => 'Terlama',
    DocumentSort.titleAscending => 'Judul A–Z',
    DocumentSort.documentDateDescending => 'Tanggal Dokumen',
  };
}

class DocumentSortNotifier extends Notifier<DocumentSort> {
  @override
  DocumentSort build() => DocumentSort.newest;

  void setSort(DocumentSort sort) {
    state = sort;
  }
}

final documentSortProvider =
    NotifierProvider<DocumentSortNotifier, DocumentSort>(
      DocumentSortNotifier.new,
    );

/// Filter state class
class DocumentFilterState {
  final String category; // 'ALL' or specific
  final int? fiscalYear;
  final String syncStatus; // 'ALL' or specific
  final String searchQuery;

  /// Phase 4.3 view filters. All default off; when set they compose
  /// with the others (never replace them — the Phase 0 search
  /// bypass bug must not return through these).
  final bool favoriteOnly;
  final String? tag; // tag NAME (lowercased)
  final String? collectionId;

  const DocumentFilterState({
    this.category = 'ALL',
    this.fiscalYear,
    this.syncStatus = 'ALL',
    this.searchQuery = '',
    this.favoriteOnly = false,
    this.tag,
    this.collectionId,
  });

  bool get hasActiveFilters =>
      category != 'ALL' ||
      fiscalYear != null ||
      syncStatus != 'ALL' ||
      favoriteOnly ||
      tag != null ||
      collectionId != null;

  DocumentFilterState copyWith({
    String? category,
    int? fiscalYear,
    bool clearFiscalYear = false,
    String? syncStatus,
    String? searchQuery,
    bool? favoriteOnly,
    String? tag,
    bool clearTag = false,
    String? collectionId,
    bool clearCollection = false,
  }) {
    return DocumentFilterState(
      category: category ?? this.category,
      fiscalYear: clearFiscalYear ? null : (fiscalYear ?? this.fiscalYear),
      syncStatus: syncStatus ?? this.syncStatus,
      searchQuery: searchQuery ?? this.searchQuery,
      favoriteOnly: favoriteOnly ?? this.favoriteOnly,
      tag: clearTag ? null : (tag ?? this.tag),
      collectionId:
          clearCollection ? null : (collectionId ?? this.collectionId),
    );
  }

  /// JSON snapshot for saved views (Phase 4.7).
  Map<String, dynamic> toJson() => {
        'category': category,
        'fiscalYear': fiscalYear,
        'syncStatus': syncStatus,
        'searchQuery': searchQuery,
        'favoriteOnly': favoriteOnly,
        'tag': tag,
        'collectionId': collectionId,
      };

  static DocumentFilterState fromJson(Map<String, dynamic> j) =>
      DocumentFilterState(
        category: j['category'] as String? ?? 'ALL',
        fiscalYear: j['fiscalYear'] as int?,
        syncStatus: j['syncStatus'] as String? ?? 'ALL',
        searchQuery: j['searchQuery'] as String? ?? '',
        favoriteOnly: j['favoriteOnly'] as bool? ?? false,
        tag: j['tag'] as String?,
        collectionId: j['collectionId'] as String?,
      );
}

class DocumentFilterNotifier extends Notifier<DocumentFilterState> {
  Timer? _debounceTimer;

  @override
  DocumentFilterState build() {
    ref.onDispose(() => _debounceTimer?.cancel());
    return const DocumentFilterState();
  }

  void setCategory(String category) {
    state = state.copyWith(category: category);
  }

  void setFiscalYear(int? year) {
    state = state.copyWith(fiscalYear: year, clearFiscalYear: year == null);
  }

  void setSyncStatus(String syncStatus) {
    state = state.copyWith(syncStatus: syncStatus);
  }

  void setFavoriteOnly(bool value) {
    state = state.copyWith(favoriteOnly: value);
  }

  void setTag(String? tag) {
    if (tag == null) {
      state = state.copyWith(clearTag: true);
    } else {
      state = state.copyWith(tag: tag.toLowerCase());
    }
  }

  void setCollection(String? collectionId) {
    state = collectionId == null
        ? state.copyWith(clearCollection: true)
        : state.copyWith(collectionId: collectionId);
  }

  void setSearchQuery(String query) {
    _debounceTimer?.cancel();
    if (query.trim().isEmpty) {
      state = state.copyWith(searchQuery: '');
      return;
    }
    // 150ms debounce prevents SQLite thrashing while feeling instantaneous
    _debounceTimer = Timer(const Duration(milliseconds: 150), () {
      state = state.copyWith(searchQuery: query);
    });
  }

  void clearSearchQuery() {
    _debounceTimer?.cancel();
    state = state.copyWith(searchQuery: '');
  }

  /// Resets category, fiscal year, status, favorite/tag/collection
  /// filters, but preserves the current search query
  void resetFilters() {
    state = state.copyWith(
      category: 'ALL',
      clearFiscalYear: true,
      syncStatus: 'ALL',
      favoriteOnly: false,
      clearTag: true,
      clearCollection: true,
    );
  }

  /// Full reset of all filters and search query
  void reset() {
    _debounceTimer?.cancel();
    state = const DocumentFilterState();
  }

  /// Restore a saved view wholesale (Phase 4.7). Cancels any pending
  /// debounce so a stale keystroke cannot overwrite the loaded state.
  void replaceAll(DocumentFilterState next) {
    _debounceTimer?.cancel();
    state = next;
  }
}

final documentFilterProvider =
    NotifierProvider<DocumentFilterNotifier, DocumentFilterState>(
      DocumentFilterNotifier.new,
    );

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

/// Phase 4.6 multi-selection. Holds document ids; the action bar shows
/// the exact count and scope so destructive actions never operate on an
/// ambiguous set. Selection is cleared when the underlying document
/// disappears (see DocumentListView filter) — but the authoritative
/// scope for every action is [selectedDocumentsProvider].
class DocumentSelectionNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void toggle(String id) {
    final next = {...state};
    // Remove when already present, otherwise add. A set literal that
    // spreads `...state` first can never drop an existing id, so the
    // membership flip has to be explicit.
    if (!next.remove(id)) next.add(id);
    state = next;
  }

  void selectAll(Iterable<String> ids) {
    state = ids.toSet();
  }

  void clear() => state = const {};
}

final documentSelectionProvider =
    NotifierProvider<DocumentSelectionNotifier, Set<String>>(
      DocumentSelectionNotifier.new,
    );

final selectedDocumentsStreamProvider =
    StreamProvider<List<DocumentItem>>((ref) {
  final ids = ref.watch(documentSelectionProvider).toList();
  if (ids.isEmpty) return Stream.value(const <DocumentItem>[]);
  return ref.watch(documentRepositoryProvider).watchDocumentsByIds(ids);
});

/// The concrete, live documents behind the current selection. Resolved by
/// id in SQLite (trashed rows excluded), so a document deleted/trashed
/// after selection cannot be silently included, and no full library is
/// scanned. Every bulk action operates on THIS, never raw ids.
final selectedDocumentsProvider = Provider<List<DocumentItem>>(
  (ref) => ref.watch(selectedDocumentsStreamProvider).value ?? const [],
);

/// Currently selected document for preview / detail view
class SelectedDocumentNotifier extends Notifier<DocumentItem?> {
  @override
  DocumentItem? build() => null;

  void select(DocumentItem? doc) => state = doc;
  void clear() => state = null;
}

final selectedDocumentProvider =
    NotifierProvider<SelectedDocumentNotifier, DocumentItem?>(
      SelectedDocumentNotifier.new,
    );

final selectedDocumentByIdProvider = StreamProvider<DocumentItem?>((ref) {
  final id = ref.watch(selectedDocumentProvider.select((d) => d?.id));
  if (id == null) return Stream.value(null);
  return ref.watch(documentRepositoryProvider).watchDocumentById(id);
});

/// Live details for the selected document, resolved by a single-row query
/// instead of scanning the whole materialized list. Falls back to the
/// selection snapshot until the stream's first value arrives.
final selectedDocumentDetailsProvider = Provider<DocumentItem?>((ref) {
  final selected = ref.watch(selectedDocumentProvider);
  if (selected == null) return null;
  final asyncDoc = ref.watch(selectedDocumentByIdProvider);
  if (asyncDoc.hasValue) {
    return asyncDoc.value;
  }
  return selected;
});

/// Presentation-only guard for active background operations
class HomeOperationState {
  final Set<String> uploadingDocumentIds;
  final bool isBulkUploading;
  final bool isRefreshing;

  const HomeOperationState({
    this.uploadingDocumentIds = const {},
    this.isBulkUploading = false,
    this.isRefreshing = false,
  });

  bool isUploading(String id) => uploadingDocumentIds.contains(id);
  bool get isAnyOperationActive =>
      isBulkUploading || isRefreshing || uploadingDocumentIds.isNotEmpty;

  HomeOperationState copyWith({
    Set<String>? uploadingDocumentIds,
    bool? isBulkUploading,
    bool? isRefreshing,
  }) {
    return HomeOperationState(
      uploadingDocumentIds: uploadingDocumentIds ?? this.uploadingDocumentIds,
      isBulkUploading: isBulkUploading ?? this.isBulkUploading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

class HomeOperationNotifier extends Notifier<HomeOperationState> {
  @override
  HomeOperationState build() => const HomeOperationState();

  void setUploading(String docId, bool uploading) {
    final next = Set<String>.from(state.uploadingDocumentIds);
    if (uploading) {
      next.add(docId);
    } else {
      next.remove(docId);
    }
    state = state.copyWith(uploadingDocumentIds: next);
  }

  void setBulkUploading(bool active) {
    state = state.copyWith(isBulkUploading: active);
  }

  void setRefreshing(bool active) {
    state = state.copyWith(isRefreshing: active);
  }
}

final homeOperationProvider =
    NotifierProvider<HomeOperationNotifier, HomeOperationState>(
      HomeOperationNotifier.new,
    );

/// Cloud connection and configuration status
enum CloudConfigurationStatus {
  loading,
  unconfigured,
  configured,
  demo;

  String get label => switch (this) {
    CloudConfigurationStatus.loading => 'Memeriksa konfigurasi...',
    CloudConfigurationStatus.unconfigured => 'Google Drive belum dikonfigurasi',
    CloudConfigurationStatus.configured => 'Google Drive dikonfigurasi',
    CloudConfigurationStatus.demo => 'Penyimpanan lokal (offline)',
  };
}

class CloudConfigurationNotifier
    extends AsyncNotifier<CloudConfigurationStatus> {
  @override
  Future<CloudConfigurationStatus> build() async {
    final tokenStorage = ref.watch(tokenStorageServiceProvider);
    final isDemo = await tokenStorage.isDemoMode();
    if (isDemo) {
      return CloudConfigurationStatus.demo;
    }
    final token = await tokenStorage.getAccessToken();
    if (token != null && token.trim().isNotEmpty) {
      return CloudConfigurationStatus.configured;
    }
    return CloudConfigurationStatus.unconfigured;
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

final cloudConfigurationProvider =
    AsyncNotifierProvider<CloudConfigurationNotifier, CloudConfigurationStatus>(
      CloudConfigurationNotifier.new,
    );

/// Custom storage directory path state
class StoragePathNotifier extends AsyncNotifier<String> {
  @override
  Future<String> build() async {
    final storageService = ref.watch(storageServiceProvider);
    return storageService.getStorageDirectoryPath();
  }

  /// Points future imports at [newPath] AND persists the choice so a
  /// restart reopens the same library. Phase 1.2 safe relocation is a
  /// separate concern (copy + verify + swap); this only changes the
  /// destination for NEW imports.
  Future<void> updatePath(String newPath) async {
    state = const AsyncValue.loading();
    try {
      final storageService = ref.read(storageServiceProvider);
      await storageService.setCustomBasePath(newPath);
      final rootService = ref.read(storageRootServiceProvider);
      await rootService.setActivePath(newPath);
      state = AsyncValue.data(newPath);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final storagePathProvider = AsyncNotifierProvider<StoragePathNotifier, String>(
  StoragePathNotifier.new,
);

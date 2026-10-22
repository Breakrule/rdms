import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/document_filter_state.dart';

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

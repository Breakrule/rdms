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

/// Filter state value object
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

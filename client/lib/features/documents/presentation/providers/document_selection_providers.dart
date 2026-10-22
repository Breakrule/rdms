import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/document_item.dart';
import 'auth_providers.dart';
import 'document_list_providers.dart';

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

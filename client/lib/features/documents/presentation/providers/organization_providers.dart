import 'package:drift/drift.dart' show OrderingTerm, innerJoin;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/services/bulk_import_service.dart';
import '../../../../core/services/document_export_service.dart';
import '../../../../core/services/document_organization_repository.dart';
import 'database_providers.dart';
import 'document_list_providers.dart';

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

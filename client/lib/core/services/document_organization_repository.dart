import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';

/// CRUD for tags, collections, categories, and saved views
/// (Phase 4.2 / 4.3 / 4.7). Favorites live on the document row and are
/// handled by DocumentRepository.setFavorite instead.
class DocumentOrganizationRepository {
  final AppDatabase _db;
  static const _uuid = Uuid();

  DocumentOrganizationRepository(this._db);

  // ---- Categories (Phase 4.2) ------------------------------------

  Future<List<DocumentCategory>> listCategories({bool includeArchived = false}) async {
    final q = _db.select(_db.documentCategories)
      ..orderBy([(t) => OrderingTerm.asc(t.name)]);
    if (!includeArchived) {
      q.where((t) => t.archived.equals(false));
    }
    return q.get();
  }

  Future<void> renameCategory(String code, String name) async {
    await (_db.update(_db.documentCategories)..where((t) => t.code.equals(code)))
        .write(DocumentCategoriesCompanion(name: Value(name)));
  }

  /// Archiving never deletes document references: rows keep the code
  /// and stay visible in lists even after the category is archived.
  Future<void> archiveCategory(String code) async {
    await (_db.update(_db.documentCategories)..where((t) => t.code.equals(code)))
        .write(const DocumentCategoriesCompanion(archived: Value(true)));
  }

  Future<void> ensureCategory(String code, {String? name}) async {
    final upper = code.trim().toUpperCase();
    if (upper.isEmpty) return;
    await _db.into(_db.documentCategories).insert(
          DocumentCategoriesCompanion.insert(
            code: upper,
            name: name ?? code.trim(),
          ),
          onConflict: DoUpdate(
            (old) => const DocumentCategoriesCompanion(archived: Value(false)),
            target: [_db.documentCategories.code],
          ),
        );
  }

  /// Distinct fiscal years present in active records, newest first.
  /// Replaces the fixed year list in the import form (Phase 4.2).
  Future<List<int>> distinctFiscalYears() async {
    final rows = await _db.customSelect(
      'SELECT DISTINCT fiscal_year FROM local_documents '
      'WHERE trashed_at IS NULL ORDER BY fiscal_year DESC',
      readsFrom: {_db.localDocuments},
    ).get();
    return rows.map((r) => r.data['fiscal_year'] as int).toList();
  }

  // ---- Tags (Phase 4.3) ------------------------------------------

  Future<List<Tag>> listTags() async {
    return (_db.select(_db.tags)..orderBy([(t) => OrderingTerm.asc(t.name)])).get();
  }

  Future<List<String>> tagNames() async {
    return (await listTags()).map((t) => t.name).toList();
  }

  /// documentId -> tag names, for list rendering and filters.
  Future<Map<String, Set<String>>> tagNamesByDocument() async {
    final rows = await _db.select(_db.documentTags).join([
      innerJoin(_db.tags, _db.tags.id.equalsExp(_db.documentTags.tagId)),
    ]).get();
    final out = <String, Set<String>>{};
    for (final row in rows) {
      final dt = row.readTable(_db.documentTags);
      final tag = row.readTable(_db.tags);
      out.putIfAbsent(dt.documentId, () => <String>{}).add(tag.name);
    }
    return out;
  }

  Future<Set<String>> tagNamesFor(String documentId) async {
    final rows = await (_db.select(_db.documentTags)
          ..where((t) => t.documentId.equals(documentId)))
        .get();
    final out = <String>{};
    for (final dt in rows) {
      final tag = await (_db.select(_db.tags)..where((t) => t.id.equals(dt.tagId)))
          .getSingleOrNull();
      if (tag != null) out.add(tag.name);
    }
    return out;
  }

  /// Replaces the tag set of a document, creating missing tags.
  Future<void> setTags(String documentId, List<String> names) async {
    final normalized = names
        .map((t) => t.trim().toLowerCase())
        .where((t) => t.isNotEmpty)
        .toSet()
        .toList(growable: false);
    await _db.transaction(() async {
      await (_db.delete(_db.documentTags)
            ..where((t) => t.documentId.equals(documentId)))
          .go();
      for (final name in normalized) {
        var tag =
            await (_db.select(_db.tags)..where((t) => t.name.equals(name)))
                .getSingleOrNull();
        if (tag == null) {
          final id = _uuid.v4();
          await _db.into(_db.tags).insert(TagsCompanion.insert(id: id, name: name));
          tag = await (_db.select(_db.tags)..where((t) => t.id.equals(id))).getSingle();
        }
        await _db.into(_db.documentTags).insert(
              DocumentTagsCompanion.insert(documentId: documentId, tagId: tag.id),
            );
      }
    });
  }

  Future<void> addTagToDocuments(String tagName, List<String> documentIds) async {
    for (final docId in documentIds) {
      final existing = await tagNamesFor(docId);
      await setTags(docId, {...existing, tagName}.toList());
    }
  }

  Future<void> deleteTag(String tagId) async {
    await _db.transaction(() async {
      await (_db.delete(_db.documentTags)..where((t) => t.tagId.equals(tagId))).go();
      await (_db.delete(_db.tags)..where((t) => t.id.equals(tagId))).go();
    });
  }

  // ---- Collections (Phase 4.3) -----------------------------------

  Future<List<Collection>> listCollections() =>
      (_db.select(_db.collections)..orderBy([(t) => OrderingTerm.asc(t.name)])).get();

  Future<Collection> createCollection(String name) async {
    final id = _uuid.v4();
    await _db.into(_db.collections).insert(
          CollectionsCompanion.insert(id: id, name: name.trim()),
        );
    return (_db.select(_db.collections)..where((t) => t.id.equals(id))).getSingle();
  }

  Future<void> renameCollection(String id, String name) =>
      (_db.update(_db.collections)..where((t) => t.id.equals(id)))
          .write(CollectionsCompanion(name: Value(name.trim())));

  Future<void> deleteCollection(String id) async {
    await _db.transaction(() async {
      await (_db.delete(_db.collectionItems)..where((t) => t.collectionId.equals(id))).go();
      await (_db.delete(_db.collections)..where((t) => t.id.equals(id))).go();
    });
  }

  Future<void> addToCollection(String collectionId, List<String> documentIds) async {
    for (final docId in documentIds) {
      await _db.into(_db.collectionItems).insert(
            CollectionItemsCompanion.insert(collectionId: collectionId, documentId: docId),
            onConflict: DoNothing(),
          );
    }
  }

  Future<void> removeFromCollection(String collectionId, String documentId) =>
      (_db.delete(_db.collectionItems)
            ..where((t) => t.collectionId.equals(collectionId))
            ..where((t) => t.documentId.equals(documentId)))
          .go();

  Future<List<String>> collectionDocumentIds(String collectionId) async {
    final rows = await (_db.select(_db.collectionItems)
          ..where((t) => t.collectionId.equals(collectionId)))
        .get();
    return rows.map((r) => r.documentId).toList();
  }

  // ---- Saved views (Phase 4.7) ----------------------------------

  Future<List<SavedView>> listSavedViews() =>
      (_db.select(_db.savedViews)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();

  Future<SavedView> saveView(String name, String stateJson) async {
    final id = _uuid.v4();
    await _db.into(_db.savedViews).insert(
          SavedViewsCompanion.insert(id: id, name: name.trim(), stateJson: stateJson),
        );
    return (_db.select(_db.savedViews)..where((t) => t.id.equals(id))).getSingle();
  }

  Future<void> deleteSavedView(String id) =>
      (_db.delete(_db.savedViews)..where((t) => t.id.equals(id))).go();
}

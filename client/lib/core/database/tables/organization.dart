import 'package:drift/drift.dart';

/// Phase 4 organization entities in one file (they are small, always
/// used together, and split nothing across boundaries).

/// Stable category codes with editable display names (Phase 4.2).
/// `local_documents.category` keeps storing the CODE as before; this
/// table adds the display name and the archived flag. Ambiguous legacy
/// values (e.g. both 'SK' and 'Surat Keputusan' present) are seeded
/// here 1:1 during the v4 migration and merged ONLY when the user
/// confirms a mapping — the table never auto-merges.
class DocumentCategories extends Table {
  TextColumn get code => text()(); // stored uppercase, unique
  TextColumn get name => text()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {code};
}

class Tags extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get name => text().withLength(min: 1, max: 60)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [{name}];
}

class DocumentTags extends Table {
  TextColumn get documentId => text()();
  TextColumn get tagId => text()();

  @override
  Set<Column> get primaryKey => {documentId, tagId};
}

/// Virtual collections: they reference records, never move files
/// (Phase 4.3).
class Collections extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get name => text().withLength(min: 1, max: 120)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class CollectionItems extends Table {
  TextColumn get collectionId => text()();
  TextColumn get documentId => text()();

  @override
  Set<Column> get primaryKey => {collectionId, documentId};
}

/// Saved browsing views (Phase 4.7): a named JSON snapshot of
/// filter + sort state. Device-local by design — the plan keeps saved
/// views out of server replication for this release.
class SavedViews extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get name => text().withLength(min: 1, max: 80)();
  TextColumn get stateJson => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

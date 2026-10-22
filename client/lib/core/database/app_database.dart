import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'tables/document_replicas.dart';
import 'tables/drive_upload_sessions.dart';
import 'tables/document_versions.dart';
import 'tables/local_documents.dart';
import 'tables/local_operations.dart';
import 'tables/organization.dart';
import 'tables/storage_roots.dart';
import 'tables/sync_jobs.dart';
import 'tables/usage_counters.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    LocalDocuments,
    StorageRoots,
    LocalOperations,
    SyncJobs,
    DocumentReplicas,
    DriveUploadSessions,
    DocumentCategories,
    Tags,
    DocumentTags,
    Collections,
    CollectionItems,
    SavedViews,
    UsageCounters,
    ContentBlobs,
    DocumentVersions,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 6;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'dms_local_db');
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          await _installFtsAndIndexes();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          // Ordered, stepwise migrations. Every schema change MUST bump
          // [schemaVersion] and add a matching `if (before < N)` block
          // below. Existing installations are upgraded exactly once per
          // version; new installs skip straight to onCreate.
          if (from < 2) {
            // Phase 1 additions: local recycle bin (trashed_at on
            // local_documents), durable storage roots, and the
            // operation journal.
            await m.addColumn(localDocuments, localDocuments.trashedAt);
            await m.createTable(storageRoots);
            await m.createTable(localOperations);
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_local_docs_trashed ON local_documents(trashed_at);',
            );
          }
          if (from < 3) {
            // Phase 2 additions: durable sync outbox, per-destination
            // replica state, resumable Drive upload session storage,
            // and revision/accountBinding columns on the document
            // itself.
            await m.addColumn(localDocuments, localDocuments.baseRevision);
            await m.addColumn(localDocuments, localDocuments.accountBinding);
            await m.createTable(syncJobs);
            await m.createTable(documentReplicas);
            await m.createTable(driveUploadSessions);
            // idx_sync_jobs_eligible and idx_document_replicas_doc_dest are
            // created by [_installFtsAndIndexes] so fresh installs get them
            // too; they used to live only in this block.
          }
          if (from < 4) {
            // Phase 4 additions: favorite/notes/originalFileName on the
            // document, plus the organization entities (categories,
            // tags, collections, saved views).
            await m.addColumn(localDocuments, localDocuments.isFavorite);
            await m.addColumn(localDocuments, localDocuments.notes);
            await m.addColumn(
              localDocuments,
              localDocuments.originalFileName,
            );
            await m.createTable(documentCategories);
            await m.createTable(tags);
            await m.createTable(documentTags);
            await m.createTable(collections);
            await m.createTable(collectionItems);
            await m.createTable(savedViews);
            // Seed categories 1:1 from distinct legacy values. NO
            // auto-merge of ambiguous codes (SK vs 'Surat Keputusan'):
            // Phase 4.2 requires an explicit user mapping for that.
            await customStatement(
              "INSERT OR IGNORE INTO document_categories (code, name) "
              "SELECT category, category FROM local_documents "
              "WHERE category IS NOT NULL AND category <> ''",
            );
            // idx_local_docs_favorite is created by [_installFtsAndIndexes]
            // (which runs on BOTH the fresh-install and upgrade paths). It
            // used to live only here, so every fresh install silently lacked
            // it — see the note in [_installFtsAndIndexes].
          }
          if (from < 5) {
            // Rev. 2 Phase P0.3: local usage counters. Opt-out by default —
            // rows are written to this table only, and nothing leaves the
            // device unless the user enables reporting (P0.5).
            await m.createTable(usageCounters);
          }
          if (from < 6) {
            // Rev. 2 Phase P1.1/P1.2: the version data model.
            //
            // Additive and reversible-in-effect: no existing column is
            // touched, no file is moved, and `current_version_id` stays NULL
            // for every pre-existing document until P1.3 starts creating
            // versions. An upgraded install therefore behaves exactly like a
            // fresh one for all pre-P1 code paths, which is what the R-08
            // preservation test checks.
            await m.createTable(contentBlobs);
            await m.createTable(documentVersions);
            await m.addColumn(localDocuments, localDocuments.workspaceId);
            await m.addColumn(localDocuments, localDocuments.currentVersionId);
          }
          // Rebuild FTS + indexes on every upgrade path so a change to
          // [_installFtsAndIndexes] propagates to existing users without
          // requiring a separate migration step.
          await _installFtsAndIndexes();
        },
        beforeOpen: (details) async {
          // Native-grade SQLite tuning: concurrent WAL, 64MB RAM cache, 256MB mmap
          await customStatement('PRAGMA journal_mode = WAL;');
          await customStatement('PRAGMA synchronous = NORMAL;');
          await customStatement('PRAGMA temp_store = MEMORY;');
          await customStatement('PRAGMA cache_size = -64000;');
          await customStatement('PRAGMA mmap_size = 268435456;');
        },
      );

  /// Idempotent DDL for the FTS5 shadow table, its synchronisation
  /// triggers, and the B-tree indexes that back filtering/sorting.
  /// Runs on every fresh install and after every upgrade so schema
  /// drift between a device installed at v1 and one upgraded to vN is
  /// impossible.
  ///
  /// RULE: **every index belongs here, not inside a `from < N` block.**
  /// An index created only inside an upgrade block is absent on every fresh
  /// install, because `onCreate` never runs those blocks. Three indexes
  /// (`idx_sync_jobs_eligible`, `idx_document_replicas_doc_dest`,
  /// `idx_local_docs_favorite`) were in that state until P0 moved them here —
  /// a live example of plan risk R-08: upgraded installs were fast and fresh
  /// installs (including every test using `NativeDatabase.memory()`) were
  /// measuring an unindexed path.
  Future<void> _installFtsAndIndexes() async {
    await customStatement('''
      CREATE VIRTUAL TABLE IF NOT EXISTS local_documents_fts USING fts5(
        doc_id UNINDEXED,
        title,
        document_number,
        category,
        extracted_text,
        tokenize = 'unicode61'
      );
    ''');

    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS trg_local_documents_ai AFTER INSERT ON local_documents
      BEGIN
        INSERT INTO local_documents_fts(doc_id, title, document_number, category, extracted_text)
        VALUES (new.id, new.title, coalesce(new.document_number, ''), new.category, coalesce(new.extracted_text, ''));
      END;
    ''');

    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS trg_local_documents_au AFTER UPDATE ON local_documents
      BEGIN
        DELETE FROM local_documents_fts WHERE doc_id = old.id;
        INSERT INTO local_documents_fts(doc_id, title, document_number, category, extracted_text)
        VALUES (new.id, new.title, coalesce(new.document_number, ''), new.category, coalesce(new.extracted_text, ''));
      END;
    ''');

    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS trg_local_documents_ad AFTER DELETE ON local_documents
      BEGIN
        DELETE FROM local_documents_fts WHERE doc_id = old.id;
      END;
    ''');

    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_local_docs_cat_date ON local_documents(category, created_at DESC);',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_local_docs_fiscal ON local_documents(fiscal_year, created_at DESC);',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_local_docs_status ON local_documents(sync_status, created_at DESC);',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_local_docs_created ON local_documents(created_at DESC);',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_local_docs_trashed ON local_documents(trashed_at);',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_local_docs_favorite ON local_documents(is_favorite);',
    );
    // Queue eligibility scan (Phase 2.3) and the per-document replica lookup
    // both degrade to full scans without these.
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_sync_jobs_eligible '
      'ON sync_jobs(status, next_retry_at);',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_document_replicas_doc_dest '
      'ON document_replicas(document_id, destination);',
    );
    // Every metrics query in docs/METRICS.md §2 filters on event + a time
    // window, so the rollups stay index-only as counters accumulate.
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_usage_counters_event_time '
      'ON usage_counters(event, occurred_at DESC);',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_usage_counters_session '
      'ON usage_counters(session_id);',
    );
    // Version history is read newest-first on every open of the history
    // screen, and the blob lookup by hash is the dedup path — both must be
    // index-only at a few thousand versions.
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_doc_versions_document '
      'ON document_versions(document_id, version_number DESC);',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_content_blobs_hash '
      'ON content_blobs(sha256_hash);',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_local_docs_workspace '
      'ON local_documents(workspace_id);',
    );
  }

  /// Performs full-text search matching using SQLite FTS5 index.
  ///
  /// [includeTrashed] defaults to false; a Phase 1 recycle-bin view
  /// passes true to keep search working across both scopes.
  Future<List<LocalDocument>> searchWithFts(
    String query, {
    bool includeTrashed = false,
  }) async {
    final sanitizedQuery = query.replaceAll("'", "''").trim();
    if (sanitizedQuery.isEmpty) {
      final q = select(localDocuments)
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
      if (!includeTrashed) {
        q.where((t) => t.trashedAt.isNull());
      }
      return q.get();
    }

    // FTS5 MATCH format with prefix matching
    final ftsTokens = sanitizedQuery
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .map((t) => '"$t"*')
        .join(' ');

    final where = includeTrashed
        ? 'local_documents_fts MATCH ?'
        : 'd.trashed_at IS NULL AND local_documents_fts MATCH ?';

    final rows = await customSelect(
      'SELECT d.* FROM local_documents d '
      'JOIN local_documents_fts fts ON d.id = fts.doc_id '
      'WHERE $where '
      'ORDER BY bm25(local_documents_fts) ASC',
      variables: [Variable.withString(ftsTokens)],
      readsFrom: {localDocuments},
    ).get();

    return rows.map((row) => localDocuments.map(row.data)).toList();
  }

  /// Watch documents ordered by creation date.
  ///
  /// [view] controls trashed visibility:
  /// - [DocumentView.active] (default): exclude trashed rows.
  /// - [DocumentView.trashed]: only trashed rows.
  /// - [DocumentView.all]: no trashed filtering.
  Stream<List<LocalDocument>> watchAllDocuments({
    String? categoryFilter,
    int? fiscalYearFilter,
    String? syncStatusFilter,
    DocumentView view = DocumentView.active,
  }) {
    var query = select(localDocuments);
    if (categoryFilter != null && categoryFilter.isNotEmpty && categoryFilter != 'ALL') {
      query = query..where((t) => t.category.equals(categoryFilter));
    }
    if (fiscalYearFilter != null) {
      query = query..where((t) => t.fiscalYear.equals(fiscalYearFilter));
    }
    if (syncStatusFilter != null && syncStatusFilter.isNotEmpty && syncStatusFilter != 'ALL') {
      query = query..where((t) => t.syncStatus.equals(syncStatusFilter));
    }
    switch (view) {
      case DocumentView.active:
        query = query..where((t) => t.trashedAt.isNull());
        break;
      case DocumentView.trashed:
        query = query..where((t) => t.trashedAt.isNotNull());
        break;
      case DocumentView.all:
        break;
    }
    query = query
      ..orderBy([(t) => OrderingTerm.desc(view == DocumentView.trashed ? t.trashedAt : t.createdAt)]);
    return query.watch();
  }

  /// Get queued documents directly without stream subscription.
  /// Trashed documents are excluded so a paused queue cannot accidentally
  /// upload a document the user just moved to the recycle bin.
  Future<List<LocalDocument>> getQueuedDocuments() {
    return (select(localDocuments)
          ..where((t) => t.syncStatus.equals('queued'))
          ..where((t) => t.trashedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  /// Upsert document record
  Future<int> upsertDocument(LocalDocumentsCompanion entry) {
    return into(localDocuments).insertOnConflictUpdate(entry);
  }

  /// Update document sync status
  Future<bool> updateSyncStatus({
    required String id,
    required String syncStatus,
    String? gdriveFileId,
    String? remoteBackendId,
  }) async {
    final count = await (update(localDocuments)..where((t) => t.id.equals(id))).write(
      LocalDocumentsCompanion(
        syncStatus: Value(syncStatus),
        gdriveFileId: gdriveFileId != null ? Value(gdriveFileId) : const Value.absent(),
        remoteBackendId: remoteBackendId != null ? Value(remoteBackendId) : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ),
    );
    return count > 0;
  }

  /// Count documents. [view] controls trashed visibility, defaulting to
  /// active-only so the summary card and category counts do not silently
  /// include recycled rows (Phase 1.4 acceptance gate).
  Future<int> countDocuments({DocumentView view = DocumentView.active}) async {
    final countExp = localDocuments.id.count();
    final query = selectOnly(localDocuments)..addColumns([countExp]);
    switch (view) {
      case DocumentView.active:
        query.where(localDocuments.trashedAt.isNull());
        break;
      case DocumentView.trashed:
        query.where(localDocuments.trashedAt.isNotNull());
        break;
      case DocumentView.all:
        break;
    }
    final result = await query.map((row) => row.read(countExp)).getSingle();
    return result ?? 0;
  }

  /// Read every document regardless of trashed state. Used by the
  /// portable backup export (Phase 1.5).
  Future<List<LocalDocument>> getAllDocumentsForBackup() {
    return select(localDocuments).get();
  }

  // ---- Phase 5.6: database-side filtering, ordering, paging, counts ----
  //
  // The UI used to materialize the WHOLE local_documents table on the
  // main isolate and filter/sort it in Dart on every change, which froze
  // large libraries. These queries push all of that into SQLite instead.

  /// Shared WHERE builder for the paged list and the count. EXISTS
  /// sub-queries (not JOINs) keep exactly one row per document so
  /// LIMIT/OFFSET paging and COUNT(*) stay correct with tag/collection/
  /// search filters active. All values are bound as variables (the search
  /// path is parameterized too, unlike the older string-built FTS query).
  ({String where, List<Variable> vars, Set<TableInfo> reads}) _docFilterClause({
    required bool includeTrashed,
    String? category,
    int? fiscalYear,
    String? syncStatus,
    bool favoriteOnly = false,
    String? tagName,
    String? collectionId,
    String? search,
    String? documentNumber,
    int? dateFromMillis,
    int? dateToMillis,
    String? mimeType,
    String? fileNameLike,
  }) {
    final clauses = <String>[];
    final vars = <Variable>[];
    final reads = <TableInfo>{localDocuments};
    if (!includeTrashed) clauses.add('d.trashed_at IS NULL');
    if (category != null && category.isNotEmpty && category != 'ALL') {
      clauses.add('d.category = ?');
      vars.add(Variable<String>(category));
    }
    if (fiscalYear != null) {
      clauses.add('d.fiscal_year = ?');
      vars.add(Variable<int>(fiscalYear));
    }
    if (syncStatus != null && syncStatus.isNotEmpty && syncStatus != 'ALL') {
      clauses.add('d.sync_status = ?');
      vars.add(Variable<String>(syncStatus));
    }
    if (favoriteOnly) clauses.add('d.is_favorite = 1');
    if (documentNumber != null && documentNumber.trim().isNotEmpty) {
      clauses.add('d.document_number = ?');
      vars.add(Variable<String>(documentNumber.trim()));
    }
    if (dateFromMillis != null) {
      clauses.add('d.document_date >= ?');
      // Bind with Drift's DateTime serialization so the comparison uses
      // the SAME encoding the column stores (raw int units can differ).
      vars.add(Variable.withDateTime(
        DateTime.fromMillisecondsSinceEpoch(dateFromMillis),
      ));
    }
    if (dateToMillis != null) {
      clauses.add('d.document_date <= ?');
      vars.add(Variable.withDateTime(
        DateTime.fromMillisecondsSinceEpoch(dateToMillis),
      ));
    }
    if (mimeType != null && mimeType.trim().isNotEmpty) {
      clauses.add('d.mime_type = ?');
      vars.add(Variable<String>(mimeType.trim()));
    }
    if (fileNameLike != null && fileNameLike.trim().isNotEmpty) {
      final like = '%${fileNameLike.trim()}%';
      clauses.add('(d.file_name LIKE ? OR d.original_file_name LIKE ?)');
      vars
        ..add(Variable<String>(like))
        ..add(Variable<String>(like));
    }
    if (tagName != null && tagName.isNotEmpty) {
      clauses.add(
        'EXISTS (SELECT 1 FROM document_tags dt '
        'JOIN tags tg ON tg.id = dt.tag_id '
        'WHERE dt.document_id = d.id AND tg.name = ?)',
      );
      vars.add(Variable<String>(tagName));
      reads
        ..add(documentTags)
        ..add(tags);
    }
    if (collectionId != null && collectionId.isNotEmpty) {
      clauses.add(
        'EXISTS (SELECT 1 FROM collection_items ci '
        'WHERE ci.document_id = d.id AND ci.collection_id = ?)',
      );
      vars.add(Variable<String>(collectionId));
      reads.add(collectionItems);
    }
    if (search != null && search.trim().isNotEmpty) {
      final tokens = search
          .replaceAll("'", "''")
          .trim()
          .split(RegExp(r'\s+'))
          .where((t) => t.isNotEmpty)
          .map((t) => '"${t.replaceAll('"', '""')}*"')
          .join(' ');
      clauses.add(
        'd.id IN (SELECT doc_id FROM local_documents_fts '
        'WHERE local_documents_fts MATCH ?)',
      );
      vars.add(Variable<String>(tokens));
    }
    final where = clauses.isEmpty ? '' : 'WHERE ${clauses.join(' AND ')}';
    return (where: where, vars: vars, reads: reads);
  }

  /// Maps a stable sort key to SQL ORDER BY with a deterministic `id`
  /// tie-breaker, so paging never skips or repeats a row when timestamps
  /// collide (the Windows clock-tick flake the earlier tests hit).
  static String _docOrderBy(String sortBy) {
    switch (sortBy) {
      case 'oldest':
        return 'd.created_at ASC, d.id ASC';
      case 'title':
        return 'd.title COLLATE NOCASE ASC, d.id ASC';
      case 'docDate':
        return 'd.document_date DESC, d.id ASC';
      case 'newest':
      default:
        return 'd.created_at DESC, d.id ASC';
    }
  }

  Stream<List<LocalDocument>> watchDocumentPage({
    required String sortBy,
    required int limit,
    int offset = 0,
    bool includeTrashed = false,
    String? category,
    int? fiscalYear,
    String? syncStatus,
    bool favoriteOnly = false,
    String? tagName,
    String? collectionId,
    String? search,
    String? documentNumber,
    int? dateFromMillis,
    int? dateToMillis,
    String? mimeType,
    String? fileNameLike,
  }) {
    final f = _docFilterClause(
      includeTrashed: includeTrashed,
      category: category,
      fiscalYear: fiscalYear,
      syncStatus: syncStatus,
      favoriteOnly: favoriteOnly,
      tagName: tagName,
      collectionId: collectionId,
      search: search,
      documentNumber: documentNumber,
      dateFromMillis: dateFromMillis,
      dateToMillis: dateToMillis,
      mimeType: mimeType,
      fileNameLike: fileNameLike,
    );
    final max = limit < 1 ? 1 : limit;
    final off = offset < 0 ? 0 : offset;
    return customSelect(
      'SELECT d.* FROM local_documents d ${f.where} '
      'ORDER BY ${_docOrderBy(sortBy)} LIMIT $max OFFSET $off',
      variables: f.vars,
      readsFrom: f.reads,
    ).watch().map((rows) => rows.map((r) => localDocuments.map(r.data)).toList());
  }

  Stream<int> watchDocumentCount({
    bool includeTrashed = false,
    String? category,
    int? fiscalYear,
    String? syncStatus,
    bool favoriteOnly = false,
    String? tagName,
    String? collectionId,
    String? search,
    String? documentNumber,
    int? dateFromMillis,
    int? dateToMillis,
    String? mimeType,
    String? fileNameLike,
  }) {
    final f = _docFilterClause(
      includeTrashed: includeTrashed,
      category: category,
      fiscalYear: fiscalYear,
      syncStatus: syncStatus,
      favoriteOnly: favoriteOnly,
      tagName: tagName,
      collectionId: collectionId,
      search: search,
      documentNumber: documentNumber,
      dateFromMillis: dateFromMillis,
      dateToMillis: dateToMillis,
      mimeType: mimeType,
      fileNameLike: fileNameLike,
    );
    return customSelect(
      'SELECT COUNT(*) AS c FROM local_documents d ${f.where}',
      variables: f.vars,
      readsFrom: f.reads,
    ).watch().map((rows) => (rows.first.data['c'] as int?) ?? 0);
  }

  /// Active documents grouped by category code — replaces the O(n) Dart
  /// loop the sidebar ran on every rebuild (Phase 5.6).
  Stream<Map<String, int>> watchCategoryCounts() {
    return customSelect(
      "SELECT d.category AS category, COUNT(*) AS c FROM local_documents d "
      "WHERE d.trashed_at IS NULL AND d.category <> '' GROUP BY d.category",
      readsFrom: {localDocuments},
    ).watch().map((rows) => {
          for (final r in rows) r.data['category'] as String: r.data['c'] as int,
        });
  }

  /// Summary counts straight from the DB. [total] always present; the
  /// CASE/SUM aggregates are null when the library is empty, so default
  /// them. Avoids tallying the whole collection in Dart.
  Stream<({int total, int localOnly, int synced, int attention})>
      watchStatusSummary() {
    return customSelect(
      'SELECT COUNT(*) AS total, '
      "SUM(CASE WHEN d.sync_status = 'local_only' THEN 1 ELSE 0 END) AS local_only, "
      "SUM(CASE WHEN d.sync_status = 'synced' THEN 1 ELSE 0 END) AS synced, "
      "SUM(CASE WHEN d.sync_status IN ('error','deleted','lost') THEN 1 ELSE 0 END) AS attention "
      'FROM local_documents d WHERE d.trashed_at IS NULL',
      readsFrom: {localDocuments},
    ).watch().map((rows) {
      final d = rows.first.data;
      return (
        total: (d['total'] as int?) ?? 0,
        localOnly: (d['local_only'] as int?) ?? 0,
        synced: (d['synced'] as int?) ?? 0,
        attention: (d['attention'] as int?) ?? 0,
      );
    });
  }

  /// Watch a single document by id, so the detail panel refreshes from a
  /// one-row query instead of scanning the whole materialized list.
  Stream<LocalDocument?> watchDocumentById(String id) {
    return (select(localDocuments)..where((t) => t.id.equals(id)))
        .watchSingleOrNull();
  }

  /// Watch the concrete rows behind a set of selected ids. Empty input
  /// short-circuits without touching the database.
  Stream<List<LocalDocument>> watchDocumentsByIds(List<String> ids) {
    if (ids.isEmpty) return Stream.value(const <LocalDocument>[]);
    final placeholders = List<String>.filled(ids.length, '?').join(',');
    return customSelect(
      'SELECT d.* FROM local_documents d '
      'WHERE d.trashed_at IS NULL AND d.id IN ($placeholders)',
      variables: [for (final id in ids) Variable<String>(id)],
      readsFrom: {localDocuments},
    ).watch().map((rows) => rows.map((r) => localDocuments.map(r.data)).toList());
  }
}

/// Which slice of the local_documents table a query targets.
enum DocumentView {
  /// Non-trashed rows only. Default for browsing, counts, and search.
  active,

  /// Only rows the user has moved to the local recycle bin.
  trashed,

  /// No trashed filtering. Used by backup export and health checks.
  all,
}

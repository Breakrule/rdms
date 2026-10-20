import type { Pool } from 'pg';
import type {
  DocumentCategory,
  DocumentRecord,
  DocumentSyncPayload,
  ReconcileResult,
  SyncOperation,
  SyncOperationResult,
} from '../domain/document.entity.js';
import type { IDocumentRepository } from '../domain/document.repository.js';

export class PostgresDocumentRepository implements IDocumentRepository {
  constructor(private readonly pool: Pool) {}

  async upsertBatch(workspaceId: string, payloads: DocumentSyncPayload[]): Promise<{ inserted: number; updated: number }> {
    if (payloads.length === 0) return { inserted: 0, updated: 0 };

    const client = await this.pool.connect();
    let inserted = 0;
    let updated = 0;

    try {
      await client.query('BEGIN');

      // Pre-fetch categories map
      const catRes = await client.query<{ id: string; code: string }>(
        'SELECT id, code FROM document_categories'
      );
      const catMap = new Map(catRes.rows.map((r) => [r.code.toUpperCase(), r.id]));

      for (const item of payloads) {
        let categoryId: string | null = null;
        if (item.categoryCode) {
          categoryId = catMap.get(item.categoryCode.toUpperCase()) ?? null;
          if (!categoryId) {
            // Auto create missing category if needed
            const newCat = await client.query<{ id: string }>(
              'INSERT INTO document_categories (code, name) VALUES ($1, $2) ON CONFLICT (code) DO UPDATE SET name = EXCLUDED.name RETURNING id',
              [item.categoryCode.toUpperCase(), item.categoryCode]
            );
            categoryId = newCat.rows[0].id;
            catMap.set(item.categoryCode.toUpperCase(), categoryId);
          }
        }

        const metadata = {
          ...(item.customMetadata || {}),
          ...(item.extractedText ? { extractedText: item.extractedText } : {}),
          // Phase 4.8: tags ride in custom_metadata (see 003 migration
          // note); a first-class tag table arrives with Phase 3 scoping.
          ...(item.tags && item.tags.length > 0 ? { tags: item.tags } : {}),
        };

        const result = await client.query(
          `INSERT INTO documents (
            client_local_id, title, document_number, category_id,
            document_date, fiscal_year, file_name, file_size_bytes,
            mime_type, sha256_hash, gdrive_file_id, custom_metadata,
            notes, original_file_name, revision, updated_at, workspace_id
          ) VALUES (
            $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, 1, NOW(), $15
          )
          ON CONFLICT (workspace_id, client_local_id) WHERE workspace_id IS NOT NULL DO UPDATE SET
            title = EXCLUDED.title,
            document_number = EXCLUDED.document_number,
            category_id = EXCLUDED.category_id,
            document_date = EXCLUDED.document_date,
            fiscal_year = EXCLUDED.fiscal_year,
            file_name = EXCLUDED.file_name,
            file_size_bytes = EXCLUDED.file_size_bytes,
            mime_type = EXCLUDED.mime_type,
            sha256_hash = EXCLUDED.sha256_hash,
            gdrive_file_id = COALESCE(EXCLUDED.gdrive_file_id, documents.gdrive_file_id),
            custom_metadata = EXCLUDED.custom_metadata,
            notes = EXCLUDED.notes,
            original_file_name = EXCLUDED.original_file_name,
            revision = documents.revision + 1,
            updated_at = NOW()
          RETURNING (xmax = 0) AS is_inserted`,
          [
            item.clientLocalId,
            item.title,
            item.documentNumber ?? null,
            categoryId,
            item.documentDate,
            item.fiscalYear,
            item.fileName,
            item.fileSizeBytes,
            item.mimeType,
            item.sha256Hash,
            item.gdriveFileId ?? null,
            JSON.stringify(metadata),
            item.notes ?? null,
            item.originalFileName ?? null,
            workspaceId,
          ]
        );

        if (result.rows[0]?.is_inserted) {
          inserted++;
        } else {
          updated++;
        }
      }

      await client.query('COMMIT');
      return { inserted, updated };
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  }

  async reconcile(workspaceId: string, items: Array<{ clientLocalId: string; sha256Hash: string }>): Promise<ReconcileResult> {
    if (items.length === 0) {
      return { missingOnServer: [], outdatedOnServer: [], syncedCount: 0 };
    }

    const ids = items.map((i) => i.clientLocalId);
    const res = await this.pool.query<{ client_local_id: string; sha256_hash: string }>(
      'SELECT client_local_id, sha256_hash FROM documents WHERE client_local_id = ANY($1) AND workspace_id = $2',
      [ids, workspaceId]
    );

    const serverDocs = new Map(res.rows.map((r) => [r.client_local_id, r.sha256_hash]));
    const missingOnServer: string[] = [];
    const outdatedOnServer: string[] = [];
    let syncedCount = 0;

    for (const item of items) {
      const serverHash = serverDocs.get(item.clientLocalId);
      if (!serverHash) {
        missingOnServer.push(item.clientLocalId);
      } else if (serverHash !== item.sha256Hash) {
        outdatedOnServer.push(item.clientLocalId);
      } else {
        syncedCount++;
      }
    }

    return { missingOnServer, outdatedOnServer, syncedCount };
  }

  async search(workspaceId: string, query: string, limit = 50, offset = 0): Promise<DocumentRecord[]> {
    const cleanQuery = query.trim();
    if (!cleanQuery) {
      return (await this.list(workspaceId, { limit, offset })).items;
    }

    const res = await this.pool.query(
      `SELECT d.*, c.code as category_code
       FROM documents d
       LEFT JOIN document_categories c ON d.category_id = c.id
       WHERE d.workspace_id = $1
         AND d.search_vector @@ websearch_to_tsquery('simple', $2)
       ORDER BY ts_rank_cd(d.search_vector, websearch_to_tsquery('simple', $2)) DESC, d.created_at DESC
       LIMIT $3 OFFSET $4`,
      [workspaceId, cleanQuery, limit, offset]
    );

    return res.rows.map(this.mapRowToEntity);
  }

  async list(workspaceId: string, filters: { categoryCode?: string; fiscalYear?: number; limit?: number; offset?: number }): Promise<{ items: DocumentRecord[]; total: number }> {
    const limit = filters.limit ?? 50;
    const offset = filters.offset ?? 0;
    const conditions: string[] = ['d.workspace_id = $1'];
    const values: unknown[] = [workspaceId];

    if (filters.categoryCode && filters.categoryCode !== 'ALL') {
      values.push(filters.categoryCode.toUpperCase());
      conditions.push(`c.code = $${values.length}`);
    }

    if (filters.fiscalYear) {
      values.push(filters.fiscalYear);
      conditions.push(`d.fiscal_year = $${values.length}`);
    }

    const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

    const countRes = await this.pool.query<{ count: string }>(
      `SELECT count(*)::text as count FROM documents d LEFT JOIN document_categories c ON d.category_id = c.id ${whereClause}`,
      values
    );

    values.push(limit);
    const limitIdx = values.length;
    values.push(offset);
    const offsetIdx = values.length;

    const dataRes = await this.pool.query(
      `SELECT d.*, c.code as category_code
       FROM documents d
       LEFT JOIN document_categories c ON d.category_id = c.id
       ${whereClause}
       ORDER BY d.created_at DESC
       LIMIT $${limitIdx} OFFSET $${offsetIdx}`,
      values
    );

    return {
      items: dataRes.rows.map(this.mapRowToEntity),
      total: parseInt(countRes.rows[0]?.count || '0', 10),
    };
  }

  async getById(workspaceId: string, id: string): Promise<DocumentRecord | null> {
    const res = await this.pool.query(
      `SELECT d.*, c.code as category_code
       FROM documents d
       LEFT JOIN document_categories c ON d.category_id = c.id
       WHERE d.id = $1 AND d.workspace_id = $2`,
      [id, workspaceId]
    );
    if (res.rows.length === 0) return null;
    return this.mapRowToEntity(res.rows[0]);
  }

  async getByClientLocalId(workspaceId: string, clientLocalId: string): Promise<DocumentRecord | null> {
    const res = await this.pool.query(
      `SELECT d.*, c.code as category_code
       FROM documents d
       LEFT JOIN document_categories c ON d.category_id = c.id
       WHERE d.client_local_id = $1 AND d.workspace_id = $2`,
      [clientLocalId, workspaceId]
    );
    if (res.rows.length === 0) return null;
    return this.mapRowToEntity(res.rows[0]);
  }

  async getCategories(): Promise<DocumentCategory[]> {
    const res = await this.pool.query<DocumentCategory>(
      'SELECT id, code, name FROM document_categories ORDER BY code ASC'
    );
    return res.rows;
  }

  private mapRowToEntity(row: any): DocumentRecord {
    return {
      id: row.id,
      clientLocalId: row.client_local_id,
      title: row.title,
      documentNumber: row.document_number,
      categoryId: row.category_id,
      categoryCode: row.category_code,
      documentDate: typeof row.document_date === 'string' ? row.document_date : row.document_date.toISOString().split('T')[0],
      fiscalYear: row.fiscal_year,
      fileName: row.file_name,
      fileSizeBytes: Number(row.file_size_bytes),
      mimeType: row.mime_type,
      sha256Hash: row.sha256_hash,
      gdriveFileId: row.gdrive_file_id,
      customMetadata: row.custom_metadata || {},
      notes: row.notes ?? null,
      originalFileName: row.original_file_name ?? null,
      revision: Number(row.revision ?? 1),
      workspaceId: row.workspace_id ?? null,
      createdAt: row.created_at,
      updatedAt: row.updated_at,
    };
  }

  /// Phase 2.6: revision-aware batch with idempotency.
  ///
  /// All ledger checks, comparisons, and mutations run inside a single
  /// PostgreSQL transaction. Any failure rolls the whole batch back, so
  /// a partially-applied batch cannot leave the accepted_operations
  /// ledger and the documents table disagreeing.
  async applyOperations(workspaceId: string, operations: SyncOperation[]): Promise<SyncOperationResult[]> {
    if (operations.length === 0) return [];

    const client = await this.pool.connect();
    try {
      await client.query('BEGIN');
      const catRes = await client.query<{ id: string; code: string }>(
        'SELECT id, code FROM document_categories',
      );
      const catMap = new Map(catRes.rows.map((r) => [r.code.toUpperCase(), r.id]));

      const results: SyncOperationResult[] = [];
      for (const op of operations) {
        // 1. Idempotency check, scoped to this workspace. A receipt from
        //    another workspace is invisible, so cross-workspace replays
        //    cannot read one another's outcomes.
        const prior = await client.query<{
          outcome: string;
          revision_after: number;
          error_code: string | null;
          client_local_id: string;
        }>(
          'SELECT outcome, revision_after, error_code, client_local_id FROM accepted_operations WHERE operation_id = $1 AND workspace_id = $2',
          [op.operationId, workspaceId],
        );
        if (prior.rowCount && prior.rows.length > 0) {
          const row = prior.rows[0];
          const serverDoc = await client.query<{ id: string }>(
            'SELECT id FROM documents WHERE client_local_id = $1 AND workspace_id = $2',
            [row.client_local_id, workspaceId],
          );
          results.push({
            operationId: op.operationId,
            outcome: row.outcome as SyncOperationResult['outcome'],
            serverDocumentId: serverDoc.rows[0]?.id ?? null,
            revisionAfter: row.revision_after,
            errorCode: row.error_code ?? undefined,
          });
          continue;
        }

        // 2. Look up current revision within this workspace (if any).
        const existing = await client.query<{ id: string; revision: number }>(
          'SELECT id, revision FROM documents WHERE client_local_id = $1 AND workspace_id = $2',
          [op.clientLocalId, workspaceId],
        );

        if (existing.rowCount && existing.rows.length > 0) {
          const currentRevision = Number(existing.rows[0].revision);
          if (op.baseRevision !== currentRevision) {
            // Conflict: record and do NOT mutate. Retry of this opId
            // returns the same conflict until the client rebases.
            await client.query(
              'INSERT INTO accepted_operations (operation_id, client_local_id, outcome, revision_after, error_code, workspace_id) VALUES ($1, $2, $3, $4, $5, $6)',
              [op.operationId, op.clientLocalId, 'conflict', currentRevision, 'stale_base_revision', workspaceId],
            );
            results.push({
              operationId: op.operationId,
              outcome: 'conflict',
              serverDocumentId: existing.rows[0].id,
              revisionAfter: currentRevision,
              errorCode: 'stale_base_revision',
            });
            continue;
          }
        }

        // 3. Apply the mutation. Same category-resolution logic as v1.
        let categoryId: string | null = null;
        if (op.payload.categoryCode) {
          const code = op.payload.categoryCode.toUpperCase();
          categoryId = catMap.get(code) ?? null;
          if (!categoryId) {
            const newCat = await client.query<{ id: string }>(
              'INSERT INTO document_categories (code, name) VALUES ($1, $2) ON CONFLICT (code) DO UPDATE SET name = EXCLUDED.name RETURNING id',
              [code, op.payload.categoryCode],
            );
            categoryId = newCat.rows[0].id;
            catMap.set(code, categoryId);
          }
        }
        const metadata = {
          ...(op.payload.customMetadata || {}),
          ...(op.payload.extractedText ? { extractedText: op.payload.extractedText } : {}),
          ...(op.payload.tags && op.payload.tags.length > 0 ? { tags: op.payload.tags } : {}),
        };

        const upsert = await client.query<{ id: string; revision: number }>(
          `INSERT INTO documents (
            client_local_id, title, document_number, category_id,
            document_date, fiscal_year, file_name, file_size_bytes,
            mime_type, sha256_hash, gdrive_file_id, custom_metadata,
            notes, original_file_name, revision, updated_at, workspace_id
          ) VALUES (
            $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, 1, NOW(), $15
          )
          ON CONFLICT (workspace_id, client_local_id) WHERE workspace_id IS NOT NULL DO UPDATE SET
            title = EXCLUDED.title,
            document_number = EXCLUDED.document_number,
            category_id = EXCLUDED.category_id,
            document_date = EXCLUDED.document_date,
            fiscal_year = EXCLUDED.fiscal_year,
            file_name = EXCLUDED.file_name,
            file_size_bytes = EXCLUDED.file_size_bytes,
            mime_type = EXCLUDED.mime_type,
            sha256_hash = EXCLUDED.sha256_hash,
            gdrive_file_id = COALESCE(EXCLUDED.gdrive_file_id, documents.gdrive_file_id),
            custom_metadata = EXCLUDED.custom_metadata,
            notes = EXCLUDED.notes,
            original_file_name = EXCLUDED.original_file_name,
            revision = documents.revision + 1,
            updated_at = NOW()
          RETURNING id, revision`,
          [
            op.payload.clientLocalId,
            op.payload.title,
            op.payload.documentNumber ?? null,
            categoryId,
            op.payload.documentDate,
            op.payload.fiscalYear,
            op.payload.fileName,
            op.payload.fileSizeBytes,
            op.payload.mimeType,
            op.payload.sha256Hash,
            op.payload.gdriveFileId ?? null,
            JSON.stringify(metadata),
            op.payload.notes ?? null,
            op.payload.originalFileName ?? null,
            workspaceId,
          ],
        );

        const revisionAfter = Number(upsert.rows[0].revision);
        const serverDocumentId = upsert.rows[0].id;
        await client.query(
          'INSERT INTO accepted_operations (operation_id, client_local_id, outcome, revision_after, workspace_id) VALUES ($1, $2, $3, $4, $5)',
          [op.operationId, op.clientLocalId, 'applied', revisionAfter, workspaceId],
        );
        results.push({
          operationId: op.operationId,
          outcome: 'applied',
          serverDocumentId,
          revisionAfter,
        });
      }

      await client.query('COMMIT');
      return results;
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  }
}

import { randomUUID } from 'node:crypto';
import type { IDocumentRepository } from '../domain/document.repository.js';
import type {
  DocumentCategory,
  DocumentRecord,
  DocumentSyncPayload,
  ReconcileResult,
  SyncOperation,
  SyncOperationResult,
} from '../domain/document.entity.js';

/// Test double for [IDocumentRepository] that enforces the same Phase 3.3
/// workspace-scoping contract as the PostgreSQL repository: documents and
/// idempotency receipts are keyed per workspace, and every read is
/// filtered to the caller's workspace. It lets authorization be verified
/// without a live database, and doubles as an executable spec of the
/// scoping semantics.
export class MockDocumentRepository implements IDocumentRepository {
  private readonly docs = new Map<string, DocumentRecord>();
  private readonly ledger = new Map<string, SyncOperationResult>();

  private docKey(ws: string, clientLocalId: string): string {
    return `${ws}::${clientLocalId}`;
  }
  private opKey(ws: string, operationId: string): string {
    return `${ws}::${operationId}`;
  }
  private docsOf(ws: string): DocumentRecord[] {
    return Array.from(this.docs.values()).filter((d) => d.workspaceId === ws);
  }

  private recordFromPayload(
    ws: string,
    p: DocumentSyncPayload,
    revision: number,
  ): DocumentRecord {
    return {
      id: randomUUID(),
      clientLocalId: p.clientLocalId,
      title: p.title,
      documentNumber: p.documentNumber ?? null,
      categoryId: 'cat-1',
      categoryCode: p.categoryCode,
      documentDate: p.documentDate,
      fiscalYear: p.fiscalYear,
      fileName: p.fileName,
      fileSizeBytes: p.fileSizeBytes,
      mimeType: p.mimeType,
      sha256Hash: p.sha256Hash,
      gdriveFileId: p.gdriveFileId ?? null,
      customMetadata: {
        ...(p.customMetadata ?? {}),
        ...(p.tags && p.tags.length > 0 ? { tags: p.tags } : {}),
      },
      notes: p.notes ?? null,
      originalFileName: p.originalFileName ?? null,
      revision,
      workspaceId: ws,
      createdAt: new Date(),
      updatedAt: new Date(),
    };
  }

  async upsertBatch(
    ws: string,
    payloads: DocumentSyncPayload[],
  ): Promise<{ inserted: number; updated: number }> {
    let inserted = 0;
    let updated = 0;
    for (const p of payloads) {
      const k = this.docKey(ws, p.clientLocalId);
      const prior = this.docs.get(k);
      if (prior) {
        updated++;
        this.docs.set(k, {
          ...prior,
          title: p.title,
          documentNumber: p.documentNumber ?? null,
          revision: prior.revision + 1,
        });
      } else {
        inserted++;
        this.docs.set(k, this.recordFromPayload(ws, p, 1));
      }
    }
    return { inserted, updated };
  }

  async reconcile(
    ws: string,
    items: Array<{ clientLocalId: string; sha256Hash: string }>,
  ): Promise<ReconcileResult> {
    const missingOnServer: string[] = [];
    const outdatedOnServer: string[] = [];
    let syncedCount = 0;
    for (const item of items) {
      const existing = this.docs.get(this.docKey(ws, item.clientLocalId));
      if (!existing) missingOnServer.push(item.clientLocalId);
      else if (existing.sha256Hash !== item.sha256Hash) outdatedOnServer.push(item.clientLocalId);
      else syncedCount++;
    }
    return { missingOnServer, outdatedOnServer, syncedCount };
  }

  async search(ws: string, query: string): Promise<DocumentRecord[]> {
    const q = query.toLowerCase();
    return this.docsOf(ws).filter((d) => d.title.toLowerCase().includes(q));
  }

  async list(
    ws: string,
  ): Promise<{ items: DocumentRecord[]; total: number }> {
    const items = this.docsOf(ws);
    return { items, total: items.length };
  }

  async getById(ws: string, id: string): Promise<DocumentRecord | null> {
    return this.docsOf(ws).find((d) => d.id === id) ?? null;
  }

  async getByClientLocalId(
    ws: string,
    clientLocalId: string,
  ): Promise<DocumentRecord | null> {
    return this.docs.get(this.docKey(ws, clientLocalId)) ?? null;
  }

  async getCategories(): Promise<DocumentCategory[]> {
    return [{ id: 'cat-1', code: 'SK', name: 'Surat Keputusan' }];
  }

  /// Phase 2.6 + 3.3: revision-aware, workspace-scoped batch. A receipt is
  /// visible only to its own workspace, so cross-workspace replays cannot
  /// read one another's outcomes.
  async applyOperations(
    ws: string,
    operations: SyncOperation[],
  ): Promise<SyncOperationResult[]> {
    const results: SyncOperationResult[] = [];
    for (const op of operations) {
      const prior = this.ledger.get(this.opKey(ws, op.operationId));
      if (prior) {
        results.push(prior);
        continue;
      }
      const k = this.docKey(ws, op.clientLocalId);
      const existing = this.docs.get(k);
      if (existing) {
        if (op.baseRevision !== existing.revision) {
          const conflict: SyncOperationResult = {
            operationId: op.operationId,
            outcome: 'conflict',
            serverDocumentId: existing.id,
            revisionAfter: existing.revision,
            errorCode: 'stale_base_revision',
          };
          this.ledger.set(this.opKey(ws, op.operationId), conflict);
          results.push(conflict);
          continue;
        }
        const bumped = existing.revision + 1;
        const merged: DocumentRecord = {
          ...existing,
          title: op.payload.title,
          documentNumber: op.payload.documentNumber ?? null,
          sha256Hash: op.payload.sha256Hash,
          fileName: op.payload.fileName,
          fileSizeBytes: op.payload.fileSizeBytes,
          mimeType: op.payload.mimeType,
          gdriveFileId: op.payload.gdriveFileId ?? existing.gdriveFileId,
          customMetadata:
            op.payload.tags && op.payload.tags.length > 0
              ? { ...(op.payload.customMetadata ?? existing.customMetadata), tags: op.payload.tags }
              : op.payload.customMetadata ?? existing.customMetadata,
          notes: op.payload.notes ?? existing.notes,
          originalFileName: op.payload.originalFileName ?? existing.originalFileName,
          revision: bumped,
        };
        this.docs.set(k, merged);
        const applied: SyncOperationResult = {
          operationId: op.operationId,
          outcome: 'applied',
          serverDocumentId: merged.id,
          revisionAfter: bumped,
        };
        this.ledger.set(this.opKey(ws, op.operationId), applied);
        results.push(applied);
      } else {
        const created = this.recordFromPayload(ws, op.payload, 1);
        this.docs.set(k, created);
        const applied: SyncOperationResult = {
          operationId: op.operationId,
          outcome: 'applied',
          serverDocumentId: created.id,
          revisionAfter: 1,
        };
        this.ledger.set(this.opKey(ws, op.operationId), applied);
        results.push(applied);
      }
    }
    return results;
  }
}

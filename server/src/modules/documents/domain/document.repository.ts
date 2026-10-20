import type {
  DocumentCategory,
  DocumentRecord,
  DocumentSyncPayload,
  ReconcileResult,
  SyncOperation,
  SyncOperationResult,
} from './document.entity.js';

export interface IDocumentRepository {
  // Phase 3.3: every document-touching path is scoped to an authorized
  // workspace. `workspaceId` is a required leading argument (never taken
  // from the payload), so a repository call without one cannot compile.
  // getCategories stays unscoped: categories are shared reference data.
  upsertBatch(workspaceId: string, payloads: DocumentSyncPayload[]): Promise<{ inserted: number; updated: number }>;
  reconcile(workspaceId: string, items: Array<{ clientLocalId: string; sha256Hash: string }>): Promise<ReconcileResult>;
  search(workspaceId: string, query: string, limit?: number, offset?: number): Promise<DocumentRecord[]>;
  list(workspaceId: string, filters: { categoryCode?: string; fiscalYear?: number; limit?: number; offset?: number }): Promise<{ items: DocumentRecord[]; total: number }>;
  getById(workspaceId: string, id: string): Promise<DocumentRecord | null>;
  getByClientLocalId(workspaceId: string, clientLocalId: string): Promise<DocumentRecord | null>;
  getCategories(): Promise<DocumentCategory[]>;
  /// Phase 2.6: revision-aware batch, Phase 3.3 workspace-scoped.
  /// Implementations MUST:
  /// 1. Consult the workspace-scoped accepted_operations ledger first
  ///    (idempotency): a receipt is only visible to its own workspace.
  /// 2. Compare operation.baseRevision against the current document
  ///    revision before applying a mutation.
  /// 3. Persist the outcome (applied / conflict / rejected) atomically
  ///    with the mutation itself so a crashed batch cannot half-apply.
  /// 4. Stamp / conflict-check against the caller's workspace, never
  ///    another workspace's row.
  applyOperations(workspaceId: string, operations: SyncOperation[]): Promise<SyncOperationResult[]>;
}

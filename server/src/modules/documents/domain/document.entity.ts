export interface DocumentCategory {
  id: string;
  code: string;
  name: string;
}

export interface DocumentRecord {
  id: string;
  clientLocalId: string;
  title: string;
  documentNumber: string | null;
  categoryId: string | null;
  categoryCode?: string;
  documentDate: string; // YYYY-MM-DD
  fiscalYear: number;
  fileName: string;
  fileSizeBytes: number;
  mimeType: string;
  sha256Hash: string;
  gdriveFileId: string | null;
  customMetadata: Record<string, unknown>;
  /// Phase 4.1 user-authored note (migration 003).
  notes: string | null;
  /// Phase 4.4 pre-rename original file name (migration 003).
  originalFileName: string | null;
  /// Monotonic per-document revision counter (migration 002).
  revision: number;
  /// Phase 3.2 owning workspace. Scoped reads always return the caller's
  /// own workspace id; quarantined legacy rows carry NULL and are never
  /// surfaced through an authenticated path.
  workspaceId: string | null;
  createdAt: Date;
  updatedAt: Date;
}

export interface DocumentSyncPayload {
  clientLocalId: string;
  title: string;
  documentNumber?: string | null;
  categoryCode: string;
  documentDate: string; // YYYY-MM-DD
  fiscalYear: number;
  fileName: string;
  fileSizeBytes: number;
  mimeType: string;
  sha256Hash: string;
  gdriveFileId?: string | null;
  extractedText?: string | null;
  notes?: string | null;
  originalFileName?: string | null;
  /// Phase 4.8: tag names travel inside customMetadata.tags on the
  /// server side (see 003 migration note); the client sends them as a
  /// first-class field so the repository can place them.
  tags?: string[];
  customMetadata?: Record<string, unknown>;
}

export interface ReconcilePayload {
  items: Array<{
    clientLocalId: string;
    sha256Hash: string;
  }>;
}

export interface ReconcileResult {
  missingOnServer: string[]; // List of clientLocalIds not yet in PostgreSQL
  outdatedOnServer: string[]; // List of clientLocalIds where SHA256 differs
  syncedCount: number;
}

/// Phase 2.6 request body for `POST /api/v2/sync/batch`.
///
/// Each operation carries a client-generated UUID `operationId` that
/// doubles as the idempotency key. A retry of the same `operationId`
/// returns the ORIGINAL outcome (applied | conflict | rejected) and
/// does not re-apply the mutation.
///
/// `baseRevision` is the revision the client last saw. A mismatch with
/// the server's current revision yields `conflict`; the payload is NOT
/// applied and the client is expected to reconcile (Phase 6 conflict
/// resolution UI).
export interface SyncOperation {
  operationId: string;
  clientLocalId: string;
  baseRevision: number;
  kind: 'upsert';
  payload: DocumentSyncPayload;
}

export type SyncOperationOutcome = 'applied' | 'conflict' | 'rejected';

export interface SyncOperationResult {
  operationId: string;
  outcome: SyncOperationOutcome;
  serverDocumentId: string | null;
  revisionAfter: number;
  errorCode?: string;
}

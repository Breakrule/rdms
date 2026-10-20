import type {
  SyncOperation,
  SyncOperationResult,
} from '../domain/document.entity.js';
import type { IDocumentRepository } from '../domain/document.repository.js';

/**
 * Phase 2.6 revision-aware batch. The heavy lifting is in the repository
 * (single transaction, ledger checks); this use case enforces the
 * inbound contract and shapes the response for the HTTP layer.
 *
 * Contract:
 * - A batch is at most 100 operations (matches the client's own cap so
 *   a malformed caller cannot pin the transaction open).
 * - `applied` returns the new server revision; `conflict` returns the
 *   current server revision WITHOUT mutating.
 * - Re-sending the same `operationId` returns the ORIGINAL outcome.
 */
export class ApplySyncOperationsUseCase {
  static readonly MAX_BATCH_SIZE = 100;

  constructor(private readonly repository: IDocumentRepository) {}

  async execute(workspaceId: string, operations: SyncOperation[]): Promise<{
    success: boolean;
    totalReceived: number;
    results: SyncOperationResult[];
  }> {
    if (!Array.isArray(operations)) {
      throw new Error('operations must be an array');
    }
    if (operations.length > ApplySyncOperationsUseCase.MAX_BATCH_SIZE) {
      throw new Error(
        `batch exceeds max size ${ApplySyncOperationsUseCase.MAX_BATCH_SIZE}`,
      );
    }
    const seen = new Set<string>();
    for (const op of operations) {
      if (!op.operationId) throw new Error('every operation needs an operationId');
      if (seen.has(op.operationId)) {
        throw new Error(`duplicate operationId within a single batch: ${op.operationId}`);
      }
      seen.add(op.operationId);
    }
    const results = await this.repository.applyOperations(workspaceId, operations);
    return {
      success: true,
      totalReceived: operations.length,
      results,
    };
  }
}

import type { ReconcilePayload, ReconcileResult } from '../domain/document.entity.js';
import type { IDocumentRepository } from '../domain/document.repository.js';

export class ReconcileUseCase {
  constructor(private readonly repository: IDocumentRepository) {}

  async execute(workspaceId: string, payload: ReconcilePayload): Promise<ReconcileResult> {
    if (!payload.items || payload.items.length === 0) {
      return {
        missingOnServer: [],
        outdatedOnServer: [],
        syncedCount: 0,
      };
    }

    return this.repository.reconcile(workspaceId, payload.items);
  }
}

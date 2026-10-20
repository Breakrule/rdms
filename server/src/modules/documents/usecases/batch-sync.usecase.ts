import type { DocumentSyncPayload } from '../domain/document.entity.js';
import type { IDocumentRepository } from '../domain/document.repository.js';

export class BatchSyncUseCase {
  constructor(private readonly repository: IDocumentRepository) {}

  async execute(workspaceId: string, payloads: DocumentSyncPayload[]): Promise<{
    success: boolean;
    totalReceived: number;
    inserted: number;
    updated: number;
  }> {
    if (!payloads || payloads.length === 0) {
      return {
        success: true,
        totalReceived: 0,
        inserted: 0,
        updated: 0,
      };
    }

    const { inserted, updated } = await this.repository.upsertBatch(workspaceId, payloads);

    return {
      success: true,
      totalReceived: payloads.length,
      inserted,
      updated,
    };
  }
}

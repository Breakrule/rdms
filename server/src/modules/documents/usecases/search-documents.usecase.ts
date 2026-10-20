import type { DocumentRecord } from '../domain/document.entity.js';
import type { IDocumentRepository } from '../domain/document.repository.js';

export class SearchDocumentsUseCase {
  constructor(private readonly repository: IDocumentRepository) {}

  async execute(workspaceId: string, query: string, limit = 50, offset = 0): Promise<DocumentRecord[]> {
    return this.repository.search(workspaceId, query, limit, offset);
  }
}

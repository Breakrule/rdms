import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { BatchSyncUseCase } from './batch-sync.usecase.js';
import { ReconcileUseCase } from './reconcile.usecase.js';
import { SearchDocumentsUseCase } from './search-documents.usecase.js';
import { ApplySyncOperationsUseCase } from './apply-sync-operations.usecase.js';
import { MockDocumentRepository } from '../infra/mock-document.repository.js';
import type { DocumentSyncPayload } from '../domain/document.entity.js';

// Phase 3.3 threaded every document path through a workspace. These use
// one fixed workspace; the cross-workspace isolation guarantees are
// exercised in document.authorization.test.ts.
const WS = 'ws-default';

describe('Backend Document Sync & Reconciliation Use Cases', () => {
  it('BatchSyncUseCase inserts new documents and idempotently updates existing', async () => {
    const repo = new MockDocumentRepository();
    const useCase = new BatchSyncUseCase(repo);

    const doc1: DocumentSyncPayload = {
      clientLocalId: 'client-uuid-001',
      title: 'SK Tim Reformasi Birokrasi',
      categoryCode: 'SK',
      documentDate: '2026-01-15',
      fiscalYear: 2026,
      fileName: '20260115_SK_Reformasi_a1b2c3d4.pdf',
      fileSizeBytes: 1048576,
      mimeType: 'application/pdf',
      sha256Hash: 'a'.repeat(64),
    };

    // First run: inserts
    const res1 = await useCase.execute(WS, [doc1]);
    assert.strictEqual(res1.inserted, 1);
    assert.strictEqual(res1.updated, 0);

    // Second run with modified title: idempotently updates
    const doc1Updated: DocumentSyncPayload = {
      ...doc1,
      title: 'SK Tim Reformasi Birokrasi (Revisi)',
    };
    const res2 = await useCase.execute(WS, [doc1Updated]);
    assert.strictEqual(res2.inserted, 0);
    assert.strictEqual(res2.updated, 1);

    const stored = await repo.getByClientLocalId(WS, 'client-uuid-001');
    assert.strictEqual(stored?.title, 'SK Tim Reformasi Birokrasi (Revisi)');
  });

  it('ReconcileUseCase accurately detects missing, outdated, and synced documents', async () => {
    const repo = new MockDocumentRepository();
    const batchUseCase = new BatchSyncUseCase(repo);
    const reconcileUseCase = new ReconcileUseCase(repo);

    // Seed server with doc A
    await batchUseCase.execute(WS, [
      {
        clientLocalId: 'doc-A',
        title: 'Dokumen A',
        categoryCode: 'LAPORAN',
        documentDate: '2026-02-01',
        fiscalYear: 2026,
        fileName: 'doc_a.pdf',
        fileSizeBytes: 2048,
        mimeType: 'application/pdf',
        sha256Hash: '1'.repeat(64),
      },
      {
        clientLocalId: 'doc-B',
        title: 'Dokumen B',
        categoryCode: 'NOTULA',
        documentDate: '2026-02-05',
        fiscalYear: 2026,
        fileName: 'doc_b.pdf',
        fileSizeBytes: 4096,
        mimeType: 'application/pdf',
        sha256Hash: '2'.repeat(64),
      },
    ]);

    // Client requests reconcile:
    // doc-A matches
    // doc-B has changed hash on client
    // doc-C does not exist on server
    const result = await reconcileUseCase.execute(WS, {
      items: [
        { clientLocalId: 'doc-A', sha256Hash: '1'.repeat(64) },
        { clientLocalId: 'doc-B', sha256Hash: '3'.repeat(64) },
        { clientLocalId: 'doc-C', sha256Hash: '4'.repeat(64) },
      ],
    });

    assert.strictEqual(result.syncedCount, 1);
    assert.deepStrictEqual(result.outdatedOnServer, ['doc-B']);
    assert.deepStrictEqual(result.missingOnServer, ['doc-C']);
  });

  it('SearchDocumentsUseCase delegates query properly', async () => {
    const repo = new MockDocumentRepository();
    const batchUseCase = new BatchSyncUseCase(repo);
    const searchUseCase = new SearchDocumentsUseCase(repo);

    await batchUseCase.execute(WS, [
      {
        clientLocalId: 'doc-1',
        title: 'Laporan Keuangan Semester 1',
        categoryCode: 'LAPORAN',
        documentDate: '2026-06-30',
        fiscalYear: 2026,
        fileName: 'lap_keu.pdf',
        fileSizeBytes: 5000,
        mimeType: 'application/pdf',
        sha256Hash: '5'.repeat(64),
      },
    ]);

    const results = await searchUseCase.execute(WS, 'Keuangan');
    assert.strictEqual(results.length, 1);
    assert.strictEqual(results[0].title, 'Laporan Keuangan Semester 1');
  });
});

describe('Phase 2.6: ApplySyncOperationsUseCase (revision-aware batch)', () => {
  const payload = (
    overrides: Partial<DocumentSyncPayload> = {},
  ): DocumentSyncPayload => ({
    clientLocalId: 'doc-A',
    title: 'Dokumen A',
    categoryCode: 'SK',
    documentDate: '2026-01-15',
    fiscalYear: 2026,
    fileName: 'doc_a.pdf',
    fileSizeBytes: 1024,
    mimeType: 'application/pdf',
    sha256Hash: 'a'.repeat(64),
    ...overrides,
  });

  const op = (
    operationId: string,
    baseRevision: number,
    payloadOverrides: Partial<DocumentSyncPayload> = {},
  ) => ({
    operationId,
    clientLocalId: payloadOverrides.clientLocalId ?? 'doc-A',
    baseRevision,
    kind: 'upsert' as const,
    payload: payload(payloadOverrides),
  });

  it('creates a new document at revision 1', async () => {
    const repo = new MockDocumentRepository();
    const useCase = new ApplySyncOperationsUseCase(repo);
    const out = await useCase.execute(WS, [op('op-1', 0)]);
    assert.equal(out.results[0].outcome, 'applied');
    assert.equal(out.results[0].revisionAfter, 1);
  });

  it('rejects a stale baseRevision with conflict and does NOT mutate', async () => {
    const repo = new MockDocumentRepository();
    const useCase = new ApplySyncOperationsUseCase(repo);
    await useCase.execute(WS, [op('op-1', 0)]);
    // Someone else has advanced to revision 1; a client that still
    // thinks baseRevision=0 must not be able to overwrite.
    const conflict = await useCase.execute(WS, [op('op-2', 99, { title: 'stale' })]);
    assert.equal(conflict.results[0].outcome, 'conflict');
    assert.equal(conflict.results[0].errorCode, 'stale_base_revision');
    // Verify the title change was NOT applied.
    const stored = await repo.getByClientLocalId(WS, 'doc-A');
    assert.equal(stored?.title, 'Dokumen A');
  });

  it('a repeated operationId returns the ORIGINAL result (idempotency)', async () => {
    const repo = new MockDocumentRepository();
    const useCase = new ApplySyncOperationsUseCase(repo);
    const first = await useCase.execute(WS, [op('op-dup', 0)]);
    const replay = await useCase.execute(WS, [op('op-dup', 0)]);
    assert.deepEqual(replay.results, first.results);
    // The replay did not bump the revision again.
    const stored = await repo.getByClientLocalId(WS, 'doc-A');
    assert.equal(stored?.revision, 1);
  });

  it('a metadata-only change advances the revision even when the hash is unchanged', async () => {
    const repo = new MockDocumentRepository();
    const useCase = new ApplySyncOperationsUseCase(repo);
    await useCase.execute(WS, [op('op-1', 0)]);
    const next = await useCase.execute(WS, [op('op-2', 1, { title: 'Judul Revisi' })]);
    assert.equal(next.results[0].outcome, 'applied');
    assert.equal(next.results[0].revisionAfter, 2);
    const stored = await repo.getByClientLocalId(WS, 'doc-A');
    assert.equal(stored?.title, 'Judul Revisi');
    assert.equal(stored?.sha256Hash, 'a'.repeat(64));
  });

  it('rejects a batch with duplicate operationIds inside one request', async () => {
    const repo = new MockDocumentRepository();
    const useCase = new ApplySyncOperationsUseCase(repo);
    await assert.rejects(
      () => useCase.execute(WS, [op('dup', 0), op('dup', 0)]),
      /duplicate operationId/,
    );
  });

  it('rejects a batch that exceeds MAX_BATCH_SIZE', async () => {
    const repo = new MockDocumentRepository();
    const useCase = new ApplySyncOperationsUseCase(repo);
    const bigBatch = Array.from({ length: 101 }, (_, i) => op(`op-${i}`, 0, { clientLocalId: `doc-${i}` }));
    await assert.rejects(
      () => useCase.execute(WS, bigBatch),
      /batch exceeds max size/,
    );
  });

  it('Phase 4.8: notes/originalFileName/tags persist through the batch', async () => {
    const repo = new MockDocumentRepository();
    const useCase = new ApplySyncOperationsUseCase(repo);
    await useCase.execute(WS, [
      op('op-meta', 0, {
        notes: 'Catatan reviewer',
        originalFileName: 'surat-asli.pdf',
        tags: ['penting', 'arsip-2026'],
      }),
    ]);
    const stored = await repo.getByClientLocalId(WS, 'doc-A');
    assert.equal(stored?.notes, 'Catatan reviewer');
    assert.equal(stored?.originalFileName, 'surat-asli.pdf');
    assert.deepEqual((stored?.customMetadata as { tags?: string[] }).tags,
      ['penting', 'arsip-2026']);
  });
});

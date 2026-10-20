import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import {
  DocumentSyncPayloadSchema,
  BatchSyncSchema,
  ReconcileSchema,
  ListQuerySchema,
  SearchQuerySchema,
  uuidString,
  isoCalendarDate,
  sha256Hex,
  parseBoundedInt,
} from './document.controller.js';

/**
 * Phase 0.4 baseline: request-validation contract.
 *
 * These cases exist so loosening a bound in the controller has to be an
 * explicit edit here too. Every "rejects" case corresponds to a payload
 * that previously reached PostgreSQL (or a `.getSingle()` on a NaN) and
 * surfaced as a 500 rather than a described 4xx.
 *
 * Not covered here: repository / DB behaviour (see usecases tests) and
 * HTTP status codes (integration scope, deferred to Phase 9 CI).
 */

const validPayload = () => ({
  clientLocalId: 'doc-A',
  title: 'Surat Keputusan',
  categoryCode: 'SK',
  documentDate: '2026-01-15',
  fiscalYear: 2026,
  fileName: '20260115_SK_aaaa.pdf',
  fileSizeBytes: 1024,
  mimeType: 'application/pdf',
  sha256Hash: 'a'.repeat(64),
});

describe('Phase 0.4: DocumentSyncPayloadSchema', () => {
  it('accepts a fully valid payload', () => {
    const parsed = DocumentSyncPayloadSchema.safeParse(validPayload());
    assert.equal(parsed.success, true, JSON.stringify((parsed as { error?: unknown }).error));
  });

  it('rejects a syntactically-shaped but non-calendar date', () => {
    const parsed = DocumentSyncPayloadSchema.safeParse({
      ...validPayload(),
      documentDate: '2026-13-45',
    });
    assert.equal(parsed.success, false);
  });

  it('rejects Feb 30', () => {
    const parsed = DocumentSyncPayloadSchema.safeParse({
      ...validPayload(),
      documentDate: '2026-02-30',
    });
    assert.equal(parsed.success, false);
  });

  it('accepts Feb 29 on a leap year', () => {
    const parsed = DocumentSyncPayloadSchema.safeParse({
      ...validPayload(),
      documentDate: '2024-02-29',
    });
    assert.equal(parsed.success, true);
  });

  it('rejects a non-hex sha256Hash of the right length', () => {
    const parsed = DocumentSyncPayloadSchema.safeParse({
      ...validPayload(),
      sha256Hash: 'z'.repeat(64),
    });
    assert.equal(parsed.success, false);
  });

  it('rejects an overlong documentNumber', () => {
    const parsed = DocumentSyncPayloadSchema.safeParse({
      ...validPayload(),
      documentNumber: 'X'.repeat(101),
    });
    assert.equal(parsed.success, false);
  });

  it('rejects a whitespace-only title', () => {
    const parsed = DocumentSyncPayloadSchema.safeParse({
      ...validPayload(),
      title: '     ',
    });
    assert.equal(parsed.success, false);
  });

  it('rejects a category code with disallowed characters', () => {
    const parsed = DocumentSyncPayloadSchema.safeParse({
      ...validPayload(),
      categoryCode: 'SK/../etc',
    });
    assert.equal(parsed.success, false);
  });

  it('rejects negative file size', () => {
    const parsed = DocumentSyncPayloadSchema.safeParse({
      ...validPayload(),
      fileSizeBytes: -1,
    });
    assert.equal(parsed.success, false);
  });

  it('rejects a non-integer fiscal year', () => {
    const parsed = DocumentSyncPayloadSchema.safeParse({
      ...validPayload(),
      fiscalYear: 2026.5,
    });
    assert.equal(parsed.success, false);
  });

  it('normalises an empty documentNumber string to null', () => {
    const parsed = DocumentSyncPayloadSchema.parse({
      ...validPayload(),
      documentNumber: '',
    });
    assert.equal(parsed.documentNumber, null);
  });
});

describe('Phase 0.4: BatchSyncSchema array bound', () => {
  it('accepts exactly 100 documents', () => {
    const docs = Array.from({ length: 100 }, (_, i) => ({
      ...validPayload(),
      clientLocalId: `doc-${i}`,
    }));
    const parsed = BatchSyncSchema.safeParse({ documents: docs });
    assert.equal(parsed.success, true);
  });

  it('rejects a 101-document batch', () => {
    const docs = Array.from({ length: 101 }, (_, i) => ({
      ...validPayload(),
      clientLocalId: `doc-${i}`,
    }));
    const parsed = BatchSyncSchema.safeParse({ documents: docs });
    assert.equal(parsed.success, false);
  });

  it('accepts an empty batch', () => {
    const parsed = BatchSyncSchema.safeParse({ documents: [] });
    assert.equal(parsed.success, true);
  });
});

describe('Phase 0.4: ReconcileSchema', () => {
  it('rejects a mixed case non-hex hash', () => {
    const parsed = ReconcileSchema.safeParse({
      items: [{ clientLocalId: 'doc-A', sha256Hash: 'ZZ'.repeat(32) }],
    });
    assert.equal(parsed.success, false);
  });

  it('caps reconcile at 100 items', () => {
    const items = Array.from({ length: 101 }, (_, i) => ({
      clientLocalId: `doc-${i}`,
      sha256Hash: 'a'.repeat(64),
    }));
    const parsed = ReconcileSchema.safeParse({ items });
    assert.equal(parsed.success, false);
  });
});

describe('Phase 0.4: uuidString primitive', () => {
  it('accepts a canonical UUID', () => {
    const parsed = uuidString.safeParse('3f1c2b6a-4d5e-4f60-8b7c-9d0e1f2a3b4c');
    assert.equal(parsed.success, true);
  });

  it('rejects an SQL-injection-shaped id', () => {
    const parsed = uuidString.safeParse("1' OR '1'='1");
    assert.equal(parsed.success, false);
  });

  it('rejects a UUID missing hyphens', () => {
    const parsed = uuidString.safeParse('3f1c2b6a4d5e4f608b7c9d0e1f2a3b4c');
    assert.equal(parsed.success, false);
  });
});

describe('Phase 0.4: isoCalendarDate primitive', () => {
  it('rejects year 0 (Date.UTC would map it to 1900, so the round-trip fails)', () => {
    const parsed = isoCalendarDate.safeParse('0000-01-01');
    assert.equal(parsed.success, false);
  });

  it('rejects a zero month', () => {
    const parsed = isoCalendarDate.safeParse('2026-00-10');
    assert.equal(parsed.success, false);
  });

  it('rejects a zero day', () => {
    const parsed = isoCalendarDate.safeParse('2026-05-00');
    assert.equal(parsed.success, false);
  });

  it('rejects a wrong-length date', () => {
    const parsed = isoCalendarDate.safeParse('2026-1-1');
    assert.equal(parsed.success, false);
  });
});

describe('Phase 0.4: sha256Hex primitive', () => {
  it('accepts mixed case hex', () => {
    assert.equal(sha256Hex.safeParse('Aa1bB2cCdD' + '0'.repeat(54)).success, true);
  });

  it('rejects shorter than 64', () => {
    assert.equal(sha256Hex.safeParse('a'.repeat(63)).success, false);
  });
});

describe('Phase 0.4: List/Search query schemas', () => {
  it('rejects a non-numeric limit', () => {
    const parsed = ListQuerySchema.safeParse({ limit: 'abc' });
    assert.equal(parsed.success, false);
  });

  it('rejects a signed offset', () => {
    const parsed = ListQuerySchema.safeParse({ offset: '-5' });
    assert.equal(parsed.success, false);
  });

  it('rejects a 5-digit year', () => {
    const parsed = ListQuerySchema.safeParse({ year: '12345' });
    assert.equal(parsed.success, false);
  });

  it('parseBoundedInt clamps limit to the max', () => {
    assert.equal(parseBoundedInt('9999', { min: 1, max: 100, fallback: 50 }), 100);
  });

  it('parseBoundedInt clamps to min', () => {
    assert.equal(parseBoundedInt('0', { min: 1, max: 100, fallback: 50 }), 1);
  });

  it('parseBoundedInt falls back when unparseable', () => {
    assert.equal(parseBoundedInt('undefined', { min: 1, max: 100, fallback: 50 }), 50);
  });

  it('SearchQuerySchema inherits ListQuerySchema and accepts q', () => {
    const parsed = SearchQuerySchema.safeParse({ q: 'laporan', limit: '10' });
    assert.equal(parsed.success, true);
  });

  it('SearchQuerySchema rejects q > 500 chars', () => {
    const parsed = SearchQuerySchema.safeParse({ q: 'x'.repeat(501) });
    assert.equal(parsed.success, false);
  });
});

import { Router, type Request, type Response, type NextFunction } from 'express';
import { z } from 'zod';
import type { BatchSyncUseCase } from '../usecases/batch-sync.usecase.js';
import type { ReconcileUseCase } from '../usecases/reconcile.usecase.js';
import type { SearchDocumentsUseCase } from '../usecases/search-documents.usecase.js';
import type { ApplySyncOperationsUseCase } from '../usecases/apply-sync-operations.usecase.js';
import type { IDocumentRepository } from '../domain/document.repository.js';

/**
 * Request-validation contract (Phase 0.4 of the implementation plan).
 *
 * Every schema below mirrors a constraint from
 * src/database/migrations/001_baseline.sql. Where the SQL column is
 * VARCHAR(N), the schema enforces max(N). Where the SQL column is UUID
 * or DATE, the schema rejects syntactically invalid inputs before they
 * reach PostgreSQL. Do not loosen these bounds without also updating the
 * migration and adding a regression case; the previous lax version let
 * `NaN` reach SQL and accepted "2026-13-45" as a documentDate.
 */

// --- Reusable primitives ---------------------------------------------------

export const sha256Hex = z
  .string()
  .regex(/^[0-9a-fA-F]{64}$/, 'sha256Hash must be a 64-character hex digest');

export const uuidString = z
  .string()
  .regex(
    /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/,
    'id must be a UUID',
  );

/**
 * Accepts YYYY-MM-DD only if it names a real calendar date. Rejects
 * "2026-13-45" or "2026-00-10" — the previous regex-only check accepted
 * both and let PostgreSQL surface the error as a 500.
 */
export const isoCalendarDate = z
  .string()
  .regex(/^\d{4}-\d{2}-\d{2}$/, 'Format tanggal harus YYYY-MM-DD')
  .refine((value) => {
    const [y, m, d] = value.split('-').map(Number);
    if (!y || !m || !d) return false;
    const parsed = new Date(Date.UTC(y, m - 1, d));
    return (
      parsed.getUTCFullYear() === y &&
      parsed.getUTCMonth() === m - 1 &&
      parsed.getUTCDate() === d
    );
  }, 'Tanggal tidak valid pada kalender');

const nonBlankTrimmed = (min: number, max: number) =>
  z
    .string()
    .trim()
    .min(min)
    .max(max)
    .refine((s) => s.length > 0, 'Field tidak boleh kosong');

const categoryCodeSchema = z
  .string()
  .trim()
  .min(1)
  .max(50)
  .regex(/^[A-Za-z0-9_\-]+$/, 'Kode kategori hanya boleh huruf, angka, underscore, dan dash');

// --- Payload schemas -------------------------------------------------------

export const DocumentSyncPayloadSchema = z.object({
  clientLocalId: nonBlankTrimmed(1, 64),
  title: nonBlankTrimmed(1, 255),
  documentNumber: z
    .string()
    .trim()
    .max(100)
    .nullable()
    .optional()
    .transform((v) => (v === '' ? null : v)),
  categoryCode: categoryCodeSchema,
  documentDate: isoCalendarDate,
  fiscalYear: z.number().int().min(1900).max(2100),
  fileName: nonBlankTrimmed(1, 255),
  fileSizeBytes: z.number().int().nonnegative().max(Number.MAX_SAFE_INTEGER),
  mimeType: nonBlankTrimmed(1, 100),
  sha256Hash: sha256Hex,
  gdriveFileId: z
    .string()
    .trim()
    .max(255)
    .nullable()
    .optional()
    .transform((v) => (v === '' ? null : v)),
  extractedText: z.string().max(5_000_000).nullable().optional(),
  notes: z.string().max(20_000).nullable().optional(),
  originalFileName: z
    .string()
    .trim()
    .max(255)
    .nullable()
    .optional()
    .transform((v) => (v === '' ? null : v)),
  tags: z
    .array(z.string().trim().min(1).max(60))
    .max(50)
    .optional(),
  customMetadata: z.record(z.unknown()).optional(),
});

export const BatchSyncSchema = z.object({
  documents: z.array(DocumentSyncPayloadSchema).min(0).max(100),
});

// Phase 2.6 v2 request. Every operation carries its own idempotency key
// (operationId) and the baseRevision it intends to replace.
export const SyncOperationSchema = z.object({
  operationId: nonBlankTrimmed(1, 64),
  clientLocalId: nonBlankTrimmed(1, 64),
  baseRevision: z.number().int().nonnegative().max(Number.MAX_SAFE_INTEGER),
  kind: z.literal('upsert'),
  payload: DocumentSyncPayloadSchema,
});

export const SyncBatchSchema = z.object({
  operations: z.array(SyncOperationSchema).min(0).max(100),
});

export const ReconcileSchema = z.object({
  items: z
    .array(
      z.object({
        clientLocalId: nonBlankTrimmed(1, 64),
        sha256Hash: sha256Hex,
      }),
    )
    .min(0)
    .max(100),
});

export const ListQuerySchema = z.object({
  category: z.string().trim().max(50).optional(),
  year: z
    .string()
    .regex(/^\d{4}$/, 'year must be a 4-digit Gregorian year')
    .optional(),
  limit: z
    .string()
    .regex(/^\d+$/, 'limit must be a non-negative integer')
    .optional(),
  offset: z
    .string()
    .regex(/^\d+$/, 'offset must be a non-negative integer')
    .optional(),
});

export const SearchQuerySchema = ListQuerySchema.extend({
  q: z.string().max(500).optional(),
});

// --- Bounds helpers --------------------------------------------------------

const LIMIT_DEFAULT = 50;
const LIMIT_MAX = 100;

export function parseBoundedInt(
  raw: string | undefined,
  { min, max, fallback }: { min: number; max: number; fallback: number },
): number {
  if (raw === undefined || raw === '') return fallback;
  const parsed = Number.parseInt(raw, 10);
  if (!Number.isFinite(parsed)) return fallback;
  if (parsed < min) return min;
  if (parsed > max) return max;
  return parsed;
}

// --- Router factory --------------------------------------------------------

export function createDocumentRouter(deps: {
  batchSyncUseCase: BatchSyncUseCase;
  reconcileUseCase: ReconcileUseCase;
  searchUseCase: SearchDocumentsUseCase;
  repository: IDocumentRepository;
}): Router {
  const router = Router();

  // Phase 3.3: the authorized workspace is taken from the verified token
  // (attached by requireAuth), never from the request body or a
  // client-supplied id. A route reached without it is a wiring bug or an
  // unauthenticated call; either way it must not touch another tenant's
  // data, so we fail closed with 401.
  const resolveWorkspace = (req: Request, res: Response): string | null => {
    const workspaceId = req.auth?.workspaceId;
    if (!workspaceId) {
      res.status(401).json({
        status: 'error',
        message: 'Authentication required',
        requestId: req.requestId,
      });
      return null;
    }
    return workspaceId;
  };

  // POST /api/v1/sync/batch-metadata
  router.post(
    '/sync/batch-metadata',
    async (req: Request, res: Response, next: NextFunction): Promise<void> => {
      try {
        const workspaceId = resolveWorkspace(req, res);
        if (!workspaceId) return;
        const body = Array.isArray(req.body)
          ? { documents: req.body }
          : req.body;
        const parsed = BatchSyncSchema.parse(body);
        const result = await deps.batchSyncUseCase.execute(workspaceId, parsed.documents);
        res.status(200).json({
          status: 'success',
          data: result,
        });
      } catch (err) {
        next(err);
      }
    },
  );

  // POST /sync/batch lives on the v2 router (document.controller.v2.ts)
  // mounted at /api/v2. It is intentionally absent from this v1 file so
  // v1 and v2 semantics cannot overlap under the same URL prefix.

  // POST /api/v1/sync/reconcile
  router.post(
    '/sync/reconcile',
    async (req: Request, res: Response, next: NextFunction): Promise<void> => {
      try {
        const workspaceId = resolveWorkspace(req, res);
        if (!workspaceId) return;
        const parsed = ReconcileSchema.parse(req.body);
        const result = await deps.reconcileUseCase.execute(workspaceId, parsed);
        res.status(200).json({
          status: 'success',
          data: result,
        });
      } catch (err) {
        next(err);
      }
    },
  );

  // GET /api/v1/documents/search
  router.get(
    '/documents/search',
    async (req: Request, res: Response, next: NextFunction): Promise<void> => {
      try {
        const workspaceId = resolveWorkspace(req, res);
        if (!workspaceId) return;
        const parsed = SearchQuerySchema.parse(req.query);
        const query = parsed.q ?? '';
        const limit = parseBoundedInt(parsed.limit, {
          min: 1,
          max: LIMIT_MAX,
          fallback: LIMIT_DEFAULT,
        });
        const offset = parseBoundedInt(parsed.offset, {
          min: 0,
          max: Number.MAX_SAFE_INTEGER,
          fallback: 0,
        });
        const results = await deps.searchUseCase.execute(workspaceId, query, limit, offset);
        res.status(200).json({
          status: 'success',
          data: results,
        });
      } catch (err) {
        next(err);
      }
    },
  );

  // GET /api/v1/documents/categories
  router.get(
    '/documents/categories',
    async (_req: Request, res: Response, next: NextFunction): Promise<void> => {
      try {
        const categories = await deps.repository.getCategories();
        res.status(200).json({
          status: 'success',
          data: categories,
        });
      } catch (err) {
        next(err);
      }
    },
  );

  // GET /api/v1/documents
  router.get(
    '/documents',
    async (req: Request, res: Response, next: NextFunction): Promise<void> => {
      try {
        const workspaceId = resolveWorkspace(req, res);
        if (!workspaceId) return;
        const parsed = ListQuerySchema.parse(req.query);
        const limit = parseBoundedInt(parsed.limit, {
          min: 1,
          max: LIMIT_MAX,
          fallback: LIMIT_DEFAULT,
        });
        const offset = parseBoundedInt(parsed.offset, {
          min: 0,
          max: Number.MAX_SAFE_INTEGER,
          fallback: 0,
        });
        const fiscalYear = parsed.year ? Number.parseInt(parsed.year, 10) : undefined;

        const result = await deps.repository.list(workspaceId, {
          categoryCode: parsed.category,
          fiscalYear,
          limit,
          offset,
        });

        res.status(200).json({
          status: 'success',
          data: result.items,
          pagination: {
            total: result.total,
            limit,
            offset,
          },
        });
      } catch (err) {
        next(err);
      }
    },
  );

  // GET /api/v1/documents/:id
  router.get(
    '/documents/:id',
    async (req: Request, res: Response, next: NextFunction): Promise<void> => {
      try {
        const workspaceId = resolveWorkspace(req, res);
        if (!workspaceId) return;
        const rawId = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;
        const id = uuidString.parse(rawId);
        const doc = await deps.repository.getById(workspaceId, id);
        if (!doc) {
          res.status(404).json({
            status: 'error',
            message: 'Dokumen tidak ditemukan',
          });
          return;
        }
        res.status(200).json({
          status: 'success',
          data: doc,
        });
      } catch (err) {
        next(err);
      }
    },
  );

  return router;
}

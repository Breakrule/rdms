import { randomUUID } from 'node:crypto';
import express, { type Express, type Request, type Response, type NextFunction } from 'express';
import helmet from 'helmet';
import cors from 'cors';
import { ZodError } from 'zod';
import { config } from './config.js';
import { pool, getMigrationStatus } from './database/db.js';
import { PostgresDocumentRepository } from './modules/documents/infra/postgres-document.repository.js';
import { BatchSyncUseCase } from './modules/documents/usecases/batch-sync.usecase.js';
import { ReconcileUseCase } from './modules/documents/usecases/reconcile.usecase.js';
import { SearchDocumentsUseCase } from './modules/documents/usecases/search-documents.usecase.js';
import { ApplySyncOperationsUseCase } from './modules/documents/usecases/apply-sync-operations.usecase.js';
import { createDocumentRouter } from './modules/documents/delivery/document.controller.js';
import { createDocumentV2Router } from './modules/documents/delivery/document.controller.v2.js';
import { requireAuth, type AuthContext } from './modules/auth/auth.middleware.js';
import { KeycloakTokenVerifier } from './modules/auth/keycloak-token-verifier.js';
import { DbWorkspaceProvisioner } from './modules/auth/workspace-provisioner.js';
import type { TokenVerifier } from './modules/auth/token-verifier.js';
import type { WorkspaceProvisioner } from './modules/auth/workspace-provisioner.js';
import type { IDocumentRepository } from './modules/documents/domain/document.repository.js';

declare global {
  // Augment Express Request with the per-request correlation ID. Declared
  // here (rather than a separate .d.ts) because this is currently the only
  // consumer.
  // eslint-disable-next-line @typescript-eslint/no-namespace
  namespace Express {
    interface Request {
      requestId: string;
      auth?: AuthContext;
    }
  }
}

/**
 * Assign a correlation ID to every request. Honour an inbound
 * X-Request-Id only when it looks like an opaque token (short, ASCII, no
 * control characters). Do not let a client inject arbitrary text into
 * logs.
 */
function requestIdMiddleware(req: Request, res: Response, next: NextFunction): void {
  const inbound = req.header('x-request-id');
  const safe = inbound && /^[A-Za-z0-9_\-]{1,64}$/.test(inbound);
  req.requestId = safe ? inbound! : randomUUID();
  res.setHeader('x-request-id', req.requestId);
  next();
}

function buildCorsOptions(): cors.CorsOptions {
  // Explicit allow-list when provided via CORS_ORIGINS. Otherwise fall
  // back to a narrow default: no wildcard in production; loopback origins
  // allowed in development so the Flutter web/desktop client can reach
  // the local API without configuration.
  if (config.corsOrigins && config.corsOrigins.length > 0) {
    return {
      origin: [...config.corsOrigins],
      methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
      allowedHeaders: ['Content-Type', 'Authorization', 'X-Request-Id'],
    };
  }
  if (config.isProduction) {
    return {
      origin: false,
      methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
      allowedHeaders: ['Content-Type', 'Authorization', 'X-Request-Id'],
    };
  }
  const devLoopback = /^https?:\/\/(127\.0\.0\.1|localhost)(:\d+)?$/;
  return {
    origin(origin, callback) {
      // Requests without an Origin header (curl, mobile clients, same-origin)
      // are allowed.
      if (!origin || devLoopback.test(origin)) {
        callback(null, true);
        return;
      }
      callback(new Error(`Origin ${origin} not allowed by CORS in development mode.`));
    },
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Request-Id'],
  };
}

/// Optional seams for tests: inject a stub verifier / provisioner /
/// repository so authorization can be exercised without a live Keycloak
/// or PostgreSQL instance. Production (`main.ts`) calls `createApp()` with
/// no overrides and gets the real implementations built from config.
export interface AppOverrides {
  tokenVerifier?: TokenVerifier;
  workspaceProvisioner?: WorkspaceProvisioner;
  repository?: IDocumentRepository;
  requireAuthentication?: boolean;
  localWorkspaceId?: string;
}

export function createApp(overrides: AppOverrides = {}): Express {
  const app = express();

  app.use(helmet());
  app.use(requestIdMiddleware);
  app.use(cors(buildCorsOptions()));
  app.use(express.json({ limit: '10mb' }));

  // Repository & Use Cases
  const repository = overrides.repository ?? new PostgresDocumentRepository(pool);
  const batchSyncUseCase = new BatchSyncUseCase(repository);
  const reconcileUseCase = new ReconcileUseCase(repository);
  const searchUseCase = new SearchDocumentsUseCase(repository);
  const applySyncOperationsUseCase = new ApplySyncOperationsUseCase(repository);

  // Phase 3.1/3.3: verify the bearer token against the OIDC issuer and
  // resolve the caller's personal workspace before any document route runs.
  const tokenVerifier =
    overrides.tokenVerifier ??
    new KeycloakTokenVerifier({
      issuer: config.oidc.issuer,
      audience: config.oidc.audience,
      jwksUri: config.oidc.jwksUri,
    });
  const workspaceProvisioner =
    overrides.workspaceProvisioner ?? new DbWorkspaceProvisioner(pool);
  const auth = requireAuth({
    verifier: tokenVerifier,
    workspaceProvisioner,
    enforce: overrides.requireAuthentication ?? config.auth.requireAuthentication,
    localSubject: config.auth.localSubject,
    localWorkspaceId: overrides.localWorkspaceId ?? config.auth.localWorkspaceId,
  });

  // Health check. Distinguishes three states so an operator or a CI probe
  // can tell "still starting" from "actually broken".
  app.get('/api/v1/health', async (_req: Request, res: Response) => {
    const migration = getMigrationStatus();
    if (!migration.ready) {
      res.status(503).json({
        status: 'unavailable',
        service: 'dms-metadata-backend',
        db: 'not-ready',
        reason: migration.error ?? 'Migrations have not completed.',
      });
      return;
    }
    try {
      await pool.query('SELECT 1');
      res.status(200).json({ status: 'ok', service: 'dms-metadata-backend', db: 'connected' });
    } catch (err) {
      // Report generic "db-error"; details (host, user, code) stay in logs.
      console.error(`[health] db probe failed requestId=${_req.requestId}:`, err);
      res.status(500).json({
        status: 'error',
        service: 'dms-metadata-backend',
        db: 'probe-failed',
        requestId: _req.requestId,
      });
    }
  });

  // Mount API Router. The `/api/v1/health` probe above is intentionally
  // registered before this so readiness stays unauthenticated; every
  // document route passes through requireAuth.
  app.use(
    '/api/v1',
    auth,
    createDocumentRouter({
      batchSyncUseCase,
      reconcileUseCase,
      searchUseCase,
      repository,
    }),
  );

  // v2 surface (Phase 2.6). Kept on a separate mount so v1 clients
  // never accidentally reach a v2 endpoint and vice versa. Authenticated
  // identically (Phase 3.3): no API version can bypass authorization.
  app.use(
    '/api/v2',
    auth,
    createDocumentV2Router({ applySyncOperationsUseCase }),
  );

  // Not-found handler for anything falling through the mounted routers.
  app.use((req: Request, res: Response) => {
    res.status(404).json({
      status: 'error',
      message: 'Route not found',
      requestId: req.requestId,
    });
  });

  // Error Handling Middleware.
  // - Validation errors are described (they belong to the client).
  // - Everything else is logged with the request ID and returned as a
  //   generic 500 so we never leak stack traces, connection strings, or
  //   SQL fragments to callers.
  app.use((err: unknown, req: Request, res: Response, _next: NextFunction) => {
    if (err instanceof ZodError) {
      res.status(400).json({
        status: 'fail',
        message: 'Validasi payload gagal',
        errors: err.errors.map((e) => ({
          path: e.path.join('.'),
          message: e.message,
        })),
        requestId: req.requestId,
      });
      return;
    }

    console.error(`[error] requestId=${req.requestId}:`, err);
    res.status(500).json({
      status: 'error',
      message: 'Internal Server Error',
      requestId: req.requestId,
    });
  });

  return app;
}

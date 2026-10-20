import { Router, type Request, type Response, type NextFunction } from 'express';
import type { ApplySyncOperationsUseCase } from '../usecases/apply-sync-operations.usecase.js';
import { SyncBatchSchema } from './document.controller.js';

/**
 * v2 delivery surface (Phase 2.6).
 *
 * Mounted at `/api/v2`. The v1 router stays in place for existing
 * clients; Phase 3 adds workspace scoping and the v1 surface retires
 * once the last pre-migration client is upgraded.
 *
 * Kept separate from `document.controller.ts` so v2-only endpoints do
 * not become accidentally reachable under the `/api/v1` prefix.
 */
export function createDocumentV2Router(deps: {
  applySyncOperationsUseCase: ApplySyncOperationsUseCase;
}): Router {
  const router = Router();

  // POST /api/v2/sync/batch
  router.post(
    '/sync/batch',
    async (req: Request, res: Response, next: NextFunction): Promise<void> => {
      try {
        // Phase 3.3: workspace from the verified token, never the body.
        // The same rule as v1 applies to v2 so no API version can be used
        // to reach another workspace's records (acceptance gate).
        const workspaceId = req.auth?.workspaceId;
        if (!workspaceId) {
          res.status(401).json({
            status: 'error',
            message: 'Authentication required',
            requestId: req.requestId,
          });
          return;
        }
        const parsed = SyncBatchSchema.parse(req.body);
        const result = await deps.applySyncOperationsUseCase.execute(workspaceId, parsed.operations);
        res.status(200).json({ status: 'success', data: result });
      } catch (err) {
        next(err);
      }
    },
  );

  return router;
}

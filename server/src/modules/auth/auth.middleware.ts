import type { NextFunction, Request, Response } from 'express';
import type { TokenVerifier } from './token-verifier.js';
import type { WorkspaceProvisioner } from './workspace-provisioner.js';

/// Identity + authorized workspace attached to every authenticated
/// request. Repositories MUST use `workspaceId` to scope reads and writes;
/// it is never taken from the request body or a client-supplied id.
export interface AuthContext {
  subject: string;
  email?: string;
  workspaceId: string;
}

/// Verifies the bearer access token and resolves the caller's personal
/// workspace, attaching both to `req.auth`.
///
/// Phase 3 revised for an offline-first, no-login product:
/// - `enforce === false` (default): a request with NO bearer token is
///   assigned the shared local workspace and proceeds. A request that DOES
///   carry a token is still fully verified and scoped to its own workspace,
///   so multi-tenant isolation applies whenever a real identity is present.
/// - `enforce === true`: an absent token becomes 401.
///
/// A present-but-invalid token is ALWAYS rejected (even in optional mode),
/// so we never silently downgrade an attempted authentication. The precise
/// reason stays out of the response body (it belongs in redacted logs).
export function requireAuth(deps: {
  verifier: TokenVerifier;
  workspaceProvisioner: WorkspaceProvisioner;
  enforce: boolean;
  localSubject: string;
  localWorkspaceId: string;
}) {
  const localAuth: AuthContext = {
    subject: deps.localSubject,
    workspaceId: deps.localWorkspaceId,
  };

  return async function middleware(
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> {
    const header = req.header('authorization');
    const token = header ? /^Bearer\s+(.+)$/i.exec(header)?.[1] : undefined;

    if (!token) {
      if (deps.enforce) {
        res.status(401).json({
          status: 'error',
          message: 'Authentication required',
          requestId: req.requestId,
        });
        return;
      }
      // No-login local mode: a single shared workspace.
      req.auth = localAuth;
      next();
      return;
    }

    try {
      const principal = await deps.verifier.verify(token);
      const workspaceId = await deps.workspaceProvisioner.ensurePersonalWorkspace(principal);
      req.auth = { subject: principal.subject, email: principal.email, workspaceId };
      next();
    } catch {
      res.status(401).json({
        status: 'error',
        message: 'Invalid or expired token',
        requestId: req.requestId,
      });
    }
  };
}

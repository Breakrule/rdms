import { randomUUID } from 'node:crypto';
import type { Pool } from 'pg';
import type { Principal } from './token-verifier.js';

/// Resolves (and on first sight, creates) the personal workspace for an
/// authenticated principal (Phase 3.2).
///
/// Deliberate boundary: provisioning a workspace does NOT claim any legacy
/// unowned document. Rows whose `documents.workspace_id` is NULL stay
/// invisible to every authenticated workspace until an administrator maps
/// them explicitly (Phase 3.4), so "the first person to sign in owns the
/// whole table" is impossible by construction.
///
/// An interface so delivery tests can inject a deterministic provisioner
/// without a live database.
export interface WorkspaceProvisioner {
  ensurePersonalWorkspace(principal: Principal): Promise<string>;
}

export class DbWorkspaceProvisioner implements WorkspaceProvisioner {
  constructor(private readonly pool: Pool) {}

  async ensurePersonalWorkspace(principal: Principal): Promise<string> {
    const client = await this.pool.connect();
    try {
      await client.query('BEGIN');

      const userRes = await client.query<{ id: string }>(
        `INSERT INTO users (subject, email)
         VALUES ($1, $2)
         ON CONFLICT (subject)
         DO UPDATE SET email = COALESCE(EXCLUDED.email, users.email)
         RETURNING id`,
        [principal.subject, principal.email ?? null],
      );
      const userId = userRes.rows[0].id;

      const existing = await client.query<{ id: string }>(
        `SELECT w.id
         FROM workspaces w
         JOIN memberships m ON m.workspace_id = w.id
         WHERE m.user_id = $1 AND w.kind = 'personal'
         LIMIT 1`,
        [userId],
      );
      if (existing.rowCount && existing.rows.length > 0) {
        await client.query('COMMIT');
        return existing.rows[0].id;
      }

      const workspaceId = randomUUID();
      await client.query(
        `INSERT INTO workspaces (id, owner_user_id, kind) VALUES ($1, $2, 'personal')`,
        [workspaceId, userId],
      );
      await client.query(
        `INSERT INTO memberships (workspace_id, user_id, role) VALUES ($1, $2, 'owner')`,
        [workspaceId, userId],
      );

      await client.query('COMMIT');
      return workspaceId;
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  }
}

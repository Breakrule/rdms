import pg from 'pg';
import { config } from '../config.js';

const { Pool } = pg;

export const pool = new Pool({
  host: config.db.host,
  port: config.db.port,
  user: config.db.user,
  password: config.db.password,
  database: config.db.database,
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 5000,
});

pool.on('error', (err) => {
  // Idle-client errors must not crash the process, but they must be visible.
  // A repeated stream of these signals the DB is unreachable and readiness
  // should be re-checked.
  console.error('[db] idle client error:', err);
});

/**
 * Module-level readiness flag. Set true after runMigrations succeeds and
 * a probe query confirms the ledger is queryable. Health endpoint uses
 * this to distinguish "not yet migrated" from "migrated but transient
 * DB error".
 */
let migrationReady = false;
let migrationError: string | null = null;

export function markMigrationReady(): void {
  migrationReady = true;
  migrationError = null;
}

export function markMigrationFailed(reason: string): void {
  migrationReady = false;
  migrationError = reason;
}

export function getMigrationStatus(): { ready: boolean; error: string | null } {
  return { ready: migrationReady, error: migrationError };
}

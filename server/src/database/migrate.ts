import { createHash } from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';
import type { Pool, PoolClient } from 'pg';

/**
 * Ordered, ledgered SQL migrations.
 *
 * Contract:
 * - Files live in ./migrations and are named `<NNN>_<slug>.sql` (e.g.
 *   `001_baseline.sql`). Numeric prefix drives ordering.
 * - Every applied file is recorded in `schema_migrations` with a SHA-256
 *   checksum. Re-running `runMigrations` on an up-to-date database is a
 *   no-op. Changing a previously applied file is a hard error, not a
 *   silent re-apply, so drift between environments is loud.
 * - Each file is executed inside a single transaction. Partial failures
 *   roll back.
 * - Concurrency is guarded by a PostgreSQL advisory lock. Multiple API
 *   replicas booting simultaneously will serialise.
 *
 * Failure policy:
 * Any migration error (missing directory, empty file, checksum drift, or
 * SQL error) throws. Callers MUST treat that as fatal and refuse to
 * serve traffic. Silently continuing has already been rejected in the
 * implementation plan (Phase 0.3).
 */

const LOCK_KEY = 72_015_121; // arbitrary stable namespace for this project

const MIGRATIONS_DIR = path.join(__dirname, 'migrations');

export interface AppliedMigration {
  name: string;
  checksum: string;
}

export interface MigrationResult {
  applied: AppliedMigration[];
  skipped: AppliedMigration[];
}

class MigrationError extends Error {
  override name = 'MigrationError';
}

function assertMigrationName(name: string): void {
  if (!/^\d{3,}_[A-Za-z0-9_\-]+\.sql$/.test(name)) {
    throw new MigrationError(
      `Ignoring file ${name}: expected a name like "001_baseline.sql" (digits, underscore, slug, .sql).`,
    );
  }
}

function loadFiles(): Array<{ name: string; sql: string; checksum: string }> {
  if (!fs.existsSync(MIGRATIONS_DIR)) {
    throw new MigrationError(
      `Migrations directory not found at ${MIGRATIONS_DIR}. The Docker image must copy src/database/migrations to dist/database/migrations.`,
    );
  }
  const entries = fs.readdirSync(MIGRATIONS_DIR).filter((n) => n.endsWith('.sql')).sort();
  if (entries.length === 0) {
    throw new MigrationError(
      `Migrations directory ${MIGRATIONS_DIR} has no .sql files. At least 001_baseline.sql must exist.`,
    );
  }
  return entries.map((name) => {
    assertMigrationName(name);
    const sql = fs.readFileSync(path.join(MIGRATIONS_DIR, name), 'utf8');
    if (sql.trim().length === 0) {
      throw new MigrationError(`Migration ${name} is empty.`);
    }
    const checksum = createHash('sha256').update(sql, 'utf8').digest('hex');
    return { name, sql, checksum };
  });
}

async function ensureLedger(client: PoolClient): Promise<void> {
  await client.query(`
    CREATE TABLE IF NOT EXISTS schema_migrations (
      id         SERIAL PRIMARY KEY,
      name       TEXT        NOT NULL UNIQUE,
      checksum   TEXT        NOT NULL,
      applied_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
    );
  `);
}

async function readApplied(client: PoolClient): Promise<Map<string, string>> {
  const res = await client.query<{ name: string; checksum: string }>(
    'SELECT name, checksum FROM schema_migrations ORDER BY name ASC',
  );
  return new Map(res.rows.map((r) => [r.name, r.checksum]));
}

async function applyOne(client: PoolClient, file: { name: string; sql: string; checksum: string }): Promise<void> {
  await client.query('BEGIN');
  try {
    await client.query(file.sql);
    await client.query(
      'INSERT INTO schema_migrations (name, checksum) VALUES ($1, $2)',
      [file.name, file.checksum],
    );
    await client.query('COMMIT');
  } catch (err) {
    await client.query('ROLLBACK');
    throw new MigrationError(
      `Migration ${file.name} failed: ${err instanceof Error ? err.message : String(err)}`,
      { cause: err },
    );
  }
}

export async function runMigrations(pool: Pool): Promise<MigrationResult> {
  const files = loadFiles();

  const client = await pool.connect();
  try {
    // Serialise concurrent boots across replicas. Lock releases when the
    // session ends; nothing else in the ledger requires the same key.
    await client.query('SELECT pg_advisory_lock($1)', [LOCK_KEY]);
    try {
      await ensureLedger(client);
      const applied = await readApplied(client);

      const result: MigrationResult = { applied: [], skipped: [] };

      for (const file of files) {
        const prior = applied.get(file.name);
        if (prior !== undefined) {
          if (prior !== file.checksum) {
            throw new MigrationError(
              `Checksum drift on ${file.name}. Applied ${prior}, found ${file.checksum}. ` +
                'Already-applied migrations are immutable; add a new numbered file instead.',
            );
          }
          result.skipped.push({ name: file.name, checksum: file.checksum });
          continue;
        }
        await applyOne(client, file);
        result.applied.push({ name: file.name, checksum: file.checksum });
      }

      return result;
    } finally {
      await client.query('SELECT pg_advisory_unlock($1)', [LOCK_KEY]);
    }
  } finally {
    client.release();
  }
}

export { MigrationError };

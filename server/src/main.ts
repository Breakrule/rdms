import { createApp } from './app.js';
import { config, describeConfig, ConfigError } from './config.js';
import { pool, markMigrationReady, markMigrationFailed } from './database/db.js';
import { runMigrations, MigrationError } from './database/migrate.js';

async function bootstrap(): Promise<void> {
  console.info(describeConfig());

  try {
    const result = await runMigrations(pool);
    if (result.applied.length > 0) {
      console.info(
        `[migrate] applied ${result.applied.length}: ${result.applied.map((m) => m.name).join(', ')}`,
      );
    }
    if (result.skipped.length > 0) {
      console.info(
        `[migrate] already-current ${result.skipped.length}: ${result.skipped.map((m) => m.name).join(', ')}`,
      );
    }
    markMigrationReady();
  } catch (err) {
    const reason = err instanceof MigrationError
      ? err.message
      : `Unexpected migration failure: ${err instanceof Error ? err.message : String(err)}`;
    markMigrationFailed(reason);
    console.error('[migrate] FATAL:', reason);
    console.error(
      '[migrate] refusing to serve. Fix the schema and restart. See implementation_plan_feat.md Phase 0.3.',
    );
    // Best-effort pool close so the process exits with a clean shutdown.
    try {
      await pool.end();
    } catch {
      // Ignore — we're about to exit anyway.
    }
    process.exit(1);
  }

  const app = createApp();

  const server = app.listen(config.port, config.host, () => {
    console.log(`🚀 DMS Backend Server running at http://${config.host}:${config.port}`);
  });

  server.on('error', (err) => {
    console.error('[http] server error:', err);
    process.exit(1);
  });
}

// Surface configuration errors (missing production variables, default
// passphrase reuse, malformed integers) with a clear message instead of
// a stack-trace flood.
process.on('uncaughtException', (err) => {
  if (err instanceof ConfigError) {
    console.error('[config] FATAL:', err.message);
    process.exit(1);
  }
  console.error('[fatal] uncaught exception:', err);
  process.exit(1);
});

bootstrap().catch((err) => {
  if (err instanceof ConfigError) {
    console.error('[config] FATAL:', err.message);
  } else {
    console.error('[fatal] bootstrap error:', err);
  }
  process.exit(1);
});

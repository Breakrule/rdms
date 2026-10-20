import 'dotenv/config';

/**
 * Runtime configuration for the DMS metadata API.
 *
 * Loading rules:
 * - Development (NODE_ENV=development, NODE_ENV unset, or NODE_ENV=test):
 *   defaults are permitted so a fresh local checkout can run without a .env.
 *   Defaults are loudly logged once at startup so nobody mistakes them for
 *   a production-ready configuration.
 * - Production (NODE_ENV=production): defaults are refused. Required values
 *   must be injected through environment variables. The known development
 *   passphrase ("dms_secret_2026") is explicitly rejected because it ships
 *   inside compose.yaml and .env.example.
 *
 * Adding a new variable? Extend `requiredInProduction` and update
 * .env.example plus the deployment runbook in the same change.
 */

const KNOWN_DEV_PASSWORD = 'dms_secret_2026';

const NODE_ENV = (process.env.NODE_ENV ?? 'development').toLowerCase();
const isProduction = NODE_ENV === 'production';
const isDevelopment = !isProduction;

class ConfigError extends Error {
  override name = 'ConfigError';
}

function requireEnv(name: string): string {
  const value = process.env[name];
  if (value === undefined || value.trim() === '') {
    throw new ConfigError(
      `${name} is required when NODE_ENV=${NODE_ENV}. Inject it via the environment or a secret store; do not rely on defaults in production.`,
    );
  }
  return value;
}

function parseInteger(name: string, raw: string | undefined, fallback: number | null): number {
  if (raw === undefined || raw.trim() === '') {
    if (fallback === null) {
      throw new ConfigError(`${name} is required.`);
    }
    return fallback;
  }
  const parsed = Number.parseInt(raw, 10);
  if (!Number.isFinite(parsed)) {
    throw new ConfigError(`${name} must be an integer; received ${JSON.stringify(raw)}.`);
  }
  return parsed;
}

const port = parseInteger('PORT', process.env.PORT, 4000);
const dbPort = parseInteger('DB_PORT', process.env.DB_PORT, 5432);

const dbUser = isProduction
  ? requireEnv('DB_USER')
  : (process.env.DB_USER ?? 'dms_user');

const dbName = isProduction
  ? requireEnv('DB_NAME')
  : (process.env.DB_NAME ?? 'dms_metadata');

const dbHost = isProduction
  ? requireEnv('DB_HOST')
  : (process.env.DB_HOST ?? '127.0.0.1');

const rawDbPassword = isProduction ? requireEnv('DB_PASSWORD') : (process.env.DB_PASSWORD ?? KNOWN_DEV_PASSWORD);
if (isProduction && rawDbPassword === KNOWN_DEV_PASSWORD) {
  throw new ConfigError(
    'DB_PASSWORD matches the built-in development passphrase. Refusing to start in production. Rotate the secret and inject a distinct value.',
  );
}

const host = isProduction
  ? (process.env.HOST ?? '0.0.0.0')
  : (process.env.HOST ?? '127.0.0.1');

// Phase 3.1 OIDC. Production must inject a real issuer + audience; the
// development default points at the Keycloak realm provisioned in
// compose.yaml. The JWKS URI is derived from the issuer using the
// standard OIDC discovery path so operators set exactly one value.
const oidcIssuer = isProduction
  ? requireEnv('OIDC_ISSUER')
  : (process.env.OIDC_ISSUER ?? 'http://localhost:8080/realms/rdms');

const oidcAudience = isProduction
  ? requireEnv('OIDC_AUDIENCE')
  : (process.env.OIDC_AUDIENCE ?? 'rdms-api');

const oidcJwksUri = `${oidcIssuer.replace(/\/$/, '')}/protocol/openid-connect/certs`;

// Phase 3 revised: the app is offline-first and usable with NO login. By
// default the API does not require a bearer token; anonymous callers are
// assigned a single local workspace. Multi-workspace isolation still
// works for any request that DOES present a valid token, and an operator
// can hard-require authentication (REQUIRE_AUTH=true) before exposing the
// API publicly — which is exactly what the plan's Phase 3 gate is for.
//
// The default local workspace id is a fixed UUID seeded by migration 004
// so no-login writes satisfy the documents.workspace_id foreign key.
const LOCAL_WORKSPACE_ID = '00000000-0000-4000-8000-000000000001';
const LOCAL_SUBJECT = 'local-device';

const requireEnvBool = (name: string, fallback: boolean): boolean => {
  const raw = process.env[name];
  if (raw === undefined || raw.trim() === '') return fallback;
  const v = raw.trim().toLowerCase();
  if (v === 'true' || v === '1') return true;
  if (v === 'false' || v === '0') return false;
  throw new ConfigError(`${name} must be a boolean (true/false); received ${JSON.stringify(raw)}.`);
};

// Production defaults to requiring auth; development/local defaults to the
// no-login single-workspace mode. Either can be overridden explicitly.
const requireAuthentication = requireEnvBool(
  'REQUIRE_AUTH',
  isProduction,
);

if (isProduction && host === '127.0.0.1') {
  // Not fatal: a production deployment may still bind loopback behind a
  // reverse proxy. Recorded here so operators see the intent in logs.
}

export interface ServerConfig {
  readonly nodeEnv: string;
  readonly isProduction: boolean;
  readonly isDevelopment: boolean;
  readonly port: number;
  readonly host: string;
  readonly db: {
    readonly host: string;
    readonly port: number;
    readonly user: string;
    readonly password: string;
    readonly database: string;
  };
  /**
   * Optional allow-list of CORS origins. When unset, only loopback origins
   * are accepted. Wildcards are never used in production.
   */
  readonly corsOrigins: readonly string[] | null;
  /**
   * Phase 3.1 OIDC token-validation parameters. The API accepts ONLY
   * access tokens whose audience is `oidc.audience`, signed by this
   * issuer's keys — never OIDC ID tokens and never Drive access tokens.
   */
  readonly oidc: {
    readonly issuer: string;
    readonly audience: string;
    readonly jwksUri: string;
  };
  /**
   * Phase 3 authentication posture. The app is usable with no login by
   * default (`requireAuthentication === false`); anonymous traffic is
   * scoped to `localWorkspaceId`. Set REQUIRE_AUTH=true (default in
   * production) to make the bearer token mandatory again.
   */
  readonly auth: {
    readonly requireAuthentication: boolean;
    readonly localWorkspaceId: string;
    readonly localSubject: string;
  };
}

function resolveCorsOrigins(): readonly string[] | null {
  const raw = process.env.CORS_ORIGINS;
  if (!raw || raw.trim() === '') return null;
  const list = raw.split(',').map((s) => s.trim()).filter((s) => s.length > 0);
  return list.length > 0 ? list : null;
}

export const config: ServerConfig = {
  nodeEnv: NODE_ENV,
  isProduction,
  isDevelopment,
  port,
  host,
  db: {
    host: dbHost,
    port: dbPort,
    user: dbUser,
    password: rawDbPassword,
    database: dbName,
  },
  corsOrigins: resolveCorsOrigins(),
  oidc: {
    issuer: oidcIssuer,
    audience: oidcAudience,
    jwksUri: oidcJwksUri,
  },
  auth: {
    requireAuthentication,
    localWorkspaceId: LOCAL_WORKSPACE_ID,
    localSubject: LOCAL_SUBJECT,
  },
};

/**
 * Emit a startup banner describing which defaults are in effect. Called
 * from main.ts so the log ordering is predictable.
 */
export function describeConfig(): string {
  const lines: string[] = [];
  lines.push(`[config] NODE_ENV=${NODE_ENV}`);
  lines.push(`[config] HTTP bind=${config.host}:${config.port}`);
  lines.push(`[config] Postgres target=${config.db.host}:${config.db.port}/${config.db.database} user=${config.db.user}`);
  lines.push(`[config] OIDC issuer=${config.oidc.issuer} audience=${config.oidc.audience}`);
  lines.push(
    config.auth.requireAuthentication
      ? '[config] auth=REQUIRED (bearer token mandatory)'
      : `[config] auth=OPTIONAL (no login; anonymous -> workspace ${config.auth.localWorkspaceId})`,
  );
  if (config.isDevelopment) {
    lines.push('[config] WARNING: development defaults are in effect. Do not use this mode for a public deployment.');
  }
  return lines.join('\n');
}

export { ConfigError };

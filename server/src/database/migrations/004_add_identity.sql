-- 004_add_identity.sql
-- Phase 3.2 / 3.3: authenticated personal workspaces and ownership, plus
-- workspace-scoped uniqueness so two users can never read or mutate one
-- another's records (the Phase 3 acceptance gate).
--
-- Why the uniqueness change matters:
--   documents.client_local_id was globally UNIQUE. Once several workspaces
--   share the table that is unsafe — workspace B's `ON CONFLICT
--   (client_local_id) DO UPDATE` would silently rewrite workspace A's row,
--   and B could not legitimately reuse a client id that A already used.
--   We replace it with a per-workspace uniqueness on
--   (workspace_id, client_local_id).
--
-- Legacy quarantine (Phase 3.4):
--   Existing rows keep workspace_id = NULL. Every authenticated read is
--   `WHERE workspace_id = $auth`, so NULL rows are invisible to all
--   workspaces until an administrator maps them. The unique index is
--   partial (WHERE workspace_id IS NOT NULL), so many quarantined rows may
--   share a client_local_id without violating it, and signing in never
--   auto-claims them.

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS users (
    id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    subject    VARCHAR(255) UNIQUE NOT NULL,   -- OIDC `sub` claim
    email      VARCHAR(255),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS workspaces (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    owner_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    kind          VARCHAR(16) NOT NULL DEFAULT 'personal',  -- personal | shared (Phase 8)
    created_at    TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS memberships (
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    user_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role         VARCHAR(16) NOT NULL DEFAULT 'owner',       -- owner only until Phase 8
    PRIMARY KEY (workspace_id, user_id)
);

ALTER TABLE documents
    ADD COLUMN IF NOT EXISTS workspace_id UUID REFERENCES workspaces(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_docs_workspace ON documents(workspace_id);

-- Drop the baseline's column-level UNIQUE(client_local_id) and replace it
-- with per-workspace uniqueness. The constraint name is the PostgreSQL
-- default for the column; DROP ... IF EXISTS keeps this idempotent.
ALTER TABLE documents
    DROP CONSTRAINT IF EXISTS documents_client_local_id_key;

CREATE UNIQUE INDEX IF NOT EXISTS documents_ws_client_unique
    ON documents(workspace_id, client_local_id)
    WHERE workspace_id IS NOT NULL;

-- The 002 ledger note ("Keyed on operation_id globally for now; Phase 3
-- scopes it per workspace") is realized here. operation_id stays a primary
-- key (client-generated UUID), and every lookup is additionally filtered by
-- workspace_id so a replay from another workspace cannot read a receipt.
ALTER TABLE accepted_operations
    ADD COLUMN IF NOT EXISTS workspace_id UUID REFERENCES workspaces(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_accepted_ops_workspace
    ON accepted_operations(operation_id, workspace_id);

-- No-login default (Phase 3 revised). The API is usable with
-- authentication OFF: anonymous requests are scoped to this single shared
-- "local device" workspace. It is seeded here with fixed ids so the
-- documents.workspace_id foreign key is satisfied without any sign-in
-- step. Real authenticated users still get their own personal workspaces
-- via the provisioner; this row simply backs the zero-login path.
INSERT INTO users (id, subject, email) VALUES
    ('00000000-0000-4000-8000-000000000000', 'local-device', NULL)
ON CONFLICT (subject) DO NOTHING;

INSERT INTO workspaces (id, owner_user_id, kind) VALUES
    ('00000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000000', 'personal')
ON CONFLICT (id) DO NOTHING;

INSERT INTO memberships (workspace_id, user_id, role) VALUES
    ('00000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000000', 'owner')
ON CONFLICT (workspace_id, user_id) DO NOTHING;

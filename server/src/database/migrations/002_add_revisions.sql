-- 002_add_revisions.sql
-- Phase 2.6: revision-aware batch sync.
--
-- `revision` is a monotonic per-document counter. The client sends its
-- baseRevision with each mutation; the server rejects (returns
-- `conflict`) if baseRevision != current revision. This lets
-- metadata-only changes be reconciled even when the file hash has not
-- moved, and it prevents a stale client from silently overwriting a
-- newer server record.
--
-- `accepted_operations` is the idempotency ledger: a client that
-- retries after a network drop gets the ORIGINAL result back rather
-- than double-applying. Keyed on operation_id globally for now; Phase
-- 3 scopes it per workspace.

ALTER TABLE documents
    ADD COLUMN IF NOT EXISTS revision INT NOT NULL DEFAULT 1;

CREATE TABLE IF NOT EXISTS accepted_operations (
    operation_id     VARCHAR(64) PRIMARY KEY,
    client_local_id  VARCHAR(64) NOT NULL,
    outcome          VARCHAR(16) NOT NULL,   -- applied | conflict | rejected
    revision_after   INT NOT NULL,
    error_code       VARCHAR(64),
    applied_at       TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_accepted_ops_client
    ON accepted_operations(client_local_id, applied_at DESC);

-- 003_add_document_metadata_fields.sql
-- Phase 4.8: metadata editing needs first-class columns for the note
-- and the pre-rename original file name so they survive round-trips
-- and participate in server-side search. Tags are carried in
-- custom_metadata JSONB (already trigger-indexed) rather than a
-- normalized table: normalized, workspace-scoped tag entities land
-- with Phase 3 identity, because an unscoped global tags table would
-- mix categories across the (currently unauthenticated) clients.

ALTER TABLE documents
    ADD COLUMN IF NOT EXISTS notes TEXT,
    ADD COLUMN IF NOT EXISTS original_file_name VARCHAR(255);

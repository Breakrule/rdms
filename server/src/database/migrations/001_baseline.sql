-- 001_baseline.sql
-- Fresh-install schema for the DMS metadata API.
-- This migration is the ordered, ledgered replacement for the previous
-- "run schema.sql every boot" bootstrap. Once applied, it is recorded in
-- schema_migrations and never re-executed. Later changes must land in
-- new numbered files (002_*.sql, 003_*.sql, ...), never by editing this
-- one in place after it has been deployed anywhere.

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Ledger of applied migrations. Kept inside the same schema so a fresh
-- database gets it created alongside the domain tables.
CREATE TABLE IF NOT EXISTS schema_migrations (
    id            SERIAL PRIMARY KEY,
    name          TEXT        NOT NULL UNIQUE,
    checksum      TEXT        NOT NULL,
    applied_at    TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS document_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL
);

CREATE TABLE IF NOT EXISTS documents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    client_local_id VARCHAR(64) UNIQUE NOT NULL,
    title VARCHAR(255) NOT NULL,
    document_number VARCHAR(100),
    category_id UUID REFERENCES document_categories(id) ON DELETE SET NULL,
    document_date DATE NOT NULL,
    fiscal_year INT NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    file_size_bytes BIGINT NOT NULL,
    mime_type VARCHAR(100) NOT NULL,
    sha256_hash VARCHAR(64) NOT NULL,
    gdrive_file_id VARCHAR(255),
    custom_metadata JSONB DEFAULT '{}',
    search_vector TSVECTOR,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_docs_search ON documents USING GIN(search_vector);
CREATE INDEX IF NOT EXISTS idx_docs_hash ON documents(sha256_hash);
CREATE INDEX IF NOT EXISTS idx_docs_client_id ON documents(client_local_id);

-- Trigger function to populate and update tsvector automatically
CREATE OR REPLACE FUNCTION update_document_search_vector() RETURNS trigger AS $$
BEGIN
    NEW.search_vector :=
        setweight(to_tsvector('simple', coalesce(NEW.title, '')), 'A') ||
        setweight(to_tsvector('simple', coalesce(NEW.document_number, '')), 'B') ||
        setweight(to_tsvector('simple', coalesce(NEW.file_name, '')), 'C') ||
        setweight(to_tsvector('simple', coalesce(NEW.custom_metadata->>'extractedText', '')), 'D');
    RETURN NEW;
END
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_documents_search_vector ON documents;
CREATE TRIGGER trg_documents_search_vector
BEFORE INSERT OR UPDATE ON documents
FOR EACH ROW EXECUTE FUNCTION update_document_search_vector();

-- Seed Default Categories
INSERT INTO document_categories (code, name) VALUES
('SK', 'Surat Keputusan'),
('LAPORAN', 'Laporan Pertanggungjawaban / Berkala'),
('NOTULA', 'Notula Rapat'),
('TEKNIS', 'Dokumen Petunjuk Teknis'),
('PERATURAN', 'Peraturan Daerah / Pedoman')
ON CONFLICT (code) DO NOTHING;

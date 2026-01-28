-- Migration: 20260128_001_create_captures
-- Description: Core captures table

CREATE TABLE IF NOT EXISTS captures (
    id              TEXT PRIMARY KEY,
    type            TEXT NOT NULL CHECK (type IN ('thought', 'link', 'file', 'image')),
    content         TEXT NOT NULL,
    source_url      TEXT,
    file_path       TEXT,
    thumbnail_path  TEXT,
    summary         TEXT,
    primary_tag_id  TEXT,
    is_deleted      INTEGER DEFAULT 0,
    created_at      TEXT NOT NULL,
    updated_at      TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_captures_type ON captures(type);
CREATE INDEX IF NOT EXISTS idx_captures_created_at ON captures(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_captures_is_deleted ON captures(is_deleted);

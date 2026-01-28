-- Migration: 20260128_002_create_tags
-- Description: Tags table

CREATE TABLE IF NOT EXISTS tags (
    id              TEXT PRIMARY KEY,
    name            TEXT NOT NULL UNIQUE,
    color           TEXT,
    is_system       INTEGER DEFAULT 0,
    created_at      TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_tags_name ON tags(name);

-- Add foreign key to captures (SQLite doesn't support ALTER TABLE ADD CONSTRAINT)
-- The FK relationship is documented but not enforced at DB level for SQLite compatibility
-- captures.primary_tag_id -> tags.id

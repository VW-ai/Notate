-- Migration: 001_initial
-- Description: Initial database schema for Notate M1

-- Migrations tracking table
CREATE TABLE IF NOT EXISTS migrations (
    version INTEGER PRIMARY KEY,
    applied_at TEXT NOT NULL
);

-- Core captures table
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
    updated_at      TEXT NOT NULL,
    FOREIGN KEY (primary_tag_id) REFERENCES tags(id)
);

CREATE INDEX IF NOT EXISTS idx_captures_type ON captures(type);
CREATE INDEX IF NOT EXISTS idx_captures_created_at ON captures(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_captures_primary_tag ON captures(primary_tag_id);
CREATE INDEX IF NOT EXISTS idx_captures_is_deleted ON captures(is_deleted);

-- Tags table
CREATE TABLE IF NOT EXISTS tags (
    id              TEXT PRIMARY KEY,
    name            TEXT NOT NULL UNIQUE,
    color           TEXT,
    is_system       INTEGER DEFAULT 0,
    created_at      TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_tags_name ON tags(name);

-- Capture-Tag many-to-many relationship
CREATE TABLE IF NOT EXISTS capture_tags (
    capture_id      TEXT NOT NULL,
    tag_id          TEXT NOT NULL,
    created_at      TEXT NOT NULL,
    PRIMARY KEY (capture_id, tag_id),
    FOREIGN KEY (capture_id) REFERENCES captures(id) ON DELETE CASCADE,
    FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_capture_tags_tag ON capture_tags(tag_id);

-- Traces table (for evolution tracking - M2+)
CREATE TABLE IF NOT EXISTS traces (
    id              TEXT PRIMARY KEY,
    title           TEXT NOT NULL,
    is_auto         INTEGER DEFAULT 1,
    created_at      TEXT NOT NULL,
    updated_at      TEXT NOT NULL
);

-- Capture-Trace relationship
CREATE TABLE IF NOT EXISTS capture_traces (
    capture_id      TEXT NOT NULL,
    trace_id        TEXT NOT NULL,
    position        INTEGER NOT NULL,
    created_at      TEXT NOT NULL,
    PRIMARY KEY (capture_id, trace_id),
    FOREIGN KEY (capture_id) REFERENCES captures(id) ON DELETE CASCADE,
    FOREIGN KEY (trace_id) REFERENCES traces(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_capture_traces_trace ON capture_traces(trace_id);
CREATE INDEX IF NOT EXISTS idx_capture_traces_position ON capture_traces(trace_id, position);

-- Habits table (for M2+)
CREATE TABLE IF NOT EXISTS habits (
    id              TEXT PRIMARY KEY,
    name            TEXT NOT NULL,
    description     TEXT NOT NULL,
    trigger_type    TEXT NOT NULL CHECK (trigger_type IN ('link', 'file_type', 'manual')),
    trigger_pattern TEXT,
    action_prompt   TEXT NOT NULL,
    is_active       INTEGER DEFAULT 1,
    is_system       INTEGER DEFAULT 0,
    trigger_count   INTEGER DEFAULT 0,
    last_triggered_at TEXT,
    created_at      TEXT NOT NULL,
    updated_at      TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_habits_trigger_type ON habits(trigger_type);
CREATE INDEX IF NOT EXISTS idx_habits_is_active ON habits(is_active);

-- Settings table
CREATE TABLE IF NOT EXISTS settings (
    key             TEXT PRIMARY KEY,
    value           TEXT NOT NULL,
    updated_at      TEXT NOT NULL
);

-- Insert default settings
INSERT OR IGNORE INTO settings (key, value, updated_at) VALUES
    ('evolution_hint_enabled', 'true', datetime('now')),
    ('evolution_hint_mode', 'prompt', datetime('now')),
    ('global_shortcut', '⌘+Shift+Space', datetime('now')),
    ('theme', 'system', datetime('now'));

-- Record migration
INSERT OR IGNORE INTO migrations (version, applied_at) VALUES (1, datetime('now'));

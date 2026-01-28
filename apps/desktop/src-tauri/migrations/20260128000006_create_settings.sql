-- Migration: 20260128_006_create_settings
-- Description: Settings table and default values

CREATE TABLE IF NOT EXISTS settings (
    key             TEXT PRIMARY KEY,
    value           TEXT NOT NULL,
    updated_at      TEXT NOT NULL
);

-- Insert default settings
INSERT OR IGNORE INTO settings (key, value, updated_at) VALUES
    ('evolution_hint_enabled', 'true', datetime('now')),
    ('evolution_hint_mode', 'prompt', datetime('now')),
    ('global_shortcut', 'CommandOrControl+Shift+Space', datetime('now')),
    ('theme', 'system', datetime('now'));

-- TODO: M2 - Async tasks table for AI processing
-- CREATE TABLE IF NOT EXISTS tasks (
--     id              TEXT PRIMARY KEY,
--     task_type       TEXT NOT NULL,  -- 'tagging', 'summary', 'embedding'
--     capture_id      TEXT,
--     status          TEXT NOT NULL,  -- 'pending', 'running', 'completed', 'failed'
--     result          TEXT,
--     error           TEXT,
--     created_at      TEXT NOT NULL,
--     completed_at    TEXT,
--     FOREIGN KEY (capture_id) REFERENCES captures(id) ON DELETE CASCADE
-- );

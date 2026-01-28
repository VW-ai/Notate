-- Migration: 20260128_005_create_habits
-- Description: Habits table for automation rules (M2+)

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

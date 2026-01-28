-- Migration: 20260128_004_create_traces
-- Description: Traces table for evolution tracking (M2+)

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

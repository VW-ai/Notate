-- Migration: 20260128_003_create_capture_tags
-- Description: Capture-Tag many-to-many relationship

CREATE TABLE IF NOT EXISTS capture_tags (
    capture_id      TEXT NOT NULL,
    tag_id          TEXT NOT NULL,
    created_at      TEXT NOT NULL,
    PRIMARY KEY (capture_id, tag_id),
    FOREIGN KEY (capture_id) REFERENCES captures(id) ON DELETE CASCADE,
    FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_capture_tags_tag ON capture_tags(tag_id);

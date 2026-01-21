# Data Schema

**版本:** 1.0

---

## 存储概览

```
┌─────────────────────────────────────────────────────────────────┐
│                          存储层                                   │
├───────────────────┬───────────────────┬─────────────────────────┤
│      SQLite       │     LanceDB       │     File System         │
│   (结构化数据)     │    (向量数据)      │     (文件存储)           │
├───────────────────┼───────────────────┼─────────────────────────┤
│ • captures        │ • embeddings      │ • images/               │
│ • tags            │                   │ • documents/            │
│ • capture_tags    │                   │ • thumbnails/           │
│ • traces          │                   │                         │
│ • capture_traces  │                   │                         │
│ • habits          │                   │                         │
│ • settings        │                   │                         │
└───────────────────┴───────────────────┴─────────────────────────┘
```

---

## SQLite Schema

### captures

核心内容表。

```sql
CREATE TABLE captures (
    id              TEXT PRIMARY KEY,           -- UUID
    type            TEXT NOT NULL,              -- 'thought' | 'link' | 'file' | 'image'
    content         TEXT NOT NULL,              -- 文本内容
    source_url      TEXT,                       -- 原始 URL（link 类型）
    file_path       TEXT,                       -- 文件存储路径
    thumbnail_path  TEXT,                       -- 缩略图路径
    summary         TEXT,                       -- AI 生成的摘要
    primary_tag_id  TEXT,                       -- 主标签 ID（Canvas 归属）
    is_deleted      INTEGER DEFAULT 0,          -- 软删除标记
    created_at      TEXT NOT NULL,              -- ISO 8601
    updated_at      TEXT NOT NULL,              -- ISO 8601

    FOREIGN KEY (primary_tag_id) REFERENCES tags(id)
);

CREATE INDEX idx_captures_type ON captures(type);
CREATE INDEX idx_captures_created_at ON captures(created_at DESC);
CREATE INDEX idx_captures_primary_tag ON captures(primary_tag_id);
CREATE INDEX idx_captures_is_deleted ON captures(is_deleted);
```

### tags

标签表。

```sql
CREATE TABLE tags (
    id              TEXT PRIMARY KEY,           -- UUID
    name            TEXT NOT NULL UNIQUE,       -- 标签名
    color           TEXT,                       -- 颜色（hex）
    is_system       INTEGER DEFAULT 0,          -- 系统标签
    created_at      TEXT NOT NULL
);

CREATE INDEX idx_tags_name ON tags(name);
```

### capture_tags

Capture 与 Tag 多对多关联。

```sql
CREATE TABLE capture_tags (
    capture_id      TEXT NOT NULL,
    tag_id          TEXT NOT NULL,
    created_at      TEXT NOT NULL,

    PRIMARY KEY (capture_id, tag_id),
    FOREIGN KEY (capture_id) REFERENCES captures(id) ON DELETE CASCADE,
    FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
);

CREATE INDEX idx_capture_tags_tag ON capture_tags(tag_id);
```

### traces

演化轨迹表。

```sql
CREATE TABLE traces (
    id              TEXT PRIMARY KEY,           -- UUID
    title           TEXT NOT NULL,              -- 标题（AI 生成，可编辑）
    is_auto         INTEGER DEFAULT 1,          -- 是否自动生成
    created_at      TEXT NOT NULL,
    updated_at      TEXT NOT NULL
);
```

### capture_traces

Capture 与 Trace 关联（有序）。

```sql
CREATE TABLE capture_traces (
    capture_id      TEXT NOT NULL,
    trace_id        TEXT NOT NULL,
    position        INTEGER NOT NULL,           -- 在 Trace 中的位置（从 1 开始）
    created_at      TEXT NOT NULL,

    PRIMARY KEY (capture_id, trace_id),
    FOREIGN KEY (capture_id) REFERENCES captures(id) ON DELETE CASCADE,
    FOREIGN KEY (trace_id) REFERENCES traces(id) ON DELETE CASCADE
);

CREATE INDEX idx_capture_traces_trace ON capture_traces(trace_id);
CREATE INDEX idx_capture_traces_position ON capture_traces(trace_id, position);
```

### habits

习惯规则表。

```sql
CREATE TABLE habits (
    id              TEXT PRIMARY KEY,           -- UUID
    name            TEXT NOT NULL,              -- 显示名称
    description     TEXT NOT NULL,              -- 用户输入的自然语言描述
    trigger_type    TEXT NOT NULL,              -- 'link' | 'file_type' | 'manual'
    trigger_pattern TEXT,                       -- URL 匹配模式或文件类型
    action_prompt   TEXT NOT NULL,              -- 执行时的 AI prompt
    is_active       INTEGER DEFAULT 1,          -- 是否启用
    is_system       INTEGER DEFAULT 0,          -- 是否为系统默认
    trigger_count   INTEGER DEFAULT 0,          -- 触发次数
    last_triggered_at TEXT,                     -- 最后触发时间
    created_at      TEXT NOT NULL,
    updated_at      TEXT NOT NULL
);

CREATE INDEX idx_habits_trigger_type ON habits(trigger_type);
CREATE INDEX idx_habits_is_active ON habits(is_active);
```

### settings

应用设置表。

```sql
CREATE TABLE settings (
    key             TEXT PRIMARY KEY,
    value           TEXT NOT NULL,
    updated_at      TEXT NOT NULL
);
```

**预置设置项**：

| key | 默认值 | 说明 |
|-----|--------|------|
| evolution_hint_enabled | true | 是否显示演化提示 |
| evolution_hint_mode | 'prompt' | 'prompt' \| 'silent' |
| global_shortcut | '⌘+Shift+Space' | 全局快捷键 |
| theme | 'system' | 'light' \| 'dark' \| 'system' |

---

## LanceDB Schema

### embeddings

向量存储表。

| 字段 | 类型 | 说明 |
|------|------|------|
| id | string | Capture UUID |
| vector | float[768] | Embedding 向量 |
| created_at | string | ISO 8601 |

**索引配置**：
- 索引类型：IVF_PQ
- nlist: 100
- nprobe: 10

---

## File System

### 目录结构

```
~/Library/Application Support/Notate/
├── db/
│   ├── notate.db              -- SQLite 数据库
│   └── vectors/               -- LanceDB 数据目录
│       └── embeddings/
├── files/
│   ├── images/
│   │   └── {year-month}/      -- 按月分目录
│   │       └── {uuid}.{ext}
│   └── documents/
│       └── {year-month}/
│           └── {uuid}.{ext}
├── cache/
│   └── thumbnails/
│       └── {uuid}.webp        -- 缩略图（统一 webp 格式）
└── logs/
    └── notate.log
```

### 文件命名规则

- 图片：`{uuid}.{original_ext}` → 保留原始格式
- 文档：`{uuid}.{original_ext}` → 保留原始格式
- 缩略图：`{uuid}.webp` → 统一 webp，最大 200x200

### 文件大小限制

| 类型 | 限制 |
|------|------|
| 图片 | 10 MB |
| PDF | 50 MB |
| 缩略图 | 50 KB |

---

## 数据迁移

### Migration 表

```sql
CREATE TABLE migrations (
    version         INTEGER PRIMARY KEY,
    applied_at      TEXT NOT NULL
);
```

### 迁移文件命名

```
migrations/
├── 001_initial.sql
├── 002_add_thumbnail.sql
└── ...
```

---

## 数据一致性

### 删除级联

| 操作 | 影响 |
|------|------|
| 删除 Capture | 移除 capture_tags、capture_traces 关联，删除 embedding |
| 删除 Tag | 移除 capture_tags 关联，更新 primary_tag_id |
| 删除 Trace | 移除 capture_traces 关联 |

### Trace 维护规则

- Capture 加入 Trace 后重新计算 position
- Trace 中 Capture < 3 时删除 Trace
- Capture 删除时检查并清理空 Trace

---

## 备份策略

| 数据 | 备份方式 |
|------|----------|
| SQLite | 定期 VACUUM + 复制文件 |
| LanceDB | 目录复制 |
| Files | 目录复制 |

**MVP 阶段不实现自动备份**，用户可手动复制整个 Application Support/Notate 目录。

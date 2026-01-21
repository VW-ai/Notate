# Notate 后端架构

**版本:** 1.0  
**日期:** 2025-01-20  

---

## 架构概览

```
┌─────────────────────────────────────────────────────────────────┐
│                         用户界面                                 │
│                    React + TypeScript                           │
├─────────────────────────────────────────────────────────────────┤
│                       Tauri IPC                                 │
├─────────────────────────────────────────────────────────────────┤
│                       核心服务层                                 │
│   Capture    │   Knowledge   │   Evolution   │   Habits        │
├─────────────────────────────────────────────────────────────────┤
│                       AI 服务层                                  │
│                   Gemini Provider                               │
├─────────────────────────────────────────────────────────────────┤
│                        存储层                                    │
│      SQLite        │      LanceDB       │     File System       │
└─────────────────────────────────────────────────────────────────┘
```

---

## 技术选型

| 层级 | 技术 | 选型理由 |
|------|------|----------|
| 桌面框架 | Tauri 2.0 | 小包体积(~10MB)，Rust 性能，全局快捷键支持 |
| 前端 | React 18 + TypeScript | 生态成熟 |
| 状态管理 | Zustand | 轻量，API 简洁 |
| 结构化存储 | SQLite | Rust 原生支持，单文件，零配置 |
| 向量存储 | LanceDB | 嵌入式向量库，无需单独服务 |
| AI | Gemini API | 多语言 Embedding，多模态，免费额度充足 |

---

## 核心服务职责

### Capture Service
- 创建/更新/删除 Capture
- 文件处理（存储、文本提取）
- 触发 AI 异步处理

### Knowledge Service
- 语义搜索
- Timeline/Canvas/Types 数据查询
- Related 内容计算

### Evolution Service
- 演化检测（保存时检测相似内容）
- Trace 自动生成和管理
- Canvas 布局计算

### Habits Service
- Habit 匹配和执行
- 自然语言规则解析

---

## AI 服务能力

| 能力 | 模型 | 用途 |
|------|------|------|
| Embedding | text-embedding-004 | 语义搜索、演化检测、聚类 |
| 结构化输出 | gemini-1.5-flash | 打标签、Habit 解析 |
| 文本生成 | gemini-1.5-flash | 摘要、Trace 标题 |
| 多模态 | gemini-1.5-flash | 图片 OCR、PDF 理解 |

---

## 存储设计

### SQLite 核心表

| 表 | 用途 |
|-----|------|
| captures | 核心内容（想法/链接/文件） |
| tags | 标签 |
| capture_tags | 多对多关联 |
| traces | 演化轨迹 |
| capture_traces | 轨迹-内容关联 |
| habits | 习惯规则 |

### LanceDB 向量表

| 表 | 字段 |
|-----|------|
| capture_embeddings | id, embedding(768维), created_at |

### 文件目录

```
~/Library/Application Support/Notate/
├── db/notate.db
├── db/vectors/
├── files/images/{year-month}/
├── files/documents/{year-month}/
└── cache/thumbnails/
```

---

## 关键设计决策

| 决策 | 选择 | 理由 |
|------|------|------|
| Embedding 位置 | 云端 Gemini | 多语言质量好，无需本地模型 |
| 演化检测时机 | 实时 | 用户立即看到提示 |
| Trace 生成 | 自动（≥3 条相似） | 低门槛，自然积累 |
| Canvas 布局 | AI 计算语义位置 | Tag 按相关性聚集 |
| 数据同步 | MVP 不做 | 简化范围 |

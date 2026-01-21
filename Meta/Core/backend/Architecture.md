# Backend Architecture

**版本:** 1.0

---

## 模块概览

```
┌─────────────────────────────────────────────────────────────────────┐
│                          Tauri Commands                              │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐              │
│  │   Capture    │  │  Knowledge   │  │   Habits     │              │
│  │   Service    │  │   Service    │  │   Service    │              │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘              │
│         │                 │                 │                        │
│         └────────────┬────┴────────────────┘                        │
│                      │                                               │
│              ┌───────▼───────┐                                      │
│              │   Evolution   │                                      │
│              │    Service    │                                      │
│              └───────┬───────┘                                      │
│                      │                                               │
│         ┌────────────┼────────────┐                                 │
│         │            │            │                                 │
│  ┌──────▼──────┐ ┌───▼────┐ ┌────▼─────┐                          │
│  │  AI Agent   │ │  Data  │ │  Event   │                          │
│  │   Layer     │ │  Layer │ │  Emitter │                          │
│  └─────────────┘ └────────┘ └──────────┘                          │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 模块职责

### Service Layer

| 模块 | 职责 | 依赖 |
|------|------|------|
| CaptureService | 创建/更新/删除 Capture，文件处理 | DataLayer, AIAgent |
| KnowledgeService | 搜索、时间线、Canvas 布局查询 | DataLayer, EvolutionService |
| HabitsService | Habit 匹配、创建、执行 | DataLayer, AIAgent |
| EvolutionService | 演化检测、Trace 管理 | DataLayer, AIAgent |

### 模块交互流程

#### 创建 Capture 流程
```
CaptureService.create()
    │
    ├─→ DataLayer.saveCapture()
    │
    ├─→ AIAgent.processAsync()  ──→ EventEmitter.emit('ai_processing_complete')
    │       │
    │       ├─→ generateEmbedding()
    │       ├─→ generateTags()
    │       └─→ generateSummary()
    │
    └─→ EvolutionService.detect()
            │
            ├─→ findSimilar() → return EvolutionHint
            │
            └─→ updateTraces()  ──→ EventEmitter.emit('trace_updated')
```

#### 搜索流程
```
KnowledgeService.search(query)
    │
    ├─→ AIAgent.getEmbedding(query)
    │
    └─→ DataLayer.vectorSearch(embedding)
            │
            └─→ return Capture[]
```

---

## AI Agent 设计

### Agent 架构

```
┌─────────────────────────────────────────────────────────────────┐
│                         AI Agent Layer                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │  Organizer   │  │   Surface    │  │    Habit     │          │
│  │    Agent     │  │    Agent     │  │   Executor   │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                    Gemini Provider                       │   │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐    │   │
│  │  │Embedding│  │ Tagging │  │ Summary │  │Multimodal│    │   │
│  │  └─────────┘  └─────────┘  └─────────┘  └─────────┘    │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Organizer Agent

**职责**：自动整理用户输入的内容

| 任务 | 输入 | 输出 | 模型 |
|------|------|------|------|
| Embedding | content | vector[768] | text-embedding-004 |
| Tagging | content, existingTags | Tag[] | gemini-1.5-flash |
| Summary | content | string | gemini-1.5-flash |
| OCR | image | string | gemini-1.5-flash |
| PDF Extract | pdf | string | gemini-1.5-flash |

**Tagging Prompt 模板**：
```
你是一个标签生成助手。根据以下内容生成 1-3 个标签。

现有标签库：{existingTags}

内容：
{content}

规则：
1. 优先使用现有标签
2. 只在确实需要时创建新标签
3. 标签应该是名词或短语
4. 返回 JSON 格式：{ "tags": ["tag1", "tag2"] }
```

### Surface Agent

**职责**：发现内容之间的关联

| 任务 | 触发时机 | 输出 |
|------|----------|------|
| 演化检测 | Capture 创建后 | EvolutionHint |
| Related 计算 | 请求详情时 | Capture[] |
| Trace 聚类 | 周期性 / Capture 创建后 | Trace |

**演化检测算法**：
```
1. 获取新 Capture 的 Embedding
2. 向量搜索 Top 10（余弦相似度 > 0.75）
3. 过滤：排除自身，排除 1 小时内
4. 返回最相似的作为 EvolutionHint
```

**Trace 标题生成 Prompt**：
```
以下是用户在不同时间记录的几条相关想法：

{captures_content}

请生成一个简短标题（不超过 10 字），概括这些想法的核心主题。
只返回标题文字，不要其他内容。
```

### Habit Executor Agent

**职责**：理解和执行用户定义的规则

**规则解析 Prompt**：
```
用户用自然语言描述了一个规则：
"{description}"

请解析这个规则，返回 JSON：
{
  "triggerType": "link" | "file_type" | "manual",
  "triggerPattern": "URL 匹配模式或文件类型",
  "actions": ["动作1", "动作2"],
  "tags": ["标签1"]
}
```

**执行流程**：
```
1. 检测内容是否匹配 Habit
2. 获取 Habit 的 actionPrompt
3. 调用 AI 执行具体动作
4. 更新 Capture（添加标签、摘要等）
```

---

## 异步处理

### 任务队列

```
CaptureCreated
    │
    └─→ AsyncQueue
            │
            ├─→ [Priority 1] Embedding  ──→ 用于演化检测
            │
            ├─→ [Priority 2] Evolution Detection
            │
            ├─→ [Priority 3] Tagging
            │
            └─→ [Priority 4] Summary
```

### 超时和重试策略

| 任务 | 超时 | 重试次数 | 失败处理 |
|------|------|----------|----------|
| Embedding | 10s | 2 | 记录错误，不阻塞 |
| Tagging | 15s | 1 | 使用空标签 |
| Summary | 15s | 1 | 使用空摘要 |
| Evolution | 5s | 0 | 跳过提示 |

---

## 错误处理

### 错误传播

```
Service Layer
    │
    ├─→ 业务错误 → 返回 ErrorResponse
    │
    └─→ 系统错误 → 记录日志 → 返回 INTERNAL_ERROR
```

### 日志规范

| 级别 | 场景 |
|------|------|
| ERROR | AI API 失败、数据库错误 |
| WARN | 超时、重试 |
| INFO | 请求处理完成 |
| DEBUG | 详细参数、中间状态 |

---

## 性能目标

| 操作 | 目标延迟 |
|------|----------|
| create_capture（同步部分） | < 200ms |
| get_capture | < 100ms |
| semantic_search | < 500ms |
| get_timeline | < 100ms |
| get_canvas_layout | < 200ms（缓存命中） |

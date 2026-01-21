# Notate API 接口

**版本:** 1.0  
**日期:** 2025-01-20  

---

## 通信机制

Tauri IPC：
- **Commands**：前端调用后端，同步/异步返回
- **Events**：后端推送前端，用于异步任务完知

---

## 核心数据类型

### Capture
| 字段 | 类型 | 说明 |
|------|------|------|
| id | string | UUID |
| type | 'thought' \| 'link' \| 'file' \| 'image' | 类型 |
| content | string | 文本内容 |
| filePath | string? | 文件路径 |
| summary | string? | AI 摘要 |
| tags | Tag[] | 标签列表 |
| createdAt | string | ISO 时间 |

### Trace
| 字段 | 类型 | 说明 |
|------|------|------|
| id | string | UUID |
| title | string | 标题（AI 生成，可编辑） |
| captures | Capture[] | 按时间排序的内容 |

### Habit
| 字段 | 类型 | 说明 |
|------|------|------|
| id | string | UUID |
| name | string | 名称 |
| triggerType | 'link' \| 'file_type' \| 'manual' | 触发类型 |
| triggerPattern | string? | 匹配模式 |
| actionPrompt | string | 自然语言规则 |
| isActive | boolean | 是否启用 |

---

## Commands 列表

### Capture 相关

| Command | 输入 | 输出 | 说明 |
|---------|------|------|------|
| create_capture | type, content, file?, habitId? | Capture + EvolutionHint? | 创建，返回演化提示 |
| get_capture | id | CaptureDetail | 获取详情含 related |
| update_capture | id, content | Capture | 更新内容 |
| delete_capture | id | void | 软删除 |

### Knowledge 相关

| Command | 输入 | 输出 | 说明 |
|---------|------|------|------|
| semantic_search | query, limit? | Capture[] | 语义搜索 |
| get_timeline | cursor?, limit? | { captures, hasMore } | 时间线分页 |
| get_canvas_layout | - | CanvasLayout | Canvas 布局 |
| get_traces | - | Trace[] | 所有轨迹 |
| get_types_summary | - | TypesSummary | 类型统计 |

### Evolution 相关

| Command | 输入 | 输出 | 说明 |
|---------|------|------|------|
| update_trace_title | traceId, title | void | 编辑标题 |

### Habits 相关

| Command | 输入 | 输出 | 说明 |
|---------|------|------|------|
| get_habits | - | Habit[] | 所有习惯 |
| get_matching_habits | content, mimeType? | Habit[] | 匹配的习惯 |
| create_habit | description | Habit + ParsedRule | 自然语言创建 |
| toggle_habit | id, active | void | 开关 |

### Message Refinement

| Command | 输入 | 输出 | 说明 |
|---------|------|------|------|
| refine_message | context, message, style? | { refined } | 消息优化 |

---

## Events 列表

| Event | 数据 | 触发时机 |
|-------|------|----------|
| ai_processing_complete | captureId, tags, summary | AI 处理完成 |
| trace_created | trace | 新 Trace 创建 |
| trace_updated | traceId | Trace 更新 |

---

## 错误码

| 错误码 | 说明 |
|--------|------|
| INVALID_INPUT | 输入参数无效 |
| NOT_FOUND | 资源不存在 |
| AI_API_ERROR | AI 服务调用失败 |
| FILE_TOO_LARGE | 文件超过限制 |
| UNSUPPORTED_FILE_TYPE | 不支持的文件类型 |

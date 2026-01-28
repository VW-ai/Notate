# Notate IPC 接口

**版本:** 1.2
**日期:** 2026-01-28

---

## 通信机制

Tauri IPC：

- **Commands**：前端调用后端，同步/异步返回
- **Events**：后端推送前端，用于异步任务通知

---

## 数据类型

### 基础类型

#### Tag

| 字段  | 类型    | 说明              |
| ----- | ------- | ----------------- |
| id    | string  | UUID              |
| name  | string  | 标签名称          |
| color | string? | 颜色（hex）       |
| count | number  | 关联 Capture 数量 |

#### CaptureType

```typescript
type CaptureType = "thought" | "link" | "file" | "image";
```

#### RefineStyle

```typescript
type RefineStyle =
  | "professional"
  | "polite"
  | "friendly"
  | "shorter"
  | "longer";
```

---

### 核心类型

#### Capture

| 字段          | 类型        | 说明                          |
| ------------- | ----------- | ----------------------------- |
| id            | string      | UUID                          |
| type          | CaptureType | 类型                          |
| content       | string      | 文本内容                      |
| sourceUrl     | string?     | 链接原始 URL                  |
| filePath      | string?     | 文件存储路径                  |
| thumbnailPath | string?     | 缩略图路径（图片/PDF）        |
| summary       | string?     | AI 生成的摘要                 |
| tags          | Tag[]       | 标签列表                      |
| primaryTagId  | string?     | 主标签 ID（用于 Canvas 归属） |
| createdAt     | string      | ISO 8601 时间                 |
| updatedAt     | string      | ISO 8601 时间                 |
| isDeleted     | boolean     | 软删除标记                    |

#### CaptureDetail

| 字段    | 类型       | 说明                         |
| ------- | ---------- | ---------------------------- |
| capture | Capture    | 完整 Capture 数据            |
| related | Capture[]  | 语义相关的 Captures（top 5） |
| trace   | TraceInfo? | 所属 Trace 信息（如有）      |

#### TraceInfo

| 字段     | 类型   | 说明                                        |
| -------- | ------ | ------------------------------------------- |
| id       | string | Trace UUID                                  |
| title    | string | Trace 标题                                  |
| position | number | 当前 Capture 在 Trace 中的位置（从 1 开始） |
| total    | number | Trace 中 Capture 总数                       |

#### Trace

| 字段      | 类型      | 说明                        |
| --------- | --------- | --------------------------- |
| id        | string    | UUID                        |
| title     | string    | 标题（AI 生成，用户可编辑） |
| captures  | Capture[] | 按时间排序的 Captures       |
| createdAt | string    | ISO 8601 时间               |
| updatedAt | string    | ISO 8601 时间               |

#### Habit

| 字段            | 类型                              | 说明                   |
| --------------- | --------------------------------- | ---------------------- |
| id              | string                            | UUID                   |
| name            | string                            | 显示名称               |
| description     | string                            | 用户输入的自然语言描述 |
| triggerType     | 'link' \| 'file_type' \| 'manual' | 触发类型               |
| triggerPattern  | string?                           | URL 匹配模式或文件类型 |
| actionPrompt    | string                            | 执行时的 AI prompt     |
| isActive        | boolean                           | 是否启用               |
| isSystem        | boolean                           | 是否为系统默认         |
| triggerCount    | number                            | 触发次数               |
| lastTriggeredAt | string?                           | 最后触发时间           |
| createdAt       | string                            | ISO 8601 时间          |

#### ParsedRule

| 字段           | 类型     | 说明             |
| -------------- | -------- | ---------------- |
| triggerType    | string   | 解析出的触发类型 |
| triggerPattern | string?  | 解析出的匹配模式 |
| actions        | string[] | 解析出的动作列表 |
| tags           | string[] | 解析出的标签     |

---

### 视图类型

#### EvolutionHint

| 字段       | 类型                                                      | 说明                                         |
| ---------- | --------------------------------------------------------- | -------------------------------------------- |
| oldCapture | CapturePreview                                            | 相关的旧 Capture                             |
| similarity | number                                                    | 相似度（0-1）                                |
| daysAgo    | number                                                    | 距今天数                                     |
| relation   | 'evolution' \| 'duplicate' \| 'supplement' \| 'unrelated' | 语义关系类型                                 |
| summary    | string?                                                   | 变化摘要（仅 relation = 'evolution' 时返回） |
| aspect     | string?                                                   | 变化的维度/话题                              |

#### CapturePreview

| 字段      | 类型        | 说明                  |
| --------- | ----------- | --------------------- |
| id        | string      | UUID                  |
| type      | CaptureType | 类型                  |
| content   | string      | 内容（截断至 100 字） |
| createdAt | string      | ISO 8601 时间         |

#### CanvasLayout

| 字段    | 类型       | 说明                     |
| ------- | ---------- | ------------------------ |
| tags    | TagBlock[] | Tag 区块列表             |
| version | string     | 布局版本（用于缓存失效） |

#### TagBlock

| 字段     | 类型                     | 说明                    |
| -------- | ------------------------ | ----------------------- |
| tag      | Tag                      | 标签信息                |
| position | { x: number, y: number } | 2D 位置（0-100 归一化） |
| captures | CapturePreview[]         | 区块内的 Captures       |

#### TypesSummary

| 字段     | 类型          | 说明          |
| -------- | ------------- | ------------- |
| thoughts | TypeCount     | 想法统计      |
| links    | TypeCount     | 链接统计      |
| files    | TypeCount     | 文件统计      |
| images   | TypeCount     | 图片统计      |
| entities | EntitySummary | AI 识别的实体 |

#### TypeCount

| 字段       | 类型   | 说明     |
| ---------- | ------ | -------- |
| total      | number | 总数     |
| todayCount | number | 今日新增 |

#### EntitySummary

| 字段      | 类型   | 说明     |
| --------- | ------ | -------- |
| people    | number | 人物数量 |
| companies | number | 公司数量 |
| projects  | number | 项目数量 |

#### TimelineResponse

| 字段       | 类型      | 说明         |
| ---------- | --------- | ------------ |
| captures   | Capture[] | Capture 列表 |
| hasMore    | boolean   | 是否有更多   |
| nextCursor | string?   | 下一页游标   |

---

## Commands

### Capture 相关

#### create_capture

创建新的 Capture。

**输入：**
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| type | CaptureType | ✓ | 内容类型 |
| content | string | ✓ | 文本内容 |
| sourceUrl | string? | - | 链接类 Capture 的来源 URL |
| habitId | string? | - | 指定执行的 Habit ID |

**输出：** `Capture`

> 说明：当前实现仅返回 Capture。演化提示（EvolutionHint）将在演化检测落地后（M4）扩展为 `CreateCaptureResponse = { capture, evolutionHint? }`。

---

#### get_capture

获取 Capture 详情。

**输入：**
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| id | string | ✓ | Capture UUID |

**输出：** `CaptureDetail`

---

#### update_capture

更新 Capture 内容。

**输入：**
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| id | string | ✓ | Capture UUID |
| content | string | ✓ | 新内容 |

**输出：** `Capture`

---

#### delete_capture

软删除 Capture。

**输入：**
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| id | string | ✓ | Capture UUID |

**输出：** `void`

---

### Knowledge 相关

#### semantic_search

语义搜索 Captures。

**输入：**
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| query | string | ✓ | 搜索查询 |
| limit | number? | - | 返回数量（默认 20） |

**输出：** `Capture[]`

---

#### get_timeline

获取时间线（分页）。

**输入：**
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| cursor | string? | - | 分页游标 |
| limit | number? | - | 每页数量（默认 20） |
| tagId | string? | - | 按标签筛选 |

**输出：** `TimelineResponse`

---

#### get_canvas_layout

获取 Canvas 布局。

**输入：** 无

**输出：** `CanvasLayout`

---

#### get_traces

获取所有 Traces。

**输入：** 无

**输出：** `Trace[]`

---

#### get_types_summary

获取类型统计。

**输入：** 无

**输出：** `TypesSummary`

---

### Evolution 相关

#### update_trace_title

更新 Trace 标题。

**输入：**
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| traceId | string | ✓ | Trace UUID |
| title | string | ✓ | 新标题 |

**输出：** `void`

---

### Habits 相关

#### get_habits

获取所有 Habits。

**输入：** 无

**输出：** `Habit[]`

---

#### get_matching_habits

获取匹配的 Habits。

**输入：**
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| content | string | ✓ | 内容（URL 或文本） |
| mimeType | string? | - | 文件 MIME 类型 |

**输出：** `Habit[]`

---

#### create_habit

用自然语言创建 Habit。

**输入：**
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| description | string | ✓ | 自然语言描述 |

**输出：**
| 字段 | 类型 | 说明 |
|------|------|------|
| habit | Habit | 创建的 Habit |
| parsedRule | ParsedRule | AI 解析结果 |

---

#### toggle_habit

开关 Habit。

**输入：**
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| id | string | ✓ | Habit UUID |
| active | boolean | ✓ | 启用状态 |

**输出：** `void`

---

### Message Refinement

#### refine_message

消息优化。

**输入：**
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| context | string | ✓ | 上下文（截屏 OCR 或粘贴内容） |
| message | string | ✓ | 想要表达的内容 |
| style | RefineStyle? | - | 风格（默认 professional） |

**输出：**
| 字段 | 类型 | 说明 |
|------|------|------|
| refined | string | 优化后的消息 |

---

## Events

后端推送到前端的事件。

#### ai_processing_complete

AI 异步处理完成。

**数据：**
| 字段 | 类型 | 说明 |
|------|------|------|
| captureId | string | Capture UUID |
| tags | Tag[] | AI 生成的标签 |
| summary | string? | AI 生成的摘要 |

---

#### trace_created

新 Trace 创建。

**数据：**
| 字段 | 类型 | 说明 |
|------|------|------|
| trace | Trace | 新创建的 Trace |

---

#### trace_updated

Trace 更新（新 Capture 加入）。

**数据：**
| 字段 | 类型 | 说明 |
|------|------|------|
| traceId | string | Trace UUID |
| captureId | string | 新加入的 Capture UUID |

---

## 错误处理

### 错误响应格式

```typescript
interface ErrorResponse {
  code: ErrorCode;
  message: string;
  details?: Record<string, unknown>;
}
```

### 错误码

| 错误码                | HTTP 等效 | 说明                                |
| --------------------- | --------- | ----------------------------------- |
| INVALID_INPUT         | 400       | 输入参数无效                        |
| NOT_FOUND             | 404       | 资源不存在                          |
| AI_API_ERROR          | 502       | AI 服务调用失败                     |
| FILE_TOO_LARGE        | 413       | 文件超过限制（图片 10MB，PDF 50MB） |
| UNSUPPORTED_FILE_TYPE | 415       | 不支持的文件类型                    |
| INTERNAL_ERROR        | 500       | 内部错误                            |

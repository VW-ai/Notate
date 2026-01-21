# Data Driven Development

**版本:** 1.0

---

## 核心原则

> **数据即真相**：所有状态都由数据文件定义，代码只是数据的解释器。

### 为什么 Data Driven？

1. **可预测性** - 状态变化可追踪，易于调试
2. **可配置性** - 修改 YAML 即可改变行为，无需改代码
3. **可测试性** - 用不同数据文件测试不同场景
4. **可扩展性** - 新增功能只需新增数据定义

---

## YAML 状态管理

### 状态分层

```
┌─────────────────────────────────────────────────────────────────┐
│                        状态分层                                   │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────┐                                               │
│  │   Static     │  编译时确定，代码内置                           │
│  │   Config     │  例：默认 Habits、错误消息                      │
│  └──────────────┘                                               │
│                                                                  │
│  ┌──────────────┐                                               │
│  │   App        │  运行时加载，用户可修改                         │
│  │   Config     │  例：快捷键、主题、AI 设置                      │
│  └──────────────┘                                               │
│                                                                  │
│  ┌──────────────┐                                               │
│  │   Runtime    │  运行时动态变化                                 │
│  │   State      │  例：当前视图、选中项、加载状态                  │
│  └──────────────┘                                               │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Static Config（静态配置）

### 位置

```
src/
└── config/
    ├── defaults.yaml       # 默认值
    ├── habits.yaml         # 默认 Habits
    ├── prompts.yaml        # AI Prompts
    └── errors.yaml         # 错误消息
```

### defaults.yaml

```yaml
# 默认配置值
app:
  name: "Notate"
  version: "1.0.0"

capture:
  max_content_length: 50000
  max_file_size:
    image: 10485760      # 10 MB
    document: 52428800   # 50 MB

evolution:
  similarity_threshold:
    hint: 0.75           # 演化提示
    trace: 0.70          # Trace 聚类
  min_captures_for_trace: 3
  hint_cooldown_hours: 1

ai:
  timeout_ms:
    embedding: 10000
    tagging: 15000
    summary: 15000
  retry:
    embedding: 2
    tagging: 1
    summary: 1
```

### habits.yaml

```yaml
# 系统默认 Habits
system_habits:
  - id: "system-link-extract"
    name: "Auto Extract Link"
    description: "自动提取链接标题和摘要"
    trigger_type: "link"
    trigger_pattern: "*"
    action_prompt: |
      提取以下链接的标题和摘要：
      URL: {url}

      返回 JSON：
      { "title": "...", "summary": "..." }

  - id: "system-image-ocr"
    name: "Image OCR"
    description: "图片自动 OCR 识别文字"
    trigger_type: "file_type"
    trigger_pattern: "image/*"
    action_prompt: |
      识别图片中的文字内容。
      如果没有文字，返回 { "text": "" }

  - id: "system-pdf-index"
    name: "PDF Index"
    description: "PDF 自动索引内容"
    trigger_type: "file_type"
    trigger_pattern: "application/pdf"
    action_prompt: |
      提取 PDF 的关键内容：
      1. 标题
      2. 摘要（100 字以内）
      3. 关键词

      返回 JSON：
      { "title": "...", "summary": "...", "keywords": [...] }
```

### prompts.yaml

```yaml
# AI Prompt 模板
prompts:
  tagging:
    system: |
      你是一个标签生成助手。
      规则：
      1. 优先使用现有标签
      2. 只在确实需要时创建新标签
      3. 标签应该是名词或短语
      4. 返回 1-3 个标签
    user: |
      现有标签库：{existing_tags}

      内容：
      {content}

      返回 JSON：{ "tags": ["tag1", "tag2"] }

  summary:
    system: "你是一个摘要生成助手。生成简洁的内容摘要。"
    user: |
      为以下内容生成摘要（不超过 100 字）：

      {content}

  trace_title:
    system: "你是一个标题生成助手。"
    user: |
      以下是用户在不同时间记录的几条相关想法：

      {captures}

      请生成一个简短标题（不超过 10 字），概括核心主题。
      只返回标题文字。

  habit_parse:
    system: "你是一个规则解析助手。"
    user: |
      用户描述的规则：
      "{description}"

      解析为 JSON：
      {
        "triggerType": "link" | "file_type" | "manual",
        "triggerPattern": "匹配模式",
        "actions": ["动作列表"],
        "tags": ["标签列表"]
      }

  message_refine:
    system: |
      你是一个消息优化助手。
      根据上下文和用户意图，生成合适的回复。
    user: |
      上下文：
      {context}

      用户想表达：
      {message}

      风格：{style}

      生成优化后的消息。
```

---

## App Config（应用配置）

### 位置

```
~/Library/Application Support/Notate/
└── config.yaml
```

### 结构

```yaml
# 用户可修改的应用配置
settings:
  # 外观
  theme: "system"           # light | dark | system
  language: "zh-CN"

  # 快捷键
  shortcuts:
    global_capture: "⌘+Shift+Space"
    quick_search: "⌘+K"

  # 演化追踪
  evolution:
    hint_enabled: true
    hint_mode: "prompt"     # prompt | silent

  # AI
  ai:
    provider: "gemini"
    api_key_env: "GEMINI_API_KEY"   # 从环境变量读取
```

### 配置加载优先级

```
1. 用户 config.yaml（最高）
2. 环境变量
3. defaults.yaml（最低）
```

---

## Runtime State（运行时状态）

### 前端状态（Zustand）

```typescript
// 遵循 Data Driven，状态结构清晰
interface AppState {
  // 视图状态
  view: {
    current: 'timeline' | 'canvas' | 'traces' | 'types'
    search: string
    selectedTags: string[]
  }

  // 数据缓存
  data: {
    captures: Map<string, Capture>
    traces: Map<string, Trace>
    tags: Map<string, Tag>
  }

  // UI 状态
  ui: {
    detailPanelOpen: boolean
    selectedCaptureId: string | null
    loading: Record<string, boolean>
  }
}
```

### 后端状态

后端尽量 **无状态**，所有持久状态存储在：
- SQLite（结构化数据）
- LanceDB（向量数据）
- 文件系统（文件）

---

## 开发流程

### 1. 定义数据结构

```yaml
# 先在 YAML 中定义
new_feature:
  enabled: true
  config:
    option_a: "value"
    option_b: 100
```

### 2. 实现数据加载

```rust
// Rust 加载 YAML
let config: Config = serde_yaml::from_str(&yaml_content)?;
```

```typescript
// TypeScript 加载
const config = yaml.parse(yamlContent);
```

### 3. 基于数据实现逻辑

```rust
// 代码只是数据的解释器
if config.new_feature.enabled {
    process_with_config(&config.new_feature.config);
}
```

### 4. 测试不同配置

```yaml
# test_config.yaml - 测试场景
new_feature:
  enabled: false  # 测试禁用情况
```

---

## 最佳实践

### DO ✅

- 配置项有明确的默认值
- 配置项有类型定义和验证
- 敏感信息使用环境变量
- 配置变更记录日志

### DON'T ❌

- 在代码中硬编码配置值
- 将 API Key 写入配置文件
- 配置项过于细碎（适度抽象）
- 运行时频繁读取配置文件（应缓存）

---

## 配置验证

### Schema 定义

```yaml
# config.schema.yaml
type: object
properties:
  settings:
    type: object
    properties:
      theme:
        type: string
        enum: [light, dark, system]
      shortcuts:
        type: object
        properties:
          global_capture:
            type: string
            pattern: "^[⌘⇧⌃⌥]+\\+.*$"
```

### 启动时验证

```rust
fn validate_config(config: &Config) -> Result<(), ConfigError> {
    // 验证必填项
    // 验证格式
    // 验证范围
}
```

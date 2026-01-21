# Rust Style Skill

> Enforce Rust coding conventions and Data Driven development for Notate backend.

## When to Use

Use this skill when:
- Writing new Rust code in `apps/desktop/src-tauri/src/`
- Reviewing backend code for style compliance
- Designing new features or configurations

## Core Principle: Data Driven

> **数据即真相**：所有状态都由数据文件定义，代码只是数据的解释器。

### Why Data Driven?

1. **可预测性** - 状态变化可追踪，易于调试
2. **可配置性** - 修改 YAML 即可改变行为，无需改代码
3. **可测试性** - 用不同数据文件测试不同场景
4. **可扩展性** - 新增功能只需新增数据定义

---

## Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Variables/Functions | snake_case | `capture_count`, `create_capture()` |
| Types/Structs | PascalCase | `Capture`, `CaptureService` |
| Modules | snake_case | `capture_service.rs` |

---

## Directory Structure

```
apps/desktop/src-tauri/src/
├── commands/    # Tauri command handlers
├── services/    # Business logic
├── db/          # Database operations
├── ai/          # AI integration
└── config/      # YAML configurations
    ├── defaults.yaml   # 默认值
    ├── habits.yaml     # 默认 Habits
    ├── prompts.yaml    # AI Prompts
    └── errors.yaml     # 错误消息
```

---

## State Management

### 状态分层

| Layer | Description | Example |
|-------|-------------|---------|
| Static Config | 编译时确定，代码内置 | 默认 Habits、错误消息 |
| App Config | 运行时加载，用户可修改 | 快捷键、主题、AI 设置 |
| Runtime State | 运行时动态变化 | 当前视图、选中项 |

### 配置加载优先级

```
1. 用户 config.yaml（最高）
2. 环境变量
3. defaults.yaml（最低）
```

### 后端状态原则

后端尽量 **无状态**，所有持久状态存储在：
- SQLite（结构化数据）
- LanceDB（向量数据）
- 文件系统（文件）

---

## Development Flow

### 1. 先定义数据结构

```yaml
new_feature:
  enabled: true
  config:
    option_a: "value"
    option_b: 100
```

### 2. 实现数据加载

```rust
let config: Config = serde_yaml::from_str(&yaml_content)?;
```

### 3. 基于数据实现逻辑

```rust
// 代码只是数据的解释器
if config.new_feature.enabled {
    process_with_config(&config.new_feature.config);
}
```

---

## Error Handling

- Use `Result<T, E>` for fallible operations
- Never use `panic!` for expected errors
- Use `thiserror` for custom error types

```rust
pub async fn create_capture(input: CreateCaptureInput) -> Result<Capture, CaptureError> {
    // ...
}
```

---

## Database Conventions

- Tables: snake_case plural (`captures`, `capture_tags`)
- Columns: snake_case (`created_at`, `file_path`)
- Foreign keys: `{table}_id` (`capture_id`, `tag_id`)

---

## Best Practices

### DO

- 配置项有明确的默认值
- 配置项有类型定义和验证
- 敏感信息使用环境变量
- 配置变更记录日志

### DON'T

- 在代码中硬编码配置值
- 将 API Key 写入配置文件
- 配置项过于细碎
- 运行时频繁读取配置文件（应缓存）

---

## Key Rules

1. **No secrets in code** - Use environment variables for API keys
2. **Async errors as Result** - Never panic on expected failures
3. **All user data local** - Never upload without explicit consent
4. **Data first** - Define YAML before writing code

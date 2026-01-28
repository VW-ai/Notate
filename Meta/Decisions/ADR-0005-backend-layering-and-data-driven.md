# ADR-0005: Backend Layering & Data-Driven Foundation

- **Status**: Proposed
- **Date**: 2026-01-28
- **Deciders**: Wayne, Team

## Context

- 当前 `services/capture_service.rs` 同时承担校验与直接执行 SQL，业务逻辑与数据访问耦合，测试难度大。
- 迁移执行依赖手写 `include_str!` 的单一脚本，未来多版本管理与幂等性风险高。
- 错误返回为字符串，缺少统一的 `ErrorCode`/结构化响应，前后端类型难对齐。
- Data-driven 约定（defaults/prompts/habits/errors YAML）尚未形成统一加载与注入路径，系统默认 Habits/Prompts 也未落地。
- 存储目录（files/cache/vectors）和文件/向量存储初始化缺席，后续接入文件/Embedding 时会频繁改接口。

## Decision

采纳分层与数据驱动的后端基线：

1. **分层架构**
   - `db/repositories/*`: 仅负责 SQL/持久化；不含业务规则。
   - `services/*`: 业务逻辑与校验，依赖 repo + 配置 +存储；不直接写 SQL。
   - `ipc/commands/*`: 仅做参数解析、调用 service、返回 DTO/结构化错误。
2. **迁移体系**
   - 使用 `sqlx::migrate!()` 加载 `migrations/*.sql` 版本化迁移；弃用手写 include_str。
3. **错误与校验**
   - 引入 `AppError` + `ErrorCode`（SCREAMING_SNAKE_CASE），命令层统一返回结构化错误。
   - 在 service 层做输入校验（长度、类型、URL、文件大小等）。
4. **数据驱动加载**
   - `config/` 目录包含 `defaults.yaml`, `prompts.yaml`, `habits.yaml`, `errors.yaml`。
   - 启动时统一加载为 `AppConfig`，缺文件使用安全默认；系统默认 Habits/Prompts 幂等写入 DB（后续里程碑可填充逻辑）。
5. **存储初始化**
   - 独立 `storage_service` 负责按配置创建 `files/images|documents`, `cache/thumbnails`, `vectors` 目录；路径记录日志，权限错误显式返回。

## Alternatives Considered

### Alternative 1: 保持现状（service 直接写 SQL，单迁移文件）

- **Pros**: 变更最小，立即可跑。
- **Cons**: 可测试性差，未来演化成本高，错误码/类型难对齐。
- **Why not**: 无法支撑后续向量、文件、Habits/Trace 等模块扩展。

### Alternative 2: 引入重型框架（如 Diesel + 领域驱动全栈）

- **Pros**: 强类型查询、完整 DDD 模板。
- **Cons**: 学习/改造成本高，当前规模过度设计。
- **Why not**: Hackathon/MVP 阶段不需要，sqlx + 轻量分层足够。

## Consequences

### Positive

- 可测试：service 可用 mock repo，repo 可用临时 SQLite，覆盖率更易达标。
- 可演进：替换存储/添加缓存时只改 repo；添加新业务只改 service。
- 一致性：前后端共享类型与错误码对齐，减少接口漂移。
- 稳定迁移：版本化迁移支持多阶段演化，幂等可验证。

### Negative

- 初期重构成本：需要新建 repo 层、调整命令返回、迁移脚本拆分。
- 代码体积小幅增加，团队需遵守分层约定。

### Risks

- 团队 Rust 经验有限，分层可能导致样板代码；缓解：提供样例 repo/service 模板。
- 迁移拆分若操作不慎可能破坏现有数据；缓解：先在开发环境验证，保留备份步骤。
- Data-driven 文件缺失可能阻断启动；缓解：loader 对缺文件使用默认空结构并记录警告。

## Related

- ADR-0001: Tauri for Desktop Framework
- ADR-0002: Evolution Detection Algorithm
- ADR-0003: Gemini as AI Provider
- ADR-0004: Cloud Embedding Strategy

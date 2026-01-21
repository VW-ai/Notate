# Milestones

> 项目里程碑追踪 - 按时间划分的开发阶段，每个阶段有明确的交付物。

## Milestone 生命周期

```
Draft → Active → Complete → Archived
```

- **Draft**: 规划阶段，范围未确定
- **Active**: 正在进行
- **Complete**: 所有交付物已验证
- **Archived**: 历史记录

## MVP 路线图

```
M1 ──→ M2 ──→ M3 ──→ M4 ──→ M5 ──→ M6
 │      │      │      │      │      │
 │      │      │      │      │      └─ Polish & MVP Release
 │      │      │      │      └─ Habits System
 │      │      │      └─ Evolution Tracking
 │      │      └─ Library Views
 │      └─ AI Integration
 └─ Core Infrastructure
```

## Index

| Milestone | 名称 | 核心内容 | Status |
|-----------|------|---------|--------|
| [M1](M1.md) | Core Infrastructure | 项目搭建、数据库、快捷键、Overlay | Draft |
| [M2](M2.md) | AI Integration | Gemini、Embedding、打标签、摘要 | Draft |
| [M3](M3.md) | Library Views | Timeline、Canvas、Traces、Types | Draft |
| [M4](M4.md) | Evolution Tracking | 演化检测、Trace 生成、详情 Panel | Draft |
| [M5](M5.md) | Habits System | 默认 Habits、自定义 Habits | Draft |
| [M6](M6.md) | Polish & MVP | Home、Message Refinement、发布 | Draft |

## 依赖关系

```
M1 (必需)
 ├──→ M2 (需要基础设施)
 │     ├──→ M3 (需要 Embedding 和标签)
 │     │     └──→ M4 (需要 Library 视图)
 │     └──→ M5 (需要 AI 能力)
 └─────────────────────→ M6 (需要全部完成)
```

## 规范

### 文件命名
- 文件: `M{N}.md` (M1.md, M2.md, ...)
- 标题: 简短，行动导向

### 任务状态
- `[ ]` - 未开始
- `[~]` - 进行中
- `[x]` - 已完成

### 时长建议
- 每个 Milestone 1-4 周
- 更长的工作应拆分为多个 Milestone

## 创建新 Milestone

1. 复制 `_TEMPLATE.md` 为 `M{N}.md`
2. 先填写 Goal 和 Scope
3. 拆解为具体 Tasks
4. 在 Test Plan 中定义验收标准
5. 更新本文件的 Index

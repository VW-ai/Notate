# ADR-0004: Cloud Embedding Strategy

- **Status**: Accepted
- **Date**: 2025-01-26
- **Deciders**: Wayne

## Context

Notate 需要 Embedding 能力来支撑：

- 语义搜索
- 演化检测（相似度计算）
- Trace 聚类
- Canvas 布局（语义位置计算）

需要决定 Embedding 在云端生成还是本地生成。

## Decision

选择 **云端 Embedding**，使用 Gemini text-embedding-004。

### 规格

- 模型：text-embedding-004
- 维度：768
- 存储：LanceDB（本地向量数据库）

### 流程

```
用户保存 Capture
      │
      ▼
  调用 Gemini API
  生成 Embedding
      │
      ▼
  存储到 LanceDB
  (本地向量库)
```

## Alternatives Considered

### Alternative 1: 本地 Embedding（如 ONNX Runtime + MiniLM）

- **Pros**: 离线可用，无 API 成本，隐私性好
- **Cons**:
  - 多语言质量差（尤其中文）
  - 增加包体积（~100MB+）
  - 需要处理不同平台兼容性
- **Why not**: 效果是第一优先级，Hackathon 阶段不考虑工程优化

### Alternative 2: 混合方案（本地优先，云端兜底）

- **Pros**: 平衡离线能力和质量
- **Cons**: 实现复杂，需要处理两套 Embedding 的兼容性
- **Why not**: 复杂度太高，Hackathon 阶段不需要

## Consequences

### Positive

- **效果最优**：Gemini Embedding 多语言质量好，中英文混合场景表现佳
- **实现简单**：无需处理本地模型加载、平台兼容性
- **包体积小**：不需要打包模型文件
- **充分利用 Gemini**：Hackathon 评审加分项

### Negative

- 需要网络连接
- 离线无法使用 Embedding 相关功能

### Risks

| 风险     | 缓解措施                                 |
| -------- | ---------------------------------------- |
| 离线场景 | Hackathon 阶段不处理，MVP 后考虑本地降级 |
| API 延迟 | Embedding 异步生成，不阻塞用户操作       |
| 成本     | Hackathon 阶段免费额度充足，不考虑       |

## Design Decisions

### 为什么不做工程优化

Hackathon 阶段的优先级：

```
效果 > 功能完整性 > 工程优化
```

以下优化明确**不做**：

- ❌ Embedding 缓存策略
- ❌ 批量 Embedding 请求
- ❌ 本地模型降级
- ❌ 请求限流/重试

MVP 后根据实际使用情况再考虑。

## Related

- [ADR-0003 - Gemini as AI Provider](ADR-0003-gemini-as-ai-provider.md)
- [Technical.md - 存储设计](../Core/Technical.md)

# ADR-0003: Gemini as AI Provider

- **Status**: Accepted
- **Date**: 2025-01-26
- **Deciders**: Wayne

## Context

Notate 需要 AI 能力支撑以下功能：

- Embedding 生成（语义搜索、演化检测）
- 结构化输出（自动打标签、Habit 规则解析）
- 文本生成（摘要、Trace 标题）
- 多模态理解（图片 OCR、PDF 解析、截屏 Context）

需要选择一个 AI Provider 来支撑这些能力。

## Decision

选择 **Google Gemini** 作为唯一 AI Provider。

### 使用的模型

| 能力       | 模型               | 用途                                 |
| ---------- | ------------------ | ------------------------------------ |
| Embedding  | text-embedding-004 | 语义搜索、演化检测、聚类             |
| 结构化输出 | gemini-2.0-flash   | 打标签、Habit 解析                   |
| 文本生成   | gemini-2.0-flash   | 摘要、Trace 标题、Message Refinement |
| 多模态     | gemini-2.0-flash   | 图片 OCR、PDF 理解、截屏分析         |

## Alternatives Considered

### Alternative 1: OpenAI

- **Pros**: 生态成熟，文档完善
- **Cons**: 多模态能力相对较弱，Embedding 模型多语言支持一般
- **Why not**: 多模态不是核心优势

### Alternative 2: Anthropic Claude

- **Pros**: 推理能力强，长文本处理好
- **Cons**: 无原生 Embedding API，多模态能力有限
- **Why not**: 缺少 Embedding，需要混用多个 provider

### Alternative 3: 多 Provider 混用

- **Pros**: 各取所长
- **Cons**: 集成复杂度高，调试困难
- **Why not**: Hackathon 阶段不需要这种复杂度

## Consequences

### Positive

- **多模态能力强**：Gemini 在图片理解、PDF 解析方面表现优秀
- **统一 Provider**：简化集成，减少调试成本
- **Hackathon 加分**：参加 Gemini Hackathon，深度使用 Gemini 能力是评审关注点
- **免费额度充足**：开发阶段成本可忽略

### Negative

- 单一供应商依赖（Hackathon 阶段可接受）
- 未来切换成本

### Risks

| 风险                   | 缓解措施                                   |
| ---------------------- | ------------------------------------------ |
| Gemini API 不稳定      | Hackathon 阶段可接受，MVP 后再考虑降级策略 |
| 功能受限于 Gemini 能力 | 当前功能设计已验证 Gemini 可支撑           |

## Future Improvements

- MVP 后考虑添加 Provider 抽象层
- 根据用户反馈评估是否需要支持其他 Provider

## Related

- [Technical.md - AI 服务能力](../Core/Technical.md)
- [ADR-0002 - Evolution Detection Algorithm](ADR-0002-evolution-detection-algorithm.md)
- [ADR-0004 - Cloud Embedding Strategy](ADR-0004-cloud-embedding-strategy.md)

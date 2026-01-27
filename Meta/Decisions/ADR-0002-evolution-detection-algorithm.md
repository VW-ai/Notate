# ADR-0002: Evolution Detection Algorithm

- **Status**: Accepted
- **Date**: 2025-01-26
- **Deciders**: Wayne

## Context

演化追踪（Evolution Tracking）是 Notate 的核心差异化功能。当用户保存新 capture 时，需要检测是否与历史内容存在"演化关系"——即同一话题但观点/结论发生了变化。

核心挑战：

1. 如何快速从大量历史 captures 中找到相关内容
2. 如何准确区分"重复"、"演化"、"补充"三种关系
3. 如何在速度和准确性之间取得平衡

## Decision

采用**两阶段检测方案**：Embedding 快速筛选 + Gemini 语义判断。

### Stage 1: Embedding 快速筛选

- 使用 Gemini text-embedding-004 生成向量
- 在 LanceDB 中进行向量相似度搜索
- 阈值：cosine similarity > 0.7
- 返回 Top 5 候选

### Stage 2: Gemini 语义判断

对每个候选，调用 Gemini 判断关系类型：

```yaml
input:
  new_capture: "用户新保存的内容"
  old_capture: "历史 capture 内容"

output:
  relation: "evolution" | "duplicate" | "supplement" | "unrelated"
  summary: "变化摘要（仅 evolution 时返回）"
  aspect: "变化的维度/话题"
```

### 流程

```
新 Capture → Embedding → 向量搜索 (Top 5, >0.7)
                              │
                              ▼ 有候选
                        Gemini 判断关系
                              │
                              ▼ relation == "evolution"
                        返回 EvolutionHint
                        { old_capture, summary, aspect }
```

## Alternatives Considered

### Alternative 1: 纯 Embedding 方案

- **Pros**: 简单、快速、成本低
- **Cons**: 无法区分重复/演化/补充，只能告诉用户"有相似内容"
- **Why not**: 用户体验差，"你的观点从 X 变成 Y" 比 "你记过类似的" 更有价值

### Alternative 2: 纯 Gemini 方案

- **Pros**: 最准确
- **Cons**: 每次保存都要与所有历史比较，成本高、速度慢
- **Why not**: 不可扩展，captures 多了之后不可行

### Alternative 3: 基于 Tag 的规则匹配

- **Pros**: 简单、可解释
- **Cons**: 依赖标签准确性，无法捕捉跨标签的演化
- **Why not**: 太粗糙，漏掉很多真正的演化

## Consequences

### Positive

- 速度可控：Stage 1 < 200ms, Stage 2 < 1s
- 准确性高：Gemini 能理解语义，区分演化类型
- 用户体验好：能告诉用户具体"变化了什么"
- 成本可控：每次最多 5 次 Gemini 调用

### Negative

- 依赖 Gemini API 可用性
- Stage 2 增加了延迟（但可接受）

### Risks

| 风险                 | 缓解措施                                         |
| -------------------- | ------------------------------------------------ |
| Gemini API 延迟/失败 | Stage 2 设置超时，失败时降级为仅显示"有相似内容" |
| 误判率               | MVP 后收集用户反馈，调整 prompt 和阈值           |
| 成本超预期           | 监控 API 调用量，必要时调整候选数量              |

## Future Improvements

- 动态阈值：根据用户历史数据自动调整相似度阈值
- 本地缓存：对常见判断结果进行缓存
- 用户反馈：允许用户标记"这不是演化"，用于优化模型
- Batch 处理：多个候选合并成一次 Gemini 调用

## Related

- [Product.md - 演化追踪](../Core/Product.md#32-演化追踪evolution-tracking)
- [M4 - Evolution Tracking](../Milestone/M4.md)

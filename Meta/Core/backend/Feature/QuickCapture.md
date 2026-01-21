# Quick Capture 后端设计

**版本:** 1.0  

---

## 数据流

```
用户输入
    ↓
验证 → 文件处理（如有）→ 保存 SQLite → 执行 Habit（如有）
    ↓
返回 Capture + EvolutionHint
    ↓ (异步)
计算 Embedding → AI 打标签 → 生成摘要 → 演化检测 → Trace 更新
    ↓
Event 通知前端
```

---

## 输入类型处理

| 类型 | 处理 |
|------|------|
| Thought | 直接存储 content |
| Link | 存储 URL 到 source_url，可选提取标题 |
| Image | 存文件 + OCR 提取文字 + 生成缩略图 |
| File (PDF) | 存文件 + 提取文字 + 生成预览 |

**文件限制**：
- 图片 < 10MB，格式：png/jpg/gif/webp
- PDF < 50MB

---

## AI 异步处理

**执行顺序**：
1. Embedding（最高优先，用于演化检测）
2. 演化检测（需要及时返回）
3. 打标签
4. 生成摘要

**超时和重试**：

| 操作 | 超时 | 重试 |
|------|------|------|
| Embedding | 10s | 2 次 |
| 打标签 | 15s | 1 次 |
| 摘要 | 15s | 1 次 |
| 演化检测 | 5s | 不重试 |

失败不阻塞，记录日志后继续。

---

## 演化检测

**时机**：Embedding 完成后立即执行

**流程**：
1. 在 LanceDB 搜索相似向量（top 5，阈值 0.75）
2. 排除自身，排除 1 小时内的
3. 取最相似的返回

**返回数据**：
- oldCapture: { id, content(截断100字), createdAt }
- similarity: 0-1
- daysAgo: 天数差

---

## 错误处理

| 场景 | 处理 |
|------|------|
| content 为空 | 返回 INVALID_INPUT |
| 文件太大 | 返回 FILE_TOO_LARGE |
| 不支持的类型 | 返回 UNSUPPORTED_FILE_TYPE |
| AI 失败 | Capture 仍保存，AI 字段为空 |

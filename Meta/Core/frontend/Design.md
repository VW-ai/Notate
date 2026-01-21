# Notate 设计语言

**版本:** 1.0  

---

## 设计原则

| 原则 | 体现 |
|------|------|
| 轻量 | Overlay 快速出现/消失，无多余动效 |
| 克制 | 信息密度适中，留白充足 |
| 一致 | 相同操作相同反馈 |
| 温暖 | 文案友好，空状态有引导 |

---

## 色彩

### 主色
- Primary: `#6366F1`（品牌色）
- Primary Light: `#EEF2FF`（浅背景）

### 中性色
- Text Primary: `#111827`
- Text Secondary: `#6B7280`
- Border: `#D1D5DB`
- Background: `#F9FAFB`

### 语义色
- Success: `#10B981`
- Warning: `#F59E0B`
- Error: `#EF4444`

### Capture 类型色
- Thought 💭: `#8B5CF6`（紫）
- Link 🔗: `#3B82F6`（蓝）
- File 📄: `#F59E0B`（橙）
- Image 📷: `#10B981`（绿）

---

## 字体

- 系统字体栈：`-apple-system, BlinkMacSystemFont, "Segoe UI", ...`
- 中文：`"Noto Sans SC"`

| 层级 | 大小 | 用途 |
|------|------|------|
| display | 24px | 页面标题 |
| title | 18px | 区块标题 |
| body | 14px | 正文 |
| caption | 12px | 辅助文字 |

---

## 间距

基础单位：4px

| 场景 | 间距 |
|------|------|
| 紧凑元素间 | 4px |
| 相关元素间 | 8px |
| 区块内边距 | 16px |
| 区块间距 | 24px |

---

## 圆角

| 场景 | 圆角 |
|------|------|
| 小元素（tag） | 4px |
| 中等元素（卡片） | 8px |
| 大元素（模态框） | 12px |

---

## 阴影

| 层级 | 用途 |
|------|------|
| shadow-sm | 卡片默认 |
| shadow-md | 卡片 hover、下拉 |
| shadow-lg | 模态框 |
| shadow-xl | Overlay |

---

## 动效

| 类型 | 时长 | 场景 |
|------|------|------|
| 快速 | 150ms | hover、focus |
| 正常 | 200ms | 展开、fade |
| 慢速 | 300ms | 页面切换 |

缓动：`cubic-bezier(0.4, 0, 0.2, 1)`

---

## 图标

使用 **Lucide Icons**

| 用途 | 图标 |
|------|------|
| 想法 | MessageCircle |
| 链接 | Link |
| 文件 | FileText |
| 搜索 | Search |
| 添加 | Plus |
| 关闭 | X |

---

## 常用文案

| 场景 | 文案 |
|------|------|
| 空输入 | What's on your mind? |
| 保存成功 | ✅ 已保存 |
| 演化提示 | 💡 你 X 天前也记过类似的 |
| 空状态 | 还没有内容 |
| 错误 | 出了点问题，请稍后重试 |

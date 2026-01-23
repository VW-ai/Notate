# Notate 设计语言

**版本:** 2.0

---

## 设计北极星

**Notate = 轻量个人知识 Layer**

> 80% 时间：Overlay（快捷键唤起，3 秒内完成一次 capture/refine/search）
>
> 20% 时间：App（Library/Habits 维护、回顾、检索）

**体验目标**

- 任何一次操作都能用键盘完成（鼠标只作为可选）
- 用户"记录/整理"不被打断：出现快、走得快、反馈明确

---

## 核心原则（不可破）

| 原则                       | 说明                                       |
| -------------------------- | ------------------------------------------ |
| **One Surface**            | 一次只显示一个浮层（Overlay），不叠弹窗    |
| **Text-first**             | 信息只靠文本表达；视觉元素极少             |
| **Kaomoji = 状态系统**     | 是"状态灯"，不是装饰                       |
| **Progressive disclosure** | 只呈现当下要做的下一步                     |
| **1% Rainbow Rule**        | 彩虹只用于"交互反馈/进度/奖励"，不承载信息 |

---

## 视觉系统（Tokens）

### 色彩（Gray-first + Accent + Controlled Rainbow）

#### 基础色板

| 用途     | 颜色值                     | Tailwind             |
| -------- | -------------------------- | -------------------- |
| 主背景   | `rgba(255, 255, 255, 0.9)` | `bg-primary`         |
| 次背景   | `#f5f5f5`                  | `bg-secondary`       |
| 正文黑   | `#1a1a1a`                  | `text-primary`       |
| 副文本   | `#666666`                  | `text-secondary`     |
| 弱化文本 | `#999999`                  | `text-muted`         |
| 边框     | `#D1D5DB`                  | `border-gray-200/60` |

#### 语义色

| 用途   | 颜色值    | 说明             |
| ------ | --------- | ---------------- |
| 强调蓝 | `#3b82f6` | 关键选中态、链接 |
| 成功绿 | `#22c55e` | 成功状态         |
| 警告橙 | `#F59E0B` | 警告状态         |
| 错误红 | `#EF4444` | 错误状态         |

#### 内容类型色

| 类型        | 颜色         | 用途        |
| ----------- | ------------ | ----------- |
| AI          | `#22c55e` 绿 | AI 相关内容 |
| Research    | `#3b82f6` 蓝 | 研究内容    |
| Startup     | `#a855f7` 紫 | 创业相关    |
| Product     | `#f59e0b` 橙 | 产品相关    |
| Design      | `#ec4899` 粉 | 设计相关    |
| Engineering | `#14b8a6` 青 | 工程技术    |

#### Rainbow（仅 3 种形态）

彩虹渐变用于特殊强调元素：

```css
linear-gradient(90deg, #ff6b6b, #feca57, #48dbfb, #ff9ff3, #54a0ff, #5f27cd)
```

| 形态            | 用途                              |
| --------------- | --------------------------------- |
| `Rainbow Ring`  | 1–2px 聚焦描边（输入框 focus）    |
| `Rainbow Bar`   | 2px 进度条（生成中状态）          |
| `Rainbow Sweep` | 成功瞬间 150–250ms 扫光（仅一次） |

> **禁止**：彩虹大面积填充、彩虹正文渐变、同屏多处彩虹

---

### 字体系统

#### 字体家族

```css
font-family:
  -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue",
  sans-serif;
```

#### 层级规范

| 层级    | 字号 | 字重 | 用途         |
| ------- | ---- | ---- | ------------ |
| H1      | 32px | 600  | 主页问候语   |
| H2      | 20px | 600  | 页面标题     |
| H3      | 14px | 500  | 卡片标题     |
| Body    | 14px | 400  | 正文内容     |
| Caption | 12px | 400  | 时间戳、标签 |

**HUD 内最多 3 层**：

- **Title**：短（可选）
- **Body**：主指令（必有）
- **Helper**：一句解释（可选）

> 文案长度：**每个 HUD 屏最多 2 句**

---

### 间距系统

基础单位：**4px**

| 场景       | 值      | Tailwind          |
| ---------- | ------- | ----------------- |
| 容器内边距 | 16-32px | `p-4` ~ `p-8`     |
| 卡片内边距 | 12-20px | `p-3` ~ `p-5`     |
| 元素间距   | 8-24px  | `gap-2` ~ `gap-6` |
| 标题下方   | 12-24px | `mb-3` ~ `mb-6`   |

#### 布局尺寸

- 侧边栏宽度: `208px` (`w-52`)
- 交通灯预留: `52px`
- 卡片宽度: `180px` (Canvas)
- 右侧面板: `320px` (`w-80`)

---

### 形状与质感

| 属性     | 值                   | 说明            |
| -------- | -------------------- | --------------- |
| 大圆角   | `rounded-2xl` (16px) | 模态框、Overlay |
| 中圆角   | `rounded-xl` (12px)  | 卡片            |
| 小圆角   | `rounded-lg` (8px)   | 按钮、标签      |
| 主阴影   | `shadow-lg`          | 卡片 hover      |
| 毛玻璃   | `backdrop-blur-xl`   | 浮层背景        |
| 边框色   | `border-gray-200/60` | 统一边框        |
| 透明背景 | `bg-white/80`        | 毛玻璃效果      |

> 阴影：极轻（"浮起"即可）；分割线：能不用就不用，需要分组时才用极淡线

---

## Kaomoji 状态系统

**只允许以下 8 个表情：**

| 状态              | Kaomoji         | 用途             |
| ----------------- | --------------- | ---------------- |
| Ready             | `( ・_・)`      | 等待输入         |
| Capture/Input     | `(｀・ω・´)`    | 捕获模式         |
| Working           | `(－_－)・・・` | 处理中           |
| Success           | `(＾▽＾)✓`      | 成功完成         |
| Error             | `(；＿；)`      | 出错             |
| Warning           | `(￣□￣;)`      | 警告             |
| Permission/Locked | `(¬_¬)`         | 权限请求         |
| Quiet/Background  | `(・_・; )`     | 后台静默（可选） |

**使用规则**

- 永远在 HUD 左侧（作为"状态灯"）
- 一屏只出现一个
- 视觉权重低于正文（更淡/更小一点）

---

## 动画系统

### 关键帧动画

| 动画名          | 时长  | 用途               |
| --------------- | ----- | ------------------ |
| `rainbow-sweep` | 250ms | 彩虹条扫过（成功） |
| `fade-in`       | 150ms | 元素淡入           |
| `scale-in`      | 150ms | 缩放进入           |

### Framer Motion 标准

**进场动画**:

```tsx
initial={{ opacity: 0, y: -10 }}
animate={{ opacity: 1, y: 0 }}
transition={{ duration: 0.15, ease: 'easeOut' }}
```

**瀑布效果**:

```tsx
transition={{ delay: index * 0.03, duration: 0.4 }}
```

### 交互过渡

| 类型 | 时长  | 场景         |
| ---- | ----- | ------------ |
| 快速 | 150ms | hover、focus |
| 正常 | 200ms | 展开、fade   |
| 慢速 | 300ms | 页面切换     |

- 标准过渡: `transition-all duration-200`
- 缓动: `cubic-bezier(0.4, 0, 0.2, 1)`
- Hover 效果: 边框变亮 + 阴影增加 + Y轴上移
- 选中态: `ring-2 ring-gray-900`

---

## 文案风格（Microcopy）

**短、冷静、给下一步**

- 少用感叹号
- 一屏最多两句
- 多用动词开头：Paste / Choose / Type / Press Enter

### 通用句库

| 场景     | 文案                        |
| -------- | --------------------------- |
| 空输入   | What's on your mind?        |
| 粘贴提示 | Paste and press Enter       |
| 选择询问 | What is this?               |
| 保存成功 | Saved ✓                     |
| 处理中   | Working…                    |
| 可粘贴   | Ready to paste (⌘V)         |
| 错误     | Couldn't finish. Try again. |
| 演化提示 | 💡 你 X 天前也记过类似的    |
| 空状态   | 还没有内容                  |

---

## 特殊元素

### Canvas 背景点阵

```css
background: radial-gradient(circle, #d1d5db 1px, transparent 1px);
background-size: 24px 24px;
opacity: 0.5;
```

### Cluster 大标题

```css
font-size: 64px;
font-weight: 800;
letter-spacing: -0.02em;
color: rgba(cluster-color, 0.2);
```

---

## 图标

使用 **Lucide Icons**

| 用途 | 图标          |
| ---- | ------------- |
| 想法 | MessageCircle |
| 链接 | Link          |
| 文件 | FileText      |
| 搜索 | Search        |
| 添加 | Plus          |
| 关闭 | X             |

---

## 技术栈

- **Tailwind CSS 3.4** - 原子化 CSS 框架
- **Framer Motion 11** - React 动画库
- **Lucide React** - 图标系统
- **Recharts** - 数据可视化

---

## 设计价值观

1. **内容为王** - 界面服务于内容，不喧宾夺主
2. **效率优先** - 最少操作完成任务
3. **现代美感** - 毛玻璃 + 极简风格
4. **一致性** - 统一的颜色、间距、动画规范
5. **优雅反馈** - 清晰的视觉交互提示

---

## 设计一致性检查清单

- [ ] Overlay 是否始终只有一个面板？
- [ ] 是否所有关键流程都能只用键盘完成？
- [ ] Kaomoji 是否只来自固定表情库？
- [ ] 同一屏彩虹是否只出现一次？是否符合 Ring/Bar/Sweep 三形态？
- [ ] 每个 HUD 屏是否最多两句文案？
- [ ] Habits 是否始终在表达"整理规则"而不是"任务自动化"？

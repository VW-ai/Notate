# Notate 组件库

**版本:** 1.0  

---

## 组件分类

```
components/
├── ui/          # 基础组件（无业务逻辑）
└── shared/      # 业务通用组件
```

---

## 基础组件 (ui/)

### Button
| Prop | 类型 | 说明 |
|------|------|------|
| variant | 'primary' \| 'secondary' \| 'ghost' \| 'danger' | 样式 |
| size | 'sm' \| 'md' \| 'lg' | 尺寸 |
| loading | boolean | 加载状态 |
| disabled | boolean | 禁用 |

### Input
| Prop | 类型 | 说明 |
|------|------|------|
| value | string | 值 |
| placeholder | string | 占位 |
| error | boolean \| string | 错误状态 |
| onEnter | () => void | 回车 |

### Modal
| Prop | 类型 | 说明 |
|------|------|------|
| open | boolean | 是否显示 |
| onClose | () => void | 关闭 |
| title | string | 标题 |
| size | 'sm' \| 'md' \| 'lg' | 尺寸 |

### Tag
| Prop | 类型 | 说明 |
|------|------|------|
| color | string | 颜色 |
| removable | boolean | 可删除 |
| onRemove | () => void | 删除回调 |

### Toast（全局调用）
- `toast.success(message)`
- `toast.error(message)`
- `toast.info(message)`

### Empty
| Prop | 类型 | 说明 |
|------|------|------|
| icon | ReactNode | 图标 |
| title | string | 主文案 |
| description | string | 副文案 |
| action | ReactNode | 操作按钮 |

---

## 业务组件 (shared/)

### CaptureCard
| Prop | 类型 | 说明 |
|------|------|------|
| capture | Capture | 数据 |
| variant | 'default' \| 'compact' \| 'expanded' | 显示模式 |
| showTags | boolean | 显示标签 |
| onClick | () => void | 点击 |

**变体说明**：
- default: Timeline 用，完整信息
- compact: Canvas/Traces 用，仅图标+日期+预览
- expanded: Traces 展开，完整内容

### CaptureTypeIcon
| Prop | 类型 | 说明 |
|------|------|------|
| type | CaptureType | 类型 |
| size | 'sm' \| 'md' \| 'lg' | 尺寸 |

### TraceTimeline
| Prop | 类型 | 说明 |
|------|------|------|
| captures | Capture[] | 按时间排序 |
| currentId | string | 当前高亮 |
| variant | 'full' \| 'mini' | 完整/简化 |

### HabitCard
| Prop | 类型 | 说明 |
|------|------|------|
| habit | Habit | 数据 |
| selected | boolean | 选中状态 |
| onToggle | (active) => void | 开关 |

### EvolutionHint
| Prop | 类型 | 说明 |
|------|------|------|
| hint | EvolutionHint | 提示数据 |
| expanded | boolean | 展开状态 |
| onExpand | () => void | 展开 |
| onViewDetail | () => void | 查看详情 |

### SearchInput
| Prop | 类型 | 说明 |
|------|------|------|
| value | string | 值 |
| onChange | (value) => void | 变化 |
| onSearch | (value) => void | 搜索 |
| loading | boolean | 搜索中 |

### ViewSwitcher
| Prop | 类型 | 说明 |
|------|------|------|
| views | { key, label }[] | 视图列表 |
| current | string | 当前视图 |
| onChange | (view) => void | 切换 |

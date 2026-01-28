# Notate 代码规范

**版本:** 1.0

---

## 目录结构

```
notate/
├── apps/desktop/
│   ├── src/                    # 前端
│   │   ├── components/ui/      # 基础组件
│   │   ├── components/shared/  # 业务组件
│   │   ├── pages/
│   │   ├── stores/
│   │   ├── hooks/
│   │   └── services/           # 调用 Tauri
│   └── src-tauri/src/          # Rust 后端
│       ├── commands/
│       ├── services/
│       ├── db/
│       └── ai/
├── packages/shared/            # 共享类型
└── docs/
```

---

## 命名规范

### TypeScript

| 类型      | 规范        | 示例                              |
| --------- | ----------- | --------------------------------- |
| 变量/函数 | camelCase   | `captureCount`, `createCapture()` |
| 常量      | UPPER_SNAKE | `MAX_FILE_SIZE`                   |
| 类型/接口 | PascalCase  | `Capture`, `CreateCaptureInput`   |
| 组件      | PascalCase  | `CaptureCard.tsx`                 |
| Hook      | use 前缀    | `useCapture()`                    |

### Rust

| 类型        | 规范       | 示例                                |
| ----------- | ---------- | ----------------------------------- |
| 变量/函数   | snake_case | `capture_count`, `create_capture()` |
| 类型/结构体 | PascalCase | `Capture`, `CaptureService`         |

### 数据库

- 表名：snake_case 复数（`captures`, `capture_tags`）
- 列名：snake_case（`created_at`, `file_path`）

---

## Git 规范

### 分支命名

- `feature/功能名`
- `fix/问题描述`
- `refactor/模块名`

### Commit 消息

格式：`type(scope): description`

| type     | 用途      |
| -------- | --------- |
| feat     | 新功能    |
| fix      | 修复      |
| refactor | 重构      |
| docs     | 文档      |
| chore    | 构建/工具 |

示例：`feat(overlay): add quick capture input`

---

## 工具配置

| 工具                | 用途              |
| ------------------- | ----------------- |
| ESLint + Prettier   | TS 检查和格式化   |
| Clippy + rustfmt    | Rust 检查和格式化 |
| husky + lint-staged | 提交前检查        |

---

## 关键约定

- 所有异步错误用 Result 返回，不用 panic
- 用户数据全部本地存储，不上传
- API key 不提交代码库，用环境变量
- 组件 props 必须有 TypeScript 类型定义
- Embedding 调用统一使用 Google Gemini（云端生成向量，后续在设置页暴露开关/说明）

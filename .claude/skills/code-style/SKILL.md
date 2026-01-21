# Code Style Skill

> Enforce TypeScript and Rust coding conventions for Notate.

## When to Use

Use this skill when:
- Writing new code in TypeScript or Rust
- Reviewing code for style compliance
- Refactoring existing code

## TypeScript Conventions

### Naming
| Type | Convention | Example |
|------|------------|---------|
| Variables/Functions | camelCase | `captureCount`, `createCapture()` |
| Constants | UPPER_SNAKE | `MAX_FILE_SIZE` |
| Types/Interfaces | PascalCase | `Capture`, `CreateCaptureInput` |
| Components | PascalCase files | `CaptureCard.tsx` |
| Hooks | `use` prefix | `useCapture()` |

### Files
- Components: `ComponentName.tsx`
- Hooks: `useHookName.ts`
- Services: `serviceName.ts`
- Types: `types.ts` or `modelName.types.ts`

### Props
- Always define TypeScript types for component props
- Use interface for props, type for unions/aliases

```typescript
interface CaptureCardProps {
  capture: Capture;
  onClick?: () => void;
}
```

## Rust Conventions

### Naming
| Type | Convention | Example |
|------|------------|---------|
| Variables/Functions | snake_case | `capture_count`, `create_capture()` |
| Types/Structs | PascalCase | `Capture`, `CaptureService` |
| Modules | snake_case | `capture_service.rs` |

### Error Handling
- Use `Result<T, E>` for fallible operations
- Never use `panic!` for expected errors
- Use `thiserror` for custom error types

```rust
pub async fn create_capture(input: CreateCaptureInput) -> Result<Capture, CaptureError> {
    // ...
}
```

## Database Conventions

- Tables: snake_case plural (`captures`, `capture_tags`)
- Columns: snake_case (`created_at`, `file_path`)
- Foreign keys: `{table}_id` (`capture_id`, `tag_id`)

## Directory Structure

```
apps/desktop/
├── src/                    # Frontend
│   ├── components/ui/      # Basic components (no business logic)
│   ├── components/shared/  # Business components
│   ├── pages/
│   ├── stores/
│   ├── hooks/
│   └── services/           # Tauri IPC calls
└── src-tauri/src/          # Rust backend
    ├── commands/
    ├── services/
    ├── db/
    └── ai/
```

## Key Rules

1. **No secrets in code** - Use environment variables for API keys
2. **All user data local** - Never upload without explicit consent
3. **Async errors as Result** - Never panic on expected failures
4. **Types for all props** - No implicit any in TypeScript

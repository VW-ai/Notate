# TypeScript Style Skill

> Enforce TypeScript/React coding conventions for Notate frontend.

## When to Use

Use this skill when:
- Writing new TypeScript/React code in `apps/desktop/src/`
- Reviewing frontend code for style compliance
- Refactoring existing frontend code

## Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Variables/Functions | camelCase | `captureCount`, `createCapture()` |
| Constants | UPPER_SNAKE | `MAX_FILE_SIZE` |
| Types/Interfaces | PascalCase | `Capture`, `CreateCaptureInput` |
| Components | PascalCase files | `CaptureCard.tsx` |
| Hooks | `use` prefix | `useCapture()` |

## File Naming

- Components: `ComponentName.tsx`
- Hooks: `useHookName.ts`
- Services: `serviceName.ts`
- Types: `types.ts` or `modelName.types.ts`

## Props & Types

- Always define TypeScript types for component props
- Use `interface` for props, `type` for unions/aliases

```typescript
interface CaptureCardProps {
  capture: Capture;
  onClick?: () => void;
}
```

## Directory Structure

```
apps/desktop/src/
├── components/ui/      # Basic components (no business logic)
├── components/shared/  # Business components
├── pages/
├── stores/
├── hooks/
└── services/           # Tauri IPC calls
```

## Key Rules

1. **No secrets in code** - Use environment variables for API keys
2. **Types for all props** - No implicit `any`
3. **All user data local** - Never upload without explicit consent

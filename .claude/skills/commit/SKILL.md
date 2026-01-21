# Commit Skill

> Generate conventional commit messages for Notate.

## When to Use

Use this skill when:
- Creating a new commit
- Reviewing commit message format
- Preparing a PR

## Commit Message Format

```
type(scope): description

[optional body]

[optional footer]
```

## Types

| Type | Usage |
|------|-------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `style` | Formatting, no code change |
| `refactor` | Code change, no feature/fix |
| `test` | Adding/fixing tests |
| `chore` | Maintenance, deps, configs |
| `perf` | Performance improvement |

## Scopes

Common scopes for Notate:
- `overlay` - Overlay/Quick Capture feature
- `library` - Library views
- `capture` - Capture CRUD operations
- `habits` - Habits feature
- `evolution` - Evolution tracking
- `ai` - AI service integration
- `db` - Database operations
- `ui` - UI components

## Examples

```
feat(overlay): add quick capture input

fix(capture): resolve duplicate tag creation

docs(readme): update installation instructions

refactor(library): extract timeline view component

chore(deps): upgrade to React 18.3

test(capture): add unit tests for validation
```

## Breaking Changes

For breaking changes, add `!` after type/scope:

```
feat(api)!: change capture response format

BREAKING CHANGE: capture.content is now capture.text
```

## Rules

1. **Subject line max 72 characters**
2. **Use imperative mood** ("add" not "added" or "adds")
3. **Don't end subject with period**
4. **Capitalize first letter of description**
5. **Separate subject from body with blank line**

## Branch Naming

Related branch naming convention:
- `feat/{description}` - Feature branches
- `fix/{description}` - Bug fix branches
- `docs/{description}` - Documentation branches
- `refactor/{description}` - Refactoring branches

Examples:
- `feat/quick-capture-overlay`
- `fix/duplicate-tag-creation`
- `docs/api-documentation`

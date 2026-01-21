# Commit Skill

> Generate conventional commit messages for Notate with automatic progress tracking.

## When to Use

Use this skill when:
- Creating a new commit
- Reviewing commit message format
- Preparing a PR

## Workflow

When `/commit` is invoked, follow these steps:

### Step 1: Analyze Changes

```bash
git status
git diff --stat
git diff
```

Assess the scope and nature of all changes.

### Step 2: Decide on Commit Strategy

**If changes are cohesive** (single feature/fix/topic):
- Proceed with a single commit

**If changes span multiple concerns** (e.g., feature + refactor + docs):
- Split into logical atomic commits
- Each commit should be independently buildable
- Group by: feature, component, or concern
- Stage files selectively: `git add <specific-files>`

### Step 3: Update Progress.md

Before committing, update `Meta/Progress.md`:

1. Check if today's date section exists
2. If not, create new section at top (after the `---` separator)
3. Add completed items based on what's being committed
4. Use the template format in Progress.md

Example addition:
```markdown
## 2025-01-21

### Completed
- Added quick capture overlay component
- Implemented global hotkey registration

### Next
- Connect overlay to backend IPC
```

### Step 4: Create Commit(s)

1. Stage Progress.md along with related changes
2. Write commit message following format below
3. Execute commit

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

## Splitting Large Changes

When changes are too large or span multiple concerns, split them:

### Signs You Should Split

- Changes touch 3+ unrelated areas
- Mix of feature code + refactoring
- Multiple independent fixes
- Docs changes unrelated to code changes

### How to Split

```bash
# Stage specific files for first commit
git add src/components/Overlay.tsx src/hooks/useOverlay.ts
git commit -m "feat(overlay): add overlay component"

# Stage next set of files
git add src/services/capture.ts
git commit -m "feat(capture): add capture service"

# Stage docs/meta last
git add Meta/Progress.md
git commit -m "docs(progress): update progress log"
```

### Split Strategy Priority

1. **Infrastructure/config** first (if any)
2. **Backend changes** second
3. **Frontend changes** third
4. **Tests** with their related code
5. **Documentation/meta** last

### Atomic Commit Principle

Each commit should:
- Build successfully on its own
- Have a clear, single purpose
- Be revertable without breaking other changes

# Notate

> A lightweight personal knowledge layer that captures thoughts via hotkey, auto-organizes with AI, and helps you see how your ideas evolve.

## Overview

Notate is a **desktop application** for B2C individual users who want to:
- Capture ideas instantly via global hotkey (< 3 seconds from thought to record)
- Have AI automatically organize, tag, and summarize their captures
- See their knowledge distributed across topics (Canvas view)
- Track how their thinking evolves over time (Evolution Tracking)

The core value proposition: **"Your thoughts finally have a place to go, and they can be reused."**

### Key Differentiator

Unlike task-completion tools that treat context as a means to an end, Notate treats **context as the goal itself**. We help users organize and reuse their information, not execute tasks for them.

## Quick Start

```bash
# Clone the repository
git clone <repo-url>
cd notate

# Install dependencies
npm install

# Run development server
npm run tauri dev

# Run tests
npm test                    # Frontend tests
cargo test                  # Backend tests (in apps/desktop/src-tauri)
```

## Documentation

All project documentation lives in the `Meta/` folder:

| Folder | Purpose |
|--------|---------|
| [Meta/Core/](Meta/Core/Meta.md) | Core documents (Product, Technical, Design, API) |
| [Meta/Decisions/](Meta/Decisions/Meta.md) | Architecture Decision Records |
| [Meta/Milestone/](Meta/Milestone/Meta.md) | Milestone planning and tracking |

Quick links:
- [Product Requirements](Meta/Core/Product.md) - Full product specification
- [Technical Architecture](Meta/Core/Technical.md) - Backend architecture
- [Code Standards](Meta/Core/Regulation.md) - Development conventions
- [Interface Design](Meta/Core/Interface.md) - Detailed UI specifications
- [Current Progress](Meta/Progress.md) - Development log
- [Change Log](CHANGELOG.md) - Release history

## Tech Stack

| Layer | Technology | Purpose |
|-------|------------|---------|
| Desktop Framework | Tauri 2.0 | Small bundle (~10MB), Rust performance |
| Frontend | React 18 + TypeScript | UI development |
| State Management | Zustand | Lightweight state |
| Backend | Rust | Native performance, system integration |
| Structured Storage | SQLite | Local data persistence |
| Vector Storage | LanceDB | Semantic search, embeddings |
| AI | Gemini API | Tagging, summarization, embeddings |

## Project Structure

```
notate/
├── CLAUDE.md                 # This file - project entry point
├── CHANGELOG.md              # Release history
├── Meta/                     # Project documentation
│   ├── Core/                 # Product, Technical, Design docs
│   ├── Decisions/            # ADRs
│   ├── Milestone/            # Milestone tracking
│   ├── Progress.md           # Development log
│   ├── Todo.md               # Deferred tasks
│   └── Labels.md             # Label conventions
├── apps/desktop/
│   ├── src/                  # React frontend
│   │   ├── components/ui/    # Basic components
│   │   ├── components/shared/# Business components
│   │   ├── pages/
│   │   ├── stores/
│   │   ├── hooks/
│   │   └── services/         # Tauri IPC calls
│   └── src-tauri/src/        # Rust backend
│       ├── commands/
│       ├── services/
│       ├── db/
│       └── ai/
├── packages/shared/          # Shared types
└── .github/workflows/        # CI/CD
```

## Development Workflow

### Branching Strategy
- `main` - Production-ready code
- `develop` - Integration branch
- `feat/*` - Feature branches
- `fix/*` - Bug fix branches

### Commit Messages
Follow [Conventional Commits](https://www.conventionalcommits.org/):
```
type(scope): description

[optional body]
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

Example: `feat(overlay): add quick capture input`

### Code Standards

**TypeScript:**
- Variables/functions: camelCase
- Types/interfaces: PascalCase
- Components: PascalCase files
- Hooks: `use` prefix

**Rust:**
- Variables/functions: snake_case
- Types/structs: PascalCase

See [Regulation.md](Meta/Core/Regulation.md) for full standards.

## Core Concepts

### Capture Types
- **Thought** - Quick text notes
- **Link** - URLs with auto-extraction
- **File** - Documents (PDF, images)

### Views
- **Timeline** - Chronological list of captures
- **Canvas** - Tag-based spatial layout
- **Traces** - Evolution tracking across time
- **Types** - Filter by content type

### AI Roles
1. **Organizer** - Auto-tagging, summarization, clustering
2. **Habit Executor** - Understand and execute user-defined rules
3. **Surface Agent** - Detect and surface related/contradicting captures

## Current Status

**Active Milestone:** [M1 - Core Infrastructure & Quick Capture](Meta/Milestone/M1.md)

See [Progress.md](Meta/Progress.md) for daily updates.

## Skills

Custom Claude skills in `.claude/skills/`:

| Skill | Purpose |
|-------|---------|
| typescript-style | Enforce TypeScript/React coding conventions for frontend |
| rust-style | Enforce Rust conventions and Data Driven development for backend |
| commit | Generate conventional commit messages |

## Contributing

### For New Contributors
1. Read [Product.md](Meta/Core/Product.md) to understand the product
2. Read [Regulation.md](Meta/Core/Regulation.md) for coding standards
3. Check [Meta/Milestone/](Meta/Milestone/Meta.md) for current priorities
4. Pick a task or open an issue

### Making Decisions
For architectural decisions:
1. Create an ADR in `Meta/Decisions/`
2. Discuss with team
3. Update status once decided

### Tracking Progress
- Update [Progress.md](Meta/Progress.md) daily during active development
- Move completed items in [Todo.md](Meta/Todo.md) to archive
- Update milestone status when deliverables complete

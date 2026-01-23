# Progress Log

Append-only development log. Add new entries at the top.

---

## 2026-01-23

### Completed

- Consolidated design documentation from root-level files into Meta/Core/frontend/
- Updated Design.md (v2.0): merged design principles, Kaomoji system, visual tokens, Rainbow rules, animation system
- Updated Interface.md: added Overlay interaction patterns (3-template system), keyboard specs, Ask Mode, Compose Mode
- Updated Components.md (v2.0): added component style code (glass card, buttons, inputs, pills, message bubbles)
- Removed redundant DESIGN-LANGUAGE.md and DESIGN-SYSTEM.md from project root

### Next

- Implement Quick Capture overlay UI
- Add global hotkey (⌘+Shift+Space)

---

## 2026-01-21

### Completed

- Restructured core documentation (removed outdated specs)
- Added detailed IPC, backend, frontend technical specs
- Created M2-M6 milestone roadmap
- Added TypeScript and Rust style skills
- Enhanced commit skill with progress tracking and split commit support
- Added GitHub PR template and commit template

**M1 Project Initialization:**

- Created monorepo structure with npm workspaces
- Set up `packages/shared` with TypeScript types (Capture, Tag, Trace, Habit, API)
- Created `apps/desktop` frontend scaffold (React 18 + Vite + Zustand)
- Created `apps/desktop/src-tauri` Rust backend structure
- Implemented SQLite database schema with migrations (captures, tags, traces, habits, settings)
- Created YAML-based config system (`defaults.yaml`)
- Implemented IPC commands (create/get/update/delete capture)
- Set up Zustand stores (useCaptureStore, useAppStore)
- Configured dev tools (ESLint, Prettier, Vitest)
- **Successfully launched Tauri dev server** - app window opens with React frontend

### Blockers / Issues

- None

### Next

- Implement Quick Capture overlay UI
- Add global hotkey (⌘+Shift+Space)
- Test capture persistence flow

---

## 2025-01-20

### Completed

- Initialized project structure with Meta folder hierarchy
- Created CLAUDE.md project entry point
- Set up ADR system and milestone tracking
- Organized core documents (Product, Technical, Design, etc.)

### Decisions Made

- [ADR-0001](Decisions/ADR-0001-tauri-desktop-framework.md): Use Tauri 2.0 for desktop framework

### Blockers / Issues

- None

### Next

- Begin M1: Core Infrastructure & Quick Capture implementation
- Set up development environment (Tauri + React + Rust)

---

<!-- Template for new entries:

## YYYY-MM-DD

### Completed
-

### Decisions Made
-

### Blockers / Issues
-

### Next
-

-->

# Progress Log

Append-only development log. Add new entries at the top.

---

## 2026-01-28

### Completed

**M1 Backend Phase 1: Migration System Refactoring**

- Migrated from manual SQL execution to `sqlx::migrate!()` macro
- Split `001_initial.sql` into 6 separate migration files:
  - `20260128_001_create_captures.sql`
  - `20260128_002_create_tags.sql`
  - `20260128_003_create_capture_tags.sql`
  - `20260128_004_create_traces.sql`
  - `20260128_005_create_habits.sql`
  - `20260128_006_create_settings.sql`
- Added `migrate` feature to sqlx in Cargo.toml
- Updated `db/mod.rs`:
  - Added `MigrateError` to error enum
  - Exported `get_app_dir()` for storage service use
  - Added WAL mode verification logging
  - Enabled foreign keys
  - Added `test_utils` module with `setup_test_db()` for testing
- Deleted old `src/db/migrations/` directory
- Added TODO comment for future async tasks table in migration 006

**M1 Backend Phase 2: Directory Initialization**

- Created `services/storage_service.rs`:
  - `StoragePaths` struct with all path references
  - `init_directories()` function creates: files/images, files/documents, cache/thumbnails, vectors
  - Comprehensive logging of all initialized paths
  - `StorageError` enum for error handling
- Updated `lib.rs` to call storage init after DB init
- Added `tempfile` dev dependency for testing
- Added 3 unit tests: path creation, directory creation, idempotency

**M1 Backend Phase 3: ErrorCode System & Input Validation**

- Created `src/errors.rs`:
  - `ErrorCode` enum with SCREAMING_SNAKE_CASE serialization
  - `AppError` struct with code, message, and optional field
  - Builder methods: `content_too_long()`, `invalid_source_url()`, `link_requires_url()`
- Created `config/errors.yaml` with error message templates
- Updated `capture_service.rs`:
  - Added `validate_input()` function
  - Content length validation against `max_content_length`
  - URL format validation using `url` crate
  - Link type requires source_url validation
- Updated `commands/capture.rs` to pass config to service
- Added `url` crate dependency for URL parsing
- Added 6 validation unit tests (all passing)
- Total: 13 tests passing

**M1 Backend Phase 4: Tags Loading via JOIN**

- Updated `capture_service.rs`:
  - Added `parse_tags_from_concat()` helper function
  - Modified `get_by_id()` to JOIN with capture_tags and tags tables
  - Modified `list()` to JOIN with capture_tags and tags tables
  - Uses GROUP_CONCAT to aggregate tags: "id:name:color|id:name:color"
- Captures now return their associated tags array
- Added 4 unit tests for tags parsing
- Total: 17 tests passing

### In Progress

- Phase 5: Trace/Habit models
- Phase 6-8: Remaining backend improvements

### Next

- Implement ErrorCode enum and errors.yaml
- Add input validation to create_capture
- Implement tags JOIN loading

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

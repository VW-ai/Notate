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

**M1 Backend Phase 5: Trace/Habit Models & Placeholder APIs**

- Created `db/models/trace.rs`:
  - `Trace` struct with id, title, is_auto, captures, timestamps
  - `CaptureTrace` struct for capture-trace positioning
- Created `db/models/habit.rs`:
  - `TriggerType` enum (Link, FileType, Manual)
  - `Habit` struct matching shared TypeScript types
  - 2 unit tests for TriggerType
- Created `services/trace_service.rs` (stub returning empty vec)
- Created `services/habit_service.rs` (stub returning empty vec)
- Created `commands/trace.rs` with `get_traces` IPC command
- Created `commands/habit.rs` with `get_habits` IPC command
- Registered new commands in lib.rs
- Total: 19 tests passing

**M1 Backend Phase 6: Data Driven Config Files**

- Created `config/prompts.yaml`:
  - AI prompt templates for tagging, summary, evolution_hint
  - Each prompt has system message and limits (max_tags, max_length, etc.)
- Created `config/habits.yaml`:
  - Empty habits list as placeholder for M2
  - Includes example habit structure in comments
- Updated `config/mod.rs`:
  - Added `PromptsConfig` with `PromptTemplates` struct
  - Added `HabitsConfig` with `HabitDef` struct
  - Implemented `Default` traits for fallback
  - Added `load()` methods with graceful fallback on parse errors
- Total: 19 tests passing

**M1 Backend Phase 7: Observability Enhancement**

- Added tracing to `commands/config.rs` for get_config IPC
- Added error logging (tracing::warn) to all IPC command error paths:
  - create_capture, get_capture, get_captures, update_capture, delete_capture
  - get_traces, get_habits
- Comprehensive tracing coverage now includes:
  - App initialization (info level)
  - Database initialization and WAL mode (info level)
  - Migration execution (info level)
  - Storage directory initialization (info level)
  - Config loading (info level)
  - All IPC commands (debug level)
  - All error scenarios (warn level)
  - Service operations (debug level)
- Total: 19 tests passing

**M1 Backend Phase 8: Testing Infrastructure**

- Added config module tests:
  - test_load_defaults_success - verifies defaults.yaml loads correctly
  - test_prompts_config_default - tests PromptsConfig defaults
  - test_habits_config_default - tests HabitsConfig defaults
  - test_prompts_config_load - tests embedded YAML loading
  - test_habits_config_load - tests habits YAML loading
- Added capture model tests:
  - test_capture_type_as_str - CaptureType to string conversion
  - test_capture_type_from_str - string to CaptureType parsing
  - test_capture_type_serialization - JSON serialization
  - test_create_capture_input_serialization - input struct serialization
- Total: 28 tests passing (increased from 19)
- CI workflow configured with cargo test in GitHub Actions

### Summary - M1 Backend Phases 1-8 Complete

All 8 backend improvement phases completed:

1. Migration system with sqlx::migrate!()
2. Storage directory initialization
3. ErrorCode system with validation
4. Tags loading via JOIN
5. Trace/Habit models and placeholder APIs
6. Data-driven config files (prompts.yaml, habits.yaml)
7. Comprehensive tracing coverage
8. 28 unit tests covering all core functionality

### Next

- Phase 9: Hotkey & Overlay (frontend implementation)
- M2 planning

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

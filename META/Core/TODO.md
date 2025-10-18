# TODO - Notate Development

## High Priority

### UI Responsiveness & Layout (2025-10-18)
- [ ] **Different Proportion Handling**
  - Implement responsive layout for different screen sizes
  - Handle ultra-wide and narrow aspect ratios
  - Adjust panel widths dynamically based on available space
  - Support minimum/maximum window sizes
  - Optimize for MacBook vs external monitor layouts

### New Application Pages (2025-10-18)
- [ ] **Notes Page Development**
  - Design and implement dedicated notes section
  - Determine notes vs entries distinction
  - Notes organization and categorization
  - Search and filtering for notes
  - Rich text or markdown support

- [ ] **Settings Page Development**
  - Centralized settings interface
  - Trigger configuration UI
  - Theme and appearance settings
  - Keyboard shortcuts customization
  - Data export/import options
  - Privacy and security settings
  - Timer preferences (default tags, durations)

### Internationalization (2025-10-18)
- [ ] **Multi-language Input Handling**
  - IME (Input Method Editor) support for Chinese, Japanese, Korean
  - Proper character composition handling
  - Trigger detection with multi-byte characters
  - Text field compatibility with IME states
  - Font rendering optimization for CJK characters
  - Right-to-left language support consideration

### New User Input Features (2025-10-17)
- [ ] **Copy and Paste Support for Entries**
  - Implement clipboard functionality for entry content
  - Support both plain text and formatted content
  - Keyboard shortcuts (Cmd+C, Cmd+V)
  - Context menu integration

- [ ] **Feedback System (After User Typed)**
  - Real-time or post-typing feedback mechanism
  - Validation, suggestions, or AI feedback
  - Visual indicators for feedback state
  - Integration with entry creation flow

- [ ] **Tracker Integration**
  - Time tracking or activity tracking system integration
  - Determine which tracker system to integrate with
  - Automatic time logging for entries/events
  - Export/sync functionality

- [ ] **Ending Trigger Implementation**
  - Allow users to mark end of sentences with configurable trigger
  - Custom character or key combination to signal completion
  - Settings UI for trigger configuration
  - Integration with entry submission flow

- [ ] **Chinese Support + Symbol Support**
  - Internationalization for Chinese language
  - Proper rendering and input of Chinese characters
  - Support special symbols and characters
  - IME (Input Method Editor) compatibility
  - Font rendering optimization for Chinese text

### Tag Management Enhancements
- [ ] **Implement tag filtering on timeline**
  - Apply selected tags filter to entry/event display
  - Add visual indicator when filters are active
  - Clear filters button functionality

- [ ] **Tag search in panel**
  - Implement search field functionality
  - Filter tag list based on search input
  - Show "no results" state

- [ ] **Tag editing operations**
  - Right-click context menu on tags
  - Rename tag functionality
  - Delete tag with confirmation
  - Merge duplicate tags

### UI/UX Polish
- [ ] **Keyboard shortcuts**
  - Cmd+T to toggle tag panel
  - Cmd+N to create new tag
  - ESC to close tag input field

- [ ] **Drag feedback improvements**
  - Show ghost/preview while dragging
  - Visual feedback on drop success
  - Error state if drop fails

- [ ] **Tag panel responsive design**
  - Collapsible/expandable width
  - Remember panel state (open/closed)
  - Smooth resize animations

## Medium Priority

### Tag Analytics
- [ ] **Tag statistics view**
  - Most used tags chart
  - Tags over time graph
  - Tag co-occurrence analysis

- [ ] **Smart tag suggestions**
  - ML-based tag recommendations
  - Context-aware suggestions
  - Auto-tagging based on content

### Bulk Operations
- [ ] **Multi-select in tag panel**
  - Cmd+click to select multiple tags
  - Apply multiple tags at once
  - Bulk tag editing

- [ ] **Tag templates**
  - Save common tag combinations
  - Quick apply tag sets
  - Project-based tag groups

## Low Priority

### Advanced Features
- [ ] **Tag hierarchy**
  - Parent/child tag relationships
  - Nested tag display
  - Inherit parent tags option

- [ ] **Tag colors customization**
  - Manual color picker
  - Color themes/palettes
  - Import/export color schemes

- [ ] **Tag export/import**
  - Export tags with entries
  - Import tags from CSV
  - Sync tags across devices

### Performance Optimization
- [ ] **Lazy loading for large tag lists**
  - Virtualized scrolling
  - Pagination for 100+ tags
  - Performance profiling

## Bugs to Fix

### Current Issues
- None known - system is stable

### Edge Cases to Test
- [ ] Very long tag names (truncation)
- [ ] Special characters in tag names
- [ ] Tag names with emojis
- [ ] Dragging multiple items simultaneously
- [ ] Rapid tag creation/deletion

## Documentation Needed
- [ ] User guide for tag management
- [ ] Developer documentation for TagColorManager
- [ ] Drag-and-drop implementation notes
- [ ] Tag storage format specification

## Code Quality
- [ ] Add unit tests for TagColorManager
- [ ] Add UI tests for drag-and-drop
- [ ] Add tests for tag persistence
- [ ] Code documentation/comments review

---

## Completed This Session ✅

### 2025-10-18 - Timer System Implementation
- [x] Implement comprehensive timer workflow with ;;; trigger
- [x] Create unified popup window with 5 modes (name input, tags, running, conflict, completion)
- [x] Remove keyboard number selection from tag popup
- [x] Implement live tag filtering as user types
- [x] Add notification integration with text input support
- [x] Create singleton TimerPopupManager for popup coordination
- [x] Implement popup-notification mutual dismissal
- [x] Add NSPanel support for fullscreen app compatibility
- [x] Connect in-app timer stop to creation detail view
- [x] Add timeline auto-refresh after timer save
- [x] Unify button design across all popups
- [x] Add colored tag display to popup views
- [x] Implement smart window activation (no activation for name input)
- [x] Add trigger migration for ;;; in TriggerConfiguration

### 2025-10-17 - Sticky Cursor & UI Polish
- [x] Implement sticky cursor tag assignment system
- [x] Add global mouse tracking for tag drag state
- [x] Unify timeline card layouts (entry + event alignment)
- [x] Restructure detail view scrolling architecture
- [x] Add colored inset shadows to detail panels
- [x] Migrate color scheme from blue to red/orange/yellow
- [x] Enhance date picker visual design (yellow theme)
- [x] Fix 3-panel layout system (timeline/detail/tag)
- [x] Add fixed space reservation for tags
- [x] Scale up tag sizes by 3 levels
- [x] Fix time display wrapping in timeline cards
- [x] Move duration/AI actions to bottom right of cards

### 2025-01-16 - Tag Management System
- [x] Create tag management panel with drag-and-drop
- [x] Implement 72-color palette system
- [x] Add tag suggestions (top 8 most-used)
- [x] Enable drag-and-drop from entries/events to tags
- [x] Visual feedback on tag hover during drag
- [x] Easy tag creation with + button
- [x] Color persistence across sessions
- [x] Tag display with colors in detail views
- [x] Empty state UI for tag panel
- [x] Toggle button for panel visibility

## Notes

### Design Decisions
- Chose 280px width for tag panel (balance between visibility and screen space)
- Used #2C2C2E background to distinguish from timeline (#1C1C1E)
- Top 8 most-used tags shown (not top 10) for better mobile adaptation
- Tag format for events: `[tags: tag1, tag2]` in notes field

### Future Considerations
- Consider moving event tags to custom Calendar field if possible
- Evaluate need for tag categories/groups
- Consider tag autocomplete from external sources (project names, etc.)
- Explore tag sharing/collaboration features

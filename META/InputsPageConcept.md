# Inputs Page Concept & Navigation Update

## Overview
Introduce a dedicated **Inputs** page that focuses on note creation and review, separating it from the timeline. Simplify bottom navigation to three primary destinations while surfacing settings via a floating icon on every page.

## Navigation Changes
- **Bottom Bar**: `Timeline`, `Inputs`, `Archive` (or selected third tab). `Settings` is removed from the dock.
- **Floating Settings Icon**: Top-right corner (≈16pt inset) across all pages. Styled as a glassmorphic circle with a gear glyph and soft shadow. Tapping opens a modal settings panel/sheet without navigating away.

## Inputs Page Layout
Three vertical panes mirror Apple Notes structure while keeping Notate styling.

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│ Notate                                           ⎔ Settings                      │
│                                                                                  │
│ Inputs ▸ All notes                🔍 Search…                Sort: Date ▾         │
└──────────────┬────────────────────────────┬──────────────────────────────────────┘
               │                            │                                      │
               │  Collections               │  Jan 24 · 3:14 PM           🏷 work   │
               │  ───────────────────────   │  ─────────────────────────────────── │
               │  ● All Notes (128)         │  • Draft keynote outline…           │
               │  ● Pinned (6)              │    “Finalize intro slides…”         │
               │  ● Recently Edited (12)    │                                      │
               │                            │  Jan 23 · 9:02 AM            🏷 ux    │
               │  Tags                      │  ─────────────────────────────────── │
               │  ───────────────────────   │  • Design review notes…             │
               │  ● #work (42)              │    “Feedback from usability…”       │
               │  ● #personal (28)          │                                      │
               │  ● #travel (11)            │  Jan 22 · 7:18 PM            🏷 plan  │
               │  ● #meeting (19)           │  ─────────────────────────────────── │
               │  ● #ideas (8)              │  • Q1 planning recap…               │
               │  ● + Add tag filter        │    “Key risks: hiring…”             │
               │                            │                                      │
               │                            │  Jan 20 · 5:07 PM            🏷 ai    │
               │                            │  ─────────────────────────────────── │
               │                            │  • Prompt experiments log…          │
               │                            │    “Tried summarizer v2…”           │
               │                            │                                      │
               ├────────────┬───────────────┴──────────────────────────────────────┤
               │            │ Draft keynote outline                                 │
               │            │ Jan 24 · 3:14 PM · Created by Wayne                   │
               │            │ Tags: #work   #presentation   + Add tag               │
               │            │────────────────────────────────────────────────────── │
               │            │ Finalize intro slides with updated metrics.           │
               │            │ Outline:                                              │
               │            │ 1. Vision recap                                       │
               │            │ 2. Product highlights                                  │
               │            │ 3. Demo flow                                           │
               │            │                                                       │
               │            │ Next steps                                            │
               │            │ - Sync with design on visuals                          │
               │            │ - Schedule dry run                                     │
               │            │                                                       │
               │            │ [Pin]  [Share]  [Delete]                              │
               │            │                                                       │
               │            │ (scroll for full note content)                        │
               └────────────┴───────────────────────────────────────────────────────┘
```

### Left Pane (Collections & Filters)
- Sections: `All Notes`, `Pinned`, `Recently Edited` followed by tag filters.
- Active tag colors displayed as dots; support multi-select (shift-click) for combined filters.
- Optional “+ Add tag filter” control to quickly include new tag groups.

### Middle Pane (Note Previews)
- Reuse timeline entry cards with compressed spacing.
- Display: title/snippet (first ~8 words), updated timestamp, primary tag badge.
- Inline quick actions (pin, tag, delete) visible on hover.

### Right Pane (Detail View)
- Embed `SimpleEntryDetailView` with padding synced to middle pane cards.
- Show tag chips, actions, related reminders, etc., just like the timeline detail drawer, but anchored as a full-height column.

## Search & Sorting
- Search bar sits beneath the top bar, stretching across middle/right panes; filters notes and tag list simultaneously (content + tag name matching).
- Secondary sort selector (`Date`, `Title`, `Tag`) with ascending/descending toggle.

## Mode Switching
- Timeline tab retains its existing header (date picker, tag panel toggle).
- Inputs tab omits the timeline header entirely, giving full vertical real estate to the tri-pane layout.
- Archive tab unaffected aside from floating settings icon addition.

## Settings Modal
- Gear tap reveals floating sheet (e.g., 480×400pt) with dimmed backdrop; contains app-wide preferences previously housed in the Settings tab.
- Modal can be reused across pages for consistency.

## Next Steps
1. Prototype bottom navigation change and ensure tab transitions preserve state.
2. Design the floating settings icon + modal appearance and interaction.
3. Implement tri-pane layout with responsive behavior (collapse to stacked view on narrow widths).
4. Wire search and sort logic to existing AppState filters.

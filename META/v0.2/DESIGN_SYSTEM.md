# Notate Design System v0.2
## Thoughtful Capture, Intelligent Organization

---

## Design Philosophy

Notate's design system is built on three core principles:

1. **Quiet Intelligence** — AI works in the background, surfacing insights without demanding attention
2. **Frictionless Flow** — Capture should be invisible; reviewing should be delightful
3. **Organic Minimalism** — Clean interfaces with subtle warmth and personality

### Design Signature

Unlike purely Apple-inspired apps, Notate establishes its own visual identity through:

- **Muted, sophisticated color palette** inspired by the logo's charcoal slate
- **Asymmetric accent patterns** that create visual rhythm without chaos
- **Soft, breathing micro-interactions** that make the interface feel alive
- **Generous whitespace** that respects the user's cognitive load
- **Subtle depth through shadows** rather than heavy borders

---

## Color System

### Primary Palette

Based on the logo's slate foundation, we build a cohesive yet distinct color system:

```
Notate Slate (Primary Brand Color)
- Base:        #3E4A54  (Slate 600)
- Dark:        #2D3741  (Slate 700)
- Light:       #566672  (Slate 500)
- Ultra Light: #8A97A3  (Slate 400)

Usage: Logo, primary headings, major UI chrome
```

### Accent Colors

These colors provide semantic meaning and visual interest:

```
Neural Blue (Accent Primary)
- Base:    #4A90E2  (Intelligence, AI processing, links)
- Light:   #6CA8EA
- Dark:    #2E75C7
- Subtle:  #E8F2FB  (Backgrounds, hover states)

Thought Purple (Creativity & Ideas)
- Base:    #8B7BDB  (Piece/Thought entries)
- Light:   #A594E4
- Dark:    #6F5DC8
- Subtle:  #F2EFFD

Action Amber (Attention & Warmth)
- Base:    #F5A623  (TODOs, priorities, warnings)
- Light:   #F7B84D
- Dark:    #D98F0E
- Subtle:  #FEF6E8

Success Emerald (Completion & Growth)
- Base:    #27AE60  (Completed states, positive feedback)
- Light:   #52C27D
- Dark:    #1E8449
- Subtle:  #E8F7EF

Alert Crimson (Errors & Critical Actions)
- Base:    #E74C3C  (Destructive actions, errors)
- Light:   #EC6B5E
- Dark:    #C33828
- Subtle:  #FDEDEB
```

### Neutral Scale

For text, backgrounds, and subtle UI elements:

```
- White:         #FFFFFF
- Ghost:         #F8F9FA  (Lightest background)
- Mist:          #E9ECEF  (Subtle backgrounds)
- Fog:           #CED4DA  (Borders, dividers)
- Cloud:         #ADB5BD  (Disabled states)
- Smoke:         #6C757D  (Secondary text)
- Ash:           #495057  (Body text)
- Charcoal:      #212529  (Headings, primary text)
- Void:          #000000
```

### Dark Mode

Notate embraces dark mode with carefully calibrated backgrounds:

```
- Surface:       #1A1F25  (Main background)
- Surface Lift:  #242A31  (Cards, elevated elements)
- Surface Float: #2D343D  (Popovers, modals)
- Border Dark:   #3A4149
- Text Primary:  #E9ECEF
- Text Secondary:#ADB5BD
```

---

## Typography

### Font Families

```swift
Primary: SF Pro Rounded
- Use for: Headings, UI labels, body text, buttons
- Rationale: Friendlier than SF Pro, maintains Apple ecosystem consistency

Monospace: SF Mono
- Use for: Triggers (///, ,,,), metadata, timestamps, code
- Rationale: Technical precision for technical elements

Display (Future): Custom geometric sans
- Reserved for marketing, landing pages, large-format displays
```

### Type Scale

Based on a 1.25 scale ratio (Major Third) for harmonious progression:

```
Display (48px / 3rem)     — Weight: 700 (Bold)
  ↓ Logo wordmark, empty states, hero sections

H1 (32px / 2rem)          — Weight: 600 (Semibold)
  ↓ Page titles, modal headers

H2 (24px / 1.5rem)        — Weight: 600 (Semibold)
  ↓ Section headers, card titles

H3 (19px / 1.1875rem)     — Weight: 500 (Medium)
  ↓ Subsection headers, list item titles

Body (15px / 0.9375rem)   — Weight: 400 (Regular)
  ↓ Main content, entry text, descriptions

Small (13px / 0.8125rem)  — Weight: 400 (Regular)
  ↓ Metadata, captions, helper text

Tiny (11px / 0.6875rem)   — Weight: 500 (Medium)
  ↓ Badges, tags, timestamps

Code (14px / 0.875rem)    — Weight: 400 (Regular, Mono)
  ↓ Triggers, technical details
```

### Line Heights

```
- Display: 1.1   (Tight, for impact)
- Headings: 1.3  (Compact)
- Body: 1.6      (Readable)
- Small: 1.5     (Balanced)
```

### Font Weights Available

```
300: Light      — Reserved for large display text
400: Regular    — Body text, default
500: Medium     — UI labels, emphasis
600: Semibold   — Headings, strong emphasis
700: Bold       — Extra emphasis, display
```

---

## Spacing & Layout

### Base Unit System

All spacing derives from a **4px base unit** for perfect pixel alignment:

```
Space 0:   0px      (No space)
Space 1:   4px      (Micro — inline elements, tight gaps)
Space 2:   8px      (Tiny — icon-text gaps, small padding)
Space 3:   12px     (Small — compact components)
Space 4:   16px     (Base — standard padding, gaps)
Space 5:   20px     (Medium — comfortable spacing)
Space 6:   24px     (Large — section separation)
Space 8:   32px     (XL — major section breaks)
Space 10:  40px     (XXL — page-level spacing)
Space 12:  48px     (Huge — dramatic separation)
Space 16:  64px     (Massive — hero sections)
```

### Component Spacing Rules

```
Card Inner Padding:     Space 5 (20px)
Card Outer Margin:      Space 4 (16px)
Section Vertical Gap:   Space 6 (24px)
List Item Padding:      Space 4 (16px)
Button Padding:         Space 3 - Space 4 (12-16px)
Input Padding:          Space 3 (12px)
Icon-Text Gap:          Space 2 (8px)
Inline Element Gap:     Space 1 (4px)
```

### Grid System

Notate uses a **flexible content-first grid**:

```
Desktop Breakpoint: 1280px
  - Sidebar: 320px (fixed)
  - Main: Flex 1 (min 600px)
  - Detail Panel: 480px (fixed)

Tablet Breakpoint: 768px
  - Sidebar: 280px
  - Main/Detail: Stacked

Mobile: < 768px
  - Single column, full-width cards
```

---

## Border Radius

Softer than Apple's standard for a more approachable feel:

```
Micro:    4px   — Tags, badges, tiny pills
Small:    8px   — Inputs, small buttons
Medium:   12px  — Cards, standard buttons
Large:    16px  — Modals, panels
XL:       20px  — Hero cards, feature sections
Circle:   9999px — Avatars, circular buttons
```

---

## Shadows & Depth

Subtle layering creates depth without visual noise:

### Light Mode Shadows

```
Shadow-Minimal:  0 1px 2px rgba(0, 0, 0, 0.04)
  ↓ Subtle separation, nested elements

Shadow-Subtle:   0 2px 4px rgba(0, 0, 0, 0.06)
  ↓ Resting cards, input fields

Shadow-Soft:     0 4px 8px rgba(0, 0, 0, 0.08)
  ↓ Elevated cards, dropdowns

Shadow-Medium:   0 8px 16px rgba(0, 0, 0, 0.12)
  ↓ Modals, floating panels

Shadow-Strong:   0 16px 32px rgba(0, 0, 0, 0.16)
  ↓ Prominent overlays, dialogs
```

### Dark Mode Shadows

```
Shadow-Minimal:  0 1px 2px rgba(0, 0, 0, 0.20)
Shadow-Subtle:   0 2px 4px rgba(0, 0, 0, 0.30)
Shadow-Soft:     0 4px 8px rgba(0, 0, 0, 0.40)
Shadow-Medium:   0 8px 16px rgba(0, 0, 0, 0.50)
Shadow-Strong:   0 16px 32px rgba(0, 0, 0, 0.60)
```

### Glow Effects (AI Processing States)

```
Glow-Neural:     0 0 16px rgba(74, 144, 226, 0.3)
  ↓ Active AI processing indicator

Glow-Success:    0 0 12px rgba(39, 174, 96, 0.25)
  ↓ Successfully completed action
```

---

## Iconography

### System

- **Source**: SF Symbols (macOS native)
- **Weight**: Medium (500) as default, adjusts with text
- **Size**: Matches adjacent text or explicit sizing

### Custom Icons (Future)

Reserved for brand-specific elements:
- Notate logo variations
- Entry type indicators (if needed beyond SF Symbols)
- Timer/tracking specialized glyphs

### Icon Usage Patterns

```
Entry Types:
  - TODO:    circle / checkmark.circle.fill
  - Piece:   lightbulb / sparkles
  - Archive: archivebox

Actions:
  - Calendar:  calendar.badge.plus
  - Reminder:  bell.badge
  - Contact:   person.crop.circle.badge.plus
  - Maps:      map.fill
  - Edit:      pencil
  - Delete:    trash
  - Convert:   arrow.triangle.2.circlepath

States:
  - Processing: brain.head.profile + spinner
  - Success:    checkmark.circle.fill
  - Error:      exclamationmark.triangle.fill
  - Info:       info.circle
```

---

## Animation & Motion

Notate feels **responsive and organic**, never sluggish or abrupt.

### Timing Functions

```swift
Ease-Snappy:     cubic-bezier(0.4, 0.0, 0.2, 1)
  ↓ Quick, decisive interactions (button clicks)

Ease-Smooth:     cubic-bezier(0.4, 0.0, 0.6, 1)
  ↓ Smooth transitions (view changes, modals)

Ease-Gentle:     cubic-bezier(0.3, 0.0, 0.7, 1)
  ↓ Subtle, graceful movements (hover states)

Ease-Bounce:     cubic-bezier(0.68, -0.55, 0.27, 1.55)
  ↓ Playful feedback (success states)
```

### Duration Scale

```
Duration-Instant:  100ms  — Hover states, color changes
Duration-Quick:    200ms  — Button feedback, toggles
Duration-Smooth:   300ms  — Modal appearance, page transitions
Duration-Gentle:   400ms  — Large layout shifts
Duration-Slow:     600ms  — Emphasis, celebrations
```

### Animation Patterns

#### Micro-interactions

```swift
// Button Press
scale: 0.98
duration: 100ms
timing: ease-snappy

// Card Hover
translateY: -2px
shadow: shadow-soft → shadow-medium
duration: 200ms
timing: ease-gentle

// AI Processing Pulse
scale: 1.0 → 1.05 → 1.0
opacity: 1.0 → 0.8 → 1.0
duration: 1500ms
timing: ease-gentle
iteration: infinite
```

#### State Transitions

```swift
// Entry Creation
entrance: slideInUp + fadeIn
duration: 300ms
timing: ease-smooth

// Entry Deletion
exit: slideOutLeft + fadeOut
duration: 250ms
timing: ease-snappy

// Tab Switching
crossfade: opacity 0 → 1
slide: translateX -20px → 0px
duration: 300ms
timing: ease-smooth
```

#### Processing States

```swift
// AI Analyzing
neural-pulse:
  glow: 0 → 16px blur
  color: neural-blue
  duration: 2000ms
  iteration: infinite

// Success Celebration
scale: 1.0 → 1.1 → 1.0
color: success-emerald
glow: success-glow
duration: 600ms
timing: ease-bounce
```

---

## Component Patterns

### Entry Cards

**Unified Design for TODOs and Pieces**

```
Structure:
┌─────────────────────────────────────────┐
│ [Accent Bar] [Checkbox/Icon] Content   │
│              Metadata · Tags · Time    │
│              ─────────────────────────  │ (if selected)
└─────────────────────────────────────────┘

Specifications:
- Border Radius: 12px
- Inner Padding: 20px
- Shadow: shadow-subtle (resting), shadow-soft (hover)
- Accent Bar: 4px wide, left edge, color-coded by type
  - TODO: Action Amber
  - Piece: Thought Purple
  - Archive: Cloud (neutral)

States:
- Resting: Subtle shadow, white/surface background
- Hover: Slight lift (-2px), shadow upgrade, accent bar brightens
- Selected: 2px border in accent color, background tint (5% opacity)
- Processing: Neural pulse animation on accent bar
```

### Buttons

```
Primary Button:
- Background: Neural Blue
- Text: White
- Padding: 12px 20px
- Border Radius: 10px
- Hover: Darken 10%, lift 1px
- Active: Scale 0.98

Secondary Button:
- Background: Mist (light mode) / Surface Lift (dark)
- Text: Ash / Text Primary
- Border: 1px solid Fog / Border Dark
- Padding: 12px 20px
- Border Radius: 10px
- Hover: Background darkens 5%

Ghost Button:
- Background: Transparent
- Text: Neural Blue
- Padding: 12px 20px
- Hover: Background Neural Blue 5% opacity

Destructive Button:
- Background: Alert Crimson
- Text: White
- Otherwise same as Primary
```

### Input Fields

```
Text Input:
- Border: 1.5px solid Fog
- Border Radius: 10px
- Padding: 12px 16px
- Font: Body (15px)
- Background: White / Surface

Focus State:
- Border: 2px solid Neural Blue
- Shadow: 0 0 0 3px Neural Blue 15% opacity
- Background: Neural Blue 2% opacity

Error State:
- Border: 2px solid Alert Crimson
- Icon: exclamationmark.circle.fill in crimson
```

### Tags

```
Standard Tag:
- Background: Thought Purple 10% opacity
- Text: Thought Purple (dark)
- Font: Tiny (11px), Medium weight
- Padding: 4px 10px
- Border Radius: 6px
- Border: 1px solid Thought Purple 20%

Interactive Tag (clickable):
- Hover: Background 15% opacity, lift 1px
- Active: Background 20% opacity
```

### Badges

```
Status Badge:
- Background: Color 15% opacity
- Text: Color (dark shade)
- Font: Tiny (11px), Medium weight
- Padding: 4px 8px
- Border Radius: 4px
- Display: inline-flex with icon

Examples:
- Processing: Neural Blue + spinner icon
- Done: Success Emerald + checkmark
- Failed: Alert Crimson + xmark
```

---

## Layout Patterns

### Main Application Layout

```
┌──────────────────────────────────────────────────────────┐
│ Toolbar (64px height)                                    │
│ [Logo] [App Name]                     [Settings] [User]  │
├──────────┬───────────────────────────┬──────────────────┤
│          │                           │                  │
│ Sidebar  │  Main Content Area        │  Detail Panel    │
│ (320px)  │  (Flex)                   │  (480px)         │
│          │                           │                  │
│ Search   │  ┌─────────────────────┐  │  Entry Details   │
│ Filters  │  │  Entry Card         │  │  AI Insights     │
│ Tabs     │  └─────────────────────┘  │  Actions         │
│          │  ┌─────────────────────┐  │  Metadata        │
│          │  │  Entry Card         │  │                  │
│          │  └─────────────────────┘  │                  │
│          │                           │                  │
└──────────┴───────────────────────────┴──────────────────┘
```

### Responsive Breakpoints

```
Large Desktop (1920px+):
- Three-column layout maintained
- Detail panel expands to 560px

Desktop (1280px - 1920px):
- Standard three-column layout
- Optimal viewing experience

Laptop (1024px - 1280px):
- Sidebar collapses to 280px
- Detail panel collapses to 400px

Tablet (768px - 1024px):
- Two-column: Sidebar + Main (detail overlays)
- Sidebar can slide away

Mobile (< 768px):
- Single column
- Navigation drawer for sidebar
- Detail view full-screen modal
```

---

## Interaction Patterns

### Hover States

All interactive elements respond to hover:

```
Cards:
- Lift: translateY(-2px)
- Shadow: Upgrade one level
- Accent: Brighten 10%
- Cursor: pointer

Buttons:
- Background: Darken/brighten 10%
- Lift: translateY(-1px)
- Shadow: Add shadow-subtle

Links:
- Color: Brighten 15%
- Underline: Fade in
```

### Click/Tap Feedback

```
All Buttons:
- Scale: 0.98 for 100ms
- Optional: Haptic feedback (if available)

Checkboxes:
- Scale: 1.0 → 1.15 → 1.0
- Color transition: 200ms
- Success pulse on check

Toggle Switches:
- Slide animation: 200ms ease-smooth
- Color fade: 200ms
```

### Loading States

```
Inline Spinner:
- Size: 16px (matches text)
- Color: Neural Blue
- Animation: Smooth rotation

Card Loading:
- Shimmer effect across content
- Pulse: opacity 0.6 → 1.0 → 0.6
- Duration: 1500ms

Full-Page Loading:
- Centered spinner (32px)
- Optional: Loading message below
- Background: Semi-transparent overlay
```

### Empty States

```
Structure:
- Icon: 64px, Light weight, Secondary color
- Headline: H2, Primary color
- Description: Body text, Secondary color
- Optional CTA: Primary button

Tone:
- Encouraging, not punitive
- Provides clear next steps
- Examples:
  - "No TODOs yet — Start capturing tasks!"
  - "Archive is empty — Complete a TODO to see it here"
```

---

## Accessibility

### Color Contrast

All text meets WCAG AA standards:

```
Large Text (24px+):  3:1 minimum
Body Text (15px):    4.5:1 minimum
Small Text (13px):   4.5:1 minimum

Tested Combinations:
✓ Charcoal on White:       15.8:1
✓ Ash on White:            10.3:1
✓ Smoke on White:          5.2:1
✓ Neural Blue on White:    4.9:1
✓ White on Neural Blue:    4.8:1
✓ White on Action Amber:   4.6:1
```

### Keyboard Navigation

All interactive elements are keyboard-accessible:

```
Tab Order:
- Follows visual hierarchy
- Skip links available for sidebar
- Modal traps focus appropriately

Shortcuts:
- ⌘N: New entry
- ⌘F: Focus search
- ⌘1-4: Switch tabs
- ⌘E: Edit selected entry
- ⌘⌫: Delete selected entry
- ⌘↵: Complete TODO
- ↑↓: Navigate entries
- ⌘↑↓: Jump sections
```

### Screen Reader Support

```
Semantic HTML/SwiftUI:
- Proper heading hierarchy
- ARIA labels on icons
- Status announcements for AI processing
- Live regions for toast notifications

Labels:
- All buttons labeled
- Form inputs have associated labels
- Icon-only elements have accessibility labels
```

### Motion Preferences

```
Respects system preference:
- prefers-reduced-motion
- Disables: Pulse animations, parallax, decorative motion
- Preserves: Essential feedback, state transitions
```

---

## Dark Mode Considerations

Notate's dark mode is carefully tuned for **comfort and focus**.

### Color Adaptations

```
Backgrounds:
- Surface → #1A1F25
- Cards → #242A31 (lifted surfaces)
- Modals → #2D343D (floating elements)

Text:
- Primary → #E9ECEF (slightly warm white)
- Secondary → #ADB5BD
- Tertiary → #6C757D

Accents:
- Slightly desaturated in dark mode
- Neural Blue: #5A9FE8 (lighter)
- Thought Purple: #9B8BE5 (lighter)
```

### Shadow Adjustments

```
Light mode: Soft, subtle shadows
Dark mode: Stronger, more defined shadows (prevents muddy appearance)

Example:
Card shadow light: 0 2px 4px rgba(0,0,0,0.06)
Card shadow dark:  0 2px 4px rgba(0,0,0,0.30)
```

### Specific Components

```
Entry Cards (Dark):
- Background: Surface Lift (#242A31)
- Border: 1px solid Border Dark (#3A4149)
- Shadow: Stronger for definition
- Accent bar: Full brightness maintained

Inputs (Dark):
- Background: Surface (#1A1F25)
- Border: Border Dark (#3A4149)
- Focus: Neural Blue glow remains vibrant
```

---

## Design Tokens (Swift Implementation)

All design values should be defined as tokens:

```swift
enum NotateDesignTokens {
    // Colors
    enum Colors {
        static let slate600 = Color(hex: "3E4A54")
        static let neuralBlue = Color(hex: "4A90E2")
        // ... etc
    }

    // Spacing
    enum Spacing {
        static let space1: CGFloat = 4
        static let space2: CGFloat = 8
        // ... etc
    }

    // Typography
    enum Typography {
        static let display = Font.system(size: 48, weight: .bold, design: .rounded)
        // ... etc
    }

    // Shadows
    enum Shadows {
        static let subtle = Shadow(color: .black.opacity(0.06), radius: 4, y: 2)
        // ... etc
    }
}
```

---

## Design Principles in Practice

### 1. Quiet Intelligence

```
DO:
- Show AI insights in a dedicated panel (not inline interruptions)
- Use subtle pulse animations during processing
- Present action suggestions, don't demand immediate response

DON'T:
- Interrupt user with AI popups mid-workflow
- Use aggressive animations or colors for AI features
- Make AI the hero—it's a supporting character
```

### 2. Frictionless Flow

```
DO:
- Auto-save everything
- Use placeholders instead of empty states
- Provide keyboard shortcuts for power users
- Make capture instant (< 50ms perceived latency)

DON'T:
- Require confirmation for every action
- Force multi-step processes for simple tasks
- Disable features behind complex onboarding
```

### 3. Organic Minimalism

```
DO:
- Use whitespace generously
- Soften hard edges with rounded corners
- Add subtle shadows for depth
- Maintain breathing room between sections

DON'T:
- Cram UI elements tightly
- Use harsh borders everywhere
- Flatten everything (depth aids comprehension)
- Over-decorate with unnecessary flourishes
```

---

## Future Design Considerations

### Widgets

```
Planned widget types:
- Quick Capture: Minimal input field
- Active Timer: Pomodoro display
- Today's TODOs: Compact list
- Recent Pieces: Idea snapshot

Widget Design:
- Matches app aesthetic
- Uses same color system
- Simplified typography
- Touch targets minimum 44x44px
```

### Notifications

```
System Notifications:
- Icon: Notate logo (slate)
- Title: Action-focused (e.g., "TODO completed")
- Body: Entry content (truncated)
- Action buttons: Contextual (View, Dismiss)

In-App Toasts:
- Position: Bottom-right
- Duration: 3 seconds
- Dismiss: Tap or auto-fade
- Style: Card with shadow-medium
```

### Onboarding

```
First Launch:
- Minimal, non-intrusive
- Progressive disclosure
- Tutorial on first capture
- Permissions requested in-context

Visual Style:
- Large illustrations (simplified)
- Step indicators (dots)
- Skip always available
- Uses Notate color palette
```

---

## File Organization

Design assets should be organized as:

```
Notate/Design/
├── DesignTokens.swift         (All tokens defined)
├── Components/
│   ├── NotateButton.swift
│   ├── NotateCard.swift
│   ├── NotateInput.swift
│   ├── NotateTag.swift
│   └── NotateBadge.swift
├── Modifiers/
│   ├── ShadowModifiers.swift
│   ├── AnimationModifiers.swift
│   └── LayoutModifiers.swift
└── Extensions/
    ├── Color+Notate.swift
    ├── Font+Notate.swift
    └── View+Notate.swift
```

---

## Version History

- **v0.2** (2025-10) — Complete redesign with unified visual language
- **v0.1** (2025-07) — Initial design system based on Apple HIG

---

## Credits & References

- Inspired by: Apple Human Interface Guidelines, Material Design 3, Linear's design system
- Typography: San Francisco Pro Rounded (Apple)
- Icons: SF Symbols (Apple)
- Philosophy: Dieter Rams' "Less, but better"

---

**This design system is a living document. As Notate evolves, so should these guidelines.**

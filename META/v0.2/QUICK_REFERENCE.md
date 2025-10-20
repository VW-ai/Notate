# Notate v0.2 - Quick Reference Guide

A concise reference for developers working on Notate.

---

## Design Tokens

### Colors
```swift
// Brand
.notateSlate          // #3E4A54 - Primary brand color
.notateNeuralBlue     // #4A90E2 - AI, intelligence, links
.notateThoughtPurple  // #8B7BDB - Pieces/thoughts
.notateActionAmber    // #F5A623 - TODOs, attention
.notateSuccessEmerald // #27AE60 - Completion
.notateAlertCrimson   // #E74C3C - Errors, destructive
```

### Typography
```swift
.notateDisplay   // 48px, Bold
.notateH1        // 32px, Semibold
.notateH2        // 24px, Semibold
.notateH3        // 19px, Medium
.notateBody      // 15px, Regular  ← Default body text
.notateSmall     // 13px, Regular
.notateTiny      // 11px, Medium
```

### Spacing
```swift
.space1   // 4px   - Micro gaps
.space2   // 8px   - Icon-text gaps
.space3   // 12px  - Compact padding
.space4   // 16px  - Standard padding ← Most common
.space5   // 20px  - Card inner padding
.space6   // 24px  - Section gaps
.space8   // 32px  - Major sections
```

### Shadows
```swift
.minimal  // Subtle separation
.subtle   // Resting cards ← Default for cards
.soft     // Elevated cards (hover)
.medium   // Modals, popovers
.strong   // Prominent dialogs
```

---

## Component Usage

### Button
```swift
NotateButton(
    title: "Execute",
    icon: "play.fill",
    style: .primary,  // .primary, .secondary, .ghost, .destructive
    size: .medium     // .small, .medium, .large
) {
    // Action
}
```

### Card
```swift
NotateCard(
    padding: 20,
    cornerRadius: 12,
    shadow: .subtle
) {
    // Content
}
```

### Badge
```swift
NotateBadge(
    text: "Processing",
    style: .processing  // .processing, .success, .error, .info
)
```

### Tag
```swift
NotateTag(
    tag: "#work",
    onRemove: { removeTag() }  // Optional
)
```

### Toast Notification
```swift
NotificationService.shared.showCapture(entry: entry)
NotificationService.shared.showProcessingComplete(entry: entry, actionCount: 3)
NotificationService.shared.showActionExecuted(action: action, entry: entry)
```

---

## Common Patterns

### Entry Type Check
```swift
if entry.isTodo {
    // TODO-specific logic
} else if entry.isPiece {
    // Piece-specific logic
}
```

### Accent Color
```swift
entry.accentColor  // Returns .notateActionAmber or .notateThoughtPurple
```

### Processing State
```swift
let isProcessing = appState.processingEntryIds.contains(entry.id)

// Show processing indicator
if isProcessing {
    ProgressView()
        .neuralPulse(isActive: true)
}
```

### AI Metadata Access
```swift
if let aiMetadata = entry.aiMetadata {
    let actions = aiMetadata.actions
    let research = aiMetadata.researchResults
}

// Check if processed
if entry.hasAIProcessing {
    // Show AI insights
}
```

---

## Animation Presets

### Neural Pulse (AI Processing)
```swift
.neuralPulse(isActive: isProcessingAI)
```

### Hover Lift
```swift
.scaleEffect(isHovering ? 1.01 : 1.0)
.shadow(
    color: isHovering ? .black.opacity(0.12) : .black.opacity(0.06),
    radius: isHovering ? 8 : 4,
    y: isHovering ? 4 : 2
)
.animation(.easeOut(duration: 0.2), value: isHovering)
```

### Celebration (TODO Complete)
```swift
withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
    showCelebration = true
}
```

### Smooth Transition
```swift
withAnimation(.easeInOut(duration: 0.3)) {
    // State change
}
```

---

## Database Operations

### Create Entry
```swift
let entry = Entry(
    type: .todo,
    content: "Buy milk",
    triggerUsed: "///"
)
DatabaseManager.shared.createEntry(entry)
```

### Update Entry
```swift
var updated = entry
updated.content = "Updated content"
DatabaseManager.shared.updateEntry(updated)
```

### Update AI Metadata
```swift
DatabaseManager.shared.updateEntryAIMetadata(
    entry.id,
    metadata: aiMetadata
)
```

### Update Action Status
```swift
DatabaseManager.shared.updateAIActionStatus(
    entry.id,
    actionId: action.id,
    status: .executed
)
```

---

## Settings Keys

```swift
// AI Processing
"aiProcessingEnabled"              // Bool - Enable AI processing

// Auto-Execute
"autoExecute_calendar"             // Bool - Auto-create calendar events
"autoExecute_appleReminders"       // Bool - Auto-create reminders
"autoExecute_contacts"             // Bool - Auto-create contacts
"autoExecute_maps"                 // Bool - Auto-open maps

// Clipboard
"clipboardMonitoringEnabled"       // Bool - Monitor clipboard

// General
"cautiousMode"                     // Bool - Always ask before actions
```

---

## Notifications

### System Notifications
```swift
// Entry created
Notification.Name("Notate.entryCreated")
// object: Entry

// Capture finished
Notification.Name.notateDidFinishCapture
// object: CaptureResult

// AI processing complete
Notification.Name("Notate.aiProcessingComplete")
// object: Entry

// TODO archived
Notification.Name("Notate.todoArchived")
// object: Entry
```

---

## Testing Utilities

### Create Test Entry
```swift
let testEntry = Entry(
    id: UUID().uuidString,
    type: .todo,
    content: "Test TODO",
    tags: ["#test"],
    triggerUsed: "///",
    createdAt: Date(),
    status: .open,
    priority: .medium
)
```

### Mock AI Metadata
```swift
var metadata = AIMetadata()
metadata.actions = [
    AIAction(
        id: UUID().uuidString,
        type: .calendar,
        status: .pending,
        data: [
            "title": ActionData("Test Event"),
            "startDate": ActionData(Date())
        ]
    )
]
```

---

## Accessibility

### Labels
```swift
.accessibilityLabel("Complete TODO")
.accessibilityHint("Double tap to mark as complete")
```

### Traits
```swift
.accessibilityAddTraits(.isButton)
.accessibilityRemoveTraits(.isImage)
```

### Live Regions
```swift
@AccessibilityFocusState private var focusedField: Field?

// Announce changes
.accessibilityElement(children: .combine)
.accessibilityLabel("TODO completed: \(entry.content)")
```

---

## Performance Tips

### Lazy Loading
```swift
LazyVStack {
    ForEach(entries) { entry in
        NotateEntryCard(entry: entry)
    }
}
```

### Task Cancellation
```swift
@State private var task: Task<Void, Never>?

.onDisappear {
    task?.cancel()
}
```

### Debouncing
```swift
.onChange(of: searchQuery) { query in
    debounceTimer?.invalidate()
    debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
        performSearch(query)
    }
}
```

---

## Common Issues

### Entry Not Updating in UI
**Cause:** AppState not refreshing
**Solution:**
```swift
appState.forceRefreshEntries()
```

### AI Processing Stuck
**Check:**
1. Is entry in `processingEntryIds`?
2. Is AI service configured?
3. Check logs for errors

**Fix:**
```swift
appState.processingEntryIds.remove(entry.id)
```

### Colors Not Showing
**Check:**
1. Using `NotateDesignSystem.Colors.*`?
2. Dark mode adaptation?
3. Proper color space?

---

## File Locations

```
Notate/
├── Design/
│   ├── NotateDesignSystem.swift     ← All design tokens
│   ├── Components/                  ← Reusable UI components
│   └── Modifiers/                   ← View modifiers
├── Services/
│   ├── NotificationService.swift    ← Toast notifications
│   ├── TagService.swift             ← Tag management
│   ├── ClipboardMonitor.swift       ← Clipboard detection
│   └── PomodoroTimer.swift          ← Timer logic
├── Views/
│   ├── ContentView.swift            ← Main app layout
│   ├── EntryDetailView.swift        ← Detail panel
│   └── SettingsView.swift           ← Settings panel
└── Models/
    ├── Entry.swift                  ← Entry data model
    └── AIMetadata.swift             ← AI processing data
```

---

## Keyboard Shortcuts

```
⌘N         New entry (future)
⌘F         Focus search
⌘1-4       Switch tabs
⌘E         Edit selected entry
⌘⌫         Delete selected entry
⌘↵         Complete TODO
⌘C         Copy entry content
↑↓         Navigate entries
⌘↑↓       Jump sections
```

---

## Git Workflow

### Branch Naming
```
feature/design-system
feature/todo-completion
feature/tagging-system
bugfix/entry-not-updating
refactor/unified-cards
```

### Commit Messages
```
feat: implement neural pulse animation
fix: prevent duplicate toast notifications
refactor: unify TODO and Piece card components
docs: update design system documentation
test: add tag service unit tests
```

---

## Useful Snippets

### Create Notification
```swift
extension NotificationService {
    func showCustom(title: String, message: String, icon: String) {
        let toast = NotateToast(
            type: .info,
            title: title,
            message: message,
            icon: icon,
            duration: 3.0
        )
        show(toast)
    }
}
```

### Format Duration
```swift
extension TimeInterval {
    var formattedDuration: String {
        let minutes = Int(self) / 60
        let seconds = Int(self) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
```

### Safe Array Access
```swift
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
```

---

## Resources

- **Design System:** `/META/DESIGN_SYSTEM.md`
- **Feature Spec:** `/META/FEATURE_SPECIFICATION.md`
- **Roadmap:** `/META/IMPLEMENTATION_ROADMAP.md`
- **AI Implementation:** `/META/AI_UNIFIED_IMPLEMENTATION_GUIDE.md`
- **Security:** `/META/SECURITY.md`

---

**Quick Start:** Read `DESIGN_SYSTEM.md` first, then `IMPLEMENTATION_ROADMAP.md` for coding.

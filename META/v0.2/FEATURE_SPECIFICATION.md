# Notate v0.2 - Feature Specification
## Enhanced Functionality & User Experience

---

## Overview

This document outlines the major feature enhancements planned for Notate v0.2, focusing on improving the core capture-process-act workflow while maintaining the app's minimalist philosophy.

---

## 1. Entry Feedback & Notification System

### Problem Statement
Users currently have no visibility into:
- Whether an entry was successfully captured
- When AI processing starts/completes
- If AI actions were executed successfully

### Solution: Multi-Layer Feedback System

#### Layer 1: Capture Toast (Immediate)

**Trigger:** Entry successfully captured via keyboard trigger

**Visual:**
```
┌──────────────────────────────────────────────────┐
│ ✓ Captured TODO                        Just now  │
│ "Buy milk and eggs from store"                   │
│ Trigger: ///                                      │
└──────────────────────────────────────────────────┘
```

**Specifications:**
- Position: Bottom-right corner, 20px margin
- Duration: 3 seconds (auto-dismiss)
- Animation: Slide up + fade in (300ms), fade out (200ms)
- Dismissible: Click to dismiss immediately
- Max entries shown: 3 (stacked vertically)

**Implementation:**
- Use existing toast in ContentView but enhance styling
- Add entry type icon (checkmark for TODO, lightbulb for Piece)
- Show trigger used as badge

#### Layer 2: Processing Status Badge (During AI Analysis)

**Trigger:** AI processing begins for an entry

**Visual:**
On the entry card itself:
```
┌─────────────────────────────────────────────┐
│ [●] Buy milk and eggs        [Processing] ●  │  ← Pulsing dot
│ 2 min ago · Medium                           │
└─────────────────────────────────────────────┘
```

**Specifications:**
- Badge: "Processing" with neural blue color
- Pulsing animation: 1.5s cycle, opacity 0.6 → 1.0 → 0.6
- Accent bar: Neural blue with glow effect
- Status: Visible in list view and detail view

**Implementation:**
- Check `appState.processingEntryIds.contains(entry.id)`
- Add `.neuralPulse()` modifier to accent bar
- Badge component shows processing status

#### Layer 3: Completion Notification (After AI Processing)

**Trigger:** AI finishes processing (insights + actions extracted)

**Visual:**
```
┌──────────────────────────────────────────────────┐
│ ✨ AI Insights Ready                   2 min ago │
│ "Buy milk and eggs"                              │
│ → 3 actions suggested · Research complete        │
└──────────────────────────────────────────────────┘
```

**Specifications:**
- Position: Bottom-right (same as capture toast)
- Duration: 5 seconds
- Click action: Jump to entry detail view
- Includes quick stats: action count, research availability

**Implementation:**
- Listen to `Notification.Name("Notate.aiProcessingComplete")`
- Show toast with summary
- Make toast clickable to select entry

#### Layer 4: Action Execution Feedback

**Trigger:** AI action executes (e.g., creates calendar event)

**Visual:**
```
┌──────────────────────────────────────────────────┐
│ ✓ Calendar Event Created              Just now   │
│ "Coffee chat tomorrow at John A Paulson"         │
│ → View in Calendar                               │
└──────────────────────────────────────────────────┘
```

**Specifications:**
- Position: Bottom-right
- Duration: 4 seconds
- Action button: "View in [App]" opens the created resource
- Different icons per action type

**Implementation:**
- Post notification from `ToolService` after successful execution
- Include action type, description, and jump URL
- Toast becomes clickable to open target app

### Technical Implementation

```swift
// New NotificationService.swift
class NotificationService: ObservableObject {
    @Published var activeToasts: [NotateToast] = []

    func showCapture(entry: Entry) { }
    func showProcessing(entryId: String) { }
    func showProcessingComplete(entry: Entry, actionCount: Int) { }
    func showActionExecuted(action: AIAction, entry: Entry) { }
}

struct NotateToast: Identifiable {
    let id = UUID()
    let type: ToastType
    let title: String
    let message: String
    let icon: String
    let duration: TimeInterval
    let action: (() -> Void)?
}

enum ToastType {
    case capture, processing, success, error, info
}
```

---

## 2. TODO Completion: One-Way Only (No Undo)

### Current Behavior
TODOs can be marked as done, then unmarked back to open. This creates confusion:
- Archive becomes unreliable (items disappear)
- No clear "completion" moment
- Undermines sense of progress

### New Behavior: Completion is Final

#### User Flow

**Before Completion:**
```
User clicks checkbox on TODO
  ↓
Confirmation dialog appears:
  "Mark as Complete?"
  "This TODO will be archived. You can view it in the Archive tab."
  [Cancel] [Complete]
```

**After Completion:**
- TODO instantly moves to Archive tab
- Celebration animation (checkmark scales + green glow)
- Toast notification: "TODO completed and archived"
- Entry shows in Archive with read-only state

**Accidental Click Protection:**
- 500ms delay required for checkbox to register (prevents accidental completion)
- OR: Long-press gesture (macOS equivalent: click + hold 300ms)
- Visual feedback during delay: Progress ring fills around checkbox

#### Archive View Changes

**Archive becomes Read-Only:**
- No checkboxes shown (completion is visual only)
- Strikethrough text maintained
- Green success color accent
- Metadata shows completion timestamp
- Actions:
  - View details (read-only)
  - Delete permanently
  - Export

**Bulk Actions in Archive:**
- Select multiple → "Delete All Selected"
- "Clear Archive" button (with confirmation)
- Export to CSV/JSON

### Implementation Details

```swift
// Remove markTodoAsOpen() functionality from AppState
// Update UI to remove undo capability

// EntryDetailView.swift
private func toggleCompletion(_ entry: Entry) {
    if entry.status == .done {
        // Previously could undo - now do nothing
        return
    } else {
        // Show confirmation dialog
        showCompletionConfirmation = true
    }
}

// Add confirmation modal
.alert("Complete TODO?", isPresented: $showCompletionConfirmation) {
    Button("Cancel", role: .cancel) { }
    Button("Complete") {
        completeTodoWithAnimation(entry)
    }
} message: {
    Text("This TODO will be moved to the Archive. Completed TODOs cannot be reopened.")
}

// Celebration animation
private func completeTodoWithAnimation(_ entry: Entry) {
    withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
        // Scale + glow effect
        showCompletionCelebration = true
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
        appState.markTodoAsDone(entry)
        showCompletionCelebration = false
    }
}
```

### Archive View Enhancements

**New Features:**
- Sort by completion date (newest first)
- Filter by original priority
- Search within archived items
- Export selected items
- Statistics: "You've completed X TODOs this week!"

---

## 3. Unified Entry Design Language

### Problem Statement
TODOs and Pieces currently have different visual treatments:
- TODOs: List-style with checkboxes
- Pieces: Card-style with icons
- Inconsistent spacing, shadows, and interactions

### Solution: Single Unified Card Component

#### Visual Structure

**All entries use the same base card:**
```
┌─ [4px accent bar]
│ ┌───────────────────────────────────────────────┐
│ │ [Type Icon] Entry Content                     │
│ │             ─────────────────────────          │
│ │             Metadata · Tags · Priority        │
│ └───────────────────────────────────────────────┘
└─
```

**Type Differentiation:**

**TODO Entry:**
```
┌─ [Amber accent]
│ ┌───────────────────────────────────────────────┐
│ │ ○ Buy milk and eggs from store                │
│ │   2 min ago · Medium · #shopping              │
│ └───────────────────────────────────────────────┘
└─
```

**Piece Entry:**
```
┌─ [Purple accent]
│ ┌───────────────────────────────────────────────┐
│ │ ✦ I like the moon today I want to draw        │
│ │   5 min ago · #art #inspiration               │
│ └───────────────────────────────────────────────┘
└─
```

#### Implementation

```swift
// New unified component: NotateEntryCard.swift

struct NotateEntryCard: View {
    let entry: Entry
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack(spacing: 0) {
            // Accent bar (left edge)
            accentBar

            // Card content
            cardContent
                .padding(20)
                .background(cardBackground)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: shadowColor, radius: shadowRadius, y: shadowY)
        .onTapGesture { selectEntry() }
        .onHover { isHovering in
            withAnimation(.easeOut(duration: 0.2)) {
                self.isHovering = isHovering
            }
        }
    }

    private var accentBar: some View {
        Rectangle()
            .fill(entry.accentColor)
            .frame(width: 4)
            .opacity(isProcessing ? 0.8 : 1.0)
            .modifier(NeuralPulse(isActive: isProcessing))
    }

    // Shared across TODOs and Pieces
    private var cardContent: some View {
        HStack(spacing: 16) {
            // Type icon (checkbox for TODO, sparkle for Piece)
            typeIcon

            VStack(alignment: .leading, spacing: 8) {
                // Content text
                contentText

                // Metadata row (unified)
                metadataRow
            }

            Spacer()

            // Priority indicator (TODOs only)
            if entry.isTodo, let priority = entry.priority {
                PriorityIndicator(priority: priority)
            }
        }
    }
}
```

**Benefits:**
- Consistent spacing and sizing
- Shared hover/selection states
- Unified animations
- Easier maintenance
- Better accessibility (predictable structure)

---

## 4. Auto-Execute AI Actions

### Current Behavior
AI suggests actions (create calendar event, add reminder, etc.) but requires:
1. User clicks "Execute" button
2. Permission check
3. User clicks "Jump" to see created item

**Problem:** Too many steps for automated intelligence.

### New Behavior: Execute by Default

#### Execution Flow

**After AI Processing:**
```
Entry analyzed
  ↓
Actions identified (e.g., "Create calendar event")
  ↓
Check permissions
  ↓
  ├─ Granted → Execute immediately
  │   ↓
  │   Show toast: "Calendar event created"
  │   ↓
  │   Update entry with "Done" status
  │
  └─ Not granted → Show permission request
      ↓
      User grants permission
      ↓
      Execute action
      ↓
      Remember preference for this action type
```

#### Permission Handling

**First-Time Actions:**
- AI identifies action type requiring permission (e.g., Calendar)
- System permission dialog appears immediately
- User grants/denies
- If granted: Execute action
- If denied: Show in-app guidance to enable in System Settings

**Subsequent Actions:**
- No additional prompts
- Execute silently
- Show success toast

#### User Control

**Settings Panel:**
```
┌─────────────────────────────────────────────────┐
│ AI Action Preferences                           │
├─────────────────────────────────────────────────┤
│                                                 │
│ [✓] Auto-execute Calendar events                │
│ [✓] Auto-execute Reminders                      │
│ [✓] Auto-create Contacts                        │
│ [✓] Auto-open Maps locations                    │
│ [ ] Auto-execute Web searches                   │
│                                                 │
│ ─────────────────────────────────────────────   │
│                                                 │
│ [ ] Always ask before executing actions         │
│     (Cautious mode - requires manual approval)  │
│                                                 │
└─────────────────────────────────────────────────┘
```

**Per-Action Review:**
- Entry detail view shows action status: "Done ✓" or "Failed ✗"
- Click "View in App" → Opens Calendar/Reminders/etc. to the created item
- Revert button available for 24 hours

#### Implementation

```swift
// AutonomousAIAgent.swift modifications

func processEntry(_ entry: Entry) async {
    // Extract actions
    let actions = await extractActions(from: entry)

    // Auto-execute if enabled
    for action in actions {
        if shouldAutoExecute(action.type) {
            await executeActionAutomatically(action, for: entry)
        }
    }
}

private func shouldAutoExecute(_ actionType: AIActionType) -> Bool {
    // Check user preferences
    let preferences = UserDefaults.standard
    let key = "autoExecute_\(actionType.rawValue)"
    return preferences.bool(forKey: key)
}

private func executeActionAutomatically(_ action: AIAction, for entry: Entry) async {
    // Check permission
    let permissionStatus = permissionManager.getPermissionForAction(action.type)

    guard permissionStatus.isGranted else {
        // Request permission first
        await requestPermissionAndExecute(action, for: entry)
        return
    }

    // Execute immediately
    do {
        let success = try await toolService.execute(action, for: entry)

        if success {
            // Update entry status
            await MainActor.run {
                databaseManager.updateAIActionStatus(entry.id, actionId: action.id, status: .executed)

                // Show success toast
                notificationService.showActionExecuted(action, entry: entry)
            }
        }
    } catch {
        print("❌ Auto-execute failed: \(error)")
        // Update entry status to failed
        await MainActor.run {
            databaseManager.updateAIActionStatus(entry.id, actionId: action.id, status: .failed)
        }
    }
}
```

---

## 5. Remove AI Search, Implement Tagging System

### Rationale
Web search integration adds complexity without sufficient value:
- Results are generic
- Doesn't integrate well with capture workflow
- Users can search manually if needed

**Better approach:** Intelligent tagging for organization and retrieval.

### New Tagging System

#### Tag Extraction

**AI automatically suggests tags during processing:**
```
Entry: "Buy organic milk from Whole Foods tomorrow"

AI extracts:
- Content tags: #shopping, #groceries
- Entity tags: #wholeFoods
- Time tags: #tomorrow
- Category: #errand
```

**User can:**
- Accept all suggestions (one click)
- Accept individual tags
- Add custom tags
- Remove suggested tags

#### Tag Management

**Tag Autocomplete:**
```
User types: #sho...
  ↓
Suggestions appear:
  #shopping (12 entries)
  #shortStory (3 entries)
  #shower-thoughts (8 entries)
```

**Tag Cloud View:**
```
┌─────────────────────────────────────────────────┐
│ Your Tags                                       │
├─────────────────────────────────────────────────┤
│                                                 │
│  #work (45)    #ideas (32)    #shopping (28)   │
│  #fitness (15) #reading (12)  #art (10)        │
│  #coding (8)   #meetings (6)  #recipes (5)     │
│                                                 │
│  [See all 47 tags →]                            │
└─────────────────────────────────────────────────┘
```

**Click tag → Filter view to entries with that tag**

#### Tag-Based Features

**Smart Collections:**
```
Automatically generated based on tag frequency:
- "Work" (all #work, #meeting, #project tags)
- "Personal" (all #personal, #errand, #home tags)
- "Ideas" (all #idea, #brainstorm, #concept tags)
```

**Tag Analytics:**
```
- Most used tags this week
- Tag combinations (e.g., #work + #urgent often together)
- Trending tags (growing usage)
```

#### Implementation

```swift
// New TagService.swift

class TagService {
    // Extract tags from AI metadata
    func extractTagsFromAI(_ entry: Entry) -> [String] {
        guard let aiMetadata = entry.aiMetadata,
              let tagData = aiMetadata.extractedData?["tags"] as? [String] else {
            return []
        }
        return tagData
    }

    // Get all unique tags in database
    func getAllTags() -> [TagWithCount] {
        // Query database for unique tags + count
    }

    // Tag autocomplete suggestions
    func suggestTags(for query: String) -> [TagWithCount] {
        getAllTags()
            .filter { $0.tag.lowercased().hasPrefix(query.lowercased()) }
            .sorted { $0.count > $1.count }
    }

    // Smart collections
    func generateSmartCollections() -> [SmartCollection] {
        // Analyze tag patterns and create collections
    }
}

struct TagWithCount: Identifiable {
    let id = UUID()
    let tag: String
    let count: Int
}

// Update Entry model to include suggested tags
extension Entry {
    var suggestedTags: [String] {
        aiMetadata?.extractedData?["suggestedTags"] as? [String] ?? []
    }
}
```

**UI Components:**

```swift
// TagInputView.swift
struct TagInputView: View {
    @Binding var tags: [String]
    @State private var inputText = ""
    @State private var suggestions: [TagWithCount] = []

    var body: some View {
        VStack {
            // Input field with # prefix
            HStack {
                Text("#")
                TextField("Add tag", text: $inputText)
                    .onChange(of: inputText) { query in
                        suggestions = tagService.suggestTags(for: query)
                    }
            }

            // Suggestions dropdown
            if !suggestions.isEmpty {
                tagSuggestions
            }

            // Current tags (chips)
            tagChips
        }
    }
}
```

---

## 6. Clipboard Support for Capture

### Feature Description

Allow users to trigger capture by:
1. Copying text to clipboard
2. Text contains trigger pattern
3. Notate auto-detects and captures

### Use Cases

**Scenario 1: Copy from Website**
```
User sees on website: "/// Remember to book dentist appointment"
  ↓
User copies text (Cmd+C)
  ↓
Notate detects trigger in clipboard
  ↓
Shows notification: "Clipboard capture detected - Create TODO?"
  ↓
User clicks "Yes" → Entry created
```

**Scenario 2: Share to Notate**
```
User in Notes app types: ",,, Great idea for app feature"
  ↓
Selects text and uses macOS Share → "Send to Notate"
  ↓
Notate extracts content after trigger
  ↓
Entry created automatically
```

### Implementation

```swift
// ClipboardMonitor.swift

class ClipboardMonitor: ObservableObject {
    private var lastChangeCount: Int = 0
    private var timer: Timer?

    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }

    private func checkClipboard() {
        let pasteboard = NSPasteboard.general
        guard pasteboard.changeCount != lastChangeCount else { return }

        lastChangeCount = pasteboard.changeCount

        if let clipboardText = pasteboard.string(forType: .string) {
            processClipboardText(clipboardText)
        }
    }

    private func processClipboardText(_ text: String) {
        // Check if text contains any configured triggers
        let triggers = ConfigurationManager.shared.getAllTriggers()

        for trigger in triggers {
            if let match = detectTriggerPattern(in: text, trigger: trigger.characters) {
                // Found trigger in clipboard
                showClipboardCapturePrompt(content: match.content, trigger: trigger)
                break
            }
        }
    }

    private func showClipboardCapturePrompt(content: String, trigger: TriggerConfiguration) {
        // Show notification or in-app prompt
        let alert = NSAlert()
        alert.messageText = "Capture from Clipboard?"
        alert.informativeText = "\(trigger.characters) \(content)"
        alert.addButton(withTitle: "Capture")
        alert.addButton(withTitle: "Ignore")

        if alert.runModal() == .alertFirstButtonReturn {
            createEntryFromClipboard(content: content, trigger: trigger)
        }
    }
}
```

**Settings Toggle:**
```
[ ] Monitor clipboard for triggers
    Notate will watch for trigger patterns in copied text
    and offer to create entries automatically.
```

---

## 7. Time Analysis Infrastructure

### Purpose
Lay foundation for future productivity insights without building full analytics now.

### Data Model Extensions

```swift
// Extend Entry model with time tracking fields

extension Entry {
    // Time tracking
    var viewedAt: Date?              // Last time user viewed this entry
    var viewCount: Int                // How many times viewed
    var estimatedDuration: TimeInterval?  // AI-estimated time to complete (TODOs)
    var actualDuration: TimeInterval?     // User-logged time spent
    var completedAt: Date?           // When TODO was marked done

    // Pomodoro integration (future)
    var pomodoroSessions: [PomodoroSession]?  // Time tracking sessions
    var totalTimeSpent: TimeInterval {
        pomodoroSessions?.reduce(0) { $0 + $1.duration } ?? 0
    }
}

struct PomodoroSession: Codable, Identifiable {
    let id: String
    let startedAt: Date
    let duration: TimeInterval  // Actual duration (may be less than 25min if interrupted)
    let completed: Bool         // Did user finish the session?
    let notes: String?          // Optional notes about the session
}
```

### AI Time Estimation

During processing, AI estimates task duration:
```
Entry: "Write quarterly report"
  ↓
AI analyzes complexity
  ↓
Estimates: "This task will take approximately 2-3 hours"
  ↓
Stored in entry.estimatedDuration
  ↓
Shown in UI: "Est. 2-3 hours"
```

### Database Schema Update

```sql
-- Add columns to entries table
ALTER TABLE entries ADD COLUMN viewed_at INTEGER;
ALTER TABLE entries ADD COLUMN view_count INTEGER DEFAULT 0;
ALTER TABLE entries ADD COLUMN estimated_duration_seconds INTEGER;
ALTER TABLE entries ADD COLUMN actual_duration_seconds INTEGER;
ALTER TABLE entries ADD COLUMN completed_at INTEGER;
ALTER TABLE entries ADD COLUMN pomodoro_sessions TEXT;  -- JSON array
```

### Future Analytics (Not Implemented Yet)

**Planned insights:**
- Average completion time by priority
- Accuracy of AI time estimates
- Productive hours (when most TODOs completed)
- Task velocity (TODOs completed per day/week)
- Pomodoro effectiveness (completion rate with vs without timer)

**UI Placeholder:**
```
┌─────────────────────────────────────────────────┐
│ Analytics (Coming Soon)                         │
├─────────────────────────────────────────────────┤
│                                                 │
│ We're tracking time data to provide insights   │
│ into your productivity patterns.                │
│                                                 │
│ Check back in future updates for:              │
│  • Completion time analytics                   │
│  • Productivity trends                          │
│  • Time estimation accuracy                    │
│                                                 │
└─────────────────────────────────────────────────┘
```

---

## 8. Pomodoro Timer & Event Tracking

### Overview
Integrate a Pomodoro timer directly into Notate for focused work sessions on TODOs.

### Trigger-Based Timer Start

**Keyboard capture for timer:**
```
User types: "/// timer 25m write quarterly report"
  ↓
Notate detects "timer" keyword + duration
  ↓
Creates TODO: "Write quarterly report"
  ↓
Automatically starts 25-minute Pomodoro timer
  ↓
Shows timer in menubar + widget
```

**Alternative syntax:**
```
"/// 🍅 write quarterly report"  → Starts default 25min timer
"/// timer 50m deep work session" → Custom duration
"/// focus 90m no interruptions"  → 90min deep work block
```

### Timer UI Components

#### Menubar Timer

```
┌──────────────────┐
│ Notate  🍅 23:45 │  ← Active timer in menubar
└──────────────────┘

Click → Shows popover:
┌────────────────────────────────────┐
│ Write quarterly report             │
│                                    │
│        ⏱ 23:45                     │
│     ████████████░░░░               │
│                                    │
│ [Pause] [Skip Break] [Stop]       │
└────────────────────────────────────┘
```

#### In-App Timer Display

```
Active TODO card shows timer:
┌─────────────────────────────────────────────┐
│ ○ Write quarterly report        [⏱ 23:45]  │
│   Started 2 min ago · High                  │
│   ████████████████░░░░░░ 78%               │
└─────────────────────────────────────────────┘
```

#### Completion Flow

```
Timer reaches 0:00
  ↓
Notification: "Pomodoro complete! Take a break."
  ↓
Options:
  [Mark TODO Done] [Start Break] [Continue Working]
  ↓
If "Mark TODO Done":
  - Stop timer
  - Mark TODO complete
  - Log session duration
  ↓
If "Start Break":
  - Start 5min break timer
  - After break: "Ready to continue?"
```

### Implementation

```swift
// PomodoroTimer.swift

@MainActor
class PomodoroTimer: ObservableObject {
    @Published var isRunning = false
    @Published var timeRemaining: TimeInterval = 0
    @Published var totalDuration: TimeInterval = 25 * 60  // 25 minutes
    @Published var associatedEntry: Entry?

    private var timer: Timer?
    private var startTime: Date?

    func start(duration: TimeInterval, for entry: Entry) {
        self.totalDuration = duration
        self.timeRemaining = duration
        self.associatedEntry = entry
        self.startTime = Date()
        self.isRunning = true

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func tick() {
        guard timeRemaining > 0 else {
            complete()
            return
        }

        timeRemaining -= 1
    }

    private func complete() {
        timer?.invalidate()
        isRunning = false

        // Log session
        if let entry = associatedEntry, let startTime = startTime {
            let session = PomodoroSession(
                id: UUID().uuidString,
                startedAt: startTime,
                duration: totalDuration - timeRemaining,
                completed: true,
                notes: nil
            )

            // Save session to entry
            var updatedEntry = entry
            var sessions = updatedEntry.pomodoroSessions ?? []
            sessions.append(session)
            updatedEntry.pomodoroSessions = sessions

            // Update database
            DatabaseManager.shared.updateEntry(updatedEntry)
        }

        // Show completion notification
        showCompletionNotification()
    }

    func pause() {
        timer?.invalidate()
        isRunning = false
    }

    func stop() {
        timer?.invalidate()
        isRunning = false
        timeRemaining = 0

        // Log incomplete session if significant time elapsed
        if let startTime = startTime, Date().timeIntervalSince(startTime) > 60 {
            logIncompleteSession()
        }
    }
}
```

### Widget Support

#### macOS Widget (Today View)

```
┌─────────────────────────────────────┐
│ Notate - Active Timer               │
├─────────────────────────────────────┤
│                                     │
│ Write quarterly report              │
│                                     │
│          ⏱ 23:45                    │
│      ████████████░░░░               │
│                                     │
│      [Pause]    [Stop]              │
│                                     │
└─────────────────────────────────────┘
```

**Implementation:**
```swift
// NotateWidget/TimerWidget.swift

struct TimerWidgetView: View {
    let entry: TimerWidgetEntry

    var body: some View {
        VStack(spacing: 12) {
            Text(entry.todoTitle)
                .font(.headline)
                .lineLimit(2)

            Text(entry.timeRemaining.formatted())
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .monospacedDigit()

            ProgressView(value: entry.progress)
                .tint(.blue)

            HStack {
                Button(intent: PauseTimerIntent()) {
                    Label("Pause", systemImage: "pause.fill")
                }

                Button(intent: StopTimerIntent()) {
                    Label("Stop", systemImage: "stop.fill")
                }
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}
```

---

## 9. Additional Enhancements

### Copy Entry Content

**Keyboard shortcut:** ⌘C when entry is selected

**Behavior:**
- Copies entry content to clipboard
- Strips metadata, keeps tags
- Format: Plain text or Markdown (user preference)

**Implementation:**
```swift
.onCopyCommand {
    // Entry selected, copy its content
    if let selectedEntry = appState.selectedEntry {
        return [NSItemProvider(object: selectedEntry.content as NSString)]
    }
    return []
}
```

### Smart Paste Detection

**Scenario:**
User pastes text containing trigger:
```
Paste: "/// Remember to call mom"
  ↓
Notate detects trigger in pasted text
  ↓
Shows inline prompt: "Create TODO from pasted text?"
  ↓
User confirms → Entry created
```

---

## Priority & Roadmap

### Phase 1: Foundation (Weeks 1-2)
✓ Design system documentation
- [ ] Entry feedback system
- [ ] TODO completion finality
- [ ] Unified entry cards

### Phase 2: Intelligence (Weeks 3-4)
- [ ] Auto-execute AI actions
- [ ] Remove web search
- [ ] Implement tagging system

### Phase 3: Advanced (Weeks 5-6)
- [ ] Clipboard monitoring
- [ ] Time tracking infrastructure
- [ ] Pomodoro timer
- [ ] Widget support

---

## Success Metrics

**User Experience:**
- Time to capture: < 50ms (maintained)
- AI processing feedback: 100% visible
- TODO completion clarity: Zero confusion about archive behavior
- Action execution: 90% success rate without user intervention

**Technical:**
- Clipboard monitoring: < 5% CPU usage
- Timer accuracy: ±1 second
- Widget refresh rate: Every 1 second during active timer
- Database migration: Zero data loss

---

## Open Questions

1. **Clipboard privacy:** Should we add explicit privacy notice about clipboard monitoring?
2. **Timer notifications:** System notifications or in-app only?
3. **Tag limits:** Max tags per entry? (Suggest: 10)
4. **Pomodoro customization:** Allow custom break durations?
5. **Widget placement:** Today view only, or also Notification Center?

---

**This specification is a living document and will evolve as implementation progresses.**

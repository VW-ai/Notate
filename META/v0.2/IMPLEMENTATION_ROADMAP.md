# Notate v0.2 - Implementation Roadmap
## Strategic Technical Plan

---

## Overview

This document outlines the **technical implementation strategy** for Notate v0.2, detailing the order of work, dependencies, file structure, and migration approach to ensure a smooth transformation while maintaining app stability.

---

## Guiding Principles

### 1. Backwards Compatibility
- Existing database must continue working
- Graceful migration path for data
- No breaking changes to capture engine

### 2. Incremental Delivery
- Each phase delivers user-visible value
- Features can be tested independently
- Rollback strategy for each phase

### 3. Code Quality
- SwiftUI best practices
- Clear separation of concerns
- Comprehensive error handling
- Performance benchmarks maintained

---

## Phase 1: Foundation & Design System
**Duration:** Week 1-2
**Goal:** Establish visual identity and core design components

### 1.1 Design System Implementation

#### File Structure
```
Notate/Design/
├── NotateDesignSystem.swift        # Master design tokens
├── Components/
│   ├── NotateButton.swift          # Unified button component
│   ├── NotateCard.swift            # Unified card component
│   ├── NotateInput.swift           # Text fields, search bars
│   ├── NotateTag.swift             # Tag chips and badges
│   ├── NotateBadge.swift           # Status badges
│   └── NotateToast.swift           # Notification toasts
├── Modifiers/
│   ├── ShadowModifiers.swift       # Pre-defined shadow styles
│   ├── AnimationModifiers.swift    # Animation presets
│   └── NeuralPulseModifier.swift   # AI processing animation
└── Extensions/
    ├── Color+Notate.swift          # Color palette extension
    ├── Font+Notate.swift           # Typography extension
    └── View+Notate.swift           # Convenience modifiers
```

#### Implementation Steps

**Step 1: Create NotateDesignSystem.swift**
```swift
// Complete rewrite of ModernDesignSystem.swift
// Includes all colors, typography, spacing from DESIGN_SYSTEM.md

enum NotateDesignSystem {
    enum Colors {
        // Brand
        static let slate600 = Color(hex: "3E4A54")
        static let slate700 = Color(hex: "2D3741")

        // Accents
        static let neuralBlue = Color(hex: "4A90E2")
        static let thoughtPurple = Color(hex: "8B7BDB")
        static let actionAmber = Color(hex: "F5A623")
        static let successEmerald = Color(hex: "27AE60")
        static let alertCrimson = Color(hex: "E74C3C")

        // Neutrals
        static let ghost = Color(hex: "F8F9FA")
        static let mist = Color(hex: "E9ECEF")
        // ... etc
    }

    enum Typography {
        static let display = Font.system(size: 48, weight: .bold, design: .rounded)
        static let h1 = Font.system(size: 32, weight: .semibold, design: .rounded)
        // ... etc
    }

    enum Spacing {
        static let space1: CGFloat = 4
        static let space2: CGFloat = 8
        // ... etc
    }

    enum Shadows {
        static func minimal(darkMode: Bool = false) -> Shadow {
            Shadow(
                color: .black.opacity(darkMode ? 0.20 : 0.04),
                radius: 2,
                y: 1
            )
        }
        // ... etc
    }
}
```

**Step 2: Create Core Components**
- NotateButton with all variants (primary, secondary, ghost, destructive)
- NotateCard with accent bar support
- NotateInput with focus states
- NotateTag for tag chips
- NotateBadge for status indicators

**Step 3: Create Animation Modifiers**
```swift
// NeuralPulseModifier.swift
struct NeuralPulse: ViewModifier {
    let isActive: Bool
    @State private var pulsing = false

    func body(content: Content) -> some View {
        content
            .opacity(isActive ? (pulsing ? 0.6 : 1.0) : 1.0)
            .shadow(
                color: isActive ? NotateDesignSystem.Colors.neuralBlue.opacity(0.3) : .clear,
                radius: pulsing ? 16 : 0
            )
            .onAppear {
                if isActive {
                    withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                        pulsing = true
                    }
                }
            }
    }
}

extension View {
    func neuralPulse(isActive: Bool) -> some View {
        modifier(NeuralPulse(isActive: isActive))
    }
}
```

**Step 4: Color & Font Extensions**
```swift
// Color+Notate.swift
extension Color {
    init(hex: String) {
        // Hex color initializer
    }

    // Convenience accessors
    static var notateSlate: Color { NotateDesignSystem.Colors.slate600 }
    static var notateNeuralBlue: Color { NotateDesignSystem.Colors.neuralBlue }
    // ... etc
}

// Font+Notate.swift
extension Font {
    static var notateDisplay: Font { NotateDesignSystem.Typography.display }
    static var notateH1: Font { NotateDesignSystem.Typography.h1 }
    // ... etc
}
```

#### Testing Checklist
- [ ] All colors render correctly in light mode
- [ ] All colors render correctly in dark mode
- [ ] Typography scales properly
- [ ] Shadows visible but subtle
- [ ] Animations smooth (60fps)
- [ ] Components accessible (VoiceOver)

---

### 1.2 Notification System (Toast)

#### Create NotificationService

**File:** `Notate/Services/NotificationService.swift`

```swift
@MainActor
class NotificationService: ObservableObject {
    static let shared = NotificationService()

    @Published var activeToasts: [NotateToast] = []

    private let maxToasts = 3

    func show(_ toast: NotateToast) {
        // Add to array
        activeToasts.append(toast)

        // Trim if exceeds max
        if activeToasts.count > maxToasts {
            activeToasts.removeFirst()
        }

        // Auto-dismiss after duration
        Task {
            try? await Task.sleep(nanoseconds: UInt64(toast.duration * 1_000_000_000))
            dismiss(toast)
        }
    }

    func dismiss(_ toast: NotateToast) {
        activeToasts.removeAll { $0.id == toast.id }
    }

    // Convenience methods
    func showCapture(entry: Entry) {
        let toast = NotateToast(
            type: .capture,
            title: "Captured \(entry.type.displayName)",
            message: entry.content,
            icon: entry.type == .todo ? "checkmark.circle.fill" : "lightbulb.fill",
            duration: 3.0
        )
        show(toast)
    }

    func showProcessingComplete(entry: Entry, actionCount: Int) {
        let toast = NotateToast(
            type: .success,
            title: "AI Insights Ready",
            message: "\(actionCount) actions suggested",
            icon: "sparkles",
            duration: 5.0,
            action: {
                // Jump to entry
                AppState.shared.selectedEntry = entry
            }
        )
        show(toast)
    }
}

struct NotateToast: Identifiable {
    let id = UUID()
    let type: ToastType
    let title: String
    let message: String
    let icon: String
    let duration: TimeInterval
    var action: (() -> Void)? = nil

    enum ToastType {
        case capture, processing, success, error, info

        var accentColor: Color {
            switch self {
            case .capture: return .notateActionAmber
            case .processing: return .notateNeuralBlue
            case .success: return .notateSuccessEmerald
            case .error: return .notateAlertCrimson
            case .info: return .notateSlate
            }
        }
    }
}
```

#### Create NotateToastView Component

**File:** `Notate/Design/Components/NotateToast.swift`

```swift
struct NotateToastView: View {
    let toast: NotateToast
    let onDismiss: () -> Void

    var body: some View {
        NotateCard(
            padding: NotateDesignSystem.Spacing.space4,
            cornerRadius: NotateDesignSystem.CornerRadius.medium,
            shadow: .medium
        ) {
            HStack(spacing: NotateDesignSystem.Spacing.space3) {
                // Icon
                Image(systemName: toast.icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(toast.type.accentColor)

                VStack(alignment: .leading, spacing: 4) {
                    // Title
                    Text(toast.title)
                        .font(.notateBody)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    // Message
                    Text(toast.message)
                        .font(.notateSmall)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                // Dismiss button
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: 400)
        .onTapGesture {
            if let action = toast.action {
                action()
                onDismiss()
            }
        }
    }
}

// Overlay in ContentView
struct ToastOverlay: View {
    @EnvironmentObject var notificationService: NotificationService

    var body: some View {
        VStack(spacing: 12) {
            Spacer()

            ForEach(notificationService.activeToasts) { toast in
                NotateToastView(toast: toast) {
                    notificationService.dismiss(toast)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(NotateDesignSystem.Spacing.space5)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: notificationService.activeToasts)
    }
}
```

#### Integration Points

**Modify ContentView.swift:**
```swift
.overlay(alignment: .bottomTrailing) {
    ToastOverlay()
        .environmentObject(notificationService)
}
```

**Modify CaptureEngine.swift:**
```swift
// After successful capture
NotificationService.shared.showCapture(entry: createdEntry)
```

#### Testing
- [ ] Toast appears on capture
- [ ] Toast auto-dismisses after 3s
- [ ] Multiple toasts stack correctly
- [ ] Toast clickable to dismiss
- [ ] Smooth animations

---

### 1.3 Unified Entry Card Component

#### Create NotateEntryCard

**File:** `Notate/Design/Components/NotateEntryCard.swift`

This replaces both `ModernTodoCard` and `ModernThoughtCard` with a single unified component.

```swift
struct NotateEntryCard: View {
    let entry: Entry
    @EnvironmentObject var appState: AppState
    @State private var isHovering = false

    private var isProcessing: Bool {
        appState.processingEntryIds.contains(entry.id)
    }

    private var isSelected: Bool {
        appState.selectedEntry?.id == entry.id
    }

    var body: some View {
        HStack(spacing: 0) {
            // Accent bar (4px left edge)
            accentBar

            // Card content
            cardContent
                .padding(NotateDesignSystem.Spacing.space5)
        }
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: NotateDesignSystem.CornerRadius.medium))
        .shadow(
            color: shadowColor,
            radius: shadowRadius,
            y: shadowY
        )
        .scaleEffect(isHovering ? 1.01 : 1.0)
        .onTapGesture { selectEntry() }
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
    }

    private var accentBar: some View {
        Rectangle()
            .fill(entry.accentColor)
            .frame(width: 4)
            .neuralPulse(isActive: isProcessing)
    }

    private var cardContent: some View {
        HStack(spacing: NotateDesignSystem.Spacing.space4) {
            // Type-specific icon (checkbox for TODO, sparkle for Piece)
            typeIcon

            VStack(alignment: .leading, spacing: NotateDesignSystem.Spacing.space2) {
                // Content text
                contentText

                // Metadata row
                metadataRow
            }

            Spacer()

            // Right side: Priority (TODO) or Processing badge
            rightSideContent
        }
    }

    @ViewBuilder
    private var typeIcon: some View {
        if entry.isTodo {
            Button(action: toggleCompletion) {
                Image(systemName: entry.status == .done ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(entry.status == .done ? .notateSuccessEmerald : .secondary)
            }
            .buttonStyle(.plain)
        } else {
            Image(systemName: "sparkles")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.notateThoughtPurple)
        }
    }

    private var contentText: some View {
        Text(entry.content)
            .font(.notateBody)
            .foregroundColor(entry.status == .done ? .secondary : .primary)
            .strikethrough(entry.status == .done)
            .lineLimit(2)
    }

    private var metadataRow: some View {
        HStack(spacing: NotateDesignSystem.Spacing.space2) {
            Text(entry.formattedDate)
                .font(.notateTiny)
                .foregroundColor(.secondary)

            if entry.isTodo, let priority = entry.priority {
                Text("·")
                    .foregroundColor(.secondary)

                PriorityIndicator(priority: priority, style: .dots)
            }

            if !entry.tags.isEmpty {
                Text("·")
                    .foregroundColor(.secondary)

                Text("\(entry.tags.count) tag\(entry.tags.count == 1 ? "" : "s")")
                    .font(.notateTiny)
                    .foregroundColor(.secondary)
            }
        }
    }

    @ViewBuilder
    private var rightSideContent: some View {
        if isProcessing {
            NotateBadge(text: "Processing", style: .processing)
        } else if entry.isTodo, let priority = entry.priority {
            PriorityIndicator(priority: priority, style: .badge)
        }
    }

    // Accent color based on type
    private var accentColor: Color {
        entry.accentColor
    }

    private func selectEntry() {
        withAnimation(.easeInOut(duration: 0.2)) {
            appState.selectedEntry = entry
        }
    }

    private func toggleCompletion() {
        // Will implement completion confirmation in Phase 1
    }
}

// Extension for accent color
extension Entry {
    var accentColor: Color {
        switch type {
        case .todo:
            return .notateActionAmber
        case .thought, .piece:
            return .notateThoughtPurple
        }
    }
}
```

#### Replace Existing Card Views

**Update TodoListView.swift:**
```swift
// Replace ModernTodoCard with NotateEntryCard
ForEach(todos) { todo in
    NotateEntryCard(entry: todo)
        .environmentObject(appState)
}
```

**Update ThoughtCardView.swift:**
```swift
// Replace ModernThoughtCard with NotateEntryCard
ForEach(thoughts) { thought in
    NotateEntryCard(entry: thought)
        .environmentObject(appState)
}
```

#### Testing
- [ ] TODOs display correctly with checkbox
- [ ] Pieces display correctly with sparkle
- [ ] Accent bar color matches type
- [ ] Hover states work smoothly
- [ ] Selection highlights entry
- [ ] Processing animation shows when AI active

---

## Phase 2: TODO Completion & AI Automation
**Duration:** Week 3-4
**Goal:** Finalize TODO behavior and auto-execute AI actions

### 2.1 Remove TODO Undo Capability

#### Database Schema (No changes needed)
Current schema already supports this - we just remove UI capabilities.

#### Code Changes

**File: AppState.swift**
```swift
// REMOVE this function entirely
func markTodoAsOpen(_ entry: Entry) {
    // Delete this function
}
```

**File: EntryDetailView.swift**
```swift
// MODIFY toggleCompletion
private func toggleCompletion(_ entry: Entry) {
    if entry.status == .done {
        // Remove undo capability - do nothing
        return
    } else {
        // Show confirmation before completing
        showCompletionConfirmation = true
    }
}

// ADD completion confirmation
@State private var showCompletionConfirmation = false

.alert("Complete TODO?", isPresented: $showCompletionConfirmation) {
    Button("Cancel", role: .cancel) { }
    Button("Complete") {
        completeTodoWithAnimation(entry)
    }
} message: {
    Text("This TODO will be moved to the Archive. Completed TODOs cannot be reopened.")
}

// ADD celebration animation
private func completeTodoWithAnimation(_ entry: Entry) {
    // Trigger success animation
    withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
        // Scale effect, green glow
    }

    // Complete after animation
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
        appState.markTodoAsDone(entry)

        // Show completion toast
        NotificationService.shared.showTodoCompleted(entry: entry)
    }
}
```

**File: NotateEntryCard.swift**
```swift
// Update checkbox behavior
private func toggleCompletion() {
    guard entry.status != .done else {
        // Cannot undo - shake animation to indicate
        withAnimation(.default) {
            // Shake effect
        }
        return
    }

    // Show confirmation alert
    showCompletionConfirmation = true
}
```

**File: ArchiveListView.swift**
```swift
// Make archive view read-only

struct ArchiveListView: View {
    let archivedTodos: [Entry]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(archivedTodos) { entry in
                    ArchivedEntryCard(entry: entry)  // New read-only card
                }
            }
        }
    }
}

struct ArchivedEntryCard: View {
    let entry: Entry

    var body: some View {
        NotateCard {
            HStack {
                // Completed checkmark (non-interactive)
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.notateSuccessEmerald)

                VStack(alignment: .leading, spacing: 8) {
                    Text(entry.content)
                        .strikethrough()
                        .foregroundColor(.secondary)

                    HStack {
                        Text("Completed: \(entry.completedAt?.formatted() ?? "N/A")")
                            .font(.notateTiny)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Delete button only
                Button(action: { deleteEntry() }) {
                    Image(systemName: "trash")
                        .foregroundColor(.notateAlertCrimson)
                }
            }
        }
    }
}
```

#### Testing
- [ ] Completed TODOs cannot be unmarked
- [ ] Confirmation dialog appears before completion
- [ ] Celebration animation plays on completion
- [ ] Archive view is read-only
- [ ] Checkbox shake animation on attempted undo

---

### 2.2 Auto-Execute AI Actions

#### Update AI Processing Flow

**File: AutonomousAIAgent.swift**

```swift
func processEntry(_ entry: Entry) async {
    // Mark as processing
    await MainActor.run {
        appState.processingEntryIds.insert(entry.id)
    }

    // Extract metadata and actions
    let metadata = await extractMetadata(from: entry)
    let actions = metadata.actions

    // Save metadata
    await MainActor.run {
        databaseManager.updateEntryAIMetadata(entry.id, metadata: metadata)
    }

    // AUTO-EXECUTE actions if enabled
    for action in actions {
        if shouldAutoExecute(action.type) {
            await executeActionAutomatically(action, for: entry)
        }
    }

    // Mark processing complete
    await MainActor.run {
        appState.processingEntryIds.remove(entry.id)

        // Show completion toast
        NotificationService.shared.showProcessingComplete(
            entry: entry,
            actionCount: actions.count
        )
    }
}

private func shouldAutoExecute(_ actionType: AIActionType) -> Bool {
    // Check user preferences
    let key = "autoExecute_\(actionType.rawValue)"
    return UserDefaults.standard.bool(forKey: key)
}

private func executeActionAutomatically(_ action: AIAction, for entry: Entry) async {
    // Check permission
    let permission = await permissionManager.checkPermission(for: action.type)

    guard permission.isGranted else {
        // Permission not granted - request it
        await requestPermissionAndExecute(action, for: entry)
        return
    }

    // Execute action
    do {
        // Update status to executing
        await MainActor.run {
            databaseManager.updateAIActionStatus(entry.id, actionId: action.id, status: .executing)
        }

        // Execute via ToolService
        let success = try await toolService.execute(action, for: entry)

        // Update status
        await MainActor.run {
            databaseManager.updateAIActionStatus(
                entry.id,
                actionId: action.id,
                status: success ? .executed : .failed
            )

            if success {
                // Show success toast
                NotificationService.shared.showActionExecuted(action: action, entry: entry)
            }
        }
    } catch {
        print("❌ Auto-execute failed: \(error)")
        await MainActor.run {
            databaseManager.updateAIActionStatus(entry.id, actionId: action.id, status: .failed)
        }
    }
}
```

#### Add Settings Panel for Auto-Execute

**File: SettingsView.swift**

```swift
Section("AI Actions") {
    Toggle("Auto-execute Calendar events", isOn: $autoExecuteCalendar)
        .onChange(of: autoExecuteCalendar) { value in
            UserDefaults.standard.set(value, forKey: "autoExecute_calendar")
        }

    Toggle("Auto-execute Reminders", isOn: $autoExecuteReminders)
        .onChange(of: autoExecuteReminders) { value in
            UserDefaults.standard.set(value, forKey: "autoExecute_appleReminders")
        }

    Toggle("Auto-create Contacts", isOn: $autoExecuteContacts)
        .onChange(of: autoExecuteContacts) { value in
            UserDefaults.standard.set(value, forKey: "autoExecute_contacts")
        }

    Toggle("Auto-open Maps", isOn: $autoExecuteMaps)
        .onChange(of: autoExecuteMaps) { value in
            UserDefaults.standard.set(value, forKey: "autoExecute_maps")
        }

    Divider()

    Toggle("Cautious Mode (always ask before executing)", isOn: $cautiousMode)
        .onChange(of: cautiousMode) { value in
            // Disable all auto-execute if cautious mode enabled
            if value {
                disableAllAutoExecute()
            }
        }
}
```

#### Testing
- [ ] Actions auto-execute after processing
- [ ] Permission requests appear if needed
- [ ] Success toasts show after execution
- [ ] Settings toggle controls behavior
- [ ] Cautious mode disables auto-execute

---

## Phase 3: Tagging & Advanced Features
**Duration:** Week 5-6
**Goal:** Remove web search, implement tagging, add clipboard support

### 3.1 Remove Web Search

**File: AIMetadata.swift**
```swift
// Remove webSearch case from AIActionType
enum AIActionType: String, Codable, CaseIterable {
    case appleReminders = "reminders"
    case calendar = "calendar"
    case contacts = "contacts"
    case maps = "maps"
    // REMOVE: case webSearch = "web_search"
}
```

**File: PromptManager.swift**
```swift
// Remove web search from action extraction prompt
static func actionExtractionPrompt(...) -> String {
    """
    Available action types:
    - calendar: Create calendar event
    - reminders: Create reminder in Apple Reminders
    - contacts: Save contact information
    - maps: Save/navigate to location

    DO NOT suggest web search actions.
    """
}
```

**File: EntryDetailView.swift**
```swift
// Remove web search handling from executeActionWithToolService()
// Remove .webSearch case
```

### 3.2 Implement Tagging System

#### Update Database Schema

```sql
-- Already have tags array in Entry model, but add tag suggestions

-- Create tags table for analytics
CREATE TABLE IF NOT EXISTS tags (
    tag TEXT PRIMARY KEY,
    count INTEGER DEFAULT 1,
    last_used INTEGER,
    created_at INTEGER
);

-- Create tag index for fast lookups
CREATE INDEX IF NOT EXISTS idx_tags_count ON tags(count DESC);
```

#### Create TagService

**File: Notate/Services/TagService.swift**

```swift
class TagService {
    static let shared = TagService()
    private let database = DatabaseManager.shared

    // Get all unique tags with counts
    func getAllTags() -> [TagWithCount] {
        // Query database
        // SELECT tag, count FROM tags ORDER BY count DESC
    }

    // Autocomplete suggestions
    func suggestTags(for query: String, limit: Int = 5) -> [TagWithCount] {
        getAllTags()
            .filter { $0.tag.lowercased().hasPrefix(query.lowercased()) }
            .prefix(limit)
            .map { $0 }
    }

    // Record tag usage
    func recordTagUsage(_ tag: String) {
        // INSERT OR UPDATE tags SET count = count + 1, last_used = NOW()
    }

    // Extract tags from AI metadata
    func extractSuggestedTags(from entry: Entry) -> [String] {
        guard let aiMetadata = entry.aiMetadata,
              let extractedData = aiMetadata.extractedData,
              let tags = extractedData["suggested_tags"] as? [String] else {
            return []
        }
        return tags
    }
}

struct TagWithCount: Identifiable {
    let id = UUID()
    let tag: String
    let count: Int
}
```

#### Update AI Extraction to Include Tags

**File: PromptManager.swift**

```swift
static func contentExtractionPrompt(for entry: Entry) -> String {
    """
    Analyze this entry and extract:

    1. **Suggested Tags**: 3-5 relevant tags (use # prefix)
       - Content-based: What is this about?
       - Category: What type of entry? (work, personal, idea, etc.)
       - Entities: People, places, brands mentioned

    2. **Priority**: If TODO, estimate priority (low/medium/high)

    3. **Time Estimate**: If TODO, estimate completion time

    Entry: "\(entry.content)"

    Return JSON:
    {
      "suggested_tags": ["#shopping", "#groceries", "#wholeFoods"],
      "priority": "medium",
      "time_estimate_minutes": 30
    }
    """
}
```

#### Create Tag UI Components

**File: Notate/Design/Components/NotateTagInput.swift**

```swift
struct NotateTagInput: View {
    @Binding var tags: [String]
    @State private var inputText = ""
    @State private var suggestions: [TagWithCount] = []
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Current tags
            if !tags.isEmpty {
                tagChips
            }

            // Input field
            HStack {
                Image(systemName: "number")
                    .foregroundColor(.secondary)

                TextField("Add tag", text: $inputText)
                    .focused($isFocused)
                    .onChange(of: inputText) { query in
                        updateSuggestions(query)
                    }
                    .onSubmit {
                        addTag()
                    }
            }
            .padding(12)
            .background(Color(.textBackgroundColor))
            .cornerRadius(8)

            // Suggestions dropdown
            if !suggestions.isEmpty && isFocused {
                suggestionsList
            }
        }
    }

    private var tagChips: some View {
        FlowLayout(spacing: 8) {
            ForEach(tags, id: \.self) { tag in
                NotateTagChip(tag: tag, onRemove: {
                    removeTag(tag)
                })
            }
        }
    }

    private var suggestionsList: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(suggestions) { suggestion in
                Button(action: {
                    selectSuggestion(suggestion.tag)
                }) {
                    HStack {
                        Text(suggestion.tag)
                            .font(.notateBody)

                        Spacer()

                        Text("\(suggestion.count)")
                            .font(.notateTiny)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
            }
        }
        .background(Color(.windowBackgroundColor))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.1), radius: 8)
    }
}

struct NotateTagChip: View {
    let tag: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Text(tag)
                .font(.notateTiny)
                .fontWeight(.medium)

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 12))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.notateThoughtPurple.opacity(0.15))
        .foregroundColor(.notateThoughtPurple)
        .cornerRadius(6)
    }
}
```

#### Testing
- [ ] Web search removed from action types
- [ ] AI suggests relevant tags
- [ ] Tag autocomplete works
- [ ] Tags save to database
- [ ] Tag usage tracked for analytics

---

### 3.3 Clipboard Monitoring

**File: Notate/Services/ClipboardMonitor.swift**

```swift
class ClipboardMonitor: ObservableObject {
    @Published var detectedCapture: DetectedCapture?

    private var lastChangeCount = 0
    private var timer: Timer?
    private var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: "clipboardMonitoringEnabled")
    }

    func startMonitoring() {
        guard isEnabled else { return }

        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    private func checkClipboard() {
        let pasteboard = NSPasteboard.general

        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount

        guard let text = pasteboard.string(forType: .string) else { return }

        // Check for trigger pattern
        if let capture = detectTriggerInText(text) {
            detectedCapture = capture
        }
    }

    private func detectTriggerInText(_ text: String) -> DetectedCapture? {
        let triggers = ConfigurationManager.shared.getAllTriggers()

        for trigger in triggers where trigger.enabled {
            // Pattern: {trigger} content {trigger}
            let pattern = "\(trigger.characters)\\s*(.+?)\\s*\(trigger.characters)"

            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let contentRange = Range(match.range(at: 1), in: text) {

                let content = String(text[contentRange])
                return DetectedCapture(content: content, trigger: trigger)
            }
        }

        return nil
    }
}

struct DetectedCapture {
    let content: String
    let trigger: TriggerConfiguration
}
```

#### Integrate with AppState

**File: AppState.swift**

```swift
lazy var clipboardMonitor = ClipboardMonitor()

init() {
    // Start clipboard monitoring if enabled
    if UserDefaults.standard.bool(forKey: "clipboardMonitoringEnabled") {
        clipboardMonitor.startMonitoring()
    }

    // Listen for detected captures
    clipboardMonitor.$detectedCapture
        .compactMap { $0 }
        .sink { [weak self] capture in
            self?.handleClipboardCapture(capture)
        }
        .store(in: &cancellables)
}

private func handleClipboardCapture(_ capture: DetectedCapture) {
    // Show prompt
    let alert = NSAlert()
    alert.messageText = "Capture from Clipboard?"
    alert.informativeText = "\(capture.trigger.characters) \(capture.content)"
    alert.addButton(withTitle: "Capture")
    alert.addButton(withTitle: "Ignore")

    if alert.runModal() == .alertFirstButtonReturn {
        // Create entry
        let entry = Entry(
            type: capture.trigger.type,
            content: capture.content,
            triggerUsed: capture.trigger.characters
        )

        databaseManager.createEntry(entry)
        NotificationService.shared.showCapture(entry: entry)
    }
}
```

#### Testing
- [ ] Clipboard monitoring can be enabled/disabled
- [ ] Trigger patterns detected in clipboard
- [ ] Prompt appears for clipboard captures
- [ ] Entry created when confirmed
- [ ] Minimal CPU usage (< 5%)

---

## Phase 4: Time Tracking & Pomodoro
**Duration:** Week 7-8 (if needed)

### 4.1 Database Migration for Time Fields

**File: DatabaseManager.swift**

```swift
// Migration v2 → v3: Add time tracking fields
private func migrateToVersion3() {
    let sql = """
    ALTER TABLE entries ADD COLUMN viewed_at INTEGER;
    ALTER TABLE entries ADD COLUMN view_count INTEGER DEFAULT 0;
    ALTER TABLE entries ADD COLUMN estimated_duration_seconds INTEGER;
    ALTER TABLE entries ADD COLUMN actual_duration_seconds INTEGER;
    ALTER TABLE entries ADD COLUMN completed_at INTEGER;
    ALTER TABLE entries ADD COLUMN pomodoro_sessions TEXT;
    """

    executeMigration(sql, toVersion: 3)
}
```

### 4.2 Pomodoro Timer Implementation

**File: Notate/Services/PomodoroTimer.swift**

(See detailed implementation in FEATURE_SPECIFICATION.md)

### 4.3 Widget Support

**Create new target:** NotateWidget

**File: NotateWidget/TimerWidget.swift**

(See detailed implementation in FEATURE_SPECIFICATION.md)

---

## Testing Strategy

### Unit Tests
```
NotateTests/
├── DesignSystemTests.swift      # Color, typography, spacing
├── NotificationServiceTests.swift
├── TagServiceTests.swift
├── ClipboardMonitorTests.swift
└── PomodoroTimerTests.swift
```

### Integration Tests
```
NotateIntegrationTests/
├── CaptureFlowTests.swift       # End-to-end capture
├── AIProcessingTests.swift      # AI extraction + execution
├── TodoCompletionTests.swift    # Completion + archive
└── TaggingFlowTests.swift       # Tag suggestion + usage
```

### UI Tests
```
NotateUITests/
├── EntryCardTests.swift         # Unified card rendering
├── ToastTests.swift             # Notification display
├── SettingsTests.swift          # Settings panel
└── AccessibilityTests.swift     # VoiceOver, keyboard nav
```

---

## Performance Benchmarks

Maintain these targets throughout implementation:

```
Capture latency:        < 50ms   (user press → entry created)
AI processing time:     < 5s     (entry → insights complete)
UI render time:         < 16ms   (60fps maintained)
Database query time:    < 10ms   (typical read operation)
Clipboard check cycle:  < 5% CPU (background monitoring)
Memory footprint:       < 100MB  (typical usage)
```

---

## Rollback Strategy

Each phase must have a rollback plan:

**Phase 1:** Keep `ModernDesignSystem.swift` until `NotateDesignSystem` fully validated
**Phase 2:** Preserve `markTodoAsOpen()` but hide from UI initially
**Phase 3:** Web search can be disabled via feature flag before removal
**Phase 4:** Time tracking fields nullable, won't break existing entries

---

## Success Criteria

### Phase 1 Complete When:
- [ ] All components use `NotateDesignSystem`
- [ ] Toasts appear for all capture events
- [ ] Unified entry cards render for TODO and Piece
- [ ] No visual regressions
- [ ] Performance benchmarks met

### Phase 2 Complete When:
- [ ] TODO completion is one-way only
- [ ] AI actions auto-execute (if enabled)
- [ ] Settings panel controls auto-execute
- [ ] Celebration animations play
- [ ] Archive is read-only

### Phase 3 Complete When:
- [ ] Web search fully removed
- [ ] Tag suggestions appear during AI processing
- [ ] Tag autocomplete functional
- [ ] Clipboard monitoring optional and working
- [ ] Tag analytics tracked

### Phase 4 Complete When:
- [ ] Pomodoro timer functional
- [ ] Widget displays active timer
- [ ] Time tracking data persists
- [ ] Timer notifications work
- [ ] Integration with TODO completion

---

## Deployment

### Version Numbering
- Current: v0.1.x
- Next: v0.2.0 (major redesign)

### Release Notes Template

```
## Notate v0.2.0 - "Neural Flow"

### Design Overhaul
- Complete visual redesign with distinctive Notate aesthetic
- Unified entry cards for TODOs and Pieces
- Smooth animations and micro-interactions
- Dark mode refinements

### Behavior Changes
- ⚠️ BREAKING: Completed TODOs can no longer be unmarked
- AI actions now auto-execute (configurable in Settings)
- Enhanced feedback system with notifications

### New Features
- Intelligent tagging system powered by AI
- Clipboard monitoring for effortless capture
- Pomodoro timer integration
- macOS widget support

### Improvements
- Faster AI processing
- Better error handling
- Improved accessibility
- Performance optimizations

### Removed
- Web search integration (replaced with smarter tagging)
```

---

**This roadmap is a living document and will be updated as implementation progresses.**

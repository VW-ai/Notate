# Quick Start: Integrating Phase 1 Components

This guide will help you integrate the new design system into Notate in **~30 minutes**.

---

## Prerequisites

All Phase 1 components are built and ready in:
- `/Notate/Design/` directory
- `/Notate/Services/NotificationService.swift`

---

## Step-by-Step Integration

### Step 1: Add NotificationService to App (5 min)

**File:** `Notate/NotateApp.swift`

Add the notification service as an environment object:

```swift
import SwiftUI

@main
struct NotateApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var notificationService = NotificationService.shared  // ADD THIS

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(notificationService)  // ADD THIS
                .onAppear {
                    setupCaptureEngine()
                }
        }
        .windowStyle(.hiddenTitleBar)
    }

    // ... rest of file
}
```

---

### Step 2: Add Toast Overlay to ContentView (5 min)

**File:** `Notate/Views/ContentView.swift`

Add the toast overlay at the end of your view:

```swift
struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            // ... existing content ...
        }
        .sheet(isPresented: $showingSettings) {
            // ... existing sheets ...
        }
        // ADD THIS OVERLAY:
        .overlay(alignment: .bottomTrailing) {
            ToastOverlay()
                .environmentObject(NotificationService.shared)
        }
    }
}
```

---

### Step 3: Replace Entry Cards (10 min)

**File:** `Notate/Views/TodoListView.swift`

Replace `ModernTodoCard` with `NotateEntryCard`:

```swift
// OLD:
struct TodoListView: View {
    let todos: [Entry]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(todos) { todo in
                    ModernTodoCard(todo: todo)  // OLD
                        .environmentObject(appState)
                }
            }
        }
    }
}

// NEW:
struct TodoListView: View {
    let todos: [Entry]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(todos) { todo in
                    NotateEntryCard(entry: todo)  // NEW
                        .environmentObject(appState)
                }
            }
            .padding(.horizontal, NotateDesignSystem.Spacing.space4)
            .padding(.vertical, NotateDesignSystem.Spacing.space3)
        }
        .background(Color.notateGhost)
    }
}
```

**File:** `Notate/Views/ThoughtCardView.swift`

Similar replacement:

```swift
// Replace ModernThoughtCard with NotateEntryCard
ForEach(thoughts) { thought in
    NotateEntryCard(entry: thought)  // NEW
        .environmentObject(appState)
}
```

---

### Step 4: Update ContentView "All" Tab (5 min)

**File:** `Notate/Views/ContentView.swift`

In the `allEntriesView`, replace card components:

```swift
private var allEntriesView: some View {
    ScrollView {
        LazyVStack(spacing: NotateDesignSystem.Spacing.space3) {
            let todos = appState.filteredEntries().filter { $0.isTodo }
            let thoughts = appState.filteredEntries().filter { $0.isPiece }

            if !todos.isEmpty {
                // Section header (optional styling update)
                Text("TODOs (\(todos.count))")
                    .font(.notateH3)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, NotateDesignSystem.Spacing.space4)

                ForEach(todos) { todo in
                    NotateEntryCard(entry: todo)  // NEW
                        .environmentObject(appState)
                }
            }

            if !thoughts.isEmpty {
                Text("Pieces (\(thoughts.count))")
                    .font(.notateH3)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, NotateDesignSystem.Spacing.space4)

                ForEach(thoughts) { thought in
                    NotateEntryCard(entry: thought)  // NEW
                        .environmentObject(appState)
                }
            }
        }
        .padding(.horizontal, NotateDesignSystem.Spacing.space4)
        .padding(.vertical, NotateDesignSystem.Spacing.space3)
    }
    .background(Color.notateGhost)
}
```

---

### Step 5: Add Capture Toast (5 min)

**File:** `Notate/CaptureEngine.swift`

After successfully creating an entry, show a toast:

```swift
// In the capture completion handler
func handleCapturedContent(_ content: String, trigger: TriggerConfiguration) {
    // ... create entry ...

    // ADD THIS after entry is created:
    NotificationService.shared.showCapture(entry: createdEntry)
}
```

**OR if using notification:**

```swift
// Listen for capture notification
NotificationCenter.default.publisher(for: .notateDidFinishCapture)
    .compactMap { $0.object as? CaptureResult }
    .sink { result in
        // Show toast
        if let entry = findEntryFromResult(result) {
            NotificationService.shared.showCapture(entry: entry)
        }
    }
    .store(in: &cancellables)
```

---

### Step 6: Build & Test (5 min)

1. **Build the project:**
   ```bash
   # In Xcode: Cmd+B
   # Or terminal:
   xcodebuild -project Notate.xcodeproj -scheme Notate -configuration Debug
   ```

2. **Run the app:**
   ```bash
   # In Xcode: Cmd+R
   ```

3. **Test key features:**
   - ✅ Capture an entry (should show toast)
   - ✅ View TODO list (should use new cards)
   - ✅ View Pieces list (should use new cards)
   - ✅ Click on an entry (should select with accent border)
   - ✅ Hover over entry (should lift slightly)
   - ✅ Toggle dark mode (should adapt automatically)

---

## Optional Enhancements

### Update Settings Button

Replace settings button in `ContentView` toolbar:

```swift
// OLD:
ModernButton(title: "Settings", icon: "gear", ...)

// NEW:
NotateButton(
    title: "Settings",
    icon: "gear",
    style: .ghost,
    size: .medium
) {
    showingSettings = true
}
```

### Update Search Bar Styling

In `ContentView` header:

```swift
HStack {
    Image(systemName: "magnifyingglass")
        .foregroundColor(.secondary)

    TextField("Search entries...", text: $appState.searchQuery)
        .font(.notateBody)  // Use new typography
        .textFieldStyle(PlainTextFieldStyle())
}
.padding(NotateDesignSystem.Spacing.space3)
.background(Color.notateMist)  // Use new colors
.cornerRadius(NotateDesignSystem.CornerRadius.small)
```

### Add Processing Toasts

When AI processing starts:

```swift
// In AppState.processEntryWithAI()
func processEntryWithAI(_ entry: Entry) {
    processingEntryIds.insert(entry.id)

    // Show processing toast
    NotificationService.shared.showProcessing(entry: entry)

    Task {
        await autonomousAIAgent.processEntry(entry)

        await MainActor.run {
            processingEntryIds.remove(entry.id)

            // Show completion toast
            let actionCount = entry.aiMetadata?.actions.count ?? 0
            NotificationService.shared.showProcessingComplete(
                entry: entry,
                actionCount: actionCount
            )
        }
    }
}
```

---

## Troubleshooting

### Issue: "Cannot find 'NotateDesignSystem' in scope"

**Fix:** Make sure the file is added to the Xcode project:
1. Right-click on `Notate/Design/` folder in Xcode
2. Add Files to "Notate"...
3. Select all files in `Design/` directory
4. Ensure "Add to targets: Notate" is checked

### Issue: "Cannot find 'NotificationService' in scope"

**Fix:** Same as above - add `NotificationService.swift` to the project.

### Issue: Toasts not appearing

**Check:**
1. Is `ToastOverlay` added to `ContentView`?
2. Is `NotificationService` injected as environment object?
3. Are you calling `NotificationService.shared.show...()` methods?

### Issue: Entry cards look different than expected

**Check:**
1. Are you using `NotateEntryCard` (not the old cards)?
2. Is `appState` injected as environment object?
3. Does the entry have an `accentColor` extension?

### Issue: Dark mode not working

**Check:**
1. System dark mode is enabled?
2. Using `@Environment(\.colorScheme)` in components?
3. Colors using adaptive variants (e.g., `.notateGhost` vs hardcoded)?

---

## Verification Checklist

After integration, verify:

- [ ] App builds without errors
- [ ] Capture toast appears after typing trigger
- [ ] Entry cards use new design (accent bar visible)
- [ ] Entry selection shows colored border
- [ ] Hover effects work smoothly
- [ ] Dark mode switches properly
- [ ] Processing animation (neural pulse) works
- [ ] TODO completion shows confirmation dialog
- [ ] Completed TODOs cannot be unchecked
- [ ] All buttons use new NotateButton style
- [ ] Typography uses new design system fonts
- [ ] Shadows consistent across cards

---

## Next Steps After Integration

Once integrated and tested:

1. **Remove old components:**
   - Delete `ModernTodoCard`
   - Delete `ModernThoughtCard`
   - Keep `ModernDesignSystem` for now (gradual migration)

2. **Update other views:**
   - Archive view
   - Entry detail view
   - Settings view

3. **Move to Phase 2:**
   - Implement TODO completion finality
   - Add AI action auto-execution
   - Implement tagging system

---

## Estimated Time

- **Minimum integration:** 30 minutes
- **With optional enhancements:** 1 hour
- **Full migration of all views:** 2-3 hours

---

## Support

If you encounter issues:

1. **Check file locations:** All files should be in correct directories
2. **Verify imports:** Make sure all new files are in Xcode project
3. **Review console:** Look for Swift compiler errors
4. **Compare with documentation:** See `/META/PHASE1_COMPLETION_SUMMARY.md`

---

**Ready to integrate? Start with Step 1!**

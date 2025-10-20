import SwiftUI
import AppKit

/// Unified timer popup window that handles all timer states
/// - Event name input (when ;;; typed with no name)
/// - Tag selection (after name confirmed or when name provided)
/// - Running timer status (when timer is active)
/// - Timer conflict resolution (when trying to start while one is running)
/// - Event completion/editing (after timer stopped)
class TimerPopupWindow: NSPanel {

    enum PopupMode {
        case eventNameInput(completion: (String) -> Void)
        case tagSelection(eventName: String, completion: ([String]) -> Void)
        case runningTimer(eventName: String, tags: [String], startTime: Date, onStop: () -> Void)
        case conflict(currentEventName: String, currentTags: [String], currentDuration: TimeInterval, newEventName: String?, completion: (Bool) -> Void)
        case eventCompletion(eventName: String, tags: [String], duration: TimeInterval, completion: (String) -> Void)
    }

    // Override to allow window to become key and main
    override var canBecomeKey: Bool { return true }
    override var canBecomeMain: Bool { return true }

    init(mode: PopupMode) {
        // Determine height based on mode
        let height: CGFloat
        switch mode {
        case .tagSelection:
            height = 384 // 320 * 1.2 = 384 (20% increase)
        case .conflict:
            height = 384 // 320 * 1.2 = 384 (20% increase)
        default:
            height = 320
        }

        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: height),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        // Panel configuration (NSPanel better supports appearing over fullscreen)
        self.title = ""
        self.titlebarAppearsTransparent = true
        self.isMovableByWindowBackground = true
        self.isFloatingPanel = true

        // Adjust key behavior based on mode
        switch mode {
        case .eventNameInput:
            self.becomesKeyOnlyIfNeeded = true // Don't steal focus
        default:
            self.becomesKeyOnlyIfNeeded = false // Can become key for interaction
        }

        // Use mainMenu + 1 level - appears above menus and fullscreen windows
        self.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.mainMenuWindow)) + 2)
        self.isReleasedWhenClosed = false
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        self.hidesOnDeactivate = false
        self.worksWhenModal = true

        // CRITICAL: Make window accept mouse and keyboard events
        self.ignoresMouseEvents = false
        self.acceptsMouseMovedEvents = true

        // Center on screen
        self.center()

        // Set content view based on mode
        let contentView = TimerPopupContentView(mode: mode, window: self)
        self.contentView = NSHostingView(rootView: contentView)

        // CRITICAL: Order front BEFORE activating to ensure it appears
        self.orderFrontRegardless()

        // Only activate app for certain modes
        // Don't activate for event name input only (popup can still work without activation)
        let shouldActivateApp: Bool
        switch mode {
        case .eventNameInput:
            shouldActivateApp = false // Keep user in their current app
        case .tagSelection, .runningTimer, .conflict, .eventCompletion:
            shouldActivateApp = true // These need keyboard/mouse input
        }

        if shouldActivateApp {
            // Make only THIS window visible, not the entire app
            self.orderFrontRegardless()
            self.makeKey()

            // Activate app to make window interactive
            NSApp.activate(ignoringOtherApps: true)

            // Hide all other Notate windows except this popup
            DispatchQueue.main.async {
                for window in NSApp.windows {
                    if window != self && window.isVisible && window.canBecomeKey {
                        window.orderOut(nil)
                    }
                }

                // Make this window first responder
                self.makeFirstResponder(self.contentView)

                // Bring popup back to front
                self.orderFrontRegardless()
            }
        } else {
            // Just make the window key without activating the app
            self.makeKey()
        }
    }
}

/// Main content view that switches between different modes
struct TimerPopupContentView: View {
    let mode: TimerPopupWindow.PopupMode
    let window: NSWindow

    var body: some View {
        Group {
            switch mode {
            case .eventNameInput(let completion):
                EventNameInputView(window: window, completion: completion)
            case .tagSelection(let eventName, let completion):
                TagSelectionView(eventName: eventName, window: window, completion: completion)
            case .runningTimer(let eventName, let tags, let startTime, let onStop):
                RunningTimerView(eventName: eventName, tags: tags, startTime: startTime, window: window, onStop: onStop)
            case .conflict(let currentEventName, let currentTags, let currentDuration, let newEventName, let completion):
                TimerConflictView(currentEventName: currentEventName, currentTags: currentTags, currentDuration: currentDuration, newEventName: newEventName, window: window, completion: completion)
            case .eventCompletion(let eventName, let tags, let duration, let completion):
                EventCompletionView(eventName: eventName, tags: tags, duration: duration, window: window, completion: completion)
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - Event Name Input View

struct EventNameInputView: View {
    let window: NSWindow
    let completion: (String) -> Void

    @State private var eventName: String = ""
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack(spacing: 8) {
                Text("🍅")
                    .font(.system(size: 24))
                Text("New Timer Event")
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)

            Divider()

            // Event name input
            VStack(alignment: .leading, spacing: 8) {
                Text("Event name:")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)

                TextField("e.g., zoom with vic", text: $eventName)
                    .textFieldStyle(.plain)
                    .font(.system(size: 16))
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(NSColor.controlBackgroundColor))
                    )
                    .focused($isInputFocused)

                Text("Press Enter to continue (can be empty)")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)

            Spacer()

            // Footer
            HStack {
                Text("⏎ Continue")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)

                Spacer()

                Text("⎋ Cancel")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .onAppear {
            isInputFocused = true
        }
        .onKeyPress(.escape) {
            window.close()
            NSApp.hide(nil)
            return .handled
        }
        .onKeyPress(.return) {
            completion(eventName.trimmingCharacters(in: .whitespacesAndNewlines))
            return .handled
        }
    }
}

// MARK: - Tag Selection View (Reused from previous implementation)

struct TagSelectionView: View {
    let eventName: String
    let window: NSWindow
    let completion: ([String]) -> Void

    @StateObject private var tagStore = TagStore.shared
    private let tagColorManager = TagColorManager.shared
    @State private var searchText: String = ""
    @State private var selectedTags: Set<String> = []
    @State private var quickTags: [String] = []
    @FocusState private var isSearchFocused: Bool

    // Computed property for filtered tags based on search text
    private var filteredTags: [String] {
        if searchText.isEmpty {
            return []
        }
        return tagStore.searchTags(searchText, excluding: Array(selectedTags))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 8) {
                Text("🏷️")
                    .font(.system(size: 24))
                Text("Select Tags:")
                    .font(.system(size: 16, weight: .semibold))
                Text(eventName.isEmpty ? "(no name)" : eventName)
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 24) // Increased from 16
            .padding(.bottom, 16)

            Divider()

            // Quick tags (only show when no search)
            if searchText.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Quick tags (click to select):")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)

                    let rows = stride(from: 0, to: min(quickTags.count, 9), by: 3).map {
                        Array(quickTags[$0..<min($0 + 3, quickTags.count)])
                    }

                    ForEach(Array(rows.enumerated()), id: \.offset) { rowIndex, rowTags in
                        HStack(spacing: 12) {
                            ForEach(Array(rowTags.enumerated()), id: \.offset) { tagIndex, tag in
                                quickTagButton(tag: tag)
                            }
                            Spacer()
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }

            // Search/Custom tag input
            VStack(alignment: .leading, spacing: 8) {
                Text("Type tag name + Enter to add, or search existing:")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)

                TextField("Enter tag name or search...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(NSColor.controlBackgroundColor))
                    )
                    .focused($isSearchFocused)
                    .onSubmit {
                        handleCustomTagEntry()
                    }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)

            // Filtered tags (show when typing)
            if !searchText.isEmpty && !filteredTags.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(filteredTags, id: \.self) { tag in
                            filteredTagButton(tag: tag)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .frame(maxHeight: 120)
                .padding(.top, 8)
            }

            // Selected tags (no label, just pills)
            if !selectedTags.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(Array(selectedTags), id: \.self) { tag in
                        tagPill(tag)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
            }

            Spacer()

            // Footer
            HStack {
                Text(searchText.isEmpty ? "⏎ Finish" : "⏎ Add '\(searchText)' tag")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Spacer()
                Text("⎋ Finish & Save")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24) // Increased from 16
        }
        .onAppear {
            loadQuickTags()
            isSearchFocused = true
        }
        .onKeyPress(.escape) {
            // Escape finishes tag selection and proceeds
            completion(Array(selectedTags))
            window.close()
            NSApp.hide(nil)
            return .handled
        }
    }

    private func handleCustomTagEntry() {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            // Add the custom tag
            selectedTags.insert(trimmed)
            // Clear search field
            searchText = ""
        } else if isSearchFocused {
            // If search field is empty and Enter pressed, finish tag selection
            completion(Array(selectedTags))
            window.close()
            NSApp.hide(nil)
        }
    }

    private func quickTagButton(tag: String) -> some View {
        let isSelected = selectedTags.contains(tag)
        let tagColor = tagColorManager.colorForTag(tag)

        return Button(action: { toggleTag(tag) }) {
            Text("#\(tag)")
                .font(.system(size: 13))
                .foregroundColor(isSelected ? tagColor : .primary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isSelected ? tagColor.opacity(0.1) : Color.clear)
                )
        }
        .buttonStyle(.plain)
    }

    private func filteredTagButton(tag: String) -> some View {
        let isSelected = selectedTags.contains(tag)
        let tagColor = tagColorManager.colorForTag(tag)

        return Button(action: { toggleTag(tag) }) {
            HStack {
                Text("#\(tag)")
                    .font(.system(size: 13))
                    .foregroundColor(isSelected ? tagColor : .primary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(tagColor)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? tagColor.opacity(0.1) : Color(NSColor.controlBackgroundColor))
            )
        }
        .buttonStyle(.plain)
    }

    private func tagPill(_ tag: String) -> some View {
        let tagColor = tagColorManager.colorForTag(tag)

        return HStack(spacing: 4) {
            Text("#\(tag)")
                .font(.system(size: 12))
                .foregroundColor(tagColor)
            Button(action: { selectedTags.remove(tag) }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 10))
                    .foregroundColor(tagColor.opacity(0.7))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(tagColor.opacity(0.15))
        .cornerRadius(4)
    }

    private func loadQuickTags() {
        quickTags = tagStore.getTopTags(limit: 9)
    }

    private func toggleTag(_ tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
    }
}

// MARK: - Running Timer View

struct RunningTimerView: View {
    let eventName: String
    let tags: [String]
    let startTime: Date
    let window: NSWindow
    let onStop: () -> Void

    @StateObject private var operatorState = OperatorState.shared
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?

    var body: some View {
        ZStack {
            // Sliding background effect (similar to TomatoTimerBanner)
            slidingBarBackground

            VStack(spacing: 20) {
                // Header
                HStack(spacing: 8) {
                    Text("🍅")
                        .font(.system(size: 24))
                    Text("Timer Running")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 32) // Increased from 20

                Divider()
                    .background(Color.white.opacity(0.3))

                // Timer display
                VStack(spacing: 12) {
                    Text(eventName.isEmpty ? "(no name)" : eventName)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)

                    Text(formattedDuration)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)

                    if !tags.isEmpty {
                        FlowLayout(spacing: 6) {
                            ForEach(tags, id: \.self) { tag in
                                Text("#\(tag)")
                                    .font(.system(size: 13))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.white.opacity(0.2))
                                    .foregroundColor(.white)
                                    .cornerRadius(4)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)

                Spacer()

                // Action buttons
                HStack(spacing: 12) {
                    Button(action: {
                        window.close()
                        NSApp.hide(nil)
                    }) {
                        HStack(spacing: 4) {
                            Text("⎋")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.7))
                            Text("Close")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                    .keyboardShortcut(.escape, modifiers: [])
                    .buttonStyle(.plain)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(8)

                    Button(action: {
                        stopTimerAndEdit()
                    }) {
                        HStack(spacing: 4) {
                            Text("⏎")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.7))
                            Text("Stop Timer")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                    .keyboardShortcut(.return, modifiers: [])
                    .buttonStyle(.plain)
                    .background(Color.white.opacity(0.3))
                    .cornerRadius(8)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
        }
        .onAppear {
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
        .focusable()
    }

    private var slidingBarBackground: some View {
        GeometryReader { geometry in
            ZStack {
                Color(hex: "#8B3A3A").opacity(0.4)

                // Sliding bar
                Rectangle()
                    .fill(Color(hex: "#C0392B"))
                    .frame(width: 8)
                    .offset(x: animationOffset(geometry: geometry))
            }
        }
        .ignoresSafeArea()
    }

    @State private var animationProgress: CGFloat = 0

    private func animationOffset(geometry: GeometryProxy) -> CGFloat {
        return geometry.size.width * animationProgress
    }

    private var formattedDuration: String {
        let hours = Int(elapsedTime) / 3600
        let minutes = (Int(elapsedTime) % 3600) / 60
        let seconds = Int(elapsedTime) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    private func startTimer() {
        elapsedTime = Date().timeIntervalSince(startTime)
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            elapsedTime = Date().timeIntervalSince(startTime)
        }

        // Start sliding animation
        withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) {
            animationProgress = 1.0
        }
    }

    private func stopTimerAndEdit() {
        window.close()
        NSApp.hide(nil)
        onStop()
    }
}

// MARK: - Timer Conflict View

struct TimerConflictView: View {
    let currentEventName: String
    let currentTags: [String]
    let currentDuration: TimeInterval
    let newEventName: String?
    let window: NSWindow
    let completion: (Bool) -> Void

    var body: some View {
        VStack(spacing: 20) {
            // Warning header
            HStack(spacing: 8) {
                Text("⚠️")
                    .font(.system(size: 24))
                Text("Timer Already Running")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.orange)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 32)

            Divider()

            // Current timer info
            VStack(alignment: .leading, spacing: 12) {
                Text("Current timer:")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)

                VStack(alignment: .leading, spacing: 8) {
                    Text(currentEventName.isEmpty ? "(no name)" : currentEventName)
                        .font(.system(size: 16, weight: .medium))

                    Text(formattedDuration(currentDuration))
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)

                    if !currentTags.isEmpty {
                        Text(currentTags.map { "#\($0)" }.joined(separator: " "))
                            .font(.system(size: 13))
                            .foregroundColor(.blue)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
            .padding(.horizontal, 20)

            // Message
            Text("Stop current timer to start a new one?")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .padding(.horizontal, 20)

            if let newName = newEventName, !newName.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("New event:")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Text(newName)
                        .font(.system(size: 14))
                }
                .padding(.horizontal, 20)
            }

            Spacer()

            // Action buttons
            HStack(spacing: 12) {
                Button(action: {
                    window.close()
                    NSApp.hide(nil)
                    completion(false)
                }) {
                    HStack(spacing: 4) {
                        Text("⎋")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        Text("Cancel")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .keyboardShortcut(.escape, modifiers: [])
                .buttonStyle(.plain)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)

                Button(action: {
                    window.close()
                    completion(true)
                }) {
                    HStack(spacing: 4) {
                        Text("⏎")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                        Text("Stop & Start New")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .keyboardShortcut(.return, modifiers: [])
                .buttonStyle(.plain)
                .background(Color.orange)
                .cornerRadius(8)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .focusable()
    }

    private func formattedDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        return String(format: "%02dh%02dm", hours, minutes)
    }
}

// MARK: - Event Completion View

struct EventCompletionView: View {
    let eventName: String
    let tags: [String]
    let duration: TimeInterval
    let window: NSWindow
    let completion: (String) -> Void

    @State private var editedEventName: String
    @FocusState private var isInputFocused: Bool

    init(eventName: String, tags: [String], duration: TimeInterval, window: NSWindow, completion: @escaping (String) -> Void) {
        self.eventName = eventName
        self.tags = tags
        self.duration = duration
        self.window = window
        self.completion = completion
        self._editedEventName = State(initialValue: eventName)
    }

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack(spacing: 8) {
                Text("✅")
                    .font(.system(size: 24))
                Text("Timer Stopped")
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)

            Divider()

            // Duration
            Text(formattedDuration)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.green)

            // Event name editing
            VStack(alignment: .leading, spacing: 8) {
                Text("Event name:")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)

                TextField("Edit event name", text: $editedEventName)
                    .textFieldStyle(.plain)
                    .font(.system(size: 16))
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(NSColor.controlBackgroundColor))
                    )
                    .focused($isInputFocused)
            }
            .padding(.horizontal, 20)

            // Tags
            if !tags.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tags:")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)

                    FlowLayout(spacing: 6) {
                        ForEach(tags, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.system(size: 13))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }

            Spacer()

            // Footer
            HStack {
                Text("⏎ Save & Close")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .onAppear {
            isInputFocused = true
        }
        .onKeyPress(.return) {
            completion(editedEventName.trimmingCharacters(in: .whitespacesAndNewlines))
            window.close()
            NSApp.hide(nil)
            return .handled
        }
    }

    private var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        return String(format: "%02dh%02dm", hours, minutes)
    }
}

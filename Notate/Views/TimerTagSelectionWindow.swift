import SwiftUI
import AppKit

/// Lightweight popup window for keyboard-only timer tag selection
/// Appears when user types ;;;event name
class TimerTagSelectionWindow: NSWindow {

    init(eventName: String) {
        // Create window with appropriate size and style
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 300),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        // Window configuration
        self.title = ""
        self.titlebarAppearsTransparent = true
        self.isMovableByWindowBackground = true
        self.level = .floating
        self.isReleasedWhenClosed = false

        // Center on screen
        self.center()

        // Set content view
        let contentView = TimerTagSelectionView(eventName: eventName, window: self)
        self.contentView = NSHostingView(rootView: contentView)

        // Make key and order front
        self.makeKeyAndOrderFront(nil)
    }
}

/// SwiftUI view for tag selection interface
struct TimerTagSelectionView: View {
    let eventName: String
    let window: NSWindow

    @StateObject private var tagStore = TagStore.shared
    @StateObject private var operatorState = OperatorState.shared
    @StateObject private var calendarService = CalendarService.shared

    @State private var searchText: String = ""
    @State private var selectedTags: Set<String> = []
    @State private var quickTags: [String] = []
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection

            Divider()

            // Quick tags (1-9)
            quickTagsSection
                .padding(.horizontal, 20)
                .padding(.top, 16)

            // Search input
            searchSection
                .padding(.horizontal, 20)
                .padding(.top, 12)

            // Selected tags display
            if !selectedTags.isEmpty {
                selectedTagsSection
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
            }

            Spacer()

            // Footer instructions
            footerSection
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
        }
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            loadQuickTags()
            isSearchFocused = true
        }
        .onKeyPress(.escape) {
            cancelSelection()
            return .handled
        }
        .onKeyPress(.return) {
            startTimer()
            return .handled
        }
        .onKeyPress { press in
            // Handle number keys 1-9
            if let char = press.characters.first,
               char.isNumber,
               let number = Int(String(char)),
               number >= 1 && number <= 9 {
                handleNumberKey(String(char))
                return .handled
            }
            return .ignored
        }
    }

    private var headerSection: some View {
        HStack(spacing: 8) {
            Text("🍅")
                .font(.system(size: 24))
            Text("Start Timer:")
                .font(.system(size: 16, weight: .semibold))
            Text(eventName)
                .font(.system(size: 16))
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    private var quickTagsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quick tags (press 1-9):")
                .font(.system(size: 12))
                .foregroundColor(.secondary)

            // Display tags in rows of 3
            let rows = stride(from: 0, to: min(quickTags.count, 9), by: 3).map {
                Array(quickTags[$0..<min($0 + 3, quickTags.count)])
            }

            ForEach(Array(rows.enumerated()), id: \.offset) { rowIndex, rowTags in
                HStack(spacing: 12) {
                    ForEach(Array(rowTags.enumerated()), id: \.offset) { tagIndex, tag in
                        let number = rowIndex * 3 + tagIndex + 1
                        quickTagButton(number: number, tag: tag)
                    }
                    Spacer()
                }
            }
        }
    }

    private func quickTagButton(number: Int, tag: String) -> some View {
        let isSelected = selectedTags.contains(tag)

        return HStack(spacing: 4) {
            Text("\(number)")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(isSelected ? .white : .secondary)
                .frame(width: 16, height: 16)
                .background(isSelected ? Color.blue : Color.clear)
                .clipShape(Circle())

            Text("#\(tag)")
                .font(.system(size: 13))
                .foregroundColor(isSelected ? .blue : .primary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        )
    }

    private var searchSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Or type to search:")
                .font(.system(size: 12))
                .foregroundColor(.secondary)

            TextField("Search tags...", text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(NSColor.controlBackgroundColor))
                )
                .focused($isSearchFocused)
                .onChange(of: searchText) { _, newValue in
                    handleSearchTextChange(newValue)
                }

            // Show filtered tags if searching
            if !searchText.isEmpty {
                filteredTagsView
            }
        }
    }

    private var filteredTagsView: some View {
        let filtered = tagStore.searchTags(searchText, excluding: Array(selectedTags))
            .prefix(5)

        return VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(filtered), id: \.self) { tag in
                Button(action: {
                    toggleTag(tag)
                    searchText = ""
                }) {
                    HStack {
                        Text("#\(tag)")
                            .font(.system(size: 13))
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                .cornerRadius(4)
            }
        }
    }

    private var selectedTagsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Selected tags:")
                .font(.system(size: 12))
                .foregroundColor(.secondary)

            FlowLayout(spacing: 6) {
                ForEach(Array(selectedTags), id: \.self) { tag in
                    HStack(spacing: 4) {
                        Text("#\(tag)")
                            .font(.system(size: 12))
                        Button(action: {
                            selectedTags.remove(tag)
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 10))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(4)
                }
            }
        }
    }

    private var footerSection: some View {
        HStack {
            Text("⏎ Start Timer")
                .font(.system(size: 12))
                .foregroundColor(.secondary)

            Spacer()

            Text("⎋ Cancel")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Actions

    private func loadQuickTags() {
        quickTags = tagStore.getTopTags(limit: 9)
    }

    private func handleNumberKey(_ char: String) {
        guard let number = Int(char), number >= 1, number <= quickTags.count else {
            return
        }

        let tag = quickTags[number - 1]
        toggleTag(tag)
    }

    private func toggleTag(_ tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
    }

    private func handleSearchTextChange(_ text: String) {
        // If user types a complete tag and presses space, add it
        if text.hasSuffix(" ") {
            let trimmed = text.trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty {
                let tagName = trimmed.hasPrefix("#") ? String(trimmed.dropFirst()) : trimmed
                selectedTags.insert(tagName)
                searchText = ""
            }
        }
    }

    private func startTimer() {
        // Start timer with selected tags
        operatorState.timerEventName = eventName
        operatorState.timerTags = Array(selectedTags)
        operatorState.startTimer()

        // Close window
        window.close()

        print("🍅 Timer started: \(eventName), tags: \(selectedTags)")
    }

    private func cancelSelection() {
        window.close()
        print("⎋ Timer tag selection cancelled")
    }
}

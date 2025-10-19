// ContentView.swift (iOS)
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @State private var selectedTab = 0
    @State private var showingQuickCapture = false

    var body: some View {
        if horizontalSizeClass == .regular {
            // iPad: Use NavigationSplitView (similar to macOS)
            iPadLayout
        } else {
            // iPhone: Use TabView
            iPhoneLayout
        }
    }

    // MARK: - iPhone Layout

    private var iPhoneLayout: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: All Entries
            NavigationStack {
                EntryListView(filterType: .all)
                    .navigationTitle("All")
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            quickCaptureButton
                        }
                    }
            }
            .tabItem {
                Label("All", systemImage: "tray.fill")
            }
            .tag(0)

            // Tab 2: TODOs
            NavigationStack {
                EntryListView(filterType: .todos)
                    .navigationTitle("TODOs")
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            quickCaptureButton
                        }
                    }
            }
            .tabItem {
                Label("TODOs", systemImage: "checkmark.circle.fill")
            }
            .tag(1)

            // Tab 3: Pieces
            NavigationStack {
                EntryListView(filterType: .pieces)
                    .navigationTitle("Pieces")
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            quickCaptureButton
                        }
                    }
            }
            .tabItem {
                Label("Pieces", systemImage: "lightbulb.fill")
            }
            .tag(2)

            // Tab 4: Settings
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
            .tag(3)
        }
        .sheet(isPresented: $showingQuickCapture) {
            QuickCaptureView()
        }
    }

    // MARK: - iPad Layout

    private var iPadLayout: some View {
        NavigationSplitView {
            // Sidebar
            SidebarView(selectedTab: $selectedTab)
        } content: {
            // Entry List
            EntryListView(filterType: currentFilterType)
                .navigationTitle(currentFilterType.displayName)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        quickCaptureButton
                    }
                }
        } detail: {
            // Entry Detail
            if let selectedEntry = appState.selectedEntry {
                EntryDetailView(entry: selectedEntry)
            } else {
                emptyDetailView
            }
        }
        .sheet(isPresented: $showingQuickCapture) {
            QuickCaptureView()
        }
    }

    // MARK: - Helpers

    private var currentFilterType: FilterType {
        switch selectedTab {
        case 0: return .all
        case 1: return .todos
        case 2: return .pieces
        default: return .all
        }
    }

    private var quickCaptureButton: some View {
        Button {
            showingQuickCapture = true
        } label: {
            Image(systemName: "plus.circle.fill")
                .font(.title2)
        }
    }

    private var emptyDetailView: some View {
        VStack(spacing: ModernDesignSystem.Spacing.large) {
            Image(systemName: "arrow.left")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(ModernDesignSystem.Colors.secondary.opacity(0.6))

            Text("Select an entry")
                .font(ModernDesignSystem.Typography.title)
                .fontWeight(.semibold)
                .foregroundColor(ModernDesignSystem.Colors.primary)

            Text("Tap any entry to view details and AI insights")
                .font(ModernDesignSystem.Typography.body)
                .foregroundColor(ModernDesignSystem.Colors.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)
        }
    }
}

// MARK: - Supporting Views

struct SidebarView: View {
    @Binding var selectedTab: Int

    var body: some View {
        List(selection: $selectedTab) {
            Label("All", systemImage: "tray.fill")
                .tag(0)

            Label("TODOs", systemImage: "checkmark.circle.fill")
                .tag(1)

            Label("Pieces", systemImage: "lightbulb.fill")
                .tag(2)

            Section("More") {
                Label("Archive", systemImage: "archivebox.fill")
                    .tag(4)

                Label("Settings", systemImage: "gearshape.fill")
                    .tag(3)
            }
        }
        .navigationTitle("Notate")
    }
}

enum FilterType {
    case all, todos, pieces

    var displayName: String {
        switch self {
        case .all: return "All"
        case .todos: return "TODOs"
        case .pieces: return "Pieces"
        }
    }
}

struct EntryListView: View {
    let filterType: FilterType
    @EnvironmentObject var appState: AppState

    var body: some View {
        List(filteredEntries) { entry in
            NavigationLink(value: entry) {
                EntryRowView(entry: entry)
            }
        }
        .navigationDestination(for: Entry.self) { entry in
            EntryDetailView(entry: entry)
        }
        .refreshable {
            appState.forceRefreshEntries()
        }
    }

    private var filteredEntries: [Entry] {
        let allEntries = appState.entries

        switch filterType {
        case .all:
            return allEntries.filter { entry in
                entry.isThought || entry.isPiece || (entry.isTodo && entry.status == .open)
            }
        case .todos:
            return allEntries.filter { $0.isTodo && $0.status == .open }
        case .pieces:
            return allEntries.filter { $0.isPiece || $0.isThought }
        }
    }
}

struct EntryRowView: View {
    let entry: Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                EntryTypeBadge(type: entry.type, size: .small)

                if entry.isTodo {
                    Image(systemName: entry.status == .done ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(entry.status == .done ? .green : .secondary)
                }

                Spacer()

                Text(entry.formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(entry.content)
                .font(.body)
                .lineLimit(2)
                .foregroundColor(.primary)

            if entry.hasAIProcessing {
                HStack(spacing: 4) {
                    Image(systemName: "brain.head.profile")
                        .font(.caption)
                        .foregroundColor(.blue)

                    Text("AI Processed")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct QuickCaptureView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    @State private var content = ""
    @State private var isTodo = false
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Toggle("TODO", isOn: $isTodo)
                    .padding()

                TextEditor(text: $content)
                    .focused($isFocused)
                    .frame(minHeight: 200)
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding()

                Spacer()
            }
            .navigationTitle("Quick Capture")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveEntry()
                    }
                    .disabled(content.isEmpty)
                }
            }
            .onAppear {
                isFocused = true
            }
        }
    }

    private func saveEntry() {
        let entry = Entry.createQuickCapture(
            content: content,
            trigger: "quick-capture",
            sourceApp: "Notate iOS"
        )

        var finalEntry = entry
        if isTodo {
            finalEntry = finalEntry.convertToTodo()
        }

        appState.databaseManager.saveEntry(finalEntry)
        dismiss()
    }
}

// MARK: - Entry Type Badge

struct EntryTypeBadge: View {
    let type: EntryType
    let size: BadgeSize

    enum BadgeSize {
        case small, medium

        var fontSize: CGFloat {
            switch self {
            case .small: return 10
            case .medium: return 12
            }
        }

        var padding: CGFloat {
            switch self {
            case .small: return 4
            case .medium: return 6
            }
        }
    }

    var body: some View {
        Text(type.displayName)
            .font(.system(size: size.fontSize, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, size.padding + 4)
            .padding(.vertical, size.padding)
            .background(type.color)
            .clipShape(Capsule())
    }
}

extension EntryType {
    var color: Color {
        switch self {
        case .todo: return .blue
        case .thought: return .purple
        case .piece: return .orange
        }
    }

    var displayName: String {
        switch self {
        case .todo: return "TODO"
        case .thought: return "Thought"
        case .piece: return "Piece"
        }
    }
}

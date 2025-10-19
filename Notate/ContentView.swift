import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab: AppTab = .timeline
    @State private var showingSettings: Bool = false

    enum AppTab {
        case timeline
        case list
        case analysis
    }

    private var archivedEntries: [Entry] {
        appState.entries.filter { $0.isTodo && $0.status == .done }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Main content area
            ZStack(alignment: .topTrailing) {
                Group {
                    switch selectedTab {
                    case .timeline:
                        TimelineView()
                            .environmentObject(appState)
                    case .list:
                        ListView()
                            .environmentObject(appState)
                    case .analysis:
                        InsightsView()
                            .environmentObject(appState)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Floating settings icon
                floatingSettingsButton
                    .padding(.top, 16)
                    .padding(.trailing, 16)
            }

            // Bottom navigation bar
            bottomNavigationBar
        }
        .background(Color(hex: "#1C1C1E"))
        .preferredColorScheme(.dark)
        .onReceive(NotificationCenter.default.publisher(for: .notateDidFinishCapture)) { note in
            if let result = note.object as? CaptureResult {
                // Use new notification service for toast
                if let entry = appState.entries.first(where: { $0.content == result.content }) {
                    NotificationService.shared.showCapture(entry: entry)
                }
            }
        }
        .overlay(alignment: .bottomLeading) {
            ToastOverlay()
                .padding(.leading, NotateDesignSystem.Spacing.space5)
                .padding(.bottom, 80) // Above bottom nav
        }
        .overlay {
            settingsModalSheet
        }
    }

    // MARK: - Bottom Navigation Bar

    private var bottomNavigationBar: some View {
        HStack(spacing: 0) {
            // Timeline tab
            bottomNavButton(
                icon: "calendar",
                title: "Timeline",
                tab: .timeline
            )

            // List tab
            bottomNavButton(
                icon: "list.bullet",
                title: "List",
                tab: .list
            )

            // Analysis tab
            bottomNavButton(
                icon: "chart.bar.fill",
                title: "Analysis",
                tab: .analysis
            )
        }
        .padding(.vertical, 12)
        .background(Color(hex: "#2C2C2E"))
        .overlay(
            Rectangle()
                .fill(Color(hex: "#3A3A3C"))
                .frame(height: 0.5),
            alignment: .top
        )
    }

    private var floatingSettingsButton: some View {
        Button(action: {
            showSettingsModal()
        }) {
            Image(systemName: "gear")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(Color(hex: "#2C2C2E").opacity(0.7))
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
                )
        }
        .buttonStyle(.plain)
    }

    private func bottomNavButton(icon: String, title: String, tab: AppTab) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = tab
            }
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(selectedTab == tab ? .notateNeuralBlue : .secondary)

                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(selectedTab == tab ? .notateNeuralBlue : .secondary)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func showSettingsModal() {
        showingSettings = true
    }
}

// MARK: - Settings Modal Sheet Extension

extension ContentView {
    @ViewBuilder
    var settingsModalSheet: some View {
        if showingSettings {
            ZStack {
                // Dimmed backdrop
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture {
                        showingSettings = false
                    }

                // Settings sheet
                ZStack(alignment: .topTrailing) {
                    // Settings content (embed existing SettingsView)
                    SettingsView()
                        .environmentObject(appState)

                    // Floating close button
                    Button(action: {
                        showingSettings = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 16)
                    .padding(.trailing, 16)
                }
                .frame(width: 700, height: 650)
                .background(Color(hex: "#1C1C1E"))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
            }
        }
    }
}

// Remove all old code below - not needed with new timeline design
/*
    // Old Custom Toolbar
    private var customToolbar: some View {
        HStack {
            // Left side - App title and icon
            HStack(spacing: ModernDesignSystem.Spacing.small) {
                Text("Notate")
                    .font(ModernDesignSystem.Typography.title)
                    .fontWeight(.bold)
                    .foregroundColor(ModernDesignSystem.Colors.primary)

                Image(systemName: "brain.head.profile")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(ModernDesignSystem.Colors.accent)
            }

            Spacer()

            // Right side - Settings button
            ModernButton(
                title: "Settings",
                icon: "gear",
                style: .ghost,
                size: .medium
            ) {
                showingSettings = true
            }
        }
        .padding(.horizontal, ModernDesignSystem.Spacing.large)
        .padding(.vertical, ModernDesignSystem.Spacing.medium)
        .background(ModernDesignSystem.Colors.windowBackground)
        .overlay(
            Rectangle()
                .fill(ModernDesignSystem.Colors.border)
                .frame(height: 1),
            alignment: .bottom
        )
    }

    private var headerView: some View {
        ModernCard(
            padding: ModernDesignSystem.Spacing.regular,
            cornerRadius: ModernDesignSystem.CornerRadius.medium,
            shadowIntensity: ModernDesignSystem.Shadow.minimal
        ) {
            VStack(spacing: ModernDesignSystem.Spacing.medium) {
                // Modern search bar
                HStack(spacing: ModernDesignSystem.Spacing.small) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(ModernDesignSystem.Colors.secondary)

                    TextField("Search entries...", text: $appState.searchQuery)
                        .font(ModernDesignSystem.Typography.body)
                        .textFieldStyle(PlainTextFieldStyle())

                    if !appState.searchQuery.isEmpty {
                        ModernButton(
                            title: "Clear",
                            style: .ghost,
                            size: .small
                        ) {
                            appState.searchQuery = ""
                        }
                    }
                }
                .padding(.horizontal, ModernDesignSystem.Spacing.medium)
                .padding(.vertical, ModernDesignSystem.Spacing.small)
                .background(
                    RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.small)
                        .fill(ModernDesignSystem.Colors.surfaceSecondary)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.small)
                        .stroke(ModernDesignSystem.Colors.border, lineWidth: 1)
                )

                // Modern filter row
                HStack(spacing: ModernDesignSystem.Spacing.medium) {
                    HStack(spacing: ModernDesignSystem.Spacing.small) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(ModernDesignSystem.Colors.secondary)

                        Text("Filter:")
                            .font(ModernDesignSystem.Typography.small)
                            .foregroundColor(ModernDesignSystem.Colors.secondary)
                            .fontWeight(.medium)
                    }

                    Picker("Filter", selection: $appState.selectedFilter) {
                        ForEach(AppState.FilterType.allCases, id: \.self) { filter in
                            Text(filter.displayName).tag(filter)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(maxWidth: 150)

                    Spacer()

                    // Modern entry count badge
                    HStack(spacing: ModernDesignSystem.Spacing.tiny) {
                        Image(systemName: "number")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(ModernDesignSystem.Colors.accent)

                        Text("\(appState.filteredEntries().count)")
                            .font(ModernDesignSystem.Typography.small)
                            .foregroundColor(ModernDesignSystem.Colors.accent)
                            .fontWeight(.semibold)

                        Text("entries")
                            .font(ModernDesignSystem.Typography.small)
                            .foregroundColor(ModernDesignSystem.Colors.secondary)
                    }
                    .padding(.horizontal, ModernDesignSystem.Spacing.small)
                    .padding(.vertical, ModernDesignSystem.Spacing.tiny)
                    .background(
                        RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.small)
                            .fill(ModernDesignSystem.Colors.accent.opacity(0.1))
                    )
                }
            }
        }
        .padding(.horizontal, ModernDesignSystem.Spacing.regular)
        .padding(.top, ModernDesignSystem.Spacing.small)
    }
    
    private var tabSelectionView: some View {
        HStack(spacing: ModernDesignSystem.Spacing.tiny) {
            ForEach(AppState.TabSelection.allCases, id: \.self) { tab in
                modernTabButton(for: tab)
            }
        }
        .padding(.horizontal, ModernDesignSystem.Spacing.regular)
        .padding(.vertical, ModernDesignSystem.Spacing.small)
    }

    private func modernTabButton(for tab: AppState.TabSelection) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                appState.selectedTab = tab
            }
        }) {
            Text(tabDisplayName(for: tab))
                .font(ModernDesignSystem.Typography.small)
                .fontWeight(.medium)
                .foregroundColor(
                    appState.selectedTab == tab
                        ? ModernDesignSystem.Colors.surface
                        : ModernDesignSystem.Colors.secondary
                )
                .padding(.horizontal, ModernDesignSystem.Spacing.medium)
                .padding(.vertical, ModernDesignSystem.Spacing.small)
                .background(
                    RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.small)
                        .fill(
                            appState.selectedTab == tab
                                ? ModernDesignSystem.Colors.accent
                                : ModernDesignSystem.Colors.surfaceSecondary
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func tabDisplayName(for tab: AppState.TabSelection) -> String {
        switch tab {
        case .archive:
            let count = appState.getArchiveCount()
            return count > 0 ? "Archive (\(count))" : "Archive"
        default:
            return tab.displayName
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        let filteredEntries = appState.filteredEntries()
        
        if filteredEntries.isEmpty {
            emptyStateView
        } else {
            switch appState.selectedTab {
            case .all:
                allEntriesView
            case .todos:
                let todos = filteredEntries.filter { $0.isTodo }
                if todos.isEmpty {
                    emptyTodosView
                } else {
                    TodoListView(todos: todos)
                }
            case .thoughts:
                let thoughts = filteredEntries.filter { $0.isPiece }
                if thoughts.isEmpty {
                    emptyPiecesView
                } else {
                    ThoughtCardView(thoughts: thoughts)
                }
            case .archive:
                let archivedTodos = filteredEntries.filter { $0.isTodo && $0.status == EntryStatus.done }
                if archivedTodos.isEmpty {
                    emptyArchiveView
                } else {
                    ArchiveListView(archivedTodos: archivedTodos)
                }
            }
        }
    }
    
    private var allEntriesView: some View {
        ScrollView {
            LazyVStack(spacing: NotateDesignSystem.Spacing.space3) {
                let todos = appState.filteredEntries().filter { $0.isTodo }
                let thoughts = appState.filteredEntries().filter { $0.isPiece }

                if !todos.isEmpty {
                    // Section header
                    Text("TODOs (\(todos.count))")
                        .font(.notateH3)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, NotateDesignSystem.Spacing.space4)

                    ForEach(todos) { todo in
                        NotateEntryCard(entry: todo)
                            .environmentObject(appState)
                    }
                }

                if !thoughts.isEmpty {
                    Text("Pieces (\(thoughts.count))")
                        .font(.notateH3)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, NotateDesignSystem.Spacing.space4)
                        .padding(.top, NotateDesignSystem.Spacing.space4)

                    ForEach(thoughts) { thought in
                        NotateEntryCard(entry: thought)
                            .environmentObject(appState)
                    }
                }
            }
            .padding(.horizontal, NotateDesignSystem.Spacing.space4)
            .padding(.vertical, NotateDesignSystem.Spacing.space3)
        }
        .background(Color.notateGhost)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: ModernDesignSystem.Spacing.large) {
            VStack(spacing: ModernDesignSystem.Spacing.medium) {
                Image(systemName: "tray")
                    .font(.system(size: 64, weight: .light))
                    .foregroundColor(ModernDesignSystem.Colors.secondary.opacity(0.6))

                Text("No entries found")
                    .font(ModernDesignSystem.Typography.title)
                    .fontWeight(.semibold)
                    .foregroundColor(ModernDesignSystem.Colors.primary)
            }

            VStack(spacing: ModernDesignSystem.Spacing.medium) {
                if !appState.searchQuery.isEmpty {
                    Text("Try adjusting your search or filter")
                        .font(ModernDesignSystem.Typography.body)
                        .foregroundColor(ModernDesignSystem.Colors.secondary)
                        .multilineTextAlignment(.center)

                    ModernButton(
                        title: "Clear Search",
                        icon: "xmark.circle",
                        style: .secondary,
                        size: .medium
                    ) {
                        appState.searchQuery = ""
                    }
                } else {
                    VStack(spacing: ModernDesignSystem.Spacing.small) {
                        Text("Start capturing ideas and tasks")
                            .font(ModernDesignSystem.Typography.body)
                            .foregroundColor(ModernDesignSystem.Colors.secondary)
                            .multilineTextAlignment(.center)

                        Text("Type triggers like /// or ,,, followed by your content")
                            .font(ModernDesignSystem.Typography.small)
                            .foregroundColor(ModernDesignSystem.Colors.secondary.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ModernDesignSystem.Colors.surfaceBackground)
    }
    
    private var emptyTodosView: some View {
        VStack(spacing: ModernDesignSystem.Spacing.large) {
            VStack(spacing: ModernDesignSystem.Spacing.medium) {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 64, weight: .light))
                    .foregroundColor(ModernDesignSystem.Colors.accent.opacity(0.6))

                Text("No TODOs found")
                    .font(ModernDesignSystem.Typography.title)
                    .fontWeight(.semibold)
                    .foregroundColor(ModernDesignSystem.Colors.primary)
            }

            Text("Use triggers like /// or ;; to capture actionable tasks")
                .font(ModernDesignSystem.Typography.body)
                .foregroundColor(ModernDesignSystem.Colors.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ModernDesignSystem.Colors.surfaceBackground)
    }
    
    private var emptyPiecesView: some View {
        VStack(spacing: ModernDesignSystem.Spacing.large) {
            VStack(spacing: ModernDesignSystem.Spacing.medium) {
                Image(systemName: "lightbulb")
                    .font(.system(size: 64, weight: .light))
                    .foregroundColor(ModernDesignSystem.Colors.warning.opacity(0.6))

                Text("No pieces found")
                    .font(ModernDesignSystem.Typography.title)
                    .fontWeight(.semibold)
                    .foregroundColor(ModernDesignSystem.Colors.primary)
            }

            Text("Use triggers like ,,, to capture ideas and insights")
                .font(ModernDesignSystem.Typography.body)
                .foregroundColor(ModernDesignSystem.Colors.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ModernDesignSystem.Colors.surfaceBackground)
    }

    private var emptyArchiveView: some View {
        VStack(spacing: ModernDesignSystem.Spacing.large) {
            VStack(spacing: ModernDesignSystem.Spacing.medium) {
                Image(systemName: "archivebox")
                    .font(.system(size: 64, weight: .light))
                    .foregroundColor(ModernDesignSystem.Colors.secondary.opacity(0.6))

                Text("No completed TODOs")
                    .font(ModernDesignSystem.Typography.title)
                    .fontWeight(.semibold)
                    .foregroundColor(ModernDesignSystem.Colors.primary)
            }

            VStack(spacing: ModernDesignSystem.Spacing.small) {
                Text("Completed TODOs will automatically appear here")
                    .font(ModernDesignSystem.Typography.body)
                    .foregroundColor(ModernDesignSystem.Colors.secondary)
                    .multilineTextAlignment(.center)

                if appState.getArchiveCount() == 0 {
                    Text("Complete a TODO to see archive in action!")
                        .font(ModernDesignSystem.Typography.small)
                        .foregroundColor(ModernDesignSystem.Colors.secondary.opacity(0.8))
                        .padding(.top, ModernDesignSystem.Spacing.small)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ModernDesignSystem.Colors.surfaceBackground)
    }

    private func captureToastView(result: CaptureResult) -> some View {
        ModernCard(
            padding: ModernDesignSystem.Spacing.regular,
            cornerRadius: ModernDesignSystem.CornerRadius.medium,
            shadowIntensity: ModernDesignSystem.Shadow.medium
        ) {
            VStack(spacing: ModernDesignSystem.Spacing.small) {
                HStack(spacing: ModernDesignSystem.Spacing.small) {
                    Image(systemName: result.type == EntryType.todo ? "checkmark.circle.fill" : "lightbulb.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(result.type == EntryType.todo ? ModernDesignSystem.Colors.success : ModernDesignSystem.Colors.warning)

                    Text("Captured \(result.type.displayName)")
                        .font(ModernDesignSystem.Typography.body)
                        .fontWeight(.semibold)
                        .foregroundColor(ModernDesignSystem.Colors.primary)

                    Spacer()

                    Text("Just now")
                        .font(ModernDesignSystem.Typography.tiny)
                        .foregroundColor(ModernDesignSystem.Colors.secondary)
                        .padding(.horizontal, ModernDesignSystem.Spacing.small)
                        .padding(.vertical, ModernDesignSystem.Spacing.tiny)
                        .background(
                            RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.small)
                                .fill(ModernDesignSystem.Colors.surfaceSecondary)
                        )
                }

                Text(result.content)
                    .font(ModernDesignSystem.Typography.small)
                    .foregroundColor(ModernDesignSystem.Colors.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack {
                    HStack(spacing: ModernDesignSystem.Spacing.tiny) {
                        Image(systemName: "keyboard")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(ModernDesignSystem.Colors.accent)

                        Text("\(result.triggerUsed)")
                            .font(ModernDesignSystem.Typography.tiny)
                            .foregroundColor(ModernDesignSystem.Colors.accent)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, ModernDesignSystem.Spacing.small)
                    .padding(.vertical, ModernDesignSystem.Spacing.tiny)
                    .background(
                        RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.small)
                            .fill(ModernDesignSystem.Colors.accent.opacity(0.1))
                    )

                    Spacer()
                }
            }
        }
        .padding(.horizontal, ModernDesignSystem.Spacing.regular)
        .padding(.bottom, ModernDesignSystem.Spacing.large)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}
*/

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var showToast = false
    @State private var showingSettings = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with search and filter
                headerView

                // Tab selection
                tabSelectionView

                // Content area
                contentView
                    .background(ModernDesignSystem.Colors.surfaceBackground)
            }
            .background(ModernDesignSystem.Colors.surfaceBackground)
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: ModernDesignSystem.Spacing.small) {
                        Text("Notate")
                            .font(ModernDesignSystem.Typography.title)
                            .fontWeight(.bold)
                            .foregroundColor(ModernDesignSystem.Colors.primary)

                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(ModernDesignSystem.Colors.accent)
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    ModernButton(
                        title: "Settings",
                        icon: "gear",
                        style: .ghost,
                        size: .medium
                    ) {
                        showingSettings = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environmentObject(appState)
        }
        .onReceive(NotificationCenter.default.publisher(for: .notateDidFinishCapture)) { note in
            if let result = note.object as? CaptureResult {
                withAnimation { showToast = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation { showToast = false }
                }
            }
        }
        .overlay(alignment: .bottom) {
            if showToast, let result = appState.lastCaptureResult {
                captureToastView(result: result)
            }
        }
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
                let thoughts = filteredEntries.filter { $0.isThought }
                if thoughts.isEmpty {
                    emptyThoughtsView
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
        List {
            let todos = appState.filteredEntries().filter { $0.isTodo }
            let thoughts = appState.filteredEntries().filter { $0.isThought }
            
            if !todos.isEmpty {
                Section("TODOs (\(todos.count))") {
                    ForEach(todos) { todo in
                        ModernTodoRowView(todo: todo)
                            .swipeActions(allowsFullSwipe: false) {
                                Button("Convert to Thought") {
                                    appState.convertTodoToThought(todo)
                                }
                                .tint(.blue)

                                Button("Delete", role: .destructive) {
                                    appState.deleteEntry(todo)
                                }
                                
                                if todo.status == EntryStatus.open {
                                    Button("Done") {
                                        appState.markTodoAsDone(todo)
                                    }
                                    .tint(.green)
                                }
                            }
                    }
                }
            }
            
            if !thoughts.isEmpty {
                Section("Thoughts (\(thoughts.count))") {
                    ForEach(thoughts) { thought in
                        ThoughtRowView(thought: thought)
                            .swipeActions(allowsFullSwipe: false) {
                                Button("Delete", role: .destructive) {
                                    appState.deleteEntry(thought)
                                }
                                
                                Button("Convert to TODO") {
                                    appState.convertThoughtToTodo(thought)
                                }
                                .tint(.blue)
                            }
                    }
                }
            }
        }
        .listStyle(PlainListStyle())
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
    
    private var emptyThoughtsView: some View {
        VStack(spacing: ModernDesignSystem.Spacing.large) {
            VStack(spacing: ModernDesignSystem.Spacing.medium) {
                Image(systemName: "lightbulb")
                    .font(.system(size: 64, weight: .light))
                    .foregroundColor(ModernDesignSystem.Colors.warning.opacity(0.6))

                Text("No thoughts found")
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

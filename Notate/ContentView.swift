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
            }
            .navigationTitle("Notate")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Settings") {
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
        VStack(spacing: 12) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search entries...", text: $appState.searchQuery)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !appState.searchQuery.isEmpty {
                    Button("Clear") {
                        appState.searchQuery = ""
                    }
                    .font(.caption)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(NSColor.systemGray))
            .cornerRadius(8)
            
            // Filter picker
            HStack {
                Text("Filter:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Picker("Filter", selection: $appState.selectedFilter) {
                    ForEach(AppState.FilterType.allCases, id: \.self) { filter in
                        Text(filter.displayName).tag(filter)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(maxWidth: 150)
                
                Spacer()
                
                // Entry count
                Text("\(appState.filteredEntries().count) entries")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private var tabSelectionView: some View {
        Picker("Tab", selection: $appState.selectedTab) {
            ForEach(AppState.TabSelection.allCases, id: \.self) { tab in
                Text(tab.displayName).tag(tab)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal)
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
                        TodoRowView(todo: todo)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
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
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
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
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No entries found")
                .font(.title2)
                .fontWeight(.medium)
            
            if !appState.searchQuery.isEmpty {
                Text("Try adjusting your search or filter")
                    .foregroundColor(.secondary)
                
                Button("Clear Search") {
                    appState.searchQuery = ""
                }
            } else {
                Text("Start capturing by typing a trigger like /// or ,,, followed by your content")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyTodosView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No TODOs found")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Use triggers like /// or ;; to capture actionable tasks")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyThoughtsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "lightbulb")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No thoughts found")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Use triggers like ,,, to capture ideas and insights")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func captureToastView(result: CaptureResult) -> some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: result.type == EntryType.todo ? "checkmark.circle.fill" : "lightbulb.fill")
                    .foregroundColor(result.type == EntryType.todo ? .green : .orange)
                
                Text("Captured \(result.type.displayName)")
                    .fontWeight(.medium)
                
                Spacer()
            }
            
            Text(result.content)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            HStack {
                Text("Trigger: \(result.triggerUsed)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Just now")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.bottom, 24)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

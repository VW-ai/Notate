import SwiftUI

struct ArchiveListView: View {
    let archivedTodos: [Entry]
    @EnvironmentObject var appState: AppState
    @State private var showingClearConfirmation = false

    var body: some View {
        VStack(spacing: 0) {
            // Archive header with clear button
            archiveHeader

            // Archive list
            List {
                ForEach(archivedTodos) { archivedTodo in
                    ArchivedTodoRowView(todo: archivedTodo)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button("Restore") {
                                appState.restoreFromArchive(archivedTodo)
                            }
                            .tint(.blue)

                            Button("Delete Forever", role: .destructive) {
                                appState.permanentlyDeleteFromArchive(archivedTodo)
                            }
                        }
                }
            }
            .listStyle(PlainListStyle())
        }
    }

    private var archiveHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Archive")
                    .font(.headline)
                    .fontWeight(.semibold)

                Text("\(archivedTodos.count) completed TODOs")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if !archivedTodos.isEmpty {
                Button("Clear All") {
                    showingClearConfirmation = true
                }
                .font(.caption)
                .foregroundColor(.red)
                .confirmationDialog(
                    "Clear Archive",
                    isPresented: $showingClearConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Delete All (\(archivedTodos.count) items)", role: .destructive) {
                        appState.clearArchive()
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This will permanently delete all completed TODOs. This action cannot be undone.")
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

struct ArchivedTodoRowView: View {
    let todo: Entry
    @EnvironmentObject var appState: AppState
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Completed checkbox (disabled)
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 4) {
                    // Content (with strikethrough)
                    Text(todo.content)
                        .strikethrough(true)
                        .foregroundColor(.secondary)
                        .lineLimit(isExpanded ? nil : 2)

                    // Metadata
                    HStack {
                        Text("Completed: \(todo.formattedDate)")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if let priority = todo.priority {
                            Text("•")
                                .foregroundColor(.secondary)
                                .font(.caption)

                            Text(priority.displayName)
                                .font(.caption)
                                .foregroundColor(priorityColor(priority))
                        }

                        if !todo.tags.isEmpty {
                            Text("•")
                                .foregroundColor(.secondary)
                                .font(.caption)

                            Text(todo.displayTags)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }

                Spacer()

                // Expand/collapse button
                Button(action: { isExpanded.toggle() }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                .buttonStyle(PlainButtonStyle())
            }

            // Show metadata if expanded
            if isExpanded && (!todo.tags.isEmpty || todo.triggerUsed != "") {
                VStack(alignment: .leading, spacing: 4) {
                    if !todo.tags.isEmpty {
                        Text("Tags: \(todo.displayTags)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Text("Captured with: \(todo.triggerUsed)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.leading, 40) // Align with content
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            isExpanded.toggle()
        }
    }

    private func priorityColor(_ priority: EntryPriority) -> Color {
        switch priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .green
        }
    }
}

#Preview {
    let sampleArchived = Entry(
        type: .todo,
        content: "Sample completed TODO that was archived",
        triggerUsed: "///",
        status: .done,
        priority: .high
    )

    ArchiveListView(archivedTodos: [sampleArchived])
        .environmentObject(AppState())
}
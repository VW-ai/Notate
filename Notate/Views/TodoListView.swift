import SwiftUI

struct TodoListView: View {
    let todos: [Entry]
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        List {
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
                        } else {
                            Button("Reopen") {
                                appState.markTodoAsOpen(todo)
                            }
                            .tint(.orange)
                        }
                    }
            }
        }
        .listStyle(PlainListStyle())
    }
}

struct TodoRowView: View {
    let todo: Entry
    @EnvironmentObject var appState: AppState
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Checkbox
                Button(action: {
                    if todo.status == EntryStatus.open {
                        appState.markTodoAsDone(todo)
                    } else {
                        appState.markTodoAsOpen(todo)
                    }
                }) {
                    Image(systemName: todo.status == EntryStatus.done ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(todo.status == EntryStatus.done ? .green : .gray)
                        .font(.title2)
                }
                .buttonStyle(PlainButtonStyle())
                
                VStack(alignment: .leading, spacing: 4) {
                    // Content
                    Text(todo.content)
                        .strikethrough(todo.status == EntryStatus.done)
                        .foregroundColor(todo.status == EntryStatus.done ? .secondary : .primary)
                        .lineLimit(isExpanded ? nil : 2)
                    
                    // Metadata
                    HStack {
                        // Priority indicator
                        if let priority = todo.priority {
                            PriorityBadge(priority: priority)
                        }
                        
                        // Status badge
                        StatusBadge(status: todo.status)
                        
                        // Tags
                        if !todo.tags.isEmpty {
                            ForEach(todo.tags.prefix(3), id: \.self) { tag in
                                TagBadge(tag: tag)
                            }
                            
                            if todo.tags.count > 3 {
                                Text("+\(todo.tags.count - 3)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        // Date
                        Text(todo.formattedDate)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Expand button
                Button(action: { isExpanded.toggle() }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Expanded content
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                    
                    // Additional metadata
                    HStack {
                        Text("Trigger: \(todo.triggerUsed)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if let sourceApp = todo.sourceApp {
                            Text("• \(sourceApp)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // All tags
                    if !todo.tags.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Tags:")
                                .font(.caption)
                                .fontWeight(.medium)
                            
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 4) {
                                ForEach(todo.tags, id: \.self) { tag in
                                    TagBadge(tag: tag)
                                }
                            }
                        }
                    }
                    
                    // Actions
                    HStack {
                        Button("Edit Priority") {
                            // TODO: Implement priority editing
                        }
                        .font(.caption)
                        
                        Spacer()
                        
                        Button("Convert to Thought") {
                            appState.convertTodoToThought(todo)
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                        
                        Button("Delete", role: .destructive) {
                            appState.deleteEntry(todo)
                        }
                        .font(.caption)
                    }
                }
                .padding(.leading, 40) // Align with content
            }
        }
        .padding(.vertical, 4)
    }
}

struct PriorityBadge: View {
    let priority: EntryPriority
    
    var body: some View {
        Text(priority.displayName)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(priorityColor.opacity(0.2))
            .foregroundColor(priorityColor)
            .cornerRadius(4)
    }
    
    private var priorityColor: Color {
        switch priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .green
        }
    }
}

struct StatusBadge: View {
    let status: EntryStatus
    
    var body: some View {
        Text(status.displayName)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(statusColor.opacity(0.2))
            .foregroundColor(statusColor)
            .cornerRadius(4)
    }
    
    private var statusColor: Color {
        switch status {
        case .open: return .blue
        case .done: return .green
        }
    }
}

struct TagBadge: View {
    let tag: String
    
    var body: some View {
        Text(tag)
            .font(.caption)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.blue.opacity(0.1))
            .foregroundColor(.blue)
            .cornerRadius(4)
    }
}

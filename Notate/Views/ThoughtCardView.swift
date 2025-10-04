import SwiftUI

struct ThoughtCardView: View {
    let thoughts: [Entry]
    @EnvironmentObject var appState: AppState
    
    private let columns = [
        GridItem(.adaptive(minimum: 300), spacing: 16)
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(thoughts) { thought in
                    ThoughtCard(thought: thought)
                }
            }
            .padding()
        }
    }
}

struct ThoughtCard: View {
    let thought: Entry
    @EnvironmentObject var appState: AppState
    @State private var isExpanded = false
    @State private var isPinned = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("💭")
                        .font(.title2)
                    
                    Text(thought.formattedDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Pin button
                Button(action: { isPinned.toggle() }) {
                    Image(systemName: isPinned ? "pin.fill" : "pin")
                        .foregroundColor(isPinned ? .orange : .secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Content
            Text(thought.content)
                .font(.body)
                .lineLimit(isExpanded ? nil : 4)
                .multilineTextAlignment(.leading)
            
            // Tags
            if !thought.tags.isEmpty {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 4) {
                    ForEach(thought.tags, id: \.self) { tag in
                        TagBadge(tag: tag)
                    }
                }
            }
            
            // Metadata
            HStack {
                Text("Trigger: \(thought.triggerUsed)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let sourceApp = thought.sourceApp {
                    Text("• \(sourceApp)")
                        .font(.caption)
                        .foregroundColor(.secondary)
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
                Divider()
                
                // Actions
                HStack {
                    Button("Convert to TODO") {
                        appState.convertThoughtToTodo(thought)
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Button("Delete", role: .destructive) {
                        appState.deleteEntry(thought)
                    }
                    .font(.caption)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isPinned ? Color.orange : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Compact Thought View for List
struct ThoughtRowView: View {
    let thought: Entry
    @EnvironmentObject var appState: AppState
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("💭")
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(thought.content)
                        .lineLimit(isExpanded ? nil : 2)
                    
                    HStack {
                        if !thought.tags.isEmpty {
                            ForEach(thought.tags.prefix(2), id: \.self) { tag in
                                TagBadge(tag: tag)
                            }
                            
                            if thought.tags.count > 2 {
                                Text("+\(thought.tags.count - 2)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        Text(thought.formattedDate)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button(action: { isExpanded.toggle() }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            if isExpanded {
                Divider()
                
                HStack {
                    Text("Trigger: \(thought.triggerUsed)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let sourceApp = thought.sourceApp {
                        Text("• \(sourceApp)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button("Convert to TODO") {
                        appState.convertThoughtToTodo(thought)
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                    
                    Button("Delete", role: .destructive) {
                        appState.deleteEntry(thought)
                    }
                    .font(.caption)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

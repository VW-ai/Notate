import SwiftUI

struct TodoListView: View {
    let todos: [Entry]
    @EnvironmentObject var appState: AppState

    var body: some View {
        ScrollView {
            LazyVStack(spacing: ModernDesignSystem.Spacing.medium) {
                ForEach(todos) { todo in
                    ModernTodoCard(todo: todo)
                        .environmentObject(appState)
                }
            }
            .padding(.horizontal, ModernDesignSystem.Spacing.regular)
            .padding(.vertical, ModernDesignSystem.Spacing.small)
        }
        .background(ModernDesignSystem.Colors.surfaceBackground)
    }
}

struct ModernTodoCard: View {
    let todo: Entry
    @EnvironmentObject var appState: AppState

    var body: some View {
        ModernCard(
            padding: ModernDesignSystem.Spacing.regular,
            cornerRadius: ModernDesignSystem.CornerRadius.medium,
            shadowIntensity: isCompleted ? ModernDesignSystem.Shadow.subtle : ModernDesignSystem.Shadow.light
        ) {
            VStack(spacing: ModernDesignSystem.Spacing.medium) {
                // Main content row
                HStack(spacing: ModernDesignSystem.Spacing.medium) {
                    // Completion checkbox
                    completionButton

                    // Content
                    VStack(alignment: .leading, spacing: ModernDesignSystem.Spacing.tiny) {
                        Text(todo.content)
                            .font(ModernDesignSystem.Typography.body)
                            .foregroundColor(isCompleted ? ModernDesignSystem.Colors.secondary : ModernDesignSystem.Colors.primary)
                            .strikethrough(isCompleted)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)

                        // Quick metadata
                        quickMetadataRow
                    }

                    Spacer()

                    // Priority indicator
                    if let priority = todo.priority {
                        PriorityIndicator(priority: priority, style: .dots)
                    }
                }

                // Selection indicator
                if appState.selectedEntry?.id == todo.id {
                    HStack {
                        Rectangle()
                            .fill(ModernDesignSystem.Colors.accent)
                            .frame(height: 2)
                        Spacer()
                    }
                }
            }
        }
        .opacity(isCompleted ? 0.7 : 1.0)
        .background(
            RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.medium)
                .stroke(ModernDesignSystem.Colors.accent, lineWidth: isSelected ? 2 : 0)
                .background(
                    RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.medium)
                        .fill(isSelected ? ModernDesignSystem.Colors.accent.opacity(0.05) : Color.clear)
                )
        )
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                appState.selectedEntry = todo
            }
        }
    }

    private var completionButton: some View {
        Button(action: toggleCompletion) {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(isCompleted ? ModernDesignSystem.Colors.completedColor : ModernDesignSystem.Colors.secondary)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var quickMetadataRow: some View {
        HStack(spacing: ModernDesignSystem.Spacing.small) {
            Text(todo.formattedDate)
                .font(ModernDesignSystem.Typography.tiny)
                .foregroundColor(ModernDesignSystem.Colors.secondary)

            if let priority = todo.priority {
                Text("•")
                    .font(ModernDesignSystem.Typography.tiny)
                    .foregroundColor(ModernDesignSystem.Colors.secondary)

                PriorityIndicator(priority: priority, style: .badge)
            }

            Spacer()

            EntryTypeBadge(type: todo.type, size: .small)
        }
    }


    private var isCompleted: Bool {
        todo.status == .done
    }

    private var isSelected: Bool {
        appState.selectedEntry?.id == todo.id
    }

    private func toggleCompletion() {
        withAnimation(.easeInOut(duration: 0.3)) {
            if isCompleted {
                appState.markTodoAsOpen(todo)
            } else {
                appState.markTodoAsDone(todo)
            }
        }
    }
}

// MARK: - Modern Todo Row for List View
struct ModernTodoRowView: View {
    let todo: Entry
    @EnvironmentObject var appState: AppState

    var body: some View {
        ModernCard(
            padding: ModernDesignSystem.Spacing.medium,
            cornerRadius: ModernDesignSystem.CornerRadius.small,
            shadowIntensity: ModernDesignSystem.Shadow.minimal
        ) {
            VStack(alignment: .leading, spacing: ModernDesignSystem.Spacing.small) {
                HStack(spacing: ModernDesignSystem.Spacing.medium) {
                    // Completion checkbox
                    Button(action: toggleCompletion) {
                        Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(isCompleted ? ModernDesignSystem.Colors.success : ModernDesignSystem.Colors.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())

                    // Content
                    VStack(alignment: .leading, spacing: ModernDesignSystem.Spacing.tiny) {
                        Text(todo.content)
                            .font(ModernDesignSystem.Typography.body)
                            .foregroundColor(isCompleted ? ModernDesignSystem.Colors.secondary : ModernDesignSystem.Colors.primary)
                            .strikethrough(isCompleted)
                            .lineLimit(2)

                        // Metadata row
                        HStack(spacing: ModernDesignSystem.Spacing.small) {
                            Text(todo.formattedDate)
                                .font(ModernDesignSystem.Typography.tiny)
                                .foregroundColor(ModernDesignSystem.Colors.secondary)

                            if let priority = todo.priority {
                                Text("•")
                                    .font(ModernDesignSystem.Typography.tiny)
                                    .foregroundColor(ModernDesignSystem.Colors.secondary)

                                PriorityIndicator(priority: priority, style: .dots)
                            }

                            Spacer()

                            if !todo.tags.isEmpty {
                                Text("\(todo.tags.count) tag\(todo.tags.count == 1 ? "" : "s")")
                                    .font(ModernDesignSystem.Typography.tiny)
                                    .foregroundColor(ModernDesignSystem.Colors.secondary)
                            }
                        }
                    }

                    Spacer()
                }
            }
        }
        .opacity(isCompleted ? 0.6 : 1.0)
        .background(
            RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.small)
                .stroke(ModernDesignSystem.Colors.accent, lineWidth: isSelected ? 2 : 0)
                .background(
                    RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.small)
                        .fill(isSelected ? ModernDesignSystem.Colors.accent.opacity(0.05) : Color.clear)
                )
        )
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                appState.selectedEntry = todo
            }
        }
    }

    private var isCompleted: Bool {
        todo.status == .done
    }

    private var isSelected: Bool {
        appState.selectedEntry?.id == todo.id
    }

    private func toggleCompletion() {
        withAnimation(.easeInOut(duration: 0.3)) {
            if isCompleted {
                appState.markTodoAsOpen(todo)
            } else {
                appState.markTodoAsDone(todo)
            }
        }
    }
}



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
    @State private var isExpanded = false
    @State private var showingActions = false

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
                            .lineLimit(isExpanded ? nil : 2)
                            .multilineTextAlignment(.leading)

                        // Quick metadata
                        quickMetadataRow
                    }

                    Spacer()

                    // Priority indicator and actions
                    VStack(spacing: ModernDesignSystem.Spacing.tiny) {
                        if let priority = todo.priority {
                            PriorityIndicator(priority: priority, style: .dots)
                        }

                        Button(action: { showingActions.toggle() }) {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(ModernDesignSystem.Colors.secondary)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }

                // Expanded metadata
                if isExpanded {
                    expandedMetadata
                }

                // Action buttons
                if showingActions {
                    actionButtons
                }
            }
        }
        .opacity(isCompleted ? 0.7 : 1.0)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                isExpanded.toggle()
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

    private var expandedMetadata: some View {
        VStack(alignment: .leading, spacing: ModernDesignSystem.Spacing.small) {
            if !todo.tags.isEmpty {
                HStack {
                    Image(systemName: "tag")
                        .font(.system(size: 12))
                        .foregroundColor(ModernDesignSystem.Colors.secondary)

                    Text(todo.displayTags)
                        .font(ModernDesignSystem.Typography.small)
                        .foregroundColor(ModernDesignSystem.Colors.secondary)
                }
            }

            HStack {
                Image(systemName: "keyboard")
                    .font(.system(size: 12))
                    .foregroundColor(ModernDesignSystem.Colors.secondary)

                Text("Captured with: \(todo.triggerUsed)")
                    .font(ModernDesignSystem.Typography.small)
                    .foregroundColor(ModernDesignSystem.Colors.secondary)
            }

            if let sourceApp = todo.sourceApp {
                HStack {
                    Image(systemName: "app")
                        .font(.system(size: 12))
                        .foregroundColor(ModernDesignSystem.Colors.secondary)

                    Text("From: \(sourceApp)")
                        .font(ModernDesignSystem.Typography.small)
                        .foregroundColor(ModernDesignSystem.Colors.secondary)
                }
            }
        }
        .padding(.top, ModernDesignSystem.Spacing.small)
    }

    private var actionButtons: some View {
        HStack(spacing: ModernDesignSystem.Spacing.small) {
            ModernButton(
                title: isCompleted ? "Reopen" : "Complete",
                icon: isCompleted ? "arrow.counterclockwise" : "checkmark",
                style: .secondary,
                size: .small
            ) {
                toggleCompletion()
            }

            ModernButton(
                title: "Convert",
                icon: "arrow.triangle.2.circlepath",
                style: .secondary,
                size: .small
            ) {
                appState.convertTodoToThought(todo)
                showingActions = false
            }

            Spacer()

            ModernButton(
                title: "Delete",
                icon: "trash",
                style: .destructive,
                size: .small
            ) {
                appState.deleteEntry(todo)
            }
        }
        .padding(.top, ModernDesignSystem.Spacing.small)
    }

    private var isCompleted: Bool {
        todo.status == .done
    }

    private func toggleCompletion() {
        withAnimation(.easeInOut(duration: 0.3)) {
            if isCompleted {
                appState.markTodoAsOpen(todo)
            } else {
                appState.markTodoAsDone(todo)
            }
            showingActions = false
        }
    }
}

// MARK: - Modern Todo Row for List View
struct ModernTodoRowView: View {
    let todo: Entry
    @EnvironmentObject var appState: AppState
    @State private var isExpanded = false

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
                            .lineLimit(isExpanded ? nil : 2)

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

                    // Expand button
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isExpanded.toggle()
                        }
                    }) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(ModernDesignSystem.Colors.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                // Expanded content
                if isExpanded && !todo.tags.isEmpty {
                    VStack(alignment: .leading, spacing: ModernDesignSystem.Spacing.small) {
                        Rectangle()
                            .fill(ModernDesignSystem.Colors.border)
                            .frame(height: 1)

                        HStack {
                            Image(systemName: "tag")
                                .font(.system(size: 12))
                                .foregroundColor(ModernDesignSystem.Colors.secondary)

                            Text("Tags")
                                .font(ModernDesignSystem.Typography.small)
                                .foregroundColor(ModernDesignSystem.Colors.secondary)
                                .fontWeight(.medium)
                        }

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: ModernDesignSystem.Spacing.tiny) {
                            ForEach(todo.tags, id: \.self) { tag in
                                ModernTagBadge(tag: tag)
                            }
                        }
                    }
                }
            }
        }
        .opacity(isCompleted ? 0.6 : 1.0)
    }

    private var isCompleted: Bool {
        todo.status == .done
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



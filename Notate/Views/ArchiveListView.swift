import SwiftUI

struct ArchiveListView: View {
    let archivedTodos: [Entry]
    @EnvironmentObject var appState: AppState
    @State private var showingClearConfirmation = false

    var body: some View {
        VStack(spacing: 0) {
            // Modern archive header
            modernArchiveHeader

            // Modern archive list
            ScrollView {
                LazyVStack(spacing: ModernDesignSystem.Spacing.small) {
                    ForEach(archivedTodos) { archivedTodo in
                        ModernArchivedTodoCard(todo: archivedTodo)
                            .environmentObject(appState)
                    }
                }
                .padding(.horizontal, ModernDesignSystem.Spacing.regular)
                .padding(.vertical, ModernDesignSystem.Spacing.small)
            }
            .background(ModernDesignSystem.Colors.surfaceBackground)
        }
        .background(ModernDesignSystem.Colors.surfaceBackground)
    }

    private var modernArchiveHeader: some View {
        ModernCard(
            padding: ModernDesignSystem.Spacing.regular,
            cornerRadius: ModernDesignSystem.CornerRadius.medium,
            shadowIntensity: ModernDesignSystem.Shadow.minimal
        ) {
            HStack(spacing: ModernDesignSystem.Spacing.medium) {
                // Archive icon and info
                HStack(spacing: ModernDesignSystem.Spacing.small) {
                    Image(systemName: "archivebox.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(ModernDesignSystem.Colors.secondary)

                    VStack(alignment: .leading, spacing: ModernDesignSystem.Spacing.tiny) {
                        Text("Archive")
                            .font(ModernDesignSystem.Typography.title)
                            .fontWeight(.bold)
                            .foregroundColor(ModernDesignSystem.Colors.primary)

                        Text("\(archivedTodos.count) completed TODOs")
                            .font(ModernDesignSystem.Typography.small)
                            .foregroundColor(ModernDesignSystem.Colors.secondary)
                    }
                }

                Spacer()

                // Clear all button
                if !archivedTodos.isEmpty {
                    ModernButton(
                        title: "Clear All",
                        icon: "trash.fill",
                        style: .destructive,
                        size: .small
                    ) {
                        showingClearConfirmation = true
                    }
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
        }
        .padding(.horizontal, ModernDesignSystem.Spacing.regular)
        .padding(.top, ModernDesignSystem.Spacing.small)
    }
}

struct ModernArchivedTodoCard: View {
    let todo: Entry
    @EnvironmentObject var appState: AppState
    @State private var isExpanded = false
    @State private var showingActions = false

    var body: some View {
        ModernCard(
            padding: ModernDesignSystem.Spacing.regular,
            cornerRadius: ModernDesignSystem.CornerRadius.medium,
            shadowIntensity: ModernDesignSystem.Shadow.light
        ) {
            VStack(spacing: ModernDesignSystem.Spacing.medium) {
                // Main content row
                HStack(spacing: ModernDesignSystem.Spacing.medium) {
                    // Completion status
                    VStack(spacing: ModernDesignSystem.Spacing.tiny) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(ModernDesignSystem.Colors.success)

                        Text("DONE")
                            .font(ModernDesignSystem.Typography.tiny)
                            .foregroundColor(ModernDesignSystem.Colors.success)
                            .fontWeight(.bold)
                    }

                    // Content and metadata
                    VStack(alignment: .leading, spacing: ModernDesignSystem.Spacing.tiny) {
                        Text(todo.content)
                            .font(ModernDesignSystem.Typography.body)
                            .foregroundColor(ModernDesignSystem.Colors.secondary)
                            .strikethrough(true)
                            .lineLimit(isExpanded ? nil : 2)
                            .multilineTextAlignment(.leading)

                        // Quick metadata row
                        HStack(spacing: ModernDesignSystem.Spacing.small) {
                            Text("Completed \(todo.formattedDate)")
                                .font(ModernDesignSystem.Typography.tiny)
                                .foregroundColor(ModernDesignSystem.Colors.secondary)

                            if let priority = todo.priority {
                                Text("•")
                                    .font(ModernDesignSystem.Typography.tiny)
                                    .foregroundColor(ModernDesignSystem.Colors.secondary)

                                PriorityIndicator(priority: priority, style: .badge)
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

                    // Controls
                    VStack(spacing: ModernDesignSystem.Spacing.tiny) {
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

                        Button(action: { showingActions.toggle() }) {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 12, weight: .medium))
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
        .opacity(0.8)
    }

    private var expandedMetadata: some View {
        VStack(alignment: .leading, spacing: ModernDesignSystem.Spacing.small) {
            Rectangle()
                .fill(ModernDesignSystem.Colors.border)
                .frame(height: 1)

            if !todo.tags.isEmpty {
                VStack(alignment: .leading, spacing: ModernDesignSystem.Spacing.small) {
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

            HStack {
                Image(systemName: "keyboard")
                    .font(.system(size: 12))
                    .foregroundColor(ModernDesignSystem.Colors.secondary)

                Text("Captured with: \(todo.triggerUsed)")
                    .font(ModernDesignSystem.Typography.small)
                    .foregroundColor(ModernDesignSystem.Colors.secondary)
            }
        }
    }

    private var actionButtons: some View {
        HStack(spacing: ModernDesignSystem.Spacing.small) {
            ModernButton(
                title: "Restore",
                icon: "arrow.uturn.backward",
                style: .secondary,
                size: .small
            ) {
                appState.restoreFromArchive(todo)
                showingActions = false
            }

            Spacer()

            ModernButton(
                title: "Delete Forever",
                icon: "trash.fill",
                style: .destructive,
                size: .small
            ) {
                appState.permanentlyDeleteFromArchive(todo)
            }
        }
        .padding(.top, ModernDesignSystem.Spacing.small)
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
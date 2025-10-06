import SwiftUI

struct ThoughtCardView: View {
    let thoughts: [Entry]
    @EnvironmentObject var appState: AppState

    private let columns = [
        GridItem(.adaptive(minimum: 320), spacing: ModernDesignSystem.Spacing.regular)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: ModernDesignSystem.Spacing.regular) {
                ForEach(thoughts) { thought in
                    ModernThoughtCard(thought: thought)
                        .environmentObject(appState)
                }
            }
            .padding(.horizontal, ModernDesignSystem.Spacing.regular)
            .padding(.vertical, ModernDesignSystem.Spacing.small)
        }
        .background(ModernDesignSystem.Colors.surfaceBackground)
    }
}

struct ModernThoughtCard: View {
    let thought: Entry
    @EnvironmentObject var appState: AppState
    @State private var isExpanded = false
    @State private var isPinned = false
    @State private var showingActions = false

    var body: some View {
        ModernCard(
            padding: ModernDesignSystem.Spacing.regular,
            cornerRadius: ModernDesignSystem.CornerRadius.medium,
            shadowIntensity: isPinned ? ModernDesignSystem.Shadow.medium : ModernDesignSystem.Shadow.light
        ) {
            VStack(spacing: ModernDesignSystem.Spacing.medium) {
                // Header row
                HStack(spacing: ModernDesignSystem.Spacing.medium) {
                    // Icon and type
                    VStack(spacing: ModernDesignSystem.Spacing.tiny) {
                        Text("💭")
                            .font(.system(size: 24))

                        Text("THOUGHT")
                            .font(ModernDesignSystem.Typography.tiny)
                            .foregroundColor(ModernDesignSystem.Colors.secondary)
                            .fontWeight(.medium)
                    }

                    // Content preview
                    VStack(alignment: .leading, spacing: ModernDesignSystem.Spacing.tiny) {
                        Text(thought.content)
                            .font(ModernDesignSystem.Typography.body)
                            .foregroundColor(ModernDesignSystem.Colors.primary)
                            .lineLimit(isExpanded ? nil : 3)
                            .multilineTextAlignment(.leading)

                        // Quick metadata
                        quickMetadataRow
                    }

                    Spacer()

                    // Controls
                    VStack(spacing: ModernDesignSystem.Spacing.tiny) {
                        // Pin button
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isPinned.toggle()
                            }
                        }) {
                            Image(systemName: isPinned ? "pin.fill" : "pin")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(isPinned ? ModernDesignSystem.Colors.accent : ModernDesignSystem.Colors.secondary)
                        }
                        .buttonStyle(PlainButtonStyle())

                        // Actions menu
                        Button(action: { showingActions.toggle() }) {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(ModernDesignSystem.Colors.secondary)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }

                // Tags section
                if !thought.tags.isEmpty {
                    tagsSection
                }

                // AI Suggestions section
                if thought.hasAIProcessing {
                    AISuggestionsInlineView(entry: thought)
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
        .overlay(
            RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.medium)
                .stroke(isPinned ? ModernDesignSystem.Colors.accent.opacity(0.3) : Color.clear, lineWidth: 2)
        )
        .scaleEffect(isPinned ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isPinned)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                isExpanded.toggle()
            }
        }
    }

    private var quickMetadataRow: some View {
        HStack(spacing: ModernDesignSystem.Spacing.small) {
            Text(thought.formattedDate)
                .font(ModernDesignSystem.Typography.tiny)
                .foregroundColor(ModernDesignSystem.Colors.secondary)

            Spacer()

            if !thought.tags.isEmpty {
                Text("•")
                    .font(ModernDesignSystem.Typography.tiny)
                    .foregroundColor(ModernDesignSystem.Colors.secondary)

                Text("\(thought.tags.count) tag\(thought.tags.count == 1 ? "" : "s")")
                    .font(ModernDesignSystem.Typography.tiny)
                    .foregroundColor(ModernDesignSystem.Colors.secondary)
            }
        }
    }

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: ModernDesignSystem.Spacing.small) {
            HStack {
                Image(systemName: "tag")
                    .font(.system(size: 12))
                    .foregroundColor(ModernDesignSystem.Colors.secondary)

                Text("Tags")
                    .font(ModernDesignSystem.Typography.small)
                    .foregroundColor(ModernDesignSystem.Colors.secondary)
                    .fontWeight(.medium)

                Spacer()
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: ModernDesignSystem.Spacing.tiny) {
                ForEach(thought.tags, id: \.self) { tag in
                    ModernTagBadge(tag: tag)
                }
            }
        }
        .padding(.top, ModernDesignSystem.Spacing.small)
    }

    private var expandedMetadata: some View {
        VStack(alignment: .leading, spacing: ModernDesignSystem.Spacing.small) {
            HStack {
                Image(systemName: "keyboard")
                    .font(.system(size: 12))
                    .foregroundColor(ModernDesignSystem.Colors.secondary)

                Text("Captured with: \(thought.triggerUsed)")
                    .font(ModernDesignSystem.Typography.small)
                    .foregroundColor(ModernDesignSystem.Colors.secondary)
            }

            if let sourceApp = thought.sourceApp {
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
                title: "Convert to TODO",
                icon: "arrow.triangle.2.circlepath",
                style: .secondary,
                size: .small
            ) {
                appState.convertThoughtToTodo(thought)
                showingActions = false
            }

            Spacer()

            ModernButton(
                title: "Delete",
                icon: "trash",
                style: .destructive,
                size: .small
            ) {
                appState.deleteEntry(thought)
            }
        }
        .padding(.top, ModernDesignSystem.Spacing.small)
    }
}

// MARK: - Modern Tag Badge Component
struct ModernTagBadge: View {
    let tag: String

    var body: some View {
        Text(tag)
            .font(ModernDesignSystem.Typography.tiny)
            .fontWeight(.medium)
            .foregroundColor(ModernDesignSystem.Colors.accent)
            .padding(.horizontal, ModernDesignSystem.Spacing.small)
            .padding(.vertical, ModernDesignSystem.Spacing.tiny)
            .background(
                RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.small)
                    .fill(ModernDesignSystem.Colors.accent.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.small)
                    .stroke(ModernDesignSystem.Colors.accent.opacity(0.2), lineWidth: 1)
            )
    }
}

// MARK: - Compact Thought View for List
struct ThoughtRowView: View {
    let thought: Entry
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
                    Text("💭")
                        .font(.system(size: 20))

                    VStack(alignment: .leading, spacing: ModernDesignSystem.Spacing.tiny) {
                        Text(thought.content)
                            .font(ModernDesignSystem.Typography.body)
                            .foregroundColor(ModernDesignSystem.Colors.primary)
                            .lineLimit(isExpanded ? nil : 2)

                        HStack {
                            if !thought.tags.isEmpty {
                                ForEach(thought.tags.prefix(2), id: \.self) { tag in
                                    ModernTagBadge(tag: tag)
                                }

                                if thought.tags.count > 2 {
                                    Text("+\(thought.tags.count - 2)")
                                        .font(ModernDesignSystem.Typography.tiny)
                                        .foregroundColor(ModernDesignSystem.Colors.secondary)
                                }
                            }

                            Spacer()

                            Text(thought.formattedDate)
                                .font(ModernDesignSystem.Typography.tiny)
                                .foregroundColor(ModernDesignSystem.Colors.secondary)
                        }
                    }

                    Spacer()

                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isExpanded.toggle()
                        }
                    }) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .foregroundColor(ModernDesignSystem.Colors.secondary)
                            .font(.system(size: 12, weight: .medium))
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                if isExpanded {
                    VStack(alignment: .leading, spacing: ModernDesignSystem.Spacing.small) {
                        Rectangle()
                            .fill(ModernDesignSystem.Colors.border)
                            .frame(height: 1)

                        HStack {
                            Text("Trigger: \(thought.triggerUsed)")
                                .font(ModernDesignSystem.Typography.small)
                                .foregroundColor(ModernDesignSystem.Colors.secondary)

                            if let sourceApp = thought.sourceApp {
                                Text("• \(sourceApp)")
                                    .font(ModernDesignSystem.Typography.small)
                                    .foregroundColor(ModernDesignSystem.Colors.secondary)
                            }

                            Spacer()

                            ModernButton(
                                title: "Convert",
                                style: .secondary,
                                size: .small
                            ) {
                                appState.convertThoughtToTodo(thought)
                            }

                            ModernButton(
                                title: "Delete",
                                style: .destructive,
                                size: .small
                            ) {
                                appState.deleteEntry(thought)
                            }
                        }
                    }
                }
            }
        }
    }
}

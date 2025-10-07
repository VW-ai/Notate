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

    var body: some View {
        ModernCard(
            padding: ModernDesignSystem.Spacing.regular,
            cornerRadius: ModernDesignSystem.CornerRadius.medium,
            shadowIntensity: ModernDesignSystem.Shadow.light
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
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)

                        // Quick metadata
                        quickMetadataRow
                    }

                    Spacer()

                }

                // Tags section
                if !thought.tags.isEmpty {
                    tagsSection
                }

                // Selection indicator
                if appState.selectedEntry?.id == thought.id {
                    HStack {
                        Rectangle()
                            .fill(ModernDesignSystem.Colors.accent)
                            .frame(height: 2)
                        Spacer()
                    }
                }
            }
        }
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
                appState.selectedEntry = thought
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

    private var isSelected: Bool {
        appState.selectedEntry?.id == thought.id
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
                            .lineLimit(2)

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
                }
            }
        }
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
                appState.selectedEntry = thought
            }
        }
    }

    private var isSelected: Bool {
        appState.selectedEntry?.id == thought.id
    }
}

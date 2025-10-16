import SwiftUI

// MARK: - Notate Entry Card
// Unified card component for both TODOs and Pieces

struct NotateEntryCard: View {
    let entry: Entry
    @EnvironmentObject var appState: AppState

    @Environment(\.colorScheme) private var colorScheme
    @State private var isHovering = false
    @State private var showCompletionConfirmation = false

    private var isProcessing: Bool {
        appState.processingEntryIds.contains(entry.id)
    }

    private var isSelected: Bool {
        appState.selectedEntry?.id == entry.id
    }

    var body: some View {
        HStack(spacing: 0) {
            // Accent bar (4px left edge)
            accentBar

            // Card content
            cardContent
                .padding(NotateDesignSystem.Spacing.space5)
        }
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: NotateDesignSystem.CornerRadius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: NotateDesignSystem.CornerRadius.medium)
                .stroke(isSelected ? entry.accentColor : Color.clear, lineWidth: 2)
        )
        .shadowSubtle(darkMode: colorScheme == .dark)
        .scaleEffect(isHovering ? 1.01 : 1.0)
        .animation(NotateDesignSystem.Animation.cardHover, value: isHovering)
        .onTapGesture { selectEntry() }
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
        .alert("Complete TODO?", isPresented: $showCompletionConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Complete") {
                completeTodo()
            }
        } message: {
            Text("This TODO will be moved to the Archive. Completed TODOs cannot be reopened.")
        }
    }

    // MARK: - Accent Bar

    private var accentBar: some View {
        Rectangle()
            .fill(entry.accentColor)
            .frame(width: 4)
            .neuralPulse(isActive: isProcessing)
    }

    // MARK: - Card Content

    private var cardContent: some View {
        HStack(spacing: NotateDesignSystem.Spacing.space4) {
            // Type-specific icon (checkbox for TODO, sparkle for Piece)
            typeIcon

            VStack(alignment: .leading, spacing: NotateDesignSystem.Spacing.space2) {
                // Content text
                contentText

                // Metadata row
                metadataRow
            }

            Spacer()

            // Right side: Processing badge or priority
            rightSideContent
        }
    }

    // MARK: - Type Icon

    @ViewBuilder
    private var typeIcon: some View {
        if entry.isTodo {
            // TODO: Checkbox
            Button(action: toggleCompletion) {
                Image(systemName: entry.status == .done ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(entry.status == .done ? .notateSuccessEmerald : .secondary)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(entry.status == .done) // Cannot undo completion
        } else {
            // Piece: Sparkle icon
            Image(systemName: "sparkles")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.notateThoughtPurple)
                .frame(width: 24, height: 24)
        }
    }

    // MARK: - Content Text

    private var contentText: some View {
        Text(entry.content)
            .font(.notateBody)
            .foregroundColor(entry.status == .done ? .secondary : .primary)
            .strikethrough(entry.status == .done)
            .lineLimit(2)
    }

    // MARK: - Metadata Row

    private var metadataRow: some View {
        HStack(spacing: NotateDesignSystem.Spacing.space2) {
            // Created date
            Text(entry.formattedDate)
                .font(.notateTiny)
                .foregroundColor(.secondary)

            // Priority (TODOs only)
            if entry.isTodo, let priority = entry.priority {
                Text("·")
                    .font(.notateTiny)
                    .foregroundColor(.secondary)

                // Priority dots
                HStack(spacing: 3) {
                    ForEach(0..<priority.level, id: \.self) { _ in
                        Circle()
                            .fill(priorityColor(for: priority))
                            .frame(width: 6, height: 6)
                    }
                }
            }

            // Tags count
            if !entry.tags.isEmpty {
                Text("·")
                    .font(.notateTiny)
                    .foregroundColor(.secondary)

                Text("\(entry.tags.count) tag\(entry.tags.count == 1 ? "" : "s")")
                    .font(.notateTiny)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Right Side Content

    @ViewBuilder
    private var rightSideContent: some View {
        if isProcessing {
            // Show processing badge
            NotateBadge(text: "Processing", style: .processing)
        } else if entry.isTodo, let priority = entry.priority {
            // Show priority badge for TODOs
            Text(priority.displayName)
                .font(.notateTiny)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, NotateDesignSystem.Spacing.space2)
                .padding(.vertical, 3)
                .background(priorityColor(for: priority))
                .clipShape(Capsule())
        }
    }

    // MARK: - Helpers

    private var cardBackground: Color {
        if isSelected {
            return entry.accentColor.opacity(0.05)
        }

        return colorScheme == .dark
            ? NotateDesignSystem.Colors.surfaceLift
            : .white
    }

    private func priorityColor(for priority: EntryPriority) -> Color {
        switch priority {
        case .high:
            return .notateAlertCrimson
        case .medium:
            return .notateActionAmber
        case .low:
            return .notateSuccessEmerald
        }
    }

    // MARK: - Actions

    private func selectEntry() {
        withAnimation(.easeInOut(duration: 0.2)) {
            appState.selectedEntry = entry
        }
    }

    private func toggleCompletion() {
        guard entry.status != .done else {
            // Cannot undo - shake animation to indicate
            withAnimation(.default) {
                // TODO: Add shake animation
            }
            return
        }

        // Show confirmation before completing
        showCompletionConfirmation = true
    }

    private func completeTodo() {
        // Complete with celebration animation
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            appState.markTodoAsDone(entry)
        }

        // Show completion toast
        NotificationService.shared.showTodoCompleted(entry: entry)
    }
}

// MARK: - Entry Extension for Accent Color

extension Entry {
    var accentColor: Color {
        switch type {
        case .todo:
            return .notateActionAmber
        case .thought, .piece:
            return .notateThoughtPurple
        }
    }
}

// MARK: - Priority Level Extension

extension EntryPriority {
    var level: Int {
        switch self {
        case .low: return 1
        case .medium: return 2
        case .high: return 3
        }
    }
}

// MARK: - Preview

#if DEBUG
struct NotateEntryCard_Previews: PreviewProvider {
    static var previews: some View {
        let mockAppState = AppState()

        VStack(spacing: 16) {
            // TODO entry
            NotateEntryCard(
                entry: Entry(
                    type: .todo,
                    content: "Buy milk and eggs from the store tomorrow morning",
                    tags: ["#shopping", "#groceries"],
                    triggerUsed: "///",
                    status: .open,
                    priority: .medium
                )
            )
            .environmentObject(mockAppState)

            // High priority TODO
            NotateEntryCard(
                entry: Entry(
                    type: .todo,
                    content: "Complete quarterly report by Friday deadline",
                    tags: ["#work", "#urgent"],
                    triggerUsed: "///",
                    status: .open,
                    priority: .high
                )
            )
            .environmentObject(mockAppState)

            // Completed TODO
            NotateEntryCard(
                entry: Entry(
                    type: .todo,
                    content: "Call dentist to schedule appointment",
                    tags: ["#health"],
                    triggerUsed: "///",
                    status: .done,
                    priority: .low
                )
            )
            .environmentObject(mockAppState)

            // Piece entry
            NotateEntryCard(
                entry: Entry(
                    type: .piece,
                    content: "I like the moon today I want to draw it in watercolor",
                    tags: ["#art", "#inspiration", "#creative"],
                    triggerUsed: ",,,"
                )
            )
            .environmentObject(mockAppState)

            // Processing entry
            NotateEntryCard(
                entry: Entry(
                    type: .todo,
                    content: "Coffee chat tomorrow at John A Paulson",
                    tags: ["#meeting"],
                    triggerUsed: "///"
                )
            )
            .environmentObject({
                let state = AppState()
                state.processingEntryIds.insert("test-id")
                return state
            }())
        }
        .padding(40)
        .frame(width: 700)
        .preferredColorScheme(.light)

        // Dark mode preview
        VStack(spacing: 16) {
            NotateEntryCard(
                entry: Entry(
                    type: .todo,
                    content: "Dark mode TODO example with priority",
                    tags: ["#design"],
                    triggerUsed: "///",
                    priority: .high
                )
            )
            .environmentObject(mockAppState)

            NotateEntryCard(
                entry: Entry(
                    type: .piece,
                    content: "Dark mode piece entry for testing visual consistency",
                    tags: ["#testing", "#dark-mode"],
                    triggerUsed: ",,,"
                )
            )
            .environmentObject(mockAppState)
        }
        .padding(40)
        .frame(width: 700)
        .background(Color.notateSurfaceDark)
        .preferredColorScheme(.dark)
    }
}
#endif

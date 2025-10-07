import SwiftUI

struct AISuggestionsInlineView: View {
    let entry: Entry
    @State private var isExpanded = false

    var body: some View {
        if let aiMetadata = entry.aiMetadata {
            VStack(alignment: .leading, spacing: 8) {
                // Compact header
                aiHeaderView(metadata: aiMetadata)

                // Expanded content
                if isExpanded {
                    aiExpandedContent(metadata: aiMetadata)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.blue.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.blue.opacity(0.2), lineWidth: 1)
            )
        }
    }

    // MARK: - Header View

    private func aiHeaderView(metadata: AIMetadata) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.blue)

            Text("AI")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.blue)

            // Quick stats
            if !metadata.actions.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "gear")
                        .font(.system(size: 9))
                    Text("\(metadata.actions.count)")
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundColor(.blue.opacity(0.8))
            }

            if metadata.researchResults != nil {
                HStack(spacing: 4) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 9))
                    Text("Research")
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundColor(.green.opacity(0.8))
            }

            Spacer()

            // Expand/collapse button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }) {
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.blue)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    // MARK: - Expanded Content

    private func aiExpandedContent(metadata: AIMetadata) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Quick actions
            if !metadata.actions.isEmpty {
                quickActionsView(actions: metadata.actions)
            }

            // Research summary
            if let research = metadata.researchResults {
                researchSummaryView(research: research)
            }
        }
    }

    private func quickActionsView(actions: [AIAction]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Actions")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 6) {
                ForEach(actions.prefix(4), id: \.id) { action in
                    quickActionChip(action: action)
                }
            }
        }
    }

    private func quickActionChip(action: AIAction) -> some View {
        HStack(spacing: 6) {
            Image(systemName: action.type.iconName)
                .font(.system(size: 10))
                .foregroundColor(action.type.color)

            Text(action.type.displayName)
                .font(.system(size: 10, weight: .medium))
                .lineLimit(1)

            Spacer(minLength: 0)

            Circle()
                .fill(action.status.color)
                .frame(width: 6, height: 6)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(NSColor.quaternarySystemFill))
        .clipShape(Capsule())
    }

    private func researchSummaryView(research: ResearchResults) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Research")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)

                Spacer()

                if research.researchCost > 0 {
                    Text(String(format: "$%.4f", research.researchCost))
                        .font(.system(size: 9, weight: .medium))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.green.opacity(0.2))
                        .foregroundColor(.green)
                        .clipShape(Capsule())
                }
            }

            Text(research.content)
                .font(.system(size: 11))
                .lineLimit(3)
                .padding(8)
                .background(Color(NSColor.textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 6))

            // Top suggestion
            if let firstSuggestion = research.suggestions.first {
                HStack(spacing: 6) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 9))
                        .foregroundColor(.yellow)

                    Text(firstSuggestion)
                        .font(.system(size: 10))
                        .lineLimit(2)
                        .foregroundColor(.secondary)

                    Spacer()
                }
                .padding(.top, 2)
            }
        }
    }
}

// MARK: - Preview

struct AISuggestionsInlineView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleEntry = Entry(
            type: .todo,
            content: "/// Call dentist tomorrow at 2pm",
            triggerUsed: "///"
        )

        AISuggestionsInlineView(entry: sampleEntry)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
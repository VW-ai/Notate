import SwiftUI

struct AIResultsView: View {
    let entry: Entry
    @EnvironmentObject var appState: AppState
    @State private var expandedActions = Set<String>()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let aiMetadata = entry.aiMetadata {
                // AI Actions Section
                if !aiMetadata.actions.isEmpty {
                    aiActionsSection(actions: aiMetadata.actions)
                }

                // Research Results Section
                if let research = aiMetadata.researchResults {
                    aiResearchSection(research: research)
                }

                // Processing Info
                if let processingMeta = aiMetadata.processingMeta {
                    processingInfoSection(meta: processingMeta)
                }
            } else {
                noAIDataView
            }
        }
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - AI Actions Section

    private func aiActionsSection(actions: [AIAction]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "gear.circle.fill")
                    .foregroundColor(.blue)
                Text("AI Actions")
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                Text("\(actions.count)")
                    .font(.system(size: 12, weight: .medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .clipShape(Capsule())
            }

            ForEach(actions, id: \.id) { action in
                aiActionRow(action: action)
            }
        }
    }

    private func aiActionRow(action: AIAction) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Action type icon
                Image(systemName: action.type.iconName)
                    .foregroundColor(action.type.color)
                    .frame(width: 20)

                // Action title
                Text(action.type.displayName)
                    .font(.system(size: 14, weight: .medium))

                Spacer()

                // Status badge
                actionStatusBadge(status: action.status)

                // Expand/collapse button
                Button(action: {
                    toggleActionExpansion(action.id)
                }) {
                    Image(systemName: expandedActions.contains(action.id) ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }

            // Expanded details
            if expandedActions.contains(action.id) {
                actionDetailsView(action: action)
            }
        }
        .padding(12)
        .background(Color(NSColor.quaternarySystemFill))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func actionStatusBadge(status: ActionStatus) -> some View {
        Text(status.displayName)
            .font(.system(size: 11, weight: .medium))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(status.color.opacity(0.2))
            .foregroundColor(status.color)
            .clipShape(Capsule())
    }

    private func actionDetailsView(action: AIAction) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Action data
            ForEach(Array(action.data.keys.sorted()), id: \.self) { key in
                if let value = action.data[key] {
                    HStack {
                        Text(key.capitalized)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(value.stringValue)
                            .font(.system(size: 12))
                            .lineLimit(2)
                    }
                }
            }

            // Action buttons
            HStack(spacing: 8) {
                if action.status == .executed && action.reversible {
                    Button("Reverse") {
                        reverseAction(action)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }

                if action.status == .failed {
                    Button("Retry") {
                        retryAction(action)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
        }
        .padding(.top, 4)
    }

    // MARK: - Research Section

    private func aiResearchSection(research: ResearchResults) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "doc.text.magnifyingglass")
                    .foregroundColor(.green)
                Text("AI Research")
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                if research.researchCost > 0 {
                    Text(String(format: "$%.4f", research.researchCost))
                        .font(.system(size: 11, weight: .medium))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.2))
                        .foregroundColor(.green)
                        .clipShape(Capsule())
                }
            }

            Text(research.content)
                .font(.system(size: 13))
                .padding(12)
                .background(Color(NSColor.textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            if !research.suggestions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Suggestions")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)

                    ForEach(research.suggestions, id: \.self) { suggestion in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.yellow)
                                .padding(.top, 2)

                            Text(suggestion)
                                .font(.system(size: 12))
                                .fixedSize(horizontal: false, vertical: true)

                            Spacer()
                        }
                    }
                }
            }

            // Regenerate button
            HStack {
                Spacer()
                Button("Regenerate Research") {
                    regenerateResearch()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
    }

    // MARK: - Processing Info Section

    private func processingInfoSection(meta: ProcessingMeta) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.secondary)
                Text("Processing Info")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                Spacer()
            }

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Processed")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Text(meta.processedAt.formatted(.dateTime.hour().minute()))
                        .font(.system(size: 12, weight: .medium))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Time")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Text("\(meta.processingTimeMs)ms")
                        .font(.system(size: 12, weight: .medium))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Cost")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Text(String(format: "$%.4f", meta.totalCost))
                        .font(.system(size: 12, weight: .medium))
                }
            }
        }
        .padding(12)
        .background(Color(NSColor.quaternarySystemFill).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - No AI Data View

    private var noAIDataView: some View {
        VStack(spacing: 12) {
            Image(systemName: "brain")
                .font(.system(size: 32))
                .foregroundColor(.secondary)

            Text("No AI processing yet")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)

            Button("Process with AI") {
                processWithAI()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    // MARK: - Actions

    private func toggleActionExpansion(_ actionId: String) {
        if expandedActions.contains(actionId) {
            expandedActions.remove(actionId)
        } else {
            expandedActions.insert(actionId)
        }
    }

    private func reverseAction(_ action: AIAction) {
        Task {
            // TODO: Implement action reversal through AppState/AutonomousAIAgent
            print("Reversing action: \(action.id)")
        }
    }

    private func retryAction(_ action: AIAction) {
        Task {
            // TODO: Implement action retry through AppState/AutonomousAIAgent
            print("Retrying action: \(action.id)")
        }
    }

    private func regenerateResearch() {
        Task {
            // TODO: Implement research regeneration through AppState/AutonomousAIAgent
            print("Regenerating research for entry: \(entry.id)")
        }
    }

    private func processWithAI() {
        Task {
            // TODO: Implement AI processing trigger through AppState/AutonomousAIAgent
            print("Processing entry with AI: \(entry.id)")
        }
    }
}

// MARK: - Extensions

extension AIActionType {
    var iconName: String {
        switch self {
        case .appleReminders: return "list.bullet.circle"
        case .calendar: return "calendar.circle"
        case .contacts: return "person.circle"
        case .maps: return "map.circle"
        }
    }

    var color: Color {
        switch self {
        case .appleReminders: return .blue
        case .calendar: return .red
        case .contacts: return .green
        case .maps: return .orange
        }
    }
}

// ActionStatus extensions are now in AIMetadata.swift
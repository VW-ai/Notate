import SwiftUI

// MARK: - Piece Timeline Card
// Card for displaying Pieces in timeline (left column)

struct PieceTimelineCard: View {
    let piece: Entry
    @EnvironmentObject var appState: AppState
    @StateObject private var tagDragState = TagDragState.shared

    @State private var isHovering = false

    private var isSelected: Bool {
        appState.selectedEntry?.id == piece.id
    }

    var body: some View {
        Button(action: {
            // If dragging tags, assign them; otherwise open detail
            if tagDragState.isDragging {
                tagDragState.assignToEntry(piece.id, appState: appState)
            } else {
                withAnimation(.easeInOut(duration: 0.2)) {
                    appState.selectedEvent = nil // Close any open event first
                    appState.selectedEntry = piece
                }
            }
        }) {
            VStack(alignment: .leading, spacing: NotateDesignSystem.Spacing.space2) {
                // Content
                Text(piece.content)
                    .font(.notateBody)
                    .foregroundColor(.primary)
                    .lineLimit(4)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Time and AI actions row
                HStack(spacing: NotateDesignSystem.Spacing.space2) {
                    // Time (when piece was captured)
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 10, weight: .medium))
                        Text(piece.createdAt.formatted(date: .omitted, time: .shortened))
                            .font(.notateTiny)
                    }
                    .foregroundColor(.secondary)

                    Spacer()

                    // AI action icons
                    aiActionIcons
                }
            }
            .padding(.vertical, NotateDesignSystem.Spacing.space4)
            .padding(.horizontal, NotateDesignSystem.Spacing.space3)
            .background(
                RoundedRectangle(cornerRadius: NotateDesignSystem.CornerRadius.medium)
                    .fill(Color(hex: "#7CB342").opacity(0.2))
            )
            .overlay(
                RoundedRectangle(cornerRadius: NotateDesignSystem.CornerRadius.medium)
                    .stroke(isSelected ? Color.notateNeuralBlue : Color(hex: "#7CB342").opacity(0.4), lineWidth: 1.5)
            )
            .shadowSubtle(darkMode: true)
            .scaleEffect(isHovering ? 1.02 : 1.0)
            .animation(.easeOut(duration: 0.15), value: isHovering)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            isHovering = hovering
        }
        .onDrag {
            // Provide drag data for tagging
            let dragData = "entry:\(piece.id)"
            return NSItemProvider(object: dragData as NSString)
        }
    }

    // MARK: - AI Action Icons

    private var aiActionIcons: some View {
        HStack(spacing: 6) {
            if let aiMetadata = piece.aiMetadata {
                ForEach(aiMetadata.actions.prefix(4)) { action in
                    actionIcon(for: action.type)
                        .font(.system(size: 14))
                        .foregroundColor(actionColor(for: action.type))
                }

                // Show "+N" if more than 4 actions
                if aiMetadata.actions.count > 4 {
                    Text("+\(aiMetadata.actions.count - 4)")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private func actionIcon(for type: AIActionType) -> Image {
        switch type {
        case .calendar:
            return Image(systemName: "calendar")
        case .appleReminders:
            return Image(systemName: "bell.fill")
        case .contacts:
            return Image(systemName: "person.crop.circle")
        case .maps:
            return Image(systemName: "map.fill")
        case .webSearch:
            return Image(systemName: "magnifyingglass")
        }
    }

    private func actionColor(for type: AIActionType) -> Color {
        switch type {
        case .calendar:
            return .notateAlertCrimson
        case .appleReminders:
            return .notateActionAmber
        case .contacts:
            return .notateNeuralBlue
        case .maps:
            return .notateSuccessEmerald
        case .webSearch:
            return .notateThoughtPurple
        }
    }
}

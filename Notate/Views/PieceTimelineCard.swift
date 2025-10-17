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
            HStack(alignment: .top, spacing: NotateDesignSystem.Spacing.space2) {
                // Left side: Time (single line for entry)
                Text(piece.createdAt.formatted(date: .omitted, time: .shortened))
                    .font(.notateTiny)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: true, vertical: false)
                    .frame(minWidth: 65, alignment: .leading)

                Rectangle()
                    .fill(Color(hex: "#7CB342").opacity(0.5))
                    .frame(width: 3)

                // Right side: Content
                VStack(alignment: .leading, spacing: NotateDesignSystem.Spacing.space3) {
                    // Content (title)
                    Text(piece.content)
                        .font(.notateBodyMedium)
                        .foregroundColor(.primary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // Tags row (always reserve space)
                    if !piece.tags.isEmpty {
                        tagsRow
                    } else {
                        // Empty placeholder to reserve vertical space
                        Spacer()
                            .frame(height: 20)
                    }

                    // AI action icons at bottom right
                    HStack {
                        Spacer()
                        aiActionIcons
                    }
                }
            }
            .padding(.vertical, NotateDesignSystem.Spacing.space5)
            .padding(.horizontal, NotateDesignSystem.Spacing.space5)
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

    // MARK: - Tags Row

    private var tagsRow: some View {
        HStack(spacing: 6) {
            ForEach(piece.tags.prefix(5), id: \.self) { tag in
                Text("#\(tag)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(TagColorManager.shared.getColorForTag(tag)?.opacity(0.8) ?? Color.gray.opacity(0.8))
                    )
            }

            if piece.tags.count > 5 {
                Text("+\(piece.tags.count - 5)")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.secondary)
            }
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

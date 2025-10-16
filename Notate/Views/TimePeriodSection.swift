import SwiftUI

// MARK: - Time Period Section
// Section for Morning/Afternoon/Evening/Anytime with two-column layout

struct TimePeriodSection: View {
    let title: String
    let icon: String
    let pieces: [Entry]
    let events: [CalendarEvent]
    let selectedDate: Date

    @State private var isExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: NotateDesignSystem.Spacing.space3) {
            // Section header
            sectionHeader

            if isExpanded {
                // Two-column timeline layout
                twoColumnTimeline
            }
        }
    }

    // MARK: - Section Header

    private var sectionHeader: some View {
        HStack(spacing: NotateDesignSystem.Spacing.space2) {
            // Collapse button on the left
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }) {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(PlainButtonStyle())

            Text(icon)
                .font(.system(size: 18))

            Text(title)
                .font(.notateH3)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            Text("\(totalCount)")
                .font(.notateTiny)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
                .padding(.horizontal, NotateDesignSystem.Spacing.space2)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(Color.secondary.opacity(0.1))
                )

            Spacer()
        }
        .padding(.vertical, NotateDesignSystem.Spacing.space3)
        .padding(.horizontal, NotateDesignSystem.Spacing.space4)
    }

    // MARK: - Two-Column Timeline

    private var twoColumnTimeline: some View {
        VStack(spacing: NotateDesignSystem.Spacing.space2) {
            if pieces.isEmpty && events.isEmpty {
                emptyState
            } else {
                // Merge and sort all items chronologically
                ForEach(sortedTimelineItems, id: \.id) { item in
                    TimelineRow(item: item)
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        HStack {
            Spacer()
            Text("No items")
                .font(.notateSmall)
                .foregroundColor(.secondary.opacity(0.6))
                .padding(.vertical, NotateDesignSystem.Spacing.space4)
            Spacer()
        }
    }

    // MARK: - Helper Properties

    private var totalCount: Int {
        pieces.count + events.count
    }

    private var sortedTimelineItems: [TimelineItem] {
        // Build aligned rows: group entries with events based on time overlap
        var alignedRows: [AlignedTimelineRow] = []
        var processedPieceIds = Set<String>()

        // Process each event and find overlapping pieces
        for event in events {
            var alignedPieces: [Entry] = []

            for piece in pieces {
                // Check if piece's createdAt falls within event's time range
                if piece.createdAt >= event.startTime && piece.createdAt <= event.endTime {
                    alignedPieces.append(piece)
                    processedPieceIds.insert(piece.id)
                }
            }

            // Sort aligned pieces by creation time
            alignedPieces.sort { $0.createdAt < $1.createdAt }

            alignedRows.append(AlignedTimelineRow(
                id: "aligned-event-\(event.id)",
                event: event,
                alignedPieces: alignedPieces,
                timestamp: event.startTime
            ))
        }

        // Add standalone pieces (not aligned with any event)
        for piece in pieces where !processedPieceIds.contains(piece.id) {
            alignedRows.append(AlignedTimelineRow(
                id: "standalone-piece-\(piece.id)",
                event: nil,
                alignedPieces: [piece],
                timestamp: piece.createdAt
            ))
        }

        // Sort all rows by timestamp
        alignedRows.sort { $0.timestamp < $1.timestamp }

        // Convert to TimelineItem array
        return alignedRows.map { row in
            TimelineItem(
                id: row.id,
                type: .alignedRow(row),
                timestamp: row.timestamp
            )
        }
    }
}

// MARK: - Aligned Timeline Row Data Model

struct AlignedTimelineRow: Identifiable {
    let id: String
    let event: CalendarEvent?
    let alignedPieces: [Entry]
    let timestamp: Date
}

// MARK: - Timeline Item

struct TimelineItem: Identifiable {
    let id: String
    let type: TimelineItemType
    let timestamp: Date
}

enum TimelineItemType {
    case alignedRow(AlignedTimelineRow)
}

// MARK: - Timeline Row

struct TimelineRow: View {
    let item: TimelineItem
    @EnvironmentObject var appState: AppState
    @State private var isEventCollapsed = false

    var body: some View {
        if case .alignedRow(let row) = item.type {
            HStack(alignment: .top, spacing: NotateDesignSystem.Spacing.space4) {
                // Left column: Aligned Pieces (scaled to 65% if aligned with event)
                VStack(spacing: NotateDesignSystem.Spacing.space2) {
                    if row.event != nil && isEventCollapsed && row.alignedPieces.count > 2 {
                        // Collapsed state for 3+ entries: show just shapes with hover
                        collapsedPiecesStack(pieces: row.alignedPieces)
                    } else if row.event != nil && isEventCollapsed {
                        // Collapsed state for 1-2 entries: show squeezed with text
                        ForEach(row.alignedPieces) { piece in
                            CollapsedPieceCard(piece: piece)
                        }
                    } else {
                        // Expanded state: show full cards
                        ForEach(row.alignedPieces) { piece in
                            PieceTimelineCard(piece: piece)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Right column: Calendar Event (if present)
                if let event = row.event {
                    StretchableEventCard(
                        event: event,
                        alignedPiecesCount: row.alignedPieces.count,
                        isCollapsed: $isEventCollapsed
                    )
                    .frame(maxWidth: .infinity, alignment: .trailing)
                } else {
                    Spacer()
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    // MARK: - Collapsed Pieces Stack (3+ entries)

    @ViewBuilder
    private func collapsedPiecesStack(pieces: [Entry]) -> some View {
        HStack(spacing: -8) {
            ForEach(pieces.prefix(3).indices, id: \.self) { index in
                Rectangle()
                    .fill(Color(hex: "#7CB342").opacity(0.2))
                    .frame(width: 60, height: 20)
                    .overlay(
                        RoundedRectangle(cornerRadius: NotateDesignSystem.CornerRadius.small)
                            .stroke(Color(hex: "#7CB342").opacity(0.4), lineWidth: 1)
                    )
                    .cornerRadius(NotateDesignSystem.CornerRadius.small)
                    .offset(x: CGFloat(index * 4))
            }
            if pieces.count > 3 {
                Text("+\(pieces.count - 3)")
                    .font(.notateTiny)
                    .foregroundColor(.secondary)
            }
        }
        .popover(isPresented: .constant(false)) { // TODO: Add hover detection
            VStack(spacing: NotateDesignSystem.Spacing.space2) {
                ForEach(pieces) { piece in
                    PieceTimelineCard(piece: piece)
                }
            }
            .padding()
        }
    }
}

// MARK: - Collapsed Piece Card (for 1-2 entries in collapsed state)

struct CollapsedPieceCard: View {
    let piece: Entry
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack(spacing: NotateDesignSystem.Spacing.space1) {
            Text(piece.content)
                .font(.notateTiny)
                .foregroundColor(.primary)
                .lineLimit(1)

            Spacer()
        }
        .padding(.horizontal, NotateDesignSystem.Spacing.space2)
        .padding(.vertical, NotateDesignSystem.Spacing.space1)
        .frame(height: 24)
        .background(
            RoundedRectangle(cornerRadius: NotateDesignSystem.CornerRadius.small)
                .fill(Color(hex: "#7CB342").opacity(0.2))
        )
        .overlay(
            RoundedRectangle(cornerRadius: NotateDesignSystem.CornerRadius.small)
                .stroke(Color(hex: "#7CB342").opacity(0.4), lineWidth: 1)
        )
    }
}

// MARK: - Stretchable Event Card (stretches to cover aligned pieces)

struct StretchableEventCard: View {
    let event: CalendarEvent
    let alignedPiecesCount: Int
    @Binding var isCollapsed: Bool
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack(alignment: .top, spacing: NotateDesignSystem.Spacing.space2) {
            // Left side: Time range (vertical)
            VStack(alignment: .leading, spacing: 0) {
                Text(event.startTime.formatted(date: .omitted, time: .shortened))
                    .font(.notateTiny)
                    .foregroundColor(.secondary)

                Spacer()

                Text(event.endTime.formatted(date: .omitted, time: .shortened))
                    .font(.notateTiny)
                    .foregroundColor(.secondary)
            }
            .frame(width: 50)

            Rectangle()
                .fill(event.isAIGenerated ? Color.notateNeuralBlue : Color(hex: "#3A3A3C"))
                .frame(width: 3)

            // Middle: Event content
            VStack(alignment: .leading, spacing: NotateDesignSystem.Spacing.space2) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(event.title)
                            .font(.notateBodyMedium)
                            .foregroundColor(.primary)
                        Text(event.duration)
                            .font(.notateTiny)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    // Collapse button at top right (only show if 2+ aligned pieces)
                    if alignedPiecesCount >= 2 {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isCollapsed.toggle()
                            }
                        }) {
                            Image(systemName: isCollapsed ? "chevron.down" : "chevron.up")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.secondary)
                                .frame(width: 20, height: 20)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }

                // Location and attendees
                if event.location != nil || !event.attendees.isEmpty {
                    VStack(alignment: .leading, spacing: NotateDesignSystem.Spacing.space2) {
                        if let location = event.location {
                            HStack(alignment: .top, spacing: 6) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                    .frame(width: 16)
                                Text(location)
                                    .font(.notateTiny)
                                    .foregroundColor(.secondary)
                            }
                        }

                        if !event.attendees.isEmpty {
                            HStack(alignment: .top, spacing: 6) {
                                Image(systemName: "person.2.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                    .frame(width: 16)
                                Group {
                                    if event.attendees.count > 3 {
                                        Text(event.attendees.prefix(3).joined(separator: ", ") + " +\(event.attendees.count - 3)")
                                    } else {
                                        Text(event.attendees.joined(separator: ", "))
                                    }
                                }
                                .font(.notateTiny)
                                .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .padding(NotateDesignSystem.Spacing.space3)
        .background(
            RoundedRectangle(cornerRadius: NotateDesignSystem.CornerRadius.medium)
                .fill(event.isAIGenerated ? Color.notateNeuralBlue.opacity(0.15) : Color(hex: "#8B7355").opacity(0.2))
        )
        .overlay(
            RoundedRectangle(cornerRadius: NotateDesignSystem.CornerRadius.medium)
                .stroke(
                    event.isAIGenerated ? Color.notateNeuralBlue.opacity(0.5) : Color(hex: "#8B7355").opacity(0.4),
                    lineWidth: 1.5
                )
        )
        .shadowSubtle(darkMode: true)
        .onTapGesture {
            withAnimation {
                appState.selectedEntry = nil // Close any open entry first
                appState.selectedEvent = event
            }
        }
        .onDrag {
            // Provide drag data for tagging
            let dragData = "event:\(event.id)"
            return NSItemProvider(object: dragData as NSString)
        }
    }
}

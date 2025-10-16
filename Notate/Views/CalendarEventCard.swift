import SwiftUI

// MARK: - Calendar Event Card
// Card for displaying calendar events in timeline (right column)

struct CalendarEventCard: View {
    let event: CalendarEvent
    @EnvironmentObject var appState: AppState

    @State private var isHovering = false

    var body: some View {
        Button(action: {
            withAnimation {
                appState.selectedEvent = event
            }
        }) {
            VStack(alignment: .leading, spacing: NotateDesignSystem.Spacing.space3) {
                // Title row with duration and time
                HStack(alignment: .top, spacing: NotateDesignSystem.Spacing.space2) {
                    // Left accent bar
                    Rectangle()
                        .fill(event.isAIGenerated ? Color.notateNeuralBlue : Color(hex: "#3A3A3C"))
                        .frame(width: 3)

                    VStack(alignment: .leading, spacing: NotateDesignSystem.Spacing.space1) {
                        // Title with AI indicator
                        HStack(spacing: 4) {
                            Text(event.title)
                                .font(.notateBodyMedium)
                                .foregroundColor(.primary)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)

                            if event.isAIGenerated {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.notateNeuralBlue)
                            }
                        }

                        // Duration
                        Text(event.duration)
                            .font(.notateTiny)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    // Time range on right
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(event.startTime.formatted(date: .omitted, time: .shortened))
                            .font(.notateTiny)
                            .foregroundColor(.secondary)
                        Text(event.endTime.formatted(date: .omitted, time: .shortened))
                            .font(.notateTiny)
                            .foregroundColor(.secondary)
                    }
                }

                // Details section (location, attendees)
                if event.location != nil || !event.attendees.isEmpty {
                    VStack(alignment: .leading, spacing: NotateDesignSystem.Spacing.space2) {
                        // Location
                        if let location = event.location, !location.isEmpty {
                            HStack(alignment: .top, spacing: 6) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .frame(width: 16)

                                Text(location)
                                    .font(.notateTiny)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                        }

                        // Attendees
                        if !event.attendees.isEmpty {
                            HStack(alignment: .top, spacing: 6) {
                                Image(systemName: "person.2.fill")
                                    .font(.system(size: 12, weight: .medium))
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
                                .lineLimit(2)
                            }
                        }
                    }
                    .padding(.leading, 3) // Align with accent bar
                }
            }
            .padding(NotateDesignSystem.Spacing.space3)
            .background(
                RoundedRectangle(cornerRadius: NotateDesignSystem.CornerRadius.medium)
                    .fill(event.isAIGenerated ? Color.notateNeuralBlue.opacity(0.15) : Color(hex: "#8B7355").opacity(0.2)) // Light brown
            )
            .overlay(
                RoundedRectangle(cornerRadius: NotateDesignSystem.CornerRadius.medium)
                    .stroke(
                        event.isAIGenerated ? Color.notateNeuralBlue.opacity(0.5) : Color(hex: "#8B7355").opacity(0.4),
                        lineWidth: 1.5
                    )
            )
            .shadowSubtle(darkMode: true)
            .scaleEffect(isHovering ? 1.02 : 1.0)
            .animation(.easeOut(duration: 0.15), value: isHovering)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

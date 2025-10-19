import SwiftUI

/// Centralized manager for assigning colors to entries and calendar events
/// Currently handles all-day events with a special color
/// Future: Will use AI to categorize and color-code all items
class ItemColorManager {
    static let shared = ItemColorManager()

    private init() {}

    // MARK: - Color Definitions

    /// Light red color for all-day events (holidays, birthdays, etc.)
    private let allDayEventColor = Color(hex: "#FF6B6B")  // Light red

    /// Default color for regular events
    private let regularEventColor = Color(hex: "#66FF99")  // Bright green

    /// Default color for entries/notes
    private let defaultEntryColor = Color(hex: "#66D9FF")  // Bright blue

    // MARK: - Public Methods

    /// Get the color for a calendar event
    /// - Parameter event: The calendar event
    /// - Returns: Color for the event's vertical line indicator
    func colorForEvent(_ event: CalendarEvent) -> Color {
        if event.isAllDay {
            return allDayEventColor
        }

        // Future: AI-based categorization will go here
        // For now, return default regular event color
        return regularEventColor
    }

    /// Get the color for an entry/note
    /// - Parameter entry: The entry
    /// - Returns: Color for the entry's vertical line indicator
    func colorForEntry(_ entry: Entry) -> Color {
        // Future: AI-based categorization will go here
        // For now, return default entry color
        return defaultEntryColor
    }
}

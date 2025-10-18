import Foundation
import EventKit
import Combine

// MARK: - Calendar Service
// Handles EventKit integration for importing calendar events

@MainActor
class CalendarService: ObservableObject {
    static let shared = CalendarService()

    private let eventStore = EKEventStore()
    @Published var hasCalendarAccess = false
    @Published var events: [CalendarEvent] = []

    private init() {
        checkCalendarAuthorizationStatus()
    }

    // MARK: - Authorization

    func checkCalendarAuthorizationStatus() {
        let status = EKEventStore.authorizationStatus(for: .event)

        switch status {
        case .authorized:
            hasCalendarAccess = true
        case .notDetermined:
            requestCalendarAccess()
        case .denied, .restricted:
            hasCalendarAccess = false
        @unknown default:
            hasCalendarAccess = false
        }
    }

    func requestCalendarAccess() {
        eventStore.requestAccess(to: .event) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.hasCalendarAccess = granted
                if granted {
                    self?.fetchEvents(for: Date())
                }
            }
        }
    }

    // MARK: - Fetch Events

    func fetchEvents(for date: Date) {
        guard hasCalendarAccess else {
            print("No calendar access")
            return
        }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let predicate = eventStore.predicateForEvents(
            withStart: startOfDay,
            end: endOfDay,
            calendars: nil
        )

        let ekEvents = eventStore.events(matching: predicate)

        // Convert EKEvent to our CalendarEvent model
        events = ekEvents.map { ekEvent in
            CalendarEvent(
                id: ekEvent.eventIdentifier ?? UUID().uuidString,
                title: ekEvent.title ?? "Untitled Event",
                startTime: ekEvent.startDate,
                endTime: ekEvent.endDate,
                location: ekEvent.location,
                attendees: ekEvent.attendees?.compactMap { $0.name } ?? [],
                calendarName: ekEvent.calendar?.title ?? "Calendar",
                calendarColor: ekEvent.calendar?.cgColor,
                isAllDay: ekEvent.isAllDay,
                notes: ekEvent.notes,
                url: ekEvent.url,
                isAIGenerated: false, // We'll mark AI-generated ones separately
                linkedPieceId: nil
            )
        }
        .sorted { $0.startTime < $1.startTime }
    }

    /// Fetch ALL events in a date range (for TagStore to get all tags)
    func fetchAllEvents(from startDate: Date, to endDate: Date) async -> [CalendarEvent] {
        guard hasCalendarAccess else {
            print("⚠️ No calendar access for fetchAllEvents")
            return []
        }

        let predicate = eventStore.predicateForEvents(
            withStart: startDate,
            end: endDate,
            calendars: nil
        )

        let ekEvents = eventStore.events(matching: predicate)

        let calendarEvents = ekEvents.map { ekEvent in
            CalendarEvent(
                id: ekEvent.eventIdentifier ?? UUID().uuidString,
                title: ekEvent.title ?? "Untitled Event",
                startTime: ekEvent.startDate,
                endTime: ekEvent.endDate,
                location: ekEvent.location,
                attendees: ekEvent.attendees?.compactMap { $0.name } ?? [],
                calendarName: ekEvent.calendar?.title ?? "Calendar",
                calendarColor: ekEvent.calendar?.cgColor,
                isAllDay: ekEvent.isAllDay,
                notes: ekEvent.notes,
                url: ekEvent.url,
                isAIGenerated: false,
                linkedPieceId: nil
            )
        }

        print("📅 Fetched \(calendarEvents.count) events from \(startDate) to \(endDate)")
        return calendarEvents
    }

    // MARK: - Filter Events by Time Period

    func eventsForTimePeriod(startHour: Int, endHour: Int, on date: Date) -> [CalendarEvent] {
        let calendar = Calendar.current
        return events.filter { event in
            guard calendar.isDate(event.startTime, inSameDayAs: date) else {
                return false
            }

            if event.isAllDay {
                return startHour == 0 // Show all-day events in morning or anytime
            }

            let hour = calendar.component(.hour, from: event.startTime)
            return hour >= startHour && hour < endHour
        }
    }
}

// MARK: - Calendar Event Model

struct CalendarEvent: Identifiable {
    let id: String
    let title: String
    let startTime: Date
    let endTime: Date
    let location: String?
    let attendees: [String]
    let calendarName: String
    let calendarColor: CGColor?
    let isAllDay: Bool
    let notes: String?
    let url: URL?
    let isAIGenerated: Bool
    let linkedPieceId: String?

    var duration: String {
        let interval = endTime.timeIntervalSince(startTime)
        let hours = Int(interval) / 3600
        let minutes = Int(interval) / 60 % 60

        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }
}

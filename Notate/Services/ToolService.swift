import Foundation
import EventKit
import Contacts
import MapKit
import Combine

@MainActor
class ToolService: ObservableObject {
    private let eventStore = EKEventStore()
    private let contactStore = CNContactStore()

    // MARK: - Permission Management

    func requestCalendarPermissions() async -> Bool {
        return await withCheckedContinuation { continuation in
            eventStore.requestAccess(to: .event) { granted, error in
                continuation.resume(returning: granted)
            }
        }
    }

    func requestRemindersPermissions() async -> Bool {
        return await withCheckedContinuation { continuation in
            eventStore.requestAccess(to: .reminder) { granted, error in
                continuation.resume(returning: granted)
            }
        }
    }

    func requestContactsPermissions() async -> Bool {
        return await withCheckedContinuation { continuation in
            contactStore.requestAccess(for: .contacts) { granted, error in
                continuation.resume(returning: granted)
            }
        }
    }

    // MARK: - Calendar Integration

    func createCalendarEvent(title: String, notes: String?, startDate: Date, endDate: Date? = nil) async throws -> String {
        let hasPermission = await requestCalendarPermissions()
        guard hasPermission else {
            throw ToolError.permissionDenied("Calendar access denied")
        }

        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.notes = notes
        event.startDate = startDate
        event.endDate = endDate ?? Calendar.current.date(byAdding: .hour, value: 1, to: startDate) ?? startDate
        event.calendar = eventStore.defaultCalendarForNewEvents

        try eventStore.save(event, span: .thisEvent)
        return event.eventIdentifier
    }

    func updateCalendarEvent(eventId: String, title: String? = nil, notes: String? = nil, startDate: Date? = nil) async throws {
        guard let event = eventStore.event(withIdentifier: eventId) else {
            throw ToolError.notFound("Calendar event not found")
        }

        if let title = title { event.title = title }
        if let notes = notes { event.notes = notes }
        if let startDate = startDate { event.startDate = startDate }

        try eventStore.save(event, span: .thisEvent)
    }

    func deleteCalendarEvent(eventId: String) async throws {
        guard let event = eventStore.event(withIdentifier: eventId) else {
            throw ToolError.notFound("Calendar event not found")
        }

        try eventStore.remove(event, span: .thisEvent)
    }

    // MARK: - Reminders Integration

    func createReminder(title: String, notes: String?, dueDate: Date? = nil, priority: Int = 0) async throws -> String {
        let hasPermission = await requestRemindersPermissions()
        guard hasPermission else {
            throw ToolError.permissionDenied("Reminders access denied")
        }

        let reminder = EKReminder(eventStore: eventStore)
        reminder.title = title
        reminder.notes = notes
        reminder.calendar = eventStore.defaultCalendarForNewReminders()

        if let dueDate = dueDate {
            reminder.dueDateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate)
        }

        // Priority: 0 = none, 1 = high, 5 = medium, 9 = low
        reminder.priority = priority

        try eventStore.save(reminder, commit: true)
        return reminder.calendarItemIdentifier
    }

    func updateReminder(reminderId: String, title: String? = nil, notes: String? = nil, isCompleted: Bool? = nil) async throws {
        guard let reminder = eventStore.calendarItem(withIdentifier: reminderId) as? EKReminder else {
            throw ToolError.notFound("Reminder not found")
        }

        if let title = title { reminder.title = title }
        if let notes = notes { reminder.notes = notes }
        if let isCompleted = isCompleted { reminder.isCompleted = isCompleted }

        try eventStore.save(reminder, commit: true)
    }

    func deleteReminder(reminderId: String) async throws {
        guard let reminder = eventStore.calendarItem(withIdentifier: reminderId) as? EKReminder else {
            throw ToolError.notFound("Reminder not found")
        }

        try eventStore.remove(reminder, commit: true)
    }

    // MARK: - Contacts Integration

    func createContact(firstName: String, lastName: String? = nil, phoneNumber: String? = nil, email: String? = nil) async throws -> String {
        let hasPermission = await requestContactsPermissions()
        guard hasPermission else {
            throw ToolError.permissionDenied("Contacts access denied")
        }

        let contact = CNMutableContact()
        contact.givenName = firstName
        if let lastName = lastName {
            contact.familyName = lastName
        }

        if let phoneNumber = phoneNumber {
            let phone = CNLabeledValue(label: CNLabelPhoneNumberMain, value: CNPhoneNumber(stringValue: phoneNumber))
            contact.phoneNumbers = [phone]
        }

        if let email = email {
            let emailValue = CNLabeledValue(label: CNLabelEmailiCloud, value: email as NSString)
            contact.emailAddresses = [emailValue]
        }

        let saveRequest = CNSaveRequest()
        saveRequest.add(contact, toContainerWithIdentifier: nil)

        try contactStore.execute(saveRequest)
        return contact.identifier
    }

    func searchContacts(name: String) async throws -> [CNContact] {
        let hasPermission = await requestContactsPermissions()
        guard hasPermission else {
            throw ToolError.permissionDenied("Contacts access denied")
        }

        let predicate = CNContact.predicateForContacts(matchingName: name)
        let keysToFetch = [CNContactGivenNameKey as CNKeyDescriptor, CNContactFamilyNameKey as CNKeyDescriptor, CNContactPhoneNumbersKey as CNKeyDescriptor, CNContactEmailAddressesKey as CNKeyDescriptor]

        return try contactStore.unifiedContacts(matching: predicate, keysToFetch: keysToFetch)
    }

    func deleteContact(contactId: String) async throws {
        let hasPermission = await requestContactsPermissions()
        guard hasPermission else {
            throw ToolError.permissionDenied("Contacts access denied")
        }

        let predicate = CNContact.predicateForContacts(withIdentifiers: [contactId])
        let contacts = try contactStore.unifiedContacts(matching: predicate, keysToFetch: [CNContactIdentifierKey as CNKeyDescriptor])

        guard let contact = contacts.first else {
            throw ToolError.notFound("Contact not found")
        }

        let saveRequest = CNSaveRequest()
        let mutableContact = contact.mutableCopy() as! CNMutableContact
        saveRequest.delete(mutableContact)

        try contactStore.execute(saveRequest)
    }

    // MARK: - Maps Integration

    func searchLocation(query: String) async throws -> [MKMapItem] {
        return await withCheckedContinuation { continuation in
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = query

            let search = MKLocalSearch(request: request)
            search.start { response, error in
                if let error = error {
                    continuation.resume(returning: [])
                } else {
                    continuation.resume(returning: response?.mapItems ?? [])
                }
            }
        }
    }

    func openInMaps(latitude: Double, longitude: Double, name: String? = nil) {
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = name
        mapItem.openInMaps()
    }

    func openInMaps(address: String) async throws {
        let locations = try await searchLocation(query: address)
        guard let firstLocation = locations.first else {
            throw ToolError.notFound("Location not found")
        }
        await MainActor.run {
            firstLocation.openInMaps()
        }
    }

    // MARK: - Utility Methods

    func getUpcomingEvents(from startDate: Date, to endDate: Date) async throws -> [EKEvent] {
        let hasPermission = await requestCalendarPermissions()
        guard hasPermission else {
            throw ToolError.permissionDenied("Calendar access denied")
        }

        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
        return eventStore.events(matching: predicate)
    }

    func getPendingReminders() async throws -> [EKReminder] {
        let hasPermission = await requestRemindersPermissions()
        guard hasPermission else {
            throw ToolError.permissionDenied("Reminders access denied")
        }

        let predicate = eventStore.predicateForIncompleteReminders(withDueDateStarting: nil, ending: nil, calendars: nil)

        return await withCheckedContinuation { continuation in
            eventStore.fetchReminders(matching: predicate) { reminders in
                continuation.resume(returning: reminders ?? [])
            }
        }
    }
}

// MARK: - Error Types

enum ToolError: LocalizedError {
    case permissionDenied(String)
    case notFound(String)
    case invalidInput(String)
    case systemError(String)

    var errorDescription: String? {
        switch self {
        case .permissionDenied(let message):
            return "Permission denied: \(message)"
        case .notFound(let message):
            return "Not found: \(message)"
        case .invalidInput(let message):
            return "Invalid input: \(message)"
        case .systemError(let message):
            return "System error: \(message)"
        }
    }
}
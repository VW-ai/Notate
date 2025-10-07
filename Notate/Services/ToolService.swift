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
        print("📅 [ToolService] Requesting calendar permissions...")

        // Check current authorization status
        let status = EKEventStore.authorizationStatus(for: .event)
        print("📅 [ToolService] Current calendar auth status: \(status.rawValue)")

        switch status {
        case .fullAccess:
            print("📅 [ToolService] Already have full access")
            return true
        case .writeOnly:
            print("📅 [ToolService] Have write-only access")
            return true
        case .denied:
            print("❌ [ToolService] Calendar access was denied - user needs to enable in System Settings")
            return false
        case .restricted:
            print("❌ [ToolService] Calendar access is restricted")
            return false
        case .notDetermined:
            print("📅 [ToolService] Calendar permission not determined, requesting...")
            do {
                let granted = try await eventStore.requestFullAccessToEvents()
                print("📅 [ToolService] Calendar permission request result: \(granted)")
                return granted
            } catch {
                print("❌ [ToolService] Calendar permission request error: \(error.localizedDescription)")
                return false
            }
        @unknown default:
            print("⚠️ [ToolService] Unknown calendar auth status")
            return false
        }
    }

    func requestRemindersPermissions() async -> Bool {
        print("✅ [ToolService] Requesting reminders permissions...")

        // Check current authorization status
        let status = EKEventStore.authorizationStatus(for: .reminder)
        print("✅ [ToolService] Current reminders auth status: \(status.rawValue)")

        switch status {
        case .fullAccess:
            print("✅ [ToolService] Already have full access")
            return true
        case .writeOnly:
            print("✅ [ToolService] Have write-only access")
            return true
        case .denied:
            print("❌ [ToolService] Reminders access was denied - user needs to enable in System Settings")
            return false
        case .restricted:
            print("❌ [ToolService] Reminders access is restricted")
            return false
        case .notDetermined:
            print("✅ [ToolService] Reminders permission not determined, requesting...")
            do {
                let granted = try await eventStore.requestFullAccessToReminders()
                print("✅ [ToolService] Reminders permission request result: \(granted)")
                return granted
            } catch {
                print("❌ [ToolService] Reminders permission request error: \(error.localizedDescription)")
                return false
            }
        @unknown default:
            print("⚠️ [ToolService] Unknown reminders auth status")
            return false
        }
    }

    func requestContactsPermissions() async -> Bool {
        print("👤 [ToolService] Requesting contacts permissions...")

        // Check current authorization status
        let status = CNContactStore.authorizationStatus(for: .contacts)
        print("👤 [ToolService] Current contacts auth status: \(status.rawValue)")

        switch status {
        case .authorized:
            print("👤 [ToolService] Already authorized")
            return true
        case .denied:
            print("❌ [ToolService] Contacts access was denied - user needs to enable in System Settings")
            return false
        case .restricted:
            print("❌ [ToolService] Contacts access is restricted")
            return false
        case .notDetermined:
            print("👤 [ToolService] Contacts permission not determined, requesting...")
            return await withCheckedContinuation { continuation in
                contactStore.requestAccess(for: .contacts) { granted, error in
                    if let error = error {
                        print("❌ [ToolService] Contacts permission error: \(error.localizedDescription)")
                    }
                    print("👤 [ToolService] Contacts permission request result: \(granted)")
                    continuation.resume(returning: granted)
                }
            }
        @unknown default:
            print("⚠️ [ToolService] Unknown contacts auth status")
            return false
        }
    }

    // MARK: - Calendar Integration

    func createCalendarEvent(title: String, notes: String?, startDate: Date, endDate: Date? = nil) async throws -> String {
        print("📅 [ToolService] Creating calendar event...")
        print("   Title: \(title)")
        print("   Start: \(startDate)")
        print("   Notes: \(notes ?? "none")")

        let hasPermission = await requestCalendarPermissions()
        print("📅 [ToolService] Permission check: \(hasPermission)")

        guard hasPermission else {
            print("❌ [ToolService] Calendar permission DENIED")
            throw ToolError.permissionDenied("Calendar access denied")
        }

        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.notes = notes
        event.startDate = startDate
        event.endDate = endDate ?? Calendar.current.date(byAdding: .hour, value: 1, to: startDate) ?? startDate
        event.calendar = eventStore.defaultCalendarForNewEvents

        print("📅 [ToolService] Default calendar: \(eventStore.defaultCalendarForNewEvents?.title ?? "none")")

        do {
            try eventStore.save(event, span: .thisEvent)
            print("✅ [ToolService] Calendar event created successfully: \(event.eventIdentifier)")
            return event.eventIdentifier
        } catch {
            print("❌ [ToolService] Failed to save calendar event: \(error.localizedDescription)")
            throw error
        }
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
        print("✅ [ToolService] Creating reminder...")
        print("   Title: \(title)")
        print("   Due: \(dueDate?.description ?? "none")")
        print("   Notes: \(notes ?? "none")")

        let hasPermission = await requestRemindersPermissions()
        print("✅ [ToolService] Permission check: \(hasPermission)")

        guard hasPermission else {
            print("❌ [ToolService] Reminders permission DENIED")
            throw ToolError.permissionDenied("Reminders access denied")
        }

        let reminder = EKReminder(eventStore: eventStore)
        reminder.title = title
        reminder.notes = notes
        reminder.calendar = eventStore.defaultCalendarForNewReminders()

        print("✅ [ToolService] Default reminders calendar: \(eventStore.defaultCalendarForNewReminders()?.title ?? "none")")

        if let dueDate = dueDate {
            reminder.dueDateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate)
            print("✅ [ToolService] Due date components set: \(reminder.dueDateComponents?.description ?? "none")")
        }

        // Priority: 0 = none, 1 = high, 5 = medium, 9 = low
        reminder.priority = priority

        do {
            try eventStore.save(reminder, commit: true)
            print("✅ [ToolService] Reminder created successfully: \(reminder.calendarItemIdentifier)")
            return reminder.calendarItemIdentifier
        } catch {
            print("❌ [ToolService] Failed to save reminder: \(error.localizedDescription)")
            throw error
        }
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
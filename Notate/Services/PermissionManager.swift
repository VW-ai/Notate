import Foundation
import EventKit
import Contacts
import SwiftUI
import Combine

@MainActor
class PermissionManager: ObservableObject {
    @Published var calendarPermission: PermissionStatus = .notDetermined
    @Published var remindersPermission: PermissionStatus = .notDetermined
    @Published var contactsPermission: PermissionStatus = .notDetermined

    private let eventStore = EKEventStore()
    private let contactStore = CNContactStore()

    enum PermissionStatus {
        case notDetermined
        case requesting
        case granted
        case denied
        case restricted

        var isGranted: Bool {
            return self == .granted
        }

        var displayMessage: String {
            switch self {
            case .notDetermined:
                return "Permission not requested"
            case .requesting:
                return "Requesting permission..."
            case .granted:
                return "Permission granted"
            case .denied:
                return "Permission denied"
            case .restricted:
                return "Permission restricted"
            }
        }

        var icon: String {
            switch self {
            case .notDetermined:
                return "questionmark.circle"
            case .requesting:
                return "clock"
            case .granted:
                return "checkmark.circle.fill"
            case .denied:
                return "xmark.circle.fill"
            case .restricted:
                return "lock.circle.fill"
            }
        }

        var color: Color {
            switch self {
            case .notDetermined:
                return .gray
            case .requesting:
                return .blue
            case .granted:
                return .green
            case .denied:
                return .red
            case .restricted:
                return .orange
            }
        }
    }

    // MARK: - Permission Checking

    func checkAllPermissions() {
        checkCalendarPermission()
        checkRemindersPermission()
        checkContactsPermission()
    }

    private func checkCalendarPermission() {
        let status = EKEventStore.authorizationStatus(for: .event)
        calendarPermission = convertAuthStatus(status)
    }

    private func checkRemindersPermission() {
        let status = EKEventStore.authorizationStatus(for: .reminder)
        remindersPermission = convertAuthStatus(status)
    }

    private func checkContactsPermission() {
        let status = CNContactStore.authorizationStatus(for: .contacts)
        contactsPermission = convertContactAuthStatus(status)
    }

    private func convertAuthStatus(_ status: EKAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .notDetermined:
            return .notDetermined
        case .restricted:
            return .restricted
        case .denied:
            return .denied
        case .authorized:
            return .granted
        @unknown default:
            return .notDetermined
        }
    }

    private func convertContactAuthStatus(_ status: CNAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .notDetermined:
            return .notDetermined
        case .restricted:
            return .restricted
        case .denied:
            return .denied
        case .authorized:
            return .granted
        @unknown default:
            return .notDetermined
        }
    }

    // MARK: - Permission Requesting

    func requestCalendarPermission() async -> Bool {
        calendarPermission = .requesting

        let granted = await withCheckedContinuation { continuation in
            eventStore.requestAccess(to: .event) { granted, error in
                DispatchQueue.main.async {
                    continuation.resume(returning: granted)
                }
            }
        }

        calendarPermission = granted ? .granted : .denied
        return granted
    }

    func requestRemindersPermission() async -> Bool {
        remindersPermission = .requesting

        let granted = await withCheckedContinuation { continuation in
            eventStore.requestAccess(to: .reminder) { granted, error in
                DispatchQueue.main.async {
                    continuation.resume(returning: granted)
                }
            }
        }

        remindersPermission = granted ? .granted : .denied
        return granted
    }

    func requestContactsPermission() async -> Bool {
        contactsPermission = .requesting

        let granted = await withCheckedContinuation { continuation in
            contactStore.requestAccess(for: .contacts) { granted, error in
                DispatchQueue.main.async {
                    continuation.resume(returning: granted)
                }
            }
        }

        contactsPermission = granted ? .granted : .denied
        return granted
    }

    // MARK: - Permission for Specific Actions

    func getPermissionForAction(_ actionType: AIActionType) -> PermissionStatus {
        switch actionType {
        case .appleReminders:
            return remindersPermission
        case .calendar:
            return calendarPermission
        case .contacts:
            return contactsPermission
        case .maps, .webSearch:
            return .granted // These don't require special permissions
        }
    }

    func requestPermissionForAction(_ actionType: AIActionType) async -> Bool {
        switch actionType {
        case .appleReminders:
            return await requestRemindersPermission()
        case .calendar:
            return await requestCalendarPermission()
        case .contacts:
            return await requestContactsPermission()
        case .maps, .webSearch:
            return true // These don't require special permissions
        }
    }

    // MARK: - System Settings Navigation

    func openSystemPreferences(for actionType: AIActionType) {
        let settingsPath: String

        switch actionType {
        case .appleReminders:
            settingsPath = "x-apple.systempreferences:com.apple.preference.security?Privacy_Reminders"
        case .calendar:
            settingsPath = "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars"
        case .contacts:
            settingsPath = "x-apple.systempreferences:com.apple.preference.security?Privacy_Contacts"
        case .maps, .webSearch:
            return // No special permissions needed
        }

        if let url = URL(string: settingsPath) {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - User Guidance

    func getPermissionGuidance(for actionType: AIActionType) -> PermissionGuidance {
        switch actionType {
        case .appleReminders:
            return PermissionGuidance(
                title: "Reminders Access Required",
                message: "To create reminders in Apple Reminders, Notate needs permission to access your reminders.",
                instructions: [
                    "Click 'Grant Permission' below",
                    "Allow access in the system dialog",
                    "Your reminders will be created automatically"
                ],
                privacyNote: "Notate only creates new reminders and doesn't read existing ones."
            )
        case .calendar:
            return PermissionGuidance(
                title: "Calendar Access Required",
                message: "To create calendar events, Notate needs permission to access your calendar.",
                instructions: [
                    "Click 'Grant Permission' below",
                    "Allow access in the system dialog",
                    "Events will be added to your default calendar"
                ],
                privacyNote: "Notate only creates new events and doesn't read existing calendar data."
            )
        case .contacts:
            return PermissionGuidance(
                title: "Contacts Access Required",
                message: "To create contacts, Notate needs permission to access your contacts.",
                instructions: [
                    "Click 'Grant Permission' below",
                    "Allow access in the system dialog",
                    "New contacts will be added to your address book"
                ],
                privacyNote: "Notate only creates new contacts and doesn't access existing contact information."
            )
        case .maps, .webSearch:
            return PermissionGuidance(
                title: "No Permission Required",
                message: "This action doesn't require special permissions.",
                instructions: [],
                privacyNote: ""
            )
        }
    }
}

struct PermissionGuidance {
    let title: String
    let message: String
    let instructions: [String]
    let privacyNote: String
}
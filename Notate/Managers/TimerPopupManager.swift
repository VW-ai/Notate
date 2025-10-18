import Foundation
import AppKit
import UserNotifications

/// Singleton manager to ensure only one timer popup is open at a time
/// and to coordinate between popups and notifications
@MainActor
class TimerPopupManager {
    static let shared = TimerPopupManager()

    private var currentPopup: TimerPopupWindow?
    private var currentNotificationId: String?

    private init() {}

    // MARK: - Popup Management

    /// Shows a popup, automatically closing any existing popup first
    func showPopup(mode: TimerPopupWindow.PopupMode, notificationId: String? = nil) {
        // Close existing popup if any
        closePopup()

        // Create and show new popup
        let popup = TimerPopupWindow(mode: mode)
        currentPopup = popup
        currentNotificationId = notificationId

        popup.makeKeyAndOrderFront(nil)
        print("🪟 Popup opened: \(mode)")
    }

    /// Closes the current popup if one exists
    func closePopup() {
        if let popup = currentPopup {
            popup.close()
            currentPopup = nil
            print("🪟 Popup closed")
        }

        // Also dismiss any associated notification
        if let notifId = currentNotificationId {
            dismissNotification(notifId)
            currentNotificationId = nil
        }
    }

    /// Check if a popup is currently open
    var hasOpenPopup: Bool {
        return currentPopup != nil && currentPopup?.isVisible == true
    }

    // MARK: - Notification Management

    /// Dismisses a notification by ID
    private func dismissNotification(_ identifier: String) {
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [identifier])
        print("🔔 Notification dismissed: \(identifier)")
    }

    /// Called when user interacts with notification (should close popup)
    func handleNotificationInteraction(_ notificationId: String) {
        if currentNotificationId == notificationId {
            closePopup()
        }
    }
}

// Extension to add mode description for logging
extension TimerPopupWindow.PopupMode: CustomStringConvertible {
    var description: String {
        switch self {
        case .eventNameInput:
            return "Event Name Input"
        case .tagSelection:
            return "Tag Selection"
        case .runningTimer:
            return "Running Timer"
        case .conflict:
            return "Timer Conflict"
        case .eventCompletion:
            return "Event Completion"
        }
    }
}

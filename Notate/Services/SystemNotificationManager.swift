import Foundation
import UserNotifications
import AppKit
import Combine

/// Manages native macOS system notifications for entry capture feedback
/// Uses UNUserNotificationCenter for system-integrated notifications
@MainActor
class SystemNotificationManager: NSObject, ObservableObject {
    static let shared = SystemNotificationManager()

    @Published var permissionGranted: Bool = false

    private let notificationCenter = UNUserNotificationCenter.current()

    private override init() {
        super.init()
        notificationCenter.delegate = self
        checkPermission()
    }

    // MARK: - Permission Management

    func requestPermission() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run {
                self.permissionGranted = granted
            }
            print(granted ? "✅ Notification permission granted" : "⚠️ Notification permission denied")
            return granted
        } catch {
            print("❌ Failed to request notification permission: \(error)")
            return false
        }
    }

    func checkPermission() {
        Task {
            let settings = await notificationCenter.notificationSettings()
            await MainActor.run {
                self.permissionGranted = settings.authorizationStatus == .authorized
            }
        }
    }

    // MARK: - Entry Capture Notifications

    /// Show notification when entry is captured
    func notifyEntryCapture(_ entry: Entry) {
        guard permissionGranted else {
            print("⚠️ Notifications not permitted, skipping entry capture notification")
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "✓ Entry Captured"
        content.body = formatEntryPreview(entry)
        content.sound = .default
        content.categoryIdentifier = "ENTRY_CAPTURE"

        // Add entry ID to userInfo for interaction handling
        content.userInfo = [
            "entryId": entry.id,
            "entryType": entry.type.rawValue
        ]

        sendNotification(identifier: "entry-\(entry.id)", content: content)
    }

    /// Show notification when AI processing completes with actions
    func notifyAIProcessingComplete(_ entry: Entry, actions: [AIAction]) {
        guard permissionGranted else { return }

        let content = UNMutableNotificationContent()
        content.title = "🤖 AI Processing Complete"
        content.body = formatEntryPreview(entry)
        content.subtitle = formatActionsSummary(actions)
        content.sound = .default
        content.categoryIdentifier = "AI_COMPLETE"

        content.userInfo = [
            "entryId": entry.id,
            "actionCount": actions.count
        ]

        sendNotification(identifier: "ai-\(entry.id)", content: content)
    }

    /// Show notification when specific AI action is executed
    func notifyActionExecuted(_ action: AIAction, for entry: Entry) {
        guard permissionGranted else { return }

        let content = UNMutableNotificationContent()
        content.title = formatActionTitle(action)
        content.body = formatEntryPreview(entry)
        content.sound = nil // Silent for individual actions
        content.categoryIdentifier = "ACTION_EXECUTED"

        content.userInfo = [
            "entryId": entry.id,
            "actionId": action.id,
            "actionType": action.type.rawValue
        ]

        sendNotification(identifier: "action-\(action.id)", content: content)
    }

    /// Show combined notification for entry capture + AI actions
    func notifyEntryCaptureWithActions(_ entry: Entry, actions: [AIAction]) {
        guard permissionGranted else { return }

        let content = UNMutableNotificationContent()
        content.title = "✓ Entry Captured"
        content.body = formatEntryPreview(entry)

        if !actions.isEmpty {
            content.subtitle = formatActionsSummary(actions)
        }

        content.sound = .default
        content.categoryIdentifier = "ENTRY_WITH_ACTIONS"

        content.userInfo = [
            "entryId": entry.id,
            "actionCount": actions.count
        ]

        sendNotification(identifier: "entry-with-actions-\(entry.id)", content: content)
    }

    // MARK: - Timer Notifications

    /// Show notification when timer starts
    func notifyTimerStarted(eventName: String?, tags: [String]) {
        guard permissionGranted else { return }

        let content = UNMutableNotificationContent()
        content.title = "🍅 Timer Started"
        content.body = eventName ?? "Tracking time..."

        if !tags.isEmpty {
            content.subtitle = tags.map { "#\($0)" }.joined(separator: " ")
        }

        content.sound = .default
        content.categoryIdentifier = "TIMER_START"

        sendNotification(identifier: "timer-start-\(Date().timeIntervalSince1970)", content: content)
    }

    /// Show notification when timer is stopped
    func notifyTimerStopped(duration: TimeInterval, eventName: String?) {
        guard permissionGranted else { return }

        let content = UNMutableNotificationContent()
        content.title = "⏱️ Timer Stopped"
        content.body = eventName ?? "Time tracking completed"
        content.subtitle = formatDuration(duration)
        content.sound = .default
        content.categoryIdentifier = "TIMER_STOP"

        sendNotification(identifier: "timer-stop-\(Date().timeIntervalSince1970)", content: content)
    }

    // MARK: - Utility Methods

    private func sendNotification(identifier: String, content: UNMutableNotificationContent) {
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: nil // Deliver immediately
        )

        notificationCenter.add(request) { error in
            if let error = error {
                print("❌ Failed to send notification: \(error)")
            } else {
                print("✅ Notification sent: \(content.title)")
            }
        }
    }

    private func formatEntryPreview(_ entry: Entry) -> String {
        let maxLength = 60
        if entry.content.count <= maxLength {
            return entry.content
        }
        return String(entry.content.prefix(maxLength)) + "..."
    }

    private func formatActionsSummary(_ actions: [AIAction]) -> String {
        if actions.isEmpty {
            return "No actions taken"
        }

        // Group by type and create icon summary
        var actionCounts: [AIActionType: Int] = [:]
        for action in actions {
            actionCounts[action.type, default: 0] += 1
        }

        let summary = actionCounts.map { type, count in
            let icon = actionIcon(for: type)
            return count > 1 ? "\(icon)×\(count)" : icon
        }.joined(separator: " ")

        return summary + " • \(actions.count) action\(actions.count == 1 ? "" : "s")"
    }

    private func formatActionTitle(_ action: AIAction) -> String {
        let icon = actionIcon(for: action.type)
        return "\(icon) \(action.type.displayName) Created"
    }

    private func actionIcon(for type: AIActionType) -> String {
        switch type {
        case .calendar: return "📅"
        case .appleReminders: return "✅"
        case .contacts: return "👤"
        case .maps: return "🗺️"
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    // MARK: - Notification Management

    /// Clear all pending notifications
    func clearAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        notificationCenter.removeAllDeliveredNotifications()
    }

    /// Clear notifications for a specific entry
    func clearNotifications(for entryId: String) {
        notificationCenter.getPendingNotificationRequests { requests in
            let identifiersToRemove = requests
                .filter { $0.content.userInfo["entryId"] as? String == entryId }
                .map { $0.identifier }

            self.notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
        }

        notificationCenter.getDeliveredNotifications { notifications in
            let identifiersToRemove = notifications
                .filter { $0.request.content.userInfo["entryId"] as? String == entryId }
                .map { $0.request.identifier }

            self.notificationCenter.removeDeliveredNotifications(withIdentifiers: identifiersToRemove)
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension SystemNotificationManager: UNUserNotificationCenterDelegate {

    /// Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notifications even when app is in foreground
        completionHandler([.banner, .sound])
    }

    /// Handle user interaction with notification
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        // Handle different notification categories
        switch response.notification.request.content.categoryIdentifier {
        case "ENTRY_CAPTURE", "AI_COMPLETE", "ENTRY_WITH_ACTIONS", "ACTION_EXECUTED":
            if let entryId = userInfo["entryId"] as? String {
                handleEntryNotificationTap(entryId: entryId)
            }

        case "TIMER_START", "TIMER_STOP":
            handleTimerNotificationTap()

        default:
            break
        }

        completionHandler()
    }

    private func handleEntryNotificationTap(entryId: String) {
        // Post notification to app to show this entry
        NotificationCenter.default.post(
            name: NSNotification.Name("ShowEntryFromNotification"),
            object: nil,
            userInfo: ["entryId": entryId]
        )

        // Activate app
        NSApp.activate(ignoringOtherApps: true)
    }

    private func handleTimerNotificationTap() {
        // Post notification to app to show operator panel
        NotificationCenter.default.post(
            name: NSNotification.Name("ShowOperatorPanel"),
            object: nil
        )

        // Activate app
        NSApp.activate(ignoringOtherApps: true)
    }
}

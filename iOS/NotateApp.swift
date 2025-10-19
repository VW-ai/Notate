// NotateApp.swift (iOS)
import SwiftUI

@main
struct NotateApp: App {
    @StateObject private var appState = AppState()

    init() {
        print("🚀 Notate iOS Starting...")
        setupAppearance()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .onAppear {
                    checkForPendingCapture()
                }
                .onOpenURL { url in
                    handleURL(url)
                }
        }
    }

    private func setupAppearance() {
        // Configure app-wide appearance
        print("🎨 Setting up iOS appearance...")
    }

    // MARK: - URL Handling

    private func handleURL(_ url: URL) {
        print("📱 Received URL: \(url)")

        guard url.scheme == "notate" else { return }

        switch url.host {
        case "capture":
            // Triggered from keyboard extension
            checkForPendingCapture()

        default:
            print("⚠️ Unknown URL host: \(url.host ?? "nil")")
        }
    }

    // MARK: - Keyboard Extension Integration

    private func checkForPendingCapture() {
        let appGroupID = "group.com.notate.shared"
        guard let userDefaults = UserDefaults(suiteName: appGroupID) else {
            print("⚠️ Could not access App Group shared defaults")
            return
        }

        if let content = userDefaults.string(forKey: "pendingCapture"),
           let timestamp = userDefaults.object(forKey: "captureTimestamp") as? Date {

            // Only process if capture is recent (< 5 minutes old)
            if Date().timeIntervalSince(timestamp) < 300 {
                print("📝 Processing pending capture from keyboard: \(content.prefix(50))...")

                // Create entry
                let entry = Entry.createQuickCapture(
                    content: content,
                    trigger: "keyboard",
                    sourceApp: "Keyboard Extension"
                )

                appState.databaseManager.saveEntry(entry)

                // Clear pending capture
                userDefaults.removeObject(forKey: "pendingCapture")
                userDefaults.removeObject(forKey: "captureTimestamp")

                print("✅ Keyboard capture processed")
            } else {
                print("⚠️ Pending capture too old, ignoring")
                userDefaults.removeObject(forKey: "pendingCapture")
                userDefaults.removeObject(forKey: "captureTimestamp")
            }
        }
    }
}

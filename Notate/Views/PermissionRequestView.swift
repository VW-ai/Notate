import SwiftUI
import AppKit
import EventKit
import Contacts

struct PermissionRequestView: View {
    @Binding var hasPermission: Bool
    @State private var isChecking = false

    // New properties for AI action permissions
    let actionType: AIActionType?
    let onPermissionGranted: (() -> Void)?
    let onDismiss: (() -> Void)?
    @EnvironmentObject var permissionManager: PermissionManager

    // Initialize for accessibility permission (original functionality)
    init(hasPermission: Binding<Bool>) {
        self._hasPermission = hasPermission
        self.actionType = nil
        self.onPermissionGranted = nil
        self.onDismiss = nil
    }

    // Initialize for AI action permissions (new functionality)
    init(actionType: AIActionType, onPermissionGranted: @escaping () -> Void, onDismiss: @escaping () -> Void) {
        self._hasPermission = .constant(false)
        self.actionType = actionType
        self.onPermissionGranted = onPermissionGranted
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        VStack(spacing: 30) {
            // Header with dynamic content based on permission type
            VStack(spacing: 16) {
                Image(systemName: iconName)
                    .font(.system(size: 64))
                    .foregroundColor(.blue)

                Text("Notate")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text(subtitle)
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            
            // Permission explanation - dynamic based on type
            VStack(spacing: 16) {
                Text(permissionTitle)
                    .font(.title3)
                    .fontWeight(.semibold)

                Text(permissionDescription)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(0..<instructions.count, id: \.self) { index in
                        PermissionStepView(
                            number: "\(index + 1)",
                            text: instructions[index]
                        )
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
            }
            
            // Action buttons - dynamic based on type
            VStack(spacing: 12) {
                Button(action: openSystemPreferences) {
                    HStack {
                        Image(systemName: "gear")
                        Text(primaryButtonText)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())

                Button(action: checkPermission) {
                    HStack {
                        if isChecking {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text(secondaryButtonText)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .foregroundColor(.primary)
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isChecking)

                // Add dismiss button for AI action permissions
                if actionType != nil {
                    Button(action: {
                        onDismiss?()
                    }) {
                        Text("Cancel")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            Spacer()

            // Bottom description - dynamic based on type
            Text(bottomDescription)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(40)
        .frame(width: 500, height: 600)
    }

    // MARK: - Computed Properties for Dynamic Content

    private var iconName: String {
        if let actionType = actionType {
            switch actionType {
            case .calendar: return "calendar"
            case .appleReminders: return "list.bullet"
            case .contacts: return "person.crop.circle"
            case .maps: return "map"
            case .webSearch: return "magnifyingglass"
            }
        }
        return "keyboard"
    }

    private var subtitle: String {
        if actionType != nil {
            return "AI-Powered Productivity Assistant"
        }
        return "智能 TODO 捕获工具"
    }

    private var permissionTitle: String {
        if let actionType = actionType {
            switch actionType {
            case .calendar: return "Calendar Access Required"
            case .appleReminders: return "Reminders Access Required"
            case .contacts: return "Contacts Access Required"
            case .maps: return "Location Access Required"
            case .webSearch: return "Network Access Required"
            }
        }
        return "需要辅助功能权限"
    }

    private var permissionDescription: String {
        if let actionType = actionType {
            switch actionType {
            case .calendar:
                return "Notate needs access to Calendar to create events from your TODOs and manage your schedule."
            case .appleReminders:
                return "Notate needs access to Reminders to create and manage tasks from your captured content."
            case .contacts:
                return "Notate needs access to Contacts to save contact information from your entries."
            case .maps:
                return "Notate needs location access to provide location-based suggestions and navigation."
            case .webSearch:
                return "Notate needs network access to search the web for research and information."
            }
        }
        return "Notate 需要辅助功能权限来监听键盘输入，以便捕获您的 TODO 和想法。"
    }

    private var instructions: [String] {
        if let actionType = actionType {
            switch actionType {
            case .calendar:
                return [
                    "Click the button below to open System Settings",
                    "Go to Privacy & Security > Calendar",
                    "Enable Notate in the list of applications"
                ]
            case .appleReminders:
                return [
                    "Click the button below to open System Settings",
                    "Go to Privacy & Security > Reminders",
                    "Enable Notate in the list of applications"
                ]
            case .contacts:
                return [
                    "Click the button below to open System Settings",
                    "Go to Privacy & Security > Contacts",
                    "Enable Notate in the list of applications"
                ]
            case .maps:
                return [
                    "Click the button below to open System Settings",
                    "Go to Privacy & Security > Location Services",
                    "Enable Notate in the list of applications"
                ]
            case .webSearch:
                return [
                    "Network access is managed automatically",
                    "Check your internet connection",
                    "Try the action again"
                ]
            }
        }
        return [
            "点击下方按钮打开系统设置",
            "在辅助功能列表中找到并启用 Notate",
            "返回应用，权限将自动生效"
        ]
    }

    private var primaryButtonText: String {
        if actionType != nil {
            return "Open System Settings"
        }
        return "打开系统设置"
    }

    private var secondaryButtonText: String {
        if actionType != nil {
            return "Check Permission Status"
        }
        return "检查权限状态"
    }

    private var bottomDescription: String {
        if actionType != nil {
            return "Once permission is granted, Notate will be able to perform this action automatically for your convenience."
        }
        return "权限授予后，您就可以使用 /// 或 ,,, 等触发器来快速捕获 TODO 和想法了！"
    }

    // MARK: - Permission Methods

    private func openSystemPreferences() {
        if let actionType = actionType {
            let urlString: String
            switch actionType {
            case .calendar:
                urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars"
            case .appleReminders:
                urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_Reminders"
            case .contacts:
                urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_Contacts"
            case .maps:
                urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices"
            case .webSearch:
                // For network access, just return - no specific settings to open
                return
            }

            if let url = URL(string: urlString) {
                NSWorkspace.shared.open(url)
            }
        } else {
            // Original accessibility permission
            let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
            NSWorkspace.shared.open(url)
        }
    }
    
    private func checkPermission() {
        isChecking = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if let actionType = actionType {
                // Check AI action permissions
                checkAIActionPermission(actionType)
            } else {
                // Original accessibility permission checking
                checkAccessibilityPermission()
            }
        }
    }

    private func checkAIActionPermission(_ actionType: AIActionType) {
        Task { @MainActor in
            let hasPermissionNow: Bool

            switch actionType {
            case .calendar:
                hasPermissionNow = await requestCalendarPermission()
            case .appleReminders:
                hasPermissionNow = await requestRemindersPermission()
            case .contacts:
                hasPermissionNow = await requestContactsPermission()
            case .maps, .webSearch:
                // These don't require explicit permission requests
                hasPermissionNow = true
            }

            isChecking = false

            if hasPermissionNow {
                onPermissionGranted?()
            } else {
                showPermissionDeniedAlert(for: actionType)
            }
        }
    }

    private func checkAccessibilityPermission() {
        // 使用多种方法检测权限
        let trusted1 = AXIsProcessTrusted()
        let trusted2 = checkPermissionByCreatingEventTap()
        let trusted3 = checkPermissionFromSystemPreferences()

        let hasPermissionNow = trusted1 || trusted2 || trusted3

        print("🔍 权限检测结果:")
        print("  - AXIsProcessTrusted: \(trusted1)")
        print("  - EventTap测试: \(trusted2)")
        print("  - 系统偏好设置: \(trusted3)")
        print("  - 最终结果: \(hasPermissionNow)")

        hasPermission = hasPermissionNow
        isChecking = false

        if !hasPermissionNow {
            // 显示详细的提示
            let alert = NSAlert()
            alert.messageText = "权限未授予"
            alert.informativeText = """
            检测结果:
            • AXIsProcessTrusted: \(trusted1 ? "✅" : "❌")
            • EventTap测试: \(trusted2 ? "✅" : "❌")
            • 系统偏好设置: \(trusted3 ? "✅" : "❌")

            请确保在系统设置 > 隐私与安全性 > 辅助功能中启用了 Notate 的权限。
            """
            alert.addButton(withTitle: "打开系统设置")
            alert.addButton(withTitle: "确定")
            alert.alertStyle = .informational

            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                openSystemPreferences()
            }
        }
    }

    // MARK: - AI Permission Request Methods

    private func requestCalendarPermission() async -> Bool {
        let eventStore = EKEventStore()
        do {
            let granted = try await eventStore.requestFullAccessToEvents()
            return granted
        } catch {
            print("❌ Calendar permission error: \(error)")
            return false
        }
    }

    private func requestRemindersPermission() async -> Bool {
        let eventStore = EKEventStore()
        do {
            let granted = try await eventStore.requestFullAccessToReminders()
            return granted
        } catch {
            print("❌ Reminders permission error: \(error)")
            return false
        }
    }

    private func requestContactsPermission() async -> Bool {
        let contactStore = CNContactStore()
        do {
            try await contactStore.requestAccess(for: .contacts)
            return true
        } catch {
            print("❌ Contacts permission error: \(error)")
            return false
        }
    }

    private func showPermissionDeniedAlert(for actionType: AIActionType) {
        let alert = NSAlert()
        alert.messageText = "Permission Denied"
        alert.informativeText = "Notate needs permission to access \(actionType.displayName) to perform this action. Please grant permission in System Settings."
        alert.addButton(withTitle: "Open Settings")
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = .warning

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            openSystemPreferences()
        }
    }
    
    private func checkPermissionByCreatingEventTap() -> Bool {
        let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: CGEventMask(1 << CGEventType.keyDown.rawValue),
            callback: { _, _, _, _ in return nil },
            userInfo: nil
        )
        
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            return true
        }
        
        return false
    }
    
    private func checkPermissionFromSystemPreferences() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }
}

struct PermissionStepView: View {
    let number: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(Color.blue)
                .clipShape(Circle())
            
            Text(text)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

#Preview {
    PermissionRequestView(hasPermission: .constant(false))
}

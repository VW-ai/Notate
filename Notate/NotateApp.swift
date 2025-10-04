import SwiftUI
import AppKit

@main
struct NotateApp: App {
    @StateObject private var appState = AppState()
    @State private var hasAccessibilityPermission = false
    @State private var permissionCheckTimer: Timer?

    var body: some Scene {
        WindowGroup {
            if hasAccessibilityPermission {
                ContentView()
                    .environmentObject(appState)
                    .onAppear {
                        appState.engine.start()
                        startPermissionMonitoring()
                    }
                    .onDisappear {
                        stopPermissionMonitoring()
                    }
            } else {
                PermissionRequestView(hasPermission: $hasAccessibilityPermission)
                    .onAppear {
                        checkAccessibilityPermission()
                        startPermissionMonitoring()
                    }
                    .onDisappear {
                        stopPermissionMonitoring()
                    }
            }
        }
    }
    
    private func checkAccessibilityPermission() {
        // 使用更可靠的权限检测方法
        let trusted = checkAccessibilityPermissionReliable()
        hasAccessibilityPermission = trusted
        
        print("🔍 权限检测结果: \(trusted ? "已授予" : "未授予")")
        
        if !trusted {
            // 延迟1秒后自动请求权限
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                requestAccessibilityIfNeeded()
            }
        }
    }
    
    private func checkAccessibilityPermissionReliable() -> Bool {
        // 方法1: 使用 AXIsProcessTrusted
        let trusted1 = AXIsProcessTrusted()
        
        // 方法2: 尝试创建一个事件监听器来测试权限
        let trusted2 = checkPermissionByCreatingEventTap()
        
        // 方法3: 检查系统偏好设置中的权限状态
        let trusted3 = checkPermissionFromSystemPreferences()
        
        print("🔍 权限检测详情:")
        print("  - AXIsProcessTrusted: \(trusted1)")
        print("  - EventTap测试: \(trusted2)")
        print("  - 系统偏好设置: \(trusted3)")
        
        // 如果任一方法返回true，则认为有权限
        return trusted1 || trusted2 || trusted3
    }
    
    private func checkPermissionByCreatingEventTap() -> Bool {
        // 尝试创建一个事件监听器来测试权限
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
        // 检查系统偏好设置中的权限状态
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }
    
    private func startPermissionMonitoring() {
        // 每5秒检查一次权限状态
        permissionCheckTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            let trusted = checkAccessibilityPermissionReliable()
            if trusted != hasAccessibilityPermission {
                print("🔄 权限状态发生变化: \(hasAccessibilityPermission) -> \(trusted)")
                hasAccessibilityPermission = trusted
                
                if trusted {
                    // 权限已授予，启动捕获引擎
                    appState.engine.start()
                } else {
                    // 权限被撤销，停止捕获引擎
                    appState.engine.stop()
                }
            }
        }
    }
    
    private func stopPermissionMonitoring() {
        permissionCheckTimer?.invalidate()
        permissionCheckTimer = nil
    }
}

func requestAccessibilityIfNeeded() {
    let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
    let trusted = AXIsProcessTrustedWithOptions(opts)
    if !trusted {
        print("➡️ 请到 系统设置 > 隐私与安全性 > 辅助功能 / 输入监控 打开 Notate")
        
        // 自动打开系统设置页面
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            openSystemPreferences()
        }
    }
}

func openSystemPreferences() {
    // 打开系统设置 > 隐私与安全性 > 辅助功能
    let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
    NSWorkspace.shared.open(url)
    
    // 显示用户友好的提示
    showAccessibilityAlert()
}

func showAccessibilityAlert() {
    let alert = NSAlert()
    alert.messageText = "需要辅助功能权限"
    alert.informativeText = "Notate 需要辅助功能权限来监听键盘输入。\n\n请在系统设置中启用 Notate 的辅助功能权限，然后重新启动应用。"
    alert.addButton(withTitle: "打开系统设置")
    alert.addButton(withTitle: "稍后设置")
    alert.alertStyle = .informational
    
    let response = alert.runModal()
    if response == .alertFirstButtonReturn {
        // 用户点击了"打开系统设置"，再次尝试打开
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
}

import SwiftUI
import AppKit

@main
struct NotateApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .onAppear {
                    requestAccessibilityIfNeeded()
                    appState.engine.start()
                }
        }
    }
}

func requestAccessibilityIfNeeded() {
    let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
    let trusted = AXIsProcessTrustedWithOptions(opts)
    if !trusted {
        print("➡️ 请到 系统设置 > 隐私与安全性 > 辅助功能 / 输入监控 打开 Notate")
    }
}

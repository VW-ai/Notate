import SwiftUI
import AppKit

struct PermissionRequestView: View {
    @Binding var hasPermission: Bool
    @State private var isChecking = false
    
    var body: some View {
        VStack(spacing: 30) {
            // 应用图标和标题
            VStack(spacing: 16) {
                Image(systemName: "keyboard")
                    .font(.system(size: 64))
                    .foregroundColor(.blue)
                
                Text("Notate")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("智能 TODO 捕获工具")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            
            // 权限说明
            VStack(spacing: 16) {
                Text("需要辅助功能权限")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text("Notate 需要辅助功能权限来监听键盘输入，以便捕获您的 TODO 和想法。")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 8) {
                    PermissionStepView(
                        number: "1",
                        text: "点击下方按钮打开系统设置"
                    )
                    
                    PermissionStepView(
                        number: "2", 
                        text: "在辅助功能列表中找到并启用 Notate"
                    )
                    
                    PermissionStepView(
                        number: "3",
                        text: "返回应用，权限将自动生效"
                    )
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
            }
            
            // 操作按钮
            VStack(spacing: 12) {
                Button(action: openSystemPreferences) {
                    HStack {
                        Image(systemName: "gear")
                        Text("打开系统设置")
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
                        Text("检查权限状态")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .foregroundColor(.primary)
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isChecking)
            }
            
            Spacer()
            
            // 底部说明
            Text("权限授予后，您就可以使用 /// 或 ,,, 等触发器来快速捕获 TODO 和想法了！")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(40)
        .frame(width: 500, height: 600)
    }
    
    private func openSystemPreferences() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
    
    private func checkPermission() {
        isChecking = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
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

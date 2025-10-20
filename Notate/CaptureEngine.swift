import AppKit
import Carbon.HIToolbox
import Combine

// Key codes for special keys
private let kVK_V: CGKeyCode = 9  // V key

extension Notification.Name {
    static let notateDidDetectTrigger = Notification.Name("Notate.didDetectTrigger")
    static let notateDidFinishCapture  = Notification.Name("Notate.didFinishCapture")
    static let todoArchivedNotification = Notification.Name("Notate.todoArchived")
    static let notateDidDetectTimerTrigger = Notification.Name("Notate.didDetectTimerTrigger")
    static let notateDidPasteContent = Notification.Name("Notate.didPasteContent")
}

struct CaptureResult {
    let content: String
    let triggerUsed: String
    let type: EntryType
}

struct TimerCaptureResult {
    let eventName: String
    let triggerUsed: String
}

struct PasteResult {
    let pastedContent: String
    let pastedLength: Int
}

final class CaptureEngine: ObservableObject {
    enum State { case idle, capturing }

    private var state: State = State.idle
    private var cancellables = Set<AnyCancellable>()

    // 触发符 rolling buffer - now supports multiple triggers
    private var triggerBuf: [Character] = []
    private var currentTrigger: String = ""
    private var currentTriggerConfig: TriggerConfig?

    // 捕获相关
    private var captureText: String = ""
    private var lastKeystrokeAt: Date = .init()
    private var idleTimer: Timer?
    private var isIMEComposing = false

    // 事件监听
    private var eventTap: CFMachPort?
    private var runLoopSrc: CFRunLoopSource?

    private let translator = KeyTranslator()
    private let configManager = ConfigurationManager.shared
    private let databaseManager = DatabaseManager.shared

    func start() {
        print("🚀 启动捕获引擎...")
        
        // Listen for both keyDown and keyUp events for better IME support
        let mask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue)
        let callback: CGEventTapCallBack = { (proxy, type, cgEvent, refcon) -> Unmanaged<CGEvent>? in
            // 把 self 取出来
            let engine = Unmanaged<CaptureEngine>
                .fromOpaque(refcon!)
                .takeUnretainedValue()

            // Handle IME composing state
            if type == CGEventType.keyUp {
                engine.handleKeyUp(cgEvent)
            } else if type == CGEventType.keyDown {
                // 取键码/修饰键 -> 字符
                let keyCode = cgEvent.getIntegerValueField(.keyboardEventKeycode)
                let flags   = cgEvent.flags
                let ch      = engine.translator?.char(from: CGKeyCode(keyCode), with: flags)

                // 添加调试信息
                if let char = ch, !char.isEmpty {
                    print("⌨️ 捕获到按键: '\(char)' (键码: \(keyCode))")
                }

                engine.handleKeystroke(ch, keyCode: CGKeyCode(keyCode), flags: flags)
            }
            
            return Unmanaged.passUnretained(cgEvent)
        }

        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap, // 使用默认选项，允许拦截
            eventsOfInterest: CGEventMask(mask),
            callback: callback,
            userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        )

        guard let tap = eventTap else {
            print("⚠️ 创建 EventTap 失败（检查辅助功能/输入监控权限）")
            return
        }

        runLoopSrc = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSrc, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        
        print("✅ Capture Engine started with \(configManager.getEnabledTriggers().count) triggers")
    }
    
    func stop() {
        idleTimer?.invalidate()
        idleTimer = nil
        
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        
        if let source = runLoopSrc {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
        }
        
        eventTap = nil
        runLoopSrc = nil
        
        // Reset state
        triggerBuf.removeAll()
        captureText = ""
        currentTrigger = ""
        currentTriggerConfig = nil
        state = State.idle
        
        print("✅ Capture Engine stopped")
    }

    // MARK: - 内部逻辑

    private func handleKeyUp(_ event: CGEvent) {
        // Reset IME composing state on key up
        if configManager.configuration.enableIMEComposing {
            // 简化IME检测：在keyUp时重置IME状态
            isIMEComposing = false
        }
    }

    private func handleKeystroke(_ ch: String?, keyCode: CGKeyCode, flags: CGEventFlags) {
        lastKeystrokeAt = Date()

        // Detect Cmd+V paste command during capture
        if state == .capturing && keyCode == kVK_V && flags.contains(.maskCommand) {
            handlePaste()
            return
        }

        switch state {
        case .idle:
            guard let c = ch?.first else { return }
            
            // 过滤掉删除键和其他控制字符
            if c == "\u{8}" || c == "\u{7F}" { // Backspace or Delete
                print("🗑️ 检测到删除键，忽略")
                return
            }
            
            // Add character to rolling buffer
            triggerBuf.append(c)
            
            // Keep buffer size reasonable (max length of longest trigger)
            let maxTriggerLength = configManager.getEnabledTriggers().map { $0.trigger.count }.max() ?? 3
            if triggerBuf.count > maxTriggerLength {
                triggerBuf.removeFirst()
            }
            
            // Check against all enabled triggers
            let currentBuffer = String(triggerBuf)
            print("🔍 检查触发器: '\(currentBuffer)'")

            for triggerConfig in configManager.getEnabledTriggers() {
                if currentBuffer.hasSuffix(triggerConfig.trigger) {
                    // Found a matching trigger
                    print("✅ 检测到触发器: '\(triggerConfig.trigger)' -> \(triggerConfig.isTimerTrigger ? "Timer" : triggerConfig.defaultType.displayName)")
                    currentTrigger = triggerConfig.trigger
                    currentTriggerConfig = triggerConfig
                    state = State.capturing
                    captureText = ""
                    isIMEComposing = false

                    NotificationCenter.default.post(name: .notateDidDetectTrigger, object: triggerConfig.trigger)
                    startIdleTimer()
                    break
                }
            }

        case .capturing:
            // 暂时禁用IME检测，因为它干扰了正常的英文输入
            // TODO: 实现更智能的IME检测
            
            guard let s = ch else { return }
            
            // 处理删除键
            if s == "\u{8}" || s == "\u{7F}" { // Backspace or Delete
                if !captureText.isEmpty {
                    captureText.removeLast()
                    print("🗑️ 删除字符，当前文本: '\(captureText)'")
                } else {
                    print("🗑️ 文本已空，无法删除")
                }
                return
            }
            
            if s == "\r" || s == "\n" {
                print("⏎ 检测到回车键，完成捕获")
                finishCapture()
            } else {
                captureText.append(contentsOf: s)
                print("📝 捕获文本: '\(captureText)'")
            }
        }
    }

    private func startIdleTimer() {
        idleTimer?.invalidate()
        let timeout = configManager.configuration.captureTimeout
        idleTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if Date().timeIntervalSince(self.lastKeystrokeAt) > timeout {
                self.finishCapture()
            }
        }
        RunLoop.current.add(idleTimer!, forMode: .common)
    }

    private func finishCapture() {
        idleTimer?.invalidate()
        idleTimer = nil

        let rawText = captureText.trimmingCharacters(in: .whitespacesAndNewlines)

        // Check if this is a timer trigger (allow empty for timer triggers)
        if let triggerConfig = currentTriggerConfig, triggerConfig.isTimerTrigger {
            print("🍅 Timer trigger detected!")
            print("  - Event name: '\(rawText.isEmpty ? "(empty)" : rawText)'")
            handleTimerCapture(eventName: rawText)
            return
        }

        // For regular entries, require non-empty content
        guard !rawText.isEmpty else {
            print("⚠️ 捕获文本为空，重置状态")
            resetCapture()
            return
        }

        print("🎯 完成捕获:")
        print("  - 原始文本: '\(rawText)'")
        print("  - 触发器: '\(currentTrigger)'")

        // Clean content and detect type
        let cleanedContent = configManager.cleanContent(rawText)
        let entryType = configManager.detectEntryType(from: rawText, triggerUsed: currentTrigger)

        print("  - 清理后文本: '\(cleanedContent)'")
        print("  - 检测类型: \(entryType.displayName)")
        
        // Create entry
        let entry = Entry(
            type: entryType,
            content: cleanedContent,
            triggerUsed: currentTrigger,
            status: entryType == EntryType.todo ? EntryStatus.open : EntryStatus.open,
            priority: entryType == EntryType.todo ? EntryPriority.medium : nil
        )
        
        // Save to database
        databaseManager.saveEntry(entry)
        print("💾 已保存到数据库")

        // Trigger AI processing if enabled
        triggerAIProcessing(for: entry)

        // Clear input if enabled
        if configManager.configuration.autoClearInput {
            clearCurrentInput()
        }
        
        // Post notification with result
        let result = CaptureResult(content: cleanedContent, triggerUsed: currentTrigger, type: entryType)
        NotificationCenter.default.post(name: .notateDidFinishCapture, object: result)
        
        resetCapture()
    }
    
    private func resetCapture() {
        triggerBuf.removeAll()
        captureText = ""
        currentTrigger = ""
        currentTriggerConfig = nil
        state = State.idle
        isIMEComposing = false
    }

    private func handlePaste() {
        guard state == .capturing else { return }

        // Read clipboard content
        let clipboardManager = ClipboardManager.shared
        guard let clipboardText = clipboardManager.readText() else {
            print("📋 Paste attempted but clipboard is empty")
            return
        }

        // Clean the clipboard text (trim whitespace, handle newlines)
        let cleanedText = clipboardText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanedText.isEmpty else {
            print("📋 Paste attempted but clipboard contains only whitespace")
            return
        }

        // Append clipboard content to capture text
        captureText.append(cleanedText)

        print("📋 Pasted from clipboard into capture:")
        print("  - Length: \(cleanedText.count) characters")
        print("  - Content: '\(cleanedText.prefix(100))\(cleanedText.count > 100 ? "..." : "")'")
        print("  - Total capture text: '\(captureText)'")

        // Post notification for UI feedback
        let pasteResult = PasteResult(
            pastedContent: String(cleanedText.prefix(100)),
            pastedLength: cleanedText.count
        )
        NotificationCenter.default.post(name: .notateDidPasteContent, object: pasteResult)

        // Reset the idle timer since we just added content
        startIdleTimer()
    }

    private func triggerAIProcessing(for entry: Entry) {
        // Post notification for AI processing
        NotificationCenter.default.post(
            name: Notification.Name("Notate.entryCreated"),
            object: entry
        )
        print("🤖 Triggered AI processing for entry: \(entry.content.prefix(50))...")
    }
    
    private func handleTimerCapture(eventName: String) {
        // Clear input if auto-clear is enabled
        if configManager.configuration.autoClearInput {
            clearCurrentInput()
        }

        // Create timer capture result
        let result = TimerCaptureResult(
            eventName: eventName,
            triggerUsed: currentTrigger
        )

        // Post notification for timer tag selection popup
        NotificationCenter.default.post(name: .notateDidDetectTimerTrigger, object: result)

        print("🍅 Timer capture complete: '\(eventName)'")
        resetCapture()
    }

    private func clearCurrentInput() {
        // Clear the input field by sending backspace events
        // Capture the count before async dispatch to avoid race condition

        guard !captureText.isEmpty else { return }

        // Capture values before they get reset
        let characterCount = captureText.count + currentTrigger.count

        print("🧹 Auto-clearing \(characterCount) characters from input...")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            // Create event source once and reuse for better performance
            let eventSource = CGEventSource(stateID: .hidSystemState)

            for _ in 0..<characterCount {
                // Create backspace down event with proper memory management
                if let backspaceDownEvent = CGEvent(keyboardEventSource: eventSource, virtualKey: 51, keyDown: true) {
                    backspaceDownEvent.post(tap: .cghidEventTap)
                    // CGEvent is automatically managed by ARC in Swift
                }

                // Create backspace up event with proper memory management
                if let backspaceUpEvent = CGEvent(keyboardEventSource: eventSource, virtualKey: 51, keyDown: false) {
                    backspaceUpEvent.post(tap: .cghidEventTap)
                    // CGEvent is automatically managed by ARC in Swift
                }

                // Small delay between key events for better reliability
                usleep(1000) // 1ms delay
            }

            print("✅ Auto-clear completed")
        }
    }
}

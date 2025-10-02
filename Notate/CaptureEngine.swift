import AppKit
import Carbon.HIToolbox

extension Notification.Name {
    static let notateDidDetectTrigger = Notification.Name("Notate.didDetectTrigger")
    static let notateDidFinishCapture  = Notification.Name("Notate.didFinishCapture")
}

final class CaptureEngine {
    enum State { case idle, capturing }

    private var state: State = .idle

    // 触发符 rolling buffer
    private var triggerBuf: [Character] = []
    private let trigger: [Character] = Array("///")

    // 捕获相关
    private var captureText: String = ""
    private var lastKeystrokeAt: Date = .init()
    private var idleTimer: Timer?

    // 事件监听
    private var eventTap: CFMachPort?
    private var runLoopSrc: CFRunLoopSource?

    private let translator = KeyTranslator()

    func start() {
        // 仅监听 keyDown
        let mask = (1 << CGEventType.keyDown.rawValue)
        let callback: CGEventTapCallBack = { (proxy, type, cgEvent, refcon) -> Unmanaged<CGEvent>? in
            // 把 self 取出来
            let engine = Unmanaged<CaptureEngine>
                .fromOpaque(refcon!)
                .takeUnretainedValue()

            guard type == .keyDown else {
                return Unmanaged.passUnretained(cgEvent)
            }

            // 取键码/修饰键 -> 字符
            let keyCode = cgEvent.getIntegerValueField(.keyboardEventKeycode)
            let flags   = cgEvent.flags
            let ch      = engine.translator?.char(from: CGKeyCode(keyCode), with: flags)

            engine.handleKeystroke(ch)
            return Unmanaged.passUnretained(cgEvent)
        }

        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly, // 只监听，不拦截
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
    }

    // MARK: - 内部逻辑

    private func handleKeystroke(_ ch: String?) {
        lastKeystrokeAt = Date()

        switch state {
        case .idle:
            guard let c = ch?.first else { return }
            // 只保留最近 3 个字符，匹配 ///
            triggerBuf.append(c)
            if triggerBuf.count > trigger.count { triggerBuf.removeFirst() }
            if triggerBuf == trigger {
                state = .capturing
                captureText = ""
                NotificationCenter.default.post(name: .notateDidDetectTrigger, object: nil)
                startIdleTimer()
            }

        case .capturing:
            guard let s = ch else { return }
            if s == "\r" || s == "\n" {
                finishCapture()
            } else {
                captureText.append(contentsOf: s)
            }
        }
    }

    private func startIdleTimer() {
        idleTimer?.invalidate()
        idleTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if Date().timeIntervalSince(self.lastKeystrokeAt) > 3.0 {
                self.finishCapture()
            }
        }
        RunLoop.current.add(idleTimer!, forMode: .common)
    }

    private func finishCapture() {
        idleTimer?.invalidate()
        idleTimer = nil

        let text = captureText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !text.isEmpty {
            NotificationCenter.default.post(name: .notateDidFinishCapture, object: text)
        }

        // 复位
        triggerBuf.removeAll()
        captureText = ""
        state = .idle
    }
}

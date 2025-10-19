import AppKit
import Carbon.HIToolbox

final class KeyTranslator {
    private let layout: TISInputSource?
    private let layoutData: CFData?

    init?() {
        self.layout = TISCopyCurrentKeyboardLayoutInputSource()?.takeUnretainedValue()
        if let p = layout.flatMap({ TISGetInputSourceProperty($0, kTISPropertyUnicodeKeyLayoutData) }) {
            self.layoutData = unsafeBitCast(p, to: CFData.self)
        } else {
            self.layoutData = nil
        }
    }

    func char(from keyCode: CGKeyCode, with flags: CGEventFlags) -> String? {
        guard let layoutData = layoutData as Data? else { return nil }
        let keyLayout = layoutData.withUnsafeBytes { $0.baseAddress!.assumingMemoryBound(to: UCKeyboardLayout.self) }

        var deadKeyState: UInt32 = 0
        var chars = [UniChar](repeating: 0, count: 4)
        var length: Int = 0

        let modifier = UInt32(flags.contains(.maskShift) ? shiftKey : 0)

        let status = UCKeyTranslate(
            keyLayout,
            keyCode,
            UInt16(kUCKeyActionDown),
            modifier,
            UInt32(LMGetKbdType()),
            OptionBits(kUCKeyTranslateNoDeadKeysBit),
            &deadKeyState,
            4,
            &length,
            &chars
        )

        guard status == noErr, length > 0 else { return nil }
        return String(utf16CodeUnits: chars, count: length)
    }
}

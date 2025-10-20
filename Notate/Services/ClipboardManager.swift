import AppKit
import Foundation

/// ClipboardManager - Centralized clipboard operations using NSPasteboard
final class ClipboardManager {
    static let shared = ClipboardManager()

    private init() {}

    // MARK: - Read Operations

    /// Read plain text from clipboard
    /// - Returns: String content if available, nil otherwise
    func readText() -> String? {
        let pasteboard = NSPasteboard.general
        return pasteboard.string(forType: .string)
    }

    /// Check if clipboard has text content
    var hasText: Bool {
        let pasteboard = NSPasteboard.general
        return pasteboard.types?.contains(.string) ?? false
    }

    // MARK: - Write Operations

    /// Copy plain text to clipboard
    /// - Parameter text: Text to copy
    func copyText(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        print("📋 Copied to clipboard: '\(text.prefix(50))\(text.count > 50 ? "..." : "")'")
    }

    /// Copy multiple string representations to clipboard
    /// - Parameters:
    ///   - plainText: Plain text version
    ///   - richText: Optional rich text version
    func copyMultiFormat(plainText: String, richText: NSAttributedString? = nil) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        var items: [NSPasteboardItem] = []
        let item = NSPasteboardItem()

        // Add plain text
        item.setString(plainText, forType: .string)

        // Add rich text if provided
        if let richText = richText,
           let rtfData = try? richText.data(
            from: NSRange(location: 0, length: richText.length),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
           ) {
            item.setData(rtfData, forType: .rtf)
        }

        items.append(item)
        pasteboard.writeObjects(items)

        print("📋 Copied multi-format to clipboard")
    }

    // MARK: - Clipboard Info

    /// Get current clipboard change count (useful for monitoring)
    var changeCount: Int {
        NSPasteboard.general.changeCount
    }

    /// Get clipboard content preview (first 100 characters)
    var preview: String? {
        guard let text = readText() else { return nil }
        let preview = text.prefix(100)
        return String(preview) + (text.count > 100 ? "..." : "")
    }
}

import SwiftUI
import Foundation
import Combine

// MARK: - Tag Color Manager
// Manages random color assignment for tags with persistence

class TagColorManager: ObservableObject {
    static let shared = TagColorManager()

    @Published private(set) var tagColors: [String: Color] = [:]
    @Published private(set) var knownTags: Set<String> = [] // Track all known tags, even those with 0 count

    // Track next color index to assign (cycles through 0-71)
    private var nextColorIndex: Int = 0

    // 72 distinct, visually pleasing colors
    private let colorPalette: [Color] = [
        // Reds & Pinks
        Color(hex: "#FF6B6B"), Color(hex: "#FF4757"), Color(hex: "#EE5A6F"),
        Color(hex: "#FF6348"), Color(hex: "#FF7979"), Color(hex: "#FF6B9D"),
        Color(hex: "#FF5E78"), Color(hex: "#FC5C65"), Color(hex: "#FF3838"),

        // Oranges
        Color(hex: "#FFA502"), Color(hex: "#FF9F43"), Color(hex: "#FF8C00"),
        Color(hex: "#FFA07A"), Color(hex: "#FF9500"), Color(hex: "#FF9966"),
        Color(hex: "#FF8800"), Color(hex: "#FFB142"), Color(hex: "#FFA94D"),

        // Yellows & Golds
        Color(hex: "#FFD93D"), Color(hex: "#FFE66D"), Color(hex: "#F6E58D"),
        Color(hex: "#FFDD59"), Color(hex: "#FFD32A"), Color(hex: "#FFCC00"),
        Color(hex: "#FCDC00"), Color(hex: "#FFD700"), Color(hex: "#FFC312"),

        // Greens
        Color(hex: "#6BCF7F"), Color(hex: "#55E6C1"), Color(hex: "#26DE81"),
        Color(hex: "#20BF6B"), Color(hex: "#2ECC71"), Color(hex: "#1DD1A1"),
        Color(hex: "#10AC84"), Color(hex: "#38E54D"), Color(hex: "#0BE881"),
        Color(hex: "#05C46B"), Color(hex: "#00D2D3"), Color(hex: "#0ABDE3"),

        // Cyans & Teals
        Color(hex: "#48DBfB"), Color(hex: "#00CEC9"), Color(hex: "#17C0EB"),
        Color(hex: "#1ABC9C"), Color(hex: "#00D8D6"), Color(hex: "#0FBCF9"),
        Color(hex: "#4BCFFA"), Color(hex: "#00B8D4"), Color(hex: "#01CBC6"),

        // Blues
        Color(hex: "#4834DF"), Color(hex: "#5F27CD"), Color(hex: "#54A0FF"),
        Color(hex: "#48DBFB"), Color(hex: "#0984E3"), Color(hex: "#3498DB"),
        Color(hex: "#2E86DE"), Color(hex: "#0ABDE3"), Color(hex: "#4A69BD"),
        Color(hex: "#3867D6"), Color(hex: "#0652DD"), Color(hex: "#1E90FF"),

        // Purples & Violets
        Color(hex: "#A29BFE"), Color(hex: "#6C5CE7"), Color(hex: "#8E44AD"),
        Color(hex: "#9B59B6"), Color(hex: "#A55EEA"), Color(hex: "#8854D0"),
        Color(hex: "#9C88FF"), Color(hex: "#BE2EDD"), Color(hex: "#B53471"),
        Color(hex: "#833471"), Color(hex: "#6D214F"), Color(hex: "#8E44AD"),

        // Browns & Earth tones
        Color(hex: "#D2691E"), Color(hex: "#A0522D"), Color(hex: "#CD853F"),
        Color(hex: "#BC8F8F"), Color(hex: "#C19A6B"), Color(hex: "#996515"),
    ]

    private let userDefaultsKey = "tagColorMapping"
    private let knownTagsKey = "knownTags"
    private let colorIndexKey = "nextColorIndex"

    private init() {
        loadColors()
        loadKnownTags()
        loadColorIndex()
    }

    // MARK: - Public Methods

    /// Get color for a tag (returns nil if not assigned yet)
    func getColorForTag(_ tag: String) -> Color? {
        return tagColors[tag]
    }

    /// Get color for a tag (assigns next sequential color if not exists)
    func colorForTag(_ tag: String) -> Color {
        if let existingColor = tagColors[tag] {
            return existingColor
        }

        // Assign next color in sequence (cycles through 72 colors)
        let newColor = getNextColor()
        tagColors[tag] = newColor

        // Also register as known tag (but don't call registerTag to avoid recursion)
        knownTags.insert(tag)

        saveColors()
        saveKnownTags()
        return newColor
    }

    /// Ensure color is assigned for a tag (safe to call during view updates)
    func ensureColorForTag(_ tag: String) {
        guard tagColors[tag] == nil else { return }
        _ = colorForTag(tag)
    }

    /// Register a tag as known (e.g., when creating via + button)
    func registerTag(_ tag: String) {
        let trimmed = tag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if knownTags.insert(trimmed).inserted {
            saveKnownTags()
            // Assign next sequential color immediately when registering
            if tagColors[trimmed] == nil {
                let newColor = getNextColor()
                tagColors[trimmed] = newColor
                saveColors()
            }
        }
    }

    /// Manually set color for a tag
    func setColor(_ color: Color, forTag tag: String) {
        tagColors[tag] = color
        saveColors()
    }

    /// Remove color mapping for a tag
    func removeTag(_ tag: String) {
        tagColors.removeValue(forKey: tag)
        knownTags.remove(tag)
        saveColors()
        saveKnownTags()
    }

    /// Clear all color mappings
    func clearAllColors() {
        tagColors.removeAll()
        knownTags.removeAll()
        saveColors()
        saveKnownTags()
    }

    /// Get all known tags (including those with 0 count)
    func getAllKnownTags() -> Set<String> {
        return knownTags
    }

    // MARK: - Private Methods

    /// Get next color in sequence (cycles through 72 colors)
    private func getNextColor() -> Color {
        let color = colorPalette[nextColorIndex]

        // Increment and wrap around to cycle through colors
        nextColorIndex = (nextColorIndex + 1) % colorPalette.count

        // Save the updated index
        saveColorIndex()

        return color
    }

    // MARK: - Persistence

    private func saveColors() {
        let colorDict = tagColors.mapValues { $0.hexString }
        UserDefaults.standard.set(colorDict, forKey: userDefaultsKey)
    }

    private func loadColors() {
        guard let colorDict = UserDefaults.standard.dictionary(forKey: userDefaultsKey) as? [String: String] else {
            return
        }

        tagColors = colorDict.compactMapValues { hexString in
            Color(hex: hexString)
        }
    }

    private func saveKnownTags() {
        let tagsArray = Array(knownTags)
        UserDefaults.standard.set(tagsArray, forKey: knownTagsKey)
    }

    private func loadKnownTags() {
        guard let tagsArray = UserDefaults.standard.array(forKey: knownTagsKey) as? [String] else {
            return
        }
        knownTags = Set(tagsArray)
    }

    private func saveColorIndex() {
        UserDefaults.standard.set(nextColorIndex, forKey: colorIndexKey)
    }

    private func loadColorIndex() {
        nextColorIndex = UserDefaults.standard.integer(forKey: colorIndexKey)
    }
}

// MARK: - Color Extensions

extension Color {
    var hexString: String {
        let components = NSColor(self).cgColor.components ?? [0, 0, 0, 1]
        let r = Int(components[0] * 255.0)
        let g = Int(components[1] * 255.0)
        let b = Int(components[2] * 255.0)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

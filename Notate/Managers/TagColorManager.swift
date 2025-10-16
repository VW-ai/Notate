import SwiftUI
import Foundation
import Combine

// MARK: - Tag Color Manager
// Manages random color assignment for tags with persistence

class TagColorManager: ObservableObject {
    static let shared = TagColorManager()

    @Published private(set) var tagColors: [String: Color] = [:]

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

    private init() {
        loadColors()
    }

    // MARK: - Public Methods

    /// Get color for a tag (assigns new random color if not exists)
    func colorForTag(_ tag: String) -> Color {
        if let existingColor = tagColors[tag] {
            return existingColor
        }

        // Assign new random color
        let newColor = getRandomUnusedColor()
        tagColors[tag] = newColor
        saveColors()
        return newColor
    }

    /// Manually set color for a tag
    func setColor(_ color: Color, forTag tag: String) {
        tagColors[tag] = color
        saveColors()
    }

    /// Remove color mapping for a tag
    func removeTag(_ tag: String) {
        tagColors.removeValue(forKey: tag)
        saveColors()
    }

    /// Clear all color mappings
    func clearAllColors() {
        tagColors.removeAll()
        saveColors()
    }

    // MARK: - Private Methods

    private func getRandomUnusedColor() -> Color {
        // Get colors that are not currently in use
        let usedColors = Set(tagColors.values.map { $0.hexString })
        let availableColors = colorPalette.filter { color in
            !usedColors.contains(color.hexString)
        }

        // If all colors are used, just pick a random one from the full palette
        if availableColors.isEmpty {
            return colorPalette.randomElement() ?? Color.blue
        }

        // Return random available color
        return availableColors.randomElement() ?? colorPalette.randomElement() ?? Color.blue
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

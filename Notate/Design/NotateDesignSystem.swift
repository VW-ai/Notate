import SwiftUI

// MARK: - Notate Design System v0.2
// Complete design token system for Notate application
// See: /META/DESIGN_SYSTEM.md for full specification

enum NotateDesignSystem {

    // MARK: - Colors

    enum Colors {
        // MARK: Brand Colors
        /// Primary brand color - Slate 600
        static let slate600 = Color(hex: "3E4A54")
        /// Dark variant - Slate 700
        static let slate700 = Color(hex: "2D3741")
        /// Light variant - Slate 500
        static let slate500 = Color(hex: "566672")
        /// Ultra light variant - Slate 400
        static let slate400 = Color(hex: "8A97A3")

        // MARK: Accent Colors
        /// Neural Blue - Intelligence, AI processing, links
        static let neuralBlue = Color(hex: "4A90E2")
        static let neuralBlueLight = Color(hex: "6CA8EA")
        static let neuralBlueDark = Color(hex: "2E75C7")
        static let neuralBlueSubtle = Color(hex: "E8F2FB")

        /// Thought Purple - Creativity, ideas, Piece entries
        static let thoughtPurple = Color(hex: "8B7BDB")
        static let thoughtPurpleLight = Color(hex: "A594E4")
        static let thoughtPurpleDark = Color(hex: "6F5DC8")
        static let thoughtPurpleSubtle = Color(hex: "F2EFFD")

        /// Action Amber - TODOs, priorities, attention
        static let actionAmber = Color(hex: "F5A623")
        static let actionAmberLight = Color(hex: "F7B84D")
        static let actionAmberDark = Color(hex: "D98F0E")
        static let actionAmberSubtle = Color(hex: "FEF6E8")

        /// Success Emerald - Completion, positive feedback
        static let successEmerald = Color(hex: "27AE60")
        static let successEmeraldLight = Color(hex: "52C27D")
        static let successEmeraldDark = Color(hex: "1E8449")
        static let successEmeraldSubtle = Color(hex: "E8F7EF")

        /// Alert Crimson - Errors, destructive actions
        static let alertCrimson = Color(hex: "E74C3C")
        static let alertCrimsonLight = Color(hex: "EC6B5E")
        static let alertCrimsonDark = Color(hex: "C33828")
        static let alertCrimsonSubtle = Color(hex: "FDEDEB")

        // MARK: Neutral Scale
        static let white = Color(hex: "FFFFFF")
        static let ghost = Color(hex: "F8F9FA")
        static let mist = Color(hex: "E9ECEF")
        static let fog = Color(hex: "CED4DA")
        static let cloud = Color(hex: "ADB5BD")
        static let smoke = Color(hex: "6C757D")
        static let ash = Color(hex: "495057")
        static let charcoal = Color(hex: "212529")
        static let void = Color(hex: "000000")

        // MARK: Dark Mode
        static let surfaceDark = Color(hex: "1A1F25")
        static let surfaceLift = Color(hex: "242A31")
        static let surfaceFloat = Color(hex: "2D343D")
        static let borderDark = Color(hex: "3A4149")
        static let textPrimaryDark = Color(hex: "E9ECEF")
        static let textSecondaryDark = Color(hex: "ADB5BD")

        // MARK: Semantic Helpers
        static func background(for colorScheme: ColorScheme) -> Color {
            colorScheme == .dark ? surfaceDark : white
        }

        static func surface(for colorScheme: ColorScheme) -> Color {
            colorScheme == .dark ? surfaceLift : ghost
        }

        static func border(for colorScheme: ColorScheme) -> Color {
            colorScheme == .dark ? borderDark : fog
        }

        static func textPrimary(for colorScheme: ColorScheme) -> Color {
            colorScheme == .dark ? textPrimaryDark : charcoal
        }

        static func textSecondary(for colorScheme: ColorScheme) -> Color {
            colorScheme == .dark ? textSecondaryDark : smoke
        }
    }

    // MARK: - Typography

    enum Typography {
        /// 48px, Bold - Logo wordmark, empty states, hero sections
        static let display = Font.system(size: 48, weight: .bold, design: .rounded)

        /// 32px, Semibold - Page titles, modal headers
        static let h1 = Font.system(size: 32, weight: .semibold, design: .rounded)

        /// 24px, Semibold - Section headers, card titles
        static let h2 = Font.system(size: 24, weight: .semibold, design: .rounded)

        /// 19px, Medium - Subsection headers, list item titles
        static let h3 = Font.system(size: 19, weight: .medium, design: .rounded)

        /// 15px, Regular - Main content, entry text, descriptions
        static let body = Font.system(size: 15, weight: .regular, design: .rounded)

        /// 15px, Medium - Body text with emphasis
        static let bodyMedium = Font.system(size: 15, weight: .medium, design: .rounded)

        /// 15px, Semibold - Body text strong emphasis
        static let bodySemibold = Font.system(size: 15, weight: .semibold, design: .rounded)

        /// 13px, Regular - Metadata, captions, helper text
        static let small = Font.system(size: 13, weight: .regular, design: .rounded)

        /// 13px, Medium - Small text with emphasis
        static let smallMedium = Font.system(size: 13, weight: .medium, design: .rounded)

        /// 11px, Medium - Badges, tags, timestamps
        static let tiny = Font.system(size: 11, weight: .medium, design: .rounded)

        /// 11px, Regular - Tiny regular text
        static let tinyRegular = Font.system(size: 11, weight: .regular, design: .rounded)

        /// 14px, Regular, Monospaced - Triggers, technical details
        static let code = Font.system(size: 14, weight: .regular, design: .monospaced)

        // Line height modifiers
        static func withLineSpacing(_ font: Font, lineHeight: CGFloat) -> Font {
            // SwiftUI doesn't support line-height directly, use .lineSpacing modifier on Text
            return font
        }
    }

    // MARK: - Spacing

    enum Spacing {
        /// 0px - No space
        static let space0: CGFloat = 0

        /// 4px - Micro gaps, inline elements
        static let space1: CGFloat = 4

        /// 8px - Icon-text gaps, small padding
        static let space2: CGFloat = 8

        /// 12px - Compact components
        static let space3: CGFloat = 12

        /// 16px - Standard padding, gaps (most common)
        static let space4: CGFloat = 16

        /// 20px - Comfortable spacing, card inner padding
        static let space5: CGFloat = 20

        /// 24px - Section separation
        static let space6: CGFloat = 24

        /// 32px - Major section breaks
        static let space8: CGFloat = 32

        /// 40px - Page-level spacing
        static let space10: CGFloat = 40

        /// 48px - Dramatic separation
        static let space12: CGFloat = 48

        /// 64px - Massive spacing, hero sections
        static let space16: CGFloat = 64
    }

    // MARK: - Corner Radius

    enum CornerRadius {
        /// 4px - Tags, badges, tiny pills
        static let micro: CGFloat = 4

        /// 8px - Inputs, small buttons
        static let small: CGFloat = 8

        /// 12px - Cards, standard buttons (most common)
        static let medium: CGFloat = 12

        /// 16px - Modals, panels
        static let large: CGFloat = 16

        /// 20px - Hero cards, feature sections
        static let extraLarge: CGFloat = 20

        /// 9999px - Avatars, circular buttons
        static let circle: CGFloat = 9999
    }

    // MARK: - Shadows

    enum Shadow {
        /// Minimal - 0 1px 2px rgba(0,0,0,0.04/0.20)
        static func minimal(darkMode: Bool = false) -> ShadowStyle {
            ShadowStyle(
                color: .black.opacity(darkMode ? 0.20 : 0.04),
                radius: 2,
                x: 0,
                y: 1
            )
        }

        /// Subtle - 0 2px 4px rgba(0,0,0,0.06/0.30)
        static func subtle(darkMode: Bool = false) -> ShadowStyle {
            ShadowStyle(
                color: .black.opacity(darkMode ? 0.30 : 0.06),
                radius: 4,
                x: 0,
                y: 2
            )
        }

        /// Soft - 0 4px 8px rgba(0,0,0,0.08/0.40)
        static func soft(darkMode: Bool = false) -> ShadowStyle {
            ShadowStyle(
                color: .black.opacity(darkMode ? 0.40 : 0.08),
                radius: 8,
                x: 0,
                y: 4
            )
        }

        /// Medium - 0 8px 16px rgba(0,0,0,0.12/0.50)
        static func medium(darkMode: Bool = false) -> ShadowStyle {
            ShadowStyle(
                color: .black.opacity(darkMode ? 0.50 : 0.12),
                radius: 16,
                x: 0,
                y: 8
            )
        }

        /// Strong - 0 16px 32px rgba(0,0,0,0.16/0.60)
        static func strong(darkMode: Bool = false) -> ShadowStyle {
            ShadowStyle(
                color: .black.opacity(darkMode ? 0.60 : 0.16),
                radius: 32,
                x: 0,
                y: 16
            )
        }

        /// Neural Glow - AI processing indicator
        static var neuralGlow: ShadowStyle {
            ShadowStyle(
                color: Colors.neuralBlue.opacity(0.3),
                radius: 16,
                x: 0,
                y: 0
            )
        }

        /// Success Glow - Completion celebration
        static var successGlow: ShadowStyle {
            ShadowStyle(
                color: Colors.successEmerald.opacity(0.25),
                radius: 12,
                x: 0,
                y: 0
            )
        }
    }

    // MARK: - Animation

    enum Animation {
        // Timing functions
        static let easeSnappy = SwiftUI.Animation.timingCurve(0.4, 0.0, 0.2, 1.0)
        static let easeSmooth = SwiftUI.Animation.timingCurve(0.4, 0.0, 0.6, 1.0)
        static let easeGentle = SwiftUI.Animation.timingCurve(0.3, 0.0, 0.7, 1.0)
        static let easeBounce = SwiftUI.Animation.timingCurve(0.68, -0.55, 0.27, 1.55)

        // Durations
        static let instant: Double = 0.1
        static let quick: Double = 0.2
        static let smooth: Double = 0.3
        static let gentle: Double = 0.4
        static let slow: Double = 0.6

        // Common presets
        static let buttonPress = easeSnappy.speed(1.0 / instant)
        static let cardHover = easeGentle.speed(1.0 / quick)
        static let modalAppear = easeSmooth.speed(1.0 / smooth)
        static let celebration = easeBounce.speed(1.0 / slow)
    }
}

// MARK: - Shadow Helper Struct

struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat

    init(color: Color, radius: CGFloat, x: CGFloat = 0, y: CGFloat = 0) {
        self.color = color
        self.radius = radius
        self.x = x
        self.y = y
    }
}

// MARK: - Color Extension (Hex Support)

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

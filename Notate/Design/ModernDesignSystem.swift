import SwiftUI
import Foundation

// MARK: - Modern Design System for Notate

/// A comprehensive design system providing consistent styling across the entire Notate application
struct ModernDesignSystem {

    // MARK: - Typography
    struct Typography {
        static let largeTitle = Font.system(size: 28, weight: .bold, design: .rounded)
        static let title = Font.system(size: 22, weight: .semibold, design: .rounded)
        static let headline = Font.system(size: 18, weight: .semibold)
        static let body = Font.system(size: 15, weight: .medium)
        static let bodyRegular = Font.system(size: 15, weight: .regular)
        static let caption = Font.system(size: 13, weight: .medium)
        static let small = Font.system(size: 12, weight: .regular)
        static let tiny = Font.system(size: 11, weight: .medium)

        // Specialized fonts
        static let monospace = Font.system(.body, design: .monospaced)
        static let code = Font.system(size: 14, design: .monospaced)
    }

    // MARK: - Colors
    struct Colors {
        // Primary colors
        static let accent = Color.accentColor
        static let primary = Color.primary
        static let secondary = Color.secondary

        // Semantic colors
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
        static let info = Color.blue

        // Background colors
        static let surface = Color(NSColor.controlBackgroundColor)
        static let surfaceSecondary = Color(NSColor.tertiarySystemFill)
        static let cardBackground = Color(NSColor.controlBackgroundColor)
        static let surfaceBackground = Color(NSColor.controlBackgroundColor).opacity(0.3)
        static let windowBackground = Color(NSColor.windowBackgroundColor)

        // Interactive colors
        static let buttonPrimary = Color.accentColor
        static let buttonSecondary = Color(NSColor.quaternarySystemFill)
        static let buttonDestructive = Color.red

        // Status colors for entries
        static let todoColor = Color.blue
        static let thoughtColor = Color.orange
        static let completedColor = Color.green

        // Border colors
        static let border = Color(NSColor.separatorColor)
    }

    // MARK: - Spacing
    struct Spacing {
        static let tiny: CGFloat = 4
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let regular: CGFloat = 16
        static let large: CGFloat = 20
        static let extraLarge: CGFloat = 24
        static let huge: CGFloat = 32
        static let massive: CGFloat = 40
    }

    // MARK: - Corner Radius
    struct CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let extraLarge: CGFloat = 20
    }

    // MARK: - Shadow
    struct Shadow {
        static let minimal = Color.black.opacity(0.02)
        static let subtle = Color.black.opacity(0.03)
        static let light = Color.black.opacity(0.08)
        static let medium = Color.black.opacity(0.15)
    }
}

// MARK: - Modern Card Component

struct ModernCard<Content: View>: View {
    let content: Content
    let padding: CGFloat
    let cornerRadius: CGFloat
    let shadowIntensity: Color

    init(
        padding: CGFloat = ModernDesignSystem.Spacing.extraLarge,
        cornerRadius: CGFloat = ModernDesignSystem.CornerRadius.large,
        shadowIntensity: Color = ModernDesignSystem.Shadow.subtle,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.shadowIntensity = shadowIntensity
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(ModernDesignSystem.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: shadowIntensity, radius: 8, x: 0, y: 2)
    }
}

// MARK: - Modern Section Header

struct ModernSectionHeader: View {
    let title: String
    let subtitle: String?
    let icon: String?

    init(title: String, subtitle: String? = nil, icon: String? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
    }

    var body: some View {
        HStack(spacing: ModernDesignSystem.Spacing.medium) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(ModernDesignSystem.Colors.accent)
                    .frame(width: 32, height: 32)
                    .background(ModernDesignSystem.Colors.accent.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.small))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(ModernDesignSystem.Typography.headline)
                    .foregroundColor(ModernDesignSystem.Colors.primary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(ModernDesignSystem.Typography.caption)
                        .foregroundColor(ModernDesignSystem.Colors.secondary)
                }
            }

            Spacer()
        }
    }
}

// MARK: - Modern Button

enum ModernButtonStyle {
    case primary, secondary, destructive, ghost
}

enum ModernButtonSize {
    case small, medium, large

    var padding: EdgeInsets {
        switch self {
        case .small:
            return EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
        case .medium:
            return EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16)
        case .large:
            return EdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20)
        }
    }

    var fontSize: CGFloat {
        switch self {
        case .small: return 12
        case .medium: return 14
        case .large: return 16
        }
    }
}

struct ModernButton: View {
    let title: String
    let icon: String?
    let style: ModernButtonStyle
    let size: ModernButtonSize
    let action: () -> Void

    init(
        title: String,
        icon: String? = nil,
        style: ModernButtonStyle = .primary,
        size: ModernButtonSize = .medium,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.size = size
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: size.fontSize, weight: .medium))
                }

                Text(title)
                    .font(.system(size: size.fontSize, weight: .medium))
            }
            .foregroundColor(foregroundColor)
            .padding(size.padding)
            .background(backgroundColor)
            .clipShape(Capsule())
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var foregroundColor: Color {
        switch style {
        case .primary, .destructive:
            return .white
        case .secondary:
            return ModernDesignSystem.Colors.primary
        case .ghost:
            return ModernDesignSystem.Colors.accent
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .primary:
            return ModernDesignSystem.Colors.buttonPrimary
        case .secondary:
            return ModernDesignSystem.Colors.buttonSecondary
        case .destructive:
            return ModernDesignSystem.Colors.buttonDestructive
        case .ghost:
            return Color.clear
        }
    }
}

// MARK: - Modern Toggle Row

struct ModernToggleRow: View {
    let title: String
    let subtitle: String?
    @Binding var isOn: Bool

    init(title: String, subtitle: String? = nil, isOn: Binding<Bool>) {
        self.title = title
        self.subtitle = subtitle
        self._isOn = isOn
    }

    var body: some View {
        HStack(spacing: ModernDesignSystem.Spacing.regular) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(ModernDesignSystem.Typography.body)
                    .foregroundColor(ModernDesignSystem.Colors.primary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(ModernDesignSystem.Typography.small)
                        .foregroundColor(ModernDesignSystem.Colors.secondary)
                }
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle())
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Modern List Item

struct ModernListItem<Content: View>: View {
    let content: Content
    let onTap: (() -> Void)?

    init(onTap: (() -> Void)? = nil, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.onTap = onTap
    }

    var body: some View {
        Button(action: onTap ?? {}) {
            content
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(onTap == nil)
    }
}

// MARK: - Entry Type Badge

struct EntryTypeBadge: View {
    let type: EntryType
    let size: BadgeSize

    enum BadgeSize {
        case small, medium

        var padding: EdgeInsets {
            switch self {
            case .small:
                return EdgeInsets(top: 2, leading: 6, bottom: 2, trailing: 6)
            case .medium:
                return EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
            }
        }

        var fontSize: CGFloat {
            switch self {
            case .small: return 10
            case .medium: return 12
            }
        }
    }

    init(type: EntryType, size: BadgeSize = .medium) {
        self.type = type
        self.size = size
    }

    var body: some View {
        Text(type.displayName)
            .font(.system(size: size.fontSize, weight: .medium))
            .foregroundColor(badgeTextColor)
            .padding(size.padding)
            .background(badgeBackgroundColor)
            .clipShape(Capsule())
    }

    private var badgeTextColor: Color {
        switch type {
        case .todo:
            return ModernDesignSystem.Colors.todoColor
        case .thought:
            return ModernDesignSystem.Colors.thoughtColor
        }
    }

    private var badgeBackgroundColor: Color {
        switch type {
        case .todo:
            return ModernDesignSystem.Colors.todoColor.opacity(0.15)
        case .thought:
            return ModernDesignSystem.Colors.thoughtColor.opacity(0.15)
        }
    }
}

// MARK: - Priority Indicator

struct PriorityIndicator: View {
    let priority: EntryPriority
    let style: IndicatorStyle

    enum IndicatorStyle {
        case dots, badge
    }

    init(priority: EntryPriority, style: IndicatorStyle = .dots) {
        self.priority = priority
        self.style = style
    }

    var body: some View {
        switch style {
        case .dots:
            dotsIndicator
        case .badge:
            badgeIndicator
        }
    }

    private var dotsIndicator: some View {
        HStack(spacing: 3) {
            ForEach(0..<priority.level, id: \.self) { _ in
                Circle()
                    .fill(priorityColor)
                    .frame(width: 6, height: 6)
            }
        }
    }

    private var badgeIndicator: some View {
        Text(priority.displayName)
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(priorityColor)
            .clipShape(Capsule())
    }

    private var priorityColor: Color {
        switch priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .green
        }
    }
}

// MARK: - Extensions for Priority

extension EntryPriority {
    var level: Int {
        switch self {
        case .low: return 1
        case .medium: return 2
        case .high: return 3
        }
    }
}

// MARK: - View Extensions

extension View {
    func modernCard(
        padding: CGFloat = ModernDesignSystem.Spacing.extraLarge,
        cornerRadius: CGFloat = ModernDesignSystem.CornerRadius.large,
        shadowIntensity: Color = ModernDesignSystem.Shadow.subtle
    ) -> some View {
        ModernCard(padding: padding, cornerRadius: cornerRadius, shadowIntensity: shadowIntensity) {
            self
        }
    }
}
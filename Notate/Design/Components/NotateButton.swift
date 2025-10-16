import SwiftUI

// MARK: - Notate Button Component
// Unified button with multiple styles and sizes

enum NotateButtonStyle {
    case primary
    case secondary
    case ghost
    case destructive

    var backgroundColor: Color {
        switch self {
        case .primary:
            return .notateNeuralBlue
        case .secondary:
            return .notateMist
        case .ghost:
            return .clear
        case .destructive:
            return .notateAlertCrimson
        }
    }

    var backgroundColorDark: Color {
        switch self {
        case .primary:
            return .notateNeuralBlue
        case .secondary:
            return .notateSurfaceLift
        case .ghost:
            return .clear
        case .destructive:
            return .notateAlertCrimson
        }
    }

    var foregroundColor: Color {
        switch self {
        case .primary, .destructive:
            return .white
        case .secondary:
            return .notateAsh
        case .ghost:
            return .notateNeuralBlue
        }
    }

    var foregroundColorDark: Color {
        switch self {
        case .primary, .destructive:
            return .white
        case .secondary:
            return Color.white
        case .ghost:
            return .notateNeuralBlueLight
        }
    }

    var borderColor: Color? {
        switch self {
        case .secondary:
            return .notateFog
        default:
            return nil
        }
    }

    var borderColorDark: Color? {
        switch self {
        case .secondary:
            return .notateBorderDark
        default:
            return nil
        }
    }
}

enum NotateButtonSize {
    case small
    case medium
    case large

    var padding: EdgeInsets {
        switch self {
        case .small:
            return EdgeInsets(
                top: NotateDesignSystem.Spacing.space2,
                leading: NotateDesignSystem.Spacing.space3,
                bottom: NotateDesignSystem.Spacing.space2,
                trailing: NotateDesignSystem.Spacing.space3
            )
        case .medium:
            return EdgeInsets(
                top: NotateDesignSystem.Spacing.space3,
                leading: NotateDesignSystem.Spacing.space4,
                bottom: NotateDesignSystem.Spacing.space3,
                trailing: NotateDesignSystem.Spacing.space4
            )
        case .large:
            return EdgeInsets(
                top: NotateDesignSystem.Spacing.space4,
                leading: NotateDesignSystem.Spacing.space5,
                bottom: NotateDesignSystem.Spacing.space4,
                trailing: NotateDesignSystem.Spacing.space5
            )
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

struct NotateButton: View {
    let title: String
    let icon: String?
    let style: NotateButtonStyle
    let size: NotateButtonSize
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressed = false
    @State private var isHovering = false

    init(
        title: String,
        icon: String? = nil,
        style: NotateButtonStyle = .primary,
        size: NotateButtonSize = .medium,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.size = size
        self.action = action
    }

    var body: some View {
        Button(action: {
            withAnimation(NotateDesignSystem.Animation.buttonPress) {
                isPressed = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
                action()
            }
        }) {
            HStack(spacing: NotateDesignSystem.Spacing.space2) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: size.fontSize, weight: .medium))
                }

                Text(title)
                    .font(.system(size: size.fontSize, weight: .medium, design: .rounded))
            }
            .foregroundColor(foregroundColor)
            .padding(size.padding)
            .background(backgroundColor)
            .cornerRadius(NotateDesignSystem.CornerRadius.small + 2) // Slightly rounder than input fields
            .overlay(
                RoundedRectangle(cornerRadius: NotateDesignSystem.CornerRadius.small + 2)
                    .stroke(borderColor ?? Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.98 : (isHovering ? 1.01 : 1.0))
        .opacity(isPressed ? 0.9 : 1.0)
        .animation(NotateDesignSystem.Animation.cardHover, value: isHovering)
        .animation(NotateDesignSystem.Animation.buttonPress, value: isPressed)
        .onHover { hovering in
            isHovering = hovering
        }
    }

    private var backgroundColor: Color {
        let base = colorScheme == .dark ? style.backgroundColorDark : style.backgroundColor
        return isHovering ? base.opacity(0.9) : base
    }

    private var foregroundColor: Color {
        colorScheme == .dark ? style.foregroundColorDark : style.foregroundColor
    }

    private var borderColor: Color? {
        colorScheme == .dark ? style.borderColorDark : style.borderColor
    }
}

// MARK: - Preview

#if DEBUG
struct NotateButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Styles
            HStack(spacing: 12) {
                NotateButton(title: "Primary", icon: "star.fill", style: .primary, size: .medium) {
                    print("Primary tapped")
                }

                NotateButton(title: "Secondary", icon: "gear", style: .secondary, size: .medium) {
                    print("Secondary tapped")
                }

                NotateButton(title: "Ghost", icon: "link", style: .ghost, size: .medium) {
                    print("Ghost tapped")
                }

                NotateButton(title: "Delete", icon: "trash", style: .destructive, size: .medium) {
                    print("Destructive tapped")
                }
            }

            // Sizes
            VStack(spacing: 12) {
                NotateButton(title: "Small Button", icon: "sparkles", style: .primary, size: .small) {
                    print("Small tapped")
                }

                NotateButton(title: "Medium Button", icon: "sparkles", style: .primary, size: .medium) {
                    print("Medium tapped")
                }

                NotateButton(title: "Large Button", icon: "sparkles", style: .primary, size: .large) {
                    print("Large tapped")
                }
            }

            // Without icons
            HStack(spacing: 12) {
                NotateButton(title: "Execute", style: .primary, size: .medium) {
                    print("Execute tapped")
                }

                NotateButton(title: "Cancel", style: .secondary, size: .medium) {
                    print("Cancel tapped")
                }
            }
        }
        .padding(40)
        .frame(width: 800, height: 600)
        .preferredColorScheme(.light)

        // Dark mode preview
        VStack(spacing: 20) {
            HStack(spacing: 12) {
                NotateButton(title: "Primary", icon: "star.fill", style: .primary, size: .medium) {}
                NotateButton(title: "Secondary", icon: "gear", style: .secondary, size: .medium) {}
                NotateButton(title: "Ghost", icon: "link", style: .ghost, size: .medium) {}
                NotateButton(title: "Delete", icon: "trash", style: .destructive, size: .medium) {}
            }
        }
        .padding(40)
        .frame(width: 800, height: 600)
        .background(Color.notateSurfaceDark)
        .preferredColorScheme(.dark)
    }
}
#endif

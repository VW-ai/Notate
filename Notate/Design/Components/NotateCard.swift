import SwiftUI

// MARK: - Notate Card Component
// Reusable card container with consistent styling

struct NotateCard<Content: View>: View {
    let content: Content
    let padding: CGFloat
    let cornerRadius: CGFloat
    let useShadow: Bool
    let shadowLevel: ShadowLevel

    @Environment(\.colorScheme) private var colorScheme

    enum ShadowLevel {
        case minimal
        case subtle
        case soft
        case medium
        case strong
        case none
    }

    init(
        padding: CGFloat = NotateDesignSystem.Spacing.space5,
        cornerRadius: CGFloat = NotateDesignSystem.CornerRadius.medium,
        shadow: ShadowLevel = .subtle,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.shadowLevel = shadow
        self.useShadow = shadow != .none
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .if(useShadow) { view in
                applyShadow(to: view)
            }
    }

    private var cardBackground: Color {
        colorScheme == .dark
            ? NotateDesignSystem.Colors.surfaceLift
            : .white
    }

    @ViewBuilder
    private func applyShadow<V: View>(to view: V) -> some View {
        let isDark = colorScheme == .dark

        switch shadowLevel {
        case .minimal:
            view.shadowMinimal(darkMode: isDark)
        case .subtle:
            view.shadowSubtle(darkMode: isDark)
        case .soft:
            view.shadowSoft(darkMode: isDark)
        case .medium:
            view.shadowMedium(darkMode: isDark)
        case .strong:
            view.shadowStrong(darkMode: isDark)
        case .none:
            view
        }
    }
}

// MARK: - Preview

#if DEBUG
struct NotateCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 24) {
            // Default card
            NotateCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Default Card")
                        .font(.notateH3)
                        .foregroundColor(.primary)

                    Text("This is a card with default padding, corner radius, and subtle shadow.")
                        .font(.notateBody)
                        .foregroundColor(.secondary)
                }
            }

            // Compact card
            NotateCard(
                padding: NotateDesignSystem.Spacing.space3,
                cornerRadius: NotateDesignSystem.CornerRadius.small,
                shadow: .minimal
            ) {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.notateActionAmber)

                    Text("Compact Card")
                        .font(.notateSmall)
                }
            }

            // Elevated card
            NotateCard(
                padding: NotateDesignSystem.Spacing.space6,
                cornerRadius: NotateDesignSystem.CornerRadius.large,
                shadow: .medium
            ) {
                VStack(spacing: 12) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 32))
                        .foregroundColor(.notateNeuralBlue)

                    Text("Elevated Card")
                        .font(.notateH2)

                    Text("With medium shadow and large corner radius")
                        .font(.notateSmall)
                        .foregroundColor(.secondary)
                }
            }

            // No shadow card
            NotateCard(shadow: .none) {
                Text("No Shadow Card")
                    .font(.notateBody)
            }
        }
        .padding(40)
        .frame(width: 600)
        .preferredColorScheme(.light)

        // Dark mode preview
        VStack(spacing: 24) {
            NotateCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Dark Mode Card")
                        .font(.notateH3)
                        .foregroundColor(.primary)

                    Text("Cards automatically adapt to dark mode.")
                        .font(.notateBody)
                        .foregroundColor(.secondary)
                }
            }

            NotateCard(shadow: .soft) {
                HStack {
                    Image(systemName: "moon.stars.fill")
                        .foregroundColor(.notateThoughtPurple)

                    Text("Elevated in Dark Mode")
                        .font(.notateBodyMedium)
                }
            }
        }
        .padding(40)
        .frame(width: 600)
        .background(Color.notateSurfaceDark)
        .preferredColorScheme(.dark)
    }
}
#endif

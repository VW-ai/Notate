import SwiftUI

// MARK: - Notate Badge Component
// Status badges with semantic colors

enum NotateBadgeStyle: Equatable {
    case processing
    case success
    case error
    case info
    case custom(color: Color)

    static func == (lhs: NotateBadgeStyle, rhs: NotateBadgeStyle) -> Bool {
        switch (lhs, rhs) {
        case (.processing, .processing),
             (.success, .success),
             (.error, .error),
             (.info, .info):
            return true
        case (.custom, .custom):
            return true  // We consider all custom styles equal for animation purposes
        default:
            return false
        }
    }

    var color: Color {
        switch self {
        case .processing:
            return .notateNeuralBlue
        case .success:
            return .notateSuccessEmerald
        case .error:
            return .notateAlertCrimson
        case .info:
            return .notateSlate
        case .custom(let color):
            return color
        }
    }

    var icon: String? {
        switch self {
        case .processing:
            return "arrow.clockwise"
        case .success:
            return "checkmark"
        case .error:
            return "xmark"
        case .info:
            return "info.circle"
        case .custom:
            return nil
        }
    }
}

struct NotateBadge: View {
    let text: String
    let style: NotateBadgeStyle
    let showIcon: Bool

    @State private var isAnimating = false

    init(
        text: String,
        style: NotateBadgeStyle = .info,
        showIcon: Bool = true
    ) {
        self.text = text
        self.style = style
        self.showIcon = showIcon
    }

    var body: some View {
        HStack(spacing: NotateDesignSystem.Spacing.space1) {
            if showIcon, let icon = style.icon {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .medium))
                    .rotationEffect(.degrees(isAnimating && style == .processing ? 360 : 0))
            }

            Text(text)
                .font(.notateTiny)
                .fontWeight(.medium)
        }
        .foregroundColor(style.color)
        .padding(.horizontal, NotateDesignSystem.Spacing.space2)
        .padding(.vertical, NotateDesignSystem.Spacing.space1)
        .background(style.color.opacity(0.15))
        .clipShape(Capsule())
        .onAppear {
            if style == .processing {
                withAnimation(
                    .linear(duration: 1.0)
                    .repeatForever(autoreverses: false)
                ) {
                    isAnimating = true
                }
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct NotateBadge_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                NotateBadge(text: "Processing", style: .processing)
                NotateBadge(text: "Success", style: .success)
                NotateBadge(text: "Error", style: .error)
                NotateBadge(text: "Info", style: .info)
            }

            HStack(spacing: 12) {
                NotateBadge(text: "TODO", style: .custom(color: .notateActionAmber))
                NotateBadge(text: "Piece", style: .custom(color: .notateThoughtPurple))
            }

            HStack(spacing: 12) {
                NotateBadge(text: "No Icon", style: .info, showIcon: false)
                NotateBadge(text: "With Icon", style: .info, showIcon: true)
            }
        }
        .padding(40)
        .frame(width: 600, height: 400)
        .preferredColorScheme(.light)

        // Dark mode
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                NotateBadge(text: "Processing", style: .processing)
                NotateBadge(text: "Success", style: .success)
                NotateBadge(text: "Error", style: .error)
            }
        }
        .padding(40)
        .frame(width: 600, height: 400)
        .background(Color.notateSurfaceDark)
        .preferredColorScheme(.dark)
    }
}
#endif

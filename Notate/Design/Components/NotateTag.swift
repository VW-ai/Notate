import SwiftUI

// MARK: - Notate Tag Component
// Tag chips for categorization and filtering

struct NotateTag: View {
    let tag: String
    let onRemove: (() -> Void)?
    let isInteractive: Bool

    @State private var isHovering = false

    init(
        tag: String,
        onRemove: (() -> Void)? = nil
    ) {
        self.tag = tag
        self.onRemove = onRemove
        self.isInteractive = onRemove != nil
    }

    var body: some View {
        HStack(spacing: NotateDesignSystem.Spacing.space2) {
            Text(tag)
                .font(.notateTiny)
                .fontWeight(.medium)

            if let onRemove = onRemove {
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.notateThoughtPurple.opacity(0.7))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .foregroundColor(.notateThoughtPurple)
        .padding(.horizontal, NotateDesignSystem.Spacing.space2 + 2)
        .padding(.vertical, NotateDesignSystem.Spacing.space1 + 2)
        .background(Color.notateThoughtPurpleSubtle)
        .cornerRadius(NotateDesignSystem.CornerRadius.micro + 2)
        .overlay(
            RoundedRectangle(cornerRadius: NotateDesignSystem.CornerRadius.micro + 2)
                .stroke(Color.notateThoughtPurple.opacity(0.2), lineWidth: 1)
        )
        .scaleEffect(isHovering && isInteractive ? 1.05 : 1.0)
        .animation(NotateDesignSystem.Animation.cardHover, value: isHovering)
        .onHover { hovering in
            if isInteractive {
                isHovering = hovering
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct NotateTag_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 24) {
            // Read-only tags
            HStack(spacing: 8) {
                NotateTag(tag: "#work")
                NotateTag(tag: "#personal")
                NotateTag(tag: "#ideas")
                NotateTag(tag: "#shopping")
            }

            // Removable tags
            HStack(spacing: 8) {
                NotateTag(tag: "#work") {
                    print("Remove #work")
                }
                NotateTag(tag: "#urgent") {
                    print("Remove #urgent")
                }
                NotateTag(tag: "#project-alpha") {
                    print("Remove #project-alpha")
                }
            }

            // Tags in a flow layout
            FlowLayout(spacing: 8) {
                ForEach(["#coding", "#design", "#meeting", "#brainstorm", "#deadline", "#review", "#testing"], id: \.self) { tag in
                    NotateTag(tag: tag) {
                        print("Remove \(tag)")
                    }
                }
            }
            .frame(maxWidth: 400)
        }
        .padding(40)
        .frame(width: 600, height: 500)
        .preferredColorScheme(.light)

        // Dark mode
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                NotateTag(tag: "#dark-mode")
                NotateTag(tag: "#testing") {
                    print("Remove")
                }
            }
        }
        .padding(40)
        .frame(width: 600, height: 400)
        .background(Color.notateSurfaceDark)
        .preferredColorScheme(.dark)
    }
}

// MARK: - Flow Layout Helper

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        var totalHeight: CGFloat = 0
        var totalWidth: CGFloat = 0
        var lineWidth: CGFloat = 0
        var lineHeight: CGFloat = 0

        for size in sizes {
            if lineWidth + size.width > (proposal.width ?? 0) {
                totalHeight += lineHeight + spacing
                lineWidth = size.width
                lineHeight = size.height
            } else {
                lineWidth += size.width + spacing
                lineHeight = max(lineHeight, size.height)
            }
            totalWidth = max(totalWidth, lineWidth)
        }

        totalHeight += lineHeight
        return CGSize(width: totalWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var lineX = bounds.minX
        var lineY = bounds.minY
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if lineX + size.width > bounds.maxX {
                lineY += lineHeight + spacing
                lineHeight = 0
                lineX = bounds.minX
            }

            subview.place(
                at: CGPoint(x: lineX, y: lineY),
                proposal: ProposedViewSize(size)
            )

            lineHeight = max(lineHeight, size.height)
            lineX += size.width + spacing
        }
    }
}

#endif

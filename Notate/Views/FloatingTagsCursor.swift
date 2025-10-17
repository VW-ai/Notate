import SwiftUI

// MARK: - Floating Tags Cursor
// Visual feedback showing tags following the mouse cursor during drag-to-assign
// Multiple tags fan out in a beautiful animated stack

struct FloatingTagsCursor: View {
    let tags: [String]
    let position: CGPoint

    @StateObject private var tagColorManager = TagColorManager.shared

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(Array(tags.prefix(5).enumerated()), id: \.element) { index, tag in
                TagCursorChip(
                    tag: tag,
                    color: tagColorManager.getColorForTag(tag) ?? .gray,
                    index: index,
                    totalCount: min(tags.count, 5)
                )
            }

            // "+X more" badge if more than 5 tags
            if tags.count > 5 {
                Text("+\(tags.count - 5)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.blue.opacity(0.9))
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.4), lineWidth: 1)
                    )
                    .offset(x: 0, y: CGFloat(min(tags.count, 5)) * 8 + 20)
                    .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
            }
        }
        .position(x: position.x + 40, y: position.y + 20) // Position near cursor
        .allowsHitTesting(false) // Don't intercept clicks
    }
}

// Individual tag chip in the cursor with fan-out effect
struct TagCursorChip: View {
    let tag: String
    let color: Color
    let index: Int
    let totalCount: Int

    var body: some View {
        Text("#\(tag)")
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(color.opacity(0.9))
            )
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.6), lineWidth: 1.5)
            )
            .shadow(color: Color.black.opacity(0.5), radius: 10, x: 0, y: 5)
        // Fan out effect - each tag slightly offset for depth
        .offset(
            x: CGFloat(index - totalCount / 2) * 12,
            y: CGFloat(index) * 8
        )
        .scaleEffect(1.0 - CGFloat(index) * 0.05) // Slight scale difference for depth
        .zIndex(Double(totalCount - index)) // Stack order - front to back
    }
}

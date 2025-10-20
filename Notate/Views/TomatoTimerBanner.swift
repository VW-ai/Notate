import SwiftUI

// MARK: - Tomato Timer Banner
// Red animated banner showing active timer with event name and tag input

struct TomatoTimerBanner: View {
    @StateObject private var operatorState = OperatorState.shared
    @StateObject private var tagColorManager = TagColorManager.shared
    @EnvironmentObject var appState: AppState

    @State private var animationOffset: CGFloat = 0

    // Get top 8 tag suggestions from TagStore (universal, not date-dependent)
    private var topUsedTags: [String] {
        TagStore.shared.getTopTags(limit: 8, excluding: operatorState.timerTags)
    }

    var body: some View {
        ZStack {
            // Subtle red background
            Color(hex: "#8B3A3A").opacity(0.4) // Muted dark red

            // Thin sliding red bar
            slidingBar

            // Content
            VStack(spacing: 12) {
                // Timer display
                timerDisplay

                // Event name input
                eventNameField

                // Tags row
                tagsRow
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .clipped() // Prevent bar from overflowing horizontally
    }

    // MARK: - Sliding Bar

    private var slidingBar: some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(Color(hex: "#C0392B")) // Darker red for the sliding bar
                .frame(width: 8) // Thin vertical bar
                .offset(x: animationOffset)
                .onAppear {
                    withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) {
                        animationOffset = geometry.size.width
                    }
                }
        }
    }

    // MARK: - Timer Display

    private var timerDisplay: some View {
        HStack(spacing: 8) {
            Image(systemName: "timer")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)

            Text(operatorState.formattedDuration(seconds: operatorState.timerElapsedSeconds))
                .font(.system(size: 24, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
        }
    }

    // MARK: - Event Name Field

    private var eventNameField: some View {
        HStack(spacing: 10) {
            Image(systemName: "pencil")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.9))

            TextField("Event name...", text: $operatorState.timerEventName)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: - Tags Row

    private var tagsRow: some View {
        HStack(spacing: 8) {
            // Existing tags
            ForEach(operatorState.timerTags, id: \.self) { tag in
                tagPill(tag: tag, removable: true)
            }

            // Add tag suggestions
            if operatorState.timerTags.count < 5 {
                ForEach(topUsedTags.prefix(5 - operatorState.timerTags.count), id: \.self) { tag in
                    tagSuggestion(tag: tag)
                }
            }
        }
    }

    // MARK: - Tag Pill (Removable)

    private func tagPill(tag: String, removable: Bool) -> some View {
        HStack(spacing: 4) {
            Text("#\(tag)")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)

            if removable {
                Button(action: {
                    operatorState.timerTags.removeAll { $0 == tag }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(tagColorManager.getColorForTag(tag)?.opacity(0.9) ?? Color.gray.opacity(0.9))
        )
    }

    // MARK: - Tag Suggestion (Clickable)

    private func tagSuggestion(tag: String) -> some View {
        Button(action: {
            if !operatorState.timerTags.contains(tag) {
                operatorState.timerTags.append(tag)
                tagColorManager.registerTag(tag)
            }
        }) {
            Text("#\(tag)")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .strokeBorder(Color.white.opacity(0.4), lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

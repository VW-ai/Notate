import SwiftUI

// MARK: - Tomato Timer Banner
// Red animated banner showing active timer with event name and tag input

struct TomatoTimerBanner: View {
    @StateObject private var operatorState = OperatorState.shared
    @StateObject private var tagColorManager = TagColorManager.shared
    @EnvironmentObject var appState: AppState

    @State private var animationOffset: CGFloat = 0

    // Tag suggestions (from all entries)
    private var allExistingTags: [String] {
        let allTags = appState.entries.flatMap { $0.tags }
        return Array(Set(allTags)).sorted()
    }

    private var topUsedTags: [String] {
        let allTags = appState.entries.flatMap { $0.tags }

        var tagCounts: [String: Int] = [:]
        for tag in allTags {
            tagCounts[tag, default: 0] += 1
        }

        return tagCounts
            .sorted { $0.value > $1.value }
            .prefix(8)
            .map { $0.key }
            .filter { !operatorState.timerTags.contains($0) }
    }

    var body: some View {
        ZStack {
            // Animated flowing background
            flowingBackground

            // Content
            VStack(spacing: 16) {
                // Timer display
                timerDisplay

                // Event name input
                eventNameField

                // Tags row
                tagsRow
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 20)
        }
    }

    // MARK: - Flowing Background

    private var flowingBackground: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(hex: "#E74C3C"),
                Color(hex: "#C0392B"),
                Color(hex: "#E74C3C"),
                Color(hex: "#C0392B")
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
        .offset(x: animationOffset)
        .onAppear {
            withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
                animationOffset = 400
            }
        }
    }

    // MARK: - Timer Display

    private var timerDisplay: some View {
        HStack(spacing: 12) {
            Image(systemName: "timer")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)

            Text(operatorState.formattedDuration(seconds: operatorState.timerElapsedSeconds))
                .font(.system(size: 32, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
        }
    }

    // MARK: - Event Name Field

    private var eventNameField: some View {
        HStack(spacing: 12) {
            Image(systemName: "pencil")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.8))

            TextField("Event name...", text: $operatorState.timerEventName)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .frame(maxWidth: 400)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.2))
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

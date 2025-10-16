import SwiftUI

// MARK: - Insights View
// Time insights and analytics (to be implemented)

struct InsightsView: View {
    var body: some View {
        VStack(spacing: NotateDesignSystem.Spacing.space6) {
            Spacer()

            // Icon
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 64, weight: .light))
                .foregroundColor(.notateNeuralBlue.opacity(0.5))

            // Title
            Text("Insights")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.primary)

            // Description
            Text("Time insights and analytics coming soon")
                .font(.notateBody)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "#1C1C1E"))
    }
}

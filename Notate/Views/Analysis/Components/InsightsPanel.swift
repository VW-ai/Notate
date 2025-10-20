import SwiftUI

struct InsightsPanel: View {
    let insights: [Insight]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("💡 INSIGHTS")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            if insights.isEmpty {
                emptyState
            } else {
                insightsList
            }
        }
        .padding()
        .background(Color(hex: "#1C1C1E"))
    }

    // MARK: - Insights List

    private var insightsList: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(insights) { insight in
                InsightRow(insight: insight)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        HStack(spacing: 12) {
            Image(systemName: "lightbulb")
                .font(.system(size: 32))
                .foregroundColor(.gray.opacity(0.5))

            Text("No insights available yet. Track more time to see patterns and suggestions.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

// MARK: - Insight Row

struct InsightRow: View {
    let insight: Insight

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // Icon
            Text(insight.icon)
                .font(.title2)

            // Message
            VStack(alignment: .leading, spacing: 4) {
                Text(insight.message)
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)

                // Action button if available
                if let actionTitle = insight.actionTitle, let action = insight.action {
                    Button(action: action) {
                        Text(actionTitle)
                            .font(.callout)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 2)
                }
            }

            Spacer()
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        InsightsPanel(insights: [
            Insight(
                icon: "📊",
                message: "You spent 42.8% of your time on #coding this week (+12% vs last week)"
            ),
            Insight(
                icon: "⏰",
                message: "Your most productive hours: 9AM-12PM (peak at 10AM)"
            ),
            Insight(
                icon: "⚠️",
                message: "23% of events are untagged (15 events) - tag them for better insights",
                actionTitle: "Review",
                action: {
                    print("Review tapped")
                }
            ),
            Insight(
                icon: "🎯",
                message: "You had 3x more deep focus sessions (2h+) compared to last week"
            ),
            Insight(
                icon: "📅",
                message: "Wednesday is your most active day with 12.3 hours tracked"
            )
        ])

        InsightsPanel(insights: [])
    }
    .padding()
    .frame(width: 700)
}

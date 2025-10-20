import SwiftUI

struct AnalysisStatsCards: View {
    let analytics: TimeAnalytics
    let previousAnalytics: TimeAnalytics?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("OVERVIEW")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                // Total Time Card
                StatCard(
                    value: analytics.formattedTotalHours,
                    label: "Total Time",
                    comparison: getHoursComparison(),
                    icon: "clock.fill"
                )

                // Events Logged Card
                StatCard(
                    value: "\(analytics.eventCount)",
                    label: "Events Logged",
                    comparison: getEventsComparison(),
                    icon: "calendar"
                )

                // Most Active Day Card
                if let mostActiveDay = analytics.mostActiveDay {
                    StatCard(
                        value: mostActiveDay.dayOfWeek,
                        subtitle: mostActiveDay.formattedHours,
                        label: "Most Active Day",
                        icon: "star.fill"
                    )
                } else {
                    StatCard(
                        value: "—",
                        label: "Most Active Day",
                        icon: "star"
                    )
                }

                // Top Category Card
                if let topTag = analytics.topTag {
                    StatCard(
                        value: topTag.tag,
                        subtitle: topTag.formattedHours,
                        label: "Top Category",
                        icon: "tag.fill",
                        iconColor: topTag.color
                    )
                } else {
                    StatCard(
                        value: "—",
                        label: "Top Category",
                        icon: "tag"
                    )
                }
            }

            // Tagged vs Untagged Progress Bar
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Tagged:")
                        .font(.callout)
                        .foregroundColor(.secondary)

                    Text(String(format: "%.0f%%", analytics.taggedPercentage))
                        .font(.callout)
                        .fontWeight(.medium)

                    Spacer()

                    Text("Untagged:")
                        .font(.callout)
                        .foregroundColor(.secondary)

                    Text(String(format: "%.0f%%", analytics.untaggedPercentage))
                        .font(.callout)
                        .fontWeight(.medium)
                        .foregroundColor(.orange)
                }

                GeometryReader { geometry in
                    HStack(spacing: 0) {
                        // Tagged portion
                        Rectangle()
                            .fill(Color.blue.opacity(0.7))
                            .frame(width: geometry.size.width * (analytics.taggedPercentage / 100))

                        // Untagged portion
                        Rectangle()
                            .fill(Color.orange.opacity(0.5))
                            .frame(width: geometry.size.width * (analytics.untaggedPercentage / 100))

                        Spacer(minLength: 0)
                    }
                }
                .frame(height: 8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(4)
            }
            .padding(.top, 4)
        }
        .padding()
        .background(Color(hex: "#1C1C1E"))
    }

    // MARK: - Comparison Helpers

    private func getHoursComparison() -> ComparisonMetric? {
        guard let previous = previousAnalytics else { return nil }
        return ComparisonMetric(
            current: analytics.totalHours,
            previous: previous.totalHours
        )
    }

    private func getEventsComparison() -> ComparisonMetric? {
        guard let previous = previousAnalytics else { return nil }
        return ComparisonMetric(
            current: Double(analytics.eventCount),
            previous: Double(previous.eventCount)
        )
    }
}

// MARK: - Stat Card Component

struct StatCard: View {
    let value: String
    var subtitle: String? = nil
    let label: String
    var comparison: ComparisonMetric? = nil
    var icon: String
    var iconColor: Color = .blue

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(iconColor.opacity(0.8))

                Spacer()

                if let comparison = comparison {
                    ComparisonBadge(metric: comparison)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
            }

            Text(label)
                .font(.callout)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.05))
        .cornerRadius(10)
    }
}

// MARK: - Comparison Badge

struct ComparisonBadge: View {
    let metric: ComparisonMetric

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: metric.isIncreasing ? "arrow.up" : (metric.isDecreasing ? "arrow.down" : "minus"))
                .font(.caption2)

            Text(metric.changeFormatted)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(badgeColor.opacity(0.2))
        .foregroundColor(badgeColor)
        .cornerRadius(4)
    }

    private var badgeColor: Color {
        if metric.isIncreasing {
            return .green
        } else if metric.isDecreasing {
            return .red
        } else {
            return .gray
        }
    }
}

// MARK: - Preview

#Preview {
    AnalysisStatsCards(
        analytics: TimeAnalytics(
            timeRange: .week,
            totalHours: 152800, // 42.5 hours in seconds
            eventCount: 127,
            tagBreakdown: [
                TagTimeData(
                    id: "coding",
                    tag: "#coding",
                    hours: 65520,
                    eventCount: 45,
                    percentage: 42.8,
                    color: .blue
                ),
                TagTimeData(
                    id: "meetings",
                    tag: "#meetings",
                    hours: 37800,
                    eventCount: 32,
                    percentage: 24.7,
                    color: .green
                )
            ],
            untaggedHours: 10080,
            dailyBreakdown: [
                DailyTimeData(
                    id: Date(),
                    date: Date(),
                    tagHours: ["#coding": 44280],
                    totalHours: 44280
                )
            ],
            hourlyHeatmap: Array(repeating: Array(repeating: 0, count: 24), count: 7),
            sessionDistribution: [],
            weeklyTrend: [],
            insights: []
        ),
        previousAnalytics: TimeAnalytics(
            timeRange: .week,
            totalHours: 136000,
            eventCount: 119,
            tagBreakdown: [],
            untaggedHours: 9000,
            dailyBreakdown: [],
            hourlyHeatmap: [],
            sessionDistribution: [],
            weeklyTrend: [],
            insights: []
        )
    )
    .padding()
    .frame(width: 800)
}

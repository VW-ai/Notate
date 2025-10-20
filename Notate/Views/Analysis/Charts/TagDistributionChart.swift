import SwiftUI
import Charts

struct TagDistributionChart: View {
    let tagData: [TagTimeData]
    let maxSlices: Int = 8

    private var displayData: [TagTimeData] {
        let topTags = Array(tagData.prefix(maxSlices - 1))

        // If there are more tags, group them as "Other"
        if tagData.count > maxSlices {
            let otherTags = Array(tagData.dropFirst(maxSlices - 1))
            let otherHours = otherTags.reduce(0.0) { $0 + $1.hours }
            let otherCount = otherTags.reduce(0) { $0 + $1.eventCount }
            let otherPercentage = otherTags.reduce(0.0) { $0 + $1.percentage }

            let otherData = TagTimeData(
                id: "Other",
                tag: "Other",
                hours: otherHours,
                eventCount: otherCount,
                percentage: otherPercentage,
                color: .gray.opacity(0.6)
            )

            return topTags + [otherData]
        }

        return topTags
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("📊 TAG DISTRIBUTION")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            if displayData.isEmpty {
                emptyState
            } else {
                HStack(spacing: 24) {
                    // Pie Chart
                    pieChart
                        .frame(width: 200, height: 200)

                    // Legend
                    legend
                }
            }
        }
        .padding()
        .background(Color(hex: "#1C1C1E"))
        
    }

    // MARK: - Pie Chart

    private var pieChart: some View {
        Chart(displayData) { item in
            SectorMark(
                angle: .value("Hours", item.hours),
                innerRadius: .ratio(0.5),
                angularInset: 1.5
            )
            .foregroundStyle(item.color.gradient)
            .annotation(position: .overlay) {
                if item.percentage > 8 { // Only show percentage if slice is large enough
                    Text(String(format: "%.0f%%", item.percentage))
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
        }
    }

    // MARK: - Legend

    private var legend: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(displayData) { item in
                HStack(spacing: 8) {
                    // Color indicator
                    Circle()
                        .fill(item.color)
                        .frame(width: 12, height: 12)

                    // Tag name
                    Text(item.tag)
                        .font(.callout)
                        .fontWeight(.medium)

                    Spacer()

                    // Percentage
                    Text(item.formattedPercentage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.pie")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.5))

            Text("No data available")
                .font(.callout)
                .foregroundColor(.secondary)

            Text("Track time in your calendar to see distribution")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        TagDistributionChart(tagData: [
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
            ),
            TagTimeData(
                id: "writing",
                tag: "#writing",
                hours: 22680,
                eventCount: 18,
                percentage: 14.8,
                color: .purple
            ),
            TagTimeData(
                id: "reading",
                tag: "#reading",
                hours: 11160,
                eventCount: 12,
                percentage: 7.3,
                color: .orange
            ),
            TagTimeData(
                id: "Untagged",
                tag: "Untagged",
                hours: 10080,
                eventCount: 8,
                percentage: 6.6,
                color: .gray
            ),
            TagTimeData(
                id: "exercise",
                tag: "#exercise",
                hours: 5760,
                eventCount: 4,
                percentage: 3.8,
                color: .red
            )
        ])

        TagDistributionChart(tagData: [])
    }
    .padding()
    .frame(width: 600)
}

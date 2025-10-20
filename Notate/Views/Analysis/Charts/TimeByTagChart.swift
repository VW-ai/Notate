import SwiftUI
import Charts

struct TimeByTagChart: View {
    let tagData: [TagTimeData]
    let maxItems: Int = 10

    private var displayData: [TagTimeData] {
        Array(tagData.prefix(maxItems))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("⏱️  TIME BY CATEGORY")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            if displayData.isEmpty {
                emptyState
            } else {
                chartView
            }
        }
        .padding()
        .background(Color(hex: "#1C1C1E"))
        
    }

    // MARK: - Chart View

    private var chartView: some View {
        Chart(displayData) { item in
            BarMark(
                x: .value("Hours", item.hours / 3600),
                y: .value("Tag", item.tag)
            )
            .foregroundStyle(item.color.gradient)
            .annotation(position: .trailing, alignment: .leading) {
                HStack(spacing: 8) {
                    Text(item.formattedHours)
                        .font(.callout)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    Text(item.formattedPercentage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.leading, 8)
            }
        }
        .chartXAxis {
            AxisMarks(position: .bottom) { value in
                AxisValueLabel {
                    if let hours = value.as(Double.self) {
                        Text("\(Int(hours))h")
                            .font(.caption2)
                    }
                }
                AxisGridLine()
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisValueLabel {
                    if let tag = value.as(String.self) {
                        Text(tag)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
            }
        }
        .frame(height: CGFloat(displayData.count * 40 + 40))
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.5))

            Text("No data available")
                .font(.callout)
                .foregroundColor(.secondary)

            Text("Track time in your calendar to see analytics")
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
        TimeByTagChart(tagData: [
            TagTimeData(
                id: "coding",
                tag: "#coding",
                hours: 65520, // 18.2 hours
                eventCount: 45,
                percentage: 42.8,
                color: .blue
            ),
            TagTimeData(
                id: "meetings",
                tag: "#meetings",
                hours: 37800, // 10.5 hours
                eventCount: 32,
                percentage: 24.7,
                color: .green
            ),
            TagTimeData(
                id: "writing",
                tag: "#writing",
                hours: 22680, // 6.3 hours
                eventCount: 18,
                percentage: 14.8,
                color: .purple
            ),
            TagTimeData(
                id: "reading",
                tag: "#reading",
                hours: 11160, // 3.1 hours
                eventCount: 12,
                percentage: 7.3,
                color: .orange
            ),
            TagTimeData(
                id: "Untagged",
                tag: "Untagged",
                hours: 10080, // 2.8 hours
                eventCount: 8,
                percentage: 6.6,
                color: .gray
            ),
            TagTimeData(
                id: "exercise",
                tag: "#exercise",
                hours: 5760, // 1.6 hours
                eventCount: 4,
                percentage: 3.8,
                color: .red
            )
        ])

        TimeByTagChart(tagData: [])
    }
    .padding()
    .frame(width: 700)
}

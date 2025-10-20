import SwiftUI
import Charts

struct DailyDistributionChart: View {
    let dailyData: [DailyTimeData]
    let topTags: [String] // Top 5 tags to show, rest go into "Other"

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("📅 DAILY TIME DISTRIBUTION")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            if dailyData.isEmpty {
                emptyState
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    chartView
                    legend
                }
            }
        }
        .padding()
        .background(Color(hex: "#1C1C1E"))
        
    }

    // MARK: - Chart View

    private var chartView: some View {
        let chart = Chart {
            ForEach(dailyData) { day in
                ForEach(getStackedData(for: day), id: \.tag) { segment in
                    BarMark(
                        x: .value("Date", day.date, unit: .day),
                        y: .value("Hours", segment.hours / 3600),
                        stacking: .standard
                    )
                    .foregroundStyle(getColor(for: segment.tag))
                }
            }
        }

        return chart
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                    AxisGridLine()
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let hours = value.as(Double.self) {
                            Text("\(Int(hours))h")
                                .font(.caption2)
                        }
                    }
                    AxisGridLine()
                }
            }
            .chartLegend(.hidden)
            .frame(height: 280)
    }

    // MARK: - Legend

    private var legend: some View {
        HStack(spacing: 16) {
            ForEach(displayTags, id: \.self) { tag in
                HStack(spacing: 4) {
                    Rectangle()
                        .fill(getColor(for: tag))
                        .frame(width: 12, height: 12)
                        .cornerRadius(2)

                    Text(tag)
                        .font(.caption)
                }
            }
        }
    }

    // MARK: - Data Helpers

    private var displayTags: [String] {
        var tags = Array(topTags.prefix(5))
        // Add "Other" if there are more tags
        if topTags.count > 5 {
            tags.append("Other")
        }
        return tags
    }

    private func getStackedData(for day: DailyTimeData) -> [TagSegment] {
        var segments: [TagSegment] = []

        // Add top 5 tags
        for tag in topTags.prefix(5) {
            if let hours = day.tagHours[tag] {
                segments.append(TagSegment(tag: tag, hours: hours))
            }
        }

        // Group remaining as "Other"
        if topTags.count > 5 {
            let otherHours = topTags.dropFirst(5).reduce(0.0) { sum, tag in
                sum + (day.tagHours[tag] ?? 0)
            }
            if otherHours > 0 {
                segments.append(TagSegment(tag: "Other", hours: otherHours))
            }
        }

        return segments
    }

    private func getColor(for tag: String) -> Color {
        if tag == "Other" {
            return .gray.opacity(0.6)
        } else if tag == "Untagged" {
            return .gray
        } else {
            return TagColorManager.shared.colorForTag(tag)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.5))

            Text("No data available")
                .font(.callout)
                .foregroundColor(.secondary)

            Text("Track time daily to see distribution patterns")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
    }
}

// MARK: - Helper Struct

struct TagSegment {
    let tag: String
    let hours: TimeInterval
}

// MARK: - Preview

#Preview {
    let calendar = Calendar.current
    let today = Date()

    let dailyData = Array((0..<7).map { dayOffset -> DailyTimeData in
        let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!

        return DailyTimeData(
            id: date,
            date: date,
            tagHours: [
                "#coding": Double.random(in: 14400...28800),
                "#meetings": Double.random(in: 7200...14400),
                "#writing": Double.random(in: 3600...10800),
                "#reading": Double.random(in: 1800...7200),
                "Untagged": Double.random(in: 0...5400)
            ],
            totalHours: 0
        )
    }.reversed())

    DailyDistributionChart(
        dailyData: dailyData,
        topTags: ["#coding", "#meetings", "#writing", "#reading", "Untagged"]
    )
    .padding()
    .frame(width: 700)
}

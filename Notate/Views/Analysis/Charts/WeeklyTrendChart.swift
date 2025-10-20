import SwiftUI
import Charts

struct WeeklyTrendChart: View {
    let weeklyData: [WeeklyData]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("📈 WEEKLY HOURS TREND")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            if weeklyData.isEmpty {
                emptyState
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    chartView
                    trendIndicator
                }
            }
        }
        .padding()
        .background(Color(hex: "#1C1C1E"))
        
    }

    // MARK: - Chart View

    private var chartView: some View {
        let areaGradient = LinearGradient(
            colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.05)],
            startPoint: .top,
            endPoint: .bottom
        )

        let chart = Chart {
            ForEach(weeklyData) { week in
                LineMark(
                    x: .value("Week", week.weekStart, unit: .weekOfYear),
                    y: .value("Hours", week.totalHours / 3600)
                )
                .foregroundStyle(Color.blue.gradient)
                .interpolationMethod(.catmullRom)

                AreaMark(
                    x: .value("Week", week.weekStart, unit: .weekOfYear),
                    y: .value("Hours", week.totalHours / 3600)
                )
                .foregroundStyle(areaGradient)
                .interpolationMethod(.catmullRom)

                PointMark(
                    x: .value("Week", week.weekStart, unit: .weekOfYear),
                    y: .value("Hours", week.totalHours / 3600)
                )
                .foregroundStyle(Color.blue)
                .symbol(.circle)
                .symbolSize(30)
            }
        }

        return chart
            .chartXAxis {
                AxisMarks(values: .stride(by: .weekOfYear)) { value in
                    AxisValueLabel(format: .dateTime.week())
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
            .frame(height: 200)
    }

    // MARK: - Trend Indicator

    private var trendIndicator: some View {
        Group {
            if let trend = calculateTrend() {
                HStack(spacing: 4) {
                    Text("Trend:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Image(systemName: trend.isIncreasing ? "arrow.up.right" : (trend.isDecreasing ? "arrow.down.right" : "minus"))
                        .font(.caption2)
                        .foregroundColor(trend.isIncreasing ? .green : (trend.isDecreasing ? .red : .gray))

                    Text(trend.isIncreasing ? "Increasing" : (trend.isDecreasing ? "Decreasing" : "Stable"))
                        .font(.caption)
                        .foregroundColor(trend.isIncreasing ? .green : (trend.isDecreasing ? .red : .gray))

                    if abs(trend.change) > 0.1 {
                        Text("(\(trend.changeFormatted))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Trend Calculation

    private func calculateTrend() -> ComparisonMetric? {
        guard weeklyData.count >= 3 else { return nil }

        // Compare first half vs second half of the data
        let midpoint = weeklyData.count / 2
        let firstHalf = weeklyData.prefix(midpoint)
        let secondHalf = weeklyData.suffix(weeklyData.count - midpoint)

        let firstAvg = firstHalf.reduce(0.0) { $0 + $1.totalHours } / Double(firstHalf.count)
        let secondAvg = secondHalf.reduce(0.0) { $0 + $1.totalHours } / Double(secondHalf.count)

        return ComparisonMetric(current: secondAvg, previous: firstAvg)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.5))

            Text("No trend data available")
                .font(.callout)
                .foregroundColor(.secondary)

            Text("Track time over multiple weeks to see trends")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
    }
}

// MARK: - Preview

#Preview {
    let calendar = Calendar.current
    let today = Date()

    let weeklyData = Array((0..<12).map { weekOffset -> WeeklyData in
        let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: today)!

        // Simulate upward trend
        let baseHours: Double = 120000 // ~33 hours in seconds
        let trendHours = baseHours + Double(12 - weekOffset) * 7200 // +2h per week

        return WeeklyData(
            id: weekStart,
            weekStart: weekStart,
            totalHours: trendHours + Double.random(in: -7200...7200) // Add some variance
        )
    }.reversed())

    VStack(spacing: 20) {
        WeeklyTrendChart(weeklyData: weeklyData)

        WeeklyTrendChart(weeklyData: [])
    }
    .padding()
    .frame(width: 700)
}

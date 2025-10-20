import SwiftUI
import Charts

struct FocusSessionChart: View {
    let sessionData: [SessionBucket]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🎯 FOCUS SESSION DISTRIBUTION")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            if sessionData.allSatisfy({ $0.count == 0 }) {
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
        Chart(sessionData) { bucket in
            BarMark(
                x: .value("Duration", bucket.range),
                y: .value("Count", bucket.count)
            )
            .foregroundStyle(barColor(for: bucket))
            .annotation(position: .top) {
                if bucket.count > 0 {
                    Text("\(bucket.count)")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
            }
        }
        .chartXAxis {
            AxisMarks { value in
                AxisValueLabel {
                    if let range = value.as(String.self) {
                        Text(range)
                            .font(.caption2)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisValueLabel {
                    if let count = value.as(Int.self) {
                        Text("\(count)")
                            .font(.caption2)
                    }
                }
                AxisGridLine()
            }
        }
        .frame(height: 200)
    }

    // MARK: - Bar Color Logic

    private func barColor(for bucket: SessionBucket) -> Color {
        // Color code by session length:
        // Short sessions (< 1h) = yellow
        // Medium sessions (1-2h) = blue
        // Long sessions (2h+) = green
        switch bucket.id {
        case "0-30m", "30m-1h":
            return .yellow.opacity(0.7)
        case "1-2h":
            return .blue.opacity(0.7)
        case "2-4h", "4h+":
            return .green.opacity(0.7)
        default:
            return .gray.opacity(0.7)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.5))

            Text("No sessions tracked")
                .font(.callout)
                .foregroundColor(.secondary)

            Text("Log calendar events to see session lengths")
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
        FocusSessionChart(sessionData: [
            SessionBucket(id: "0-30m", range: "0-30m", count: 45, lowerBound: 0, upperBound: 1800),
            SessionBucket(id: "30m-1h", range: "30m-1h", count: 32, lowerBound: 1800, upperBound: 3600),
            SessionBucket(id: "1-2h", range: "1-2h", count: 28, lowerBound: 3600, upperBound: 7200),
            SessionBucket(id: "2-4h", range: "2-4h", count: 15, lowerBound: 7200, upperBound: 14400),
            SessionBucket(id: "4h+", range: "4h+", count: 7, lowerBound: 14400, upperBound: .infinity)
        ])

        FocusSessionChart(sessionData: SessionBucket.buckets)
    }
    .padding()
    .frame(width: 500)
}

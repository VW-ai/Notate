import SwiftUI

struct TimeOfDayHeatmap: View {
    let heatmapData: [[Double]] // 7 days × 24 hours

    private let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    private let cellSize: CGFloat = 24

    private var maxValue: Double {
        heatmapData.flatMap { $0 }.max() ?? 1.0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🌡️  TIME OF DAY HEATMAP")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            if isEmpty {
                emptyState
            } else {
                heatmapView
            }
        }
        .padding()
        .background(Color(hex: "#1C1C1E"))
        
    }

    // MARK: - Heatmap View

    private var heatmapView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Hour labels (top)
            HStack(spacing: 0) {
                // Empty space for day labels
                Text("")
                    .frame(width: 50)

                ForEach(0..<24, id: \.self) { hour in
                    if hour % 3 == 0 {
                        Text("\(hour)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .frame(width: cellSize * 3, alignment: .leading)
                    }
                }
            }
            .padding(.bottom, 4)

            // Heatmap grid
            VStack(alignment: .leading, spacing: 2) {
                ForEach(0..<7, id: \.self) { dayIndex in
                    HStack(spacing: 2) {
                        // Day label
                        Text(days[dayIndex])
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .frame(width: 45, alignment: .leading)

                        // Hour cells
                        ForEach(0..<24, id: \.self) { hourIndex in
                            let value = heatmapData[dayIndex][hourIndex]
                            HeatmapCell(value: value, maxValue: maxValue)
                        }
                    }
                }
            }

            // Legend
            legend
                .padding(.top, 12)
        }
    }

    // MARK: - Legend

    private var legend: some View {
        HStack(spacing: 8) {
            Text("0h")
                .font(.caption2)
                .foregroundColor(.secondary)

            HStack(spacing: 2) {
                ForEach(0..<5, id: \.self) { index in
                    Rectangle()
                        .fill(intensityColor(for: Double(index) / 4.0))
                        .frame(width: 16, height: 12)
                        .cornerRadius(2)
                }
            }

            Text("\(Int(maxValue))h+")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Helpers

    private var isEmpty: Bool {
        return heatmapData.flatMap { $0 }.allSatisfy { $0 == 0 }
    }

    private func intensityColor(for ratio: Double) -> Color {
        // Blue gradient from light to dark
        let lightBlue = Color.blue.opacity(0.1)
        let darkBlue = Color.blue.opacity(0.9)

        return Color(
            red: lightBlue.components.red * (1 - ratio) + darkBlue.components.red * ratio,
            green: lightBlue.components.green * (1 - ratio) + darkBlue.components.green * ratio,
            blue: lightBlue.components.blue * (1 - ratio) + darkBlue.components.blue * ratio
        )
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.5))

            Text("No data available")
                .font(.callout)
                .foregroundColor(.secondary)

            Text("Track time throughout the week to see patterns")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
    }
}

// MARK: - Heatmap Cell

struct HeatmapCell: View {
    let value: Double
    let maxValue: Double

    private var intensity: Double {
        guard maxValue > 0 else { return 0 }
        return min(value / maxValue, 1.0)
    }

    private var cellColor: Color {
        if value == 0 {
            return Color.gray.opacity(0.05)
        } else if intensity < 0.2 {
            return Color.blue.opacity(0.2)
        } else if intensity < 0.4 {
            return Color.blue.opacity(0.4)
        } else if intensity < 0.6 {
            return Color.blue.opacity(0.6)
        } else if intensity < 0.8 {
            return Color.blue.opacity(0.8)
        } else {
            return Color.blue.opacity(0.95)
        }
    }

    var body: some View {
        Rectangle()
            .fill(cellColor)
            .frame(width: 24, height: 24)
            .cornerRadius(3)
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(Color.gray.opacity(0.1), lineWidth: 0.5)
            )
            .help(value > 0 ? "\(String(format: "%.1f", value))h" : "No activity")
    }
}

// MARK: - Color Extension for RGB Components

extension Color {
    var components: (red: Double, green: Double, blue: Double, opacity: Double) {
        let nsColor = NSColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var opacity: CGFloat = 0

        nsColor.usingColorSpace(.deviceRGB)?.getRed(&red, green: &green, blue: &blue, alpha: &opacity)

        return (Double(red), Double(green), Double(blue), Double(opacity))
    }
}

// MARK: - Preview

#Preview {
    // Generate sample heatmap data with realistic patterns
    let heatmap = (0..<7).map { day -> [Double] in
        (0..<24).map { hour in
            // Simulate work hours (9-5) being busier
            if hour >= 9 && hour <= 17 {
                return Double.random(in: 1.0...4.0)
            } else if hour >= 6 && hour <= 22 {
                return Double.random(in: 0...2.0)
            } else {
                return 0
            }
        }
    }

    VStack(spacing: 20) {
        TimeOfDayHeatmap(heatmapData: heatmap)

        TimeOfDayHeatmap(heatmapData: Array(repeating: Array(repeating: 0, count: 24), count: 7))
    }
    .padding()
    .frame(width: 700)
}

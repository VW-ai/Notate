import SwiftUI
import UniformTypeIdentifiers

struct AnalysisView: View {
    @StateObject private var viewModel = AnalysisViewModel()
    @State private var showExportMenu = false

    var body: some View {
        VStack(spacing: 0) {
            // Top spacer to match other pages
            Spacer()
                .frame(height: 80)
                .background(Color(hex: "#1C1C1E"))

            // Time range selector at top center
            timeRangeHeader

            // Scrollable content
            ScrollView {
                VStack(spacing: 20) {
                    // Stats Cards
                    AnalysisStatsCards(
                        analytics: viewModel.analytics,
                        previousAnalytics: viewModel.previousPeriodAnalytics
                    )

                    // Time by Tag Chart
                    TimeByTagChart(tagData: viewModel.analytics.tagBreakdown)

                    // Tag Distribution & Daily Distribution Row
                    HStack(alignment: .top, spacing: 20) {
                        TagDistributionChart(tagData: viewModel.analytics.tagBreakdown)
                            .frame(maxWidth: .infinity)

                        DailyDistributionChart(
                            dailyData: viewModel.analytics.dailyBreakdown,
                            topTags: Array(viewModel.analytics.tagBreakdown.prefix(5).map { $0.tag })
                        )
                        .frame(maxWidth: .infinity)
                    }

                    // Heatmap & Focus Sessions Row
                    HStack(alignment: .top, spacing: 20) {
                        TimeOfDayHeatmap(heatmapData: viewModel.analytics.hourlyHeatmap)
                            .frame(maxWidth: .infinity)

                        FocusSessionChart(sessionData: viewModel.analytics.sessionDistribution)
                            .frame(maxWidth: .infinity)
                    }

                    // Weekly Trend
                    WeeklyTrendChart(weeklyData: viewModel.analytics.weeklyTrend)

                    // Insights
                    InsightsPanel(insights: viewModel.analytics.insights)
                }
                .padding()
            }
        }
        .background(Color(hex: "#1C1C1E"))
        .overlay {
            if viewModel.isLoading {
                loadingOverlay
            }
        }
    }

    // MARK: - Time Range Header

    private var timeRangeHeader: some View {
        HStack(spacing: 20) {
            // Refresh button (left)
            Button(action: {
                viewModel.loadAnalytics()
            }) {
                Image(systemName: "arrow.clockwise")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.7))
            }
            .buttonStyle(.plain)
            .help("Refresh analytics")

            Spacer()

            // Time range picker (center)
            TimeRangePicker(
                selectedRange: $viewModel.selectedTimeRange,
                onRangeChange: { newRange in
                    viewModel.changeTimeRange(newRange)
                }
            )

            Spacer()

            // Export menu (right)
            Menu {
                Button("Export as CSV") {
                    exportCSV()
                }

                Button("Export as JSON") {
                    exportJSON()
                }
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.7))
            }
            .buttonStyle(.plain)
            .help("Export analytics data")
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 16)
        .background(Color(hex: "#1C1C1E"))
    }

    // MARK: - Loading Overlay

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.2)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                ProgressView()
                    .scaleEffect(0.8)

                Text("Loading analytics...")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
            .padding(24)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
            .shadow(radius: 10)
        }
    }

    // MARK: - Export Functions

    private func exportCSV() {
        let csv = viewModel.exportCSV()

        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.commaSeparatedText]
        savePanel.nameFieldStringValue = "notate-analytics-\(Date().ISO8601Format()).csv"

        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                do {
                    try csv.write(to: url, atomically: true, encoding: .utf8)
                    print("✅ Exported CSV to: \(url)")
                } catch {
                    print("❌ Failed to export CSV: \(error)")
                }
            }
        }
    }

    private func exportJSON() {
        guard let jsonData = viewModel.exportJSON() else {
            print("❌ Failed to generate JSON")
            return
        }

        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.json]
        savePanel.nameFieldStringValue = "notate-analytics-\(Date().ISO8601Format()).json"

        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                do {
                    try jsonData.write(to: url)
                    print("✅ Exported JSON to: \(url)")
                } catch {
                    print("❌ Failed to export JSON: \(error)")
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AnalysisView()
    }
    .frame(width: 1000, height: 800)
}

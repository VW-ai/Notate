import Foundation
import SwiftUI
import EventKit
import Combine

@MainActor
class AnalysisViewModel: ObservableObject {
    @Published var analytics: TimeAnalytics = .empty
    @Published var selectedTimeRange: TimeRange = .week
    @Published var isLoading: Bool = false
    @Published var selectedTags: Set<String> = []
    @Published var showAllDayEvents: Bool = true

    // Custom date range for .custom time range
    @Published var customStartDate: Date = Date()
    @Published var customEndDate: Date = Date()

    private let calendarService = CalendarService.shared
    private let tagColorManager = TagColorManager.shared
    private var cancellables = Set<AnyCancellable>()

    // For week-over-week comparisons
    @Published var previousPeriodAnalytics: TimeAnalytics?

    init() {
        setupObservers()
        loadAnalytics()
    }

    // MARK: - Setup

    private func setupObservers() {
        // Reload when calendar events change
        calendarService.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                // Debounce calendar updates
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self?.loadAnalytics()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Data Loading

    func loadAnalytics() {
        isLoading = true

        Task {
            let analytics = await calculateAnalytics(for: selectedTimeRange)
            let previousAnalytics = await calculatePreviousPeriodAnalytics()

            await MainActor.run {
                self.analytics = analytics
                self.previousPeriodAnalytics = previousAnalytics
                self.isLoading = false
                print("📊 Analytics loaded: \(analytics.eventCount) events, \(analytics.formattedTotalHours)")
            }
        }
    }

    func changeTimeRange(_ timeRange: TimeRange) {
        selectedTimeRange = timeRange
        loadAnalytics()
    }

    func setCustomDateRange(start: Date, end: Date) {
        customStartDate = start
        customEndDate = end
        selectedTimeRange = .custom
        loadAnalytics()
    }

    // MARK: - Analytics Calculation

    private func calculateAnalytics(for timeRange: TimeRange) async -> TimeAnalytics {
        let dateRange = timeRange.dateRange(customStart: customStartDate, customEnd: customEndDate)
        let events = await fetchEvents(from: dateRange.start, to: dateRange.end)

        // Filter events
        let filteredEvents = filterEvents(events)

        // Calculate metrics
        let tagBreakdown = calculateTagBreakdown(from: filteredEvents)
        let dailyBreakdown = calculateDailyBreakdown(from: filteredEvents)
        let hourlyHeatmap = calculateHourlyHeatmap(from: filteredEvents)
        let sessionDistribution = calculateSessionDistribution(from: filteredEvents)
        let weeklyTrend = calculateWeeklyTrend(from: filteredEvents)
        let insights = await generateInsights(events: filteredEvents, tagBreakdown: tagBreakdown, dailyBreakdown: dailyBreakdown)

        let totalHours = filteredEvents.reduce(0.0) { $0 + $1.endTime.timeIntervalSince($1.startTime) }
        let untaggedHours = filteredEvents
            .filter { extractTags(from: $0.notes).isEmpty }
            .reduce(0.0) { $0 + $1.endTime.timeIntervalSince($1.startTime) }

        return TimeAnalytics(
            timeRange: timeRange,
            totalHours: totalHours,
            eventCount: filteredEvents.count,
            tagBreakdown: tagBreakdown,
            untaggedHours: untaggedHours,
            dailyBreakdown: dailyBreakdown,
            hourlyHeatmap: hourlyHeatmap,
            sessionDistribution: sessionDistribution,
            weeklyTrend: weeklyTrend,
            insights: insights
        )
    }

    private func calculatePreviousPeriodAnalytics() async -> TimeAnalytics? {
        let currentRange = selectedTimeRange.dateRange(customStart: customStartDate, customEnd: customEndDate)
        let duration = currentRange.end.timeIntervalSince(currentRange.start)

        let previousEnd = currentRange.start
        let previousStart = previousEnd.addingTimeInterval(-duration)

        let events = await fetchEvents(from: previousStart, to: previousEnd)
        let filteredEvents = filterEvents(events)

        let totalHours = filteredEvents.reduce(0.0) { $0 + $1.endTime.timeIntervalSince($1.startTime) }
        let untaggedHours = filteredEvents
            .filter { extractTags(from: $0.notes).isEmpty }
            .reduce(0.0) { $0 + $1.endTime.timeIntervalSince($1.startTime) }

        return TimeAnalytics(
            timeRange: selectedTimeRange,
            totalHours: totalHours,
            eventCount: filteredEvents.count,
            tagBreakdown: [],
            untaggedHours: untaggedHours,
            dailyBreakdown: [],
            hourlyHeatmap: [],
            sessionDistribution: [],
            weeklyTrend: [],
            insights: []
        )
    }

    // MARK: - Event Fetching

    private func fetchEvents(from startDate: Date, to endDate: Date) async -> [CalendarEvent] {
        return await calendarService.fetchAllEvents(from: startDate, to: endDate)
    }

    private func filterEvents(_ events: [CalendarEvent]) -> [CalendarEvent] {
        return events.filter { event in
            // Filter out all-day events if disabled
            if !showAllDayEvents && event.isAllDay {
                return false
            }

            // Filter by selected tags
            if !selectedTags.isEmpty {
                let eventTags = extractTags(from: event.notes)
                if eventTags.isEmpty {
                    // Include untagged events if "Untagged" is selected
                    return selectedTags.contains("Untagged")
                } else {
                    // Check if event has any of the selected tags
                    return !Set(eventTags).isDisjoint(with: selectedTags)
                }
            }

            return true
        }
    }

    // MARK: - Tag Breakdown

    private func calculateTagBreakdown(from events: [CalendarEvent]) -> [TagTimeData] {
        var tagHours: [String: TimeInterval] = [:]
        var tagEventCounts: [String: Int] = [:]

        let totalHours = events.reduce(0.0) { $0 + $1.endTime.timeIntervalSince($1.startTime) }

        for event in events {
            let duration = event.endTime.timeIntervalSince(event.startTime)
            let tags = extractTags(from: event.notes)

            if tags.isEmpty {
                // Untagged event
                tagHours["Untagged", default: 0] += duration
                tagEventCounts["Untagged", default: 0] += 1
            } else {
                // Distribute duration among all tags
                let durationPerTag = duration / Double(tags.count)
                for tag in tags {
                    let tagWithHash = "#\(tag)"
                    tagHours[tagWithHash, default: 0] += durationPerTag
                    tagEventCounts[tagWithHash, default: 0] += 1
                }
            }
        }

        // Convert to TagTimeData and sort by hours descending
        let breakdown = tagHours.map { (tag, hours) -> TagTimeData in
            let percentage = totalHours > 0 ? (hours / totalHours) * 100 : 0
            let color = tag == "Untagged" ? Color.gray : tagColorManager.colorForTag(tag)

            return TagTimeData(
                id: tag,
                tag: tag,
                hours: hours,
                eventCount: tagEventCounts[tag] ?? 0,
                percentage: percentage,
                color: color
            )
        }.sorted { $0.hours > $1.hours }

        return breakdown
    }

    // MARK: - Daily Breakdown

    private func calculateDailyBreakdown(from events: [CalendarEvent]) -> [DailyTimeData] {
        let calendar = Calendar.current
        var dailyData: [Date: [String: TimeInterval]] = [:]

        for event in events {
            let day = calendar.startOfDay(for: event.startTime)
            let duration = event.endTime.timeIntervalSince(event.startTime)
            let tags = extractTags(from: event.notes)

            if dailyData[day] == nil {
                dailyData[day] = [:]
            }

            if tags.isEmpty {
                dailyData[day]?["Untagged", default: 0] += duration
            } else {
                let durationPerTag = duration / Double(tags.count)
                for tag in tags {
                    let tagWithHash = "#\(tag)"
                    dailyData[day]?[tagWithHash, default: 0] += durationPerTag
                }
            }
        }

        return dailyData.map { (date, tagHours) -> DailyTimeData in
            let totalHours = tagHours.values.reduce(0, +)
            return DailyTimeData(
                id: date,
                date: date,
                tagHours: tagHours,
                totalHours: totalHours
            )
        }.sorted { $0.date < $1.date }
    }

    // MARK: - Hourly Heatmap

    private func calculateHourlyHeatmap(from events: [CalendarEvent]) -> [[Double]] {
        let calendar = Calendar.current
        var heatmap = Array(repeating: Array(repeating: 0.0, count: 24), count: 7)

        for event in events {
            if event.isAllDay { continue }

            let weekday = calendar.component(.weekday, from: event.startTime)
            let hour = calendar.component(.hour, from: event.startTime)
            let duration = event.endTime.timeIntervalSince(event.startTime) / 3600 // Convert to hours

            // Weekday: 1 = Sunday, 2 = Monday, ..., 7 = Saturday
            // Convert to 0-based index with Monday = 0
            let dayIndex = (weekday + 5) % 7

            heatmap[dayIndex][hour] += duration
        }

        return heatmap
    }

    // MARK: - Session Distribution

    private func calculateSessionDistribution(from events: [CalendarEvent]) -> [SessionBucket] {
        var bucketCounts: [String: Int] = [
            "0-30m": 0,
            "30m-1h": 0,
            "1-2h": 0,
            "2-4h": 0,
            "4h+": 0
        ]

        for event in events {
            if event.isAllDay { continue }

            let duration = event.endTime.timeIntervalSince(event.startTime)
            let bucket = SessionBucket.bucket(for: duration, count: 0)
            bucketCounts[bucket.id, default: 0] += 1
        }

        return SessionBucket.buckets.map { template in
            SessionBucket(
                id: template.id,
                range: template.range,
                count: bucketCounts[template.id] ?? 0,
                lowerBound: template.lowerBound,
                upperBound: template.upperBound
            )
        }
    }

    // MARK: - Weekly Trend

    private func calculateWeeklyTrend(from events: [CalendarEvent]) -> [WeeklyData] {
        let calendar = Calendar.current
        var weeklyHours: [Date: TimeInterval] = [:]

        for event in events {
            let weekStart = calendar.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: event.startTime).date ?? event.startTime
            let duration = event.endTime.timeIntervalSince(event.startTime)
            weeklyHours[weekStart, default: 0] += duration
        }

        return weeklyHours.map { (weekStart, hours) -> WeeklyData in
            WeeklyData(
                id: weekStart,
                weekStart: weekStart,
                totalHours: hours
            )
        }.sorted { $0.weekStart < $1.weekStart }
    }

    // MARK: - Insights Generation

    private func generateInsights(events: [CalendarEvent], tagBreakdown: [TagTimeData], dailyBreakdown: [DailyTimeData]) async -> [Insight] {
        var insights: [Insight] = []

        // Top tag insight
        if let topTag = tagBreakdown.first(where: { $0.tag != "Untagged" }) {
            let comparison = getComparison(for: topTag.tag)
            let changeText = comparison != nil ? " (\(comparison!.changeFormatted) vs last period)" : ""
            insights.append(Insight(
                icon: "📊",
                message: "You spent \(topTag.formattedPercentage) of your time on \(topTag.tag) this period\(changeText)"
            ))
        }

        // Most productive hours
        if let mostProductiveHour = findMostProductiveHour() {
            insights.append(Insight(
                icon: "⏰",
                message: "Your most productive hours: \(mostProductiveHour.start)-\(mostProductiveHour.end)"
            ))
        }

        // Untagged events warning
        let untaggedCount = events.filter { extractTags(from: $0.notes).isEmpty }.count
        if untaggedCount > 0 {
            let percentage = Double(untaggedCount) / Double(events.count) * 100
            insights.append(Insight(
                icon: "⚠️",
                message: String(format: "%.0f%% of events are untagged (%d events) - tag them for better insights", percentage, untaggedCount),
                actionTitle: "Review",
                action: { [weak self] in
                    self?.selectedTags = ["Untagged"]
                }
            ))
        }

        // Deep focus sessions
        let deepFocusSessions = events.filter { $0.endTime.timeIntervalSince($0.startTime) >= 7200 }.count
        if let previousDeepFocus = previousPeriodAnalytics?.sessionDistribution.last?.count, deepFocusSessions > 0 {
            let ratio = Double(deepFocusSessions) / Double(max(previousDeepFocus, 1))
            if ratio >= 2.0 {
                insights.append(Insight(
                    icon: "🎯",
                    message: "You had \(Int(ratio))x more deep focus sessions (2h+) compared to last period"
                ))
            }
        }

        // Most active day
        if let mostActiveDay = dailyBreakdown.max(by: { $0.totalHours < $1.totalHours }) {
            insights.append(Insight(
                icon: "📅",
                message: "\(mostActiveDay.dayOfWeek) is your most active day with \(mostActiveDay.formattedHours) tracked"
            ))
        }

        // Productivity trend
        if analytics.weeklyTrend.count >= 3 {
            let recentWeeks = analytics.weeklyTrend.suffix(3)
            let avgRecent = recentWeeks.reduce(0.0) { $0 + $1.totalHours } / 3
            let earlierWeeks = analytics.weeklyTrend.prefix(max(analytics.weeklyTrend.count - 3, 1))
            let avgEarlier = earlierWeeks.reduce(0.0) { $0 + $1.totalHours } / Double(earlierWeeks.count)

            if avgRecent > avgEarlier * 1.1 {
                insights.append(Insight(
                    icon: "📈",
                    message: "Your productivity is trending up - recent weeks show +\(Int((avgRecent - avgEarlier) / 3600))h average increase"
                ))
            }
        }

        return insights
    }

    private func findMostProductiveHour() -> (start: String, end: String)? {
        let heatmap = analytics.hourlyHeatmap
        var maxHours: Double = 0
        var maxHourIndex: Int = 0

        for day in 0..<7 {
            for hour in 0..<24 {
                if heatmap[day][hour] > maxHours {
                    maxHours = heatmap[day][hour]
                    maxHourIndex = hour
                }
            }
        }

        guard maxHours > 0 else { return nil }

        let startHour = maxHourIndex
        let endHour = min(maxHourIndex + 3, 23) // Show 3-hour window

        let formatter = DateFormatter()
        formatter.dateFormat = "ha"

        let startDate = Calendar.current.date(bySettingHour: startHour, minute: 0, second: 0, of: Date()) ?? Date()
        let endDate = Calendar.current.date(bySettingHour: endHour, minute: 0, second: 0, of: Date()) ?? Date()

        return (formatter.string(from: startDate), formatter.string(from: endDate))
    }

    private func getComparison(for tag: String) -> ComparisonMetric? {
        guard let previousAnalytics = previousPeriodAnalytics else { return nil }

        let currentHours = analytics.tagBreakdown.first(where: { $0.tag == tag })?.hours ?? 0
        let previousHours = previousAnalytics.tagBreakdown.first(where: { $0.tag == tag })?.hours ?? 0

        return ComparisonMetric(current: currentHours, previous: previousHours)
    }

    // MARK: - Tag Extraction

    private func extractTags(from notes: String?) -> [String] {
        guard let notes = notes else { return [] }

        // Use the same tag extraction logic as SimpleEventDetailView
        // Format: "[tags: tag1, tag2]" in the notes field
        let pattern = "\\[tags: ([^\\]]+)\\]"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return []
        }

        let range = NSRange(notes.startIndex..., in: notes)
        guard let match = regex.firstMatch(in: notes, options: [], range: range),
              let tagsRange = Range(match.range(at: 1), in: notes) else {
            return []
        }

        let tagsString = String(notes[tagsRange])
        return tagsString.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
    }

    // MARK: - Export

    func exportCSV() -> String {
        var csv = "Tag,Hours,Event Count,Percentage\n"

        for tagData in analytics.tagBreakdown {
            let hours = tagData.hours / 3600
            csv += "\(tagData.tag),\(hours),\(tagData.eventCount),\(tagData.percentage)\n"
        }

        csv += "\nDate,Total Hours\n"
        for dailyData in analytics.dailyBreakdown {
            let hours = dailyData.totalHours / 3600
            csv += "\(dailyData.formattedDate),\(hours)\n"
        }

        return csv
    }

    func exportJSON() -> Data? {
        let export = AnalyticsExport(
            exportedAt: Date(),
            timeRange: selectedTimeRange.displayName,
            summary: ExportSummary(
                totalHours: analytics.totalHours / 3600,
                eventCount: analytics.eventCount,
                taggedPercentage: analytics.taggedPercentage,
                untaggedPercentage: analytics.untaggedPercentage
            ),
            tagBreakdown: analytics.tagBreakdown.map { tag in
                ExportTagData(
                    tag: tag.tag,
                    hours: tag.hours / 3600,
                    eventCount: tag.eventCount,
                    percentage: tag.percentage
                )
            },
            dailyBreakdown: analytics.dailyBreakdown.map { day in
                ExportDailyData(
                    date: day.formattedDate,
                    hours: day.totalHours / 3600,
                    eventCount: 0
                )
            },
            weeklyTrend: analytics.weeklyTrend.map { week in
                ExportWeeklyData(
                    weekStart: week.formattedDate,
                    hours: week.totalHours / 3600
                )
            }
        )

        return try? JSONEncoder().encode(export)
    }
}

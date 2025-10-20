import Foundation
import SwiftUI

// MARK: - Time Range Selection

enum TimeRange: String, CaseIterable, Identifiable {
    case today = "Today"
    case week = "This Week"
    case month = "This Month"
    case quarter = "This Quarter"
    case year = "This Year"
    case all = "All Time"
    case custom = "Custom"

    var id: String { rawValue }

    var displayName: String {
        return rawValue
    }

    /// Get the date range for this time range
    func dateRange(customStart: Date? = nil, customEnd: Date? = nil) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()

        switch self {
        case .today:
            let start = calendar.startOfDay(for: now)
            let end = calendar.date(byAdding: .day, value: 1, to: start) ?? now
            return (start, end)

        case .week:
            let start = calendar.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: now).date ?? now
            let end = calendar.date(byAdding: .weekOfYear, value: 1, to: start) ?? now
            return (start, end)

        case .month:
            let start = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
            let end = calendar.date(byAdding: .month, value: 1, to: start) ?? now
            return (start, end)

        case .quarter:
            let month = calendar.component(.month, from: now)
            let quarterStartMonth = ((month - 1) / 3) * 3 + 1
            var components = calendar.dateComponents([.year], from: now)
            components.month = quarterStartMonth
            components.day = 1
            let start = calendar.date(from: components) ?? now
            let end = calendar.date(byAdding: .month, value: 3, to: start) ?? now
            return (start, end)

        case .year:
            let start = calendar.date(from: calendar.dateComponents([.year], from: now)) ?? now
            let end = calendar.date(byAdding: .year, value: 1, to: start) ?? now
            return (start, end)

        case .all:
            // Go back 5 years as a reasonable "all time"
            let start = calendar.date(byAdding: .year, value: -5, to: now) ?? now
            return (start, now)

        case .custom:
            return (customStart ?? now, customEnd ?? now)
        }
    }
}

// MARK: - Main Analytics Structure

struct TimeAnalytics {
    let timeRange: TimeRange
    let totalHours: TimeInterval
    let eventCount: Int
    let tagBreakdown: [TagTimeData]
    let untaggedHours: TimeInterval
    let dailyBreakdown: [DailyTimeData]
    let hourlyHeatmap: [[Double]]          // 7 days × 24 hours
    let sessionDistribution: [SessionBucket]
    let weeklyTrend: [WeeklyData]
    let insights: [Insight]

    // Computed properties
    var taggedPercentage: Double {
        guard totalHours > 0 else { return 0 }
        return ((totalHours - untaggedHours) / totalHours) * 100
    }

    var untaggedPercentage: Double {
        guard totalHours > 0 else { return 0 }
        return (untaggedHours / totalHours) * 100
    }

    var mostActiveDay: DailyTimeData? {
        return dailyBreakdown.max(by: { $0.totalHours < $1.totalHours })
    }

    var topTag: TagTimeData? {
        return tagBreakdown.filter { $0.tag != "Untagged" }.first
    }

    var formattedTotalHours: String {
        let hours = Int(totalHours / 3600)
        let minutes = Int((totalHours.truncatingRemainder(dividingBy: 3600)) / 60)

        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }

    static let empty = TimeAnalytics(
        timeRange: .week,
        totalHours: 0,
        eventCount: 0,
        tagBreakdown: [],
        untaggedHours: 0,
        dailyBreakdown: [],
        hourlyHeatmap: Array(repeating: Array(repeating: 0, count: 24), count: 7),
        sessionDistribution: [],
        weeklyTrend: [],
        insights: []
    )
}

// MARK: - Tag Time Data

struct TagTimeData: Identifiable {
    let id: String                         // tag name or "Untagged"
    let tag: String
    let hours: TimeInterval
    let eventCount: Int
    let percentage: Double
    let color: Color

    var formattedHours: String {
        let hrs = Int(hours / 3600)
        let mins = Int((hours.truncatingRemainder(dividingBy: 3600)) / 60)

        if hrs > 0 && mins > 0 {
            return "\(hrs)h \(mins)m"
        } else if hrs > 0 {
            return "\(hrs)h"
        } else {
            return "\(mins)m"
        }
    }

    var formattedPercentage: String {
        return String(format: "%.1f%%", percentage)
    }
}

// MARK: - Daily Time Data

struct DailyTimeData: Identifiable {
    let id: Date
    let date: Date
    let tagHours: [String: TimeInterval]  // tag name → hours
    let totalHours: TimeInterval

    var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }

    var formattedHours: String {
        let hours = Int(totalHours / 3600)
        let minutes = Int((totalHours.truncatingRemainder(dividingBy: 3600)) / 60)

        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Session Bucket (for duration histogram)

struct SessionBucket: Identifiable {
    let id: String
    let range: String                      // "0-30m", "30m-1h", etc
    let count: Int
    let lowerBound: TimeInterval
    let upperBound: TimeInterval

    var formattedRange: String {
        return range
    }

    static let buckets: [SessionBucket] = [
        SessionBucket(id: "0-30m", range: "0-30m", count: 0, lowerBound: 0, upperBound: 1800),
        SessionBucket(id: "30m-1h", range: "30m-1h", count: 0, lowerBound: 1800, upperBound: 3600),
        SessionBucket(id: "1-2h", range: "1-2h", count: 0, lowerBound: 3600, upperBound: 7200),
        SessionBucket(id: "2-4h", range: "2-4h", count: 0, lowerBound: 7200, upperBound: 14400),
        SessionBucket(id: "4h+", range: "4h+", count: 0, lowerBound: 14400, upperBound: .infinity)
    ]

    static func bucket(for duration: TimeInterval, count: Int) -> SessionBucket {
        if duration < 1800 {
            return SessionBucket(id: "0-30m", range: "0-30m", count: count, lowerBound: 0, upperBound: 1800)
        } else if duration < 3600 {
            return SessionBucket(id: "30m-1h", range: "30m-1h", count: count, lowerBound: 1800, upperBound: 3600)
        } else if duration < 7200 {
            return SessionBucket(id: "1-2h", range: "1-2h", count: count, lowerBound: 3600, upperBound: 7200)
        } else if duration < 14400 {
            return SessionBucket(id: "2-4h", range: "2-4h", count: count, lowerBound: 7200, upperBound: 14400)
        } else {
            return SessionBucket(id: "4h+", range: "4h+", count: count, lowerBound: 14400, upperBound: .infinity)
        }
    }
}

// MARK: - Weekly Data

struct WeeklyData: Identifiable {
    let id: Date
    let weekStart: Date
    let totalHours: TimeInterval

    var weekLabel: String {
        let calendar = Calendar.current
        let weekOfYear = calendar.component(.weekOfYear, from: weekStart)
        return "W\(weekOfYear)"
    }

    var formattedHours: String {
        let hours = Int(totalHours / 3600)
        return "\(hours)h"
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: weekStart)
    }
}

// MARK: - Insight

struct Insight: Identifiable {
    let id = UUID()
    let icon: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?

    init(icon: String, message: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.icon = icon
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
}

// MARK: - Comparison Data (for week-over-week comparisons)

struct ComparisonMetric {
    let current: Double
    let previous: Double

    var change: Double {
        guard previous > 0 else { return 0 }
        return ((current - previous) / previous) * 100
    }

    var changeFormatted: String {
        let sign = change >= 0 ? "+" : ""
        return String(format: "%@%.0f%%", sign, change)
    }

    var isIncreasing: Bool {
        return change > 0
    }

    var isDecreasing: Bool {
        return change < 0
    }
}

// MARK: - Export Data Structures

struct AnalyticsExport: Codable {
    let exportedAt: Date
    let timeRange: String
    let summary: ExportSummary
    let tagBreakdown: [ExportTagData]
    let dailyBreakdown: [ExportDailyData]
    let weeklyTrend: [ExportWeeklyData]
}

struct ExportSummary: Codable {
    let totalHours: Double
    let eventCount: Int
    let taggedPercentage: Double
    let untaggedPercentage: Double
}

struct ExportTagData: Codable {
    let tag: String
    let hours: Double
    let eventCount: Int
    let percentage: Double
}

struct ExportDailyData: Codable {
    let date: String
    let hours: Double
    let eventCount: Int
}

struct ExportWeeklyData: Codable {
    let weekStart: String
    let hours: Double
}

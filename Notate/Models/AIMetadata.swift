import Foundation
import SwiftUI

// MARK: - Main AI Metadata Structure
struct AIMetadata: Codable {
    var actions: [AIAction] = []
    var researchResults: ResearchResults?
    var processingMeta: ProcessingMeta?

    init(actions: [AIAction] = [], researchResults: ResearchResults? = nil, processingMeta: ProcessingMeta? = nil) {
        self.actions = actions
        self.researchResults = researchResults
        self.processingMeta = processingMeta
    }
}

// MARK: - AI Actions
struct AIAction: Codable, Identifiable {
    let id: String
    let type: AIActionType
    var status: ActionStatus
    let data: [String: ActionData]
    let executedAt: Date?
    let reversible: Bool
    let reverseData: [String: ActionData]?

    init(
        id: String = UUID().uuidString,
        type: AIActionType,
        status: ActionStatus = .pending,
        data: [String: ActionData] = [:],
        executedAt: Date? = nil,
        reversible: Bool = true,
        reverseData: [String: ActionData]? = nil
    ) {
        self.id = id
        self.type = type
        self.status = status
        self.data = data
        self.executedAt = executedAt
        self.reversible = reversible
        self.reverseData = reverseData
    }
}

enum AIActionType: String, CaseIterable, Codable {
    case appleReminders = "apple_reminders"
    case calendar = "calendar"
    case contacts = "contacts"
    case maps = "maps"

    var displayName: String {
        switch self {
        case .appleReminders: return "Apple Reminders"
        case .calendar: return "Calendar"
        case .contacts: return "Contacts"
        case .maps: return "Maps"
        }
    }
}

enum ActionStatus: String, Codable {
    case pending
    case executing
    case executed
    case failed
    case reversed

    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .executing: return "Executing"
        case .executed: return "Executed"
        case .failed: return "Failed"
        case .reversed: return "Reversed"
        }
    }

    var color: Color {
        switch self {
        case .pending: return .orange
        case .executing: return .blue
        case .executed: return .green
        case .failed: return .red
        case .reversed: return .gray
        }
    }
}

// MARK: - Action Data (Flexible for different action types)
struct ActionData: Codable {
    let value: ActionValue

    init(_ value: ActionValue) {
        self.value = value
    }

    // Convenience initializers
    init(_ string: String) {
        self.value = .string(string)
    }

    init(_ date: Date) {
        self.value = .date(date)
    }

    init(_ bool: Bool) {
        self.value = .bool(bool)
    }

    init(_ int: Int) {
        self.value = .int(int)
    }

    // Convenience accessors
    var stringValue: String {
        switch value {
        case .string(let str):
            return str
        case .date(let date):
            return date.formatted()
        case .bool(let bool):
            return bool ? "true" : "false"
        case .int(let int):
            return String(int)
        }
    }

    var dateValue: Date? {
        switch value {
        case .date(let date):
            return date
        case .string(let str):
            // Try to parse ISO string to date
            return ISO8601DateFormatter().date(from: str)
        default:
            return nil
        }
    }
}

enum ActionValue: Codable {
    case string(String)
    case date(Date)
    case bool(Bool)
    case int(Int)

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .date(let value):
            try container.encode(value)
        case .bool(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else if let dateValue = try? container.decode(Date.self) {
            self = .date(dateValue)
        } else if let boolValue = try? container.decode(Bool.self) {
            self = .bool(boolValue)
        } else if let intValue = try? container.decode(Int.self) {
            self = .int(intValue)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unable to decode ActionValue")
        }
    }
}

// MARK: - Research Results (moved from AIService.swift for consistency)
struct ResearchResults: Codable {
    let format: ResultFormat = .markdown
    let content: String
    let suggestions: [String]
    let generatedAt: Date
    let researchCost: Double
    let processingTimeMs: Int

    init(content: String, suggestions: [String] = [], generatedAt: Date, researchCost: Double, processingTimeMs: Int = 0) {
        self.content = content
        self.suggestions = suggestions
        self.generatedAt = generatedAt
        self.researchCost = researchCost
        self.processingTimeMs = processingTimeMs
    }
}

enum ResultFormat: String, Codable {
    case markdown

    var displayName: String {
        switch self {
        case .markdown: return "Markdown"
        }
    }
}

// MARK: - Processing Metadata
struct ProcessingMeta: Codable {
    let processedAt: Date
    let processingVersion: String
    let totalCost: Double
    let processingTimeMs: Int

    init(processedAt: Date = Date(), processingVersion: String = "v1.0", totalCost: Double, processingTimeMs: Int) {
        self.processedAt = processedAt
        self.processingVersion = processingVersion
        self.totalCost = totalCost
        self.processingTimeMs = processingTimeMs
    }
}

// MARK: - Convenience Extensions

extension AIMetadata {
    var hasActions: Bool {
        return !actions.isEmpty
    }

    var hasResearch: Bool {
        return researchResults != nil
    }

    var executedActions: [AIAction] {
        return actions.filter { $0.status == .executed }
    }

    var pendingActions: [AIAction] {
        return actions.filter { $0.status == .pending }
    }

    var totalCost: Double {
        let researchCost = researchResults?.researchCost ?? 0
        let metaCost = processingMeta?.totalCost ?? 0
        return max(researchCost, metaCost) // Avoid double counting
    }
}

extension AIAction {
    // Helper methods to extract typed data
    func stringValue(for key: String) -> String? {
        guard let actionData = data[key],
              case .string(let value) = actionData.value else {
            return nil
        }
        return value
    }

    func dateValue(for key: String) -> Date? {
        guard let actionData = data[key],
              case .date(let value) = actionData.value else {
            return nil
        }
        return value
    }

    func boolValue(for key: String) -> Bool? {
        guard let actionData = data[key],
              case .bool(let value) = actionData.value else {
            return nil
        }
        return value
    }

    func intValue(for key: String) -> Int? {
        guard let actionData = data[key],
              case .int(let value) = actionData.value else {
            return nil
        }
        return value
    }
}

extension ResearchResults {
    var isRecent: Bool {
        let oneHour: TimeInterval = 3600
        return Date().timeIntervalSince(generatedAt) < oneHour
    }

    var formattedCost: String {
        return String(format: "$%.4f", researchCost)
    }

    var formattedProcessingTime: String {
        if processingTimeMs < 1000 {
            return "\(processingTimeMs)ms"
        } else {
            let seconds = Double(processingTimeMs) / 1000.0
            return String(format: "%.1fs", seconds)
        }
    }
}
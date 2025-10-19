import Foundation
import SQLite3

// MARK: - Entry Types
enum EntryType: String, CaseIterable, Codable {
    case todo = "todo"
    case thought = "thought" // Legacy, will be migrated to todo
    case piece = "piece" // Legacy, will be migrated to todo

    var displayName: String {
        // All entries are now called "Notes"
        return "Note"
    }
}

enum EntryStatus: String, CaseIterable, Codable {
    case open = "open"
    case done = "done"
    
    var displayName: String {
        switch self {
        case .open: return "Open"
        case .done: return "Done"
        }
    }
}

enum EntryPriority: String, CaseIterable, Codable {
    case low = "low"
    case medium = "med"
    case high = "high"
    
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }
}

// MARK: - Entry Model
struct Entry: Identifiable, Codable {
    let id: String
    var type: EntryType
    var content: String
    var tags: [String]
    var sourceApp: String?
    var triggerUsed: String
    let createdAt: Date
    var status: EntryStatus
    var priority: EntryPriority?
    var metadata: [String: FlexibleCodable]?
    
    init(
        id: String = UUID().uuidString,
        type: EntryType,
        content: String,
        tags: [String] = [],
        sourceApp: String? = nil,
        triggerUsed: String,
        createdAt: Date = Date(),
        status: EntryStatus = EntryStatus.open,
        priority: EntryPriority? = nil,
        metadata: [String: FlexibleCodable]? = nil
    ) {
        self.id = id
        self.type = type
        self.content = content
        self.tags = tags
        self.sourceApp = sourceApp
        self.triggerUsed = triggerUsed
        self.createdAt = createdAt
        self.status = status
        self.priority = priority
        self.metadata = metadata
    }
}

// MARK: - FlexibleCodable for flexible metadata
struct FlexibleCodable: Codable {
    let wrappedValue: Any
    
    init(_ value: Any) {
        self.wrappedValue = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let string = try? container.decode(String.self) {
            wrappedValue = string
        } else if let int = try? container.decode(Int.self) {
            wrappedValue = int
        } else if let double = try? container.decode(Double.self) {
            wrappedValue = double
        } else if let bool = try? container.decode(Bool.self) {
            wrappedValue = bool
        } else if let array = try? container.decode([FlexibleCodable].self) {
            wrappedValue = array.map { $0.wrappedValue }
        } else if let dict = try? container.decode([String: FlexibleCodable].self) {
            wrappedValue = dict.mapValues { $0.wrappedValue }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported type")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        if let string = wrappedValue as? String {
            try container.encode(string)
        } else if let int = wrappedValue as? Int {
            try container.encode(int)
        } else if let double = wrappedValue as? Double {
            try container.encode(double)
        } else if let bool = wrappedValue as? Bool {
            try container.encode(bool)
        } else if let array = wrappedValue as? [Any] {
            try container.encode(array.map { FlexibleCodable($0) })
        } else if let dict = wrappedValue as? [String: Any] {
            try container.encode(dict.mapValues { FlexibleCodable($0) })
        } else {
            throw EncodingError.invalidValue(wrappedValue, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Unsupported type"))
        }
    }
}

// MARK: - Entry Extensions
extension Entry {
    var isTodo: Bool { type == EntryType.todo }
    var isThought: Bool { type == EntryType.thought } // Legacy
    var isPiece: Bool { type == EntryType.thought || type == EntryType.piece } // Both are pieces
    
    var displayTags: String {
        tags.isEmpty ? "" : tags.joined(separator: ", ")
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }

    // MARK: - AI Integration
    var aiMetadata: AIMetadata? {
        get {
            guard let metadataDict = metadata,
                  let aiDataString = metadataDict["ai"]?.wrappedValue as? String,
                  let aiData = Data(base64Encoded: aiDataString) else {
                return nil
            }
            return try? JSONDecoder().decode(AIMetadata.self, from: aiData)
        }
        set {
            if let newValue = newValue {
                if let aiData = try? JSONEncoder().encode(newValue) {
                    var metadataDict = metadata ?? [:]
                    metadataDict["ai"] = FlexibleCodable(aiData.base64EncodedString())
                    metadata = metadataDict
                }
            } else {
                // Remove AI metadata
                var metadataDict = metadata ?? [:]
                metadataDict.removeValue(forKey: "ai")
                metadata = metadataDict.isEmpty ? nil : metadataDict
            }
        }
    }

    var hasAIProcessing: Bool {
        return aiMetadata != nil
    }

    var hasAIActions: Bool {
        return aiMetadata?.hasActions ?? false
    }

    var hasAIResearch: Bool {
        return aiMetadata?.hasResearch ?? false
    }

    var needsAIProcessing: Bool {
        return aiMetadata == nil
    }
    
    mutating func markAsDone() {
        if isTodo {
            status = EntryStatus.done
        }
    }
    
    mutating func markAsOpen() {
        if isTodo {
            status = EntryStatus.open
        }
    }
    
    mutating func convertToTodo() -> Entry {
        var newEntry = self
        newEntry.type = EntryType.todo
        newEntry.status = EntryStatus.open
        newEntry.priority = EntryPriority.medium
        
        // Add conversion metadata
        var metadata = newEntry.metadata ?? [:]
        metadata["converted_from"] = FlexibleCodable("thought")
        metadata["converted_at"] = FlexibleCodable(Date())
        newEntry.metadata = metadata
        
        return newEntry
    }

    mutating func convertToThought() -> Entry {
        var newEntry = self
        newEntry.type = EntryType.thought
        newEntry.status = EntryStatus.open
        newEntry.priority = nil

        var metadata = newEntry.metadata ?? [:]
        metadata["converted_from"] = FlexibleCodable("todo")
        metadata["converted_at"] = FlexibleCodable(Date())
        newEntry.metadata = metadata

        return newEntry
    }

    // MARK: - AI Helper Methods
    mutating func setAIMetadata(_ aiMetadata: AIMetadata) {
        self.aiMetadata = aiMetadata
    }

    mutating func addAIAction(_ action: AIAction) {
        var currentMetadata = aiMetadata ?? AIMetadata()
        currentMetadata.actions.append(action)
        self.aiMetadata = currentMetadata
    }

    mutating func updateAIAction(_ actionId: String, status: ActionStatus) {
        guard var currentMetadata = aiMetadata else { return }

        if let index = currentMetadata.actions.firstIndex(where: { $0.id == actionId }) {
            currentMetadata.actions[index].status = status
            self.aiMetadata = currentMetadata
        }
    }

    mutating func updateAIActionData(_ actionId: String, reverseData: [String: ActionData]) {
        guard var currentMetadata = aiMetadata else { return }

        if let index = currentMetadata.actions.firstIndex(where: { $0.id == actionId }) {
            var updatedAction = currentMetadata.actions[index]
            updatedAction = AIAction(
                id: updatedAction.id,
                type: updatedAction.type,
                status: updatedAction.status,
                data: updatedAction.data,
                executedAt: updatedAction.executedAt,
                reversible: updatedAction.reversible,
                reverseData: reverseData
            )
            currentMetadata.actions[index] = updatedAction
            self.aiMetadata = currentMetadata
        }
    }

    mutating func setAIResearch(_ research: ResearchResults) {
        var currentMetadata = aiMetadata ?? AIMetadata()
        currentMetadata.researchResults = research
        self.aiMetadata = currentMetadata
    }

    // Get executed actions of a specific type
    func getExecutedActions(ofType type: AIActionType) -> [AIAction] {
        return aiMetadata?.executedActions.filter { $0.type == type } ?? []
    }

    // Check if a specific action type was executed
    func hasExecutedAction(ofType type: AIActionType) -> Bool {
        return !getExecutedActions(ofType: type).isEmpty
    }
}

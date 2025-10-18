import Foundation
import Combine

// MARK: - Trigger Configuration Model
struct TriggerConfig: Codable, Identifiable {
    let id: String
    var trigger: String
    var defaultType: EntryType
    var isEnabled: Bool
    var isTimerTrigger: Bool // Special flag for timer triggers (creates calendar event via timer, not entry)

    init(id: String = UUID().uuidString, trigger: String, defaultType: EntryType, isEnabled: Bool = true, isTimerTrigger: Bool = false) {
        self.id = id
        self.trigger = trigger
        self.defaultType = defaultType
        self.isEnabled = isEnabled
        self.isTimerTrigger = isTimerTrigger
    }
}

// MARK: - App Configuration
struct AppConfiguration: Codable {
    var triggers: [TriggerConfig]
    var autoClearInput: Bool
    var captureTimeout: TimeInterval
    var enableIMEComposing: Bool
    var redactionMode: Bool
    
    static let `default` = AppConfiguration(
        triggers: [
            TriggerConfig(trigger: "///", defaultType: .todo),
            TriggerConfig(trigger: ",,,", defaultType: .piece),
            TriggerConfig(trigger: "，，，", defaultType: .piece),
            TriggerConfig(trigger: ";;;", defaultType: .todo, isTimerTrigger: true) // Timer triggers create calendar events, not entries
        ],
        autoClearInput: true,
        captureTimeout: 3.0,
        enableIMEComposing: true,
        redactionMode: false
    )
}

// MARK: - Configuration Manager
final class ConfigurationManager: ObservableObject {
    static let shared = ConfigurationManager()
    
    @Published var configuration: AppConfiguration {
        didSet {
            saveConfiguration()
        }
    }
    
    private let userDefaults = UserDefaults.standard
    private let configurationKey = "NotateConfiguration"
    
    private init() {
        self.configuration = Self.loadConfiguration()
    }
    
    // MARK: - Configuration Management
    
    private static func loadConfiguration() -> AppConfiguration {
        guard let data = UserDefaults.standard.data(forKey: "NotateConfiguration"),
              !data.isEmpty,
              var config = try? JSONDecoder().decode(AppConfiguration.self, from: data) else {
            return AppConfiguration.default
        }

        // Migration: Ensure timer trigger exists
        let hasTimerTrigger = config.triggers.contains { $0.trigger == ";;;" && $0.isTimerTrigger }
        if !hasTimerTrigger {
            print("🔄 Adding missing timer trigger ;;; to configuration")
            config.triggers.append(
                TriggerConfig(trigger: ";;;", defaultType: .todo, isTimerTrigger: true)
            )
            // Save the migrated configuration
            if let data = try? JSONEncoder().encode(config) {
                UserDefaults.standard.set(data, forKey: "NotateConfiguration")
                UserDefaults.standard.synchronize()
            }
        }

        return config
    }
    
    private func saveConfiguration() {
        do {
            let data = try JSONEncoder().encode(configuration)
            if !data.isEmpty {
                userDefaults.set(data, forKey: configurationKey)
                userDefaults.synchronize()
            }
        } catch {
            print("⚠️ Failed to save configuration: \(error)")
        }
    }
    
    // MARK: - Trigger Management
    
    func addTrigger(_ trigger: String, defaultType: EntryType) {
        let newTrigger = TriggerConfig(trigger: trigger, defaultType: defaultType)
        configuration.triggers.append(newTrigger)
    }
    
    func removeTrigger(id: String) {
        configuration.triggers.removeAll { $0.id == id }
    }
    
    func updateTrigger(id: String, trigger: String? = nil, defaultType: EntryType? = nil, isEnabled: Bool? = nil) {
        if let index = configuration.triggers.firstIndex(where: { $0.id == id }) {
            if let trigger = trigger {
                configuration.triggers[index].trigger = trigger
            }
            if let defaultType = defaultType {
                configuration.triggers[index].defaultType = defaultType
            }
            if let isEnabled = isEnabled {
                configuration.triggers[index].isEnabled = isEnabled
            }
        }
    }
    
    func getEnabledTriggers() -> [TriggerConfig] {
        return configuration.triggers.filter { $0.isEnabled }
    }
    
    func getTriggerConfig(for trigger: String) -> TriggerConfig? {
        return configuration.triggers.first { $0.trigger == trigger && $0.isEnabled }
    }
    
    // MARK: - Type Detection
    
    func detectEntryType(from content: String, triggerUsed: String) -> EntryType {
        // First check for inline overrides
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // English overrides
        if trimmedContent.hasPrefix("todo:") || trimmedContent.hasPrefix("t:") {
            return .todo
        }
        if trimmedContent.hasPrefix("idea:") || trimmedContent.hasPrefix("i:") || trimmedContent.hasPrefix("piece:") || trimmedContent.hasPrefix("p:") {
            return .piece
        }
        
        // Chinese overrides
        if trimmedContent.hasPrefix("待办:") || trimmedContent.hasPrefix("任务:") {
            return .todo
        }
        if trimmedContent.hasPrefix("想法:") || trimmedContent.hasPrefix("思考:") || trimmedContent.hasPrefix("片段:") {
            return .piece
        }
        
        // Fall back to trigger mapping
        if let triggerConfig = getTriggerConfig(for: triggerUsed) {
            return triggerConfig.defaultType
        }
        
        // Default fallback
        return .todo
    }
    
    func cleanContent(_ content: String) -> String {
        var cleaned = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove inline type prefixes
        let prefixes = ["todo:", "t:", "idea:", "i:", "piece:", "p:", "待办:", "任务:", "想法:", "思考:", "片段:"]
        for prefix in prefixes {
            if cleaned.hasPrefix(prefix) {
                cleaned = String(cleaned.dropFirst(prefix.count))
                break
            }
        }
        
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Settings Management
    
    func updateAutoClearInput(_ enabled: Bool) {
        configuration.autoClearInput = enabled
    }
    
    func updateCaptureTimeout(_ timeout: TimeInterval) {
        configuration.captureTimeout = timeout
    }
    
    func updateIMEComposing(_ enabled: Bool) {
        configuration.enableIMEComposing = enabled
    }
    
    func updateRedactionMode(_ enabled: Bool) {
        configuration.redactionMode = enabled
    }
    
    // MARK: - Validation
    
    func validateTrigger(_ trigger: String) -> Bool {
        // Check if trigger is not empty and doesn't contain whitespace
        guard !trigger.isEmpty && !trigger.contains(where: { $0.isWhitespace }) else {
            return false
        }
        
        // Check if trigger is not already used
        return !configuration.triggers.contains { $0.trigger == trigger }
    }
    
    func getAvailableTriggers() -> [String] {
        return configuration.triggers.map { $0.trigger }
    }
}

// MARK: - Inline Type Detection Extensions
extension String {
    var hasInlineTypePrefix: Bool {
        let prefixes = ["todo:", "t:", "idea:", "i:", "piece:", "p:", "待办:", "任务:", "想法:", "思考:", "片段:"]
        return prefixes.contains { self.hasPrefix($0) }
    }

    var inlineTypePrefix: String? {
        let prefixes = ["todo:", "t:", "idea:", "i:", "piece:", "p:", "待办:", "任务:", "想法:", "思考:", "片段:"]
        return prefixes.first { self.hasPrefix($0) }
    }
    
    var isChineseCharacter: Bool {
        return self.range(of: "\\p{Han}", options: .regularExpression) != nil
    }
    
    var containsChinese: Bool {
        return self.contains { $0.isChineseCharacter }
    }
}

extension Character {
    var isChineseCharacter: Bool {
        return String(self).isChineseCharacter
    }
}

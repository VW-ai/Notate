import Foundation
import Combine

@MainActor
class AutonomousAIAgent: ObservableObject {
    private let aiService: AIService
    private let databaseManager: DatabaseManager
    private var toolService: ToolService?

    @Published var isProcessing: Bool = false
    @Published var processingQueue: [String] = [] // Entry IDs being processed
    @Published var processingStats = ProcessingStats()

    private var cancellables = Set<AnyCancellable>()

    init(aiService: AIService, databaseManager: DatabaseManager) {
        self.aiService = aiService
        self.databaseManager = databaseManager

        // Initialize processing stats
        updateProcessingStats()

        // TODO: Initialize ToolService once implemented
        // self.toolService = ToolService()
    }

    // MARK: - Main Entry Processing

    func processEntry(_ entry: Entry) async {
        guard aiService.isConfigured else {
            print("⚠️ AI Service not configured, skipping processing")
            return
        }

        guard entry.needsAIProcessing else {
            print("ℹ️ Entry already processed: \(entry.id)")
            return
        }

        await processEntryInternal(entry)
    }

    func processEntriesInBackground() async {
        guard aiService.isConfigured else { return }

        let unprocessedEntries = databaseManager.getEntriesNeedingAIProcessing()
        guard !unprocessedEntries.isEmpty else { return }

        print("🤖 Processing \(unprocessedEntries.count) entries in background")

        // Process max 5 at a time to control costs and API rate limits
        for entry in unprocessedEntries.prefix(5) {
            await processEntryInternal(entry)
        }
    }

    private func processEntryInternal(_ entry: Entry) async {
        processingQueue.append(entry.id)
        isProcessing = true

        defer {
            processingQueue.removeAll { $0 == entry.id }
            isProcessing = !processingQueue.isEmpty
            updateProcessingStats()
        }

        print("🤖 Processing entry: \(entry.content.prefix(50))...")

        do {
            switch entry.type {
            case .todo:
                await processTodo(entry)
            case .thought, .piece:
                await processPiece(entry)
            }
        } catch {
            print("❌ Error processing entry \(entry.id): \(error)")
            await markProcessingFailed(entry, error: error)
        }
    }

    // MARK: - TODO Processing

    private func processTodo(_ entry: Entry) async {
        var actions: [AIAction] = []
        let processingStartTime = Date()
        let userContext = buildUserContext()

        // 1. Always add to Apple Reminders
        if let reminderAction = await createReminderAction(from: entry.content) {
            actions.append(reminderAction)
        }

        // 2. Check for time components and add to Calendar
        if PatternMatcher.containsDateOrTime(entry.content) {
            if let calendarAction = await createCalendarAction(from: entry.content) {
                actions.append(calendarAction)
            }
        }

        // 3. Generate research summary
        var research: ResearchResults?
        do {
            research = try await aiService.generateTodoResearch(entry.content, userContext: userContext)
            print("✅ Generated TODO research: \(research?.content.prefix(100) ?? "nil")...")
        } catch {
            print("❌ Failed to generate TODO research: \(error)")
        }

        // 4. Save all results
        let processingTime = Int(Date().timeIntervalSince(processingStartTime) * 1000)
        await saveAIResults(
            for: entry,
            actions: actions,
            research: research,
            processingTime: processingTime
        )

        print("✅ TODO processing complete: \(actions.count) actions, research: \(research != nil)")
    }

    // MARK: - PIECE Processing

    private func processPiece(_ entry: Entry) async {
        var actions: [AIAction] = []
        let processingStartTime = Date()
        let userContext = buildUserContext()

        // 1. Detect and handle structured data
        let structuredData = PatternMatcher.extractStructuredData(entry.content)

        // Phone numbers -> Contacts
        if let phoneNumber = structuredData.phoneNumber {
            if let contactAction = await createContactAction(
                from: entry.content,
                phoneNumber: phoneNumber,
                name: structuredData.personName
            ) {
                actions.append(contactAction)
            }
        }

        // Emails -> Contacts
        if let email = structuredData.email {
            if let contactAction = await createContactAction(
                from: entry.content,
                email: email,
                name: structuredData.personName
            ) {
                actions.append(contactAction)
            }
        }

        // Locations -> Maps
        if PatternMatcher.isLocation(entry.content) {
            if let mapAction = await createMapAction(from: entry.content) {
                actions.append(mapAction)
            }
        }

        // 2. Generate research if it's not just raw data
        var research: ResearchResults?
        if !PatternMatcher.isRawData(entry.content) {
            do {
                research = try await aiService.generatePieceResearch(entry.content, userContext: userContext)
                print("✅ Generated PIECE research: \(research?.content.prefix(100) ?? "nil")...")
            } catch {
                print("❌ Failed to generate PIECE research: \(error)")
            }
        }

        // 3. Save all results
        let processingTime = Int(Date().timeIntervalSince(processingStartTime) * 1000)
        await saveAIResults(
            for: entry,
            actions: actions,
            research: research,
            processingTime: processingTime
        )

        print("✅ PIECE processing complete: \(actions.count) actions, research: \(research != nil)")
    }

    // MARK: - Action Creation (Placeholders until ToolService is implemented)

    private func createReminderAction(from content: String) async -> AIAction? {
        // TODO: Implement with ToolService
        // For now, create a placeholder action that will be executed later
        return AIAction(
            type: .appleReminders,
            status: .pending,
            data: [
                "title": ActionData(content),
                "notes": ActionData("Created by Notate AI"),
                "original_content": ActionData(content)
            ],
            executedAt: nil,
            reversible: true,
            reverseData: [
                "reminder_existed": ActionData(false)
            ]
        )
    }

    private func createCalendarAction(from content: String) async -> AIAction? {
        // TODO: Implement with ToolService for actual calendar integration
        return AIAction(
            type: .calendar,
            status: .pending,
            data: [
                "title": ActionData(content),
                "notes": ActionData("Created by Notate AI"),
                "original_content": ActionData(content)
            ],
            executedAt: nil,
            reversible: true,
            reverseData: [
                "event_existed": ActionData(false)
            ]
        )
    }

    private func createContactAction(
        from content: String,
        phoneNumber: String? = nil,
        email: String? = nil,
        name: String? = nil
    ) async -> AIAction? {
        // TODO: Implement with ToolService for actual contact creation
        var actionData: [String: ActionData] = [:]

        if let phone = phoneNumber {
            actionData["phone"] = ActionData(phone)
        }

        if let email = email {
            actionData["email"] = ActionData(email)
        }

        actionData["name"] = ActionData(name ?? "Unknown Contact")
        actionData["notes"] = ActionData("Added by Notate AI")
        actionData["original_content"] = ActionData(content)

        return AIAction(
            type: .contacts,
            status: .pending,
            data: actionData,
            executedAt: nil,
            reversible: true,
            reverseData: [
                "contact_existed": ActionData(false)
            ]
        )
    }

    private func createMapAction(from content: String) async -> AIAction? {
        // TODO: Implement with ToolService for actual map integration
        return AIAction(
            type: .maps,
            status: .pending,
            data: [
                "location": ActionData(content),
                "notes": ActionData("Saved by Notate AI"),
                "original_content": ActionData(content)
            ],
            executedAt: nil,
            reversible: true,
            reverseData: [
                "location_existed": ActionData(false)
            ]
        )
    }

    // MARK: - Result Storage

    private func saveAIResults(
        for entry: Entry,
        actions: [AIAction],
        research: ResearchResults?,
        processingTime: Int
    ) async {
        let metadata = AIMetadata(
            actions: actions,
            researchResults: research,
            processingMeta: ProcessingMeta(
                processedAt: Date(),
                processingVersion: "v1.0",
                totalCost: research?.researchCost ?? 0.0,
                processingTimeMs: processingTime
            )
        )

        databaseManager.updateEntryAIMetadata(entry.id, metadata: metadata)

        // Execute actions if ToolService is available
        if let toolService = toolService {
            await executeActionsWithToolService(actions, for: entry.id, using: toolService)
        } else {
            // For now, mark actions as executed since we're in placeholder mode
            for action in actions {
                databaseManager.updateAIActionStatus(entry.id, actionId: action.id, status: .executed)
            }
        }
    }

    private func executeActionsWithToolService(_ actions: [AIAction], for entryId: String, using toolService: ToolService) async {
        for action in actions {
            do {
                // TODO: Implement action execution with ToolService
                // let result = try await toolService.executeAction(action)
                // databaseManager.updateAIActionStatus(entryId, actionId: action.id, status: result ? .executed : .failed)
                print("🔧 Would execute action: \(action.type.displayName)")
                databaseManager.updateAIActionStatus(entryId, actionId: action.id, status: .executed)
            } catch {
                print("❌ Failed to execute action \(action.id): \(error)")
                databaseManager.updateAIActionStatus(entryId, actionId: action.id, status: .failed)
            }
        }
    }

    private func markProcessingFailed(_ entry: Entry, error: Error) async {
        let metadata = AIMetadata(
            processingMeta: ProcessingMeta(
                processedAt: Date(),
                processingVersion: "v1.0",
                totalCost: 0.0,
                processingTimeMs: 0
            )
        )

        databaseManager.updateEntryAIMetadata(entry.id, metadata: metadata)
        print("❌ Marked entry \(entry.id) as processing failed: \(error.localizedDescription)")
    }

    // MARK: - User Context Building

    private func buildUserContext() -> UserContext? {
        // TODO: Implement user context gathering
        // For now, return basic context
        return UserContext(
            location: nil, // Could get from Core Location
            timeOfDay: getCurrentTimeOfDay(),
            previousEntries: nil, // Could analyze recent entries
            userPreferences: nil // Could load from settings
        )
    }

    private func getCurrentTimeOfDay() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "morning"
        case 12..<17: return "afternoon"
        case 17..<21: return "evening"
        default: return "night"
        }
    }

    // MARK: - Public Utilities

    func regenerateResearch(for entry: Entry) async {
        guard aiService.isConfigured else { return }

        do {
            let userContext = buildUserContext()
            let research = entry.isTodo ?
                try await aiService.generateTodoResearch(entry.content, userContext: userContext) :
                try await aiService.generatePieceResearch(entry.content, userContext: userContext)

            databaseManager.setAIResearchForEntry(entry.id, research: research)
            print("✅ Regenerated research for entry: \(entry.id)")
        } catch {
            print("❌ Failed to regenerate research: \(error)")
        }
    }

    func reverseAction(_ actionId: String, for entryId: String) async {
        // TODO: Implement action reversal with ToolService
        databaseManager.updateAIActionStatus(entryId, actionId: actionId, status: .reversed)
        print("↩️ Reversed action: \(actionId)")
    }

    func updateProcessingStats() {
        let usageStats = databaseManager.getAIUsageStats()

        processingStats = ProcessingStats(
            totalProcessed: usageStats.totalEntriesProcessed,
            totalCost: usageStats.totalCost,
            averageCostPerEntry: usageStats.averageCostPerEntry,
            currentlyProcessing: processingQueue.count,
            lastUpdated: usageStats.lastUpdated
        )
    }

    // MARK: - Batch Operations

    func processAllUnprocessedEntries() async {
        guard aiService.isConfigured else {
            print("⚠️ AI Service not configured")
            return
        }

        let unprocessedEntries = databaseManager.getEntriesNeedingAIProcessing()
        guard !unprocessedEntries.isEmpty else {
            print("ℹ️ No unprocessed entries found")
            return
        }

        print("🚀 Starting batch processing of \(unprocessedEntries.count) entries")

        for entry in unprocessedEntries {
            await processEntryInternal(entry)
        }

        print("✅ Batch processing complete")
    }

    func getUnprocessedCount() -> Int {
        return databaseManager.getEntriesNeedingAIProcessing().count
    }

    // MARK: - Settings Integration

    func updateAIConfiguration() {
        // Called when AI settings change
        updateProcessingStats()
    }
}

// MARK: - Supporting Types

struct ProcessingStats {
    let totalProcessed: Int
    let totalCost: Double
    let averageCostPerEntry: Double
    let currentlyProcessing: Int
    let lastUpdated: Date

    init(totalProcessed: Int = 0, totalCost: Double = 0, averageCostPerEntry: Double = 0, currentlyProcessing: Int = 0, lastUpdated: Date = Date()) {
        self.totalProcessed = totalProcessed
        self.totalCost = totalCost
        self.averageCostPerEntry = averageCostPerEntry
        self.currentlyProcessing = currentlyProcessing
        self.lastUpdated = lastUpdated
    }

    var formattedCost: String {
        return String(format: "$%.4f", totalCost)
    }

    var formattedAverageCost: String {
        return String(format: "$%.4f", averageCostPerEntry)
    }

    var hasData: Bool {
        return totalProcessed > 0
    }
}

// Placeholder ToolService until we implement the real one
struct ToolService {
    // This will be implemented in the next step
    func executeAction(_ action: AIAction) async throws -> Bool {
        // Placeholder implementation
        return true
    }
}
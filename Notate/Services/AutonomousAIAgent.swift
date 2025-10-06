import Foundation
import Combine

@MainActor
class AutonomousAIAgent: ObservableObject {
    private let aiService: AIService
    private let databaseManager: DatabaseManager
    private let toolService: ToolService
    private let contentExtractor: AIContentExtractor

    @Published var isProcessing: Bool = false
    @Published var processingQueue: [String] = [] // Entry IDs being processed
    @Published var processingStats = ProcessingStats()

    private var cancellables = Set<AnyCancellable>()

    init(aiService: AIService, databaseManager: DatabaseManager) {
        self.aiService = aiService
        self.databaseManager = databaseManager
        self.toolService = ToolService()
        self.contentExtractor = AIContentExtractor(aiService: aiService)

        // Initialize processing stats
        updateProcessingStats()
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

        // 1. Extract all information from content using AI
        let extractedInfo = await contentExtractor.extractAllInformation(entry.content)

        // 2. Create reminder action for TODOs
        if contentExtractor.shouldCreateReminder(extractedInfo, entryType: .todo) {
            if let reminderAction = await createReminderAction(from: entry.content, extractedInfo: extractedInfo) {
                actions.append(reminderAction)
            }
        }

        // 3. Create calendar action if it has time information
        if contentExtractor.shouldCreateCalendarEvent(extractedInfo) {
            if let calendarAction = await createCalendarAction(from: entry.content, extractedInfo: extractedInfo) {
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

        // 1. Extract all information from content using AI
        let extractedInfo = await contentExtractor.extractAllInformation(entry.content)

        // 2. Create contact action if we have contact info
        if contentExtractor.shouldCreateContact(extractedInfo) {
            if let contactAction = await createContactAction(from: entry.content, extractedInfo: extractedInfo) {
                actions.append(contactAction)
            }
        }

        // 3. Open maps if we have location info
        if contentExtractor.shouldOpenMaps(extractedInfo) {
            if let mapAction = await createMapAction(from: entry.content, extractedInfo: extractedInfo) {
                actions.append(mapAction)
            }
        }

        // 4. Generate research if it's not just raw data
        var research: ResearchResults?
        if contentExtractor.shouldGenerateResearch(extractedInfo, text: entry.content) {
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

    private func createReminderAction(from content: String, extractedInfo: ExtractedInformation) async -> AIAction? {
        let title = extractedInfo.actionIntent != nil ?
            "\(extractedInfo.actionIntent!) - \(content)" : content

        var actionData: [String: ActionData] = [
            "title": ActionData(title),
            "notes": ActionData("Created by Notate AI"),
            "original_content": ActionData(content)
        ]

        // Add time info if available
        if let timeInfo = extractedInfo.timeInfo {
            actionData["due_date"] = ActionData(timeInfo)
        }

        return AIAction(
            type: .appleReminders,
            status: .pending,
            data: actionData,
            executedAt: nil,
            reversible: true,
            reverseData: [
                "reminder_existed": ActionData(false)
            ]
        )
    }

    private func createCalendarAction(from content: String, extractedInfo: ExtractedInformation) async -> AIAction? {
        let title = extractedInfo.actionIntent != nil ?
            "\(extractedInfo.actionIntent!) - \(content)" : content

        var actionData: [String: ActionData] = [
            "title": ActionData(title),
            "notes": ActionData("Created by Notate AI"),
            "original_content": ActionData(content)
        ]

        // Add extracted information
        if let timeInfo = extractedInfo.timeInfo {
            actionData["start_time"] = ActionData(timeInfo)
        }

        if let locationInfo = extractedInfo.locationInfo {
            actionData["location"] = ActionData(locationInfo)
        }

        return AIAction(
            type: .calendar,
            status: .pending,
            data: actionData,
            executedAt: nil,
            reversible: true,
            reverseData: [
                "event_existed": ActionData(false)
            ]
        )
    }

    private func createContactAction(from content: String, extractedInfo: ExtractedInformation) async -> AIAction? {
        var actionData: [String: ActionData] = [
            "original_content": ActionData(content),
            "notes": ActionData("Added by Notate AI")
        ]

        // Use extracted information
        if let phone = extractedInfo.phoneNumber {
            actionData["phone"] = ActionData(phone)
        }

        if let email = extractedInfo.email {
            actionData["email"] = ActionData(email)
        }

        actionData["name"] = ActionData(extractedInfo.personName ?? "Unknown Contact")

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

    private func createMapAction(from content: String, extractedInfo: ExtractedInformation) async -> AIAction? {
        guard let locationInfo = extractedInfo.locationInfo else { return nil }

        return AIAction(
            type: .maps,
            status: .pending,
            data: [
                "location": ActionData(locationInfo),
                "notes": ActionData("Opened by Notate AI"),
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

        // Execute actions with ToolService
        await executeActionsWithToolService(actions, for: entry.id, using: toolService)
    }

    private func executeActionsWithToolService(_ actions: [AIAction], for entryId: String, using toolService: ToolService) async {
        for action in actions {
            do {
                let success = try await executeAction(action, using: toolService)
                databaseManager.updateAIActionStatus(entryId, actionId: action.id, status: success ? .executed : .failed)
                print("✅ Executed action: \(action.type.displayName)")
            } catch {
                print("❌ Failed to execute action \(action.id): \(error)")
                databaseManager.updateAIActionStatus(entryId, actionId: action.id, status: .failed)
            }
        }
    }

    private func executeAction(_ action: AIAction, using toolService: ToolService) async throws -> Bool {
        switch action.type {
        case .appleReminders:
            guard let title = action.data["title"]?.stringValue else { return false }
            let notes = action.data["notes"]?.stringValue
            let _ = try await toolService.createReminder(title: title, notes: notes)
            return true

        case .calendar:
            guard let title = action.data["title"]?.stringValue else { return false }
            let notes = action.data["notes"]?.stringValue
            // Extract date/time from original content if possible
            let startDate = extractDateFromContent(action.data["original_content"]?.stringValue ?? "") ?? Date()
            let _ = try await toolService.createCalendarEvent(title: title, notes: notes, startDate: startDate)
            return true

        case .contacts:
            guard let name = action.data["name"]?.stringValue else { return false }
            let phoneNumber = action.data["phone"]?.stringValue
            let email = action.data["email"]?.stringValue
            let nameParts = name.components(separatedBy: " ")
            let firstName = nameParts.first ?? name
            let lastName = nameParts.count > 1 ? nameParts.dropFirst().joined(separator: " ") : nil
            let _ = try await toolService.createContact(
                firstName: firstName,
                lastName: lastName,
                phoneNumber: phoneNumber,
                email: email
            )
            return true

        case .maps:
            guard let location = action.data["location"]?.stringValue else { return false }
            try await toolService.openInMaps(address: location)
            return true

        case .webSearch:
            // Web search doesn't require system integration
            return true
        }
    }

    private func extractDateFromContent(_ content: String) -> Date? {
        // Simple date/time extraction - could be enhanced with NLP
        let calendar = Calendar.current
        let now = Date()

        // Look for common time patterns
        if content.lowercased().contains("tomorrow") {
            return calendar.date(byAdding: .day, value: 1, to: now)
        } else if content.lowercased().contains("next week") {
            return calendar.date(byAdding: .weekOfYear, value: 1, to: now)
        } else if content.lowercased().contains("today") {
            return now
        }

        // Default to 1 hour from now if no specific time found
        return calendar.date(byAdding: .hour, value: 1, to: now)
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


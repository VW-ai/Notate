// AppState.swift
import Foundation
import Combine
import AppKit

@MainActor
final class AppState: ObservableObject {
    let engine = CaptureEngine()
    let databaseManager = DatabaseManager.shared
    let configManager = ConfigurationManager.shared

    // AI Components
    let aiService = AIService()
    lazy var contentExtractor = AIContentExtractor(aiService: aiService)
    lazy var autonomousAIAgent = AutonomousAIAgent(aiService: aiService, databaseManager: databaseManager)
    lazy var permissionManager = PermissionManager()

    // Notification Services
    let systemNotificationManager = SystemNotificationManager.shared
    
    @Published var lastCapturedPreview: String = ""
    @Published var lastCaptureResult: CaptureResult?
    @Published var entries: [Entry] = []
    @Published var selectedTab: TabSelection = TabSelection.all
    @Published var searchQuery: String = ""
    @Published var selectedFilter: FilterType = FilterType.none
    @Published var selectedEntry: Entry?
    @Published var selectedEvent: CalendarEvent?
    @Published var processingEntryIds: Set<String> = []

    private var cancellables = Set<AnyCancellable>()
    
    enum TabSelection: String, CaseIterable {
        case all = "All"
        case todos = "TODOs"
        case thoughts = "Pieces"
        case archive = "Archive"

        var displayName: String {
            return self.rawValue
        }
    }
    
    enum FilterType: String, CaseIterable {
        case none = "None"
        case open = "Open"
        case done = "Done"
        case high = "High Priority"
        case medium = "Medium Priority"
        case low = "Low Priority"
        
        var displayName: String {
            return self.rawValue
        }
    }
    
    init() {
        setupBindings()
        loadEntries()
    }
    
    private func setupBindings() {
        // Bind database entries to published property
        databaseManager.$entries
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newEntries in
                guard let self = self else { return }
                print("📥 AppState received \(newEntries.count) entries from database")
                self.entries = newEntries
            }
            .store(in: &cancellables)

        // Listen for capture results
        NotificationCenter.default.publisher(for: .notateDidFinishCapture)
            .compactMap { $0.object as? CaptureResult }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                self?.lastCaptureResult = result
                self?.lastCapturedPreview = result.content
            }
            .store(in: &cancellables)

        // Listen for entry creation to trigger AI processing
        NotificationCenter.default.publisher(for: Notification.Name("Notate.entryCreated"))
            .compactMap { $0.object as? Entry }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] entry in
                self?.handleNewEntry(entry)
            }
            .store(in: &cancellables)

        // Listen for notification taps to show specific entry
        NotificationCenter.default.publisher(for: NSNotification.Name("ShowEntryFromNotification"))
            .compactMap { $0.userInfo?["entryId"] as? String }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] entryId in
                self?.showEntryFromNotification(entryId: entryId)
            }
            .store(in: &cancellables)

        // Listen for timer trigger to show tag selection popup
        NotificationCenter.default.publisher(for: .notateDidDetectTimerTrigger)
            .compactMap { $0.object as? TimerCaptureResult }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                self?.showTimerTagSelection(eventName: result.eventName)
            }
            .store(in: &cancellables)
    }

    private func showEntryFromNotification(entryId: String) {
        // Find the entry and select it
        if let entry = entries.first(where: { $0.id == entryId }) {
            selectedEntry = entry
            print("📍 Showing entry from notification: \(entry.content.prefix(50))")
        }
    }

    private func showTimerTagSelection(eventName: String) {
        // Show timer tag selection popup window
        let window = TimerTagSelectionWindow(eventName: eventName)
        window.makeKeyAndOrderFront(nil)
        print("🍅 Showing timer tag selection for: \(eventName)")
    }
    
    func loadEntries() {
        databaseManager.loadEntries()
    }
    
    func forceRefreshEntries() {
        databaseManager.forceRefreshEntries()
    }

    // MARK: - AI Processing Integration

    private func handleNewEntry(_ entry: Entry) {
        // Prevent app from coming to foreground during background capture
        preventWindowActivation()

        // Send notification that entry was captured
        systemNotificationManager.notifyEntryCapture(entry)

        // Trigger AI processing if enabled
        if aiService.isConfigured && UserDefaults.standard.bool(forKey: "aiProcessingEnabled") {
            print("🤖 Starting AI processing for: \(entry.content.prefix(50))...")
            processEntryWithAI(entry)
        } else {
            print("⚠️ AI processing disabled or not configured")
        }
    }

    private func preventWindowActivation() {
        // Deactivate app to prevent it from stealing focus
        // This ensures capture happens in background
        DispatchQueue.main.async {
            NSApp.hide(nil)
        }
    }


    func filteredEntries() -> [Entry] {
        var filtered = entries

        // Apply tab filter with smart archiving logic
        switch selectedTab {
        case .todos:
            // TODOs tab: Only show OPEN todos (completed ones are auto-archived)
            filtered = filtered.filter { $0.isTodo && $0.status == EntryStatus.open }
        case .thoughts:
            // Pieces tab: Show all pieces (they don't get archived)
            filtered = filtered.filter { $0.isPiece }
        case .archive:
            // Archive tab: Show completed TODOs only
            filtered = filtered.filter { $0.isTodo && $0.status == EntryStatus.done }
        case .all:
            // All tab: Show active TODOs + all pieces (exclude completed TODOs)
            filtered = filtered.filter { entry in
                entry.isPiece || (entry.isTodo && entry.status == EntryStatus.open)
            }
        }

        // Apply additional priority filter (only relevant for open items)
        if selectedTab != .archive {
            switch selectedFilter {
            case .open:
                // Redundant for todos tab, but useful for "all" tab
                filtered = filtered.filter { $0.status == EntryStatus.open }
            case .done:
                // This filter is now only meaningful in archive context
                // For non-archive tabs, this does nothing since done items are already filtered out
                break
            case .high:
                filtered = filtered.filter { $0.priority == EntryPriority.high }
            case .medium:
                filtered = filtered.filter { $0.priority == EntryPriority.medium }
            case .low:
                filtered = filtered.filter { $0.priority == EntryPriority.low }
            case .none:
                break
            }
        }

        // Apply search filter
        if !searchQuery.isEmpty {
            filtered = filtered.filter { entry in
                entry.content.localizedCaseInsensitiveContains(searchQuery) ||
                entry.tags.contains { $0.localizedCaseInsensitiveContains(searchQuery) }
            }
        }

        return filtered
    }
    
    func updateEntry(_ entry: Entry) {
        databaseManager.updateEntry(entry)
    }
    
    func deleteEntry(_ entry: Entry) {
        databaseManager.deleteEntry(id: entry.id)
    }
    
    func convertThoughtToTodo(_ entry: Entry) {
        var mutableEntry = entry
        let convertedEntry = mutableEntry.convertToTodo()
        databaseManager.updateEntry(convertedEntry)
    }
    
    func convertTodoToThought(_ entry: Entry) {
        var mutableEntry = entry
        let convertedEntry = mutableEntry.convertToThought()
        databaseManager.updateEntry(convertedEntry)
    }
    
    func markTodoAsDone(_ entry: Entry) {
        var updatedEntry = entry
        updatedEntry.markAsDone()
        databaseManager.updateEntry(updatedEntry)

        // Show success feedback
        print("✅ TODO completed and archived: \(entry.content)")

        // Post notification for UI feedback (could trigger toast/animation)
        NotificationCenter.default.post(
            name: Notification.Name("Notate.todoArchived"),
            object: updatedEntry
        )
    }
    
    func markTodoAsOpen(_ entry: Entry) {
        var updatedEntry = entry
        updatedEntry.markAsOpen()
        databaseManager.updateEntry(updatedEntry)
    }

    // MARK: - Archive Management

    func getArchivedEntries() -> [Entry] {
        return entries.filter { $0.isTodo && $0.status == EntryStatus.done }
    }

    func restoreFromArchive(_ entry: Entry) {
        guard entry.isTodo && entry.status == EntryStatus.done else { return }
        var restoredEntry = entry
        restoredEntry.markAsOpen()
        databaseManager.updateEntry(restoredEntry)

        // Show success feedback
        print("✅ Restored TODO from archive: \(entry.content)")
    }

    func permanentlyDeleteFromArchive(_ entry: Entry) {
        guard entry.isTodo && entry.status == EntryStatus.done else { return }
        databaseManager.deleteEntry(id: entry.id)

        print("🗑️ Permanently deleted archived TODO: \(entry.content)")
    }

    func clearArchive() {
        let archivedEntries = getArchivedEntries()
        for entry in archivedEntries {
            databaseManager.deleteEntry(id: entry.id)
        }

        print("🧹 Cleared archive: \(archivedEntries.count) items deleted")
    }

    func getArchiveCount() -> Int {
        return getArchivedEntries().count
    }

    // MARK: - AI Processing

    func processEntryWithAI(_ entry: Entry) {
        processingEntryIds.insert(entry.id)
        Task {
            await autonomousAIAgent.processEntry(entry)
            await MainActor.run {
                processingEntryIds.remove(entry.id)
            }
        }
    }

    func processAllUnprocessedEntries() {
        Task {
            await autonomousAIAgent.processAllUnprocessedEntries()
        }
    }

    func regenerateAIResearch(for entry: Entry) {
        processingEntryIds.insert(entry.id)
        Task {
            await autonomousAIAgent.regenerateResearch(for: entry)
            await MainActor.run {
                processingEntryIds.remove(entry.id)
            }
        }
    }

    func reverseAIAction(_ actionId: String, for entry: Entry) {
        Task {
            await autonomousAIAgent.reverseAction(actionId, for: entry.id)
        }
    }

    var aiProcessingStats: ProcessingStats {
        return autonomousAIAgent.processingStats
    }

    var unprocessedAICount: Int {
        return autonomousAIAgent.getUnprocessedCount()
    }
}

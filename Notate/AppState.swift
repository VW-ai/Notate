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

        // Listen for notification clicks to show timer popups
        NotificationCenter.default.publisher(for: NSNotification.Name("ShowTimerNameInput"))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.showEventNameInputPopup()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: NSNotification.Name("ShowRunningTimerPopup"))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.showRunningTimerPopup()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: NSNotification.Name("ShowTimerConflictPopup"))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                // Re-trigger the conflict check
                if let self = self, OperatorState.shared.isTimerRunning {
                    self.showTimerConflictPopup(newEventName: nil)
                }
            }
            .store(in: &cancellables)

        // Listen for timer start from notification text input
        NotificationCenter.default.publisher(for: NSNotification.Name("StartTimerFromNotification"))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                if let eventName = notification.userInfo?["eventName"] as? String {
                    self?.startTimerImmediately(eventName: eventName)
                }
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

    // MARK: - Simplified Timer Workflow

    private func showTimerTagSelection(eventName: String) {
        let operatorState = OperatorState.shared
        let isEmpty = eventName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        if operatorState.isTimerRunning {
            // Timer is already running
            if isEmpty {
                // User typed ;;; - show running timer status
                showRunningTimerPopup()
            } else {
                // User typed ;;;event name - show conflict
                showTimerConflictPopup(newEventName: eventName)
            }
        } else {
            // No timer running
            if isEmpty {
                // User typed ;;; - show event name input + notification
                showEventNameInputPopup()
            } else {
                // User typed ;;;event name - start timer immediately + notification
                startTimerImmediately(eventName: eventName)
            }
        }
    }

    private func showEventNameInputPopup() {
        let popupManager = TimerPopupManager.shared

        // Send notification
        let notifId = systemNotificationManager.notifyTimerNameInput()

        // Show popup
        popupManager.showPopup(
            mode: .eventNameInput(completion: { [weak self] eventName in
                // Start timer with the entered name
                self?.startTimerImmediately(eventName: eventName)
                popupManager.closePopup()
            }),
            notificationId: notifId
        )
    }

    private func startTimerImmediately(eventName: String) {
        let operatorState = OperatorState.shared
        let popupManager = TimerPopupManager.shared

        // Start the timer (no tags yet - will be added when stopped)
        operatorState.startTimer()
        operatorState.timerEventName = eventName
        operatorState.timerTags = [] // Tags selected after stopping

        print("🍅 Timer started: '\(eventName)'")

        // Send notification
        _ = systemNotificationManager.notifyTimerStarted(eventName: eventName)

        // Close any open popups FIRST
        popupManager.closePopup()

        // Immediately hide the app to return to original context
        // Use sync to ensure it happens before popup activation completes
        NSApp.hide(nil)
    }

    private func showRunningTimerPopup() {
        let operatorState = OperatorState.shared
        let popupManager = TimerPopupManager.shared
        guard let startTime = operatorState.timerStartTime else { return }

        let duration = Date().timeIntervalSince(startTime)

        // Send notification
        let notifId = systemNotificationManager.notifyTimerRunning(
            eventName: operatorState.timerEventName,
            duration: duration
        )

        // Show popup
        popupManager.showPopup(
            mode: .runningTimer(
                eventName: operatorState.timerEventName,
                tags: operatorState.timerTags,
                startTime: startTime,
                onStop: { [weak self] in
                    // Timer stopped - show tag selection
                    self?.showTagSelectionForStoppedTimer()
                }
            ),
            notificationId: notifId
        )
    }

    private func showTimerConflictPopup(newEventName: String?) {
        let operatorState = OperatorState.shared
        let popupManager = TimerPopupManager.shared
        guard let startTime = operatorState.timerStartTime else { return }

        let currentDuration = Date().timeIntervalSince(startTime)

        // Send notification
        let notifId = systemNotificationManager.notifyTimerConflict(
            eventName: operatorState.timerEventName,
            duration: currentDuration
        )

        // Show popup
        popupManager.showPopup(
            mode: .conflict(
                currentEventName: operatorState.timerEventName,
                currentTags: operatorState.timerTags,
                currentDuration: currentDuration,
                newEventName: newEventName,
                completion: { [weak self] shouldStop in
                    if shouldStop {
                        // Stop current timer - show tag selection first
                        self?.showTagSelectionForStoppedTimer(newEventAfter: newEventName)
                    } else {
                        // Cancel - just close popup
                        popupManager.closePopup()
                    }
                }
            ),
            notificationId: notifId
        )
    }

    /// Shows tag selection after timer is stopped
    /// - Parameter newEventAfter: If provided, starts a new timer after saving current one
    private func showTagSelectionForStoppedTimer(newEventAfter: String? = nil) {
        let operatorState = OperatorState.shared
        let popupManager = TimerPopupManager.shared

        // Capture current timer state before stopping
        let eventName = operatorState.timerEventName
        let startTime = operatorState.timerStartTime ?? Date()
        let duration = Date().timeIntervalSince(startTime)

        // Stop the timer
        _ = operatorState.stopTimer()

        // Show tag selection popup
        popupManager.showPopup(
            mode: .tagSelection(
                eventName: eventName,
                completion: { [weak self] selectedTags in
                    // Save to calendar with selected tags
                    self?.saveTimerToCalendar(
                        eventName: eventName,
                        tags: selectedTags,
                        duration: duration
                    )

                    // Reset timer state
                    operatorState.resetTimer()

                    // Close popup
                    popupManager.closePopup()

                    // If there's a new event to start after this, start it
                    if let newEvent = newEventAfter {
                        if newEvent.isEmpty {
                            self?.showEventNameInputPopup()
                        } else {
                            self?.startTimerImmediately(eventName: newEvent)
                        }
                    }
                }
            )
        )
    }

    /// Public method to stop timer (called from in-app UI)
    /// In-app stops show the creation detail view for confirmation/editing
    func stopTimerFromApp() {
        let operatorState = OperatorState.shared

        // Stop the timer (keeps event name and tags in state)
        _ = operatorState.stopTimer()

        // Enter timer creation mode to show detail view
        operatorState.enterCreationMode(.timer)

        print("🍅 Timer stopped from app, showing creation detail view")
    }

    private func saveTimerToCalendar(eventName: String, tags: [String], duration: TimeInterval) {
        let toolService = ToolService()
        let startTime = Date().addingTimeInterval(-duration)
        let endTime = Date()

        Task {
            do {
                let eventId = try await toolService.createCalendarEvent(
                    title: eventName,
                    notes: tags.isEmpty ? nil : "Tags: \(tags.joined(separator: ", "))",
                    startDate: startTime,
                    endDate: endTime
                )

                await MainActor.run {
                    print("✅ Timer saved to calendar: \(eventId ?? "unknown")")

                    // Refresh calendar to show the new event in timeline
                    CalendarService.shared.fetchEvents(for: startTime)

                    // Notification will be sent by ToolService on successful calendar event creation
                }
            } catch {
                await MainActor.run {
                    print("❌ Failed to save timer to calendar: \(error)")
                }
            }
        }
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

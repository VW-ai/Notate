// AppState.swift
import Foundation
import Combine

@MainActor
final class AppState: ObservableObject {
    let engine = CaptureEngine()
    let databaseManager = DatabaseManager.shared
    let configManager = ConfigurationManager.shared
    
    @Published var lastCapturedPreview: String = ""
    @Published var lastCaptureResult: CaptureResult?
    @Published var entries: [Entry] = []
    @Published var selectedTab: TabSelection = TabSelection.all
    @Published var searchQuery: String = ""
    @Published var selectedFilter: FilterType = FilterType.none
    
    private var cancellables = Set<AnyCancellable>()
    
    enum TabSelection: String, CaseIterable {
        case all = "All"
        case todos = "TODOs"
        case thoughts = "Thoughts"
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
            .assign(to: \.entries, on: self)
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
    }
    
    func loadEntries() {
        databaseManager.loadEntries()
    }
    
    func forceRefreshEntries() {
        databaseManager.forceRefreshEntries()
    }
    
    func filteredEntries() -> [Entry] {
        var filtered = entries

        // Apply tab filter with smart archiving logic
        switch selectedTab {
        case .todos:
            // TODOs tab: Only show OPEN todos (completed ones are auto-archived)
            filtered = filtered.filter { $0.isTodo && $0.status == EntryStatus.open }
        case .thoughts:
            // Thoughts tab: Show all thoughts (they don't get archived)
            filtered = filtered.filter { $0.isThought }
        case .archive:
            // Archive tab: Show completed TODOs only
            filtered = filtered.filter { $0.isTodo && $0.status == EntryStatus.done }
        case .all:
            // All tab: Show active TODOs + all thoughts (exclude completed TODOs)
            filtered = filtered.filter { entry in
                entry.isThought || (entry.isTodo && entry.status == EntryStatus.open)
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
}

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
        
        // Apply tab filter
        switch selectedTab {
        case .todos:
            filtered = filtered.filter { $0.isTodo }
        case .thoughts:
            filtered = filtered.filter { $0.isThought }
        case .all:
            break
        }
        
        // Apply status/priority filter
        switch selectedFilter {
        case .open:
            filtered = filtered.filter { $0.status == EntryStatus.open }
        case .done:
            filtered = filtered.filter { $0.status == EntryStatus.done }
        case .high:
            filtered = filtered.filter { $0.priority == EntryPriority.high }
        case .medium:
            filtered = filtered.filter { $0.priority == EntryPriority.medium }
        case .low:
            filtered = filtered.filter { $0.priority == EntryPriority.low }
        case .none:
            break
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
    }
    
    func markTodoAsOpen(_ entry: Entry) {
        var updatedEntry = entry
        updatedEntry.markAsOpen()
        databaseManager.updateEntry(updatedEntry)
    }
}

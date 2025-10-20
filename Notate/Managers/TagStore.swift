import Foundation
import SwiftUI
import Combine

// MARK: - Tag Store
// Unified source of truth for all tags across entries and calendar events
// Provides global tag list independent of selected date

@MainActor
class TagStore: ObservableObject {
    static let shared = TagStore()

    // MARK: - Published Properties

    /// All tags with their usage counts (from entries + ALL calendar events)
    @Published private(set) var tagCounts: [String: Int] = [:]

    /// All unique tags sorted alphabetically
    @Published private(set) var allTags: [String] = []

    /// Top tags sorted by usage count
    @Published private(set) var topTags: [String] = []

    // MARK: - Private Properties

    private var cancellables = Set<AnyCancellable>()
    private let calendarService = CalendarService.shared

    private init() {
        setupObservers()
        refreshAllTags()
    }

    // MARK: - Public Methods

    /// Get top N most-used tags
    func getTopTags(limit: Int = 8, excluding: [String] = []) -> [String] {
        return tagCounts
            .sorted { $0.value > $1.value }
            .map { $0.key }
            .filter { !excluding.contains($0) }
            .prefix(limit)
            .map { $0 }
    }

    /// Get all tags matching search text
    func searchTags(_ searchText: String, excluding: [String] = []) -> [String] {
        guard !searchText.isEmpty else { return getTopTags(excluding: excluding) }

        let cleanText = searchText.hasPrefix("#") ? String(searchText.dropFirst()) : searchText

        return allTags.filter { tag in
            tag.localizedCaseInsensitiveContains(cleanText) && !excluding.contains(tag)
        }
    }

    /// Force refresh all tags from both sources
    func refreshAllTags() {
        Task {
            await refreshTagsFromAllSources()
        }
    }

    // MARK: - Private Methods

    private func setupObservers() {
        // Observe entry changes from DatabaseManager
        NotificationCenter.default.publisher(for: NSNotification.Name("DatabaseEntriesDidChange"))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshAllTags()
            }
            .store(in: &cancellables)

        // Observe calendar event changes
        calendarService.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                // Debounce calendar updates
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self?.refreshAllTags()
                }
            }
            .store(in: &cancellables)
    }

    private func refreshTagsFromAllSources() async {
        await MainActor.run {
            var counts: [String: Int] = [:]

            // 1. Get tags from entries (from database)
            let databaseManager = DatabaseManager.shared
            let entries = databaseManager.entries
            let entryTags = entries.flatMap { $0.tags }

            for tag in entryTags {
                counts[tag, default: 0] += 1
            }

            // 2. Get tags from ALL calendar events (not just selected date)
            // We need to fetch ALL events, not just the current date
            fetchAllCalendarEventTags { eventTags in
                for tag in eventTags {
                    counts[tag, default: 0] += 1
                }

                // Update published properties
                self.tagCounts = counts
                self.allTags = Array(counts.keys).sorted()
                self.topTags = counts
                    .sorted { $0.value > $1.value }
                    .map { $0.key }

                print("📊 TagStore refreshed: \(counts.count) unique tags, top: \(self.topTags.prefix(5).joined(separator: ", "))")
            }
        }
    }

    /// Fetch tags from ALL calendar events (across all dates)
    private func fetchAllCalendarEventTags(completion: @escaping ([String]) -> Void) {
        // Fetch events from a wide date range (past year to next year)
        let calendar = Calendar.current
        let now = Date()
        let startDate = calendar.date(byAdding: .year, value: -1, to: now) ?? now
        let endDate = calendar.date(byAdding: .year, value: 1, to: now) ?? now

        // Use CalendarService to fetch events
        Task {
            let events = await calendarService.fetchAllEvents(from: startDate, to: endDate)
            let tags = events.flatMap { event in
                SimpleEventDetailView.extractTags(from: event.notes)
            }

            await MainActor.run {
                completion(tags)
            }
        }
    }
}

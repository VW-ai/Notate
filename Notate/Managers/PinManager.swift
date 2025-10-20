import Foundation
import Combine

/// Manages pinned state for calendar events
/// Since we can't modify the Calendar.app structure directly, we store pinned event IDs locally
final class PinManager: ObservableObject {
    static let shared = PinManager()

    @Published private(set) var pinnedEventIDs: Set<String> = []

    private let userDefaultsKey = "notate.pinnedEvents"

    private init() {
        loadPinnedEvents()
    }

    // MARK: - Persistence

    private func loadPinnedEvents() {
        if let data = UserDefaults.standard.array(forKey: userDefaultsKey) as? [String] {
            pinnedEventIDs = Set(data)
            print("✅ Loaded \(pinnedEventIDs.count) pinned events")
        }
    }

    private func savePinnedEvents() {
        UserDefaults.standard.set(Array(pinnedEventIDs), forKey: userDefaultsKey)
        print("💾 Saved \(pinnedEventIDs.count) pinned events")
    }

    // MARK: - Public API

    func isPinned(_ eventID: String) -> Bool {
        return pinnedEventIDs.contains(eventID)
    }

    func pin(_ eventID: String) {
        pinnedEventIDs.insert(eventID)
        savePinnedEvents()
        print("📌 Pinned event: \(eventID)")
    }

    func unpin(_ eventID: String) {
        pinnedEventIDs.remove(eventID)
        savePinnedEvents()
        print("📍 Unpinned event: \(eventID)")
    }

    func togglePin(_ eventID: String) {
        if isPinned(eventID) {
            unpin(eventID)
        } else {
            pin(eventID)
        }
    }

    func clearAll() {
        pinnedEventIDs.removeAll()
        savePinnedEvents()
        print("🧹 Cleared all pinned events")
    }

    // MARK: - Bulk Operations

    func pinMultiple(_ eventIDs: [String]) {
        pinnedEventIDs.formUnion(eventIDs)
        savePinnedEvents()
        print("📌 Pinned \(eventIDs.count) events")
    }

    func unpinMultiple(_ eventIDs: [String]) {
        pinnedEventIDs.subtract(eventIDs)
        savePinnedEvents()
        print("📍 Unpinned \(eventIDs.count) events")
    }

    // MARK: - Cleanup

    /// Remove pinned event IDs that no longer exist in the calendar
    func cleanup(validEventIDs: Set<String>) {
        let beforeCount = pinnedEventIDs.count
        pinnedEventIDs = pinnedEventIDs.intersection(validEventIDs)
        let removed = beforeCount - pinnedEventIDs.count

        if removed > 0 {
            savePinnedEvents()
            print("🧹 Cleaned up \(removed) stale pinned event IDs")
        }
    }
}

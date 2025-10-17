import SwiftUI
import Combine

// MARK: - Tag Drag State
// Global state for "sticky cursor" tag assignment mode

@MainActor
class TagDragState: ObservableObject {
    static let shared = TagDragState()

    @Published var isDragging: Bool = false
    @Published var draggingTags: [String] = []
    @Published var cursorPosition: CGPoint = .zero

    private var mouseTrackingMonitor: Any?

    private init() {
        setupMouseTracking()
    }

    private func setupMouseTracking() {
        // Set up global mouse tracking that updates cursor position continuously
        mouseTrackingMonitor = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved, .leftMouseDragged]) { [weak self] event in
            guard let self = self, self.isDragging else { return event }

            if let window = NSApp.keyWindow {
                let mouseLocationInWindow = event.locationInWindow
                // SwiftUI uses top-left origin, AppKit uses bottom-left
                // Convert AppKit coordinates to SwiftUI coordinates
                let swiftUIY = window.frame.height - mouseLocationInWindow.y
                let position = CGPoint(x: mouseLocationInWindow.x, y: swiftUIY)

                Task { @MainActor in
                    self.cursorPosition = position
                }
            }

            return event
        }
    }

    deinit {
        if let monitor = mouseTrackingMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    // Start dragging tags (sticky cursor mode)
    func startDragging(tags: [String]) {
        guard !tags.isEmpty else { return }
        draggingTags = tags

        // Set initial cursor position
        if let window = NSApp.keyWindow,
           let currentEvent = NSApp.currentEvent {
            let mouseLocationInWindow = currentEvent.locationInWindow
            let swiftUIY = window.frame.height - mouseLocationInWindow.y
            cursorPosition = CGPoint(x: mouseLocationInWindow.x, y: swiftUIY)
        }

        isDragging = true
        print("🏷️ Started dragging \(tags.count) tag(s): \(tags.joined(separator: ", "))")
    }

    // Update cursor position
    func updateCursorPosition(_ position: CGPoint) {
        cursorPosition = position
    }

    // Stop dragging and clear state
    func stopDragging() {
        isDragging = false
        draggingTags = []
        print("🏷️ Stopped dragging tags")
    }

    // Assign dragging tags to an entry/event
    func assignToEntry(_ entryId: String, appState: AppState) {
        guard isDragging, !draggingTags.isEmpty else { return }

        if let entry = appState.entries.first(where: { $0.id == entryId }) {
            var updatedEntry = entry
            for tag in draggingTags {
                if !updatedEntry.tags.contains(tag) {
                    updatedEntry.tags.append(tag)
                }
            }
            appState.updateEntry(updatedEntry)
            print("✅ Assigned \(draggingTags.count) tag(s) to entry")
        }

        stopDragging()
    }

    func assignToEvent(_ eventId: String, calendarService: CalendarService) {
        guard isDragging, !draggingTags.isEmpty else { return }

        if let event = calendarService.events.first(where: { $0.id == eventId }) {
            var existingTags = SimpleEventDetailView.extractTags(from: event.notes)

            for tag in draggingTags {
                if !existingTags.contains(tag) {
                    existingTags.append(tag)
                }
            }

            Task {
                let toolService = ToolService()
                let tagsString = "[tags: \(existingTags.joined(separator: ", "))]"
                let existingNotes = SimpleEventDetailView.removeTagsFromNotes(event.notes)
                let newNotes = existingNotes.isEmpty ? tagsString : "\(existingNotes)\n\(tagsString)"

                do {
                    try await toolService.updateCalendarEvent(
                        eventId: eventId,
                        title: nil,
                        notes: newNotes,
                        startDate: nil
                    )
                    await MainActor.run {
                        calendarService.fetchEvents(for: event.startTime)
                        calendarService.objectWillChange.send()
                    }
                    print("✅ Assigned \(draggingTags.count) tag(s) to event")
                } catch {
                    print("❌ Failed to assign tags to event: \(error)")
                }
            }
        }

        stopDragging()
    }
}

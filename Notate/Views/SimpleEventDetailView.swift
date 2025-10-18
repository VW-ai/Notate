import SwiftUI
import EventKit
import Combine

// MARK: - Simple Event Detail View
// Minimal detail view for calendar events - same layout as SimpleEntryDetailView

struct SimpleEventDetailView: View {
    let event: CalendarEvent
    @EnvironmentObject var appState: AppState
    @StateObject private var tagColorManager = TagColorManager.shared
    @State private var editedTitle: String
    @State private var editedStartTime: Date
    @State private var editedEndTime: Date
    @State private var tagInput: String = ""
    @State private var eventTags: [String] = []
    @State private var isUpdatingTags: Bool = false

    init(event: CalendarEvent) {
        self.event = event
        _editedTitle = State(initialValue: event.title)
        _editedStartTime = State(initialValue: event.startTime)
        _editedEndTime = State(initialValue: event.endTime)
        // Extract tags from notes (tags are stored as [tags: tag1, tag2])
        _eventTags = State(initialValue: Self.extractTags(from: event.notes))
    }

    // Get tag suggestions from unified TagStore (universal, not date-dependent)
    private var tagSuggestions: [String] {
        TagStore.shared.searchTags(tagInput, excluding: eventTags)
    }

    var body: some View {
        GeometryReader { geometry in
            let topHeaderHeight: CGFloat = 150

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // First: padding to clear the weekday selection
                    Spacer()
                        .frame(height: topHeaderHeight)

                    mainContentSection(topHeaderHeight: topHeaderHeight)
                }
                .frame(minHeight: geometry.size.height) // Ensure content takes full height
            }
        }
        .background(Color(hex: "#1C1C1E").opacity(0.5))
        .transition(.opacity)
        .onReceive(CalendarService.shared.objectWillChange) { _ in
            // Update eventTags when calendar events are refreshed
            // BUT skip if we're currently updating to avoid race conditions
            guard !isUpdatingTags else { return }

            DispatchQueue.main.async {
                if let updatedEvent = CalendarService.shared.events.first(where: { $0.id == event.id }) {
                    eventTags = Self.extractTags(from: updatedEvent.notes)
                }
            }
        }
    }

    // MARK: - Main Content Section

    @ViewBuilder
    private func mainContentSection(topHeaderHeight: CGFloat) -> some View {
        HStack(alignment: .top, spacing: 0) {
            // Left spacer - tap to close
            Spacer()
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation {
                        appState.selectedEvent = nil
                    }
                }

            // Content positioned on the right side of the detail panel
            VStack(alignment: .leading, spacing: 24) {
                closeButton
                eventTitleEditor
                timeRangeSection
                eventMetadataSection
                tagsSection
                aiGeneratedIndicator
                deleteButton
            }
            .padding(32)
            .padding(.bottom, 60) // Extra bottom padding for comfortable scrolling
        }
        .frame(maxWidth: .infinity) // Take full width of container
        .background(Color(hex: "#1C1C1E")) // Same as main timeline background
        .overlay(
            // Inset shadow on all sides using event brown color
            Rectangle()
                .stroke(Color.clear, lineWidth: 0)
                .shadow(color: Color(hex: "#8B7355").opacity(0.3), radius: 8, x: 0, y: 0)
                .shadow(color: Color(hex: "#8B7355").opacity(0.2), radius: 4, x: 2, y: 0)  // Right
                .shadow(color: Color(hex: "#8B7355").opacity(0.2), radius: 4, x: -2, y: 0) // Left
                .shadow(color: Color(hex: "#8B7355").opacity(0.2), radius: 4, x: 0, y: 2)  // Bottom
                .shadow(color: Color(hex: "#8B7355").opacity(0.2), radius: 4, x: 0, y: -2) // Top
        )
        .transition(.asymmetric(
            insertion: .scale(scale: 0.8).combined(with: .opacity),
            removal: .scale(scale: 0.9).combined(with: .opacity)
        ))
    }

    @ViewBuilder
    private var aiGeneratedIndicator: some View {
        if event.isAIGenerated {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 12))
                    .foregroundColor(.orange)

                Text("AI Generated")
                    .font(.system(size: 12))
                    .foregroundColor(.orange)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.orange.opacity(0.1))
            )
        }
    }

    private var deleteButton: some View {
        Button(action: {
            deleteEvent()
        }) {
            HStack {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                Text("Delete Event")
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(.red)
        }
        .buttonStyle(PlainButtonStyle())
    }

    @ViewBuilder
    private var eventMetadataSection: some View {
        // Location
        if let location = event.location, !location.isEmpty {
            Button(action: openInCalendarApp) {
                HStack(spacing: 8) {
                    Image(systemName: "mappin.circle")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    Text(location)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "arrow.right.circle")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary.opacity(0.5))
                }
            }
            .buttonStyle(PlainButtonStyle())
        }

        // Calendar name
        HStack(spacing: 8) {
            Circle()
                .fill(event.calendarColor.map { Color(cgColor: $0) } ?? Color.gray)
                .frame(width: 12, height: 12)
            Text(event.calendarName)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }

        // Attendees
        if !event.attendees.isEmpty {
            Button(action: openInCalendarApp) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "person.2")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        Text("Attendees (\(event.attendees.count))")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        Spacer()
                        Image(systemName: "arrow.right.circle")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary.opacity(0.5))
                    }
                    ForEach(event.attendees.prefix(3), id: \.self) { attendee in
                        Text(attendee)
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .padding(.leading, 22)
                    }
                    if event.attendees.count > 3 {
                        Text("+\(event.attendees.count - 3) more")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .padding(.leading, 22)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
        }

        // Notes
        if let notes = event.notes, !notes.isEmpty {
            Button(action: openInCalendarApp) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "note.text")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        Text("Notes")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        Spacer()
                        Image(systemName: "arrow.right.circle")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary.opacity(0.5))
                    }
                    Text(notes)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .lineLimit(3)
                        .padding(.leading, 22)
                }
            }
            .buttonStyle(PlainButtonStyle())
        }

        // URL
        if let url = event.url {
            Button(action: { NSWorkspace.shared.open(url) }) {
                HStack(spacing: 8) {
                    Image(systemName: "link")
                        .font(.system(size: 14))
                    Text("Open Link")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(.orange)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Existing tags
            if !eventTags.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(eventTags, id: \.self) { tag in
                        let tagColor = tagColorManager.getColorForTag(tag) ?? .gray
                        HStack(spacing: 4) {
                            Text("#\(tag)")
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                            Button(action: { removeTag(tag) }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(tagColor.opacity(0.2)))
                        .overlay(Capsule().stroke(tagColor.opacity(0.4), lineWidth: 1))
                    }
                }
            }

            // Tag input
            TextField("Type #tag to add... (press Enter)", text: $tagInput)
                .font(.system(size: 12))
                .foregroundColor(.white)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.05)))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.1), lineWidth: 1))
                .onSubmit {
                    addTag()
                }
                .onChange(of: tagInput) { newValue in
                    if newValue.contains(" ") || newValue.contains(",") {
                        addTag()
                    }
                }

            // Tag suggestions
            if !tagSuggestions.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(tagSuggestions, id: \.self) { suggestion in
                            Button(action: {
                                tagInput = suggestion
                                addTag()
                            }) {
                                Text("#\(suggestion)")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.7))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Capsule().fill(Color.white.opacity(0.1)))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
        }
    }

    // MARK: - UI Components

    private var closeButton: some View {
        HStack {
            Spacer()
            Button(action: {
                withAnimation {
                    appState.selectedEvent = nil
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    private var eventTitleEditor: some View {
        TextEditor(text: $editedTitle)
            .font(.system(size: 18, weight: .medium))
            .foregroundColor(.white)
            .frame(minHeight: 60)
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .onChange(of: editedTitle) { newValue in
                updateEventTitle(newValue)
            }
    }

    // MARK: - Helper Methods

    private func calculateDuration() -> String {
        let interval = editedEndTime.timeIntervalSince(editedStartTime)
        let hours = Int(interval) / 3600
        let minutes = Int(interval) / 60 % 60

        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "0m"
        }
    }

    private func updateEventTitle(_ newTitle: String) {
        Task {
            let toolService = ToolService()
            do {
                try await toolService.updateCalendarEvent(
                    eventId: event.id,
                    title: newTitle,
                    notes: nil,
                    startDate: nil
                )
                print("✅ Updated event title: \(newTitle)")
            } catch {
                print("❌ Failed to update event title: \(error)")
            }
        }
    }

    private func updateEventTimes() {
        Task {
            let toolService = ToolService()
            do {
                try await toolService.updateCalendarEvent(
                    eventId: event.id,
                    title: nil,
                    notes: nil,
                    startDate: editedStartTime
                )
                print("✅ Updated event times")
            } catch {
                print("❌ Failed to update event times: \(error)")
            }
        }
    }

    private func deleteEvent() {
        Task {
            let toolService = ToolService()
            do {
                try await toolService.deleteCalendarEvent(eventId: event.id)
                print("✅ Deleted calendar event: \(event.id)")

                await MainActor.run {
                    appState.selectedEvent = nil
                    // Refresh calendar events for today
                    CalendarService.shared.fetchEvents(for: Date())
                }
            } catch {
                print("❌ Failed to delete event: \(error)")
                await MainActor.run {
                    showDeleteErrorAlert(error: error)
                }
            }
        }
    }

    private func openInCalendarApp() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        let dateString = dateFormatter.string(from: event.startTime)

        let script = """
        tell application "Calendar"
            activate
            view calendar at date "\(dateString)"
        end tell
        """

        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            scriptObject.executeAndReturnError(&error)
            if let error = error {
                print("❌ AppleScript error: \(error)")
                // Fallback: just open Calendar app
                if let calendarAppURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.iCal") {
                    NSWorkspace.shared.open(calendarAppURL)
                }
            }
        }
    }

    @MainActor
    private func showDeleteErrorAlert(error: Error) {
        let alert = NSAlert()
        alert.messageText = "Failed to Delete Event"
        alert.informativeText = "Could not delete the calendar event: \(error.localizedDescription)"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    // MARK: - Tag Management

    private func addTag() {
        var cleanedTag = tagInput.trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove # prefix if present
        if cleanedTag.hasPrefix("#") {
            cleanedTag = String(cleanedTag.dropFirst())
        }

        // Remove trailing space or comma
        cleanedTag = cleanedTag.trimmingCharacters(in: CharacterSet(charactersIn: " ,"))

        // Only add if not empty and not already in tags
        guard !cleanedTag.isEmpty, !eventTags.contains(cleanedTag) else {
            tagInput = ""
            return
        }

        // Add to local tags
        eventTags.append(cleanedTag)

        // Update event notes with tags (this will also ensure color is assigned)
        updateEventTags()

        // Clear input
        tagInput = ""

        print("✅ Added tag to event: \(cleanedTag)")
    }

    private func removeTag(_ tag: String) {
        eventTags.removeAll { $0 == tag }

        // Update event notes with tags
        updateEventTags()

        print("✅ Removed tag from event: \(tag)")
    }

    private func updateEventTags() {
        Task {
            // Set flag to prevent race conditions with onReceive
            await MainActor.run {
                isUpdatingTags = true
            }

            let toolService = ToolService()

            // Format tags into notes
            let tagsString = eventTags.isEmpty ? "" : "[tags: \(eventTags.joined(separator: ", "))]"

            // Get existing notes without tags
            let existingNotes = Self.removeTagsFromNotes(event.notes)

            // Combine existing notes with tags
            let newNotes = existingNotes.isEmpty ? tagsString : "\(existingNotes)\n\(tagsString)"

            do {
                try await toolService.updateCalendarEvent(
                    eventId: event.id,
                    title: nil,
                    notes: newNotes,
                    startDate: nil
                )
                print("✅ Updated event tags in notes")

                // Refresh calendar events to get updated data
                await MainActor.run {
                    // Register all tags and ensure colors are assigned AFTER successful save
                    for tag in eventTags {
                        tagColorManager.registerTag(tag)
                    }

                    // Refresh the event's date to update the calendar service
                    CalendarService.shared.fetchEvents(for: event.startTime)

                    // Force objectWillChange to notify observers
                    CalendarService.shared.objectWillChange.send()

                    // Small delay to ensure calendar update completes, then clear flag
                    Task {
                        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
                        await MainActor.run {
                            isUpdatingTags = false
                        }
                    }
                }
            } catch {
                print("❌ Failed to update event tags: \(error)")
                await MainActor.run {
                    isUpdatingTags = false
                }
            }
        }
    }

    // Extract tags from notes (format: [tags: tag1, tag2])
    static func extractTags(from notes: String?) -> [String] {
        guard let notes = notes else { return [] }

        let pattern = "\\[tags: ([^\\]]+)\\]"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return []
        }

        let range = NSRange(notes.startIndex..., in: notes)
        guard let match = regex.firstMatch(in: notes, options: [], range: range),
              let tagsRange = Range(match.range(at: 1), in: notes) else {
            return []
        }

        let tagsString = String(notes[tagsRange])
        return tagsString.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
    }

    // Remove tags section from notes
    static func removeTagsFromNotes(_ notes: String?) -> String {
        guard let notes = notes else { return "" }

        let pattern = "\\[tags: [^\\]]+\\]"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return notes
        }

        let range = NSRange(notes.startIndex..., in: notes)
        let result = regex.stringByReplacingMatches(in: notes, options: [], range: range, withTemplate: "")
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Time Range Section

    private var timeRangeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            startTimeCard
            endTimeCard
            durationDisplay
        }
    }

    private var startTimeCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .font(.system(size: 12))
                    .foregroundColor(.yellow)
                Text("Start")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }

            DatePicker("", selection: $editedStartTime)
                .datePickerStyle(.compact)
                .labelsHidden()
                .font(.system(size: 14, weight: .medium))
                .frame(maxWidth: .infinity, alignment: .leading)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .onChange(of: editedStartTime) { newValue in
                    updateEventTimes()
                }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.yellow.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.yellow.opacity(0.4),
                            Color.yellow.opacity(0.2)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: Color.yellow.opacity(0.15), radius: 8, x: 0, y: 2)
    }

    private var endTimeCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 12))
                    .foregroundColor(.yellow)
                Text("End")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }

            DatePicker("", selection: $editedEndTime)
                .datePickerStyle(.compact)
                .labelsHidden()
                .font(.system(size: 14, weight: .medium))
                .frame(maxWidth: .infinity, alignment: .leading)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .onChange(of: editedEndTime) { newValue in
                    updateEventTimes()
                }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.yellow.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.yellow.opacity(0.4),
                            Color.yellow.opacity(0.2)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: Color.yellow.opacity(0.15), radius: 8, x: 0, y: 2)
    }

    private var durationDisplay: some View {
        HStack(spacing: 6) {
            Image(systemName: "timer")
                .font(.system(size: 11))
                .foregroundColor(.secondary.opacity(0.7))
            Text("Duration: \(calculateDuration())")
                .font(.system(size: 12))
                .foregroundColor(.secondary.opacity(0.7))
        }
        .padding(.leading, 22)
    }
}

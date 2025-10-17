import SwiftUI
import UniformTypeIdentifiers

// MARK: - Tag Management Panel
// Drag entries/events to tags to assign them, easy tag creation

struct TagManagementPanel: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var tagColorManager = TagColorManager.shared
    @StateObject private var calendarService = CalendarService.shared
    @StateObject private var tagDragState = TagDragState.shared
    @State private var newTagInput: String = ""
    @State private var isAddingTag: Bool = false

    // Undo support
    @State private var deletedTag: String? = nil
    @State private var deletedTagData: (entries: [String], events: [String])? = nil
    @State private var undoTimer: Timer? = nil

    // Multi-select support
    @State private var selectedTags: Set<String> = []

    // Cached tag list to prevent re-layout on every state change
    @State private var cachedTagCounts: [(tag: String, count: Int, percentile: Double)] = []

    var availableWidth: CGFloat? = nil // Optional width constraint from parent

    // Sizing tiers for tag cloud (percentile-based)
    enum TagSizeTier {
        case extraLarge // Top 10%
        case large      // Top 25%
        case medium     // Top 50%
        case small      // Top 80%
        case extraSmall // Bottom 20%

        init(percentile: Double) {
            switch percentile {
            case 0..<0.10: self = .extraLarge
            case 0.10..<0.25: self = .large
            case 0.25..<0.50: self = .medium
            case 0.50..<0.80: self = .small
            default: self = .extraSmall
            }
        }

        var fontSize: CGFloat {
            switch self {
            case .extraLarge: return 28
            case .large: return 24
            case .medium: return 20
            case .small: return 18
            case .extraSmall: return 16
            }
        }

        var fontWeight: Font.Weight {
            switch self {
            case .extraLarge: return .bold
            case .large: return .semibold
            case .medium: return .semibold
            case .small: return .medium
            case .extraSmall: return .medium
            }
        }

        var padding: (horizontal: CGFloat, vertical: CGFloat) {
            switch self {
            case .extraLarge: return (20, 12)
            case .large: return (18, 10)
            case .medium: return (16, 9)
            case .small: return (14, 8)
            case .extraSmall: return (12, 7)
            }
        }
    }

    // Get all unique tags with their counts and percentiles (from BOTH entries AND events)
    private var tagCounts: [(tag: String, count: Int, percentile: Double)] {
        // Count tags from entries
        let entryTags = appState.entries.flatMap { $0.tags }

        // Count tags from calendar events
        let eventTags = calendarService.events.flatMap { event in
            SimpleEventDetailView.extractTags(from: event.notes)
        }

        // Combine both sources
        let allTags = entryTags + eventTags

        var counts: [String: Int] = [:]
        for tag in allTags {
            counts[tag, default: 0] += 1
        }

        // Include known tags with 0 count
        for knownTag in tagColorManager.getAllKnownTags() {
            if counts[knownTag] == nil {
                counts[knownTag] = 0
            }
        }

        // Sort by count descending
        let sorted = counts
            .map { (tag: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }

        // Calculate percentile for each tag
        let total = Double(sorted.count)
        return sorted.enumerated().map { index, item in
            let percentile = total > 0 ? Double(index) / total : 0
            return (tag: item.tag, count: item.count, percentile: percentile)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            headerSection

            Divider()
                .background(Color.white.opacity(0.15))
                .padding(.horizontal, 16)

            tagListSection
        }
        .frame(maxWidth: availableWidth, maxHeight: .infinity)
        .background(Color(hex: "#1C1C1E")) // Same as main timeline background
        .overlay(
            // Subtle separator line on the right edge
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 1),
            alignment: .trailing
        )
        .onAppear {
            // Cache tag list on appear
            cachedTagCounts = tagCounts

            // Set up Cmd+Z shortcut for undo
            NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "z" {
                    undoTagDeletion()
                    return nil // Consume the event
                }
                return event
            }
        }
        .onChange(of: appState.entries.count) { _ in
            // Only update cache when actual data changes
            cachedTagCounts = tagCounts
        }
        .onChange(of: calendarService.events.count) { _ in
            // Only update cache when actual data changes
            cachedTagCounts = tagCounts
        }
        .onChange(of: tagColorManager.knownTags) { _ in
            // Update cache when tags are added/removed
            cachedTagCounts = tagCounts
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerTitle

            if isAddingTag {
                newTagInputField
            }

            instructionsText
        }
        .padding(.horizontal, 24)
        .padding(.top, 28)
        .padding(.bottom, 20)
    }

    private var headerTitle: some View {
        HStack {
            if selectedTags.isEmpty {
                Text("Tags")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
            } else {
                Text("\(selectedTags.count) selected")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.blue)
            }

            Spacer()

            if !selectedTags.isEmpty {
                // Clear selection button
                Button(action: {
                    withAnimation {
                        selectedTags.removeAll()
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())

                // Bulk delete button
                Button(action: {
                    deleteSelectedTags()
                }) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.red)
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                Button(action: {
                    withAnimation {
                        isAddingTag = true
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color(hex: "#FFB84D"))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    private var newTagInputField: some View {
        HStack(spacing: 8) {
            TextField("New tag name", text: $newTagInput)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.05))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
                .onSubmit {
                    createNewTag()
                }

            Button(action: {
                isAddingTag = false
                newTagInput = ""
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    private var instructionsText: some View {
        Text("Drag tags to entries/events to assign them")
            .font(.system(size: 12))
            .foregroundColor(.secondary)
    }

    // MARK: - Tag List Section

    private var tagListSection: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 8) {
                if tagCounts.isEmpty {
                    emptyState
                } else {
                    tagList
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "tag")
                .font(.system(size: 40))
                .foregroundColor(.secondary.opacity(0.5))

            Text("No tags yet")
                .font(.system(size: 14))
                .foregroundColor(.secondary)

            Text("Click + to create your first tag")
                .font(.system(size: 12))
                .foregroundColor(.secondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }

    private var tagList: some View {
        FlowLayout(spacing: 12) {
            ForEach(cachedTagCounts, id: \.tag) { item in
                TagCloudChip(
                    tag: item.tag,
                    count: item.count,
                    tier: TagSizeTier(percentile: item.percentile),
                    color: tagColorManager.getColorForTag(item.tag) ?? .gray,
                    isSelected: selectedTags.contains(item.tag),
                    onDrop: { entryId, eventId in
                        handleDrop(entryId: entryId, eventId: eventId, tag: item.tag)
                    },
                    onDelete: {
                        deleteTag(item.tag)
                    },
                    onTap: { modifiers in
                        handleTagTap(item.tag, modifiers: modifiers)
                    },
                    onMouseDown: {
                        startDraggingTag(item.tag)
                    }
                )
                .environmentObject(appState)
                .id(item.tag) // Stable identity to prevent flickering
            }
        }
        .animation(nil, value: tagDragState.isDragging) // Disable animation during drag
    }

    private func startDraggingTag(_ tag: String) {
        // If tag is selected, drag all selected tags; otherwise just this tag
        let tagsToDrag = selectedTags.contains(tag) ? Array(selectedTags) : [tag]
        tagDragState.startDragging(tags: tagsToDrag)
    }

    private func handleTagTap(_ tag: String, modifiers: NSEvent.ModifierFlags) {
        if modifiers.contains(.command) {
            // Cmd+click: toggle selection
            withAnimation {
                if selectedTags.contains(tag) {
                    selectedTags.remove(tag)
                } else {
                    selectedTags.insert(tag)
                }
            }
        } else {
            // Regular click: clear selection
            if !selectedTags.isEmpty {
                withAnimation {
                    selectedTags.removeAll()
                }
            }
        }
    }

    private func deleteSelectedTags() {
        guard !selectedTags.isEmpty else { return }

        let tagsToDelete = Array(selectedTags)
        for tag in tagsToDelete {
            deleteTag(tag)
        }

        selectedTags.removeAll()
        print("🗑️ Deleted \(tagsToDelete.count) tags")
    }

    private func createNewTag() {
        let trimmed = newTagInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            isAddingTag = false
            newTagInput = ""
            return
        }

        // Register the tag in TagColorManager so it appears immediately
        tagColorManager.registerTag(trimmed)

        // Close the input
        isAddingTag = false
        newTagInput = ""

        print("✅ New tag '\(trimmed)' created and ready to use")
    }

    private func deleteTag(_ tag: String) {
        // Cancel any existing undo timer
        undoTimer?.invalidate()

        // Store the tag and affected items for undo
        let entriesWithTag = appState.entries.filter { $0.tags.contains(tag) }.map { $0.id }
        let eventsWithTag = calendarService.events.filter { event in
            SimpleEventDetailView.extractTags(from: event.notes).contains(tag)
        }.map { $0.id }

        deletedTag = tag
        deletedTagData = (entries: entriesWithTag, events: eventsWithTag)

        // Actually delete the tag from all entries and events
        performTagDeletion(tag, entries: entriesWithTag, events: eventsWithTag)

        // Set up undo timer (30 seconds)
        undoTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: false) { _ in
            // Clear undo data after timeout
            deletedTag = nil
            deletedTagData = nil
        }

        print("🗑️ Deleted tag '\(tag)' (Cmd+Z to undo within 30s)")
    }

    private func performTagDeletion(_ tag: String, entries: [String], events: [String]) {
        // Remove from entries
        for entryId in entries {
            if let entry = appState.entries.first(where: { $0.id == entryId }) {
                var updatedEntry = entry
                updatedEntry.tags.removeAll { $0 == tag }
                appState.updateEntry(updatedEntry)
            }
        }

        // Remove from events
        for eventId in events {
            if let event = calendarService.events.first(where: { $0.id == eventId }) {
                var tags = SimpleEventDetailView.extractTags(from: event.notes)
                tags.removeAll { $0 == tag }

                Task {
                    let toolService = ToolService()
                    let tagsString = tags.isEmpty ? "" : "[tags: \(tags.joined(separator: ", "))]"
                    let existingNotes = SimpleEventDetailView.removeTagsFromNotes(event.notes)
                    let newNotes = existingNotes.isEmpty ? tagsString : (tagsString.isEmpty ? existingNotes : "\(existingNotes)\n\(tagsString)")

                    do {
                        try await toolService.updateCalendarEvent(
                            eventId: eventId,
                            title: nil,
                            notes: newNotes,
                            startDate: nil
                        )
                        await MainActor.run {
                            CalendarService.shared.fetchEvents(for: event.startTime)
                        }
                    } catch {
                        print("❌ Failed to remove tag from event: \(error)")
                    }
                }
            }
        }

        // Remove from known tags
        tagColorManager.removeTag(tag)
    }

    func undoTagDeletion() {
        guard let tag = deletedTag,
              let data = deletedTagData else {
            print("⚠️ No tag deletion to undo")
            return
        }

        // Cancel the undo timer
        undoTimer?.invalidate()

        // Re-add tag to affected items
        for entryId in data.entries {
            if let entry = appState.entries.first(where: { $0.id == entryId }) {
                var updatedEntry = entry
                if !updatedEntry.tags.contains(tag) {
                    updatedEntry.tags.append(tag)
                    appState.updateEntry(updatedEntry)
                }
            }
        }

        for eventId in data.events {
            if let event = calendarService.events.first(where: { $0.id == eventId }) {
                var tags = SimpleEventDetailView.extractTags(from: event.notes)
                if !tags.contains(tag) {
                    tags.append(tag)

                    Task {
                        let toolService = ToolService()
                        let tagsString = "[tags: \(tags.joined(separator: ", "))]"
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
                                CalendarService.shared.fetchEvents(for: event.startTime)
                            }
                        } catch {
                            print("❌ Failed to restore tag to event: \(error)")
                        }
                    }
                }
            }
        }

        // Re-register the tag
        tagColorManager.registerTag(tag)

        // Clear undo data
        deletedTag = nil
        deletedTagData = nil

        print("↩️ Undone deletion of tag '\(tag)'")
    }

    private func handleDrop(entryId: String?, eventId: String?, tag: String) {
        // Ensure tag has a color assigned (this is safe - only mutates if needed)
        tagColorManager.ensureColorForTag(tag)

        if let entryId = entryId {
            // Add tag to entry
            if let entry = appState.entries.first(where: { $0.id == entryId }) {
                var updatedEntry = entry
                if !updatedEntry.tags.contains(tag) {
                    updatedEntry.tags.append(tag)
                    appState.updateEntry(updatedEntry)
                    print("✅ Added tag '\(tag)' to entry")
                }
            }
        } else if let eventId = eventId {
            // Add tag to event
            if let event = CalendarService.shared.events.first(where: { $0.id == eventId }) {
                var tags = SimpleEventDetailView.extractTags(from: event.notes)
                if !tags.contains(tag) {
                    tags.append(tag)

                    // Update event notes with new tags
                    Task {
                        let toolService = ToolService()
                        let tagsString = "[tags: \(tags.joined(separator: ", "))]"
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
                                CalendarService.shared.fetchEvents(for: Date())
                            }
                            print("✅ Added tag '\(tag)' to event")
                        } catch {
                            print("❌ Failed to add tag to event: \(error)")
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Tag Cloud Chip (with weighted sizing)

struct TagCloudChip: View {
    @EnvironmentObject var appState: AppState
    let tag: String
    let count: Int
    let tier: TagManagementPanel.TagSizeTier
    let color: Color
    let isSelected: Bool
    let onDrop: (String?, String?) -> Void
    let onDelete: () -> Void
    let onTap: (NSEvent.ModifierFlags) -> Void
    let onMouseDown: () -> Void

    @State private var isTargeted: Bool = false
    @State private var isHovering: Bool = false
    @State private var mouseDownLocation: CGPoint? = nil

    private var chipBackground: some View {
        let fillColor: Color
        if isSelected {
            fillColor = color.opacity(0.8)
        } else if isTargeted {
            fillColor = color.opacity(0.6)
        } else if isHovering {
            fillColor = color.opacity(0.5)
        } else {
            fillColor = color.opacity(0.4)
        }
        return Capsule().fill(fillColor)
    }

    private var chipStroke: some View {
        let strokeColor: Color
        let strokeWidth: CGFloat
        if isSelected {
            strokeColor = Color.white.opacity(0.8)
            strokeWidth = 2
        } else if isTargeted {
            strokeColor = Color.white.opacity(0.6)
            strokeWidth = 1.5
        } else if isHovering {
            strokeColor = Color.white.opacity(0.4)
            strokeWidth = 1
        } else {
            strokeColor = Color.white.opacity(0.2)
            strokeWidth = 1
        }
        return Capsule().stroke(strokeColor, lineWidth: strokeWidth)
    }

    var body: some View {
        HStack(spacing: 6) {
            // Tag name with count in parentheses
            Text("#\(tag)")
                .font(.system(size: tier.fontSize, weight: tier.fontWeight))
                .foregroundColor(.white)

            Text("(\(count))")
                .font(.system(size: tier.fontSize - 2, weight: isHovering ? .semibold : .regular))
                .foregroundColor(.white.opacity(0.8))

            // Delete button on hover (always reserve space to prevent layout jump)
            Button(action: {
                onDelete()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: tier.fontSize - 2))
                    .foregroundColor(.white.opacity(0.6))
            }
            .buttonStyle(PlainButtonStyle())
            .opacity(isHovering ? 1.0 : 0.0) // Hidden but still takes up space
        }
        .padding(.horizontal, tier.padding.horizontal)
        .padding(.vertical, tier.padding.vertical)
        .background(chipBackground)
        .overlay(chipStroke)
        .shadow(
            color: isSelected ? color.opacity(0.4) : (isHovering ? Color.black.opacity(0.2) : Color.black.opacity(0.1)),
            radius: isSelected ? 8 : (isHovering ? 4 : 2),
            x: 0,
            y: isSelected ? 4 : (isHovering ? 2 : 1)
        )
        .onHover { hovering in
            if !TagDragState.shared.isDragging {
                withAnimation(.easeInOut(duration: 0.15)) {
                    isHovering = hovering
                }
            }
        }
        .gesture(
            DragGesture(minimumDistance: 3)
                .onChanged { _ in
                    // Only start dragging if we actually dragged a bit and haven't started yet
                    if !TagDragState.shared.isDragging {
                        onMouseDown()
                        // Mouse tracking is now handled by TagDragState's global monitor
                    }
                }
        )
        .simultaneousGesture(
            TapGesture().onEnded {
                if let event = NSApp.currentEvent {
                    // Regular click - handle tap (only if not in drag mode)
                    if !TagDragState.shared.isDragging {
                        onTap(event.modifierFlags)
                    }
                }
            }
        )
        .contextMenu {
            Button(action: {
                onDelete()
            }) {
                Label("Delete Tag", systemImage: "trash")
            }
        }
        .onDrop(of: [.text], isTargeted: $isTargeted) { providers in
            handleDrop(providers: providers)
            return true
        }
        .animation(TagDragState.shared.isDragging ? nil : .easeInOut(duration: 0.2), value: isTargeted)
        .animation(TagDragState.shared.isDragging ? nil : .easeInOut(duration: 0.15), value: isHovering)
        .animation(TagDragState.shared.isDragging ? nil : .easeInOut(duration: 0.15), value: isSelected)
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }

        provider.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { data, error in
            if let data = data as? Data,
               let text = String(data: data, encoding: .utf8) {

                DispatchQueue.main.async {
                    // Parse the dropped data (format: "entry:ID" or "event:EventID")
                    if text.hasPrefix("entry:") {
                        let entryId = text.replacingOccurrences(of: "entry:", with: "")
                        onDrop(entryId, nil)
                    } else if text.hasPrefix("event:") {
                        let eventId = text.replacingOccurrences(of: "event:", with: "")
                        onDrop(nil, eventId)
                    }
                }
            }
        }

        return true
    }
}

import SwiftUI
import UniformTypeIdentifiers

// MARK: - Tag Management Panel
// Drag entries/events to tags to assign them, easy tag creation

struct TagManagementPanel: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var tagColorManager = TagColorManager.shared
    @StateObject private var tagStore = TagStore.shared
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

    // Calculate scale factor based on available width
    private var scaleFactor: CGFloat {
        guard let width = availableWidth else { return 1.0 }

        // Scale tags down on smaller screens
        if width >= 300 {
            return 1.0 // Full size for large panels
        } else if width >= 220 {
            return 0.85 // Slightly smaller for medium panels
        } else if width >= 160 {
            return 0.7 // Smaller for small panels
        } else {
            return 0.6 // Smallest for very constrained panels
        }
    }

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

        func fontSize(scale: CGFloat) -> CGFloat {
            let baseSize: CGFloat
            switch self {
            case .extraLarge: baseSize = 28
            case .large: baseSize = 24
            case .medium: baseSize = 20
            case .small: baseSize = 18
            case .extraSmall: baseSize = 16
            }
            return baseSize * scale
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

        func padding(scale: CGFloat) -> (horizontal: CGFloat, vertical: CGFloat) {
            let basePadding: (horizontal: CGFloat, vertical: CGFloat)
            switch self {
            case .extraLarge: basePadding = (20, 12)
            case .large: basePadding = (18, 10)
            case .medium: basePadding = (16, 9)
            case .small: basePadding = (14, 8)
            case .extraSmall: basePadding = (12, 7)
            }
            return (basePadding.horizontal * scale, basePadding.vertical * scale)
        }
    }

    // Get all unique tags with their counts and percentiles from TagStore (universal, not date-dependent)
    private var tagCounts: [(tag: String, count: Int, percentile: Double)] {
        let counts = tagStore.tagCounts

        // Include known tags with 0 count from TagColorManager
        var allCounts = counts
        for knownTag in tagColorManager.getAllKnownTags() {
            if allCounts[knownTag] == nil {
                allCounts[knownTag] = 0
            }
        }

        // Sort by count descending and filter out tags with 0 count
        let sorted = allCounts
            .filter { $0.value > 0 }  // Only show tags that actually have entries/events
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

            tagListSection
        }
        .frame(maxWidth: availableWidth, maxHeight: .infinity)
        .background(Color(hex: "#1C1C1E")) // Same as main timeline background
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
        .onChange(of: tagStore.tagCounts.count) { _ in
            // TagStore updates automatically when entries or events change
            cachedTagCounts = tagCounts
        }
        .onChange(of: tagColorManager.knownTags) { _ in
            // Update cache when new tags are registered
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
        HStack(spacing: 12) {
            if selectedTags.isEmpty {
                Text("Tags")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)

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
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, 24)
        }
    }

    // Calculate horizontal padding based on available width
    private var horizontalPadding: CGFloat {
        guard let width = availableWidth else { return 20 }

        // Add more padding on smaller screens to prevent tags from touching edges
        if width >= 280 {
            return 20
        } else if width >= 200 {
            return 16
        } else if width >= 160 {
            return 12
        } else {
            return 8
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
        FlowLayout(spacing: 12 * scaleFactor) {
            ForEach(cachedTagCounts, id: \.tag) { item in
                TagCloudChip(
                    tag: item.tag,
                    count: item.count,
                    tier: TagSizeTier(percentile: item.percentile),
                    scaleFactor: scaleFactor,
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

        // Fetch ALL events (same range as TagStore) to find events with this tag
        Task {
            let calendar = Calendar.current
            let now = Date()
            let startDate = calendar.date(byAdding: .year, value: -1, to: now) ?? now
            let endDate = calendar.date(byAdding: .year, value: 1, to: now) ?? now

            let allEvents = await calendarService.fetchAllEvents(from: startDate, to: endDate)
            let eventsWithTag = allEvents.filter { event in
                SimpleEventDetailView.extractTags(from: event.notes).contains(tag)
            }.map { $0.id }

            await MainActor.run {
                print("🔍 Deleting tag '\(tag)':")
                print("   - Found \(entriesWithTag.count) entries with tag")
                print("   - Found \(eventsWithTag.count) events with tag (searched \(allEvents.count) total events)")

                deletedTag = tag
                deletedTagData = (entries: entriesWithTag, events: eventsWithTag)

                // Actually delete the tag from all entries and events (pass allEvents for lookup)
                performTagDeletion(tag, entries: entriesWithTag, events: eventsWithTag, allEvents: allEvents)

                // Set up undo timer (30 seconds)
                undoTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: false) { _ in
                    // Clear undo data after timeout
                    deletedTag = nil
                    deletedTagData = nil
                }

                print("🗑️ Deleted tag '\(tag)' from \(entriesWithTag.count) entries and \(eventsWithTag.count) events (Cmd+Z to undo within 30s)")
            }
        }
    }

    private func performTagDeletion(_ tag: String, entries: [String], events: [String], allEvents: [CalendarEvent]) {
        // Remove from entries
        for entryId in entries {
            if let entry = appState.entries.first(where: { $0.id == entryId }) {
                var updatedEntry = entry
                updatedEntry.tags.removeAll { $0 == tag }
                appState.updateEntry(updatedEntry)
            }
        }

        // Remove from events
        Task {
            // Process all event updates
            for eventId in events {
                if let event = allEvents.first(where: { $0.id == eventId }) {
                    var tags = SimpleEventDetailView.extractTags(from: event.notes)
                    print("🔍 Event '\(event.title)' before deletion - tags: \(tags)")
                    tags.removeAll { $0 == tag }
                    print("🔍 Event '\(event.title)' after deletion - tags: \(tags)")

                    let toolService = ToolService()
                    let tagsString = tags.isEmpty ? "" : "[tags: \(tags.joined(separator: ", "))]"
                    let existingNotes = SimpleEventDetailView.removeTagsFromNotes(event.notes)
                    let newNotes = existingNotes.isEmpty ? tagsString : (tagsString.isEmpty ? existingNotes : "\(existingNotes)\n\(tagsString)")

                    print("🔍 Updating event notes from '\(event.notes ?? "")' to '\(newNotes)'")

                    do {
                        try await toolService.updateCalendarEvent(
                            eventId: eventId,
                            title: nil,
                            notes: newNotes,
                            startDate: nil
                        )
                        print("✅ Successfully updated event '\(event.title)' to remove tag '\(tag)'")
                    } catch {
                        print("❌ Failed to remove tag '\(tag)' from event '\(event.title)': \(error)")
                    }
                }
            }

            // After all event updates complete, refresh TagStore
            await MainActor.run {
                // Give calendar service a longer moment to process all calendar updates
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    tagStore.refreshAllTags()
                    // Also refresh today's events in case user is viewing today
                    CalendarService.shared.fetchEvents(for: Date())
                    print("✅ TagStore refreshed after tag deletion (delayed)")
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
    let scaleFactor: CGFloat
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
        let fontSize = tier.fontSize(scale: scaleFactor)
        let padding = tier.padding(scale: scaleFactor)

        HStack(spacing: 6 * scaleFactor) {
            // Tag name with count in parentheses
            Text("#\(tag)")
                .font(.system(size: fontSize, weight: tier.fontWeight))
                .foregroundColor(.white)

            Text("(\(count))")
                .font(.system(size: fontSize - 2, weight: isHovering ? .semibold : .regular))
                .foregroundColor(.white.opacity(0.8))

            // Delete button on hover (always reserve space to prevent layout jump)
            Button(action: {
                onDelete()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: fontSize - 2))
                    .foregroundColor(.white.opacity(0.6))
            }
            .buttonStyle(PlainButtonStyle())
            .opacity(isHovering ? 1.0 : 0.0) // Hidden but still takes up space
        }
        .padding(.horizontal, padding.horizontal)
        .padding(.vertical, padding.vertical)
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

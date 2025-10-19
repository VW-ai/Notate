import SwiftUI

/// List page - view and organize both entries and events with tri-pane Apple Notes-style layout
struct ListView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var tagStore = TagStore.shared
    @StateObject private var calendarService = CalendarService.shared
    private let tagColorManager = TagColorManager.shared

    // UI State
    @State private var searchText: String = ""
    @State private var selectedCollection: CollectionType? = .allNotes  // nil means nothing selected
    @State private var selectedItemID: String? = nil  // Can be entry or event ID
    @State private var selectedItemType: ItemType = .entry
    @State private var sortBy: SortOption = .date
    @State private var sortAscending: Bool = false
    @State private var viewMode: ViewMode = .notes  // Notes, Both, or Events

    enum ViewMode: String, CaseIterable {
        case notes = "Notes"
        case both = "Both"
        case events = "Events"
    }

    enum ItemType {
        case entry
        case event
    }

    enum CollectionType: Equatable {
        case allNotes
        case pinned
        case recentlyEdited
        case tag(String)
    }

    enum SortOption: String, CaseIterable {
        case date = "Date"
        case title = "Title"
        case tag = "Tag"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Mode selector at top
            modeSelector
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color(hex: "#1C1C1E"))

            Divider()
                .background(Color(hex: "#3A3A3C"))

            // Three-pane layout
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    // Left Pane: Collections & Filters
                    collectionsPane
                        .frame(width: geometry.size.width * 0.20)
                        .background(Color(hex: "#2C2C2E"))

                    Divider()
                        .background(Color(hex: "#3A3A3C"))

                    // Middle Pane: Note Previews
                    notePreviewsPane
                        .frame(width: geometry.size.width * 0.30)
                        .background(Color(hex: "#1C1C1E"))

                    Divider()
                        .background(Color(hex: "#3A3A3C"))

                    // Right Pane: Detail View
                    detailPane
                        .frame(maxWidth: .infinity)
                        .background(Color(hex: "#1C1C1E"))
                }
            }
        }
        .background(Color(hex: "#1C1C1E"))
    }

    // MARK: - Mode Selector

    private var modeSelector: some View {
        HStack(spacing: 0) {
            Spacer()
            HStack(spacing: 16) {
                ForEach(ViewMode.allCases, id: \.self) { mode in
                    modeButton(mode: mode)
                }
            }
            Spacer()
        }
    }

    private func modeButton(mode: ViewMode) -> some View {
        let isSelected = viewMode == mode

        // Different styling for "Both" - more gradient/special
        let isBoth = mode == .both
        let textColor: Color = {
            if isSelected {
                return isBoth ? Color(hex: "#E0E0E0") : Color(hex: "#FFD93D")
            } else {
                return .secondary
            }
        }()

        let backgroundColor: Color = {
            if isSelected && isBoth {
                return Color(hex: "#FFD93D").opacity(0.2)
            } else if isSelected {
                return Color(hex: "#FFD93D").opacity(0.15)
            } else {
                return Color.clear
            }
        }()

        return Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewMode = mode
                // Clear selection when changing modes
                selectedItemID = nil
            }
        }) {
            Text(mode.rawValue)
                .font(.system(size: isSelected ? 16 : 14, weight: isSelected ? (isBoth ? .bold : .semibold) : .medium))
                .foregroundColor(textColor)
                .padding(.horizontal, isSelected ? 20 : 16)
                .padding(.vertical, isSelected ? 10 : 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(backgroundColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isSelected && isBoth ? Color(hex: "#FFD93D").opacity(0.3) : Color.clear, lineWidth: 1)
                        )
                )
                .scaleEffect(isSelected ? 1.05 : 1.0)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Collections Pane

    private var collectionsPane: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Text("List")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.primary)
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 12)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Collections section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Collections")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 4)

                        collectionButton(
                            icon: "tray.fill",
                            title: "All Notes",
                            count: appState.entries.count,  // Always show total, not filtered
                            collection: .allNotes
                        )

                        collectionButton(
                            icon: "pin.fill",
                            title: "Pinned",
                            count: allPinnedEntries.count,  // Total pinned, not filtered
                            collection: .pinned
                        )

                        collectionButton(
                            icon: "clock.fill",
                            title: "Recently Edited",
                            count: allRecentlyEditedEntries.count,  // Total recent, not filtered
                            collection: .recentlyEdited
                        )
                    }

                    Divider()
                        .background(Color(hex: "#3A3A3C"))
                        .padding(.horizontal, 16)

                    // Tags section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tags")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 4)

                        ForEach(tagStore.getTopTags(limit: 20), id: \.self) { tag in
                            tagFilterButton(tag: tag)
                        }

                        // Add tag filter
                        Button(action: {
                            // TODO: Show tag picker
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)

                                Text("Add tag filter")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)

                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 12)
            }
        }
    }

    private func collectionButton(icon: String, title: String, count: Int, collection: CollectionType) -> some View {
        Button(action: {
            // Toggle selection: click same item to deselect
            if selectedCollection == collection {
                selectedCollection = nil
                selectedItemID = nil  // Clear preview
            } else {
                selectedCollection = collection
                selectedItemID = nil  // Clear preview when switching
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(selectedCollection == collection ? Color(hex: "#FF6B35") : .secondary)
                    .frame(width: 20)

                Text(title)
                    .font(.system(size: 13))
                    .foregroundColor(selectedCollection == collection ? .primary : .secondary)

                Spacer()

                Text("\(count)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(selectedCollection == collection ? Color(hex: "#FF6B35").opacity(0.1) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func tagFilterButton(tag: String) -> some View {
        let tagColor = tagColorManager.colorForTag(tag)
        let isSelected = selectedCollection == .tag(tag)
        let tagCount = getTagCount(for: tag, mode: viewMode)

        return Button(action: {
            // Toggle selection: click same tag to deselect
            if isSelected {
                selectedCollection = nil
                selectedItemID = nil  // Clear preview
            } else {
                selectedCollection = .tag(tag)
                selectedItemID = nil  // Clear preview when switching
            }
        }) {
            HStack(spacing: 8) {
                Circle()
                    .fill(tagColor)
                    .frame(width: 8, height: 8)

                Text("#\(tag)")
                    .font(.system(size: 13))
                    .foregroundColor(isSelected ? .primary : .secondary)

                Spacer()

                Text("\(tagCount)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(isSelected ? tagColor.opacity(0.1) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Note Previews Pane

    private var notePreviewsPane: some View {
        VStack(spacing: 0) {
            // Search and sort bar
            HStack(spacing: 12) {
                // Search field
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)

                    TextField("Search...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(hex: "#2C2C2E"))
                )

                // Sort picker
                Menu {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Button(action: {
                            if sortBy == option {
                                sortAscending.toggle()
                            } else {
                                sortBy = option
                                sortAscending = false
                            }
                        }) {
                            HStack {
                                Text(option.rawValue)
                                if sortBy == option {
                                    Image(systemName: sortAscending ? "arrow.up" : "arrow.down")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text("Sort:")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        Text(sortBy.rawValue)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.primary)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(hex: "#2C2C2E"))
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(hex: "#1C1C1E"))

            Divider()
                .background(Color(hex: "#3A3A3C"))

            // Note/Event list
            ScrollView {
                LazyVStack(spacing: 1) {
                    // Show entries if mode is Notes or Both
                    if viewMode == .notes || viewMode == .both {
                        ForEach(sortedAndFilteredEntries, id: \.id) { entry in
                            notePreviewCard(entry: entry)
                        }
                    }

                    // Show events if mode is Events or Both
                    if viewMode == .events || viewMode == .both {
                        ForEach(sortedAndFilteredEvents, id: \.id) { event in
                            eventPreviewCard(event: event)
                        }
                    }
                }
            }
        }
    }

    private func notePreviewCard(entry: Entry) -> some View {
        let isSelected = selectedItemID == entry.id

        return Button(action: {
            selectedItemID = entry.id
            selectedItemType = .entry
        }) {
            HStack(spacing: 0) {
                // Bright blue vertical line for notes
                Rectangle()
                    .fill(Color(hex: "#66D9FF"))  // Bright, light blue (almost white-blue)
                    .frame(width: 4)

                VStack(alignment: .leading, spacing: 6) {
                    // Header: timestamp and primary tag
                    HStack {
                        Text(formattedDate(entry.createdAt))
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)

                        Spacer()

                        if let firstTag = entry.tags.first {
                            let tagColor = tagColorManager.colorForTag(firstTag)
                            HStack(spacing: 4) {
                                Text("🏷")
                                    .font(.system(size: 10))
                                Text(firstTag)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(tagColor)
                            }
                        }
                    }

                    // Title/snippet
                    Text(entry.content.prefix(60))
                        .font(.system(size: 13))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            .background(isSelected ? Color(hex: "#2C2C2E") : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func eventPreviewCard(event: CalendarEvent) -> some View {
        let isSelected = selectedItemID == event.id
        let eventTags = SimpleEventDetailView.extractTags(from: event.notes)

        return Button(action: {
            selectedItemID = event.id
            selectedItemType = .event
        }) {
            HStack(spacing: 0) {
                // Bright green vertical line for events
                Rectangle()
                    .fill(Color(hex: "#66FF99"))  // Bright, light green
                    .frame(width: 4)

                VStack(alignment: .leading, spacing: 6) {
                    // Header: timestamp and primary tag
                    HStack {
                        Text(formattedDate(event.startTime))
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)

                        Spacer()

                        if let firstTag = eventTags.first {
                            let tagColor = tagColorManager.colorForTag(firstTag)
                            HStack(spacing: 4) {
                                Text("📅")
                                    .font(.system(size: 10))
                                Text(firstTag)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(tagColor)
                            }
                        }
                    }

                    // Title
                    Text(event.title)
                        .font(.system(size: 13))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            .background(isSelected ? Color(hex: "#2C2C2E") : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Detail Pane

    private var detailPane: some View {
        Group {
            if let itemID = selectedItemID {
                if selectedItemType == .entry,
                   let entry = appState.entries.first(where: { $0.id == itemID }) {
                    ScrollView {
                        SimpleEntryDetailView(entry: entry)
                            .padding(20)
                    }
                } else if selectedItemType == .event,
                          let event = calendarService.events.first(where: { $0.id == itemID }) {
                    ScrollView {
                        SimpleEventDetailView(event: event)
                            .padding(20)
                    }
                } else {
                    emptyStateView
                }
            } else {
                emptyStateView
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.5))

            Text("Select an item to view details")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Computed Properties

    // Unfiltered counts for collection badges
    private var allPinnedEntries: [Entry] {
        appState.entries.filter { entry in
            if let metadata = entry.metadata,
               let pinned = metadata["pinned"]?.wrappedValue as? Bool {
                return pinned
            }
            return false
        }
    }

    private var allRecentlyEditedEntries: [Entry] {
        let calendar = Calendar.current
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: Date()) ?? Date()
        return appState.entries.filter { $0.createdAt >= twoDaysAgo }
    }

    // Filtered by search only (not by selected collection)
    private var searchFilteredEntries: [Entry] {
        var entries = appState.entries

        // Apply search filter
        if !searchText.isEmpty {
            entries = entries.filter { entry in
                entry.content.localizedCaseInsensitiveContains(searchText) ||
                entry.tags.contains(where: { $0.localizedCaseInsensitiveContains(searchText) })
            }
        }

        return entries
    }

    private var sortedAndFilteredEntries: [Entry] {
        // Start with search-filtered entries
        var entries = searchFilteredEntries

        // Apply collection filter (single selection)
        if let collection = selectedCollection {
            switch collection {
            case .allNotes:
                break // Show all (already search-filtered)
            case .pinned:
                entries = entries.filter { entry in
                    if let metadata = entry.metadata,
                       let pinned = metadata["pinned"]?.wrappedValue as? Bool {
                        return pinned
                    }
                    return false
                }
            case .recentlyEdited:
                let calendar = Calendar.current
                let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: Date()) ?? Date()
                entries = entries.filter { $0.createdAt >= twoDaysAgo }
            case .tag(let tag):
                entries = entries.filter { $0.tags.contains(tag) }
            }
        } else {
            // Nothing selected = show nothing
            entries = []
        }

        // Apply sorting
        switch sortBy {
        case .date:
            entries.sort { sortAscending ? $0.createdAt < $1.createdAt : $0.createdAt > $1.createdAt }
        case .title:
            entries.sort { sortAscending ? $0.content < $1.content : $0.content > $1.content }
        case .tag:
            entries.sort { sortAscending ? ($0.tags.first ?? "") < ($1.tags.first ?? "") : ($0.tags.first ?? "") > ($1.tags.first ?? "") }
        }

        return entries
    }

    private var sortedAndFilteredEvents: [CalendarEvent] {
        // Start with all calendar events
        var events = calendarService.events

        // Apply search filter
        if !searchText.isEmpty {
            events = events.filter { event in
                event.title.localizedCaseInsensitiveContains(searchText) ||
                SimpleEventDetailView.extractTags(from: event.notes).contains(where: { $0.localizedCaseInsensitiveContains(searchText) })
            }
        }

        // Apply collection filter (single selection)
        if let collection = selectedCollection {
            switch collection {
            case .allNotes:
                break // Show all (already search-filtered)
            case .pinned:
                // Events don't have pinned status for now
                events = []
            case .recentlyEdited:
                let calendar = Calendar.current
                let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: Date()) ?? Date()
                events = events.filter { $0.startTime >= twoDaysAgo }
            case .tag(let tag):
                events = events.filter { event in
                    SimpleEventDetailView.extractTags(from: event.notes).contains(tag)
                }
            }
        } else {
            // Nothing selected = show nothing
            events = []
        }

        // Apply sorting
        switch sortBy {
        case .date:
            events.sort { sortAscending ? $0.startTime < $1.startTime : $0.startTime > $1.startTime }
        case .title:
            events.sort { sortAscending ? $0.title < $1.title : $0.title > $1.title }
        case .tag:
            let getFirstTag = { (event: CalendarEvent) -> String in
                SimpleEventDetailView.extractTags(from: event.notes).first ?? ""
            }
            events.sort { sortAscending ? getFirstTag($0) < getFirstTag($1) : getFirstTag($0) > getFirstTag($1) }
        }

        return events
    }

    // MARK: - Helper Functions

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd · h:mm a"
        return formatter.string(from: date)
    }

    /// Get tag count based on current view mode
    private func getTagCount(for tag: String, mode: ViewMode) -> Int {
        switch mode {
        case .notes:
            // Count only entries with this tag
            return appState.entries.filter { $0.tags.contains(tag) }.count
        case .events:
            // Count only events with this tag
            let allEvents = calendarService.events
            return allEvents.filter { event in
                SimpleEventDetailView.extractTags(from: event.notes).contains(tag)
            }.count
        case .both:
            // Use TagStore which combines both
            return tagStore.tagCounts[tag] ?? 0
        }
    }
}

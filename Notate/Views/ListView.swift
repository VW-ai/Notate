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
    @State private var selectedTimeRange: TimeRange = .allTime
    @State private var allCalendarEvents: [CalendarEvent] = []  // Cached all events

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
    }

    enum TimeRange: Equatable {
        case allTime
        case month(Int)  // 1-12 for Jan-Dec

        var displayName: String {
            switch self {
            case .allTime:
                return "ALL TIME"
            case .month(let month):
                let formatter = DateFormatter()
                return formatter.monthSymbols[month - 1].uppercased()
            }
        }
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

            // Time range selector
            timeRangeSelector
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
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
        .onAppear {
            fetchAllCalendarEvents()
        }
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
        let isBoth = mode == .both

        // Match date selector styling
        let backgroundColor: Color = {
            if isSelected {
                return Color(hex: "#FFD60A") // Same bright yellow as date selector
            } else {
                return Color(hex: "#3A3A3C") // Default gray
            }
        }()

        let textColor: Color = {
            if isSelected {
                return Color(hex: "#1C1C1E") // Dark text on yellow (like date selector)
            } else {
                return .secondary
            }
        }()

        return Button(action: {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                viewMode = mode
                // Clear selection when changing modes
                selectedItemID = nil
            }
        }) {
            Text(mode.rawValue)
                .font(.system(size: isSelected ? 18 : 14, weight: isSelected ? .bold : .semibold))
                .foregroundColor(textColor)
                .frame(minWidth: 80)
                .frame(height: isSelected ? 56 : 48)  // Match date button heights
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(backgroundColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isSelected && isBoth ? Color(hex: "#FFD60A").opacity(0.5) : Color.clear, lineWidth: 2)
                        )
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Time Range Selector

    private var timeRangeSelector: some View {
        VStack(spacing: 10) {
            // Top row: 5 months with ALL TIME in center
            HStack(spacing: 12) {
                Spacer()
                timeRangeButton(for: .month(1))  // January
                timeRangeButton(for: .month(2))  // February
                timeRangeButton(for: .allTime, isAllTime: true)  // ALL TIME (bigger)
                timeRangeButton(for: .month(3))  // March
                timeRangeButton(for: .month(4))  // April
                Spacer()
            }

            // Bottom row: 7 months
            HStack(spacing: 12) {
                Spacer()
                ForEach(5...11, id: \.self) { month in
                    timeRangeButton(for: .month(month))
                }
                timeRangeButton(for: .month(12))  // December
                Spacer()
            }
        }
    }

    private func timeRangeButton(for range: TimeRange, isAllTime: Bool = false) -> some View {
        let isSelected = selectedTimeRange == range
        let size: CGFloat = isAllTime ? 56 : 44  // ALL TIME is bigger

        let backgroundColor: Color = {
            if isSelected {
                return Color(hex: "#FFD60A")
            } else {
                return Color(hex: "#3A3A3C")
            }
        }()

        let textColor: Color = {
            if isSelected {
                return Color(hex: "#1C1C1E")
            } else {
                return .secondary
            }
        }()

        return Button(action: {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                selectedTimeRange = range
                selectedItemID = nil  // Clear selection when changing time range
            }
        }) {
            Text(range.displayName.prefix(3))  // Show first 3 letters (JAN, FEB, ALL)
                .font(.system(size: isAllTime ? 10 : 9, weight: isSelected ? .bold : .semibold))
                .foregroundColor(textColor)
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(backgroundColor)
                )
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
                            title: "All",
                            count: getAllCount(),  // Mode-aware count
                            collection: .allNotes
                        )

                        collectionButton(
                            icon: "pin.fill",
                            title: "Pinned",
                            count: allPinnedEntries.count,  // TODO: Implement pin functionality
                            collection: .pinned
                        )

                        collectionButton(
                            icon: "clock.fill",
                            title: "Recent",
                            count: getRecentCount(),  // Mode-aware count
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
                    if viewMode == .both {
                        // Both mode: merge and sort entries and events together
                        ForEach(mergedAndSortedItems, id: \.id) { item in
                            if item.isEntry, let entry = item.entry {
                                notePreviewCard(entry: entry)
                            } else if let event = item.event {
                                eventPreviewCard(event: event)
                            }
                        }
                    } else {
                        // Notes or Events mode: show separately
                        if viewMode == .notes {
                            ForEach(sortedAndFilteredEntries, id: \.id) { entry in
                                notePreviewCard(entry: entry)
                            }
                        } else if viewMode == .events {
                            ForEach(sortedAndFilteredEvents, id: \.id) { event in
                                eventPreviewCard(event: event)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Unified Item for Both Mode

    private struct UnifiedItem: Identifiable {
        let id: String
        let date: Date
        let isEntry: Bool
        let entry: Entry?
        let event: CalendarEvent?

        init(entry: Entry) {
            self.id = entry.id
            self.date = entry.createdAt
            self.isEntry = true
            self.entry = entry
            self.event = nil
        }

        init(event: CalendarEvent) {
            self.id = event.id
            self.date = event.startTime
            self.isEntry = false
            self.entry = nil
            self.event = event
        }
    }

    private var mergedAndSortedItems: [UnifiedItem] {
        var items: [UnifiedItem] = []

        // Add entries
        items.append(contentsOf: sortedAndFilteredEntries.map { UnifiedItem(entry: $0) })

        // Add events
        items.append(contentsOf: sortedAndFilteredEvents.map { UnifiedItem(event: $0) })

        // Sort by date
        items.sort { sortAscending ? $0.date < $1.date : $0.date > $1.date }

        return items
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
                          let event = allCalendarEvents.first(where: { $0.id == itemID }) {
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

        // Apply time range filter
        entries = filterByTimeRange(entries: entries)

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

        // Apply sorting (only date now)
        entries.sort { sortAscending ? $0.createdAt < $1.createdAt : $0.createdAt > $1.createdAt }

        return entries
    }

    private var sortedAndFilteredEvents: [CalendarEvent] {
        // Start with all calendar events (from cache)
        var events = allCalendarEvents

        // Apply time range filter
        events = filterByTimeRange(events: events)

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

        // Apply sorting (only date now)
        events.sort { sortAscending ? $0.startTime < $1.startTime : $0.startTime > $1.startTime }

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

    /// Get "All" count based on current view mode
    private func getAllCount() -> Int {
        switch viewMode {
        case .notes:
            return appState.entries.count
        case .events:
            return calendarService.events.count
        case .both:
            return appState.entries.count + calendarService.events.count
        }
    }

    /// Get "Recent" count based on current view mode
    private func getRecentCount() -> Int {
        let calendar = Calendar.current
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: Date()) ?? Date()

        switch viewMode {
        case .notes:
            return appState.entries.filter { $0.createdAt >= twoDaysAgo }.count
        case .events:
            return calendarService.events.filter { $0.startTime >= twoDaysAgo }.count
        case .both:
            let recentEntries = appState.entries.filter { $0.createdAt >= twoDaysAgo }.count
            let recentEvents = calendarService.events.filter { $0.startTime >= twoDaysAgo }.count
            return recentEntries + recentEvents
        }
    }

    /// Fetch all calendar events from 2-year range
    private func fetchAllCalendarEvents() {
        Task {
            let calendar = Calendar.current
            let now = Date()
            let startDate = calendar.date(byAdding: .year, value: -1, to: now) ?? now
            let endDate = calendar.date(byAdding: .year, value: 1, to: now) ?? now

            let events = await calendarService.fetchAllEvents(from: startDate, to: endDate)
            await MainActor.run {
                allCalendarEvents = events
                print("📅 Loaded \(events.count) calendar events for List page")
            }
        }
    }

    /// Filter entries by selected time range
    private func filterByTimeRange(entries: [Entry]) -> [Entry] {
        switch selectedTimeRange {
        case .allTime:
            return entries
        case .month(let month):
            let calendar = Calendar.current
            let currentYear = calendar.component(.year, from: Date())
            return entries.filter { entry in
                let entryMonth = calendar.component(.month, from: entry.createdAt)
                let entryYear = calendar.component(.year, from: entry.createdAt)
                return entryMonth == month && entryYear == currentYear
            }
        }
    }

    /// Filter events by selected time range
    private func filterByTimeRange(events: [CalendarEvent]) -> [CalendarEvent] {
        switch selectedTimeRange {
        case .allTime:
            return events
        case .month(let month):
            let calendar = Calendar.current
            let currentYear = calendar.component(.year, from: Date())
            return events.filter { event in
                let eventMonth = calendar.component(.month, from: event.startTime)
                let eventYear = calendar.component(.year, from: event.startTime)
                return eventMonth == month && eventYear == currentYear
            }
        }
    }
}

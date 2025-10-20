import SwiftUI

/// List page - view and organize both entries and events with tri-pane Apple Notes-style layout
struct ListView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var tagStore = TagStore.shared
    @StateObject private var calendarService = CalendarService.shared
    private let tagColorManager = TagColorManager.shared
    private let itemColorManager = ItemColorManager.shared

    // UI State
    @State private var searchText: String = ""
    @State private var selectedCollection: CollectionType? = .allNotes  // nil means nothing selected
    @State private var selectedItemID: String? = nil  // Can be entry or event ID
    @State private var selectedItemType: ItemType = .entry
    @State private var sortBy: SortOption = .date
    @State private var sortAscending: Bool = false
    @State private var viewMode: ViewMode = .notes  // Notes, Both, or Events
    @State private var selectedTimeRange: TimeRange = .allTime
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
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
            // Top spacer to match Timeline page
            Spacer()
                .frame(height: 80)
                .background(Color(hex: "#1C1C1E"))

            // Horizontal layout: [years] [modes] [months]
            HStack(spacing: 20) {
                // Year selector (left)
                yearSelector
                    .frame(maxWidth: .infinity)

                // Mode selector (center)
                modeSelector
                    .frame(maxWidth: .infinity)

                // Time range selector (right - months)
                timeRangeSelector
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(hex: "#1C1C1E"))

            // Three-pane layout
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    // Left Pane: Collections & Filters
                    collectionsPane
                        .frame(width: geometry.size.width * 0.20)
                        .background(Color(hex: "#1C1C1E"))

                    // Middle Pane: Note Previews
                    notePreviewsPane
                        .frame(width: geometry.size.width * 0.30)
                        .background(Color(hex: "#1C1C1E"))

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
        HStack(spacing: 16) {
            ForEach(ViewMode.allCases, id: \.self) { mode in
                modeButton(mode: mode)
            }
        }
    }

    private func modeButton(mode: ViewMode) -> some View {
        let isSelected = viewMode == mode
        let isBoth = mode == .both

        // Match date selector styling with light yellow for Both
        let backgroundColor: Color = {
            if isSelected {
                return Color(hex: "#FFD60A") // Same bright yellow as date selector
            } else if isBoth {
                return Color(hex: "#FFD60A").opacity(0.15) // Light yellow background for Both
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

    // MARK: - Year Selector

    private var yearSelector: some View {
        // Year buttons in horizontal line
        HStack(spacing: 12) {
            ForEach(0..<7, id: \.self) { index in
                let year = selectedYear - 3 + index  // Current year in the middle (index 3)
                yearButton(for: year)
            }
        }
    }

    private func yearButton(for year: Int) -> some View {
        let isSelected = selectedYear == year
        let isCurrentYear = year == Calendar.current.component(.year, from: Date())
        let size: CGFloat = 44

        let backgroundColor: Color = {
            if isSelected {
                return Color(hex: "#FFD60A")
            } else if isCurrentYear {
                return Color(hex: "#FFD60A").opacity(0.15)  // Light yellow for current year
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
                selectedYear = year
                selectedItemID = nil  // Clear selection when changing year
                fetchAllCalendarEvents()  // Refresh events for new year
            }
        }) {
            Text(String(year))
                .font(.system(size: 9, weight: isSelected ? .bold : .semibold))
                .foregroundColor(textColor)
                .frame(width: size, height: size)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(backgroundColor)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Time Range Selector

    private var timeRangeSelector: some View {
        HStack(spacing: 10) {
            // All 12 months in a single row
            ForEach(1...12, id: \.self) { month in
                timeRangeButton(for: .month(month))
            }
            // ALL TIME at the end
            timeRangeButton(for: .allTime, isAllTime: true)
        }
    }

    private func timeRangeButton(for range: TimeRange, isAllTime: Bool = false) -> some View {
        let isSelected = selectedTimeRange == range
        let size: CGFloat = isAllTime ? 48 : 36  // Smaller size for single row

        // Check if this is the current month
        let isCurrentMonth: Bool = {
            if case .month(let month) = range {
                let calendar = Calendar.current
                let currentMonth = calendar.component(.month, from: Date())
                return month == currentMonth
            }
            return false
        }()

        let backgroundColor: Color = {
            if isSelected {
                return Color(hex: "#FFD60A")
            } else if isAllTime {
                return Color(hex: "#FFD60A").opacity(0.15)  // Light yellow background for ALL TIME
            } else if isCurrentMonth {
                return Color(hex: "#FFD60A").opacity(0.15)  // Light yellow background for current month
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
            Text(isAllTime ? "ALL\nTIME" : String(range.displayName.prefix(3)))
                .font(.system(size: isAllTime ? 9 : 8, weight: isSelected ? .bold : .semibold))
                .foregroundColor(textColor)
                .multilineTextAlignment(.center)
                .lineSpacing(isAllTime ? -2 : 0)
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
                            count: getPinnedCount(),
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

            // Note/Event list
            ScrollView {
                LazyVStack(spacing: 0) {
                    if viewMode == .both {
                        // Both mode: merge and sort entries and events together
                        ForEach(mergedAndSortedItems) { item in
                            if item.isEntry, let entry = item.entry {
                                notePreviewCard(entry: entry)
                            } else if !item.isEntry, let event = item.event {
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
                            let _ = print("🔍 Events mode: rendering \(sortedAndFilteredEvents.count) events")
                            ForEach(sortedAndFilteredEvents, id: \.uniqueID) { event in
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
            // For recurring events, multiple occurrences share the same ID
            // Make it unique by combining event ID with start time timestamp
            self.id = "\(event.id)-\(event.startTime.timeIntervalSince1970)"
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

        // Sort by date - ensure stable sorting
        items.sort { item1, item2 in
            if sortAscending {
                return item1.date < item2.date
            } else {
                return item1.date > item2.date
            }
        }

        return items
    }

    private func notePreviewCard(entry: Entry) -> some View {
        let isSelected = selectedItemID == entry.id

        return Button(action: {
            selectedItemID = entry.id
            selectedItemType = .entry
            appState.selectedEntry = entry
            appState.selectedEvent = nil
        }) {
            HStack(spacing: 0) {
                // Colored vertical line for notes
                Rectangle()
                    .fill(itemColorManager.colorForEntry(entry))
                    .frame(width: 4)

                VStack(alignment: .leading, spacing: 6) {
                    // Header: timestamp + tags (aligned at fixed position)
                    HStack(spacing: 0) {
                        // Pin indicator
                        if entry.isPinned {
                            Image(systemName: "pin.fill")
                                .font(.system(size: 10))
                                .foregroundColor(Color(hex: "#FFD60A"))
                                .frame(width: 16)
                        }

                        // Time - fixed width to ensure tag alignment
                        Text(formattedDate(entry.createdAt))
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .frame(width: entry.isPinned ? 84 : 100, alignment: .leading)

                        // Tags - start at fixed position (100pt from left)
                        if !entry.tags.isEmpty {
                            HStack(spacing: 6) {
                                ForEach(entry.tags.prefix(3), id: \.self) { tag in
                                    let tagColor = tagColorManager.colorForTag(tag)
                                    HStack(spacing: 3) {
                                        Circle()
                                            .fill(tagColor)
                                            .frame(width: 6, height: 6)
                                        Text(tag)
                                            .font(.system(size: 10, weight: .medium))
                                            .foregroundColor(tagColor)
                                    }
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        Capsule()
                                            .fill(tagColor.opacity(0.15))
                                    )
                                }

                                if entry.tags.count > 3 {
                                    Text("+\(entry.tags.count - 3)")
                                        .font(.system(size: 9, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }

                        Spacer()
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
        .frame(maxWidth: .infinity, idealHeight: 62, maxHeight: 62)
        .clipped()
    }

    private func eventPreviewCard(event: CalendarEvent) -> some View {
        let isSelected = selectedItemID == event.uniqueID
        let eventTags = SimpleEventDetailView.extractTags(from: event.notes)

        return Button(action: {
            selectedItemID = event.uniqueID
            selectedItemType = .event
            appState.selectedEvent = event
            appState.selectedEntry = nil
        }) {
            HStack(spacing: 0) {
                // Colored vertical line for events (light blue for all-day events)
                Rectangle()
                    .fill(itemColorManager.colorForEvent(event))
                    .frame(width: 4)

                VStack(alignment: .leading, spacing: 6) {
                    // Header: timestamp + tags (aligned at fixed position)
                    HStack(spacing: 0) {
                        // Pin indicator
                        if event.isPinned {
                            Image(systemName: "pin.fill")
                                .font(.system(size: 10))
                                .foregroundColor(Color(hex: "#FFD60A"))
                                .frame(width: 16)
                        }

                        // Time - fixed width to ensure tag alignment
                        if event.isAllDay {
                            Text(formattedDateOnly(event.startTime))
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .frame(width: event.isPinned ? 84 : 100, alignment: .leading)
                        } else {
                            Text(formattedDate(event.startTime))
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .frame(width: event.isPinned ? 84 : 100, alignment: .leading)
                        }

                        // Tags - start at fixed position (100pt from left)
                        if !eventTags.isEmpty {
                            HStack(spacing: 6) {
                                ForEach(eventTags.prefix(3), id: \.self) { tag in
                                    let tagColor = tagColorManager.colorForTag(tag)
                                    HStack(spacing: 3) {
                                        Circle()
                                            .fill(tagColor)
                                            .frame(width: 6, height: 6)
                                        Text(tag)
                                            .font(.system(size: 10, weight: .medium))
                                            .foregroundColor(tagColor)
                                    }
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        Capsule()
                                            .fill(tagColor.opacity(0.15))
                                    )
                                }

                                if eventTags.count > 3 {
                                    Text("+\(eventTags.count - 3)")
                                        .font(.system(size: 9, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }

                        Spacer()
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
        .frame(maxWidth: .infinity, idealHeight: 62, maxHeight: 62)
        .clipped()
    }

    // MARK: - Detail Pane

    private var detailPane: some View {
        ZStack {
            if let itemID = selectedItemID {
                if selectedItemType == .entry {
                    // Use appState.selectedEntry if available and matches, otherwise fall back to entries array
                    let entry = (appState.selectedEntry?.id == itemID)
                        ? appState.selectedEntry
                        : appState.entries.first(where: { $0.id == itemID })

                    if let entry = entry {
                        GeometryReader { geometry in
                            ScrollView {
                                SimpleEntryDetailView(entry: entry)
                                    .environmentObject(appState)
                                    .id("\(entry.id)-\(entry.isPinned)")
                                    .frame(width: geometry.size.width)
                                    .frame(minHeight: geometry.size.height, alignment: .topLeading)
                            }
                        }
                        .onReceive(appState.$selectedEntry) { selectedEntry in
                            // If detail view closed itself by setting selectedEntry to nil
                            if selectedEntry == nil {
                                selectedItemID = nil
                            }
                        }
                    }
                } else if selectedItemType == .event,
                          let event = allCalendarEvents.first(where: { $0.uniqueID == itemID }) {
                    GeometryReader { geometry in
                        ScrollView {
                            SimpleEventDetailView(event: event)
                                .environmentObject(appState)
                                .id(event.id)
                                .frame(width: geometry.size.width)
                                .frame(minHeight: geometry.size.height, alignment: .topLeading)
                        }
                    }
                    .onReceive(appState.$selectedEvent) { selectedEvent in
                        // If detail view closed itself by setting selectedEvent to nil
                        if selectedEvent == nil {
                            selectedItemID = nil
                        }
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
        appState.entries.filter { $0.isPinned }
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
                entries = entries.filter { $0.isPinned }
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
                events = events.filter { $0.isPinned }
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
        events.sort { event1, event2 in
            if sortAscending {
                return event1.startTime < event2.startTime
            } else {
                return event1.startTime > event2.startTime
            }
        }

        return events
    }

    // MARK: - Helper Functions

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd · h:mm a"
        return formatter.string(from: date)
    }

    private func formattedDateOnly(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd"
        return formatter.string(from: date)
    }

    /// Get tag count based on current view mode and time range
    private func getTagCount(for tag: String, mode: ViewMode) -> Int {
        switch mode {
        case .notes:
            // Count only entries with this tag, filtered by time range
            let timeFiltered = filterByTimeRange(entries: appState.entries)
            return timeFiltered.filter { $0.tags.contains(tag) }.count
        case .events:
            // Count only events with this tag, filtered by time range
            let timeFiltered = filterByTimeRange(events: allCalendarEvents)
            return timeFiltered.filter { event in
                SimpleEventDetailView.extractTags(from: event.notes).contains(tag)
            }.count
        case .both:
            // Combine both entry and event counts, filtered by time range
            let timeFilteredEntries = filterByTimeRange(entries: appState.entries)
            let timeFilteredEvents = filterByTimeRange(events: allCalendarEvents)
            let entryCount = timeFilteredEntries.filter { $0.tags.contains(tag) }.count
            let eventCount = timeFilteredEvents.filter { event in
                SimpleEventDetailView.extractTags(from: event.notes).contains(tag)
            }.count
            return entryCount + eventCount
        }
    }

    /// Get "All" count based on current view mode and time range
    private func getAllCount() -> Int {
        switch viewMode {
        case .notes:
            return filterByTimeRange(entries: appState.entries).count
        case .events:
            return filterByTimeRange(events: allCalendarEvents).count
        case .both:
            let entryCount = filterByTimeRange(entries: appState.entries).count
            let eventCount = filterByTimeRange(events: allCalendarEvents).count
            return entryCount + eventCount
        }
    }

    /// Get "Recent" count based on current view mode and time range
    private func getRecentCount() -> Int {
        let calendar = Calendar.current
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: Date()) ?? Date()

        switch viewMode {
        case .notes:
            let timeFiltered = filterByTimeRange(entries: appState.entries)
            return timeFiltered.filter { $0.createdAt >= twoDaysAgo }.count
        case .events:
            let timeFiltered = filterByTimeRange(events: allCalendarEvents)
            return timeFiltered.filter { $0.startTime >= twoDaysAgo }.count
        case .both:
            let timeFilteredEntries = filterByTimeRange(entries: appState.entries)
            let timeFilteredEvents = filterByTimeRange(events: allCalendarEvents)
            let recentEntries = timeFilteredEntries.filter { $0.createdAt >= twoDaysAgo }.count
            let recentEvents = timeFilteredEvents.filter { $0.startTime >= twoDaysAgo }.count
            return recentEntries + recentEvents
        }
    }

    /// Get "Pinned" count based on current view mode
    private func getPinnedCount() -> Int {
        switch viewMode {
        case .notes:
            return appState.entries.filter { $0.isPinned }.count
        case .events:
            return allCalendarEvents.filter { $0.isPinned }.count
        case .both:
            let pinnedEntries = appState.entries.filter { $0.isPinned }.count
            let pinnedEvents = allCalendarEvents.filter { $0.isPinned }.count
            return pinnedEntries + pinnedEvents
        }
    }

    /// Fetch all calendar events from selected year only
    private func fetchAllCalendarEvents() {
        Task {
            let calendar = Calendar.current
            let now = Date()

            // Get start of selected year (January 1, YYYY 00:00:00)
            var startComponents = DateComponents()
            startComponents.year = selectedYear
            startComponents.month = 1
            startComponents.day = 1
            let startDate = calendar.date(from: startComponents) ?? now

            // Get end of selected year (December 31, YYYY 23:59:59)
            var endComponents = DateComponents()
            endComponents.year = selectedYear
            endComponents.month = 12
            endComponents.day = 31
            endComponents.hour = 23
            endComponents.minute = 59
            endComponents.second = 59
            let endDate = calendar.date(from: endComponents) ?? now

            let events = await calendarService.fetchAllEvents(from: startDate, to: endDate)
            await MainActor.run {
                allCalendarEvents = events
                print("📅 Loaded \(events.count) calendar events for year \(selectedYear)")
            }
        }
    }

    /// Filter entries by selected time range and year
    private func filterByTimeRange(entries: [Entry]) -> [Entry] {
        switch selectedTimeRange {
        case .allTime:
            // Filter by selected year only
            let calendar = Calendar.current
            return entries.filter { entry in
                let entryYear = calendar.component(.year, from: entry.createdAt)
                return entryYear == selectedYear
            }
        case .month(let month):
            // Filter by selected year and month
            let calendar = Calendar.current
            return entries.filter { entry in
                let entryMonth = calendar.component(.month, from: entry.createdAt)
                let entryYear = calendar.component(.year, from: entry.createdAt)
                return entryMonth == month && entryYear == selectedYear
            }
        }
    }

    /// Filter events by selected time range and year
    private func filterByTimeRange(events: [CalendarEvent]) -> [CalendarEvent] {
        switch selectedTimeRange {
        case .allTime:
            // All events already filtered by year in fetchAllCalendarEvents
            return events
        case .month(let month):
            // Filter by selected month (year already filtered in fetch)
            let calendar = Calendar.current
            return events.filter { event in
                let eventMonth = calendar.component(.month, from: event.startTime)
                return eventMonth == month
            }
        }
    }
}

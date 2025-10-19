import SwiftUI

/// List page - view and organize both entries and events with tri-pane Apple Notes-style layout
struct ListView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var tagStore = TagStore.shared
    @StateObject private var calendarService = CalendarService.shared
    private let tagColorManager = TagColorManager.shared

    // UI State
    @State private var searchText: String = ""
    @State private var selectedCollection: CollectionType = .allNotes
    @State private var selectedTagFilters: Set<String> = []
    @State private var selectedItemID: String? = nil  // Can be entry or event ID
    @State private var selectedItemType: ItemType = .entry
    @State private var sortBy: SortOption = .date
    @State private var sortAscending: Bool = false

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
        .background(Color(hex: "#1C1C1E"))
    }

    // MARK: - Collections Pane

    private var collectionsPane: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Text("Inputs")
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
                            count: filteredEntries.count,
                            collection: .allNotes
                        )

                        collectionButton(
                            icon: "pin.fill",
                            title: "Pinned",
                            count: pinnedEntries.count,
                            collection: .pinned
                        )

                        collectionButton(
                            icon: "clock.fill",
                            title: "Recently Edited",
                            count: recentlyEditedEntries.count,
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
            selectedCollection = collection
            selectedTagFilters.removeAll()
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
        let isSelected = selectedTagFilters.contains(tag)

        return Button(action: {
            if isSelected {
                selectedTagFilters.remove(tag)
            } else {
                selectedTagFilters.insert(tag)
            }
            selectedCollection = .tag(tag)
        }) {
            HStack(spacing: 8) {
                Circle()
                    .fill(tagColor)
                    .frame(width: 8, height: 8)

                Text("#\(tag)")
                    .font(.system(size: 13))
                    .foregroundColor(isSelected ? .primary : .secondary)

                Spacer()

                Text("\(tagStore.tagCounts[tag] ?? 0)")
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

            // Note list
            ScrollView {
                LazyVStack(spacing: 1) {
                    ForEach(sortedAndFilteredEntries, id: \.id) { entry in
                        notePreviewCard(entry: entry)
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
            .background(isSelected ? Color(hex: "#2C2C2E") : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Detail Pane

    private var detailPane: some View {
        Group {
            if let entryID = selectedItemID,
               let entry = appState.entries.first(where: { $0.id == entryID }) {
                ScrollView {
                    SimpleEntryDetailView(entry: entry)
                        .padding(20)
                }
            } else {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary.opacity(0.5))

                    Text("Select a note to view details")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    // MARK: - Computed Properties

    private var filteredEntries: [Entry] {
        var entries = appState.entries

        // Apply search filter
        if !searchText.isEmpty {
            entries = entries.filter { entry in
                entry.content.localizedCaseInsensitiveContains(searchText) ||
                entry.tags.contains(where: { $0.localizedCaseInsensitiveContains(searchText) })
            }
        }

        // Apply tag filters
        if !selectedTagFilters.isEmpty {
            entries = entries.filter { entry in
                !Set(entry.tags).isDisjoint(with: selectedTagFilters)
            }
        }

        return entries
    }

    private var pinnedEntries: [Entry] {
        filteredEntries.filter { entry in
            if let metadata = entry.metadata,
               let pinned = metadata["pinned"]?.wrappedValue as? Bool {
                return pinned
            }
            return false
        }
    }

    private var recentlyEditedEntries: [Entry] {
        let calendar = Calendar.current
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: Date()) ?? Date()
        return filteredEntries.filter { $0.createdAt >= twoDaysAgo }
    }

    private var sortedAndFilteredEntries: [Entry] {
        var entries = filteredEntries

        // Apply collection filter
        switch selectedCollection {
        case .allNotes:
            break // Already filtered
        case .pinned:
            entries = pinnedEntries
        case .recentlyEdited:
            entries = recentlyEditedEntries
        case .tag(let tag):
            entries = entries.filter { $0.tags.contains(tag) }
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

    // MARK: - Helper Functions

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd · h:mm a"
        return formatter.string(from: date)
    }
}

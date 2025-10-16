import SwiftUI
import UniformTypeIdentifiers

// MARK: - Tag Management Panel
// Drag entries/events to tags to assign them, easy tag creation

struct TagManagementPanel: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var tagColorManager = TagColorManager.shared
    @State private var newTagInput: String = ""
    @State private var isAddingTag: Bool = false
    @State private var dragOverTag: String? = nil

    // Get all unique tags with their counts
    private var tagCounts: [(tag: String, count: Int)] {
        let allTags = appState.entries.flatMap { $0.tags }

        var counts: [String: Int] = [:]
        for tag in allTags {
            counts[tag, default: 0] += 1
        }

        return counts
            .map { (tag: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }

    var body: some View {
        VStack(spacing: 0) {
            headerSection

            Divider()
                .background(Color.white.opacity(0.1))

            tagListSection
        }
        .frame(maxWidth: 280, maxHeight: .infinity)
        .background(Color(hex: "#2C2C2E"))
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 1),
            alignment: .trailing
        )
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
        .padding(24)
    }

    private var headerTitle: some View {
        HStack {
            Text("Tags")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)

            Spacer()

            Button(action: {
                withAnimation {
                    isAddingTag = true
                }
            }) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.blue)
            }
            .buttonStyle(PlainButtonStyle())
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
        Text("Drag entries/events here to tag them")
            .font(.system(size: 12))
            .foregroundColor(.secondary)
    }

    // MARK: - Tag List Section

    private var tagListSection: some View {
        ScrollView {
            VStack(spacing: 8) {
                if tagCounts.isEmpty {
                    emptyState
                } else {
                    tagList
                }
            }
            .padding(16)
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
        ForEach(tagCounts, id: \.tag) { item in
            TagDropTarget(
                tag: item.tag,
                count: item.count,
                color: tagColorManager.colorForTag(item.tag),
                isHighlighted: dragOverTag == item.tag,
                onDrop: { entryId, eventId in
                    handleDrop(entryId: entryId, eventId: eventId, tag: item.tag)
                },
                onDragEnter: {
                    dragOverTag = item.tag
                },
                onDragExit: {
                    if dragOverTag == item.tag {
                        dragOverTag = nil
                    }
                }
            )
            .environmentObject(appState)
        }
    }

    private func createNewTag() {
        let trimmed = newTagInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            isAddingTag = false
            newTagInput = ""
            return
        }

        // The tag will get a color assigned automatically when first used
        // Just close the input
        isAddingTag = false
        newTagInput = ""

        print("✅ New tag '\(trimmed)' ready to use (will get color on first assignment)")
    }

    private func handleDrop(entryId: String?, eventId: String?, tag: String) {
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

        dragOverTag = nil
    }
}

// MARK: - Tag Drop Target

struct TagDropTarget: View {
    @EnvironmentObject var appState: AppState
    let tag: String
    let count: Int
    let color: Color
    let isHighlighted: Bool
    let onDrop: (String?, String?) -> Void
    let onDragEnter: () -> Void
    let onDragExit: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Color indicator
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)

            // Tag name
            Text("#\(tag)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)

            Spacer()

            // Count badge
            Text("\(count)")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.7))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(color.opacity(0.2))
                )
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isHighlighted ? color.opacity(0.25) : Color.white.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isHighlighted ? color.opacity(0.6) : Color.white.opacity(0.1), lineWidth: isHighlighted ? 2 : 1)
        )
        .onDrop(of: [.text], isTargeted: nil) { providers in
            handleDrop(providers: providers)
            return true
        }
        .animation(.easeInOut(duration: 0.2), value: isHighlighted)
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

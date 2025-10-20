import SwiftUI

// MARK: - Simple Entry Detail View
// Minimal detail view for timeline - no explicit labels

struct SimpleEntryDetailView: View {
    let entry: Entry
    @EnvironmentObject var appState: AppState
    @StateObject private var tagColorManager = TagColorManager.shared
    @State private var editedContent: String
    @State private var tagInput: String = ""
    @State private var showTagSuggestions: Bool = false
    @State private var entryTags: [String] = []
    @State private var isPinned: Bool

    // Get tag suggestions from unified TagStore (universal, not date-dependent)
    private var tagSuggestions: [String] {
        TagStore.shared.searchTags(tagInput, excluding: entryTags)
    }

    init(entry: Entry) {
        self.entry = entry
        _editedContent = State(initialValue: entry.content)
        _entryTags = State(initialValue: entry.tags)
        _isPinned = State(initialValue: entry.isPinned)
    }

    var body: some View {
        GeometryReader { geometry in
            let topHeaderHeight: CGFloat = 150

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // First: padding to clear the weekday selection
                    Spacer()
                        .frame(height: topHeaderHeight)

                    HStack(alignment: .top, spacing: 0) {
                        // Left spacer - tap to close
                        Spacer()
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation {
                                    appState.selectedEntry = nil
                                }
                            }

                        // Content positioned on the right side of the detail panel
                        VStack(alignment: .leading, spacing: 24) {
                            // Top buttons: Pin and Close
                            HStack {
                                // Pin/Unpin button
                                Button(action: {
                                    isPinned.toggle()
                                    var updatedEntry = entry
                                    updatedEntry.isPinned = isPinned
                                    print("🔍 PIN BUTTON: isPinned=\(isPinned), updatedEntry.isPinned=\(updatedEntry.isPinned), entry.id=\(entry.id)")
                                    DatabaseManager.shared.updateEntry(updatedEntry)
                                    // Update the selected entry immediately with our updated entry
                                    appState.selectedEntry = updatedEntry
                                    print("🔍 PIN BUTTON: Set appState.selectedEntry with isPinned=\(updatedEntry.isPinned)")
                                }) {
                                    Image(systemName: isPinned ? "pin.slash.fill" : "pin.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(isPinned ? .orange : Color(hex: "#FFD60A"))
                                }
                                .buttonStyle(PlainButtonStyle())

                                Spacer()

                                // Close button
                                Button(action: {
                                    withAnimation {
                                        appState.selectedEntry = nil
                                    }
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }

                            // Entry name (editable) - using TextEditor for better visibility
                            TextEditor(text: $editedContent)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                                .frame(minHeight: 100)
                                .scrollContentBackground(.hidden)
                                .background(Color.clear)
                                .onChange(of: editedContent) { newValue in
                                    var updatedEntry = entry
                                    updatedEntry.content = newValue
                                    appState.updateEntry(updatedEntry)
                                }

                            // Created date
                            Text(entry.createdAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)

                            // AI Actions section
                            if let aiMetadata = entry.aiMetadata, !aiMetadata.actions.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(aiMetadata.actions) { action in
                                        AIActionSimpleRow(
                                            action: action,
                                            entry: entry,
                                            onJump: { jumpToAction(action, for: entry) },
                                            onRevert: { revertAction(action, for: entry) }
                                        )
                                    }
                                }
                            }

                            // Regenerate button
                            if entry.aiMetadata != nil {
                                Button(action: {
                                    appState.regenerateAIResearch(for: entry)
                                }) {
                                    HStack {
                                        Image(systemName: "arrow.clockwise")
                                            .font(.system(size: 14))
                                        Text("Regenerate AI Actions")
                                            .font(.system(size: 14, weight: .medium))
                                    }
                                    .foregroundColor(.orange)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }

                            // Tags section
                            VStack(alignment: .leading, spacing: 12) {
                                // Existing tags in flowing layout
                                if !entryTags.isEmpty {
                                    FlowLayout(spacing: 8) {
                                        ForEach(entryTags, id: \.self) { tag in
                                            let tagColor = tagColorManager.getColorForTag(tag) ?? .gray
                                            HStack(spacing: 4) {
                                                Text("#\(tag)")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(.white)

                                                // Remove tag button
                                                Button(action: {
                                                    removeTag(tag)
                                                }) {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .font(.system(size: 12))
                                                        .foregroundColor(.white.opacity(0.6))
                                                }
                                                .buttonStyle(PlainButtonStyle())
                                            }
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(
                                                Capsule()
                                                    .fill(tagColor.opacity(0.2))
                                            )
                                            .overlay(
                                                Capsule()
                                                    .stroke(tagColor.opacity(0.4), lineWidth: 1)
                                            )
                                        }
                                    }
                                }

                                // Tag input field
                                TextField("Type #tag to add... (press Enter)", text: $tagInput)
                                    .font(.system(size: 12))
                                    .foregroundColor(.white)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.white.opacity(0.05))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    )
                                    .onSubmit {
                                        addTag()
                                    }
                                    .onChange(of: tagInput) { newValue in
                                        // Auto-add tag when space or comma is typed
                                        if newValue.contains(" ") || newValue.contains(",") {
                                            addTag()
                                        }
                                    }

                                // Tag suggestions (always show when empty - top 8, otherwise filtered)
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
                                                        .background(
                                                            Capsule()
                                                                .fill(Color.white.opacity(0.1))
                                                        )
                                                }
                                                .buttonStyle(PlainButtonStyle())
                                            }
                                        }
                                    }
                                }
                            }

                            // Delete button
                            Button(action: {
                                appState.deleteEntry(entry)
                                appState.selectedEntry = nil
                            }) {
                                HStack {
                                    Image(systemName: "trash")
                                        .font(.system(size: 14))
                                    Text("Delete Entry")
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .foregroundColor(.red)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(32)
                        .padding(.bottom, 60) // Extra bottom padding for comfortable scrolling
                    }
                    .frame(maxWidth: .infinity) // Take full width of container
                    .background(Color(hex: "#1C1C1E")) // Same as main timeline background
                    .overlay(
                        // Inset shadow on all sides using entry green color
                        Rectangle()
                            .stroke(Color.clear, lineWidth: 0)
                            .shadow(color: Color(hex: "#7CB342").opacity(0.3), radius: 8, x: 0, y: 0)
                            .shadow(color: Color(hex: "#7CB342").opacity(0.2), radius: 4, x: 2, y: 0)  // Right
                            .shadow(color: Color(hex: "#7CB342").opacity(0.2), radius: 4, x: -2, y: 0) // Left
                            .shadow(color: Color(hex: "#7CB342").opacity(0.2), radius: 4, x: 0, y: 2)  // Bottom
                            .shadow(color: Color(hex: "#7CB342").opacity(0.2), radius: 4, x: 0, y: -2) // Top
                    )
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.8).combined(with: .opacity),
                        removal: .scale(scale: 0.9).combined(with: .opacity)
                    ))
                }
                .frame(minHeight: geometry.size.height) // Ensure content takes full height
            }
        }
        .background(Color(hex: "#1C1C1E").opacity(0.5))
        .transition(.opacity)
        .onAppear {
            // Sync local state on appear
            isPinned = entry.isPinned
        }
        .onChange(of: entry.id) { _ in
            // When entry ID changes (different entry selected), sync state
            isPinned = entry.isPinned
            editedContent = entry.content
            entryTags = entry.tags
        }
    }

    // MARK: - Jump and Revert Actions

    private func jumpToAction(_ action: AIAction, for entry: Entry) {
        print("🚀 Jump action clicked for: \(action.type.displayName)")
        print("   Reverse data: \(action.reverseData?.keys.joined(separator: ", ") ?? "nil")")

        Task {
            let toolService = ToolService()

            switch action.type {
            case .calendar:
                // Open Calendar app and navigate to the event
                if let reverseData = action.reverseData {
                    if let eventId = reverseData["eventId"]?.stringValue,
                       let startDate = reverseData["startDate"]?.dateValue {
                        await MainActor.run {
                            openCalendarApp(eventId: eventId, date: startDate)
                        }
                    } else {
                        await MainActor.run {
                            showJumpErrorAlert(message: "Calendar event data is missing.")
                        }
                    }
                } else {
                    await MainActor.run {
                        showJumpErrorAlert(message: "Calendar event data is missing.")
                    }
                }

            case .appleReminders:
                // Open Reminders app
                await MainActor.run {
                    openRemindersApp()
                }

            case .contacts:
                // Open Contacts app
                if let reverseData = action.reverseData,
                   let contactId = reverseData["contactId"]?.stringValue {
                    await MainActor.run {
                        openContactsApp(contactId: contactId)
                    }
                } else {
                    await MainActor.run {
                        openContactsApp(contactId: nil)
                    }
                }

            case .maps:
                // Open Maps app with the location
                if let reverseData = action.reverseData,
                   let query = reverseData["query"]?.stringValue {
                    do {
                        try await toolService.openInMaps(address: query)
                    } catch {
                        await MainActor.run {
                            showJumpErrorAlert(message: "Failed to open Maps: \(error.localizedDescription)")
                        }
                    }
                } else if let query = action.data["query"]?.stringValue {
                    do {
                        try await toolService.openInMaps(address: query)
                    } catch {
                        await MainActor.run {
                            showJumpErrorAlert(message: "Failed to open Maps: \(error.localizedDescription)")
                        }
                    }
                } else {
                    await MainActor.run {
                        showJumpErrorAlert(message: "Location data is missing.")
                    }
                }

            default:
                break
            }
        }
    }

    private func revertAction(_ action: AIAction, for entry: Entry) {
        Task {
            let toolService = ToolService()

            do {
                if action.status == .reversed {
                    // Restore the action - recreate the resource
                    print("🔄 Restoring action: \(action.type.displayName)")

                    switch action.type {
                    case .appleReminders:
                        if let title = action.data["title"]?.stringValue {
                            let dueDate = action.data["dueDate"]?.dateValue
                            let notes = action.data["notes"]?.stringValue
                            try await toolService.createReminder(title: title, notes: notes, dueDate: dueDate)
                            print("✅ Restored reminder: \(title)")
                        }

                    case .calendar:
                        if let title = action.data["title"]?.stringValue,
                           let startDate = action.data["startDate"]?.dateValue {
                            let endDate = action.data["endDate"]?.dateValue
                            let notes = action.data["notes"]?.stringValue
                            try await toolService.createCalendarEvent(
                                title: title,
                                notes: notes,
                                startDate: startDate,
                                endDate: endDate
                            )
                            print("✅ Restored calendar event: \(title)")
                        }

                    case .contacts:
                        if let firstName = action.data["firstName"]?.stringValue {
                            let lastName = action.data["lastName"]?.stringValue
                            let email = action.data["email"]?.stringValue
                            let phoneNumber = action.data["phoneNumber"]?.stringValue ?? action.data["phone"]?.stringValue
                            try await toolService.createContact(
                                firstName: firstName,
                                lastName: lastName,
                                phoneNumber: phoneNumber,
                                email: email
                            )
                            print("✅ Restored contact: \(firstName) \(lastName ?? "")")
                        }

                    case .maps:
                        // Nothing to restore
                        break
                    }

                    // Update action status back to executed
                    await MainActor.run {
                        appState.databaseManager.updateAIActionStatus(entry.id, actionId: action.id, status: .executed)
                    }

                    // Small delay to ensure database update completes
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

                    // Refresh the selected entry to trigger UI update
                    await MainActor.run {
                        if let updatedEntry = appState.databaseManager.entries.first(where: { $0.id == entry.id }) {
                            appState.selectedEntry = updatedEntry
                        }
                    }

                } else {
                    // Revert the action - delete the resource
                    print("↩️ Reverting action: \(action.type.displayName)")

                    switch action.type {
                    case .appleReminders:
                        if let reminderId = action.reverseData?["reminderId"]?.stringValue {
                            try await toolService.deleteReminder(reminderId: reminderId)
                            print("✅ Deleted reminder: \(reminderId)")
                        }

                    case .calendar:
                        if let eventId = action.reverseData?["eventId"]?.stringValue {
                            try await toolService.deleteCalendarEvent(eventId: eventId)
                            print("✅ Deleted calendar event: \(eventId)")
                        }

                    case .contacts:
                        if let contactId = action.reverseData?["contactId"]?.stringValue {
                            try await toolService.deleteContact(contactId: contactId)
                            print("✅ Deleted contact: \(contactId)")
                        }

                    case .maps:
                        // Nothing to revert
                        break
                    }

                    // Update action status to reversed
                    await MainActor.run {
                        appState.databaseManager.updateAIActionStatus(entry.id, actionId: action.id, status: .reversed)
                    }

                    // Small delay to ensure database update completes
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

                    // Refresh the selected entry to trigger UI update
                    await MainActor.run {
                        if let updatedEntry = appState.databaseManager.entries.first(where: { $0.id == entry.id }) {
                            appState.selectedEntry = updatedEntry
                        }
                    }
                }
            } catch {
                print("❌ Failed to revert/restore action: \(error)")
                await MainActor.run {
                    showRevertErrorAlert(for: action.type, error: error)
                }
            }
        }
    }

    @MainActor
    private func openCalendarApp(eventId: String, date: Date) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        let dateString = dateFormatter.string(from: date)

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
                openCalendarAppFallback()
            }
        } else {
            openCalendarAppFallback()
        }
    }

    @MainActor
    private func openCalendarAppFallback() {
        if let calendarAppURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.iCal") {
            NSWorkspace.shared.open(calendarAppURL)
            print("✅ Opened Calendar app (fallback)")
        }
    }

    @MainActor
    private func openRemindersApp() {
        if let remindersAppURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.reminders") {
            NSWorkspace.shared.open(remindersAppURL)
            print("✅ Opened Reminders app")
        } else {
            showJumpErrorAlert(message: "Could not find Reminders app.")
        }
    }

    @MainActor
    private func openContactsApp(contactId: String?) {
        if let contactId = contactId {
            if let url = URL(string: "addressbook://\(contactId)") {
                let success = NSWorkspace.shared.open(url)
                if success {
                    print("✅ Opened Contacts app with contact: \(contactId)")
                } else {
                    openContactsAppFallback()
                }
            } else {
                openContactsAppFallback()
            }
        } else {
            openContactsAppFallback()
        }
    }

    @MainActor
    private func openContactsAppFallback() {
        if let contactsAppURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.AddressBook") {
            NSWorkspace.shared.open(contactsAppURL)
            print("✅ Opened Contacts app")
        } else {
            showJumpErrorAlert(message: "Could not find Contacts app.")
        }
    }

    @MainActor
    private func showRevertErrorAlert(for actionType: AIActionType, error: Error) {
        let alert = NSAlert()
        alert.messageText = "Failed to Revert \(actionType.displayName)"
        alert.informativeText = "Could not revert the action: \(error.localizedDescription)\n\nThe resource may have already been deleted manually."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    @MainActor
    private func showJumpErrorAlert(message: String) {
        let alert = NSAlert()
        alert.messageText = "Cannot Jump to Resource"
        alert.informativeText = message
        alert.alertStyle = .informational
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
        guard !cleanedTag.isEmpty, !entryTags.contains(cleanedTag) else {
            tagInput = ""
            return
        }

        // Update local state immediately for instant UI feedback
        entryTags.append(cleanedTag)

        // Update entry in database
        var updatedEntry = entry
        updatedEntry.tags = entryTags
        appState.updateEntry(updatedEntry)

        // Register tag and ensure color is assigned AFTER successful update
        tagColorManager.registerTag(cleanedTag)

        // Update the selected entry to trigger UI refresh in timeline
        if let refreshedEntry = appState.databaseManager.entries.first(where: { $0.id == entry.id }) {
            appState.selectedEntry = refreshedEntry
        }

        // Clear input
        tagInput = ""

        print("✅ Added tag: \(cleanedTag)")
    }

    private func removeTag(_ tag: String) {
        // Update local state immediately for instant UI feedback
        entryTags.removeAll { $0 == tag }

        // Update entry in database
        var updatedEntry = entry
        updatedEntry.tags = entryTags
        appState.updateEntry(updatedEntry)

        // Update the selected entry to trigger UI refresh in timeline
        if let refreshedEntry = appState.databaseManager.entries.first(where: { $0.id == entry.id }) {
            appState.selectedEntry = refreshedEntry
        }

        print("✅ Removed tag: \(tag)")
    }
}

// MARK: - AI Action Simple Row

struct AIActionSimpleRow: View {
    let action: AIAction
    let entry: Entry
    let onJump: () -> Void
    let onRevert: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            // Icon
            Image(systemName: actionIcon)
                .font(.system(size: 14))
                .foregroundColor(actionColor)
                .frame(width: 20)

            // Title
            Text(actionTitle)
                .font(.system(size: 14))
                .foregroundColor(.white)

            Spacer()

            // Status/Action button
            if action.status == .failed {
                HStack(spacing: 4) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                    Text("Failed")
                        .font(.system(size: 12))
                }
                .foregroundColor(.red)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.red.opacity(0.1))
                )
            } else if action.status == .reversed {
                // Reverted status - click to restore
                Button(action: onRevert) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.uturn.left.circle.fill")
                            .font(.system(size: 12))
                        Text("Reverted")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.secondary.opacity(0.1))
                    )
                }
                .buttonStyle(PlainButtonStyle())
            } else if action.status == .executed {
                HStack(spacing: 8) {
                    // Jump button
                    Button(action: onJump) {
                        HStack(spacing: 4) {
                            Text("Jump")
                                .font(.system(size: 12))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 10))
                        }
                        .foregroundColor(.orange)
                    }
                    .buttonStyle(PlainButtonStyle())

                    // Revert button (only if reversible and not maps)
                    if action.reversible && action.type != .maps {
                        Button(action: onRevert) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.uturn.left")
                                    .font(.system(size: 10))
                                Text("Revert")
                                    .font(.system(size: 12))
                            }
                            .foregroundColor(.red)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: "#2C2C2E"))
        )
    }

    private var actionIcon: String {
        switch action.type {
        case .calendar: return "calendar"
        case .appleReminders: return "bell.fill"
        case .contacts: return "person.crop.circle"
        case .maps: return "map.fill"
        }
    }

    private var actionColor: Color {
        switch action.type {
        case .calendar: return .red
        case .appleReminders: return .orange
        case .contacts: return Color(hex: "#FFB84D") // Light orange
        case .maps: return .yellow
        }
    }

    private var actionTitle: String {
        switch action.type {
        case .calendar: return "Calendar"
        case .appleReminders: return "Reminder"
        case .contacts: return "Contact"
        case .maps: return "Maps"
        }
    }
}

// MARK: - Triangle Pointer Shape

struct TrianglePointer: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Triangle pointing RIGHT
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()

        return path
    }
}

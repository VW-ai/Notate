import SwiftUI

struct EntryDetailView: View {
    let entry: Entry?
    @EnvironmentObject var appState: AppState
    @State private var editingContent = false
    @State private var editedContent = ""
    @State private var showingDeleteConfirmation = false
    @State private var showingPermissionRequest = false
    @State private var requestedActionType: AIActionType?
    @State private var pendingAction: AIAction?
    @State private var pendingEntry: Entry?
    private var permissionManager: PermissionManager {
        appState.permissionManager
    }

    // Get the latest entry from appState to ensure UI updates
    private var currentEntry: Entry? {
        guard let entry = entry else { return nil }
        return appState.entries.first(where: { $0.id == entry.id }) ?? entry
    }

    // Check if THIS specific entry is being processed
    private var isProcessingAI: Bool {
        guard let entryId = entry?.id else { return false }
        return appState.processingEntryIds.contains(entryId)
    }

    var body: some View {
        Group {
            if let entry = currentEntry {
                detailContent(for: entry)
            } else {
                emptyDetailView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ModernDesignSystem.Colors.surfaceBackground)
        .onAppear {
            permissionManager.checkAllPermissions()
        }
        .sheet(isPresented: $showingPermissionRequest) {
            if let actionType = requestedActionType {
                PermissionRequestView(
                    actionType: actionType,
                    onPermissionGranted: {
                        // Permission granted, now execute the action
                        if let action = pendingAction, let entry = pendingEntry {
                            executeActionDirectly(action, for: entry)
                        }
                        showingPermissionRequest = false
                        requestedActionType = nil
                        pendingAction = nil
                        pendingEntry = nil
                    },
                    onDismiss: {
                        showingPermissionRequest = false
                        requestedActionType = nil
                        pendingAction = nil
                        pendingEntry = nil
                    }
                )
                .environmentObject(permissionManager)
            }
        }
    }

    // MARK: - Detail Content

    private func detailContent(for entry: Entry) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ModernDesignSystem.Spacing.large) {
                // Header with actions
                entryHeader(entry)

                // Content section
                contentSection(entry)

                // Metadata section
                metadataSection(entry)

                // AI Section
                if isProcessingAI {
                    aiLoadingSection()
                } else if entry.hasAIProcessing {
                    aiSection(entry)
                } else {
                    aiProcessingButton(entry)
                }

                Spacer(minLength: 50)
            }
            .padding(ModernDesignSystem.Spacing.large)
        }
    }

    // MARK: - Header

    private func entryHeader(_ entry: Entry) -> some View {
        VStack(alignment: .leading, spacing: ModernDesignSystem.Spacing.medium) {
            // Action buttons - minimal
            HStack(spacing: ModernDesignSystem.Spacing.small) {
                Spacer()

                ModernButton(
                    title: "Delete",
                    icon: "trash",
                    style: .destructive,
                    size: .medium
                ) {
                    showingDeleteConfirmation = true
                }
            }
        }
        .alert("Delete Entry", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                appState.deleteEntry(entry)
            }
        } message: {
            Text("This action cannot be undone.")
        }
    }

    // MARK: - Content Section

    private func contentSection(_ entry: Entry) -> some View {
        ModernCard(
            padding: ModernDesignSystem.Spacing.regular,
            cornerRadius: ModernDesignSystem.CornerRadius.medium,
            shadowIntensity: ModernDesignSystem.Shadow.light
        ) {
            VStack(alignment: .leading, spacing: ModernDesignSystem.Spacing.medium) {
                HStack {
                    Image(systemName: "doc.text")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(ModernDesignSystem.Colors.accent)

                    Text("Content")
                        .font(ModernDesignSystem.Typography.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(ModernDesignSystem.Colors.primary)

                    Spacer()

                    if editingContent {
                        HStack(spacing: ModernDesignSystem.Spacing.small) {
                            Button("Cancel") {
                                cancelEditing()
                            }
                            .font(ModernDesignSystem.Typography.small)
                            .foregroundColor(ModernDesignSystem.Colors.secondary)

                            Button("Save") {
                                saveEditing(entry)
                            }
                            .font(ModernDesignSystem.Typography.small)
                            .fontWeight(.medium)
                            .foregroundColor(ModernDesignSystem.Colors.accent)
                        }
                    }
                }

                if editingContent {
                    TextEditor(text: $editedContent)
                        .font(ModernDesignSystem.Typography.body)
                        .frame(minHeight: 100)
                        .padding(ModernDesignSystem.Spacing.small)
                        .background(ModernDesignSystem.Colors.surfaceSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.small))
                } else {
                    Text(entry.content)
                        .font(ModernDesignSystem.Typography.body)
                        .foregroundColor(ModernDesignSystem.Colors.primary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .onTapGesture {
                            startEditing(entry)
                        }
                }
            }
        }
    }

    // MARK: - Metadata Section

    private func metadataSection(_ entry: Entry) -> some View {
        ModernCard(
            padding: ModernDesignSystem.Spacing.regular,
            cornerRadius: ModernDesignSystem.CornerRadius.medium,
            shadowIntensity: ModernDesignSystem.Shadow.light
        ) {
            VStack(alignment: .leading, spacing: ModernDesignSystem.Spacing.small) {
                // Just show created date without label
                Text(entry.formattedDate)
                    .font(ModernDesignSystem.Typography.small)
                    .foregroundColor(ModernDesignSystem.Colors.secondary)

                // Tags without label - just flowing layout
                if !entry.tags.isEmpty {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: ModernDesignSystem.Spacing.tiny) {
                        ForEach(entry.tags, id: \.self) { tag in
                            ModernTagBadge(tag: tag)
                        }
                    }
                }
            }
        }
    }

    private func metadataRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(ModernDesignSystem.Colors.secondary)
                .frame(width: 20)

            Text(label)
                .font(ModernDesignSystem.Typography.small)
                .foregroundColor(ModernDesignSystem.Colors.secondary)
                .frame(width: 80, alignment: .leading)

            Text(value)
                .font(ModernDesignSystem.Typography.small)
                .foregroundColor(ModernDesignSystem.Colors.primary)

            Spacer()
        }
    }

    // MARK: - AI Section

    private func aiSection(_ entry: Entry) -> some View {
        ModernCard(
            padding: ModernDesignSystem.Spacing.regular,
            cornerRadius: ModernDesignSystem.CornerRadius.medium,
            shadowIntensity: ModernDesignSystem.Shadow.light
        ) {
            VStack(alignment: .leading, spacing: ModernDesignSystem.Spacing.medium) {
                HStack {
                    Spacer()

                    Button(action: {
                        appState.regenerateAIResearch(for: entry)
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 12))
                            Text("Regenerate")
                                .font(ModernDesignSystem.Typography.small)
                        }
                        .foregroundColor(ModernDesignSystem.Colors.accent)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(isProcessingAI)
                }

                if let aiMetadata = entry.aiMetadata {
                    // Actions without label
                    if !aiMetadata.actions.isEmpty {
                        aiActionsSection(aiMetadata.actions, for: entry)
                    }

                    // Research without label
                    if let research = aiMetadata.researchResults {
                        aiResearchSection(research)
                    }
                }
            }
        }
    }

    private func aiProcessingButton(_ entry: Entry) -> some View {
        ModernCard(
            padding: ModernDesignSystem.Spacing.regular,
            cornerRadius: ModernDesignSystem.CornerRadius.medium,
            shadowIntensity: ModernDesignSystem.Shadow.light
        ) {
            VStack(spacing: ModernDesignSystem.Spacing.medium) {
                VStack(spacing: ModernDesignSystem.Spacing.small) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 32, weight: .light))
                        .foregroundColor(ModernDesignSystem.Colors.accent.opacity(0.6))

                    Text("AI Processing Available")
                        .font(ModernDesignSystem.Typography.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(ModernDesignSystem.Colors.primary)

                    Text("Get AI insights and suggestions for this entry")
                        .font(ModernDesignSystem.Typography.small)
                        .foregroundColor(ModernDesignSystem.Colors.secondary)
                        .multilineTextAlignment(.center)
                }

                ModernButton(
                    title: "Process with AI",
                    icon: "brain.head.profile",
                    style: .primary,
                    size: .medium
                ) {
                    appState.processEntryWithAI(entry)
                }
            }
        }
    }

    private func aiLoadingSection() -> some View {
        ModernCard(
            padding: ModernDesignSystem.Spacing.regular,
            cornerRadius: ModernDesignSystem.CornerRadius.medium,
            shadowIntensity: ModernDesignSystem.Shadow.light
        ) {
            VStack(spacing: ModernDesignSystem.Spacing.medium) {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(ModernDesignSystem.Colors.accent)

                    Text("AI Insights")
                        .font(ModernDesignSystem.Typography.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(ModernDesignSystem.Colors.primary)

                    Spacer()
                }

                VStack(spacing: ModernDesignSystem.Spacing.regular) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.2)

                    Text("AI is analyzing your entry...")
                        .font(ModernDesignSystem.Typography.body)
                        .foregroundColor(ModernDesignSystem.Colors.secondary)
                        .multilineTextAlignment(.center)

                    Text("Generating insights and suggested actions")
                        .font(ModernDesignSystem.Typography.small)
                        .foregroundColor(ModernDesignSystem.Colors.secondary.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, ModernDesignSystem.Spacing.large)
            }
        }
    }

    private func aiActionsSection(_ actions: [AIAction], for entry: Entry) -> some View {
        VStack(alignment: .leading, spacing: ModernDesignSystem.Spacing.small) {
            Text("Suggested Actions")
                .font(ModernDesignSystem.Typography.headline)
                .fontWeight(.medium)
                .foregroundColor(ModernDesignSystem.Colors.primary)

            ForEach(actions, id: \.id) { action in
                // Get the latest action status from appState
                if let latestEntry = appState.entries.first(where: { $0.id == entry.id }),
                   let latestAction = latestEntry.aiMetadata?.actions.first(where: { $0.id == action.id }) {
                    aiActionRow(latestAction, for: entry)
                } else {
                    aiActionRow(action, for: entry)
                }
            }
        }
    }

    private func aiActionRow(_ action: AIAction, for entry: Entry) -> some View {
        HStack(spacing: ModernDesignSystem.Spacing.medium) {
            // Action icon
            Image(systemName: action.type.icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(ModernDesignSystem.Colors.accent)
                .frame(width: 20)

            // Action content
            VStack(alignment: .leading, spacing: ModernDesignSystem.Spacing.tiny) {
                Text(action.type.displayName)
                    .font(ModernDesignSystem.Typography.small)
                    .fontWeight(.medium)
                    .foregroundColor(ModernDesignSystem.Colors.primary)

                if let data = action.data["description"], !data.stringValue.isEmpty {
                    Text(data.stringValue)
                        .font(ModernDesignSystem.Typography.tiny)
                        .foregroundColor(ModernDesignSystem.Colors.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            // Action button
            actionStatusButton(action, for: entry)
        }
        .padding(ModernDesignSystem.Spacing.small)
        .background(ModernDesignSystem.Colors.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.small))
    }

    private func actionStatusButton(_ action: AIAction, for entry: Entry) -> some View {
        HStack(spacing: ModernDesignSystem.Spacing.tiny) {
            // Main action button (Execute/Done/Failed)
            Button(action: {
                executeAction(action, for: entry)
            }) {
                HStack(spacing: ModernDesignSystem.Spacing.tiny) {
                    Image(systemName: action.status.icon)
                        .font(.system(size: 10, weight: .medium))

                    Text(action.status.buttonDisplayName)
                        .font(ModernDesignSystem.Typography.tiny)
                        .fontWeight(.medium)
                }
                .foregroundColor(action.status.color)
                .padding(.horizontal, ModernDesignSystem.Spacing.small)
                .padding(.vertical, ModernDesignSystem.Spacing.tiny)
                .background(action.status.color.opacity(0.1))
                .clipShape(Capsule())
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(action.status == .executed || action.status == .executing)

            // Jump button (for calendar, maps, reminders, and contacts when executed)
            if action.status == .executed && (action.type == .calendar || action.type == .maps || action.type == .appleReminders || action.type == .contacts) {
                Button(action: {
                    jumpToAction(action, for: entry)
                }) {
                    HStack(spacing: ModernDesignSystem.Spacing.tiny) {
                        Image(systemName: "arrow.up.forward")
                            .font(.system(size: 10, weight: .medium))

                        Text("Jump")
                            .font(ModernDesignSystem.Typography.tiny)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, ModernDesignSystem.Spacing.small)
                    .padding(.vertical, ModernDesignSystem.Spacing.tiny)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Capsule())
                }
                .buttonStyle(PlainButtonStyle())
            }

            // Revert button (only when executed and reversible)
            if action.status == .executed && action.reversible {
                Button(action: {
                    revertAction(action, for: entry)
                }) {
                    HStack(spacing: ModernDesignSystem.Spacing.tiny) {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.system(size: 10, weight: .medium))

                        Text("Revert")
                            .font(ModernDesignSystem.Typography.tiny)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.orange)
                    .padding(.horizontal, ModernDesignSystem.Spacing.small)
                    .padding(.vertical, ModernDesignSystem.Spacing.tiny)
                    .background(Color.orange.opacity(0.1))
                    .clipShape(Capsule())
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    private func aiResearchSection(_ research: ResearchResults) -> some View {
        VStack(alignment: .leading, spacing: ModernDesignSystem.Spacing.small) {
            Text("Research & Analysis")
                .font(ModernDesignSystem.Typography.headline)
                .fontWeight(.medium)
                .foregroundColor(ModernDesignSystem.Colors.primary)

            MarkdownText(markdown: research.content)
                .padding(ModernDesignSystem.Spacing.small)
                .background(ModernDesignSystem.Colors.surfaceSecondary)
                .clipShape(RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.small))
        }
    }

    private func aiStatsSection(_ metadata: AIMetadata) -> some View {
        HStack(spacing: ModernDesignSystem.Spacing.medium) {
            VStack(spacing: ModernDesignSystem.Spacing.tiny) {
                Text("Processed")
                    .font(ModernDesignSystem.Typography.tiny)
                    .foregroundColor(ModernDesignSystem.Colors.secondary)

                Text(metadata.processingMeta?.processedAt.formatted() ?? "N/A")
                    .font(ModernDesignSystem.Typography.tiny)
                    .fontWeight(.medium)
                    .foregroundColor(ModernDesignSystem.Colors.primary)
            }

            Spacer()

            if metadata.researchResults?.processingTimeMs ?? 0 > 0 {
                VStack(spacing: ModernDesignSystem.Spacing.tiny) {
                    Text("Processing Time")
                        .font(ModernDesignSystem.Typography.tiny)
                        .foregroundColor(ModernDesignSystem.Colors.secondary)

                    Text("\(metadata.researchResults?.processingTimeMs ?? 0)ms")
                        .font(ModernDesignSystem.Typography.tiny)
                        .fontWeight(.medium)
                        .foregroundColor(ModernDesignSystem.Colors.primary)
                }
            }
        }
        .padding(ModernDesignSystem.Spacing.small)
        .background(ModernDesignSystem.Colors.accent.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.small))
    }

    // MARK: - Empty State

    private var emptyDetailView: some View {
        VStack(spacing: ModernDesignSystem.Spacing.large) {
            VStack(spacing: ModernDesignSystem.Spacing.medium) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(ModernDesignSystem.Colors.secondary.opacity(0.6))

                Text("Select an entry")
                    .font(ModernDesignSystem.Typography.title)
                    .fontWeight(.semibold)
                    .foregroundColor(ModernDesignSystem.Colors.primary)

                Text("Click on any entry to view details, AI insights, and manage actions")
                    .font(ModernDesignSystem.Typography.body)
                    .foregroundColor(ModernDesignSystem.Colors.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 300)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Actions

    private func startEditing(_ entry: Entry) {
        editedContent = entry.content
        editingContent = true
    }

    private func cancelEditing() {
        editingContent = false
        editedContent = ""
    }

    private func saveEditing(_ entry: Entry) {
        var updatedEntry = entry
        updatedEntry.content = editedContent
        appState.updateEntry(updatedEntry)
        editingContent = false
        editedContent = ""
    }

    private func toggleCompletion(_ entry: Entry) {
        if entry.status == .done {
            appState.markTodoAsOpen(entry)
        } else {
            appState.markTodoAsDone(entry)
        }
    }

    private func convertEntry(_ entry: Entry) {
        if entry.isTodo {
            appState.convertTodoToThought(entry)
        } else {
            appState.convertThoughtToTodo(entry)
        }
    }

    private func executeAction(_ action: AIAction, for entry: Entry) {
        // Check permission first
        let permissionStatus = permissionManager.getPermissionForAction(action.type)

        if permissionStatus.isGranted {
            // Permission granted, execute directly
            executeActionDirectly(action, for: entry)
        } else {
            // Need to request permission
            requestedActionType = action.type
            showingPermissionRequest = true

            // Store the action for later execution
            pendingAction = action
            pendingEntry = entry
        }
    }

    private func executeActionDirectly(_ action: AIAction, for entry: Entry) {
        // Skip if already executed or reversed
        if action.status == .executed || action.status == .reversed {
            print("⏭️ Skipping \(action.type.displayName) action - already \(action.status.rawValue)")
            return
        }

        Task {
            // Update the action status to executing
            await MainActor.run {
                appState.databaseManager.updateAIActionStatus(entry.id, actionId: action.id, status: .executing)
            }

            print("🤖 Executing action: \(action.type.displayName) for entry: \(entry.id)")

            do {
                // Execute the action using ToolService
                let success = try await executeActionWithToolService(action, for: entry)

                await MainActor.run {
                    appState.databaseManager.updateAIActionStatus(entry.id, actionId: action.id, status: success ? .executed : .failed)
                }

                if success {
                    print("✅ Successfully executed: \(action.type.displayName)")
                } else {
                    print("❌ Failed to execute: \(action.type.displayName)")
                }
            } catch {
                print("❌ Error executing action: \(error)")
                await MainActor.run {
                    appState.databaseManager.updateAIActionStatus(entry.id, actionId: action.id, status: .failed)

                    // Show permission guidance alert if it's a permission error
                    if let toolError = error as? ToolError, case .permissionDenied = toolError {
                        showPermissionDeniedAlert(for: action.type)
                    }
                }
            }
        }
    }

    private func executeActionAfterPermission(_ actionType: AIActionType) async {
        guard let action = pendingAction, let entry = pendingEntry else { return }

        await MainActor.run {
            showingPermissionRequest = false
            requestedActionType = nil
        }

        executeActionDirectly(action, for: entry)

        // Clear pending action
        pendingAction = nil
        pendingEntry = nil
    }

    @MainActor
    private func executeActionWithToolService(_ action: AIAction, for entry: Entry) async throws -> Bool {
        let toolService = ToolService()

        switch action.type {
        case .appleReminders:
            // Extract reminder data from action
            let title = action.data["title"]?.stringValue ?? entry.content
            let notes = action.data["notes"]?.stringValue
            let dueDate = action.data["dueDate"]?.dateValue

            let reminderId = try await toolService.createReminder(title: title, notes: notes, dueDate: dueDate)

            // Store reminder ID for reversal
            if !reminderId.isEmpty {
                let reverseData: [String: ActionData] = ["reminderId": ActionData(reminderId)]
                appState.databaseManager.updateAIActionData(entry.id, actionId: action.id, reverseData: reverseData)
            }

            return !reminderId.isEmpty

        case .calendar:
            // Extract calendar event data
            let title = action.data["title"]?.stringValue ?? entry.content
            let startDate = action.data["startDate"]?.dateValue ?? Date().addingTimeInterval(3600) // 1 hour from now
            let endDate = action.data["endDate"]?.dateValue ?? startDate.addingTimeInterval(3600) // 1 hour duration
            let notes = action.data["notes"]?.stringValue

            let eventId = try await toolService.createCalendarEvent(title: title, notes: notes, startDate: startDate, endDate: endDate)

            // Store event ID and dates for reversal and jump
            if !eventId.isEmpty {
                let reverseData: [String: ActionData] = [
                    "eventId": ActionData(eventId),
                    "startDate": ActionData(startDate),
                    "endDate": ActionData(endDate)
                ]
                appState.databaseManager.updateAIActionData(entry.id, actionId: action.id, reverseData: reverseData)
            }

            return !eventId.isEmpty

        case .contacts:
            // Extract contact data
            let firstName = action.data["firstName"]?.stringValue ?? ""
            let lastName = action.data["lastName"]?.stringValue ?? ""
            let email = action.data["email"]?.stringValue
            let phone = action.data["phone"]?.stringValue

            let contactId = try await toolService.createContact(firstName: firstName, lastName: lastName, phoneNumber: phone, email: email)

            // Store contact ID for reversal
            if !contactId.isEmpty {
                let reverseData: [String: ActionData] = ["contactId": ActionData(contactId)]
                appState.databaseManager.updateAIActionData(entry.id, actionId: action.id, reverseData: reverseData)
            }

            return !contactId.isEmpty

        case .maps:
            // Extract location data
            let query = action.data["query"]?.stringValue ?? entry.content

            // Store the query for jump functionality (don't auto-open)
            let reverseData: [String: ActionData] = ["query": ActionData(query)]
            appState.databaseManager.updateAIActionData(entry.id, actionId: action.id, reverseData: reverseData)

            // Don't open maps automatically - only when user clicks jump
            return true
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
                    print("   Calendar reverseData keys: \(reverseData.keys)")
                    if let eventId = reverseData["eventId"]?.stringValue,
                       let startDate = reverseData["startDate"]?.dateValue {
                        print("   Opening calendar with eventId: \(eventId), date: \(startDate)")
                        await MainActor.run {
                            openCalendarApp(eventId: eventId, date: startDate)
                        }
                    } else {
                        print("❌ Missing eventId or startDate in reverseData")
                        await MainActor.run {
                            showJumpErrorAlert(message: "Calendar event data is missing. The event may have been created before this feature was added.")
                        }
                    }
                } else {
                    print("❌ No reverseData found for calendar action")
                    await MainActor.run {
                        showJumpErrorAlert(message: "Calendar event data is missing. The event may have been created before this feature was added.")
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
                    // Fallback: just open Contacts app
                    await MainActor.run {
                        openContactsApp(contactId: nil)
                    }
                }

            case .maps:
                // Open Maps app with the location
                if let reverseData = action.reverseData {
                    print("   Maps reverseData keys: \(reverseData.keys)")
                    if let query = reverseData["query"]?.stringValue {
                        print("   Opening Maps with query: \(query)")
                        do {
                            try await toolService.openInMaps(address: query)
                            print("✅ Opened Maps for: \(query)")
                        } catch {
                            print("❌ Failed to open Maps: \(error)")
                            await MainActor.run {
                                showJumpErrorAlert(message: "Failed to open Maps: \(error.localizedDescription)")
                            }
                        }
                    } else {
                        print("❌ Missing query in reverseData")
                        // Fallback: try to get from original action data
                        if let query = action.data["query"]?.stringValue {
                            print("   Trying with original query: \(query)")
                            do {
                                try await toolService.openInMaps(address: query)
                                print("✅ Opened Maps for: \(query)")
                            } catch {
                                print("❌ Failed to open Maps: \(error)")
                                await MainActor.run {
                                    showJumpErrorAlert(message: "Failed to open Maps: \(error.localizedDescription)")
                                }
                            }
                        } else {
                            await MainActor.run {
                                showJumpErrorAlert(message: "Location data is missing.")
                            }
                        }
                    }
                } else {
                    print("❌ No reverseData found for maps action")
                    // Fallback: try to get from original action data
                    if let query = action.data["query"]?.stringValue {
                        print("   Trying with original query: \(query)")
                        do {
                            try await toolService.openInMaps(address: query)
                            print("✅ Opened Maps for: \(query)")
                        } catch {
                            print("❌ Failed to open Maps: \(error)")
                            await MainActor.run {
                                showJumpErrorAlert(message: "Failed to open Maps: \(error.localizedDescription)")
                            }
                        }
                    } else {
                        await MainActor.run {
                            showJumpErrorAlert(message: "Location data is missing.")
                        }
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
                    // Maps doesn't create anything, so nothing to revert
                    break
                }

                // Update action status to reversed
                await MainActor.run {
                    appState.databaseManager.updateAIActionStatus(entry.id, actionId: action.id, status: .reversed)
                }

                print("↩️ Reverted action: \(action.type.displayName)")
            } catch {
                print("❌ Failed to revert action: \(error)")
                // Show error alert
                await MainActor.run {
                    showRevertErrorAlert(for: action.type, error: error)
                }
            }
        }
    }

    @MainActor
    private func openCalendarApp(eventId: String, date: Date) {
        // Use AppleScript to open Calendar and show the specific date
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
                // Fallback: just open Calendar app
                openCalendarAppFallback()
            } else {
                print("✅ Opened Calendar app and navigated to date: \(dateString)")
            }
        } else {
            // Fallback: just open Calendar app
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
            // Try to open specific contact using addressbook:// URL scheme
            if let url = URL(string: "addressbook://\(contactId)") {
                let success = NSWorkspace.shared.open(url)
                if success {
                    print("✅ Opened Contacts app with contact: \(contactId)")
                } else {
                    print("❌ Failed to open contact with ID, opening Contacts app instead")
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
}

// MARK: - Extensions

extension AIActionType {
    var icon: String {
        switch self {
        case .appleReminders:
            return "list.bullet"
        case .calendar:
            return "calendar"
        case .contacts:
            return "person.crop.circle"
        case .maps:
            return "map"
        }
    }
}

extension ActionStatus {
    var icon: String {
        switch self {
        case .pending:
            return "clock"
        case .executing:
            return "arrow.clockwise"
        case .executed:
            return "checkmark"
        case .failed:
            return "xmark"
        case .reversed:
            return "arrow.counterclockwise"
        }
    }

    var buttonDisplayName: String {
        switch self {
        case .pending:
            return "Execute"
        case .executing:
            return "Running"
        case .executed:
            return "Done"
        case .failed:
            return "Failed"
        case .reversed:
            return "Reversed"
        }
    }
}

// MARK: - Permission Alert Extension
extension EntryDetailView {
    private func showPermissionDeniedAlert(for actionType: AIActionType) {
        let alert = NSAlert()
        alert.messageText = "\(actionType.displayName) Permission Required"

        let settingsURL: String
        let instructions: String

        switch actionType {
        case .calendar:
            settingsURL = "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars"
            instructions = """
            Notate needs Calendar access to create events automatically.

            To enable:
            1. Click "Open Settings" below
            2. Find "Notate" in the list
            3. Toggle it ON
            4. Return to Notate and try again
            """
        case .appleReminders:
            settingsURL = "x-apple.systempreferences:com.apple.preference.security?Privacy_Reminders"
            instructions = """
            Notate needs Reminders access to create tasks automatically.

            To enable:
            1. Click "Open Settings" below
            2. Find "Notate" in the list
            3. Toggle it ON
            4. Return to Notate and try again
            """
        case .contacts:
            settingsURL = "x-apple.systempreferences:com.apple.preference.security?Privacy_Contacts"
            instructions = """
            Notate needs Contacts access to save contact information.

            To enable:
            1. Click "Open Settings" below
            2. Find "Notate" in the list
            3. Toggle it ON
            4. Return to Notate and try again
            """
        case .maps:
            settingsURL = "x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices"
            instructions = """
            Notate needs Location Services to open maps.

            To enable:
            1. Click "Open Settings" below
            2. Find "Notate" in the list
            3. Toggle it ON
            4. Return to Notate and try again
            """
        }

        alert.informativeText = instructions
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open Settings")
        alert.addButton(withTitle: "Cancel")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            if let url = URL(string: settingsURL) {
                NSWorkspace.shared.open(url)
            }
        }
    }
}
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

    var body: some View {
        Group {
            if let entry = entry {
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
                if entry.hasAIProcessing {
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
            // Type and status
            HStack {
                EntryTypeBadge(type: entry.type, size: .medium)

                if entry.isTodo {
                    Spacer()

                    Button(action: { toggleCompletion(entry) }) {
                        HStack(spacing: ModernDesignSystem.Spacing.small) {
                            Image(systemName: entry.status == .done ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 18, weight: .medium))

                            Text(entry.status == .done ? "Completed" : "Open")
                                .font(ModernDesignSystem.Typography.body)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(entry.status == .done ? ModernDesignSystem.Colors.success : ModernDesignSystem.Colors.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }

            // Action buttons
            HStack(spacing: ModernDesignSystem.Spacing.small) {
                ModernButton(
                    title: "Edit",
                    icon: "pencil",
                    style: .secondary,
                    size: .medium
                ) {
                    startEditing(entry)
                }

                ModernButton(
                    title: "Convert",
                    icon: "arrow.triangle.2.circlepath",
                    style: .secondary,
                    size: .medium
                ) {
                    convertEntry(entry)
                }

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
            VStack(alignment: .leading, spacing: ModernDesignSystem.Spacing.medium) {
                HStack {
                    Image(systemName: "info.circle")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(ModernDesignSystem.Colors.accent)

                    Text("Details")
                        .font(ModernDesignSystem.Typography.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(ModernDesignSystem.Colors.primary)
                }

                VStack(spacing: ModernDesignSystem.Spacing.small) {
                    metadataRow(icon: "calendar", label: "Created", value: entry.formattedDate)
                    metadataRow(icon: "keyboard", label: "Trigger", value: entry.triggerUsed)

                    if let sourceApp = entry.sourceApp {
                        metadataRow(icon: "app", label: "Source", value: sourceApp)
                    }

                    if entry.isTodo, let priority = entry.priority {
                        HStack {
                            Image(systemName: "flag")
                                .font(.system(size: 14))
                                .foregroundColor(ModernDesignSystem.Colors.secondary)
                                .frame(width: 20)

                            Text("Priority")
                                .font(ModernDesignSystem.Typography.small)
                                .foregroundColor(ModernDesignSystem.Colors.secondary)
                                .frame(width: 80, alignment: .leading)

                            PriorityIndicator(priority: priority, style: .badge)

                            Spacer()
                        }
                    }

                    if !entry.tags.isEmpty {
                        HStack(alignment: .top) {
                            Image(systemName: "tag")
                                .font(.system(size: 14))
                                .foregroundColor(ModernDesignSystem.Colors.secondary)
                                .frame(width: 20)

                            Text("Tags")
                                .font(ModernDesignSystem.Typography.small)
                                .foregroundColor(ModernDesignSystem.Colors.secondary)
                                .frame(width: 80, alignment: .leading)

                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: ModernDesignSystem.Spacing.tiny) {
                                ForEach(entry.tags, id: \.self) { tag in
                                    ModernTagBadge(tag: tag)
                                }
                            }

                            Spacer()
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
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(ModernDesignSystem.Colors.accent)

                    Text("AI Insights")
                        .font(ModernDesignSystem.Typography.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(ModernDesignSystem.Colors.primary)

                    Spacer()

                    Button("Regenerate") {
                        appState.regenerateAIResearch(for: entry)
                    }
                    .font(ModernDesignSystem.Typography.small)
                    .foregroundColor(ModernDesignSystem.Colors.accent)
                }

                if let aiMetadata = entry.aiMetadata {
                    // Actions
                    if !aiMetadata.actions.isEmpty {
                        aiActionsSection(aiMetadata.actions, for: entry)
                    }

                    // Research
                    if let research = aiMetadata.researchResults {
                        aiResearchSection(research)
                    }

                    // Processing Stats
                    aiStatsSection(aiMetadata)
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

    private func aiActionsSection(_ actions: [AIAction], for entry: Entry) -> some View {
        VStack(alignment: .leading, spacing: ModernDesignSystem.Spacing.small) {
            Text("Suggested Actions")
                .font(ModernDesignSystem.Typography.headline)
                .fontWeight(.medium)
                .foregroundColor(ModernDesignSystem.Colors.primary)

            ForEach(actions, id: \.id) { action in
                aiActionRow(action, for: entry)
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
        .disabled(action.status == .executed)
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
            return !reminderId.isEmpty

        case .calendar:
            // Extract calendar event data
            let title = action.data["title"]?.stringValue ?? entry.content
            let startDate = action.data["startDate"]?.dateValue ?? Date().addingTimeInterval(3600) // 1 hour from now
            let endDate = action.data["endDate"]?.dateValue ?? startDate.addingTimeInterval(3600) // 1 hour duration
            let notes = action.data["notes"]?.stringValue

            let eventId = try await toolService.createCalendarEvent(title: title, notes: notes, startDate: startDate, endDate: endDate)
            return !eventId.isEmpty

        case .contacts:
            // Extract contact data
            let firstName = action.data["firstName"]?.stringValue ?? ""
            let lastName = action.data["lastName"]?.stringValue ?? ""
            let email = action.data["email"]?.stringValue
            let phone = action.data["phone"]?.stringValue

            let contactId = try await toolService.createContact(firstName: firstName, lastName: lastName, phoneNumber: phone, email: email)
            return !contactId.isEmpty

        case .maps:
            // Extract location data
            let query = action.data["query"]?.stringValue ?? entry.content
            try await toolService.openInMaps(address: query)
            return true

        case .webSearch:
            // Extract search query
            let query = action.data["query"]?.stringValue ?? entry.content

            // Perform AI-powered web search analysis
            let searchResult = try await performAIWebSearch(query: query, for: entry)
            return searchResult
        }
    }

    private func performAIWebSearch(query: String, for entry: Entry) async throws -> Bool {
        // Use centralized prompt from PromptManager
        let searchPrompt = PromptManager.webSearchPrompt(query: query)

        do {
            let aiResponse = try await appState.aiService.quickExtraction(searchPrompt)

            // Create comprehensive research results
            let researchResults = ResearchResults(
                content: aiResponse,
                suggestions: [],
                generatedAt: Date(),
                researchCost: 0.02, // Estimate for web search + AI analysis
                processingTimeMs: 0
            )

            // Update the entry with enhanced research
            var updatedMetadata = entry.aiMetadata ?? AIMetadata()
            updatedMetadata.researchResults = researchResults

            // Save updated metadata to database
            await MainActor.run {
                appState.databaseManager.updateEntryAIMetadata(entry.id, metadata: updatedMetadata)
            }

            // Also open the search in browser for user reference
            if let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
               let url = URL(string: "https://www.google.com/search?q=\(encodedQuery)") {
                await MainActor.run {
                    NSWorkspace.shared.open(url)
                }
            }

            return true
        } catch {
            print("❌ Web search AI analysis failed: \(error)")
            return false
        }
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
        case .webSearch:
            return "magnifyingglass"
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
        case .webSearch:
            return // Web search doesn't need permissions
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
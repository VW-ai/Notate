import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var showingAddTrigger = false
    @State private var newTriggerText = ""
    @State private var newTriggerType: EntryType = EntryType.todo
    @State private var newTriggerIsTimer = false
    @State private var claudeApiKey = ""
    @State private var showingApiKeyField = false

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // AI Configuration Section
                aiConfigurationSection
                sectionDivider

                // Trigger Configuration Section
                triggerConfigurationSection
                sectionDivider

                // Tag Colors Section
                tagColorsSection
                sectionDivider

                // System Permissions Section
                systemPermissionsSection
                sectionDivider

                // Capture Settings Section
                captureSettingsSection
                sectionDivider

                // Privacy & Security Section
                privacySecuritySection
                sectionDivider

                // About Section
                aboutSection
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
        }
        .background(Color(hex: "#1C1C1E"))
        .sheet(isPresented: $showingAddTrigger) {
            addTriggerSheet
        }
    }

    private var sectionDivider: some View {
        Rectangle()
            .fill(Color(hex: "#3A3A3C").opacity(0.3))
            .frame(height: 1)
            .padding(.vertical, 24)
    }

    // MARK: - Section Views

    private var aiConfigurationSection: some View {
        modernSectionCard(
            title: "AI Configuration",
            subtitle: "Configure Claude API for intelligent suggestions and actions",
            icon: "brain"
        ) {
            VStack(spacing: 20) {
                modernSettingRow(
                    title: "Claude API Key",
                    subtitle: appState.aiService.isConfigured ? "Configured ✓" : "Not configured",
                    control: AnyView(
                        Button(appState.aiService.isConfigured ? "Update Key" : "Add API Key") {
                            showingApiKeyField.toggle()
                        }
                        .buttonStyle(.bordered)
                    )
                )

                if showingApiKeyField {
                    VStack(spacing: 12) {
                        SecureField("Enter your Claude API key", text: $claudeApiKey)
                            .textFieldStyle(RoundedBorderTextFieldStyle())

                        HStack(spacing: 12) {
                            Button("Cancel") {
                                claudeApiKey = ""
                                showingApiKeyField = false
                            }
                            .buttonStyle(.bordered)

                            Button("Save") {
                                appState.aiService.setAPIKey(claudeApiKey)
                                claudeApiKey = ""
                                showingApiKeyField = false
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(claudeApiKey.isEmpty)
                        }
                    }
                    .padding(.top, 8)
                }

                if !claudeApiKey.isEmpty || appState.aiService.isConfigured {
                    modernSettingRow(
                        title: "Enable AI Processing",
                        subtitle: "Automatically process entries with AI suggestions",
                        control: AnyView(
                            Toggle("", isOn: Binding(
                                get: { getAIProcessingEnabled() },
                                set: { setAIProcessingEnabled($0) }
                            ))
                            .toggleStyle(SwitchToggleStyle())
                        )
                    )

                    if getAIProcessingEnabled() {
                        modernActionButton(title: "Test Connection", icon: "network") {
                            testAIConnection()
                        }

                        // AI Usage Statistics
                        if appState.aiProcessingStats.hasData {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("AI Usage")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)

                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Processed")
                                            .font(.system(size: 10))
                                            .foregroundColor(.secondary)
                                        Text("\(appState.aiProcessingStats.totalProcessed)")
                                            .font(.system(size: 11, weight: .medium))
                                    }

                                    Spacer()

                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text("Cost")
                                            .font(.system(size: 10))
                                            .foregroundColor(.secondary)
                                        Text(appState.aiProcessingStats.formattedCost)
                                            .font(.system(size: 11, weight: .medium))
                                    }
                                }
                            }
                            .padding(.top, 8)
                        }
                    }
                }
            }
        }
    }

    private var triggerConfigurationSection: some View {
        modernSectionCard(
            title: "Trigger Configuration",
            subtitle: "Customize text patterns that activate capture",
            icon: "keyboard"
        ) {
            VStack(spacing: 16) {
                // Trigger list
                ForEach(appState.configManager.configuration.triggers) { trigger in
                    modernTriggerRow(trigger: trigger)
                }

                // Add button
                Button(action: { showingAddTrigger = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16, weight: .medium))
                        Text("Add New Trigger")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(Color(hex: "#1C1C1E"))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(hex: "#FFD60A"))
                    .clipShape(Capsule())
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    private var tagColorsSection: some View {
        modernSectionCard(
            title: "Tag Colors",
            subtitle: "Manage color assignments for your tags",
            icon: "paintpalette"
        ) {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Color Distribution")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)

                    Text("Tags use a smart color distribution algorithm for maximum visual distinction. Regenerate to reassign all tag colors using the improved algorithm.")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(spacing: 12) {
                    modernActionButton(title: "Regenerate All Tag Colors", icon: "arrow.triangle.2.circlepath") {
                        regenerateTagColors()
                    }

                    Spacer()
                }
            }
        }
    }

    private var systemPermissionsSection: some View {
        modernSectionCard(
            title: "System Permissions",
            subtitle: "Manage app permissions for AI actions",
            icon: "shield.checkered"
        ) {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Calendar & Reminders")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)

                    Text("Grant permissions to allow AI to create calendar events and reminders automatically.")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 12) {
                        modernActionButton(title: "Calendar Permissions", icon: "calendar") {
                            openCalendarPermissions()
                        }

                        modernActionButton(title: "Reminders Permissions", icon: "checklist") {
                            openRemindersPermissions()
                        }

                        Spacer()
                    }
                }
                .padding(.vertical, 8)

                Divider()

                VStack(alignment: .leading, spacing: 12) {
                    Text("Contacts")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)

                    Text("Grant permission to allow AI to save contact information from your entries.")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    modernActionButton(title: "Contacts Permissions", icon: "person.crop.circle") {
                        openContactsPermissions()
                    }
                }
                .padding(.vertical, 8)

                Divider()

                VStack(alignment: .leading, spacing: 12) {
                    Text("Location Services")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)

                    Text("Grant permission for location-based features and maps integration.")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    modernActionButton(title: "Location Permissions", icon: "location") {
                        openLocationPermissions()
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }

    private var captureSettingsSection: some View {
        modernSectionCard(
            title: "Capture Settings",
            subtitle: "Configure how Notate captures your input",
            icon: "wand.and.rays"
        ) {
            VStack(spacing: 20) {
                modernSettingRow(
                    title: "Auto-clear input",
                    subtitle: "Clear text field after successful capture",
                    control: AnyView(
                        Toggle("", isOn: Binding(
                            get: { appState.configManager.configuration.autoClearInput },
                            set: { appState.configManager.updateAutoClearInput($0) }
                        ))
                        .toggleStyle(SwitchToggleStyle())
                    )
                )

                modernSettingRow(
                    title: "Capture timeout",
                    subtitle: "\(Int(appState.configManager.configuration.captureTimeout)) seconds",
                    control: AnyView(
                        Slider(value: Binding(
                            get: { appState.configManager.configuration.captureTimeout },
                            set: { appState.configManager.updateCaptureTimeout($0) }
                        ), in: 1...10, step: 0.5)
                        .frame(width: 120)
                    )
                )

                modernSettingRow(
                    title: "IME composing support",
                    subtitle: "Better support for Chinese/Japanese input",
                    control: AnyView(
                        Toggle("", isOn: Binding(
                            get: { appState.configManager.configuration.enableIMEComposing },
                            set: { appState.configManager.updateIMEComposing($0) }
                        ))
                        .toggleStyle(SwitchToggleStyle())
                    )
                )
            }
        }
    }

    private var privacySecuritySection: some View {
        modernSectionCard(
            title: "Privacy & Security",
            subtitle: "Manage your data and privacy settings",
            icon: "lock.shield"
        ) {
            VStack(spacing: 20) {
                modernSettingRow(
                    title: "Redaction mode",
                    subtitle: "Blur content in screenshots",
                    control: AnyView(
                        Toggle("", isOn: Binding(
                            get: { appState.configManager.configuration.redactionMode },
                            set: { appState.configManager.updateRedactionMode($0) }
                        ))
                        .toggleStyle(SwitchToggleStyle())
                    )
                )

                HStack(spacing: 12) {
                    modernActionButton(title: "Export Data", icon: "square.and.arrow.up") {
                        exportData()
                    }

                    modernActionButton(title: "Clear All Data", icon: "trash", style: .destructive) {
                        clearAllData()
                    }

                    Spacer()
                }
            }
        }
    }

    private var aboutSection: some View {
        modernSectionCard(
            title: "About Notate",
            subtitle: "Version and system information",
            icon: "info.circle"
        ) {
            VStack(spacing: 16) {
                modernInfoRow(label: "Version", value: "1.0.0")
                modernInfoRow(label: "Database", value: "~/Library/Application Support/Notate/")
            }
        }
    }

    private var addTriggerSheet: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Add New Trigger")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                Button(action: {
                    showingAddTrigger = false
                    newTriggerText = ""
                    newTriggerType = .todo
                    newTriggerIsTimer = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 20)

            // Divider
            Rectangle()
                .fill(Color(hex: "#3A3A3C").opacity(0.3))
                .frame(height: 1)

            // Form
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Trigger Text")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                    TextField("e.g., !!!", text: $newTriggerText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }

                // Type selector: Note or Timer
                VStack(alignment: .leading, spacing: 8) {
                    Text("Trigger Type")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)

                    HStack(spacing: 12) {
                        // Note button
                        Button(action: {
                            newTriggerIsTimer = false
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "note.text")
                                    .font(.system(size: 12))
                                Text("Note")
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundColor(newTriggerIsTimer ? .white.opacity(0.6) : Color(hex: "#1C1C1E"))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(newTriggerIsTimer ? Color(hex: "#3A3A3C") : Color(hex: "#FFD60A"))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)

                        // Timer button
                        Button(action: {
                            newTriggerIsTimer = true
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "timer")
                                    .font(.system(size: 12))
                                Text("Timer")
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundColor(newTriggerIsTimer ? Color(hex: "#1C1C1E") : .white.opacity(0.6))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(newTriggerIsTimer ? Color(hex: "#FFD60A") : Color(hex: "#3A3A3C"))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)

                        Spacer()
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 24)

            Spacer()

            // Actions
            Rectangle()
                .fill(Color(hex: "#3A3A3C").opacity(0.3))
                .frame(height: 1)

            HStack(spacing: 12) {
                Spacer()

                Button("Cancel") {
                    showingAddTrigger = false
                    newTriggerText = ""
                    newTriggerType = .todo
                    newTriggerIsTimer = false
                }
                .foregroundColor(.white.opacity(0.9))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(hex: "#3A3A3C"))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .buttonStyle(.plain)

                Button("Add Trigger") {
                    if !newTriggerText.isEmpty && appState.configManager.validateTrigger(newTriggerText) {
                        appState.configManager.addTrigger(newTriggerText, defaultType: .todo, isTimerTrigger: newTriggerIsTimer)
                        showingAddTrigger = false
                        newTriggerText = ""
                        newTriggerType = .todo
                        newTriggerIsTimer = false
                    }
                }
                .foregroundColor(Color(hex: "#1C1C1E"))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(hex: "#FFD60A"))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .buttonStyle(.plain)
                .disabled(newTriggerText.isEmpty || !appState.configManager.validateTrigger(newTriggerText))
                .opacity((newTriggerText.isEmpty || !appState.configManager.validateTrigger(newTriggerText)) ? 0.5 : 1.0)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .frame(width: 450, height: 340)
        .background(Color(hex: "#2C2C2E"))
        .cornerRadius(12)
    }

    // MARK: - Modern Components

    @ViewBuilder
    private func modernSectionCard<Content: View>(
        title: String,
        subtitle: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // Section header
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Color(hex: "#FFD60A"))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)

                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            // Content
            content()
        }
        .padding(.vertical, 16)
    }

    private func modernSettingRow(title: String, subtitle: String, control: AnyView) -> some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            Spacer()

            control
        }
        .padding(.vertical, 4)
    }

    private func modernTriggerRow(trigger: TriggerConfig) -> some View {
        HStack(spacing: 16) {
            // Trigger display
            Text(trigger.trigger)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(Color(hex: "#FFD60A"))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(hex: "#FFD60A").opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 6))

            // Type badge (show "Timer" for timer triggers)
            Text(trigger.isTimerTrigger ? "Timer" : trigger.defaultType.displayName)
                .font(.system(size: 12, weight: .medium))
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color(hex: "#3A3A3C"))
                .foregroundColor(.white.opacity(0.8))
                .clipShape(Capsule())

            Spacer()

            // Controls
            HStack(spacing: 12) {
                Toggle("", isOn: Binding(
                    get: { trigger.isEnabled },
                    set: { appState.configManager.updateTrigger(id: trigger.id, isEnabled: $0) }
                ))
                .toggleStyle(SwitchToggleStyle())

                // Delete button
                Button(action: {
                    deleteTrigger(trigger: trigger)
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundColor(.red.opacity(0.8))
                }
                .buttonStyle(.plain)
            }
        }
        .opacity(trigger.isEnabled ? 1.0 : 0.6)
    }

    private func modernActionButton(title: String, icon: String, style: ModernButtonStyle = .normal, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                Text(title)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(style == .destructive ? .white : .white.opacity(0.9))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(style == .destructive ? Color.red : Color(hex: "#3A3A3C"))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func modernInfoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)

            Spacer()

            Text(value)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }

    enum ModernButtonStyle {
        case normal, destructive
    }

    // MARK: - Helper Functions

    private func getAIProcessingEnabled() -> Bool {
        return UserDefaults.standard.bool(forKey: "aiProcessingEnabled")
    }

    private func setAIProcessingEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: "aiProcessingEnabled")
    }

    private func testAIConnection() {
        Task {
            do {
                print("🧪 Testing AI connection...")
                let testResult = try await appState.aiService.quickExtraction("Test: Reply with just 'OK' if this works")
                await MainActor.run {
                    let alert = NSAlert()
                    alert.messageText = "AI Connection Test"
                    alert.informativeText = "✅ Success! Response: \(testResult)"
                    alert.alertStyle = .informational
                    alert.runModal()
                }
                print("✅ AI connection test successful: \(testResult)")
            } catch {
                await MainActor.run {
                    let alert = NSAlert()
                    alert.messageText = "AI Connection Test"
                    alert.informativeText = "❌ Failed: \(error.localizedDescription)"
                    alert.alertStyle = .warning
                    alert.runModal()
                }
                print("❌ AI connection test failed: \(error)")
            }
        }
    }

    private func exportData() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType.json]
        panel.nameFieldStringValue = "notate-export-\(Date().timeIntervalSince1970).json"
        
        if panel.runModal() == .OK, let url = panel.url {
            if let data = appState.databaseManager.exportToJSON() {
                try? data.write(to: url)
            }
        }
    }
    
    private func clearAllData() {
        let alert = NSAlert()
        alert.messageText = "Clear All Data"
        alert.informativeText = "This will permanently delete all your captured entries. This action cannot be undone."
        alert.addButton(withTitle: "Clear All")
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = .warning

        if alert.runModal() == .alertFirstButtonReturn {
            // Clear all entries from database
            for entry in appState.entries {
                appState.databaseManager.deleteEntry(id: entry.id)
            }
        }
    }

    private func deleteTrigger(trigger: TriggerConfig) {
        let alert = NSAlert()
        alert.messageText = "Delete Trigger"
        alert.informativeText = "Are you sure you want to delete the trigger '\(trigger.trigger)'?"
        alert.addButton(withTitle: "Delete")
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = .warning

        if alert.runModal() == .alertFirstButtonReturn {
            appState.configManager.removeTrigger(id: trigger.id)
        }
    }

    private func regenerateTagColors() {
        let alert = NSAlert()
        alert.messageText = "Regenerate Tag Colors"
        alert.informativeText = "This will reassign colors to all your tags using the improved distribution algorithm for better visual distinction. Your tags will keep the same names, only colors will change."
        alert.addButton(withTitle: "Regenerate")
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = .informational

        if alert.runModal() == .alertFirstButtonReturn {
            TagColorManager.shared.reassignAllColors()

            // Show success feedback
            let successAlert = NSAlert()
            successAlert.messageText = "Tag Colors Regenerated"
            successAlert.informativeText = "All tag colors have been reassigned for maximum visual distinction."
            successAlert.alertStyle = .informational
            successAlert.runModal()
        }
    }

    // MARK: - Permission Helpers

    private func openCalendarPermissions() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") {
            NSWorkspace.shared.open(url)
        }
    }

    private func openRemindersPermissions() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Reminders") {
            NSWorkspace.shared.open(url)
        }
    }

    private func openContactsPermissions() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Contacts") {
            NSWorkspace.shared.open(url)
        }
    }

    private func openLocationPermissions() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices") {
            NSWorkspace.shared.open(url)
        }
    }
}

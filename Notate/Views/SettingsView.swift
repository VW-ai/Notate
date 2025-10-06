import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var showingAddTrigger = false
    @State private var newTriggerText = ""
    @State private var newTriggerType: EntryType = EntryType.todo

    var body: some View {
        VStack(spacing: 0) {
            // Custom header
            settingsHeader

            // Content with proper spacing
            ScrollView {
                LazyVStack(spacing: 32) {
                    // Trigger Configuration Section
                    triggerConfigurationSection

                    // Capture Settings Section
                    captureSettingsSection

                    // Privacy & Security Section
                    privacySecuritySection

                    // About Section
                    aboutSection
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 24)
            }
            .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
        }
        .frame(width: 700, height: 600)
        .background(Color(NSColor.windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .sheet(isPresented: $showingAddTrigger) {
            addTriggerSheet
        }
    }

    // MARK: - Header

    private var settingsHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Settings")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text("Configure Notate to match your workflow")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.secondary)
                    .background(Color.clear)
            }
            .buttonStyle(PlainButtonStyle())
            .keyboardShortcut(.escape)
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 20)
        .background(Color(NSColor.windowBackgroundColor))
    }

    // MARK: - Section Views

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
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.accentColor)
                    .clipShape(Capsule())
                }
                .buttonStyle(PlainButtonStyle())
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
        VStack(spacing: 24) {
            // Header
            HStack {
                Text("Add New Trigger")
                    .font(.system(size: 20, weight: .semibold))

                Spacer()

                Button("Cancel") {
                    showingAddTrigger = false
                    newTriggerText = ""
                    newTriggerType = .todo
                }
            }

            // Form
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Trigger Text")
                        .font(.system(size: 14, weight: .medium))
                    TextField("e.g., !!!", text: $newTriggerText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Default Type")
                        .font(.system(size: 14, weight: .medium))
                    Picker("Type", selection: $newTriggerType) {
                        ForEach(EntryType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }

            // Actions
            HStack(spacing: 12) {
                Button("Cancel") {
                    showingAddTrigger = false
                    newTriggerText = ""
                    newTriggerType = .todo
                }
                .buttonStyle(.bordered)

                Button("Add Trigger") {
                    if !newTriggerText.isEmpty && appState.configManager.validateTrigger(newTriggerText) {
                        appState.configManager.addTrigger(newTriggerText, defaultType: newTriggerType)
                        showingAddTrigger = false
                        newTriggerText = ""
                        newTriggerType = .todo
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(newTriggerText.isEmpty || !appState.configManager.validateTrigger(newTriggerText))
            }

            Spacer()
        }
        .padding(24)
        .frame(width: 400, height: 300)
        .background(Color(NSColor.windowBackgroundColor))
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
                    .foregroundColor(.accentColor)
                    .frame(width: 32, height: 32)
                    .background(Color.accentColor.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)

                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            // Content
            content()
        }
        .padding(24)
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
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
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.accentColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 6))

            // Type badge
            Text(trigger.defaultType.displayName)
                .font(.system(size: 12, weight: .medium))
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(trigger.defaultType == .todo ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                .foregroundColor(trigger.defaultType == .todo ? .green : .orange)
                .clipShape(Capsule())

            Spacer()

            // Controls
            Toggle("", isOn: Binding(
                get: { trigger.isEnabled },
                set: { appState.configManager.updateTrigger(id: trigger.id, isEnabled: $0) }
            ))
            .toggleStyle(SwitchToggleStyle())
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
            .foregroundColor(style == .destructive ? .white : .primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(style == .destructive ? Color.red : Color(NSColor.quaternarySystemFill))
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
}

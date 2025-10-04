import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingAddTrigger = false
    @State private var newTriggerText = ""
    @State private var newTriggerType: EntryType = EntryType.todo
    
    var body: some View {
        NavigationView {
            Form {
                // Trigger Configuration Section
                Section("Trigger Configuration") {
                    ForEach(appState.configManager.configuration.triggers) { trigger in
                        TriggerRowView(trigger: trigger)
                    }
                    
                    Button("Add New Trigger") {
                        showingAddTrigger = true
                    }
                }
                
                // Capture Settings Section
                Section("Capture Settings") {
                    Toggle("Auto-clear input after capture", 
                           isOn: Binding(
                            get: { appState.configManager.configuration.autoClearInput },
                            set: { appState.configManager.updateAutoClearInput($0) }
                           ))
                    
                    VStack(alignment: .leading) {
                        Text("Capture timeout: \(Int(appState.configManager.configuration.captureTimeout)) seconds")
                        Slider(value: Binding(
                            get: { appState.configManager.configuration.captureTimeout },
                            set: { appState.configManager.updateCaptureTimeout($0) }
                        ), in: 1...10, step: 0.5)
                    }
                    
                    Toggle("Enable IME composing support", 
                           isOn: Binding(
                            get: { appState.configManager.configuration.enableIMEComposing },
                            set: { appState.configManager.updateIMEComposing($0) }
                           ))
                }
                
                // Privacy & Security Section
                Section("Privacy & Security") {
                    Toggle("Redaction mode (for screenshots)", 
                           isOn: Binding(
                            get: { appState.configManager.configuration.redactionMode },
                            set: { appState.configManager.updateRedactionMode($0) }
                           ))
                    
                    Button("Export Data") {
                        exportData()
                    }
                    
                    Button("Clear All Data", role: .destructive) {
                        clearAllData()
                    }
                }
                
                // About Section
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Database Location")
                        Spacer()
                        Text("~/Library/Application Support/Notate/")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingAddTrigger) {
                AddTriggerView(
                    triggerText: $newTriggerText,
                    triggerType: $newTriggerType,
                    isPresented: $showingAddTrigger
                )
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
}

struct TriggerRowView: View {
    let trigger: TriggerConfig
    @EnvironmentObject var appState: AppState
    @State private var isEditing = false
    @State private var editedTrigger = ""
    @State private var editedType: EntryType = EntryType.todo
    
    var body: some View {
        HStack {
            if isEditing {
                TextField("Trigger", text: $editedTrigger)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 80)
                
                Picker("Type", selection: $editedType) {
                    ForEach(EntryType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(width: 100)
                
                Button("Save") {
                    saveChanges()
                }
                .buttonStyle(BorderlessButtonStyle())
                
                Button("Cancel") {
                    cancelEditing()
                }
                .buttonStyle(BorderlessButtonStyle())
            } else {
                Text(trigger.trigger)
                    .font(.system(.body, design: .monospaced))
                    .frame(width: 80, alignment: .leading)
                
                Text(trigger.defaultType.displayName)
                    .foregroundColor(.secondary)
                    .frame(width: 100, alignment: .leading)
                
                Spacer()
                
                Toggle("", isOn: Binding(
                    get: { trigger.isEnabled },
                    set: { appState.configManager.updateTrigger(id: trigger.id, isEnabled: $0) }
                ))
                
                Button("Edit") {
                    startEditing()
                }
                .buttonStyle(BorderlessButtonStyle())
                
                Button("Delete", role: .destructive) {
                    appState.configManager.removeTrigger(id: trigger.id)
                }
                .buttonStyle(BorderlessButtonStyle())
            }
        }
    }
    
    private func startEditing() {
        editedTrigger = trigger.trigger
        editedType = trigger.defaultType
        isEditing = true
    }
    
    private func saveChanges() {
        if appState.configManager.validateTrigger(editedTrigger) || editedTrigger == trigger.trigger {
            appState.configManager.updateTrigger(
                id: trigger.id,
                trigger: editedTrigger,
                defaultType: editedType
            )
            isEditing = false
        }
    }
    
    private func cancelEditing() {
        isEditing = false
    }
}

struct AddTriggerView: View {
    @Binding var triggerText: String
    @Binding var triggerType: EntryType
    @Binding var isPresented: Bool
    @EnvironmentObject var appState: AppState
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Add New Trigger")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Trigger Text")
                    .font(.headline)
                
                TextField("e.g., ;;, ,,,, ///", text: $triggerText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: triggerText) { _ in
                        validateTrigger()
                    }
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Default Type")
                    .font(.headline)
                
                Picker("Type", selection: $triggerType) {
                    ForEach(EntryType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.escape)
                
                Spacer()
                
                Button("Add Trigger") {
                    addTrigger()
                }
                .keyboardShortcut(.return)
                .disabled(!isValidTrigger)
            }
        }
        .padding()
        .frame(width: 400, height: 300)
    }
    
    private var isValidTrigger: Bool {
        return !triggerText.isEmpty && errorMessage.isEmpty
    }
    
    private func validateTrigger() {
        if triggerText.isEmpty {
            errorMessage = ""
        } else if !appState.configManager.validateTrigger(triggerText) {
            errorMessage = "Trigger already exists or contains invalid characters"
        } else {
            errorMessage = ""
        }
    }
    
    private func addTrigger() {
        appState.configManager.addTrigger(triggerText, defaultType: triggerType)
        triggerText = ""
        triggerType = EntryType.todo
        isPresented = false
    }
}

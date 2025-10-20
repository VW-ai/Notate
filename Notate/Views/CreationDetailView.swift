import SwiftUI

// MARK: - Creation Detail View
// Temporary detail view for creating new entries/events with flashing shadow alert

struct CreationDetailView: View {
    @StateObject private var operatorState = OperatorState.shared
    @EnvironmentObject var appState: AppState
    @StateObject private var tagColorManager = TagColorManager.shared
    @StateObject private var calendarService = CalendarService.shared

    @State private var content: String = ""
    @State private var tagInput: String = ""
    @State private var tags: [String] = []
    @State private var startTime: Date = Date()
    @State private var endTime: Date = Date().addingTimeInterval(3600) // Default 1 hour
    @State private var shadowOpacity: Double = 0.3
    @State private var isFlashing: Bool = true

    private var creationMode: CreationMode? {
        operatorState.creationMode
    }

    private var isEntry: Bool {
        creationMode == .entry
    }

    private var isEvent: Bool {
        creationMode == .event || creationMode == .timer
    }

    // Get tag suggestions from unified TagStore (universal, not date-dependent)
    private var tagSuggestions: [String] {
        TagStore.shared.searchTags(tagInput, excluding: tags)
    }

    var body: some View {
        GeometryReader { geometry in
            let topHeaderHeight: CGFloat = 150

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: topHeaderHeight)

                    mainContentSection
                }
                .frame(minHeight: geometry.size.height)
            }
        }
        .background(Color(hex: "#1C1C1E"))
        .overlay(flashingShadowOverlay)
        .transition(.asymmetric(
            insertion: .scale(scale: 0.8).combined(with: .opacity),
            removal: .scale(scale: 0.9).combined(with: .opacity)
        ))
        .onAppear {
            loadTimerData()
            startFlashing()
        }
        .onDisappear {
            isFlashing = false
        }
    }

    // MARK: - Flashing Shadow Overlay

    private var flashingShadowOverlay: some View {
        Rectangle()
            .stroke(Color.clear, lineWidth: 0)
            .shadow(
                color: shadowColor.opacity(shadowOpacity),
                radius: 8,
                x: 0,
                y: 0
            )
            .shadow(color: shadowColor.opacity(shadowOpacity), radius: 4, x: 2, y: 0)
            .shadow(color: shadowColor.opacity(shadowOpacity), radius: 4, x: -2, y: 0)
            .shadow(color: shadowColor.opacity(shadowOpacity), radius: 4, x: 0, y: 2)
            .shadow(color: shadowColor.opacity(shadowOpacity), radius: 4, x: 0, y: -2)
    }

    private var shadowColor: Color {
        isEntry ? Color(hex: "#7CB342") : Color(hex: "#8B7355")
    }

    private func startFlashing() {
        withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
            shadowOpacity = isFlashing ? 0.6 : 0.3
        }
    }

    // MARK: - Main Content Section

    private var mainContentSection: some View {
        HStack(alignment: .top, spacing: 0) {
            // Left spacer - tap to cancel
            Spacer()
                .contentShape(Rectangle())
                .onTapGesture {
                    operatorState.cancelCreation()
                }

            // Content
            VStack(alignment: .leading, spacing: 24) {
                closeButton
                titleSection
                if isEvent {
                    timeRangeSection
                }
                tagsSection
                actionButtons
            }
            .padding(32)
            .padding(.bottom, 60)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Close Button

    private var closeButton: some View {
        HStack {
            Spacer()
            Button(action: {
                operatorState.cancelCreation()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    // MARK: - Title Section

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(isEntry ? "New Input" : "New Event")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)

            if isEntry {
                TextEditor(text: $content)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                    .frame(minHeight: 100)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
            } else {
                TextField("Event title", text: $content)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
    }

    // MARK: - Time Range Section (Event Only)

    private var timeRangeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Start Time
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.system(size: 12))
                        .foregroundColor(.yellow)
                    Text("Start")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }

                DatePicker("", selection: $startTime)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .font(.system(size: 13, weight: .semibold))
                    .scaleEffect(x: 1.15, y: 1.0, anchor: .leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .onChange(of: startTime) { newValue in
                        // Auto-adjust end time if it's before start
                        if endTime < newValue {
                            endTime = newValue.addingTimeInterval(3600)
                        }
                    }
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.yellow.opacity(0.08)))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.yellow.opacity(0.25), lineWidth: 1))

            // End Time
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.system(size: 12))
                        .foregroundColor(.yellow)
                    Text("End")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }

                DatePicker("", selection: $endTime)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .font(.system(size: 13, weight: .semibold))
                    .scaleEffect(x: 1.15, y: 1.0, anchor: .leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.yellow.opacity(0.08)))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.yellow.opacity(0.25), lineWidth: 1))

            // Duration display
            HStack(spacing: 6) {
                Image(systemName: "timer")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Text("Duration: \(formattedDuration)")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            .padding(.leading, 22)
        }
    }

    private var formattedDuration: String {
        let duration = endTime.timeIntervalSince(startTime)
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        return String(format: "%dh %02dm", hours, minutes)
    }

    // MARK: - Tags Section

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tags")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)

            // Existing tags
            if !tags.isEmpty {
                existingTagsRow
            }

            // Tag input
            tagInputField

            // Tag suggestions
            if !tagSuggestions.isEmpty {
                suggestionsRow
            }
        }
    }

    private var existingTagsRow: some View {
        HStack(spacing: 6) {
            ForEach(tags, id: \.self) { tag in
                tagPill(tag: tag, removable: true)
            }
        }
    }

    private var tagInputField: some View {
        TextField("Add tag...", text: $tagInput, onCommit: addTag)
            .textFieldStyle(PlainTextFieldStyle())
            .font(.system(size: 14))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
    }

    private var suggestionsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(tagSuggestions.prefix(8), id: \.self) { tag in
                    tagSuggestionButton(tag: tag)
                }
            }
        }
    }

    private func tagPill(tag: String, removable: Bool) -> some View {
        HStack(spacing: 4) {
            Text("#\(tag)")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)

            if removable {
                Button(action: {
                    tags.removeAll { $0 == tag }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(tagColorManager.getColorForTag(tag)?.opacity(0.8) ?? Color.gray.opacity(0.8))
        )
    }

    private func tagSuggestionButton(tag: String) -> some View {
        Button(action: {
            if !tags.contains(tag) {
                tags.append(tag)
                tagColorManager.registerTag(tag)
            }
        }) {
            Text("#\(tag)")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .strokeBorder(Color.secondary.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func addTag() {
        let trimmedTag = tagInput.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")

        if !trimmedTag.isEmpty && !tags.contains(trimmedTag) {
            tags.append(trimmedTag)
            tagColorManager.registerTag(trimmedTag)
        }

        tagInput = ""
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 16) {
            // Cancel Button
            Button(action: {
                operatorState.cancelCreation()
            }) {
                HStack {
                    Image(systemName: "xmark")
                        .font(.system(size: 14))
                    Text("Cancel")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(.red)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.red.opacity(0.5), lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())

            Spacer()

            // Confirm Button
            Button(action: {
                confirmCreation()
            }) {
                HStack {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14))
                    Text("Confirm")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isEntry ? Color(hex: "#7CB342") : Color(hex: "#8B7355"))
                )
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(content.isEmpty)
            .opacity(content.isEmpty ? 0.5 : 1.0)
        }
    }

    // MARK: - Actions

    private func loadTimerData() {
        if creationMode == .timer {
            // Pre-populate with timer data
            content = operatorState.timerEventName
            tags = operatorState.timerTags
            if let timerStart = operatorState.timerStartTime {
                startTime = timerStart
                endTime = Date()
            }
        }
    }

    private func confirmCreation() {
        if isEntry {
            createEntry()
        } else if isEvent {
            createEvent()
        }

        operatorState.confirmCreation()
    }

    private func createEntry() {
        guard !content.isEmpty else { return }

        let newEntry = Entry(
            type: .piece,
            content: content,
            tags: tags,
            triggerUsed: "operator_panel"
        )

        appState.databaseManager.saveEntry(newEntry)

        // Trigger AI processing
        if appState.aiService.isConfigured {
            appState.processEntryWithAI(newEntry)
        }

        print("✅ Created new entry from operator panel")
    }

    private func createEvent() {
        guard !content.isEmpty else { return }

        Task {
            do {
                let toolService = ToolService()
                let tagsString = tags.isEmpty ? "" : "[tags: \(tags.joined(separator: ", "))]"

                _ = try await toolService.createCalendarEvent(
                    title: content,
                    notes: tagsString,
                    startDate: startTime,
                    endDate: endTime
                )

                await MainActor.run {
                    calendarService.fetchEvents(for: startTime)
                    print("✅ Created new event from operator panel")
                }
            } catch {
                print("❌ Failed to create event: \(error)")
            }
        }
    }
}

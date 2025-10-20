import SwiftUI

// MARK: - Timeline Main View
// Chronological timeline showing Pieces and Calendar Events

struct TimelineView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var calendarService = CalendarService.shared
    @StateObject private var tagDragState = TagDragState.shared
    @StateObject private var operatorState = OperatorState.shared
    @State private var selectedDate = Date()
    @State private var showTagPanel = true // Show tag panel by default

    // Track if detail panel is shown
    private var isDetailPanelPresented: Bool {
        appState.selectedEntry != nil || appState.selectedEvent != nil
    }

    // Track if creation detail panel is shown
    private var isCreationPanelPresented: Bool {
        operatorState.creationMode != nil
    }

    // Header height constants
    private let headerTopSpace: CGFloat = 80
    private let datePickerHeight: CGFloat = 70
    private var totalHeaderHeight: CGFloat {
        headerTopSpace + datePickerHeight
    }

    // Calculate tag panel width based on available screen space
    private func calculateTagPanelWidth(screenWidth: CGFloat) -> CGFloat? {
        // Tag panel should fit within the left quarter (25%) of the screen
        // Scale based on screen size to avoid overflow on smaller screens
        let leftQuarterWidth = screenWidth * 0.25

        if screenWidth >= 1600 {
            // Large screens: use most of the left quarter (max 90%)
            return min(leftQuarterWidth * 0.9, 360)
        } else if screenWidth >= 1200 {
            // Medium-large screens: use up to 85% of left quarter
            return min(leftQuarterWidth * 0.85, 280)
        } else if screenWidth >= 900 {
            // Medium screens: use up to 80% of left quarter
            return min(leftQuarterWidth * 0.8, 200)
        } else {
            // Small screens: use most of the available space
            return min(leftQuarterWidth * 0.75, 180)
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
            // Main content layer (timeline + detail panel)
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Main Timeline Content - ALWAYS in right half, never moves
                    HStack(spacing: 0) {
                        Spacer() // Pushes timeline to right half

                        VStack(spacing: 0) {
                            // Spacer for date navigation header
                            Spacer()
                                .frame(height: totalHeaderHeight)

                            // Timeline content
                            timelineContent(geometry: geometry)
                        }
                        .frame(width: geometry.size.width / 2)
                    }

                    // Detail Panel Area - occupies the quarter immediately left of timeline
                    // Contains: Detail view (top 70%) + Operator view (bottom 30%)
                    HStack(spacing: 0) {
                        // Left quarter - empty space (for tag panel)
                        Spacer()
                            .frame(width: geometry.size.width * 0.25)

                        // Second quarter - detail + operator panel area
                        VStack(spacing: 0) {
                            // Top 70%: Detail view or creation detail
                            ZStack {
                                Color(hex: "#1C1C1E")

                                if isCreationPanelPresented {
                                    // Creation detail view (higher priority)
                                    CreationDetailView()
                                        .environmentObject(appState)
                                } else if isDetailPanelPresented {
                                    // Regular detail view
                                    if let selectedEntry = appState.selectedEntry {
                                        SimpleEntryDetailView(entry: selectedEntry)
                                            .environmentObject(appState)
                                            .id("\(selectedEntry.id)-\(selectedEntry.isPinned)")
                                    } else if let selectedEvent = appState.selectedEvent {
                                        SimpleEventDetailView(event: selectedEvent)
                                            .environmentObject(appState)
                                            .id(selectedEvent.id)
                                    }
                                }
                            }
                            .frame(height: geometry.size.height * 0.7)
                            .transition(.move(edge: .leading))

                            // Bottom 30%: Operator view (always visible)
                            OperatorView()
                                .frame(height: geometry.size.height * 0.3)
                                .environmentObject(appState)
                        }
                        .frame(width: geometry.size.width * 0.25)

                        Spacer() // Fills the rest (timeline's space - right half)
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: isDetailPanelPresented)
                .animation(.easeInOut(duration: 0.3), value: isCreationPanelPresented)
            }

            // Tag Management Panel (overlay on left side, behind detail panel)
            // Uses full vertical height (100%)
            if showTagPanel {
                GeometryReader { geometry in
                    HStack(spacing: 0) {
                        VStack(spacing: 0) {
                            // Spacer to avoid date navigation header
                            Spacer()
                                .frame(height: totalHeaderHeight)

                            // Responsive width: prefer to use available space, but respect minimums
                            TagManagementPanel(availableWidth: calculateTagPanelWidth(screenWidth: geometry.size.width))
                                .environmentObject(appState)
                        }
                        .transition(.move(edge: .leading))

                        Spacer()
                            .allowsHitTesting(false) // Allow clicks through the spacer to timeline below
                    }
                    .animation(.easeInOut(duration: 0.3), value: showTagPanel)
                }
                .allowsHitTesting(true) // Panel itself can receive hits
                .zIndex(10) // Below detail panel (which is in the main content layer)
            }

            // Date navigation header (always on top)
            dateNavigationHeader
                .zIndex(100)

            // Global mouse tracking overlay for tag dragging
            if tagDragState.isDragging {
                Color.clear
                    .contentShape(Rectangle())
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .gesture(
                        TapGesture().onEnded {
                            // Click on empty space - cancel drag
                            tagDragState.stopDragging()
                        }
                    )
                    .overlay(
                        FloatingTagsCursor(
                            tags: tagDragState.draggingTags,
                            position: tagDragState.cursorPosition
                        )
                    )
                    .zIndex(200)
            }
        }
        .onAppear {
            calendarService.fetchEvents(for: selectedDate)
        }
        .onChange(of: selectedDate) { newDate in
            calendarService.fetchEvents(for: newDate)
        }
    }

    // MARK: - Timeline Content

    @ViewBuilder
    private func timelineContent(geometry: GeometryProxy) -> some View {
        // Timeline scroll view - takes full width given to it
        ScrollView {
                    VStack(spacing: NotateDesignSystem.Spacing.space5) {
                        // Pinned section
                        if !pinnedPieces.isEmpty || !pinnedEvents.isEmpty {
                            TimePeriodSection(
                                title: "Pinned",
                                icon: "📌",
                                pieces: pinnedPieces,
                                events: pinnedEvents,
                                selectedDate: selectedDate
                            )
                        }

                        // Midnight section (12am - 6am)
                        TimePeriodSection(
                            title: "Midnight",
                            icon: "🌃",
                            pieces: midnightPieces,
                            events: midnightEvents,
                            selectedDate: selectedDate
                        )

                        TimePeriodSection(
                            title: "Morning",
                            icon: "🌅",
                            pieces: morningPieces,
                            events: morningEvents,
                            selectedDate: selectedDate
                        )

                        // Afternoon section (12pm - 6pm)
                        TimePeriodSection(
                            title: "Afternoon",
                            icon: "☀️",
                            pieces: afternoonPieces,
                            events: afternoonEvents,
                            selectedDate: selectedDate
                        )

                        // Evening section (6pm - 12am)
                        TimePeriodSection(
                            title: "Evening",
                            icon: "🌙",
                            pieces: eveningPieces,
                            events: eveningEvents,
                            selectedDate: selectedDate
                        )
                    }
            .padding(.horizontal, NotateDesignSystem.Spacing.space6)
            .padding(.vertical, NotateDesignSystem.Spacing.space4)
        }
        .background(Color(hex: "#1C1C1E"))
    }

    // MARK: - Date Navigation Header

    private var dateNavigationHeader: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: headerTopSpace)

            // Date picker with tag panel toggle
            HStack(spacing: 0) {
                // Tag panel toggle button
                Button(action: {
                    withAnimation {
                        showTagPanel.toggle()
                    }
                }) {
                    Image(systemName: showTagPanel ? "tag.fill" : "tag")
                        .font(.system(size: 18))
                        .foregroundColor(showTagPanel ? Color(hex: "#FFB84D") : .secondary)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.leading, 16)

                // Date picker - evenly distributed across remaining screen
                datePickerStrip
            }
            .padding(.bottom, NotateDesignSystem.Spacing.space4)
        }
        .background(Color(hex: "#1C1C1E")) // Same as main background
    }

    // MARK: - Date Picker Strip

    private var datePickerStrip: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                ForEach(-3...3, id: \.self) { offset in
                    let date = Calendar.current.date(byAdding: .day, value: offset, to: selectedDate)!
                    dateButton(for: date, isCenter: offset == 0)
                        .frame(width: geometry.size.width / 7)
                }
            }
        }
        .frame(height: datePickerHeight)
    }

    private func dateButton(for date: Date, isCenter: Bool) -> some View {
        let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)
        let isToday = Calendar.current.isDateInToday(date)
        let dayNumber = Calendar.current.component(.day, from: date)
        let weekday = date.formatted(.dateTime.weekday(.abbreviated))

        // Background color logic
        let backgroundColor: Color = {
            if isSelected {
                return Color(hex: "#FFD60A") // Bright yellow for selected
            } else if isToday {
                return Color(hex: "#FFD60A").opacity(0.15) // Light yellow for today
            } else {
                return Color(hex: "#3A3A3C") // Default gray
            }
        }()

        return Button(action: {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                selectedDate = date
            }
        }) {
            VStack(spacing: isCenter ? 6 : 4) {
                Text(weekday)
                    .font(.system(size: isCenter ? 13 : 11, weight: .medium))
                    .foregroundColor(isSelected ? Color(hex: "#1C1C1E") : .secondary)

                Text("\(dayNumber)")
                    .font(.system(size: isCenter ? 24 : 16, weight: isCenter ? .bold : .semibold))
                    .foregroundColor(isSelected ? Color(hex: "#1C1C1E") : .primary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: isCenter ? 70 : 56)
            .background(
                RoundedRectangle(cornerRadius: NotateDesignSystem.CornerRadius.medium)
                    .fill(backgroundColor)
            )
            .scaleEffect(isCenter ? 1.0 : 0.9)
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isCenter)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Helper Properties

    private var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

    // Filter pieces by time period (using createdAt time)
    private var anytimePieces: [Entry] {
        // Pieces without a specific time - show in Anytime
        // For now, return empty array as all pieces have createdAt time
        return []
    }

    private var pinnedPieces: [Entry] {
        let calendar = Calendar.current
        return appState.entries.filter { entry in
            entry.isPinned && calendar.isDate(entry.createdAt, inSameDayAs: selectedDate)
        }
    }

    private var midnightPieces: [Entry] {
        print("🔍 Computing midnightPieces with \(appState.entries.count) total entries")
        return filterPieces(startHour: 0, endHour: 6)
    }

    private var morningPieces: [Entry] {
        print("🔍 Computing morningPieces with \(appState.entries.count) total entries")
        return filterPieces(startHour: 6, endHour: 12)
    }

    private var afternoonPieces: [Entry] {
        print("🔍 Computing afternoonPieces with \(appState.entries.count) total entries")
        return filterPieces(startHour: 12, endHour: 18)
    }

    private var eveningPieces: [Entry] {
        print("🔍 Computing eveningPieces with \(appState.entries.count) total entries")
        return filterPieces(startHour: 18, endHour: 24)
    }

    private func filterPieces(startHour: Int, endHour: Int) -> [Entry] {
        let filtered = appState.entries.filter { piece in
            guard piece.createdAt.isInSameDay(as: selectedDate) else {
                print("⏭️ Filtering out entry (different day): \(piece.content.prefix(30)) - created: \(piece.createdAt) vs selected: \(selectedDate)")
                return false
            }
            let hour = Calendar.current.component(.hour, from: piece.createdAt)
            let matches = hour >= startHour && hour < endHour
            if !matches {
                print("⏭️ Filtering out entry (wrong time): \(piece.content.prefix(30)) - hour: \(hour) not in \(startHour)-\(endHour)")
            }
            return matches
        }.sorted { $0.createdAt < $1.createdAt }

        print("📊 Filtered \(filtered.count) entries for \(startHour)-\(endHour) period on \(selectedDate)")
        return filtered
    }

    // Calendar events from EventKit
    private var pinnedEvents: [CalendarEvent] {
        let calendar = Calendar.current
        return calendarService.events.filter { event in
            event.isPinned && calendar.isDate(event.startTime, inSameDayAs: selectedDate)
        }
    }

    private var midnightEvents: [CalendarEvent] {
        calendarService.eventsForTimePeriod(startHour: 0, endHour: 6, on: selectedDate)
    }

    private var morningEvents: [CalendarEvent] {
        calendarService.eventsForTimePeriod(startHour: 6, endHour: 12, on: selectedDate)
    }

    private var afternoonEvents: [CalendarEvent] {
        calendarService.eventsForTimePeriod(startHour: 12, endHour: 18, on: selectedDate)
    }

    private var eveningEvents: [CalendarEvent] {
        calendarService.eventsForTimePeriod(startHour: 18, endHour: 24, on: selectedDate)
    }
}

// MARK: - Date Extension

extension Date {
    func isInSameDay(as other: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: other)
    }
}

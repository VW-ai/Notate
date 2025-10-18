import SwiftUI

// MARK: - Operator View
// Bottom 30% panel with timer tracking and quick creation buttons

struct OperatorView: View {
    @StateObject private var operatorState = OperatorState.shared
    @EnvironmentObject var appState: AppState
    @StateObject private var calendarService = CalendarService.shared

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Top section: Buttons (upper 50% of operator view)
                buttonSection
                    .frame(height: geometry.size.height * 0.5)

                // Bottom section: Timer banner (lower 50% of operator view)
                if operatorState.isTimerRunning {
                    TomatoTimerBanner()
                        .frame(height: geometry.size.height * 0.5)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    Spacer()
                        .frame(height: geometry.size.height * 0.5)
                }
            }
        }
        .background(Color(hex: "#1C1C1E"))
    }

    // MARK: - Button Section

    private var buttonSection: some View {
        HStack(spacing: 24) {
            Spacer()

            // + Button or expanded create buttons
            if operatorState.showingCreateButtons {
                createButtonsExpanded
            } else {
                plusButton
            }

            // Play/Stop Button
            playStopButton

            Spacer()
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Plus Button

    private var plusButton: some View {
        Button(action: {
            operatorState.toggleCreateButtons()
        }) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(Color(hex: "#FFB84D"))
        }
        .buttonStyle(PlainButtonStyle())
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Expanded Create Buttons

    private var createButtonsExpanded: some View {
        HStack(spacing: 16) {
            // + Input Button
            Button(action: {
                operatorState.enterCreationMode(.entry)
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .bold))
                    Text("Input")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: "#7CB342"))
                )
            }
            .buttonStyle(PlainButtonStyle())

            // + Event Button
            Button(action: {
                operatorState.enterCreationMode(.event)
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .bold))
                    Text("Event")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: "#8B7355"))
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Play/Stop Button

    private var playStopButton: some View {
        Button(action: {
            if operatorState.isTimerRunning {
                handleStopTimer()
            } else {
                operatorState.startTimer()
            }
        }) {
            Image(systemName: operatorState.isTimerRunning ? "stop.circle.fill" : "play.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(operatorState.isTimerRunning ? Color(hex: "#E74C3C") : Color(hex: "#52C27D"))
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Timer Stop Logic

    private func handleStopTimer() {
        let result = operatorState.stopTimer()

        if result.hasData {
            // Auto-convert to event with flash animation
            createEventFromTimer(duration: result.duration)
        } else {
            // Show detail view for manual input
            operatorState.enterCreationMode(.timer)
        }
    }

    private func createEventFromTimer(duration: TimeInterval) {
        guard let startTime = operatorState.timerStartTime else { return }

        let endTime = startTime.addingTimeInterval(duration)

        // Create calendar event
        Task {
            do {
                let toolService = ToolService()
                let tagsString = operatorState.timerTags.isEmpty ? "" : "[tags: \(operatorState.timerTags.joined(separator: ", "))]"

                _ = try await toolService.createCalendarEvent(
                    title: operatorState.timerEventName,
                    notes: tagsString,
                    startDate: startTime,
                    endDate: endTime
                )

                await MainActor.run {
                    // Refresh calendar events
                    calendarService.fetchEvents(for: startTime)

                    // Reset timer
                    operatorState.resetTimer()

                    // TODO: Play flash animation from banner to timeline

                    print("✅ Created event from timer: \(operatorState.timerEventName)")
                }
            } catch {
                print("❌ Failed to create event from timer: \(error)")
            }
        }
    }
}

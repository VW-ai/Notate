import Foundation
import SwiftUI
import Combine

// MARK: - Creation Mode
enum CreationMode {
    case entry
    case event
    case timer
}

// MARK: - Operator State
// Manages state for the bottom operator panel (timer tracking + quick creation)

@MainActor
class OperatorState: ObservableObject {
    static let shared = OperatorState()

    // Timer tracking state
    @Published var isTimerRunning: Bool = false
    @Published var timerStartTime: Date?
    @Published var timerEventName: String = ""
    @Published var timerTags: [String] = []
    @Published var timerElapsedSeconds: Int = 0

    // Creation mode state
    @Published var showingCreateButtons: Bool = false
    @Published var creationMode: CreationMode?

    // Timer update
    private var timerCancellable: AnyCancellable?

    private init() {}

    // MARK: - Timer Methods

    func startTimer() {
        guard !isTimerRunning else { return }

        timerStartTime = Date()
        isTimerRunning = true
        timerEventName = ""
        timerTags = []
        timerElapsedSeconds = 0

        // Start timer updates (every second)
        timerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, let startTime = self.timerStartTime else { return }
                self.timerElapsedSeconds = Int(Date().timeIntervalSince(startTime))
            }

        print("⏱️ Timer started")
    }

    func stopTimer() -> (hasData: Bool, duration: TimeInterval) {
        guard isTimerRunning, let startTime = timerStartTime else {
            return (false, 0)
        }

        let duration = Date().timeIntervalSince(startTime)
        let hasData = !timerEventName.isEmpty || !timerTags.isEmpty

        // Stop timer updates
        timerCancellable?.cancel()
        timerCancellable = nil

        isTimerRunning = false

        print("⏱️ Timer stopped - Duration: \(formattedDuration(seconds: timerElapsedSeconds)), Has data: \(hasData)")

        return (hasData, duration)
    }

    func resetTimer() {
        timerStartTime = nil
        timerEventName = ""
        timerTags = []
        timerElapsedSeconds = 0
        isTimerRunning = false
        timerCancellable?.cancel()
        timerCancellable = nil
    }

    func formattedDuration(seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        return String(format: "%02dh%02dm", hours, minutes)
    }

    // MARK: - Creation Mode Methods

    func toggleCreateButtons() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showingCreateButtons.toggle()
        }
    }

    func enterCreationMode(_ mode: CreationMode) {
        withAnimation(.easeInOut(duration: 0.3)) {
            creationMode = mode
            showingCreateButtons = false
        }

        print("📝 Entering creation mode: \(mode)")
    }

    func cancelCreation() {
        withAnimation(.easeInOut(duration: 0.3)) {
            creationMode = nil

            // If canceling timer creation, reset timer
            if case .timer = creationMode {
                resetTimer()
            }
        }

        print("❌ Creation canceled")
    }

    func confirmCreation() {
        print("✅ Creation confirmed for mode: \(String(describing: creationMode))")

        // Keep timer data if confirming timer-based event
        let shouldResetTimer = creationMode != .timer

        withAnimation(.easeInOut(duration: 0.3)) {
            creationMode = nil
        }

        if shouldResetTimer {
            resetTimer()
        }
    }
}

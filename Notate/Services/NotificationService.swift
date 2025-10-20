import SwiftUI
import Combine

// MARK: - Notification Service
// Manages toast notifications throughout the app

@MainActor
class NotificationService: ObservableObject {
    static let shared = NotificationService()

    @Published var activeToasts: [NotateToast] = []

    private let maxToasts = 3

    private init() {}

    func show(_ toast: NotateToast) {
        // Add to array
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            activeToasts.append(toast)
        }

        // Trim if exceeds max
        if activeToasts.count > maxToasts {
            withAnimation {
                activeToasts.removeFirst()
            }
        }

        // Auto-dismiss after duration
        Task {
            try? await Task.sleep(nanoseconds: UInt64(toast.duration * 1_000_000_000))
            await dismiss(toast)
        }
    }

    func dismiss(_ toast: NotateToast) async {
        await MainActor.run {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                activeToasts.removeAll { $0.id == toast.id }
            }
        }
    }

    func dismissImmediate(_ toast: NotateToast) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            activeToasts.removeAll { $0.id == toast.id }
        }
    }

    // MARK: - Convenience Methods

    func showCapture(entry: Entry) {
        let toast = NotateToast(
            type: entry.isTodo ? .capture : .info,
            title: "Captured \(entry.type.displayName)",
            message: entry.content,
            icon: entry.isTodo ? "checkmark.circle.fill" : "lightbulb.fill",
            duration: 3.0,
            metadata: "Trigger: \(entry.triggerUsed)"
        )
        show(toast)
    }

    func showProcessing(entry: Entry) {
        let toast = NotateToast(
            type: .processing,
            title: "AI Processing",
            message: entry.content,
            icon: "brain.head.profile",
            duration: 2.0
        )
        show(toast)
    }

    func showProcessingComplete(entry: Entry, actionCount: Int) {
        let toast = NotateToast(
            type: .success,
            title: "AI Insights Ready",
            message: entry.content,
            icon: "sparkles",
            duration: 5.0,
            metadata: "\(actionCount) action\(actionCount == 1 ? "" : "s") suggested",
            action: {
                // This will be filled in when integrated with AppState
                print("Jump to entry: \(entry.id)")
            }
        )
        show(toast)
    }

    func showActionExecuted(action: AIAction, entry: Entry) {
        let toast = NotateToast(
            type: .success,
            title: "\(action.type.displayName) Created",
            message: entry.content,
            icon: action.type.icon,
            duration: 4.0,
            metadata: "View in \(action.type.displayName)",
            action: {
                print("Jump to \(action.type.displayName)")
            }
        )
        show(toast)
    }

    func showTodoCompleted(entry: Entry) {
        let toast = NotateToast(
            type: .success,
            title: "TODO Completed",
            message: entry.content,
            icon: "checkmark.circle.fill",
            duration: 3.0,
            metadata: "Moved to Archive"
        )
        show(toast)
    }

    func showError(title: String, message: String) {
        let toast = NotateToast(
            type: .error,
            title: title,
            message: message,
            icon: "exclamationmark.triangle.fill",
            duration: 5.0
        )
        show(toast)
    }

    func showInfo(title: String, message: String, duration: TimeInterval = 3.0) {
        let toast = NotateToast(
            type: .info,
            title: title,
            message: message,
            icon: "info.circle.fill",
            duration: duration
        )
        show(toast)
    }
}

// MARK: - Toast Model

struct NotateToast: Identifiable, Equatable {
    let id = UUID()
    let type: ToastType
    let title: String
    let message: String
    let icon: String
    let duration: TimeInterval
    let metadata: String?
    var action: (() -> Void)?

    static func == (lhs: NotateToast, rhs: NotateToast) -> Bool {
        lhs.id == rhs.id
    }

    init(
        type: ToastType,
        title: String,
        message: String,
        icon: String,
        duration: TimeInterval,
        metadata: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.type = type
        self.title = title
        self.message = message
        self.icon = icon
        self.duration = duration
        self.metadata = metadata
        self.action = action
    }

    enum ToastType {
        case capture
        case processing
        case success
        case error
        case info

        var accentColor: Color {
            switch self {
            case .capture:
                return .notateActionAmber
            case .processing:
                return .notateNeuralBlue
            case .success:
                return .notateSuccessEmerald
            case .error:
                return .notateAlertCrimson
            case .info:
                return .notateSlate
            }
        }
    }
}

// MARK: - AIActionType Extension
// Note: icon extension already exists in EntryDetailView.swift

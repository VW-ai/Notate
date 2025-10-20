import SwiftUI

// MARK: - Notate Toast View
// Individual toast notification display

struct NotateToastView: View {
    let toast: NotateToast
    let onDismiss: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var isHovering = false

    var body: some View {
        NotateCard(
            padding: NotateDesignSystem.Spacing.space4,
            cornerRadius: NotateDesignSystem.CornerRadius.medium,
            shadow: .medium
        ) {
            HStack(spacing: NotateDesignSystem.Spacing.space3) {
                // Icon with accent color
                Image(systemName: toast.icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(toast.type.accentColor)
                    .frame(width: 24, height: 24)

                // Content
                VStack(alignment: .leading, spacing: NotateDesignSystem.Spacing.space1) {
                    // Title
                    Text(toast.title)
                        .font(.notateBodyMedium)
                        .foregroundColor(.primary)

                    // Message
                    Text(toast.message)
                        .font(.notateSmall)
                        .foregroundColor(.secondary)
                        .lineLimit(2)

                    // Metadata
                    if let metadata = toast.metadata {
                        Text(metadata)
                            .font(.notateTiny)
                            .foregroundColor(toast.type.accentColor)
                            .padding(.top, 2)
                    }
                }

                Spacer(minLength: NotateDesignSystem.Spacing.space2)

                // Dismiss button
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
                .opacity(isHovering ? 1.0 : 0.6)
            }
        }
        .frame(maxWidth: 400)
        .onTapGesture {
            if let action = toast.action {
                action()
                onDismiss()
            }
        }
        .onHover { hovering in
            isHovering = hovering
        }
        .transition(.asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .bottom).combined(with: .opacity)
        ))
    }
}

// MARK: - Toast Overlay Container
// Container for displaying multiple toasts

struct ToastOverlay: View {
    @EnvironmentObject var notificationService: NotificationService

    var body: some View {
        VStack(alignment: .trailing, spacing: NotateDesignSystem.Spacing.space3) {
            Spacer()

            ForEach(notificationService.activeToasts) { toast in
                NotateToastView(toast: toast) {
                    notificationService.dismissImmediate(toast)
                }
            }
        }
        .padding(NotateDesignSystem.Spacing.space5)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: notificationService.activeToasts.count)
    }
}

// MARK: - Preview

#if DEBUG
struct NotateToast_Previews: PreviewProvider {
    static var previews: some View {
        // Single toast preview
        ZStack {
            Color.notateGhost.ignoresSafeArea()

            VStack {
                Spacer()

                NotateToastView(
                    toast: NotateToast(
                        type: .capture,
                        title: "Captured TODO",
                        message: "Buy milk and eggs from the store tomorrow morning",
                        icon: "checkmark.circle.fill",
                        duration: 3.0,
                        metadata: "Trigger: ///"
                    )
                ) {
                    print("Dismissed")
                }
                .padding()
            }
        }
        .frame(width: 600, height: 400)
        .preferredColorScheme(.light)

        // Multiple toasts stacked
        ZStack {
            Color.notateGhost.ignoresSafeArea()

            VStack(alignment: .trailing, spacing: 12) {
                Spacer()

                NotateToastView(
                    toast: NotateToast(
                        type: .processing,
                        title: "AI Processing",
                        message: "Analyzing your entry...",
                        icon: "brain.head.profile",
                        duration: 2.0
                    )
                ) {
                    print("Dismissed")
                }

                NotateToastView(
                    toast: NotateToast(
                        type: .success,
                        title: "AI Insights Ready",
                        message: "Coffee chat tomorrow at John A Paulson",
                        icon: "sparkles",
                        duration: 5.0,
                        metadata: "3 actions suggested"
                    )
                ) {
                    print("Dismissed")
                }

                NotateToastView(
                    toast: NotateToast(
                        type: .success,
                        title: "Calendar Event Created",
                        message: "Coffee chat tomorrow at 2 PM",
                        icon: "calendar",
                        duration: 4.0,
                        metadata: "View in Calendar"
                    )
                ) {
                    print("Dismissed")
                }
            }
            .padding()
        }
        .frame(width: 600, height: 600)
        .preferredColorScheme(.light)

        // Dark mode
        ZStack {
            Color.notateSurfaceDark.ignoresSafeArea()

            VStack {
                Spacer()

                NotateToastView(
                    toast: NotateToast(
                        type: .error,
                        title: "Failed to Create Event",
                        message: "Calendar permission denied. Please enable in Settings.",
                        icon: "exclamationmark.triangle.fill",
                        duration: 5.0
                    )
                ) {
                    print("Dismissed")
                }

                NotateToastView(
                    toast: NotateToast(
                        type: .info,
                        title: "TODO Completed",
                        message: "Write quarterly report",
                        icon: "checkmark.circle.fill",
                        duration: 3.0,
                        metadata: "Moved to Archive"
                    )
                ) {
                    print("Dismissed")
                }
            }
            .padding()
        }
        .frame(width: 600, height: 500)
        .preferredColorScheme(.dark)
    }
}
#endif

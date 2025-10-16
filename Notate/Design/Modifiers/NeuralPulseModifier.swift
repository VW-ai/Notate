import SwiftUI

// MARK: - Neural Pulse Animation
// Pulsing effect for AI processing states

struct NeuralPulseModifier: ViewModifier {
    let isActive: Bool
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .opacity(isActive ? (isPulsing ? 0.6 : 1.0) : 1.0)
            .if(isActive) { view in
                view.shadowNeuralGlow()
            }
            .onChange(of: isActive) { active in
                if active {
                    withAnimation(
                        .easeInOut(duration: 1.5)
                        .repeatForever(autoreverses: true)
                    ) {
                        isPulsing = true
                    }
                } else {
                    withAnimation(.easeOut(duration: 0.3)) {
                        isPulsing = false
                    }
                }
            }
            .onAppear {
                if isActive {
                    withAnimation(
                        .easeInOut(duration: 1.5)
                        .repeatForever(autoreverses: true)
                    ) {
                        isPulsing = true
                    }
                }
            }
    }
}

extension View {
    /// Apply neural pulse animation when active
    /// - Parameter isActive: Whether the pulse animation should be active
    func neuralPulse(isActive: Bool) -> some View {
        modifier(NeuralPulseModifier(isActive: isActive))
    }
}

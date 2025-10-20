import SwiftUI

// MARK: - Notate View Extensions
// Convenience modifiers for applying Notate design system styles

extension View {
    // MARK: - Shadow Modifiers

    /// Apply minimal shadow (subtle separation)
    func shadowMinimal(darkMode: Bool = false) -> some View {
        let shadow = NotateDesignSystem.Shadow.minimal(darkMode: darkMode)
        return self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }

    /// Apply subtle shadow (resting cards) - most common
    func shadowSubtle(darkMode: Bool = false) -> some View {
        let shadow = NotateDesignSystem.Shadow.subtle(darkMode: darkMode)
        return self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }

    /// Apply soft shadow (elevated cards on hover)
    func shadowSoft(darkMode: Bool = false) -> some View {
        let shadow = NotateDesignSystem.Shadow.soft(darkMode: darkMode)
        return self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }

    /// Apply medium shadow (modals, popovers)
    func shadowMedium(darkMode: Bool = false) -> some View {
        let shadow = NotateDesignSystem.Shadow.medium(darkMode: darkMode)
        return self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }

    /// Apply strong shadow (prominent dialogs)
    func shadowStrong(darkMode: Bool = false) -> some View {
        let shadow = NotateDesignSystem.Shadow.strong(darkMode: darkMode)
        return self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }

    /// Apply neural glow (AI processing)
    func shadowNeuralGlow() -> some View {
        let shadow = NotateDesignSystem.Shadow.neuralGlow
        return self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }

    /// Apply success glow (celebration)
    func shadowSuccessGlow() -> some View {
        let shadow = NotateDesignSystem.Shadow.successGlow
        return self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }

    // MARK: - Conditional Modifiers

    /// Apply modifier conditionally
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    /// Apply one of two modifiers based on condition
    @ViewBuilder
    func `if`<TrueContent: View, FalseContent: View>(
        _ condition: Bool,
        if ifTransform: (Self) -> TrueContent,
        else elseTransform: (Self) -> FalseContent
    ) -> some View {
        if condition {
            ifTransform(self)
        } else {
            elseTransform(self)
        }
    }
}

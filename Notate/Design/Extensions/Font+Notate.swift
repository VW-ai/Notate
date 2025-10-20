import SwiftUI

// MARK: - Notate Font Extensions
// Convenience accessors for Notate typography system

extension Font {
    // MARK: Typography Scale
    static var notateDisplay: Font { NotateDesignSystem.Typography.display }
    static var notateH1: Font { NotateDesignSystem.Typography.h1 }
    static var notateH2: Font { NotateDesignSystem.Typography.h2 }
    static var notateH3: Font { NotateDesignSystem.Typography.h3 }
    static var notateBody: Font { NotateDesignSystem.Typography.body }
    static var notateBodyMedium: Font { NotateDesignSystem.Typography.bodyMedium }
    static var notateBodySemibold: Font { NotateDesignSystem.Typography.bodySemibold }
    static var notateSmall: Font { NotateDesignSystem.Typography.small }
    static var notateSmallMedium: Font { NotateDesignSystem.Typography.smallMedium }
    static var notateTiny: Font { NotateDesignSystem.Typography.tiny }
    static var notateTinyRegular: Font { NotateDesignSystem.Typography.tinyRegular }
    static var notateCode: Font { NotateDesignSystem.Typography.code }
}

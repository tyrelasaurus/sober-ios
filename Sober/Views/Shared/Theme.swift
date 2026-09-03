import SwiftUI

/// Color palette mirroring src/renderer/shared/theme.css so the iOS app
/// feels like the same product as the Mac app.
enum Theme {
    static let bgApp = Color(hex: 0x12151C)
    static let card = Color.white.opacity(0.055)
    static let cardStrong = Color.white.opacity(0.09)
    static let border = Color.white.opacity(0.09)

    static let textPrimary = Color(hex: 0xF3F5F9)
    static let textSecondary = Color(hex: 0xF3F5F9).opacity(0.64)
    static let textTertiary = Color(hex: 0xF3F5F9).opacity(0.4)

    static let accent = Color(hex: 0x5B8CFF)
    static let accent2 = Color(hex: 0x34D399)
    static let gold = Color(hex: 0xF5B84E)
    static let danger = Color(hex: 0xFF6B6B)
}

extension Color {
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

/// A rounded card container matching the Mac app's `.card` style.
struct CardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(Theme.card)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.border, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

extension View {
    func cardStyle() -> some View { modifier(CardBackground()) }
}

struct ScreenBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Theme.bgApp.ignoresSafeArea())
            .scrollContentBackground(.hidden)
    }
}

extension View {
    func screenBackground() -> some View { modifier(ScreenBackground()) }
}

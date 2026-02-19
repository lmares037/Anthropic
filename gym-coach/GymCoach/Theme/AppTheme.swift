import SwiftUI

/// Centralized design system for the Gym Coach app.
/// Dark minimal aesthetic with accent colors for muscle groups.
enum AppTheme {

    // MARK: - Colors

    static let background = Color(hex: "0A0A0F")
    static let surface = Color(hex: "14141F")
    static let surfaceElevated = Color(hex: "1E1E2E")
    static let surfaceBorder = Color(hex: "2A2A3A")

    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "9999AA")
    static let textTertiary = Color(hex: "666677")

    static let accent = Color(hex: "6C5CE7")
    static let accentSecondary = Color(hex: "00D2D3")
    static let success = Color(hex: "00B894")
    static let warning = Color(hex: "FDCB6E")
    static let danger = Color(hex: "E17055")

    // MARK: - Spacing

    static let paddingXS: CGFloat = 4
    static let paddingSM: CGFloat = 8
    static let paddingMD: CGFloat = 16
    static let paddingLG: CGFloat = 24
    static let paddingXL: CGFloat = 32

    // MARK: - Corner Radius

    static let radiusSM: CGFloat = 8
    static let radiusMD: CGFloat = 12
    static let radiusLG: CGFloat = 16
    static let radiusXL: CGFloat = 20

    // MARK: - Typography helpers

    static func title(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 28, weight: .bold, design: .rounded))
            .foregroundColor(textPrimary)
    }

    static func heading(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 20, weight: .semibold, design: .rounded))
            .foregroundColor(textPrimary)
    }

    static func subheading(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 15, weight: .medium, design: .rounded))
            .foregroundColor(textSecondary)
    }

    static func caption(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .foregroundColor(textTertiary)
    }
}

// MARK: - Color Hex Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6:
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255
        )
    }
}

// MARK: - View Modifiers

struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(AppTheme.paddingMD)
            .background(AppTheme.surface)
            .cornerRadius(AppTheme.radiusMD)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.radiusMD)
                    .stroke(AppTheme.surfaceBorder, lineWidth: 1)
            )
    }
}

struct ElevatedCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(AppTheme.paddingMD)
            .background(AppTheme.surfaceElevated)
            .cornerRadius(AppTheme.radiusLG)
            .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardModifier())
    }

    func elevatedCardStyle() -> some View {
        modifier(ElevatedCardModifier())
    }
}

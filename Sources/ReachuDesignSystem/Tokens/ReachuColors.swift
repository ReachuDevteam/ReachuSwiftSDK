import SwiftUI

/// Reachu Design System Color Tokens
public struct ReachuColors {
    
    // MARK: - Brand Colors
    public static let primary = Color(hex: "#007AFF")
    public static let secondary = Color(hex: "#5856D6")
    
    // MARK: - Semantic Colors
    public static let success = Color(hex: "#34C759")
    public static let warning = Color(hex: "#FF9500")
    public static let error = Color(hex: "#FF3B30")
    public static let info = Color(hex: "#007AFF")
    
    // MARK: - Background Colors
    public static let background = Color(hex: "#F2F2F7")
    public static let surface = Color.white
    public static let surfaceSecondary = Color(hex: "#F9F9F9")
    
    // MARK: - Text Colors
    public static let textPrimary = Color.black
    public static let textSecondary = Color(hex: "#8E8E93")
    public static let textTertiary = Color(hex: "#C7C7CC")
    
    // MARK: - Border Colors
    public static let border = Color(hex: "#E5E5EA")
    public static let borderSecondary = Color(hex: "#D1D1D6")
}

// MARK: - Color Extensions
extension Color {
    /// Initialize Color from hex string
    /// - Parameter hex: Hex color string (e.g., "#FF0000" or "FF0000")
    public init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

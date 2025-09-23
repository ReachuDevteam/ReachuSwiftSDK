import SwiftUI
import ReachuCore

/// Reachu Design System Color Tokens
/// 
/// Provides adaptive colors that automatically respond to theme changes
/// and dark/light mode switching.
public struct ReachuColors {
    
    // MARK: - Brand Colors
    
    /// Primary brand color - adapts to current theme
    public static var primary: Color {
        currentColorScheme.primary
    }
    
    /// Secondary brand color - adapts to current theme
    public static var secondary: Color {
        currentColorScheme.secondary
    }
    
    // MARK: - Semantic Colors
    
    /// Success color - adapts to current theme
    public static var success: Color {
        currentColorScheme.success
    }
    
    /// Warning color - adapts to current theme
    public static var warning: Color {
        currentColorScheme.warning
    }
    
    /// Error color - adapts to current theme
    public static var error: Color {
        currentColorScheme.error
    }
    
    /// Info color - adapts to current theme
    public static var info: Color {
        currentColorScheme.info
    }
    
    // MARK: - Background Colors
    
    /// Background color - adapts to current theme
    public static var background: Color {
        currentColorScheme.background
    }
    
    /// Surface color - adapts to current theme
    public static var surface: Color {
        currentColorScheme.surface
    }
    
    /// Secondary surface color - adapts to current theme
    public static var surfaceSecondary: Color {
        currentColorScheme.surfaceSecondary
    }
    
    // MARK: - Text Colors
    
    /// Primary text color - adapts to current theme
    public static var textPrimary: Color {
        currentColorScheme.textPrimary
    }
    
    /// Secondary text color - adapts to current theme
    public static var textSecondary: Color {
        currentColorScheme.textSecondary
    }
    
    /// Tertiary text color - adapts to current theme
    public static var textTertiary: Color {
        currentColorScheme.textTertiary
    }
    
    // MARK: - Border Colors
    
    /// Border color - adapts to current theme
    public static var border: Color {
        currentColorScheme.border
    }
    
    /// Secondary border color - adapts to current theme
    public static var borderSecondary: Color {
        currentColorScheme.borderSecondary
    }
    
    // MARK: - Private Helpers
    
    /// Returns default color scheme
    private static var currentColorScheme: DefaultColorScheme {
        DefaultColorScheme()
    }
}

// MARK: - Default Color Scheme
private struct DefaultColorScheme {
    let primary = Color(.sRGB, red: 0.0, green: 0.478, blue: 1.0, opacity: 1.0) // #007AFF
    let secondary = Color(.sRGB, red: 0.345, green: 0.337, blue: 0.839, opacity: 1.0) // #5856D6
    let success = Color(.sRGB, red: 0.204, green: 0.780, blue: 0.349, opacity: 1.0) // #34C759
    let warning = Color(.sRGB, red: 1.0, green: 0.584, blue: 0.0, opacity: 1.0) // #FF9500
    let error = Color(.sRGB, red: 1.0, green: 0.231, blue: 0.188, opacity: 1.0) // #FF3B30
    let info = Color(.sRGB, red: 0.0, green: 0.478, blue: 1.0, opacity: 1.0) // #007AFF
    let background = Color(.sRGB, red: 0.949, green: 0.949, blue: 0.969, opacity: 1.0) // #F2F2F7
    let surface = Color.white
    let surfaceSecondary = Color(.sRGB, red: 0.976, green: 0.976, blue: 0.976, opacity: 1.0) // #F9F9F9
    let textPrimary = Color.black
    let textSecondary = Color(.sRGB, red: 0.557, green: 0.557, blue: 0.576, opacity: 1.0) // #8E8E93
    let textTertiary = Color(.sRGB, red: 0.780, green: 0.780, blue: 0.800, opacity: 1.0) // #C7C7CC
    let border = Color(.sRGB, red: 0.898, green: 0.898, blue: 0.918, opacity: 1.0) // #E5E5EA
    let borderSecondary = Color(.sRGB, red: 0.820, green: 0.820, blue: 0.839, opacity: 1.0) // #D1D1D6
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

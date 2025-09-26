import SwiftUI
import ReachuCore

#if os(iOS)
import UIKit
#endif

/// Reachu Design System Color Tokens
/// 
/// Provides adaptive colors that automatically respond to theme changes
/// and dark/light mode switching.
public struct ReachuColors {
    
    // MARK: - Dynamic Color Access (for SwiftUI views)
    
    /// Get adaptive colors for the current color scheme
    /// Use this in SwiftUI views with @Environment(\.colorScheme)
    public static func adaptive(for colorScheme: SwiftUI.ColorScheme) -> AdaptiveColors {
        AdaptiveColors(colorScheme: colorScheme)
    }
    
    // MARK: - Static Colors (fallback)
    
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
    
    /// Returns the current color scheme based on configuration and system appearance
    /// Note: This tries to detect system appearance, but SwiftUI views should use @Environment(\.colorScheme)
    private static var currentColorScheme: ReachuCore.ColorScheme {
        // Try to detect system appearance (best effort)
        #if os(iOS)
        if #available(iOS 13.0, *) {
            let isDark = UITraitCollection.current.userInterfaceStyle == .dark
            return ReachuConfiguration.shared.theme.colors(for: isDark ? .dark : .light)
        }
        #endif
        
        // Fallback to light colors if detection fails
        return ReachuConfiguration.shared.theme.lightColors
    }
    
    // MARK: - Adaptive Color Access
    
    /// Get colors for a specific color scheme (useful for manual adaptation)
    public static func colors(for colorScheme: SwiftUI.ColorScheme) -> ReachuCore.ColorScheme {
        ReachuConfiguration.shared.theme.colors(for: colorScheme)
    }
}

// MARK: - Adaptive Colors Helper

/// Helper struct for accessing colors that adapt to color scheme
public struct AdaptiveColors {
    private let colorScheme: SwiftUI.ColorScheme
    private let themeColors: ReachuCore.ColorScheme
    
    internal init(colorScheme: SwiftUI.ColorScheme) {
        self.colorScheme = colorScheme
        self.themeColors = ReachuConfiguration.shared.theme.colors(for: colorScheme)
    }
    
    // MARK: - Brand Colors
    public var primary: Color { themeColors.primary }
    public var secondary: Color { themeColors.secondary }
    
    // MARK: - Semantic Colors
    public var success: Color { themeColors.success }
    public var warning: Color { themeColors.warning }
    public var error: Color { themeColors.error }
    public var info: Color { themeColors.info }
    
    // MARK: - Background Colors
    public var background: Color { themeColors.background }
    public var surface: Color { themeColors.surface }
    public var surfaceSecondary: Color { themeColors.surfaceSecondary }
    
    // MARK: - Text Colors
    public var textPrimary: Color { themeColors.textPrimary }
    public var textSecondary: Color { themeColors.textSecondary }
    public var textTertiary: Color { themeColors.textTertiary }
    
    // MARK: - Border Colors
    public var border: Color { themeColors.border }
    public var borderSecondary: Color { themeColors.borderSecondary }
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

import SwiftUI
import ReachuCore

/// Adaptive Color System for Reachu Components
///
/// This provides colors that automatically adapt to light/dark mode
/// and respect the configured theme settings.
public struct AdaptiveReachuColors {
    
    @SwiftUI.Environment(\.colorScheme) private var colorScheme: SwiftUI.ColorScheme
    
    private let theme: ReachuTheme
    
    public init(theme: ReachuTheme = ReachuConfiguration.shared.theme) {
        self.theme = theme
    }
    
    // MARK: - Brand Colors
    
    public var primary: Color {
        theme.colors(for: colorScheme).primary
    }
    
    public var secondary: Color {
        theme.colors(for: colorScheme).secondary
    }
    
    // MARK: - Semantic Colors
    
    public var success: Color {
        theme.colors(for: colorScheme).success
    }
    
    public var warning: Color {
        theme.colors(for: colorScheme).warning
    }
    
    public var error: Color {
        theme.colors(for: colorScheme).error
    }
    
    public var info: Color {
        theme.colors(for: colorScheme).info
    }
    
    // MARK: - Background Colors
    
    public var background: Color {
        theme.colors(for: colorScheme).background
    }
    
    public var surface: Color {
        theme.colors(for: colorScheme).surface
    }
    
    public var surfaceSecondary: Color {
        theme.colors(for: colorScheme).surfaceSecondary
    }
    
    // MARK: - Text Colors
    
    public var textPrimary: Color {
        theme.colors(for: colorScheme).textPrimary
    }
    
    public var textSecondary: Color {
        theme.colors(for: colorScheme).textSecondary
    }
    
    public var textTertiary: Color {
        theme.colors(for: colorScheme).textTertiary
    }
    
    // MARK: - Border Colors
    
    public var border: Color {
        theme.colors(for: colorScheme).border
    }
    
    public var borderSecondary: Color {
        theme.colors(for: colorScheme).borderSecondary
    }
}

// MARK: - ViewModifier for Adaptive Colors

public struct AdaptiveColorsModifier: ViewModifier {
    
    @SwiftUI.Environment(\.colorScheme) private var colorScheme: SwiftUI.ColorScheme
    
    public func body(content: Content) -> some View {
        content
            .environment(\.reachuAdaptiveColors, AdaptiveReachuColors())
            .preferredColorScheme(preferredColorScheme)
    }
    
    private var preferredColorScheme: SwiftUI.ColorScheme? {
        let theme = ReachuConfiguration.shared.theme
        switch theme.mode {
        case .automatic:
            return nil // Use system preference
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

// MARK: - Environment Support

private struct ReachuAdaptiveColorsKey: EnvironmentKey {
    static let defaultValue = AdaptiveReachuColors()
}

extension EnvironmentValues {
    public var reachuAdaptiveColors: AdaptiveReachuColors {
        get { self[ReachuAdaptiveColorsKey.self] }
        set { self[ReachuAdaptiveColorsKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {
    /// Applies adaptive Reachu colors that respond to theme and color scheme changes
    public func adaptiveReachuColors() -> some View {
        self.modifier(AdaptiveColorsModifier())
    }
}

// MARK: - Convenience Functions for Static Access

/// Provides static access to adaptive colors with environment fallback
public struct StaticAdaptiveColors {
    
    /// Get color for specific color scheme
    public static func primary(for colorScheme: SwiftUI.ColorScheme) -> Color {
        ReachuConfiguration.shared.theme.colors(for: colorScheme).primary
    }
    
    public static func secondary(for colorScheme: SwiftUI.ColorScheme) -> Color {
        ReachuConfiguration.shared.theme.colors(for: colorScheme).secondary
    }
    
    public static func success(for colorScheme: SwiftUI.ColorScheme) -> Color {
        ReachuConfiguration.shared.theme.colors(for: colorScheme).success
    }
    
    public static func warning(for colorScheme: SwiftUI.ColorScheme) -> Color {
        ReachuConfiguration.shared.theme.colors(for: colorScheme).warning
    }
    
    public static func error(for colorScheme: SwiftUI.ColorScheme) -> Color {
        ReachuConfiguration.shared.theme.colors(for: colorScheme).error
    }
    
    public static func info(for colorScheme: SwiftUI.ColorScheme) -> Color {
        ReachuConfiguration.shared.theme.colors(for: colorScheme).info
    }
    
    public static func background(for colorScheme: SwiftUI.ColorScheme) -> Color {
        ReachuConfiguration.shared.theme.colors(for: colorScheme).background
    }
    
    public static func surface(for colorScheme: SwiftUI.ColorScheme) -> Color {
        ReachuConfiguration.shared.theme.colors(for: colorScheme).surface
    }
    
    public static func surfaceSecondary(for colorScheme: SwiftUI.ColorScheme) -> Color {
        ReachuConfiguration.shared.theme.colors(for: colorScheme).surfaceSecondary
    }
    
    public static func textPrimary(for colorScheme: SwiftUI.ColorScheme) -> Color {
        ReachuConfiguration.shared.theme.colors(for: colorScheme).textPrimary
    }
    
    public static func textSecondary(for colorScheme: SwiftUI.ColorScheme) -> Color {
        ReachuConfiguration.shared.theme.colors(for: colorScheme).textSecondary
    }
    
    public static func textTertiary(for colorScheme: SwiftUI.ColorScheme) -> Color {
        ReachuConfiguration.shared.theme.colors(for: colorScheme).textTertiary
    }
    
    public static func border(for colorScheme: SwiftUI.ColorScheme) -> Color {
        ReachuConfiguration.shared.theme.colors(for: colorScheme).border
    }
    
    public static func borderSecondary(for colorScheme: SwiftUI.ColorScheme) -> Color {
        ReachuConfiguration.shared.theme.colors(for: colorScheme).borderSecondary
    }
}

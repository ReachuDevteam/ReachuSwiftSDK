import SwiftUI

/// Reachu Theme Configuration
///
/// Defines colors, typography, and visual styling for all Reachu UI components.
/// Allows complete customization of the SDK's appearance to match your app's design.
public struct ReachuTheme {
    
    // MARK: - Properties
    public let name: String
    public let colors: ColorScheme
    public let typography: TypographyScheme
    public let spacing: SpacingScheme
    public let borderRadius: BorderRadiusScheme
    
    // MARK: - Initializer
    public init(
        name: String,
        colors: ColorScheme,
        typography: TypographyScheme = .default,
        spacing: SpacingScheme = .default,
        borderRadius: BorderRadiusScheme = .default
    ) {
        self.name = name
        self.colors = colors
        self.typography = typography
        self.spacing = spacing
        self.borderRadius = borderRadius
    }
    
    // MARK: - Predefined Themes
    
    /// Default Reachu theme with brand colors
    public static let `default` = ReachuTheme(
        name: "Reachu Default",
        colors: .reachu
    )
    
    /// Light theme for bright, clean interfaces
    public static let light = ReachuTheme(
        name: "Light",
        colors: .light
    )
    
    /// Dark theme for modern, elegant interfaces
    public static let dark = ReachuTheme(
        name: "Dark",
        colors: .dark
    )
    
    /// Minimal theme with subtle colors
    public static let minimal = ReachuTheme(
        name: "Minimal",
        colors: .minimal
    )
}

// MARK: - Color Scheme

public struct ColorScheme {
    // Brand Colors
    public let primary: Color
    public let secondary: Color
    
    // Semantic Colors
    public let success: Color
    public let warning: Color
    public let error: Color
    public let info: Color
    
    // Background Colors
    public let background: Color
    public let surface: Color
    public let surfaceSecondary: Color
    
    // Text Colors
    public let textPrimary: Color
    public let textSecondary: Color
    public let textTertiary: Color
    
    // Border Colors
    public let border: Color
    public let borderSecondary: Color
    
    public init(
        primary: Color,
        secondary: Color,
        success: Color = Color(.sRGB, red: 0.204, green: 0.780, blue: 0.349, opacity: 1.0), // #34C759
        warning: Color = Color(.sRGB, red: 1.0, green: 0.584, blue: 0.0, opacity: 1.0), // #FF9500
        error: Color = Color(.sRGB, red: 1.0, green: 0.231, blue: 0.188, opacity: 1.0), // #FF3B30
        info: Color = Color(.sRGB, red: 0.0, green: 0.478, blue: 1.0, opacity: 1.0), // #007AFF
        background: Color = Color(.sRGB, red: 0.949, green: 0.949, blue: 0.969, opacity: 1.0), // #F2F2F7
        surface: Color = .white,
        surfaceSecondary: Color = Color(.sRGB, red: 0.976, green: 0.976, blue: 0.976, opacity: 1.0), // #F9F9F9
        textPrimary: Color = .black,
        textSecondary: Color = Color(.sRGB, red: 0.557, green: 0.557, blue: 0.576, opacity: 1.0), // #8E8E93
        textTertiary: Color = Color(.sRGB, red: 0.780, green: 0.780, blue: 0.800, opacity: 1.0), // #C7C7CC
        border: Color = Color(.sRGB, red: 0.898, green: 0.898, blue: 0.918, opacity: 1.0), // #E5E5EA
        borderSecondary: Color = Color(.sRGB, red: 0.820, green: 0.820, blue: 0.839, opacity: 1.0) // #D1D1D6
    ) {
        self.primary = primary
        self.secondary = secondary
        self.success = success
        self.warning = warning
        self.error = error
        self.info = info
        self.background = background
        self.surface = surface
        self.surfaceSecondary = surfaceSecondary
        self.textPrimary = textPrimary
        self.textSecondary = textSecondary
        self.textTertiary = textTertiary
        self.border = border
        self.borderSecondary = borderSecondary
    }
}

// MARK: - Predefined Color Schemes

extension ColorScheme {
    /// Default Reachu brand colors
    public static let reachu = ColorScheme(
        primary: Color(.sRGB, red: 0.0, green: 0.478, blue: 1.0, opacity: 1.0), // #007AFF
        secondary: Color(.sRGB, red: 0.345, green: 0.337, blue: 0.839, opacity: 1.0) // #5856D6
    )
    
    /// Light color scheme
    public static let light = ColorScheme(
        primary: Color(.sRGB, red: 0.0, green: 0.4, blue: 0.8, opacity: 1.0), // #0066CC
        secondary: Color(.sRGB, red: 0.345, green: 0.337, blue: 0.839, opacity: 1.0) // #5856D6
    )
    
    /// Dark color scheme
    public static let dark = ColorScheme(
        primary: Color(.sRGB, red: 0.039, green: 0.518, blue: 1.0, opacity: 1.0), // #0A84FF
        secondary: Color(.sRGB, red: 0.369, green: 0.361, blue: 0.902, opacity: 1.0), // #5E5CE6
        background: Color.black, // #000000
        surface: Color(.sRGB, red: 0.110, green: 0.110, blue: 0.118, opacity: 1.0), // #1C1C1E
        surfaceSecondary: Color(.sRGB, red: 0.173, green: 0.173, blue: 0.180, opacity: 1.0), // #2C2C2E
        textPrimary: .white,
        textSecondary: Color(.sRGB, red: 0.557, green: 0.557, blue: 0.576, opacity: 1.0), // #8E8E93
        textTertiary: Color(.sRGB, red: 0.282, green: 0.282, blue: 0.290, opacity: 1.0), // #48484A
        border: Color(.sRGB, red: 0.220, green: 0.220, blue: 0.227, opacity: 1.0), // #38383A
        borderSecondary: Color(.sRGB, red: 0.282, green: 0.282, blue: 0.290, opacity: 1.0) // #48484A
    )
    
    /// Minimal color scheme
    public static let minimal = ColorScheme(
        primary: Color(.sRGB, red: 0.2, green: 0.2, blue: 0.2, opacity: 1.0), // #333333
        secondary: Color(.sRGB, red: 0.4, green: 0.4, blue: 0.4, opacity: 1.0) // #666666
    )
}

// MARK: - Typography Scheme

public struct TypographyScheme {
    public let largeTitle: Font
    public let title1: Font
    public let title2: Font
    public let title3: Font
    public let headline: Font
    public let subheadline: Font
    public let body: Font
    public let bodyBold: Font
    public let callout: Font
    public let footnote: Font
    public let caption1: Font
    public let caption2: Font
    
    public init(
        largeTitle: Font = Font.largeTitle.weight(.bold),
        title1: Font = Font.title.weight(.semibold),
        title2: Font = Font.title2.weight(.semibold),
        title3: Font = Font.title3.weight(.medium),
        headline: Font = Font.headline.weight(.semibold),
        subheadline: Font = Font.subheadline.weight(.medium),
        body: Font = Font.body,
        bodyBold: Font = Font.body.weight(.semibold),
        callout: Font = Font.callout,
        footnote: Font = Font.footnote,
        caption1: Font = Font.caption,
        caption2: Font = Font.caption2
    ) {
        self.largeTitle = largeTitle
        self.title1 = title1
        self.title2 = title2
        self.title3 = title3
        self.headline = headline
        self.subheadline = subheadline
        self.body = body
        self.bodyBold = bodyBold
        self.callout = callout
        self.footnote = footnote
        self.caption1 = caption1
        self.caption2 = caption2
    }
    
    public static let `default` = TypographyScheme()
}

// MARK: - Spacing Scheme

public struct SpacingScheme {
    public let xs: CGFloat
    public let sm: CGFloat
    public let md: CGFloat
    public let lg: CGFloat
    public let xl: CGFloat
    public let xxl: CGFloat
    
    public init(
        xs: CGFloat = 4,
        sm: CGFloat = 8,
        md: CGFloat = 16,
        lg: CGFloat = 24,
        xl: CGFloat = 32,
        xxl: CGFloat = 48
    ) {
        self.xs = xs
        self.sm = sm
        self.md = md
        self.lg = lg
        self.xl = xl
        self.xxl = xxl
    }
    
    public static let `default` = SpacingScheme()
}

// MARK: - Border Radius Scheme

public struct BorderRadiusScheme {
    public let none: CGFloat
    public let small: CGFloat
    public let medium: CGFloat
    public let large: CGFloat
    public let xl: CGFloat
    public let circle: CGFloat
    
    public init(
        none: CGFloat = 0,
        small: CGFloat = 4,
        medium: CGFloat = 8,
        large: CGFloat = 12,
        xl: CGFloat = 16,
        circle: CGFloat = 999
    ) {
        self.none = none
        self.small = small
        self.medium = medium
        self.large = large
        self.xl = xl
        self.circle = circle
    }
    
    public static let `default` = BorderRadiusScheme()
}

// MARK: - Color Extension
// Color.init(hex:) is already defined in ReachuDesignSystem

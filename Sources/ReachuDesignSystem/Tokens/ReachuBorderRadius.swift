import Foundation
import ReachuCore

/// Reachu Design System Border Radius Tokens
/// Reads values from ReachuConfiguration theme configuration
public struct ReachuBorderRadius {
    
    /// Get borderRadius values from configured theme
    private static var scheme: BorderRadiusScheme {
        ReachuConfiguration.shared.theme.borderRadius
    }
    
    /// No radius - 0pt
    public static var none: CGFloat {
        scheme.none
    }
    
    /// Small radius - Default: 4pt (configurable via JSON)
    public static var small: CGFloat {
        scheme.small
    }
    
    /// Medium radius - Default: 8pt (configurable via JSON)
    public static var medium: CGFloat {
        scheme.medium
    }
    
    /// Large radius - Default: 12pt (configurable via JSON)
    public static var large: CGFloat {
        scheme.large
    }
    
    /// Extra large radius - Default: 16pt (configurable via JSON)
    public static var xl: CGFloat {
        scheme.xl
    }
    
    /// Circle/pill radius - Default: 999pt (effectively infinite, configurable via JSON)
    public static var circle: CGFloat {
        scheme.circle
    }
}

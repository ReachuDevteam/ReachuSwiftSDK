import Foundation
import SwiftUI

/// Configuration Loader
///
/// Loads Reachu SDK configuration from various sources:
/// - JSON files
/// - Plist files  
/// - Remote configuration
/// - Environment variables
public class ConfigurationLoader {
    
    // MARK: - JSON Configuration Loading
    
    /// Load configuration from a JSON file in the app bundle
    /// 
    /// **Usage:**
    /// ```swift
    /// // Create reachu-config.json in your app bundle
    /// try ConfigurationLoader.loadFromJSON(fileName: "reachu-config")
    /// ```
    public static func loadFromJSON(fileName: String, bundle: Bundle = .main) throws {
        guard let path = bundle.path(forResource: fileName, ofType: "json"),
              let data = FileManager.default.contents(atPath: path) else {
            throw ConfigurationError.fileNotFound(fileName: "\(fileName).json")
        }
        
        let config = try JSONDecoder().decode(JSONConfiguration.self, from: data)
        applyConfiguration(config)
    }
    
    /// Load configuration from JSON string
    public static func loadFromJSONString(_ jsonString: String) throws {
        guard let data = jsonString.data(using: .utf8) else {
            throw ConfigurationError.invalidJSON
        }
        
        let config = try JSONDecoder().decode(JSONConfiguration.self, from: data)
        applyConfiguration(config)
    }
    
    // MARK: - Plist Configuration Loading
    
    /// Load configuration from a Plist file in the app bundle
    public static func loadFromPlist(fileName: String, bundle: Bundle = .main) throws {
        guard let path = bundle.path(forResource: fileName, ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path) else {
            throw ConfigurationError.fileNotFound(fileName: "\(fileName).plist")
        }
        
        let config = try PlistConfiguration.from(plist)
        applyPlistConfiguration(config)
    }
    
    // MARK: - Environment Variables Loading
    
    /// Load configuration from environment variables
    /// Useful for CI/CD and different deployment environments
    public static func loadFromEnvironment() {
        let apiKey = ProcessInfo.processInfo.environment["REACHU_API_KEY"] ?? ""
        let environmentString = ProcessInfo.processInfo.environment["REACHU_ENVIRONMENT"] ?? "production"
        let environment = ReachuEnvironment(rawValue: environmentString) ?? .production
        
        if !apiKey.isEmpty {
            ReachuConfiguration.configure(
                apiKey: apiKey,
                environment: environment
            )
        }
    }
    
    // MARK: - Remote Configuration Loading
    
    /// Load configuration from a remote URL
    public static func loadFromRemote(url: URL) async throws {
        let (data, _) = try await URLSession.shared.data(from: url)
        let config = try JSONDecoder().decode(JSONConfiguration.self, from: data)
        
        await MainActor.run {
            applyConfiguration(config)
        }
    }
    
    // MARK: - Apply Configurations
    
    private static func applyConfiguration(_ config: JSONConfiguration) {
        let theme = createTheme(from: config.theme)
        let cartConfig = createCartConfiguration(from: config.cart)
        let networkConfig = createNetworkConfiguration(from: config.network)
        let uiConfig = createUIConfiguration(from: config.ui)
        let liveShowConfig = createLiveShowConfiguration(from: config.liveShow)
        
        ReachuConfiguration.configure(
            apiKey: config.apiKey,
            environment: ReachuEnvironment(rawValue: config.environment) ?? .production,
            theme: theme,
            cartConfig: cartConfig,
            networkConfig: networkConfig,
            uiConfig: uiConfig,
            liveShowConfig: liveShowConfig
        )
    }
    
    private static func applyPlistConfiguration(_ config: PlistConfiguration) {
        ReachuConfiguration.configure(
            apiKey: config.apiKey,
            environment: ReachuEnvironment(rawValue: config.environment) ?? .production
        )
    }
    
    // MARK: - Configuration Creation Helpers
    
    private static func createTheme(from themeConfig: JSONThemeConfiguration?) -> ReachuTheme {
        guard let config = themeConfig else { return .default }
        
        let mode = ThemeMode(rawValue: config.mode ?? "automatic") ?? .automatic
        
        // Parse light colors (complete set)
        let lightColors = ColorScheme(
            primary: hexToColor(config.lightColors?.primary ?? config.colors?.primary ?? "#007AFF"),
            secondary: hexToColor(config.lightColors?.secondary ?? config.colors?.secondary ?? "#5856D6"),
            success: hexToColor(config.lightColors?.success ?? "#34C759"),
            warning: hexToColor(config.lightColors?.warning ?? "#FF9500"),
            error: hexToColor(config.lightColors?.error ?? "#FF3B30"),
            info: hexToColor(config.lightColors?.info ?? "#007AFF"),
            background: hexToColor(config.lightColors?.background ?? "#F2F2F7"),
            surface: hexToColor(config.lightColors?.surface ?? "#FFFFFF"),
            surfaceSecondary: hexToColor(config.lightColors?.surfaceSecondary ?? "#F9F9F9"),
            textPrimary: hexToColor(config.lightColors?.textPrimary ?? "#000000"),
            textSecondary: hexToColor(config.lightColors?.textSecondary ?? "#8E8E93"),
            textTertiary: hexToColor(config.lightColors?.textTertiary ?? "#C7C7CC"),
            border: hexToColor(config.lightColors?.border ?? "#E5E5EA"),
            borderSecondary: hexToColor(config.lightColors?.borderSecondary ?? "#D1D1D6")
        )
        
        // Parse dark colors (complete set, fallback to auto-generated if not specified)
        let darkColors: ReachuCore.ColorScheme
        if let darkColorsConfig = config.darkColors {
            darkColors = ColorScheme(
                primary: hexToColor(darkColorsConfig.primary ?? "#0A84FF"),
                secondary: hexToColor(darkColorsConfig.secondary ?? "#5E5CE6"),
                success: hexToColor(darkColorsConfig.success ?? "#32D74B"),
                warning: hexToColor(darkColorsConfig.warning ?? "#FF9F0A"),
                error: hexToColor(darkColorsConfig.error ?? "#FF453A"),
                info: hexToColor(darkColorsConfig.info ?? "#0A84FF"),
                background: hexToColor(darkColorsConfig.background ?? "#000000"),
                surface: hexToColor(darkColorsConfig.surface ?? "#1C1C1E"),
                surfaceSecondary: hexToColor(darkColorsConfig.surfaceSecondary ?? "#2C2C2E"),
                textPrimary: hexToColor(darkColorsConfig.textPrimary ?? "#FFFFFF"),
                textSecondary: hexToColor(darkColorsConfig.textSecondary ?? "#8E8E93"),
                textTertiary: hexToColor(darkColorsConfig.textTertiary ?? "#48484A"),
                border: hexToColor(darkColorsConfig.border ?? "#38383A"),
                borderSecondary: hexToColor(darkColorsConfig.borderSecondary ?? "#48484A")
            )
        } else {
            darkColors = .autoDark(from: lightColors)
        }
        
        return ReachuTheme(
            name: config.name,
            mode: mode,
            lightColors: lightColors,
            darkColors: darkColors
        )
    }
    
    // MARK: - Helper Functions
    
    private static func hexToColor(_ hex: String) -> Color {
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
            (a, r, g, b) = (255, 0, 0, 0) // Default to black
        }
        
        return Color(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    private static func createCartConfiguration(from cartConfig: JSONCartConfiguration?) -> CartConfiguration {
        guard let config = cartConfig else { return .default }
        
        return CartConfiguration(
            floatingCartPosition: FloatingCartPosition(rawValue: config.floatingCartPosition) ?? .bottomRight,
            floatingCartDisplayMode: FloatingCartDisplayMode(rawValue: config.floatingCartDisplayMode) ?? .full,
            floatingCartSize: FloatingCartSize(rawValue: config.floatingCartSize) ?? .medium,
            autoSaveCart: config.autoSaveCart,
            showCartNotifications: config.showCartNotifications,
            enableGuestCheckout: config.enableGuestCheckout
        )
    }
    
    private static func createNetworkConfiguration(from networkConfig: JSONNetworkConfiguration?) -> NetworkConfiguration {
        guard let config = networkConfig else { return .default }
        
        return NetworkConfiguration(
            timeout: config.timeout,
            retryAttempts: config.retryAttempts,
            enableCaching: config.enableCaching,
            enableLogging: config.enableLogging
        )
    }
    
    private static func createUIConfiguration(from uiConfig: JSONUIConfiguration?) -> UIConfiguration {
        guard let config = uiConfig else { return .default }
        
        return UIConfiguration(
            enableProductCardAnimations: config.enableAnimations,
            showProductBrands: config.showProductBrands,
            enableHapticFeedback: config.enableHapticFeedback
        )
    }
    
    private static func createLiveShowConfiguration(from liveShowConfig: JSONLiveShowConfiguration?) -> LiveShowConfiguration {
        guard let config = liveShowConfig else { return .default }
        
        return LiveShowConfiguration(
            autoJoinChat: config.autoJoinChat,
            enableShoppingDuringStream: config.enableShopping,
            enableAutoplay: config.enableAutoplay
        )
    }
}

// MARK: - Configuration Errors
// ConfigurationError is defined in ReachuConfiguration.swift

// MARK: - JSON Configuration Models

private struct JSONConfiguration: Codable {
    let apiKey: String
    let environment: String
    let theme: JSONThemeConfiguration?
    let cart: JSONCartConfiguration?
    let network: JSONNetworkConfiguration?
    let ui: JSONUIConfiguration?
    let liveShow: JSONLiveShowConfiguration?
}

private struct JSONThemeConfiguration: Codable {
    let name: String
    let mode: String?
    let colors: JSONColorConfiguration? // Legacy support
    let lightColors: JSONColorConfiguration?
    let darkColors: JSONColorConfiguration?
}

private struct JSONColorConfiguration: Codable {
    let primary: String?
    let secondary: String?
    let success: String?
    let warning: String?
    let error: String?
    let info: String?
    let background: String?
    let surface: String?
    let surfaceSecondary: String?
    let textPrimary: String?
    let textSecondary: String?
    let textTertiary: String?
    let border: String?
    let borderSecondary: String?
}

private struct JSONCartConfiguration: Codable {
    let floatingCartPosition: String
    let floatingCartDisplayMode: String
    let floatingCartSize: String
    let autoSaveCart: Bool
    let showCartNotifications: Bool
    let enableGuestCheckout: Bool
}

private struct JSONNetworkConfiguration: Codable {
    let timeout: TimeInterval
    let retryAttempts: Int
    let enableCaching: Bool
    let enableLogging: Bool
}

private struct JSONUIConfiguration: Codable {
    let enableAnimations: Bool
    let showProductBrands: Bool
    let enableHapticFeedback: Bool
}

private struct JSONLiveShowConfiguration: Codable {
    let autoJoinChat: Bool
    let enableShopping: Bool
    let enableAutoplay: Bool
}

// MARK: - Plist Configuration

private struct PlistConfiguration {
    let apiKey: String
    let environment: String
    
    static func from(_ plist: NSDictionary) throws -> PlistConfiguration {
        guard let apiKey = plist["ReachuAPIKey"] as? String,
              let environment = plist["ReachuEnvironment"] as? String else {
            throw ConfigurationError.invalidPlist
        }
        
        return PlistConfiguration(apiKey: apiKey, environment: environment)
    }
}

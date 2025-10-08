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
    /// **Smart Configuration Loading:**
    /// ```swift
    /// // Option 1: Auto-detect config (recommended)
    /// ConfigurationLoader.loadConfiguration()
    /// 
    /// // Option 2: Specific file
    /// ConfigurationLoader.loadConfiguration(fileName: "reachu-config")
    /// 
    /// // Option 3: Custom bundle (for frameworks/modules)
    /// ConfigurationLoader.loadConfiguration(bundle: Bundle(for: MyClass.self))
    /// ```
    /// 
    /// - Parameters:
    ///   - fileName: Optional specific config file name (without .json extension)
    ///   - bundle: Bundle to search for config files (defaults to main app bundle)
    public static func loadConfiguration(fileName: String? = nil, bundle: Bundle = .main) {
        do {
            // 1. If specific fileName provided, use it directly
            if let fileName = fileName {
                print("🔧 [Config] Loading specific config: \(fileName).json")
                try loadFromJSON(fileName: fileName, bundle: bundle)
                return
            }
            
            // 2. Check environment variable
            if let configType = ProcessInfo.processInfo.environment["REACHU_CONFIG_TYPE"] {
                print("🔧 [Config] Using environment config type: \(configType)")
                let envFileName = "reachu-config-\(configType)"
                try loadFromJSON(fileName: envFileName, bundle: bundle)
                return
            }
            
            // 3. Check for config files in order of preference
            let configFiles = [
                "reachu-config",                 // User custom (highest priority)
                "reachu-config-automatic",       // Automatic theme (preferred)
                "reachu-config-example",         // Default fallback
                "reachu-config-dark-streaming"   // Dark theme (lowest priority)
            ]
            
            for configFile in configFiles {
                if bundle.path(forResource: configFile, ofType: "json") != nil {
                    print("🔧 [Config] Found config file: \(configFile).json")
                    try loadFromJSON(fileName: configFile, bundle: bundle)
                    return
                }
            }
            
            // 4. No config file found - use defaults
            print("⚠️ [Config] No config file found in bundle, using SDK defaults")
            applyDefaultConfiguration()
            
        } catch {
            print("❌ [Config] Error loading configuration: \(error)")
            print("🔧 [Config] Falling back to SDK defaults")
            applyDefaultConfiguration()
        }
    }
    
    /// Apply default SDK configuration when no config file is found
    private static func applyDefaultConfiguration() {
        // Configure with minimal defaults
        ReachuConfiguration.configure(
            apiKey: "",
            environment: .sandbox,
            theme: ReachuTheme(
                name: "Default SDK Theme",
                mode: .automatic,
                lightColors: .reachu,
                darkColors: .reachuDark
            ),
            marketConfig: .default
        )
        print("✅ [Config] Applied default SDK configuration")
    }
    
    public static func loadFromJSON(fileName: String, bundle: Bundle = .main) throws {
        guard let path = bundle.path(forResource: fileName, ofType: "json"),
              let data = FileManager.default.contents(atPath: path) else {
            throw ConfigurationError.fileNotFound(fileName: "\(fileName).json")
        }
        
        print("📄 [Config] Loading configuration from: \(fileName).json")
        let config = try JSONDecoder().decode(JSONConfiguration.self, from: data)
        applyConfiguration(config)
        print("✅ [Config] Configuration loaded successfully: \(config.theme?.name ?? "Default")")
        print("🎨 [Config] Theme mode: \(config.theme?.mode ?? "unknown")")
        if let lightColors = config.theme?.lightColors {
            print("💡 [Config] Light primary: \(lightColors.primary ?? "default")")
        }
        if let darkColors = config.theme?.darkColors {
            print("🌙 [Config] Dark primary: \(darkColors.primary ?? "default")")
        }
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
                environment: environment,
                marketConfig: .default
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
        let marketFallback = createMarketConfiguration(from: config.marketFallback)

        ReachuConfiguration.configure(
            apiKey: config.apiKey,
            environment: ReachuEnvironment(rawValue: config.environment) ?? .production,
            theme: theme,
            cartConfig: cartConfig,
            networkConfig: networkConfig,
            uiConfig: uiConfig,
            liveShowConfig: liveShowConfig,
            marketConfig: marketFallback
        )
    }
    
    private static func applyPlistConfiguration(_ config: PlistConfiguration) {
        ReachuConfiguration.configure(
            apiKey: config.apiKey,
            environment: ReachuEnvironment(rawValue: config.environment) ?? .production,
            marketConfig: .default
        )
    }
    
    // MARK: - Configuration Creation Helpers
    
    private static func createTheme(from themeConfig: JSONThemeConfiguration?) -> ReachuTheme {
        guard let config = themeConfig else { return .default }
        
        let mode = ThemeMode(rawValue: config.mode ?? "automatic") ?? .automatic
        
        // Parse light colors (with smart defaults from existing schemes)
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
        
        // Parse dark colors (with smart defaults, fallback to auto-generated if not specified)
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
            name: config.name ?? "Custom Theme",
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
        
        // Use streaming.autoJoinChat if available, otherwise fallback to legacy autoJoinChat
        let autoJoinChat = config.streaming?.autoJoinChat ?? config.autoJoinChat ?? true
        
        // Use shopping.enableShoppingDuringStream if available, otherwise fallback to legacy enableShopping
        let enableShopping = config.shopping?.enableShoppingDuringStream ?? config.enableShopping ?? true
        
        // Use streaming.enableAutoplay if available, otherwise fallback to legacy enableAutoplay
        let enableAutoplay = config.streaming?.enableAutoplay ?? config.enableAutoplay ?? false
        
        return LiveShowConfiguration(
            autoJoinChat: autoJoinChat,
            enableShoppingDuringStream: enableShopping,
            enableAutoplay: enableAutoplay
        )
    }

    private static func createMarketConfiguration(from marketConfig: JSONMarketFallbackConfiguration?) -> MarketConfiguration {
        guard let config = marketConfig else { return .default }

        return MarketConfiguration(
            countryCode: config.countryCode ?? MarketConfiguration.default.countryCode,
            countryName: config.countryName ?? MarketConfiguration.default.countryName,
            currencyCode: config.currencyCode ?? MarketConfiguration.default.currencyCode,
            currencySymbol: config.currencySymbol ?? MarketConfiguration.default.currencySymbol,
            phoneCode: config.phoneCode ?? MarketConfiguration.default.phoneCode,
            flagURL: config.flag ?? MarketConfiguration.default.flagURL
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
    let marketFallback: JSONMarketFallbackConfiguration?
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
    let tipio: JSONTipioConfiguration?
    let vimeo: JSONVimeoConfiguration?
    let realTime: JSONRealTimeConfiguration?
    let components: JSONComponentsConfiguration?
    let streaming: JSONStreamingConfiguration?
    let chat: JSONChatConfiguration?
    let shopping: JSONShoppingConfiguration?
    let ui: JSONLiveShowUIConfiguration?
    let notifications: JSONNotificationsConfiguration?
    
    // Legacy properties for backward compatibility
    let autoJoinChat: Bool?
    let enableShopping: Bool?
    let enableAutoplay: Bool?
}

private struct JSONMarketFallbackConfiguration: Codable {
    let countryCode: String?
    let countryName: String?
    let currencyCode: String?
    let currencySymbol: String?
    let phoneCode: String?
    let flag: String?
}

private struct JSONTipioConfiguration: Codable {
    let apiKey: String?
    let baseUrl: String?
    let enableWebhooks: Bool?
    let webhookSecret: String?
}

private struct JSONVimeoConfiguration: Codable {
    let apiKey: String?
    let accessToken: String?
    let baseUrl: String?
    let enableEmbedPlayer: Bool?
}

private struct JSONRealTimeConfiguration: Codable {
    let webSocketUrl: String?
    let autoReconnect: Bool?
    let heartbeatInterval: Int?
    let maxReconnectAttempts: Int?
    let componentCacheTimeout: Int?
    let autoRefreshInterval: Int?
}

private struct JSONComponentsConfiguration: Codable {
    let enableDynamicComponents: Bool?
    let maxConcurrentComponents: Int?
    let defaultAnimationDuration: Double?
    let enableOfflineCache: Bool?
    let preloadNextComponents: Bool?
}

private struct JSONStreamingConfiguration: Codable {
    let autoJoinChat: Bool?
    let enableAutoplay: Bool?
    let videoQuality: String?
    let enablePictureInPicture: Bool?
    let enableFullscreen: Bool?
    let showStreamControls: Bool?
    let muteByDefault: Bool?
}

private struct JSONChatConfiguration: Codable {
    let enableChat: Bool?
    let enableChatModeration: Bool?
    let maxChatMessageLength: Int?
    let enableEmojis: Bool?
    let enableChatNotifications: Bool?
    let chatRefreshInterval: Double?
    let enableUserMentions: Bool?
    let enableChatHistory: Bool?
    let showChatAvatars: Bool?
}

private struct JSONShoppingConfiguration: Codable {
    let enableShoppingDuringStream: Bool?
    let showProductOverlays: Bool?
    let enableQuickBuy: Bool?
    let productOverlayDuration: Double?
    let enableProductNotifications: Bool?
    let integrateLiveCart: Bool?
    let specialPricingEnabled: Bool?
    let countdownEnabled: Bool?
}

private struct JSONLiveShowUIConfiguration: Codable {
    let playerAspectRatio: String?
    let enableLiveIndicator: Bool?
    let showViewerCount: Bool?
    let enableShareButton: Bool?
    let layout: JSONLayoutConfiguration?
    let branding: JSONBrandingConfiguration?
    let animations: JSONAnimationsConfiguration?
}

private struct JSONLayoutConfiguration: Codable {
    let defaultLayout: String?
    let enableLayoutSwitching: Bool?
    let miniPlayerPosition: String?
}

private struct JSONBrandingConfiguration: Codable {
    let liveIndicatorColor: String?
    let accentColor: String?
    let overlayBackgroundOpacity: Double?
    let gradientOverlay: Bool?
    let cardBackgroundColor: String?
    let highlightColor: String?
    let shadowColor: String?
    let shadowOpacity: Double?
}

private struct JSONAnimationsConfiguration: Codable {
    let enableEntryAnimations: Bool?
    let enableExitAnimations: Bool?
    let componentTransitionDuration: Double?
    let fadeInDuration: Double?
    let slideAnimationEnabled: Bool?
}

private struct JSONNotificationsConfiguration: Codable {
    let enableStreamNotifications: Bool?
    let enableProductNotifications: Bool?
    let enableComponentNotifications: Bool?
    let notificationSound: Bool?
    let showNotificationBadges: Bool?
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

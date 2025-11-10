import Foundation
import SwiftUI

#if canImport(StripeCore)
import StripeCore
#endif

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
    /// 
    /// // Option 4: With user country check
    /// ConfigurationLoader.loadConfiguration(userCountryCode: "US")
    /// ```
    /// 
    /// - Parameters:
    ///   - fileName: Optional specific config file name (without .json extension)
    ///   - bundle: Bundle to search for config files (defaults to main app bundle)
    ///   - userCountryCode: Optional user's country code (e.g., "US", "NO"). If provided, SDK will check if market is available for this country before enabling.
    public static func loadConfiguration(fileName: String? = nil, bundle: Bundle = .main, userCountryCode: String? = nil) {
        do {
            // 1. If specific fileName provided, use it directly
            if let fileName = fileName {
                ReachuLogger.debug("Loading specific config: \(fileName).json", component: "Config")
                try loadFromJSON(fileName: fileName, bundle: bundle, userCountryCode: userCountryCode)
                return
            }
            
            // 2. Check environment variable
            if let configType = ProcessInfo.processInfo.environment["REACHU_CONFIG_TYPE"] {
                ReachuLogger.debug("Using environment config type: \(configType)", component: "Config")
                let envFileName = "reachu-config-\(configType)"
                try loadFromJSON(fileName: envFileName, bundle: bundle, userCountryCode: userCountryCode)
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
                    ReachuLogger.debug("Found config file: \(configFile).json", component: "Config")
                    try loadFromJSON(fileName: configFile, bundle: bundle, userCountryCode: userCountryCode)
                    return
                }
            }
            
            // 4. No config file found - use defaults
            ReachuLogger.warning("No config file found in bundle, using SDK defaults", component: "Config")
            applyDefaultConfiguration(userCountryCode: userCountryCode)
            
        } catch {
            ReachuLogger.error("Error loading configuration: \(error)", component: "Config")
            ReachuLogger.debug("Falling back to SDK defaults", component: "Config")
            applyDefaultConfiguration(userCountryCode: userCountryCode)
        }
    }
    
    /// Apply default SDK configuration when no config file is found
    private static func applyDefaultConfiguration(userCountryCode: String? = nil) {
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
        ReachuLogger.success("Applied default SDK configuration", component: "Config")
        
        // Check market availability if user country provided
        if let countryCode = userCountryCode {
            Task {
                await checkMarketAvailability(countryCode: countryCode)
            }
        } else {
            // Default to available if no country check
            ReachuConfiguration.setMarketAvailable(true)
        }
    }
    
    public static func loadFromJSON(fileName: String, bundle: Bundle = .main, userCountryCode: String? = nil) throws {
        guard let path = bundle.path(forResource: fileName, ofType: "json"),
              let data = FileManager.default.contents(atPath: path) else {
            throw ConfigurationError.fileNotFound(fileName: "\(fileName).json")
        }
        
        ReachuLogger.debug("Loading configuration from: \(fileName).json", component: "Config")
        let config = try JSONDecoder().decode(JSONConfiguration.self, from: data)
        
        // Use provided userCountryCode or check environment variable
        let userCountry = userCountryCode ?? ProcessInfo.processInfo.environment["REACHU_USER_COUNTRY"]
        
        applyConfiguration(config, bundle: bundle, userCountryCode: userCountry)
        ReachuLogger.success("Configuration loaded successfully: \(config.theme?.name ?? "Default")", component: "Config")
        ReachuLogger.debug("Theme mode: \(config.theme?.mode ?? "unknown")", component: "Config")
        if let lightColors = config.theme?.lightColors {
            ReachuLogger.debug("Light primary: \(lightColors.primary ?? "default")", component: "Config")
        }
        if let darkColors = config.theme?.darkColors {
            ReachuLogger.debug("Dark primary: \(darkColors.primary ?? "default")", component: "Config")
        }
    }
    
    /// Load configuration from JSON string
    public static func loadFromJSONString(_ jsonString: String, bundle: Bundle = .main, userCountryCode: String? = nil) throws {
        guard let data = jsonString.data(using: .utf8) else {
            throw ConfigurationError.invalidJSON
        }
        
        let config = try JSONDecoder().decode(JSONConfiguration.self, from: data)
        applyConfiguration(config, bundle: bundle, userCountryCode: userCountryCode)
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
    public static func loadFromRemote(url: URL, bundle: Bundle = .main, userCountryCode: String? = nil) async throws {
        let (data, _) = try await URLSession.shared.data(from: url)
        let config = try JSONDecoder().decode(JSONConfiguration.self, from: data)
        
        await MainActor.run {
            applyConfiguration(config, bundle: bundle, userCountryCode: userCountryCode)
        }
    }
    
    // MARK: - Apply Configurations
    
    private static func applyConfiguration(_ config: JSONConfiguration, bundle: Bundle = .main, userCountryCode: String? = nil) {
        let theme = createTheme(from: config.theme)
        let cartConfig = createCartConfiguration(from: config.cart)
        let networkConfig = createNetworkConfiguration(from: config.network)
        let uiConfig = createUIConfiguration(from: config.ui)
        let liveShowConfig = createLiveShowConfiguration(from: config.liveShow, rootCampaignId: config.campaignId)
        let marketFallback = createMarketConfiguration(from: config.marketFallback)
        let productDetailConfig = createProductDetailConfiguration(from: config.productDetail)
        let localizationConfig = createLocalizationConfiguration(from: config.localization, bundle: bundle)
        let campaignConfig = createCampaignConfiguration(from: config.campaigns)

        ReachuConfiguration.configure(
            apiKey: config.apiKey,
            environment: ReachuEnvironment(rawValue: config.environment) ?? .production,
            theme: theme,
            cartConfig: cartConfig,
            networkConfig: networkConfig,
            uiConfig: uiConfig,
            liveShowConfig: liveShowConfig,
            marketConfig: marketFallback,
            productDetailConfig: productDetailConfig,
            localizationConfig: localizationConfig,
            campaignConfig: campaignConfig
        )
        
        // Initialize Stripe automatically if available
        initializeStripeIfAvailable()
        
        // Check market availability if user country provided
        if let countryCode = userCountryCode {
            // Set initial language based on user country
            let languageCode = languageCodeForCountry(countryCode)
            let hasTranslations = localizationConfig.translations[languageCode] != nil
            
            ReachuLogger.debug("Country: \(countryCode) → Language: \(languageCode), Translations available: \(hasTranslations), Available languages: \(localizationConfig.translations.keys.joined(separator: ", "))", component: "Config")
            
            if hasTranslations {
                ReachuLocalization.shared.setLanguage(languageCode)
                ReachuLogger.success("Language set to '\(languageCode)' based on user country '\(countryCode)'", component: "Config")
            } else {
                ReachuLogger.warning("Language '\(languageCode)' not available in translations, using default '\(localizationConfig.defaultLanguage)'", component: "Config")
                ReachuLocalization.shared.setLanguage(localizationConfig.defaultLanguage)
            }
            
            Task {
                await checkMarketAvailability(countryCode: countryCode)
            }
        } else {
            // Default to available if no country check
            // Set language based on market fallback (countryCode is always a String, not optional)
            let fallbackCountry = marketFallback.countryCode
            let languageCode = languageCodeForCountry(fallbackCountry)
            let hasTranslations = localizationConfig.translations[languageCode] != nil
            
            ReachuLogger.debug("Market fallback country: \(fallbackCountry) → Language: \(languageCode), Translations available: \(hasTranslations), Available languages: \(localizationConfig.translations.keys.joined(separator: ", "))", component: "Config")
            
            if hasTranslations {
                ReachuLocalization.shared.setLanguage(languageCode)
                ReachuLogger.success("Language set to '\(languageCode)' based on market fallback country '\(fallbackCountry)'", component: "Config")
            } else {
                ReachuLogger.warning("Language '\(languageCode)' not available in translations, using default '\(localizationConfig.defaultLanguage)'", component: "Config")
                ReachuLocalization.shared.setLanguage(localizationConfig.defaultLanguage)
            }
            
            ReachuConfiguration.setMarketAvailable(true)
        }
        
        // Reinitialize CampaignManager with new configuration
        Task { @MainActor in
            CampaignManager.shared.reinitialize()
        }
    }
    
    /// Check if market is available for the given country code
    /// This verifies if Reachu SDK should be enabled for the user's country
    /// Also stores the complete list of available markets for component access
    /// Uses Channel.GetAvailableMarkets to get only markets enabled for this specific channel
    private static func checkMarketAvailability(countryCode: String) async {
        let config = ReachuConfiguration.shared
        
        // Skip check if API key is empty (demo mode)
        guard !config.apiKey.isEmpty else {
            ReachuLogger.warning("Skipping market check - API key not configured", component: "Config")
            ReachuConfiguration.setMarketAvailable(true, userCountryCode: countryCode, availableMarkets: [])
            return
        }
        
        do {
            let baseURL = URL(string: config.environment.graphQLURL)!
            let sdk = SdkClient(baseUrl: baseURL, apiKey: config.apiKey)
            
            ReachuLogger.debug("Checking market availability for country: \(countryCode) - Using Channel.GetAvailableMarkets - URL: \(sdk.baseUrl.absoluteString), API Key: \(sdk.apiKey.prefix(8))...", component: "Config")
            
            // Use Channel.GetAvailableMarkets - this returns only markets enabled for this specific channel
            let channelMarkets = try await sdk.channel.market.getAvailable()
            let marketCodes = channelMarkets.compactMap { $0.code?.uppercased() }
            
            ReachuLogger.debug("Channel markets loaded: \(marketCodes.joined(separator: ", "))", component: "Config")
            
            let isAvailable = marketCodes.contains(countryCode.uppercased())
            
            await MainActor.run {
                // Store the complete list of available markets for component access
                ReachuConfiguration.setMarketAvailable(isAvailable, userCountryCode: countryCode, availableMarkets: channelMarkets)
            }
            
            if isAvailable {
                ReachuLogger.success("Market available for \(countryCode) - SDK enabled - Loaded \(channelMarkets.count) available markets: \(marketCodes.joined(separator: ", "))", component: "Config")
            } else {
                ReachuLogger.warning("Market not available for \(countryCode) - SDK disabled - Available markets (\(channelMarkets.count)): \(marketCodes.joined(separator: ", "))", component: "Config")
            }
        } catch let error as NotFoundException {
            await MainActor.run {
                ReachuConfiguration.setMarketAvailable(false, userCountryCode: countryCode, availableMarkets: [])
            }
            ReachuLogger.error("Channel market query failed (404) - SDK disabled for \(countryCode) - Error type: NotFoundException, URL: \(config.environment.graphQLURL), API Key: \(config.apiKey.prefix(8))..., Query: Channel.GetAvailableMarkets", component: "Config")
        } catch let error as SdkException {
            if error.code == "NOT_FOUND" || error.status == 404 {
                await MainActor.run {
                    ReachuConfiguration.setMarketAvailable(false, userCountryCode: countryCode, availableMarkets: [])
                }
                ReachuLogger.error("Channel market query failed (404) - SDK disabled for \(countryCode) - Error code: \(error.code), Status: \(error.status ?? 0), Message: \(error.description), URL: \(config.environment.graphQLURL), API Key: \(config.apiKey.prefix(8))..., Query: Channel.GetAvailableMarkets", component: "Config")
            } else {
                // Other errors - assume available to not block SDK usage
                await MainActor.run {
                    ReachuConfiguration.setMarketAvailable(true, userCountryCode: countryCode, availableMarkets: [])
                }
                ReachuLogger.warning("Market check failed but assuming available: \(error.description) - Error code: \(error.code), Status: \(error.status ?? 0)", component: "Config")
            }
        } catch {
            // Network or other errors - assume available to not block SDK usage
            await MainActor.run {
                ReachuConfiguration.setMarketAvailable(true, userCountryCode: countryCode, availableMarkets: [])
            }
            ReachuLogger.warning("Market check failed (network error) but assuming available - Error: \(error.localizedDescription), Type: \(type(of: error))", component: "Config")
        }
    }
    
    // MARK: - Helper Methods
    
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
        let lightPrimary = hexToColor(config.lightColors?.primary ?? config.colors?.primary ?? "#007AFF")
        let lightColors = ColorScheme(
            primary: lightPrimary,
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
            borderSecondary: hexToColor(config.lightColors?.borderSecondary ?? "#D1D1D6"),
            priceColor: config.lightColors?.priceColor != nil ? hexToColor(config.lightColors!.priceColor!) : nil  // Use primary if not specified
        )
        
        // Parse dark colors (with smart defaults, fallback to auto-generated if not specified)
        let darkColors: ReachuCore.ColorScheme
        if let darkColorsConfig = config.darkColors {
            let darkPrimary = hexToColor(darkColorsConfig.primary ?? "#0A84FF")
            darkColors = ColorScheme(
                primary: darkPrimary,
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
                borderSecondary: hexToColor(darkColorsConfig.borderSecondary ?? "#48484A"),
                priceColor: darkColorsConfig.priceColor != nil ? hexToColor(darkColorsConfig.priceColor!) : nil  // Use primary if not specified
            )
        } else {
            darkColors = .autoDark(from: lightColors)
        }
        
        // Parse borderRadius from config
        let borderRadius = BorderRadiusScheme(
            none: config.borderRadius?.none ?? 0,
            small: config.borderRadius?.small ?? 4,
            medium: config.borderRadius?.medium ?? 8,
            large: config.borderRadius?.large ?? 12,
            xl: config.borderRadius?.normalizedXL ?? 16,
            circle: config.borderRadius?.normalizedCircle ?? 999
        )
        
        return ReachuTheme(
            name: config.name,
            mode: mode,
            lightColors: lightColors,
            darkColors: darkColors,
            borderRadius: borderRadius
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
            floatingCartDisplayMode: FloatingCartDisplayMode(rawValue: config.floatingCartDisplayMode) ?? .minimal,
            floatingCartSize: FloatingCartSize(rawValue: config.floatingCartSize) ?? .small,
            autoSaveCart: config.autoSaveCart,
            showCartNotifications: config.showCartNotifications,
            enableGuestCheckout: config.enableGuestCheckout,
            requirePhoneNumber: config.requirePhoneNumber ?? true,
            defaultShippingCountry: config.defaultShippingCountry ?? "US",
            supportedPaymentMethods: config.supportedPaymentMethods ?? ["stripe", "klarna", "paypal"]
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
        
        // Parse shadow configuration
        let shadowConfig: ShadowConfiguration
        if let shadowJSON = config.shadowConfig {
            shadowConfig = ShadowConfiguration(
                cardShadowRadius: shadowJSON.cardShadowRadius ?? 4,
                cardShadowOpacity: shadowJSON.cardShadowOpacity ?? 0.1,
                cardShadowOffset: shadowJSON.cardShadowOffset.map { CGSize(width: $0.width, height: $0.height) } ?? CGSize(width: 0, height: 2),
                cardShadowColor: ShadowColor(rawValue: shadowJSON.cardShadowColor ?? "adaptive") ?? .adaptive,
                buttonShadowEnabled: shadowJSON.buttonShadowEnabled ?? true,
                buttonShadowRadius: shadowJSON.buttonShadowRadius ?? 2,
                buttonShadowOpacity: shadowJSON.buttonShadowOpacity ?? 0.15,
                modalShadowRadius: shadowJSON.modalShadowRadius ?? 20,
                modalShadowOpacity: shadowJSON.modalShadowOpacity ?? 0.3,
                enableBlurEffects: shadowJSON.enableBlurEffects ?? true,
                blurIntensity: shadowJSON.blurIntensity ?? 0.3,
                blurStyle: BlurStyle(rawValue: shadowJSON.blurStyle ?? "systemMaterial") ?? .systemMaterial
            )
        } else {
            shadowConfig = .default
        }
        
        return UIConfiguration(
            enableProductCardAnimations: config.enableAnimations,
            showProductBrands: config.showProductBrands,
            showDiscountBadge: config.showDiscountBadge ?? false,
            discountBadgeText: config.discountBadgeText,
            shadowConfig: shadowConfig,
            enableHapticFeedback: config.enableHapticFeedback
        )
    }
    
    private static func createLiveShowConfiguration(from liveShowConfig: JSONLiveShowConfiguration?, rootCampaignId: Int? = nil) -> LiveShowConfiguration {
        guard let config = liveShowConfig else {
            // If no liveShow config, use root campaignId if provided
            if let rootCampaignId = rootCampaignId {
                return LiveShowConfiguration(campaignId: rootCampaignId)
            }
            return .default
        }
        
        // Use streaming.autoJoinChat if available, otherwise fallback to legacy autoJoinChat
        let autoJoinChat = config.streaming?.autoJoinChat ?? config.autoJoinChat ?? true
        
        // Use shopping.enableShoppingDuringStream if available, otherwise fallback to legacy enableShopping
        let enableShopping = config.shopping?.enableShoppingDuringStream ?? config.enableShopping ?? true
        
        // Use streaming.enableAutoplay if available, otherwise fallback to legacy enableAutoplay
        let enableAutoplay = config.streaming?.enableAutoplay ?? config.enableAutoplay ?? false
        
        // Tipio configuration
        let tipioApiKey = config.tipio?.apiKey ?? ""
        let tipioBaseUrl = config.tipio?.baseUrl ?? "https://stg-dev-microservices.tipioapp.com"
        
        // Dynamic components configuration
        // Priority: rootCampaignId > liveShow.campaignId > 0 (default)
        let campaignId = rootCampaignId ?? config.campaignId ?? 0
        
        return LiveShowConfiguration(
            autoJoinChat: autoJoinChat,
            enableShoppingDuringStream: enableShopping,
            enableAutoplay: enableAutoplay,
            tipioApiKey: tipioApiKey,
            tipioBaseUrl: tipioBaseUrl,
            campaignId: campaignId
        )
    }

    private static func createCampaignConfiguration(from campaignConfig: JSONCampaignConfiguration?) -> CampaignConfiguration {
        guard let config = campaignConfig else { return .default }
        
        return CampaignConfiguration(
            webSocketBaseURL: config.webSocketBaseURL ?? CampaignConfiguration.default.webSocketBaseURL,
            restAPIBaseURL: config.restAPIBaseURL ?? CampaignConfiguration.default.restAPIBaseURL
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
    
    private static func createProductDetailConfiguration(from productDetailConfig: JSONProductDetailConfiguration?) -> ProductDetailConfiguration {
        guard let config = productDetailConfig else { return .default }
        
        let modalHeight = ProductDetailModalHeight(rawValue: config.modalHeight ?? "full") ?? .full
        let headerStyle = ProductDetailHeaderStyle(rawValue: config.headerStyle ?? "standard") ?? .standard
        let closeButtonStyle = CloseButtonStyle(rawValue: config.closeButtonStyle ?? "navigationBar") ?? .navigationBar
        
        return ProductDetailConfiguration(
            modalHeight: modalHeight,
            imageFullWidth: config.imageFullWidth ?? false,
            imageCornerRadius: config.imageCornerRadius ?? 12,
            imageHeight: config.imageHeight,
            showImageGallery: config.showImageGallery ?? true,
            headerStyle: headerStyle,
            enableImageZoom: config.enableImageZoom ?? true,
            showNavigationTitle: config.showNavigationTitle ?? true,
            closeButtonStyle: closeButtonStyle,
            showDescription: config.showDescription ?? true,
            showSpecifications: config.showSpecifications ?? true
        )
    }
    
    private static func createLocalizationConfiguration(from localizationConfig: JSONLocalizationConfiguration?, bundle: Bundle = .main) -> LocalizationConfiguration {
        guard let config = localizationConfig else { 
            // No localization config provided, use default with English translations
            return .default
        }
        
        var translations = config.translations ?? [:]
        
        // Si hay un archivo externo de traducciones, cargarlo
        if let translationsFile = config.translationsFile {
            ReachuLogger.debug("Loading translations from file: \(translationsFile).json", component: "Config")
            if let externalTranslations = loadTranslationsFromFile(translationsFile, bundle: bundle) {
                // Merge: las traducciones del archivo externo tienen prioridad
                for (language, langTranslations) in externalTranslations {
                    if translations[language] == nil {
                        translations[language] = [:]
                    }
                    translations[language]?.merge(langTranslations) { (_, new) in new }
                }
                ReachuLogger.debug("Total languages loaded: \(externalTranslations.keys.joined(separator: ", "))", component: "Config")
            } else {
                ReachuLogger.warning("Failed to load translations file: \(translationsFile).json", component: "Config")
            }
        }
        
        // If no translations provided, use default English translations
        if translations.isEmpty {
            return LocalizationConfiguration(
                defaultLanguage: config.defaultLanguage ?? "en",
                translations: ["en": ReachuTranslationKey.defaultEnglish],
                fallbackLanguage: config.fallbackLanguage ?? "en"
            )
        }
        
        // Ensure English translations are always available as fallback (from default)
        // Don't add them if they're not in the file, they're already in defaultEnglish
        if translations["en"] == nil {
            // English is always available from ReachuTranslationKey.defaultEnglish, no need to add it here
            ReachuLogger.debug("English translations not in file, will use default built-in translations", component: "Config")
        }
        
        return LocalizationConfiguration(
            defaultLanguage: config.defaultLanguage ?? "en",
            translations: translations,
            fallbackLanguage: config.fallbackLanguage ?? "en"
        )
    }
    
    /// Map country codes to language codes (same as in ReachuConfiguration)
    private static func languageCodeForCountry(_ countryCode: String?) -> String {
        guard let countryCode = countryCode?.uppercased() else { return "en" }
        
        let countryToLanguage: [String: String] = [
            "DE": "de", "AT": "de", "CH": "de",
            "US": "en", "GB": "en", "CA": "en", "AU": "en",
            "NO": "no", "SE": "sv", "DK": "da", "FI": "fi",
            "ES": "es", "FR": "fr", "IT": "it", "NL": "nl", "PL": "pl",
            "PT": "pt", "BR": "pt", "MX": "es", "AR": "es", "CL": "es", "CO": "es",
            "JP": "ja", "CN": "zh", "KR": "ko",
        ]
        
        return countryToLanguage[countryCode] ?? "en"
    }
    
    /// Load translations from external JSON file
    /// Looks for files like: translations.json, localization.json, translations-{language}.json
    private static func loadTranslationsFromFile(_ fileName: String, bundle: Bundle = .main) -> [String: [String: String]]? {
        // Try to find the file in the bundle
        guard let path = bundle.path(forResource: fileName, ofType: "json"),
              let data = FileManager.default.contents(atPath: path) else {
            ReachuLogger.warning("Translations file not found: \(fileName).json - Searched in bundle: \(bundle.bundlePath) - Make sure the file is included in 'Copy Bundle Resources' in Xcode", component: "Config")
            return nil
        }
        
        do {
            // Try to decode as translations object
            let decoder = JSONDecoder()
            
            // Format 1: { "translations": { "en": {...}, "es": {...} } }
            if let wrapper = try? decoder.decode(TranslationsFileWrapper.self, from: data) {
                ReachuLogger.debug("Loaded translations from \(fileName).json", component: "Config")
                return wrapper.translations
            }
            
            // Format 2: Direct { "en": {...}, "es": {...} }
            if let directTranslations = try? decoder.decode([String: [String: String]].self, from: data) {
                let languages = directTranslations.keys.joined(separator: ", ")
                let totalKeys = directTranslations.values.reduce(0) { $0 + $1.count }
                ReachuLogger.debug("Loaded translations from \(fileName).json - Languages: \(languages), Total translation keys: \(totalKeys)", component: "Config")
                return directTranslations
            }
            
            ReachuLogger.error("Invalid format in translations file: \(fileName).json - Expected format: { \"en\": {...}, \"de\": {...} }", component: "Config")
            return nil
        } catch {
            ReachuLogger.error("Error loading translations file: \(error)", component: "Config")
            return nil
        }
    }
    
    /// Helper struct for decoding translations file wrapper
    private struct TranslationsFileWrapper: Codable {
        let translations: [String: [String: String]]
    }
    
    // MARK: - Stripe Initialization
    
    /// Initialize Stripe automatically by fetching publishable key from Reachu API
    private static func initializeStripeIfAvailable() {
        #if canImport(StripeCore) && os(iOS)
        ReachuLogger.debug("Initializing Stripe payment...", component: "Config")
        
        let defaultPublishableKey = "pk_test_51MvQONBjfRnXLEB43vxVNP53LmkC13ZruLbNqDYIER8GmRgLX97vWKw9gPuhYLuOSwXaXpDFYAKsZhYtBpcAWvcy00zQ9ZES0L"
        
        // Get configuration
        let config = ReachuConfiguration.shared
        guard let baseURL = URL(string: config.environment.graphQLURL) else {
            ReachuLogger.error("Invalid GraphQL URL, using default Stripe key", component: "Config")
            StripeAPI.defaultPublishableKey = defaultPublishableKey
            return
        }
        
        let apiKey = config.apiKey.isEmpty ? "DEMO_KEY" : config.apiKey
        let sdkClient = SdkClient(baseUrl: baseURL, apiKey: apiKey)
        
        Task {
            do {
                // Fetch payment methods from Reachu API
                let paymentMethods = try await sdkClient.payment.getAvailableMethods()
                ReachuLogger.debug("Available payment methods from API: \(paymentMethods.map { $0.name })", component: "Config")
                
                // Find Stripe method and extract publishable key (case-insensitive)
                if let stripeMethod = paymentMethods.first(where: { $0.name.lowercased() == "stripe" }),
                   let publishableKey = stripeMethod.publishableKey {
                    await MainActor.run {
                        StripeAPI.defaultPublishableKey = publishableKey
                        ReachuLogger.debug("Stripe configured with API key: \(publishableKey.prefix(20))...", component: "Config")
                    }
                } else {
                    // Stripe method not found in API, use default
                    await MainActor.run {
                        StripeAPI.defaultPublishableKey = defaultPublishableKey
                        ReachuLogger.warning("Stripe method not found in API, using default key", component: "Config")
                    }
                }
            } catch {
                // API call failed, use default key
                await MainActor.run {
                    StripeAPI.defaultPublishableKey = defaultPublishableKey
                    if let sdkError = error as? SdkException {
                        ReachuLogger.warning("Using default Stripe key - Payment methods fetch failed: \(sdkError.description) - Error code: \(sdkError.code), Status: \(sdkError.status ?? 0)", component: "Config")
                    } else {
                        ReachuLogger.warning("Using default Stripe key - Payment methods fetch failed: \(error.localizedDescription)", component: "Config")
                    }
                }
            }
        }
        #else
        ReachuLogger.debug("Stripe not available on this platform", component: "Config")
        #endif
    }
}

// MARK: - Configuration Errors
// ConfigurationError is defined in ReachuConfiguration.swift

// MARK: - JSON Configuration Models

private struct JSONConfiguration: Codable {
    let apiKey: String
    let campaignId: Int?  // Campaign ID at root level (preferred)
    let environment: String
    let theme: JSONThemeConfiguration?
    let cart: JSONCartConfiguration?
    let network: JSONNetworkConfiguration?
    let ui: JSONUIConfiguration?
    let liveShow: JSONLiveShowConfiguration?
    let marketFallback: JSONMarketFallbackConfiguration?
    let productDetail: JSONProductDetailConfiguration?
    let localization: JSONLocalizationConfiguration?
    let campaigns: JSONCampaignConfiguration?
}

private struct JSONThemeConfiguration: Codable {
    let name: String
    let mode: String?
    let colors: JSONColorConfiguration? // Legacy support
    let lightColors: JSONColorConfiguration?
    let darkColors: JSONColorConfiguration?
    let borderRadius: JSONBorderRadiusConfiguration?
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
    let priceColor: String?  // Customizable product price color
}

private struct JSONBorderRadiusConfiguration: Codable {
    let none: CGFloat?
    let small: CGFloat?
    let medium: CGFloat?
    let large: CGFloat?
    let xl: CGFloat?
    let extraLarge: CGFloat?  // Support both xl and extraLarge from JSON
    let round: CGFloat?  // Support round from JSON (maps to circle)
    let circle: CGFloat?
    
    var normalizedXL: CGFloat? {
        return xl ?? extraLarge
    }
    
    var normalizedCircle: CGFloat? {
        return circle ?? round
    }
}

private struct JSONCartConfiguration: Codable {
    let floatingCartPosition: String
    let floatingCartDisplayMode: String
    let floatingCartSize: String
    let autoSaveCart: Bool
    let showCartNotifications: Bool
    let enableGuestCheckout: Bool
    let requirePhoneNumber: Bool?
    let defaultShippingCountry: String?
    let supportedPaymentMethods: [String]?
}

private struct JSONNetworkConfiguration: Codable {
    let timeout: TimeInterval
    let retryAttempts: Int
    let enableCaching: Bool
    let enableLogging: Bool
}

private struct JSONShadowConfiguration: Codable {
    let cardShadowRadius: CGFloat?
    let cardShadowOpacity: Double?
    let cardShadowOffset: JSONCGSize?
    let cardShadowColor: String?
    let buttonShadowEnabled: Bool?
    let buttonShadowRadius: CGFloat?
    let buttonShadowOpacity: Double?
    let modalShadowRadius: CGFloat?
    let modalShadowOpacity: Double?
    let enableBlurEffects: Bool?
    let blurIntensity: Double?
    let blurStyle: String?
}

private struct JSONCGSize: Codable {
    let width: CGFloat
    let height: CGFloat
}

private struct JSONUIConfiguration: Codable {
    let enableAnimations: Bool
    let showProductBrands: Bool
    let showDiscountBadge: Bool?
    let discountBadgeText: String?
    let enableHapticFeedback: Bool
    let shadowConfig: JSONShadowConfiguration?
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
    
    // Dynamic components configuration
    let campaignId: Int?
    
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

private struct JSONProductDetailConfiguration: Codable {
    let modalHeight: String?
    let imageFullWidth: Bool?
    let imageCornerRadius: CGFloat?
    let imageHeight: CGFloat?
    let showImageGallery: Bool?
    let headerStyle: String?
    let enableImageZoom: Bool?
    let showNavigationTitle: Bool?
    let closeButtonStyle: String?
    let showDescription: Bool?
    let showSpecifications: Bool?
}

private struct JSONLocalizationConfiguration: Codable {
    let defaultLanguage: String?
    let fallbackLanguage: String?
    let translations: [String: [String: String]]?
    let translationsFile: String?  // Nombre del archivo externo con traducciones
}

private struct JSONCampaignConfiguration: Codable {
    let webSocketBaseURL: String?  // WebSocket endpoint (e.g., "https://dev-campaing.reachu.io")
    let restAPIBaseURL: String?    // REST API endpoint (e.g., "https://campaing.reachu.io")
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


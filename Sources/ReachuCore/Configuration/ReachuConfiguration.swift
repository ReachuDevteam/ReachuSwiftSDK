import Foundation
import SwiftUI

/// Reachu SDK Global Configuration
///
/// Centralized configuration system that allows developers to set up the entire SDK
/// once and use it across all modules (Core, UI, LiveShow, etc.) without additional setup.
///
/// **Usage:**
/// ```swift
/// // Configure once in AppDelegate or App.swift
/// ReachuConfiguration.configure(
///     apiKey: "your-api-key",
///     environment: .production,
///     theme: .default
/// )
/// 
/// // Use anywhere in the app
/// RProductCard(product: product) // Uses global config
/// RCheckoutOverlay() // Uses global cart position and colors
/// ```
public class ReachuConfiguration: ObservableObject {
    
    // MARK: - Singleton
    public static let shared = ReachuConfiguration()
    
    // MARK: - Configuration Properties
    @Published public private(set) var apiKey: String = ""
    @Published public private(set) var environment: ReachuEnvironment = .sandbox
    @Published public private(set) var theme: ReachuTheme = .default
    @Published public private(set) var cartConfiguration: CartConfiguration = .default
    @Published public private(set) var networkConfiguration: NetworkConfiguration = .default
    @Published public private(set) var uiConfiguration: UIConfiguration = .default
    @Published public private(set) var liveShowConfiguration: LiveShowConfiguration = .default
    @Published public private(set) var marketConfiguration: MarketConfiguration = .default
    @Published public private(set) var productDetailConfiguration: ProductDetailConfiguration = .default
    @Published public private(set) var localizationConfiguration: LocalizationConfiguration = .default
    @Published public private(set) var campaignConfiguration: CampaignConfiguration = .default
    
    @Published public private(set) var isConfigured: Bool = false
    @Published public private(set) var isMarketAvailable: Bool = true  // If false, SDK should not be used
    @Published public private(set) var userCountryCode: String? = nil  // User's country code if provided
    @Published public private(set) var availableMarkets: [GetAvailableMarketsDto] = []  // List of available markets from backend
    
    private init() {}
    
    // MARK: - Configuration Methods
    
    /// Main configuration method - call once at app startup
    public static func configure(
        apiKey: String,
        environment: ReachuEnvironment = .production,
        theme: ReachuTheme? = nil,
        cartConfig: CartConfiguration? = nil,
        networkConfig: NetworkConfiguration? = nil,
        uiConfig: UIConfiguration? = nil,
        liveShowConfig: LiveShowConfiguration? = nil,
        marketConfig: MarketConfiguration? = nil,
        productDetailConfig: ProductDetailConfiguration? = nil,
        localizationConfig: LocalizationConfiguration? = nil,
        campaignConfig: CampaignConfiguration? = nil
    ) {
        let instance = ReachuConfiguration.shared
        
        instance.apiKey = apiKey
        instance.environment = environment
        instance.theme = theme ?? .default
        instance.cartConfiguration = cartConfig ?? .default
        instance.networkConfiguration = networkConfig ?? .default
        instance.uiConfiguration = uiConfig ?? .default
        instance.liveShowConfiguration = liveShowConfig ?? .default
        instance.marketConfiguration = marketConfig ?? .default
        instance.productDetailConfiguration = productDetailConfig ?? .default
        instance.localizationConfiguration = localizationConfig ?? .default
        instance.campaignConfiguration = campaignConfig ?? .default
        
        // Configure localization system
        ReachuLocalization.shared.configure(instance.localizationConfiguration)
        
        instance.isConfigured = true
        
        // Initialize CampaignManager with new configuration
        Task { @MainActor in
            CampaignManager.shared.reinitialize()
        }
    }
    
    /// Quick configuration with just API key (uses defaults for everything else)
    public static func configure(apiKey: String) {
        configure(
            apiKey: apiKey,
            environment: .production,
            theme: nil,
            cartConfig: nil,
            networkConfig: nil,
            uiConfig: nil,
            liveShowConfig: nil
        )
    }
    
    /// Map country codes to language codes
    /// Used to automatically select language based on market
    private static func languageCodeForCountry(_ countryCode: String?) -> String {
        guard let countryCode = countryCode?.uppercased() else { return "en" }
        
        // Map country codes to language codes
        let countryToLanguage: [String: String] = [
            "DE": "de",  // Germany → German
            "AT": "de",  // Austria → German
            "CH": "de",  // Switzerland → German
            "US": "en",  // United States → English
            "GB": "en",  // United Kingdom → English
            "CA": "en",  // Canada → English
            "AU": "en",  // Australia → English
            "NO": "no",  // Norway → Norwegian
            "SE": "sv",  // Sweden → Swedish
            "DK": "da",  // Denmark → Danish
            "FI": "fi",  // Finland → Finnish
            "ES": "es",  // Spain → Spanish
            "FR": "fr",  // France → French
            "IT": "it",  // Italy → Italian
            "NL": "nl",  // Netherlands → Dutch
            "PL": "pl",  // Poland → Polish
            "PT": "pt",  // Portugal → Portuguese
            "BR": "pt",  // Brazil → Portuguese
            "MX": "es",  // Mexico → Spanish
            "AR": "es",  // Argentina → Spanish
            "CL": "es",  // Chile → Spanish
            "CO": "es",  // Colombia → Spanish
            "JP": "ja",  // Japan → Japanese
            "CN": "zh",  // China → Chinese
            "KR": "ko",  // South Korea → Korean
        ]
        
        return countryToLanguage[countryCode] ?? "en"  // Default to English
    }
    
    /// Set market availability status and store available markets
    /// Also automatically updates language based on country code
    internal static func setMarketAvailable(_ available: Bool, userCountryCode: String? = nil, availableMarkets: [GetAvailableMarketsDto] = []) {
        shared.isMarketAvailable = available
        shared.userCountryCode = userCountryCode
        shared.availableMarkets = availableMarkets
        
        // Automatically update language based on country code
        if let countryCode = userCountryCode {
            let languageCode = languageCodeForCountry(countryCode)
            let localizationConfig = shared.localizationConfiguration
            
            // Check if translations exist for this language
            let hasTranslations = localizationConfig.translations[languageCode] != nil
            
            if hasTranslations {
                // Update language if translations are available
                ReachuLocalization.shared.setLanguage(languageCode)
            } else {
                // Use default language if translations not available
                let defaultLang = localizationConfig.defaultLanguage
                ReachuLocalization.shared.setLanguage(defaultLang)
            }
        }
    }
    
    /// Check if a specific country code is available in the markets list
    /// Returns true if the country is in the available markets list
    /// 
    /// **Usage:**
    /// ```swift
    /// if ReachuConfiguration.shared.isMarketAvailableForCountry("DE") {
    ///     // Show Germany-specific content
    /// }
    /// ```
    public func isMarketAvailableForCountry(_ countryCode: String) -> Bool {
        guard !availableMarkets.isEmpty else {
            // If markets list is empty, assume available (backward compatibility)
            return true
        }
        let upperCountryCode = countryCode.uppercased()
        return availableMarkets.contains { $0.code?.uppercased() == upperCountryCode }
    }
    
    /// Get market info for a specific country code
    /// Returns the full market information including currency, phone code, flag, etc.
    /// 
    /// **Usage:**
    /// ```swift
    /// if let marketInfo = ReachuConfiguration.shared.getMarketInfo(for: "DE") {
    ///     print("Currency: \(marketInfo.currency?.code ?? "EUR")")
    ///     print("Phone code: \(marketInfo.phoneCode ?? "+49")")
    /// }
    /// ```
    public func getMarketInfo(for countryCode: String) -> GetAvailableMarketsDto? {
        let upperCountryCode = countryCode.uppercased()
        return availableMarkets.first { $0.code?.uppercased() == upperCountryCode }
    }
    
    /// Check if SDK should be used (market is available)
    public var shouldUseSDK: Bool {
        return isConfigured && isMarketAvailable
    }
    
    /// Update specific configurations after initial setup
    public static func updateTheme(_ theme: ReachuTheme) {
        shared.theme = theme
    }
    
    public static func updateCartConfiguration(_ config: CartConfiguration) {
        shared.cartConfiguration = config
    }
    
    // MARK: - Validation
    
    public var isValidConfiguration: Bool {
        return isConfigured && !apiKey.isEmpty
    }
    
    public func validateConfiguration() throws {
        guard isConfigured else {
            throw ConfigurationError.notConfigured
        }
        
        guard !apiKey.isEmpty else {
            throw ConfigurationError.missingAPIKey
        }
        
        // Additional validations can be added here
    }
}

// MARK: - Environment

public enum ReachuEnvironment: String, CaseIterable {
    case development = "development"
    case sandbox = "sandbox"
    case production = "production"
    
    public var baseURL: String {
        switch self {
        case .development:
            return "https://graph-ql-dev.reachu.io"
        case .sandbox:
            return "https://graph-ql-dev.reachu.io"  // Sandbox uses same endpoint as development
        case .production:
            return "https://graph-ql-dev.reachu.io"  // Same as development for now
        }
    }
    
    public var graphQLURL: String {
        return "\(baseURL)/graphql"
    }
}

// MARK: - Configuration Errors

public enum ConfigurationError: LocalizedError {
    case notConfigured
    case missingAPIKey
    case invalidEnvironment
    case invalidTheme
    case fileNotFound(fileName: String)
    case invalidJSON
    case invalidPlist
    
    public var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Reachu SDK is not configured. Call ReachuConfiguration.configure() first."
        case .missingAPIKey:
            return "API Key is required for Reachu SDK configuration."
        case .invalidEnvironment:
            return "Invalid environment specified."
        case .invalidTheme:
            return "Invalid theme configuration."
        case .fileNotFound(let fileName):
            return "Configuration file '\(fileName)' not found in app bundle."
        case .invalidJSON:
            return "Invalid JSON configuration format."
        case .invalidPlist:
            return "Invalid Plist configuration format."
        }
    }
}

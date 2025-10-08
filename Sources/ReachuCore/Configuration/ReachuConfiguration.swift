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
    
    @Published public private(set) var isConfigured: Bool = false
    
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
        marketConfig: MarketConfiguration? = nil
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
        instance.isConfigured = true
        
        print("🔧 Reachu SDK configured successfully")
        print("   API Key: \(apiKey.prefix(8))...")
        print("   Environment: \(environment)")
        print("   Theme: \(instance.theme.name)")
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
            return "https://api-sandbox.reachu.io"
        case .production:
            return "https://api.reachu.io"
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

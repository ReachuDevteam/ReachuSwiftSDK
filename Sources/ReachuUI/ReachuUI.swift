import SwiftUI
import ReachuCore

/// Reachu UI Components
/// 
/// Optional target for pre-built SwiftUI components
/// Import this target to get ready-to-use UI components for Reachu functionality

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public struct ReachuUI {
    
    /// Configure ReachuUI with default settings
    /// This ensures localization is set up even if no configuration file is provided
    public static func configure() {
        // Ensure localization is initialized with defaults if not already configured
        if !ReachuConfiguration.shared.isConfigured {
            // If SDK hasn't been configured, set up minimal defaults
            ReachuConfiguration.configure(
                apiKey: "",
                environment: .sandbox
            )
        }
        
        // Ensure localization system is initialized with default English translations
        let currentConfig = ReachuConfiguration.shared.localizationConfiguration
        if currentConfig.translations.isEmpty {
            // Use default English translations
            ReachuLocalization.shared.configure(.default)
        } else {
            // Already configured, just ensure it's set
            ReachuLocalization.shared.configure(currentConfig)
        }
        
        print("🎨 Reachu UI components initialized")
        print("🌍 Localization: \(ReachuLocalization.shared.language)")
    }
}

// MARK: - Public Exports

// Export cart management
public typealias ReachuCartManager = CartManager

// Export UI components
public typealias ReachuProductCard = RProductCard
public typealias ReachuProductSlider = RProductSlider
public typealias ReachuCheckoutOverlay = RCheckoutOverlay
public typealias ReachuProductDetailOverlay = RProductDetailOverlay

// Export UX enhancement components
public typealias ReachuFloatingCartIndicator = RFloatingCartIndicator

// Export offer banner components
public typealias ReachuOfferBanner = ROfferBanner
public typealias ReachuOfferBannerContainer = ROfferBannerContainer

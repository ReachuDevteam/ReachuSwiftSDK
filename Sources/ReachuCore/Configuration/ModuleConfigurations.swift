import Foundation
import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

// MARK: - Cart Configuration

/// Configuration for cart behavior and appearance
public struct CartConfiguration {
    
    // Cart Position
    public let floatingCartPosition: FloatingCartPosition
    public let floatingCartDisplayMode: FloatingCartDisplayMode
    public let floatingCartSize: FloatingCartSize
    
    // Cart Behavior
    public let autoSaveCart: Bool
    public let cartPersistenceKey: String
    public let maxQuantityPerItem: Int
    public let showCartNotifications: Bool
    
    // Checkout Configuration
    public let enableGuestCheckout: Bool
    public let requirePhoneNumber: Bool
    public let defaultShippingCountry: String
    public let supportedPaymentMethods: [String]
    
    public init(
        floatingCartPosition: FloatingCartPosition = .bottomRight,
        floatingCartDisplayMode: FloatingCartDisplayMode = .minimal,
        floatingCartSize: FloatingCartSize = .small,
        autoSaveCart: Bool = true,
        cartPersistenceKey: String = "reachu_cart",
        maxQuantityPerItem: Int = 99,
        showCartNotifications: Bool = true,
        enableGuestCheckout: Bool = true,
        requirePhoneNumber: Bool = true,
        defaultShippingCountry: String = "US",
        supportedPaymentMethods: [String] = ["stripe", "klarna", "paypal"]
    ) {
        self.floatingCartPosition = floatingCartPosition
        self.floatingCartDisplayMode = floatingCartDisplayMode
        self.floatingCartSize = floatingCartSize
        self.autoSaveCart = autoSaveCart
        self.cartPersistenceKey = cartPersistenceKey
        self.maxQuantityPerItem = maxQuantityPerItem
        self.showCartNotifications = showCartNotifications
        self.enableGuestCheckout = enableGuestCheckout
        self.requirePhoneNumber = requirePhoneNumber
        self.defaultShippingCountry = defaultShippingCountry
        self.supportedPaymentMethods = supportedPaymentMethods
    }
    
    public static let `default` = CartConfiguration()
}

// MARK: - Floating Cart Enums

public enum FloatingCartPosition: String, CaseIterable {
    case topLeft = "topLeft"
    case topCenter = "topCenter"
    case topRight = "topRight"
    case centerLeft = "centerLeft"
    case centerRight = "centerRight"
    case bottomLeft = "bottomLeft"
    case bottomCenter = "bottomCenter"
    case bottomRight = "bottomRight"
}

public enum FloatingCartDisplayMode: String, CaseIterable {
    case full = "full"
    case compact = "compact"
    case minimal = "minimal"
    case iconOnly = "iconOnly"
}

public enum FloatingCartSize: String, CaseIterable {
    case small = "small"
    case medium = "medium"
    case large = "large"
}

// MARK: - Market Configuration

/// Fallback configuration for markets and currency
public struct MarketConfiguration {
    public let countryCode: String
    public let countryName: String
    public let currencyCode: String
    public let currencySymbol: String
    public let phoneCode: String
    public let flagURL: String?

    public init(
        countryCode: String = "US",
        countryName: String = "United States",
        currencyCode: String = "USD",
        currencySymbol: String = "$",
        phoneCode: String = "+1",
        flagURL: String? = "https://flagcdn.com/w320/us.png"
    ) {
        self.countryCode = countryCode
        self.countryName = countryName
        self.currencyCode = currencyCode
        self.currencySymbol = currencySymbol
        self.phoneCode = phoneCode
        self.flagURL = flagURL
    }

    public static let `default` = MarketConfiguration()
}

// MARK: - Network Configuration

/// Configuration for network requests and API behavior
public struct NetworkConfiguration {
    
    // Request Configuration
    public let timeout: TimeInterval
    public let retryAttempts: Int
    public let enableCaching: Bool
    public let cacheDuration: TimeInterval
    
    // GraphQL Configuration
    public let enableQueryBatching: Bool
    public let enableSubscriptions: Bool
    
    // Performance Configuration
    public let maxConcurrentRequests: Int
    public let requestPriority: RequestPriority
    public let enableCompression: Bool
    
    // Security Configuration
    public let enableSSLPinning: Bool
    public let trustedHosts: [String]
    public let enableCertificateValidation: Bool
    
    // Debug Configuration
    public let enableLogging: Bool
    public let logLevel: LogLevel
    public let enableNetworkInspector: Bool
    
    // Custom Headers
    public let customHeaders: [String: String]
    
    // Offline Configuration
    public let enableOfflineMode: Bool
    public let offlineCacheDuration: TimeInterval
    public let syncStrategy: SyncStrategy
    
    public init(
        timeout: TimeInterval = 30.0,
        retryAttempts: Int = 3,
        enableCaching: Bool = true,
        cacheDuration: TimeInterval = 300, // 5 minutes
        enableQueryBatching: Bool = true,
        enableSubscriptions: Bool = false,
        maxConcurrentRequests: Int = 6,
        requestPriority: RequestPriority = .normal,
        enableCompression: Bool = true,
        enableSSLPinning: Bool = false,
        trustedHosts: [String] = [],
        enableCertificateValidation: Bool = true,
        enableLogging: Bool = false,
        logLevel: LogLevel = .info,
        enableNetworkInspector: Bool = false,
        customHeaders: [String: String] = [:],
        enableOfflineMode: Bool = false,
        offlineCacheDuration: TimeInterval = 86400, // 24 hours
        syncStrategy: SyncStrategy = .automatic
    ) {
        self.timeout = timeout
        self.retryAttempts = retryAttempts
        self.enableCaching = enableCaching
        self.cacheDuration = cacheDuration
        self.enableQueryBatching = enableQueryBatching
        self.enableSubscriptions = enableSubscriptions
        self.maxConcurrentRequests = maxConcurrentRequests
        self.requestPriority = requestPriority
        self.enableCompression = enableCompression
        self.enableSSLPinning = enableSSLPinning
        self.trustedHosts = trustedHosts
        self.enableCertificateValidation = enableCertificateValidation
        self.enableLogging = enableLogging
        self.logLevel = logLevel
        self.enableNetworkInspector = enableNetworkInspector
        self.customHeaders = customHeaders
        self.enableOfflineMode = enableOfflineMode
        self.offlineCacheDuration = offlineCacheDuration
        self.syncStrategy = syncStrategy
    }
    
    public static let `default` = NetworkConfiguration()
}

public enum LogLevel: String, CaseIterable {
    case debug = "debug"
    case info = "info"
    case warning = "warning"
    case error = "error"
}

// MARK: - UI Configuration

/// Configuration for UI components behavior and appearance
public struct UIConfiguration {
    
    // Product Cards
    public let defaultProductCardVariant: ProductCardVariant
    public let enableProductCardAnimations: Bool
    public let showProductBrands: Bool
    public let showProductDescriptions: Bool
    public let showDiscountBadge: Bool
    public let discountBadgeText: String?
    
    // Product Sliders
    public let defaultSliderLayout: ProductSliderLayout
    public let enableSliderPagination: Bool
    public let maxSliderItems: Int
    
    // Images
    public let imageQuality: ImageQuality
    public let enableImageCaching: Bool
    public let placeholderImageType: PlaceholderImageType
    
    // Typography
    public let typographyConfig: TypographyConfiguration
    
    // Shadows & Effects
    public let shadowConfig: ShadowConfiguration
    
    // Animations
    public let animationConfig: AnimationConfiguration
    
    // Layout & Spacing
    public let layoutConfig: LayoutConfiguration
    
    // Accessibility
    public let accessibilityConfig: AccessibilityConfiguration
    
    // Legacy (for backward compatibility)
    public let enableAnimations: Bool
    public let animationDuration: TimeInterval
    public let enableHapticFeedback: Bool
    
    public init(
        defaultProductCardVariant: ProductCardVariant = .grid,
        enableProductCardAnimations: Bool = true,
        showProductBrands: Bool = true,
        showProductDescriptions: Bool = false,
        showDiscountBadge: Bool = false,
        discountBadgeText: String? = nil,
        defaultSliderLayout: ProductSliderLayout = .cards,
        enableSliderPagination: Bool = true,
        maxSliderItems: Int = 20,
        imageQuality: ImageQuality = .medium,
        enableImageCaching: Bool = true,
        placeholderImageType: PlaceholderImageType = .shimmer,
        typographyConfig: TypographyConfiguration = .default,
        shadowConfig: ShadowConfiguration = .default,
        animationConfig: AnimationConfiguration = .default,
        layoutConfig: LayoutConfiguration = .default,
        accessibilityConfig: AccessibilityConfiguration = .default,
        // Legacy parameters for backward compatibility
        enableAnimations: Bool = true,
        animationDuration: TimeInterval = 0.3,
        enableHapticFeedback: Bool = true
    ) {
        self.defaultProductCardVariant = defaultProductCardVariant
        self.enableProductCardAnimations = enableProductCardAnimations
        self.showProductBrands = showProductBrands
        self.showProductDescriptions = showProductDescriptions
        self.showDiscountBadge = showDiscountBadge
        self.discountBadgeText = discountBadgeText
        self.defaultSliderLayout = defaultSliderLayout
        self.enableSliderPagination = enableSliderPagination
        self.maxSliderItems = maxSliderItems
        self.imageQuality = imageQuality
        self.enableImageCaching = enableImageCaching
        self.placeholderImageType = placeholderImageType
        self.typographyConfig = typographyConfig
        self.shadowConfig = shadowConfig
        self.animationConfig = animationConfig
        self.layoutConfig = layoutConfig
        self.accessibilityConfig = accessibilityConfig
        // Legacy properties
        self.enableAnimations = enableAnimations
        self.animationDuration = animationDuration
        self.enableHapticFeedback = enableHapticFeedback
    }
    
    public static let `default` = UIConfiguration()
}

// MARK: - Product Detail Configuration

/// Configuration for product detail modal appearance and behavior
public struct ProductDetailConfiguration {
    // Modal Appearance
    public let modalHeight: ProductDetailModalHeight
    public let imageFullWidth: Bool
    public let imageCornerRadius: CGFloat
    public let imageHeight: CGFloat?
    public let showImageGallery: Bool
    public let headerStyle: ProductDetailHeaderStyle
    public let enableImageZoom: Bool
    
    // Header Options
    public let showNavigationTitle: Bool
    public let closeButtonStyle: CloseButtonStyle
    
    // Content Sections
    public let showDescription: Bool
    public let showSpecifications: Bool
    
    // Additional Options
    public let showCloseButton: Bool
    public let dismissOnTapOutside: Bool
    public let enableShareButton: Bool
    
    public init(
        modalHeight: ProductDetailModalHeight = .full,
        imageFullWidth: Bool = false,
        imageCornerRadius: CGFloat = 12,
        imageHeight: CGFloat? = nil,
        showImageGallery: Bool = true,
        headerStyle: ProductDetailHeaderStyle = .standard,
        enableImageZoom: Bool = true,
        showNavigationTitle: Bool = true,
        closeButtonStyle: CloseButtonStyle = .navigationBar,
        showDescription: Bool = true,
        showSpecifications: Bool = true,
        showCloseButton: Bool = true,
        dismissOnTapOutside: Bool = true,
        enableShareButton: Bool = false
    ) {
        self.modalHeight = modalHeight
        self.imageFullWidth = imageFullWidth
        self.imageCornerRadius = imageCornerRadius
        self.imageHeight = imageHeight
        self.showImageGallery = showImageGallery
        self.headerStyle = headerStyle
        self.enableImageZoom = enableImageZoom
        self.showNavigationTitle = showNavigationTitle
        self.closeButtonStyle = closeButtonStyle
        self.showDescription = showDescription
        self.showSpecifications = showSpecifications
        self.showCloseButton = showCloseButton
        self.dismissOnTapOutside = dismissOnTapOutside
        self.enableShareButton = enableShareButton
    }
    
    public static let `default` = ProductDetailConfiguration()
}

public enum ProductDetailModalHeight: String, CaseIterable {
    case full = "full"
    case threeQuarters = "threeQuarters"
    case half = "half"
    
    public var fraction: CGFloat {
        switch self {
        case .full: return 1.0
        case .threeQuarters: return 0.75
        case .half: return 0.5
        }
    }
}

public enum ProductDetailHeaderStyle: String, CaseIterable {
    case standard = "standard"
    case compact = "compact"
}

public enum CloseButtonStyle: String, CaseIterable {
    case navigationBar = "navigationBar"
    case overlayTopLeft = "overlayTopLeft"
    case overlayTopRight = "overlayTopRight"
}

// MARK: - UI Enums

public enum ProductCardVariant: String, CaseIterable {
    case grid = "grid"
    case list = "list"
    case hero = "hero"
    case minimal = "minimal"
}

public enum ProductSliderLayout: String, CaseIterable {
    case compact = "compact"
    case cards = "cards"
    case featured = "featured"
    case wide = "wide"
    case showcase = "showcase"
    case micro = "micro"
}

public enum ImageQuality: String, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
}

public enum PlaceholderImageType: String, CaseIterable {
    case shimmer = "shimmer"
    case blurred = "blurred"
    case solid = "solid"
    case none = "none"
}

// MARK: - LiveShow Configuration

/// Configuration for LiveShow functionality
public struct LiveShowConfiguration {
    
    // Stream Configuration
    public let autoJoinChat: Bool
    public let enableChatModeration: Bool
    public let maxChatMessageLength: Int
    public let enableEmojis: Bool
    
    // Shopping Integration
    public let enableShoppingDuringStream: Bool
    public let showProductOverlays: Bool
    public let enableQuickBuy: Bool
    
    // Notifications
    public let enableStreamNotifications: Bool
    public let enableProductNotifications: Bool
    public let enableChatNotifications: Bool
    
    // Video Configuration
    public let videoQuality: VideoQuality
    public let enableAutoplay: Bool
    public let enablePictureInPicture: Bool
    
    // Tipio Integration
    public let tipioApiKey: String
    public let tipioBaseUrl: String
    
    // Dynamic Components
    public let campaignId: Int  // 0 = no campaign (SDK works normally)
    
    public init(
        autoJoinChat: Bool = true,
        enableChatModeration: Bool = true,
        maxChatMessageLength: Int = 200,
        enableEmojis: Bool = true,
        enableShoppingDuringStream: Bool = true,
        showProductOverlays: Bool = true,
        enableQuickBuy: Bool = true,
        enableStreamNotifications: Bool = true,
        enableProductNotifications: Bool = true,
        enableChatNotifications: Bool = false,
        videoQuality: VideoQuality = .auto,
        enableAutoplay: Bool = false,
        enablePictureInPicture: Bool = true,
        tipioApiKey: String = "",
        tipioBaseUrl: String = "https://stg-dev-microservices.tipioapp.com",
        campaignId: Int = 0  // Default to 0 (no campaign restrictions)
    ) {
        self.autoJoinChat = autoJoinChat
        self.enableChatModeration = enableChatModeration
        self.maxChatMessageLength = maxChatMessageLength
        self.enableEmojis = enableEmojis
        self.enableShoppingDuringStream = enableShoppingDuringStream
        self.showProductOverlays = showProductOverlays
        self.enableQuickBuy = enableQuickBuy
        self.enableStreamNotifications = enableStreamNotifications
        self.enableProductNotifications = enableProductNotifications
        self.enableChatNotifications = enableChatNotifications
        self.videoQuality = videoQuality
        self.enableAutoplay = enableAutoplay
        self.enablePictureInPicture = enablePictureInPicture
        self.tipioApiKey = tipioApiKey
        self.tipioBaseUrl = tipioBaseUrl
        self.campaignId = campaignId
    }
    
    public static let `default` = LiveShowConfiguration()
}

// MARK: - Campaign Configuration

/// Configuration for Campaign endpoints
public struct CampaignConfiguration {
    public let webSocketBaseURL: String  // WebSocket endpoint for campaigns (e.g., "https://dev-campaing.reachu.io")
    public let restAPIBaseURL: String    // REST API endpoint for campaigns (same as WebSocket base URL)
    /// API key for campaign admin endpoints (different from SDK API key)
    /// Used for endpoints like GET /v1/sdk/config and GET /v1/offers
    /// Configured in reachu-config.json under "campaigns.campaignAdminApiKey"
    /// Only needed if autoDiscover is false (legacy mode)
    public let campaignAdminApiKey: String
    /// Enable auto-discovery of campaigns using only the Reachu SDK API key
    /// When true, campaigns are discovered automatically via GET /v1/sdk/campaigns
    /// When false, uses legacy mode with campaignId from configuration
    public let autoDiscover: Bool
    /// Optional channel ID to filter campaigns during auto-discovery
    public let channelId: Int?
    
    public init(
        webSocketBaseURL: String = "https://dev-campaing.reachu.io",
        restAPIBaseURL: String = "https://dev-campaing.reachu.io",
        campaignAdminApiKey: String = "",
        autoDiscover: Bool = false,
        channelId: Int? = nil
    ) {
        self.webSocketBaseURL = webSocketBaseURL
        self.restAPIBaseURL = restAPIBaseURL
        self.campaignAdminApiKey = campaignAdminApiKey
        self.autoDiscover = autoDiscover
        self.channelId = channelId
    }
    
    public static let `default` = CampaignConfiguration()
}

public enum VideoQuality: String, CaseIterable {
    case low = "240p"
    case medium = "480p"
    case high = "720p"
    case hd = "1080p"
    case auto = "auto"
}

// MARK: - Advanced UI Configurations

/// Typography configuration for custom fonts and text styling
public struct TypographyConfiguration {
    // Custom Fonts
    public let fontFamily: String?
    public let enableCustomFonts: Bool
    public let fontWeightMapping: FontWeightMapping
    
    // Dynamic Type Support
    public let supportDynamicType: Bool
    public let minFontScale: CGFloat
    public let maxFontScale: CGFloat
    
    // Text Styling
    public let lineHeightMultiplier: CGFloat
    public let letterSpacing: CGFloat
    public let textAlignment: TextAlignment
    
    public init(
        fontFamily: String? = nil,
        enableCustomFonts: Bool = false,
        fontWeightMapping: FontWeightMapping = .default,
        supportDynamicType: Bool = true,
        minFontScale: CGFloat = 0.8,
        maxFontScale: CGFloat = 1.4,
        lineHeightMultiplier: CGFloat = 1.2,
        letterSpacing: CGFloat = 0.0,
        textAlignment: TextAlignment = .natural
    ) {
        self.fontFamily = fontFamily
        self.enableCustomFonts = enableCustomFonts
        self.fontWeightMapping = fontWeightMapping
        self.supportDynamicType = supportDynamicType
        self.minFontScale = minFontScale
        self.maxFontScale = maxFontScale
        self.lineHeightMultiplier = lineHeightMultiplier
        self.letterSpacing = letterSpacing
        self.textAlignment = textAlignment
    }
    
    public static let `default` = TypographyConfiguration()
}

/// Font weight mapping for custom fonts
public struct FontWeightMapping {
    public let light: String
    public let regular: String
    public let medium: String
    public let semibold: String
    public let bold: String
    
    public init(
        light: String = "Light",
        regular: String = "Regular",
        medium: String = "Medium",
        semibold: String = "Semibold",
        bold: String = "Bold"
    ) {
        self.light = light
        self.regular = regular
        self.medium = medium
        self.semibold = semibold
        self.bold = bold
    }
    
    public static let `default` = FontWeightMapping()
}

/// Shadow and visual effects configuration
public struct ShadowConfiguration {
    // Card Shadows
    public let cardShadowRadius: CGFloat
    public let cardShadowOpacity: Double
    public let cardShadowOffset: CGSize
    public let cardShadowColor: ShadowColor
    
    // Button Shadows
    public let buttonShadowEnabled: Bool
    public let buttonShadowRadius: CGFloat
    public let buttonShadowOpacity: Double
    
    // Modal Shadows
    public let modalShadowRadius: CGFloat
    public let modalShadowOpacity: Double
    
    // Blur Effects
    public let enableBlurEffects: Bool
    public let blurIntensity: Double
    public let blurStyle: BlurStyle
    
    public init(
        cardShadowRadius: CGFloat = 4,
        cardShadowOpacity: Double = 0.1,
        cardShadowOffset: CGSize = CGSize(width: 0, height: 2),
        cardShadowColor: ShadowColor = .adaptive,
        buttonShadowEnabled: Bool = true,
        buttonShadowRadius: CGFloat = 2,
        buttonShadowOpacity: Double = 0.15,
        modalShadowRadius: CGFloat = 20,
        modalShadowOpacity: Double = 0.3,
        enableBlurEffects: Bool = true,
        blurIntensity: Double = 0.3,
        blurStyle: BlurStyle = .systemMaterial
    ) {
        self.cardShadowRadius = cardShadowRadius
        self.cardShadowOpacity = cardShadowOpacity
        self.cardShadowOffset = cardShadowOffset
        self.cardShadowColor = cardShadowColor
        self.buttonShadowEnabled = buttonShadowEnabled
        self.buttonShadowRadius = buttonShadowRadius
        self.buttonShadowOpacity = buttonShadowOpacity
        self.modalShadowRadius = modalShadowRadius
        self.modalShadowOpacity = modalShadowOpacity
        self.enableBlurEffects = enableBlurEffects
        self.blurIntensity = blurIntensity
        self.blurStyle = blurStyle
    }
    
    public static let `default` = ShadowConfiguration()
}

/// Animation configuration for motion and transitions
public struct AnimationConfiguration {
    // Timing
    public let defaultDuration: TimeInterval
    public let springResponse: Double
    public let springDamping: Double
    
    // Animation Types
    public let enableSpringAnimations: Bool
    public let enableMicroInteractions: Bool
    public let enablePageTransitions: Bool
    public let enableSharedElementTransitions: Bool
    
    // Easing
    public let defaultEasing: AnimationEasing
    public let customTimingCurve: (Double, Double, Double, Double)?
    
    // Performance
    public let respectReduceMotion: Bool
    public let animationQuality: AnimationQuality
    public let enableHardwareAcceleration: Bool
    
    public init(
        defaultDuration: TimeInterval = 0.3,
        springResponse: Double = 0.4,
        springDamping: Double = 0.8,
        enableSpringAnimations: Bool = true,
        enableMicroInteractions: Bool = true,
        enablePageTransitions: Bool = true,
        enableSharedElementTransitions: Bool = false,
        defaultEasing: AnimationEasing = .easeInOut,
        customTimingCurve: (Double, Double, Double, Double)? = nil,
        respectReduceMotion: Bool = true,
        animationQuality: AnimationQuality = .high,
        enableHardwareAcceleration: Bool = true
    ) {
        self.defaultDuration = defaultDuration
        self.springResponse = springResponse
        self.springDamping = springDamping
        self.enableSpringAnimations = enableSpringAnimations
        self.enableMicroInteractions = enableMicroInteractions
        self.enablePageTransitions = enablePageTransitions
        self.enableSharedElementTransitions = enableSharedElementTransitions
        self.defaultEasing = defaultEasing
        self.customTimingCurve = customTimingCurve
        self.respectReduceMotion = respectReduceMotion
        self.animationQuality = animationQuality
        self.enableHardwareAcceleration = enableHardwareAcceleration
    }
    
    public static let `default` = AnimationConfiguration()
}

/// Layout and spacing configuration
public struct LayoutConfiguration {
    // Grid System
    public let gridColumns: Int
    public let gridSpacing: CGFloat
    public let gridMinItemWidth: CGFloat
    public let gridMaxItemWidth: CGFloat?
    
    // Safe Areas
    public let respectSafeAreas: Bool
    public let customSafeAreaInsets: EdgeInsets?
    public let extendThroughSafeArea: Bool
    
    // Responsive Design
    public let compactWidthThreshold: CGFloat
    public let regularWidthThreshold: CGFloat
    public let enableResponsiveLayout: Bool
    
    // Margins and Padding
    public let screenMargins: CGFloat
    public let sectionSpacing: CGFloat
    public let componentSpacing: CGFloat
    
    public init(
        gridColumns: Int = 2,
        gridSpacing: CGFloat = 16,
        gridMinItemWidth: CGFloat = 150,
        gridMaxItemWidth: CGFloat? = nil,
        respectSafeAreas: Bool = true,
        customSafeAreaInsets: EdgeInsets? = nil,
        extendThroughSafeArea: Bool = false,
        compactWidthThreshold: CGFloat = 768,
        regularWidthThreshold: CGFloat = 1024,
        enableResponsiveLayout: Bool = true,
        screenMargins: CGFloat = 16,
        sectionSpacing: CGFloat = 24,
        componentSpacing: CGFloat = 16
    ) {
        self.gridColumns = gridColumns
        self.gridSpacing = gridSpacing
        self.gridMinItemWidth = gridMinItemWidth
        self.gridMaxItemWidth = gridMaxItemWidth
        self.respectSafeAreas = respectSafeAreas
        self.customSafeAreaInsets = customSafeAreaInsets
        self.extendThroughSafeArea = extendThroughSafeArea
        self.compactWidthThreshold = compactWidthThreshold
        self.regularWidthThreshold = regularWidthThreshold
        self.enableResponsiveLayout = enableResponsiveLayout
        self.screenMargins = screenMargins
        self.sectionSpacing = sectionSpacing
        self.componentSpacing = componentSpacing
    }
    
    public static let `default` = LayoutConfiguration()
}

/// Accessibility configuration
public struct AccessibilityConfiguration {
    // Voice Over
    public let enableVoiceOverOptimizations: Bool
    public let customVoiceOverLabels: [String: String]
    
    // Dynamic Type
    public let enableDynamicTypeSupport: Bool
    public let maxDynamicTypeSize: DynamicTypeSize
    
    // Contrast & Colors
    public let respectHighContrastMode: Bool
    public let enableColorBlindnessSupport: Bool
    public let contrastRatio: ContrastRatio
    
    // Motion & Animations
    public let respectReduceMotion: Bool
    public let alternativeToAnimations: Bool
    
    // Touch & Interaction
    public let minimumTouchTargetSize: CGFloat
    public let enableHapticFeedback: Bool
    public let hapticIntensity: HapticIntensity
    
    public init(
        enableVoiceOverOptimizations: Bool = true,
        customVoiceOverLabels: [String: String] = [:],
        enableDynamicTypeSupport: Bool = true,
        maxDynamicTypeSize: DynamicTypeSize = .accessibility3,
        respectHighContrastMode: Bool = true,
        enableColorBlindnessSupport: Bool = false,
        contrastRatio: ContrastRatio = .aa,
        respectReduceMotion: Bool = true,
        alternativeToAnimations: Bool = true,
        minimumTouchTargetSize: CGFloat = 44,
        enableHapticFeedback: Bool = true,
        hapticIntensity: HapticIntensity = .medium
    ) {
        self.enableVoiceOverOptimizations = enableVoiceOverOptimizations
        self.customVoiceOverLabels = customVoiceOverLabels
        self.enableDynamicTypeSupport = enableDynamicTypeSupport
        self.maxDynamicTypeSize = maxDynamicTypeSize
        self.respectHighContrastMode = respectHighContrastMode
        self.enableColorBlindnessSupport = enableColorBlindnessSupport
        self.contrastRatio = contrastRatio
        self.respectReduceMotion = respectReduceMotion
        self.alternativeToAnimations = alternativeToAnimations
        self.minimumTouchTargetSize = minimumTouchTargetSize
        self.enableHapticFeedback = enableHapticFeedback
        self.hapticIntensity = hapticIntensity
    }
    
    public static let `default` = AccessibilityConfiguration()
}

// MARK: - Brand Configuration

/// Configuration for brand name and icon used in engagement components
public struct BrandConfiguration {
    /// Brand name displayed in engagement components (e.g., "Power", "Elkjøp")
    public let name: String
    
    /// Brand icon asset name (e.g., "avatar_power", "avatar_elkjop")
    public let iconAsset: String
    
    public init(
        name: String = "Elkjøp",
        iconAsset: String = "avatar_el"
    ) {
        self.name = name
        self.iconAsset = iconAsset
    }
    
    public static let `default` = BrandConfiguration()
    
    /// Legacy Power brand configuration (preserved for reference)
    public static let power = BrandConfiguration(
        name: "Power",
        iconAsset: "avatar_power"
    )
    
    /// Elkjøp brand configuration
    public static let elkjøp = BrandConfiguration(
        name: "Elkjøp",
        iconAsset: "avatar_elkjop"
    )
}

// MARK: - Supporting Enums

public enum TextAlignment: String, CaseIterable {
    case leading = "leading"
    case center = "center"
    case trailing = "trailing"
    case natural = "natural"
}

public enum ShadowColor: String, CaseIterable {
    case black = "black"
    case gray = "gray"
    case adaptive = "adaptive"
    case custom = "custom"
}

public enum BlurStyle: String, CaseIterable {
    case systemMaterial = "systemMaterial"
    case regularMaterial = "regularMaterial"
    case thickMaterial = "thickMaterial"
    case thinMaterial = "thinMaterial"
    case ultraThinMaterial = "ultraThinMaterial"
}

public enum AnimationEasing: String, CaseIterable {
    case linear = "linear"
    case easeIn = "easeIn"
    case easeOut = "easeOut"
    case easeInOut = "easeInOut"
    case spring = "spring"
    case custom = "custom"
}

public enum AnimationQuality: String, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case ultra = "ultra"
}

public enum DynamicTypeSize: String, CaseIterable {
    case xSmall = "xSmall"
    case small = "small"
    case medium = "medium"
    case large = "large"
    case xLarge = "xLarge"
    case xxLarge = "xxLarge"
    case xxxLarge = "xxxLarge"
    case accessibility1 = "accessibility1"
    case accessibility2 = "accessibility2"
    case accessibility3 = "accessibility3"
    case accessibility4 = "accessibility4"
    case accessibility5 = "accessibility5"
}

public enum ContrastRatio: String, CaseIterable {
    case aa = "aa"           // 4.5:1
    case aaa = "aaa"         // 7:1
    case custom = "custom"
}

public enum HapticIntensity: String, CaseIterable {
    case light = "light"
    case medium = "medium"
    case heavy = "heavy"
}

// MARK: - Network Enums

public enum RequestPriority: String, CaseIterable {
    case low = "low"
    case normal = "normal"
    case high = "high"
    case critical = "critical"
}

public enum SyncStrategy: String, CaseIterable {
    case automatic = "automatic"
    case manual = "manual"
    case background = "background"
    case realtime = "realtime"
}

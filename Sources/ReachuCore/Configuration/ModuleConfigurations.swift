import Foundation
import SwiftUI

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
        floatingCartDisplayMode: FloatingCartDisplayMode = .full,
        floatingCartSize: FloatingCartSize = .medium,
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
    
    // Debug Configuration
    public let enableLogging: Bool
    public let logLevel: LogLevel
    
    // Custom Headers
    public let customHeaders: [String: String]
    
    public init(
        timeout: TimeInterval = 30.0,
        retryAttempts: Int = 3,
        enableCaching: Bool = true,
        cacheDuration: TimeInterval = 300, // 5 minutes
        enableQueryBatching: Bool = true,
        enableSubscriptions: Bool = false,
        enableLogging: Bool = false,
        logLevel: LogLevel = .info,
        customHeaders: [String: String] = [:]
    ) {
        self.timeout = timeout
        self.retryAttempts = retryAttempts
        self.enableCaching = enableCaching
        self.cacheDuration = cacheDuration
        self.enableQueryBatching = enableQueryBatching
        self.enableSubscriptions = enableSubscriptions
        self.enableLogging = enableLogging
        self.logLevel = logLevel
        self.customHeaders = customHeaders
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
    
    // Product Sliders
    public let defaultSliderLayout: ProductSliderLayout
    public let enableSliderPagination: Bool
    public let maxSliderItems: Int
    
    // Images
    public let imageQuality: ImageQuality
    public let enableImageCaching: Bool
    public let placeholderImageType: PlaceholderImageType
    
    // Animations
    public let enableAnimations: Bool
    public let animationDuration: TimeInterval
    public let enableHapticFeedback: Bool
    
    public init(
        defaultProductCardVariant: ProductCardVariant = .grid,
        enableProductCardAnimations: Bool = true,
        showProductBrands: Bool = true,
        showProductDescriptions: Bool = false,
        defaultSliderLayout: ProductSliderLayout = .cards,
        enableSliderPagination: Bool = true,
        maxSliderItems: Int = 20,
        imageQuality: ImageQuality = .medium,
        enableImageCaching: Bool = true,
        placeholderImageType: PlaceholderImageType = .shimmer,
        enableAnimations: Bool = true,
        animationDuration: TimeInterval = 0.3,
        enableHapticFeedback: Bool = true
    ) {
        self.defaultProductCardVariant = defaultProductCardVariant
        self.enableProductCardAnimations = enableProductCardAnimations
        self.showProductBrands = showProductBrands
        self.showProductDescriptions = showProductDescriptions
        self.defaultSliderLayout = defaultSliderLayout
        self.enableSliderPagination = enableSliderPagination
        self.maxSliderItems = maxSliderItems
        self.imageQuality = imageQuality
        self.enableImageCaching = enableImageCaching
        self.placeholderImageType = placeholderImageType
        self.enableAnimations = enableAnimations
        self.animationDuration = animationDuration
        self.enableHapticFeedback = enableHapticFeedback
    }
    
    public static let `default` = UIConfiguration()
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
        enablePictureInPicture: Bool = true
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
    }
    
    public static let `default` = LiveShowConfiguration()
}

public enum VideoQuality: String, CaseIterable {
    case low = "240p"
    case medium = "480p"
    case high = "720p"
    case hd = "1080p"
    case auto = "auto"
}

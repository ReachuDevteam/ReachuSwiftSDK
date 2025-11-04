import Foundation

/// Configuration for Offer Banner component
public struct OfferBannerConfig: Codable, Equatable {
    public let logoUrl: String
    public let title: String
    public let subtitle: String?
    public let backgroundImageUrl: String
    public let countdownEndDate: String // ISO 8601 timestamp
    public let discountBadgeText: String
    public let ctaText: String
    public let ctaLink: String?
    public let overlayOpacity: Double?
    public let buttonColor: String?
    public let deeplinkUrl: String?
    public let deeplinkAction: String?
    
    public init(
        logoUrl: String,
        title: String,
        subtitle: String? = nil,
        backgroundImageUrl: String,
        countdownEndDate: String,
        discountBadgeText: String,
        ctaText: String,
        ctaLink: String? = nil,
        overlayOpacity: Double? = nil,
        buttonColor: String? = nil,
        deeplinkUrl: String? = nil,
        deeplinkAction: String? = nil
    ) {
        self.logoUrl = logoUrl
        self.title = title
        self.subtitle = subtitle
        self.backgroundImageUrl = backgroundImageUrl
        self.countdownEndDate = countdownEndDate
        self.discountBadgeText = discountBadgeText
        self.ctaText = ctaText
        self.ctaLink = ctaLink
        self.overlayOpacity = overlayOpacity
        self.buttonColor = buttonColor
        self.deeplinkUrl = deeplinkUrl
        self.deeplinkAction = deeplinkAction
    }
}

/// Component Response Models
public struct ActiveComponentResponse: Codable {
    public let componentId: String
    public let type: String
    public let name: String
    public let config: ComponentConfig
    public let status: String
    public let activatedAt: String?
}

/// Component Config (Dynamic based on type)
public enum ComponentConfig: Codable {
    case banner(BannerConfig)
    case offerBanner(OfferBannerConfig)
    case productSpotlight(ProductSpotlightConfig)
    case countdown(CountdownConfig)
    case carouselAuto(CarouselAutoConfig)
    case carouselManual(CarouselManualConfig)
    case offerBadge(OfferBadgeConfig)
    case productCarousel(ProductCarouselConfig)
    case productBanner(ProductBannerConfig)
    case productStore(ProductStoreConfig)
    
    enum CodingKeys: String, CodingKey {
        case imageUrl, title, subtitle, ctaText, ctaLink, deeplinkUrl, deeplinkAction // banner
        case logoUrl, backgroundImageUrl, countdownEndDate, discountBadgeText, overlayOpacity, buttonColor // offer_banner
        case productId, highlightText // product_spotlight
        case endDate, style // countdown
        case channelId, displayCount // carousel_auto
        case productIds // carousel_manual, product_carousel, product_store
        case text, color // offer_badge
        case autoPlay, interval // product_carousel
        case mode, displayType, columns // product_store
        case message, deeplink // banner, product_banner
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Try to decode as OfferBanner first (has most specific fields)
        if container.contains(.logoUrl) && container.contains(.backgroundImageUrl) {
            let config = try OfferBannerConfig(from: decoder)
            self = .offerBanner(config)
        }
        // Try ProductBanner (has productId AND backgroundImageUrl, different from ProductSpotlight)
        else if container.contains(.productId) && container.contains(.backgroundImageUrl) {
            let config = try ProductBannerConfig(from: decoder)
            self = .productBanner(config)
        }
        // Then try Banner (has imageUrl but not logoUrl)
        // Banner can have deeplinkUrl/deeplinkAction like OfferBanner
        else if container.contains(.imageUrl) {
            let config = try BannerConfig(from: decoder)
            self = .banner(config)
        }
        // Try ProductCarousel (has productIds AND autoPlay)
        else if container.contains(.productIds) && container.contains(.autoPlay) {
            let config = try ProductCarouselConfig(from: decoder)
            self = .productCarousel(config)
        }
        // Try ProductStore (has mode AND displayType)
        else if container.contains(.mode) && container.contains(.displayType) {
            let config = try ProductStoreConfig(from: decoder)
            self = .productStore(config)
        }
        // Try CarouselManual (has productIds but no autoPlay)
        else if container.contains(.productIds) {
            let config = try CarouselManualConfig(from: decoder)
            self = .carouselManual(config)
        }
        // Then try ProductSpotlight (has productId but no backgroundImageUrl)
        else if container.contains(.productId) {
            let config = try ProductSpotlightConfig(from: decoder)
            self = .productSpotlight(config)
        }
        // Try Countdown (has endDate)
        else if container.contains(.endDate) {
            let config = try CountdownConfig(from: decoder)
            self = .countdown(config)
        }
        // Try CarouselAuto (has channelId)
        else if container.contains(.channelId) {
            let config = try CarouselAutoConfig(from: decoder)
            self = .carouselAuto(config)
        }
        // Try OfferBadge (has text)
        else if container.contains(.text) {
            let config = try OfferBadgeConfig(from: decoder)
            self = .offerBadge(config)
        }
        // Unknown type
        else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Unknown component config type"
                )
            )
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        switch self {
        case .offerBanner(let config):
            try config.encode(to: encoder)
        case .banner(let config):
            try config.encode(to: encoder)
        case .productSpotlight(let config):
            try config.encode(to: encoder)
        case .countdown(let config):
            try config.encode(to: encoder)
        case .carouselAuto(let config):
            try config.encode(to: encoder)
        case .carouselManual(let config):
            try config.encode(to: encoder)
        case .offerBadge(let config):
            try config.encode(to: encoder)
        case .productCarousel(let config):
            try config.encode(to: encoder)
        case .productBanner(let config):
            try config.encode(to: encoder)
        case .productStore(let config):
            try config.encode(to: encoder)
        }
    }
}

/// Banner Config (Simple)
public struct BannerConfig: Codable {
    public let imageUrl: String
    public let title: String
    public let subtitle: String?
    public let ctaText: String?
    public let ctaLink: String?
    public let deeplinkUrl: String?
    public let deeplinkAction: String?
    
    public init(
        imageUrl: String,
        title: String,
        subtitle: String? = nil,
        ctaText: String? = nil,
        ctaLink: String? = nil,
        deeplinkUrl: String? = nil,
        deeplinkAction: String? = nil
    ) {
        self.imageUrl = imageUrl
        self.title = title
        self.subtitle = subtitle
        self.ctaText = ctaText
        self.ctaLink = ctaLink
        self.deeplinkUrl = deeplinkUrl
        self.deeplinkAction = deeplinkAction
    }
}

/// Product Spotlight Config
public struct ProductSpotlightConfig: Codable {
    public let productId: String
    public let highlightText: String?
}

/// Countdown Config
public struct CountdownConfig: Codable {
    public let endDate: String
    public let style: String?
}

/// Carousel Auto Config
public struct CarouselAutoConfig: Codable {
    public let channelId: String
    public let displayCount: Int?
}

/// Carousel Manual Config
public struct CarouselManualConfig: Codable {
    public let productIds: [String]
}

/// Offer Badge Config
public struct OfferBadgeConfig: Codable {
    public let text: String
    public let color: String?
}

/// Product Carousel Config
public struct ProductCarouselConfig: Codable {
    public let productIds: [String]
    public let autoPlay: Bool
    public let interval: Int  // milliseconds
    
    public init(productIds: [String], autoPlay: Bool = true, interval: Int = 3000) {
        self.productIds = productIds
        self.autoPlay = autoPlay
        self.interval = interval
    }
}

/// Product Banner Config
public struct ProductBannerConfig: Codable {
    public let productId: String
    public let backgroundImageUrl: String
    public let title: String
    public let subtitle: String?
    public let ctaText: String
    public let ctaLink: String?
    public let deeplink: String?
    
    public init(
        productId: String,
        backgroundImageUrl: String,
        title: String,
        subtitle: String? = nil,
        ctaText: String,
        ctaLink: String? = nil,
        deeplink: String? = nil
    ) {
        self.productId = productId
        self.backgroundImageUrl = backgroundImageUrl
        self.title = title
        self.subtitle = subtitle
        self.ctaText = ctaText
        self.ctaLink = ctaLink
        self.deeplink = deeplink
    }
}

/// Product Store Config
public struct ProductStoreConfig: Codable {
    public let mode: String  // "all" or "filtered"
    public let productIds: [String]?
    public let displayType: String  // "grid" or "list"
    public let columns: Int
    
    public init(mode: String, productIds: [String]? = nil, displayType: String = "grid", columns: Int = 2) {
        self.mode = mode
        self.productIds = productIds
        self.displayType = displayType
        self.columns = columns
    }
}

/// WebSocket message for component status changes
public struct ComponentStatusMessage: Codable {
    public let type: String // "component_status_changed"
    public let campaignId: Int
    public let componentId: String
    public let status: String // "active" or "inactive"
    public let component: ComponentData?
    
    public struct ComponentData: Codable {
        public let id: String
        public let type: String
        public let name: String
        public let config: ComponentConfig
        
        public init(id: String, type: String, name: String, config: ComponentConfig) {
            self.id = id
            self.type = type
            self.name = name
            self.config = config
        }
    }
    
    public init(type: String, campaignId: Int, componentId: String, status: String, component: ComponentData? = nil) {
        self.type = type
        self.campaignId = campaignId
        self.componentId = componentId
        self.status = status
        self.component = component
    }
}

/// Active component from API
public struct ActiveComponent: Codable, Identifiable {
    public let id: String?
    public let type: String
    public let config: OfferBannerConfig?
    
    public init(id: String?, type: String, config: OfferBannerConfig? = nil) {
        self.id = id
        self.type = type
        self.config = config
    }
}

/// Global component manager for handling dynamic components (singleton)
@MainActor
public class ComponentManager: ObservableObject {
    @Published public private(set) var activeComponents: [ActiveComponentResponse] = []
    @Published public private(set) var activeBanner: OfferBannerConfig?
    @Published public private(set) var isConnected = false
    
    public let campaignId: Int
    private let baseURL = "https://event-streamer-angelo100.replit.app"
    private var webSocketManager: WebSocketManager?
    
    // MARK: - Singleton
    public static let shared = ComponentManager()
    
    private init() {
        self.campaignId = ReachuConfiguration.shared.liveShowConfiguration.campaignId
        self.webSocketManager = WebSocketManager(campaignId: self.campaignId)
        
        // Auto-connect on initialization
        Task {
            await connect()
        }
    }
    
    
    /// Connect to backend and fetch active components
    public func connect() async {
        print("🔌 [ComponentManager] Connecting to campaign \(campaignId)")
        
        // 1. Fetch initial active components
        await fetchActiveComponents()
        
        // 2. Connect WebSocket for real-time updates
        webSocketManager = WebSocketManager(campaignId: campaignId)
        webSocketManager?.onMessage = { [weak self] message in
            Task { @MainActor in
                self?.handleMessage(message)
            }
        }
        
        await webSocketManager?.connect()
        isConnected = true
        
        print("✅ [ComponentManager] Connected successfully")
    }
    
    /// Disconnect from backend
    public func disconnect() {
        webSocketManager?.disconnect()
        webSocketManager = nil
        isConnected = false
    }
    
    /// Fetch active components from API
    private func fetchActiveComponents() async {
        let urlString = "\(baseURL)/api/campaigns/\(campaignId)/active-components"
        print("🌐 [ComponentManager] Fetching components from: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("❌ [ComponentManager] Invalid API URL")
            return
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 [ComponentManager] HTTP Status: \(httpResponse.statusCode)")
            }
            
            // Log raw response for debugging
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📄 [ComponentManager] Raw API response: \(jsonString)")
            }
            
            let components = try JSONDecoder().decode([ActiveComponentResponse].self, from: data)
            print("✅ [ComponentManager] Loaded \(components.count) active components")
            
            self.activeComponents = components
            
            // Extract offer_banner if present
            if let offerBanner = components.first(where: { $0.type == "offer_banner" }) {
                if case .offerBanner(let config) = offerBanner.config {
                    self.activeBanner = config
                    print("✅ [ComponentManager] Activated offer banner: \(config.title)")
                    print("🖼️ [ComponentManager] Background URL: \(config.backgroundImageUrl)")
                    print("🏷️ [ComponentManager] Logo URL: \(config.logoUrl)")
                    print("⏰ [ComponentManager] Countdown End: \(config.countdownEndDate)")
                }
            } else {
                self.activeBanner = nil
                print("ℹ️ [ComponentManager] No active banner found")
            }
            
        } catch {
            print("❌ [ComponentManager] Failed to fetch active components: \(error)")
        }
    }
    
    /// Handle WebSocket messages
    private func handleMessage(_ message: String) {
        guard let data = message.data(using: .utf8),
              let decoded = try? JSONDecoder().decode(ComponentStatusMessage.self, from: data) else {
            print("❌ [ComponentManager] Failed to decode WebSocket message")
            return
        }
        
        switch decoded.type {
        case "component_status_changed":
            print("📨 [ComponentManager] Component status changed: \(decoded.componentId) -> \(decoded.status)")
            
            if decoded.status == "active", let component = decoded.component {
                // Extract OfferBannerConfig from ComponentConfig enum
                if case .offerBanner(let bannerConfig) = component.config {
                    activeBanner = bannerConfig
                    print("✅ [ComponentManager] Banner activated: \(decoded.componentId)")
                    print("🖼️ [ComponentManager] New Background URL: \(bannerConfig.backgroundImageUrl)")
                    print("🏷️ [ComponentManager] New Logo URL: \(bannerConfig.logoUrl)")
                    print("⏰ [ComponentManager] New Countdown End: \(bannerConfig.countdownEndDate)")
                }
            } else {
                activeBanner = nil
                print("ℹ️ [ComponentManager] Banner deactivated: \(decoded.componentId)")
            }
            
        case "campaign_ended":
            activeBanner = nil
            print("ℹ️ [ComponentManager] Campaign ended - hiding all components")
            
        default:
            print("ℹ️ [ComponentManager] Unknown message type: \(decoded.type)")
        }
    }
}

/// WebSocket manager for component updates
public class WebSocketManager: ObservableObject {
    private let campaignId: Int
    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession
    
    public var onMessage: ((String) -> Void)?
    
    public init(campaignId: Int) {
        self.campaignId = campaignId
        self.urlSession = URLSession(configuration: .default)
    }
    
    public func connect() async {
        guard let url = URL(string: "wss://event-streamer-angelo100.replit.app/ws/\(campaignId)") else {
            print("❌ [WebSocketManager] Invalid WebSocket URL")
            return
        }
        
        webSocketTask = urlSession.webSocketTask(with: url)
        webSocketTask?.resume()
        
        print("🔌 [WebSocketManager] Connected to campaign \(campaignId)")
        
        // Start listening for messages
        await listenForMessages()
    }
    
    public func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        print("🔌 [WebSocketManager] Disconnected")
    }
    
    private func listenForMessages() async {
        while let webSocketTask = webSocketTask {
            do {
                let message = try await webSocketTask.receive()
                switch message {
                case .string(let text):
                    print("📨 [WebSocketManager] Received message: \(text)")
                    onMessage?(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        print("📨 [WebSocketManager] Received data message: \(text)")
                        onMessage?(text)
                    }
                @unknown default:
                    break
                }
            } catch {
                print("❌ [WebSocketManager] WebSocket error: \(error)")
                
                // Try to reconnect after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                    Task {
                        await self.connect()
                    }
                }
                break
            }
        }
    }
}

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
    
    public init(
        logoUrl: String,
        title: String,
        subtitle: String? = nil,
        backgroundImageUrl: String,
        countdownEndDate: String,
        discountBadgeText: String,
        ctaText: String,
        ctaLink: String? = nil,
        overlayOpacity: Double? = nil
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
    }
}

/// WebSocket message for component status changes
public struct ComponentStatusMessage: Codable {
    public let type: String // "component_status_changed"
    public let data: ComponentData
    
    public struct ComponentData: Codable {
        public let componentId: String
        public let status: String // "active" or "inactive"
        public let config: OfferBannerConfig?
        
        public init(componentId: String, status: String, config: OfferBannerConfig? = nil) {
            self.componentId = componentId
            self.status = status
            self.config = config
        }
    }
    
    public init(type: String, data: ComponentData) {
        self.type = type
        self.data = data
    }
}

/// Active component from API
public struct ActiveComponent: Codable, Identifiable {
    public let id: String
    public let type: String
    public let config: OfferBannerConfig?
    
    public init(id: String, type: String, config: OfferBannerConfig? = nil) {
        self.id = id
        self.type = type
        self.config = config
    }
}

/// Component manager for handling offer banners
@MainActor
public class ComponentManager: ObservableObject {
    @Published public private(set) var activeBanner: OfferBannerConfig?
    @Published public private(set) var isConnected = false
    
    private var webSocketManager: WebSocketManager?
    private let campaignId: Int
    
    public init(campaignId: Int) {
        self.campaignId = campaignId
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
        let urlString = "https://event-streamer-angelo100.replit.app/api/campaigns/\(campaignId)/active-components"
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
            
            let components = try JSONDecoder().decode([ActiveComponent].self, from: data)
            print("📦 [ComponentManager] Found \(components.count) active components")
            
            // Find offer banner component
            if let bannerComponent = components.first(where: { $0.type == "offer_banner" }) {
                activeBanner = bannerComponent.config
                print("✅ [ComponentManager] Active banner found: \(bannerComponent.id)")
            } else {
                activeBanner = nil
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
            if decoded.data.status == "active", let config = decoded.data.config {
                activeBanner = config
                print("✅ [ComponentManager] Banner activated: \(decoded.data.componentId)")
            } else {
                activeBanner = nil
                print("ℹ️ [ComponentManager] Banner deactivated: \(decoded.data.componentId)")
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

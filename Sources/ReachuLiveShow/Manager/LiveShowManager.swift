import Foundation
import SwiftUI
import Combine
import ReachuCore
import struct Foundation.Date

/// Global manager for LiveShow functionality - Similar to CartManager
@MainActor
public class LiveShowManager: ObservableObject {
    
    // MARK: - Singleton
    public static let shared = LiveShowManager()
    
    // MARK: - Published Properties
    @Published public private(set) var isLiveShowVisible: Bool = false
    @Published public private(set) var currentStream: LiveStream?
    @Published public private(set) var layout: LiveStreamLayout = .fullScreenOverlay
    @Published public private(set) var isMiniPlayerVisible: Bool = false
    @Published public private(set) var miniPlayerPosition: MiniPlayerPosition = .bottomRight
    @Published public private(set) var isIndicatorVisible: Bool = true
    @Published public private(set) var activeStreams: [LiveStream] = []
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let configuration: LiveShowConfiguration
    
    // MARK: - Initialization
    private init() {
        self.configuration = ReachuConfiguration.shared.liveShowConfiguration
        setupDemoData()
    }
    
    // MARK: - Public Methods
    
    /// Show live stream with specified layout
    public func showLiveStream(_ stream: LiveStream, layout: LiveStreamLayout = .fullScreenOverlay) {
        self.currentStream = stream
        self.layout = layout
        self.isLiveShowVisible = true
        self.isMiniPlayerVisible = false
    }
    
    /// Show live stream by ID
    public func showLiveStream(id: String, layout: LiveStreamLayout = .fullScreenOverlay) {
        guard let stream = activeStreams.first(where: { $0.id == id }) else { return }
        showLiveStream(stream, layout: layout)
    }
    
    /// Hide live stream completely
    public func hideLiveStream() {
        self.isLiveShowVisible = false
        self.isMiniPlayerVisible = false
        self.currentStream = nil
    }
    
    /// Convert to mini player
    public func showMiniPlayer() {
        guard currentStream != nil else { return }
        self.isLiveShowVisible = false
        self.isMiniPlayerVisible = true
    }
    
    /// Expand from mini player
    public func expandFromMiniPlayer() {
        guard currentStream != nil else { return }
        self.isMiniPlayerVisible = false
        self.isLiveShowVisible = true
    }
    
    /// Toggle indicator visibility
    public func toggleIndicator() {
        self.isIndicatorVisible.toggle()
    }
    
    /// Hide indicator
    public func hideIndicator() {
        self.isIndicatorVisible = false
    }
    
    /// Show indicator
    public func showIndicator() {
        self.isIndicatorVisible = true
    }
    
    /// Add product to cart from live stream
    /// Note: This requires `CartManager` to be provided by the host app (no UI dependencies here)
    public func addProductToCart(_ liveProduct: LiveProduct, cartManager: LiveShowCartManaging) {
        let product = liveProduct.asProduct
        Task {
            await cartManager.addProduct(product, quantity: 1)
        }
    }
    
    /// Quick buy product
    public func quickBuyProduct(_ liveProduct: LiveProduct, cartManager: LiveShowCartManaging) {
        addProductToCart(liveProduct, cartManager: cartManager)
        // Could trigger immediate checkout
        cartManager.showCheckout()
    }
    
    // MARK: - Computed Properties
    
    /// Check if there are active live streams
    public var hasActiveLiveStreams: Bool {
        !activeStreams.filter { $0.isLive }.isEmpty
    }
    
    /// Get total viewer count across all streams
    public var totalViewerCount: Int {
        activeStreams.reduce(0) { $0 + $1.viewerCount }
    }
    
    /// Check if any live stream is currently being watched
    public var isWatchingLiveStream: Bool {
        isLiveShowVisible || isMiniPlayerVisible
    }
    
    // MARK: - Private Methods
    
    /// Setup demo data for development
    private func setupDemoData() {
        // Create demo streamers
        let streamer1 = LiveStreamer(
            id: "streamer1",
            name: "Uniqlo",
            username: "@uniqlo",
            avatarUrl: "https://picsum.photos/100/100?random=1",
            isVerified: true,
            followerCount: 125000
        )
        
        let streamer2 = LiveStreamer(
            id: "streamer2", 
            name: "Fashion Central",
            username: "@fashioncentral",
            avatarUrl: "https://picsum.photos/100/100?random=2",
            isVerified: true,
            followerCount: 85000
        )
        
        // Create demo products
        let product1 = LiveProduct(
            id: "live-product-1",
            title: "Ribbed Cotton Top",
            price: Price(amount: 29.99, currency_code: "USD"),
            originalPrice: Price(amount: 39.99, currency_code: "USD"),
            imageUrl: "https://picsum.photos/300/400?random=10",
            discount: "25% OFF",
            specialOffer: "Order now to get special price for viewers!",
            showUntil: Date().addingTimeInterval(600) // 10 minutes
        )
        
        let product2 = LiveProduct(
            id: "live-product-2",
            title: "Denim Jacket",
            price: Price(amount: 59.99, currency_code: "USD"),
            imageUrl: "https://picsum.photos/300/400?random=11",
            specialOffer: "Limited edition - only for live viewers!"
        )
        
        // Create demo chat messages
        let chatMessages = createDemoChatMessages()
        
        // Create demo streams
        let stream1 = LiveStream(
            id: "stream-1",
            title: "Spring Fashion Collection Launch", 
            description: "Discover the latest spring trends with exclusive live offers!",
            streamer: streamer1,
            videoUrl: "https://vimeo.com/1029631656", // Tu video de Vimeo
            thumbnailUrl: "https://i.vimeocdn.com/video/1029631656.jpg",
            viewerCount: 1247,
            isLive: true,
            featuredProducts: [product1, product2],
            chatMessages: chatMessages
        )
        
        let stream2 = LiveStream(
            id: "stream-2",
            title: "Weekend Casual Styling",
            streamer: streamer2,
            videoUrl: "https://vimeo.com/1029631656", // Tu video de Vimeo
            thumbnailUrl: "https://i.vimeocdn.com/video/1029631656.jpg",
            viewerCount: 892,
            isLive: true,
            featuredProducts: [product2],
            chatMessages: chatMessages.dropFirst(5).map { $0 }
        )
        
        self.activeStreams = [stream1, stream2]
    }
    
    /// Create demo chat messages
    private func createDemoChatMessages() -> [LiveChatMessage] {
        let users = [
            LiveChatUser(id: "user1", username: "fashionlover23", isVerified: true),
            LiveChatUser(id: "user2", username: "styleinspo"),
            LiveChatUser(id: "user3", username: "shoppingqueen", isModerator: true),
            LiveChatUser(id: "user4", username: "trendwatcher"),
            LiveChatUser(id: "user5", username: "casual_chic"),
        ]
        
        let messages = [
            "Love this top! 😍",
            "Where can I get this?",
            "Looks amazing on you!",
            "How much is the shipping?",
            "Perfect for spring! 🌸",
            "Can you show it in black?",
            "Just ordered! Can't wait ❤️",
            "This would look great with jeans",
            "So stylish! 💫",
            "Adding to cart now!"
        ]
        
        return messages.enumerated().map { index, message in
            LiveChatMessage(
                user: users[index % users.count],
                message: message,
                timestamp: Date().addingTimeInterval(-TimeInterval(index * 30))
            )
        }
    }
}

// MARK: - Mock Data Provider

extension LiveShowManager {
    
    /// Get featured live stream (for demo)
    public var featuredLiveStream: LiveStream? {
        activeStreams.first { $0.isLive }
    }
    
    /// Simulate receiving new chat message
    public func simulateNewChatMessage() {
        guard var stream = currentStream else { return }
        
        let newMessage = LiveChatMessage(
            user: LiveChatUser(id: "user_new", username: "live_viewer"),
            message: ["Amazing!", "Love it!", "Want this! 😍", "How much?", "Gorgeous! ✨"].randomElement() ?? "Great!",
            timestamp: Date()
        )
        
        stream = LiveStream(
            id: stream.id,
            title: stream.title,
            description: stream.description,
            streamer: stream.streamer,
            videoUrl: stream.videoUrl,
            thumbnailUrl: stream.thumbnailUrl,
            viewerCount: stream.viewerCount + Int.random(in: 1...5),
            isLive: stream.isLive,
            startTime: stream.startTime,
            endTime: stream.endTime,
            featuredProducts: stream.featuredProducts,
            chatMessages: [newMessage] + stream.chatMessages.prefix(20).map { $0 }
        )
        
        self.currentStream = stream
        
        // Update in active streams
        if let index = activeStreams.firstIndex(where: { $0.id == stream.id }) {
            activeStreams[index] = stream
        }
    }
}

import Foundation
import SwiftUI
import Combine
import ReachuCore

/// Manager for live chat functionality with demo data simulation
@MainActor
public class LiveChatManager: ObservableObject {
    
    // MARK: - Singleton
    public static let shared = LiveChatManager()
    
    // MARK: - Published Properties
    @Published public private(set) var messages: [LiveChatMessage] = []
    @Published public private(set) var isConnected: Bool = false
    @Published public private(set) var currentUser: LiveChatUser
    
    // MARK: - Private Properties
    private var messageTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    private init() {
        // Create current user (demo)
        self.currentUser = LiveChatUser(
            id: "current-user",
            username: "you",
            avatarUrl: nil,
            isVerified: false,
            isModerator: false
        )
        
        setupDemoData()
        startMessageSimulation()
    }
    
    // MARK: - Public Methods
    
    /// Send a message to the chat
    public func sendMessage(_ text: String) {
        let message = LiveChatMessage(
            user: currentUser,
            message: text,
            timestamp: Date(),
            isStreamerMessage: false,
            isPinned: false,
            reactions: []
        )
        
        messages.append(message)
        print("💬 [Chat] Message sent: \(text)")
        
        // Simulate typing indicator response after user message
        DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 2...4)) {
            self.simulateResponseMessage()
        }
    }
    
    /// Connect to chat (simulation)
    public func connect() {
        isConnected = true
        print("🔌 [Chat] Connected to live chat")
    }
    
    /// Disconnect from chat
    public func disconnect() {
        isConnected = false
        messageTimer?.invalidate()
        messageTimer = nil
        print("🔌 [Chat] Disconnected from live chat")
    }
    
    /// Clear all messages
    public func clearMessages() {
        messages.removeAll()
        print("🗑️ [Chat] Messages cleared")
    }
    
    /// Add a message programmatically (for testing)
    public func addMessage(_ message: LiveChatMessage) {
        messages.append(message)
    }
    
    // MARK: - Private Methods
    
    private func setupDemoData() {
        let demoMessages = DemoChatData.initialMessages
        messages = demoMessages
        
        print("📝 [Chat] Loaded \(messages.count) demo messages")
    }
    
    private func startMessageSimulation() {
        guard messageTimer == nil else { return }
        
        // Simulate new messages every 8-15 seconds
        messageTimer = Timer.scheduledTimer(withTimeInterval: Double.random(in: 8...15), repeats: true) { _ in
            Task { @MainActor in
                self.simulateIncomingMessage()
                
                // Schedule next message with random interval
                self.messageTimer?.invalidate()
                self.messageTimer = Timer.scheduledTimer(withTimeInterval: Double.random(in: 8...15), repeats: true) { _ in
                    Task { @MainActor in
                        self.simulateIncomingMessage()
                    }
                }
            }
        }
        
        print("🤖 [Chat] Message simulation started")
    }
    
    private func simulateIncomingMessage() {
        let randomMessage = DemoChatData.randomMessages.randomElement()!
        let randomUser = DemoChatData.demoUsers.randomElement()!
        
        let message = LiveChatMessage(
            user: randomUser,
            message: randomMessage,
            timestamp: Date(),
            isStreamerMessage: randomUser.username == "@livehost",
            isPinned: false,
            reactions: []
        )
        
        messages.append(message)
        
        // Keep only last 50 messages for performance
        if messages.count > 50 {
            messages = Array(messages.suffix(50))
        }
        
        print("💬 [Chat] Simulated message from \(randomUser.username): \(randomMessage)")
    }
    
    private func simulateResponseMessage() {
        let responses = DemoChatData.responseMessages
        let randomResponse = responses.randomElement()!
        let responseUser = DemoChatData.demoUsers.randomElement()!
        
        let message = LiveChatMessage(
            user: responseUser,
            message: randomResponse,
            timestamp: Date(),
            isStreamerMessage: responseUser.username == "@livehost",
            isPinned: false,
            reactions: []
        )
        
        messages.append(message)
        print("💬 [Chat] Simulated response: \(randomResponse)")
    }
    
    deinit {
        messageTimer?.invalidate()
    }
}

// MARK: - Demo Chat Data

public struct DemoChatData {
    
    static let demoUsers: [LiveChatUser] = [
        LiveChatUser(
            id: "user1",
            username: "@livehost",
            avatarUrl: "https://picsum.photos/50/50?random=1",
            isVerified: true,
            isModerator: true
        ),
        LiveChatUser(
            id: "user2", 
            username: "fashionlover23",
            avatarUrl: "https://picsum.photos/50/50?random=2",
            isVerified: false,
            isModerator: false
        ),
        LiveChatUser(
            id: "user3",
            username: "styleinspo",
            avatarUrl: "https://picsum.photos/50/50?random=3",
            isVerified: true,
            isModerator: false
        ),
        LiveChatUser(
            id: "user4",
            username: "shoppingqueen",
            avatarUrl: "https://picsum.photos/50/50?random=4",
            isVerified: false,
            isModerator: false
        ),
        LiveChatUser(
            id: "user5",
            username: "trendwatcher",
            avatarUrl: "https://picsum.photos/50/50?random=5",
            isVerified: true,
            isModerator: false
        ),
        LiveChatUser(
            id: "user6",
            username: "casual_chic",
            avatarUrl: "https://picsum.photos/50/50?random=6",
            isVerified: false,
            isModerator: false
        )
    ]
    
    static let initialMessages: [LiveChatMessage] = [
        LiveChatMessage(
            user: demoUsers[0],
            message: "Welcome to our live beauty show! 💄✨",
            timestamp: Date().addingTimeInterval(-300),
            isStreamerMessage: true
        ),
        LiveChatMessage(
            user: demoUsers[1],
            message: "Can you show it in black?",
            timestamp: Date().addingTimeInterval(-250)
        ),
        LiveChatMessage(
            user: demoUsers[2],
            message: "Just ordered! Can't wait ❤️",
            timestamp: Date().addingTimeInterval(-200)
        ),
        LiveChatMessage(
            user: demoUsers[3],
            message: "This would look great with jeans",
            timestamp: Date().addingTimeInterval(-150)
        ),
        LiveChatMessage(
            user: demoUsers[4],
            message: "So stylish! 👏",
            timestamp: Date().addingTimeInterval(-100)
        ),
        LiveChatMessage(
            user: demoUsers[5],
            message: "Adding to cart now!",
            timestamp: Date().addingTimeInterval(-50)
        )
    ]
    
    static let randomMessages: [String] = [
        "Love this! 😍",
        "Where can I buy this?",
        "What size would you recommend?",
        "This looks amazing! 🤩",
        "Perfect for summer!",
        "Already in my cart! 🛒",
        "Can you show the back?",
        "What's the material?",
        "Shipping to Europe?",
        "Is there a discount code?",
        "This color is gorgeous! 💕",
        "Just what I was looking for!",
        "How's the fit?",
        "Ordering right now! 🎉",
        "Can you model it?",
        "What other colors available?",
        "Price looks good! 💰",
        "Adding to wishlist ⭐",
        "Perfect timing! 🕐",
        "Looks premium quality 👌"
    ]
    
    static let responseMessages: [String] = [
        "Thanks for joining! 🙌",
        "Check the product details below! 👇",
        "Limited time offer! ⏰",
        "Great choice! 👍",
        "You'll love it! 💕",
        "Don't miss out! 🚀",
        "Perfect for any occasion! ✨",
        "High quality guaranteed! 🏆",
        "Ships worldwide! 🌍",
        "Use code LIVE20 for 20% off! 🎁"
    ]
}

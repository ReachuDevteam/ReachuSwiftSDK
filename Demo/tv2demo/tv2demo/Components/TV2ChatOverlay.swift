import SwiftUI
import Combine

/// Twitch-style chat overlay for TV2 match viewing
/// Features horizontal layout, auto-hide, and simulated messages
struct TV2ChatOverlay: View {
    @StateObject private var chatManager = ChatManager()
    @State private var isExpanded = false
    @State private var showChat = true
    
    var body: some View {
        VStack {
            Spacer()
            
            if showChat {
                HStack(spacing: 0) {
                    // Chat messages area
                    if isExpanded {
                        chatMessagesView
                            .frame(width: 350)
                            .transition(.move(edge: .leading).combined(with: .opacity))
                    }
                    
                    // Toggle button
                    chatToggleButton
                }
                .padding(.bottom, 80) // Above tab bar
                .padding(.trailing, 16)
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .onAppear {
            chatManager.startSimulation()
        }
        .onDisappear {
            chatManager.stopSimulation()
        }
    }
    
    // MARK: - Chat Messages View
    
    private var chatMessagesView: some View {
        VStack(spacing: 0) {
            // Header
            chatHeader
            
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(chatManager.messages) { message in
                            ChatMessageRow(message: message)
                                .id(message.id)
                        }
                    }
                    .padding(12)
                }
                .background(
                    Color.black.opacity(0.85)
                )
                .onChange(of: chatManager.messages.count) { _ in
                    if let lastMessage = chatManager.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            .frame(height: 300)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.9))
                .shadow(color: Color.black.opacity(0.5), radius: 20, x: -5, y: 0)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    // MARK: - Chat Header
    
    private var chatHeader: some View {
        HStack {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .foregroundColor(TV2Theme.Colors.primary)
                .font(.system(size: 16))
            
            Text("LIVE CHAT")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
            
            Spacer()
            
            HStack(spacing: 4) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 6, height: 6)
                
                Text("\(chatManager.viewerCount)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.95))
    }
    
    // MARK: - Toggle Button
    
    private var chatToggleButton: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isExpanded.toggle()
            }
        } label: {
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [TV2Theme.Colors.primary, TV2Theme.Colors.secondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: TV2Theme.Colors.primary.opacity(0.5), radius: 10, x: 0, y: 4)
                
                // Icon
                VStack(spacing: 6) {
                    Image(systemName: isExpanded ? "chevron.right" : "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    if !isExpanded {
                        Text("CHAT")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    // Unread indicator
                    if !isExpanded && chatManager.hasUnreadMessages {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 6, height: 6)
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 14)
            }
        }
        .frame(width: 60, height: isExpanded ? 60 : 80)
    }
}

// MARK: - Chat Message Row

struct ChatMessageRow: View {
    let message: ChatMessage
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // User badge/icon
            if message.isModerator {
                Image(systemName: "shield.fill")
                    .font(.system(size: 10))
                    .foregroundColor(Color.green)
            } else if message.isSubscriber {
                Image(systemName: "star.fill")
                    .font(.system(size: 10))
                    .foregroundColor(TV2Theme.Colors.secondary)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                // Username
                Text(message.username)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(message.usernameColor)
                
                // Message
                Text(message.text)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.95))
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Chat Message Model

struct ChatMessage: Identifiable {
    let id = UUID()
    let username: String
    let text: String
    let usernameColor: Color
    let isModerator: Bool
    let isSubscriber: Bool
    let timestamp: Date
}

// MARK: - Chat Manager

@MainActor
class ChatManager: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var viewerCount: Int = 0
    @Published var hasUnreadMessages: Bool = false
    
    private var timer: Timer?
    private var viewerTimer: Timer?
    private let maxMessages = 50
    
    // Simulated users with colors
    private let simulatedUsers: [(String, Color, Bool, Bool)] = [
        ("SportsFan23", .cyan, false, false),
        ("GoalKeeper", .green, false, true),
        ("MatchMaster", .orange, false, true),
        ("TeamCaptain", .red, true, true),
        ("ElClásico", .purple, false, false),
        ("FutbolLoco", .yellow, false, true),
        ("DefenderPro", .blue, false, false),
        ("StrikerKing", .pink, false, true),
        ("MidFielder", .mint, false, false),
        ("CoachView", .indigo, true, false),
        ("TacticsGuru", .teal, false, true),
        ("FanZone", .orange, false, false),
        ("LiveScore", .green, false, false),
        ("TeamSpirit", .purple, false, true),
        ("UltrasGroup", .red, false, true),
    ]
    
    // Simulated messages (football-themed, Spanish/English mix)
    private let simulatedMessages: [String] = [
        "¡Qué golazo! 🔥",
        "What a save!",
        "INCREDIBLE PLAY!!!",
        "La defensa está dormida...",
        "This ref is terrible",
        "¡VAMOS! 💪",
        "Beautiful pass",
        "That should've been a penalty",
        "El portero está en otro nivel",
        "SHOOT!",
        "¿Por qué no tiró?",
        "Great positioning",
        "Este partido está loco",
        "Need a goal here",
        "La táctica está funcionando",
        "Come on, wake up!",
        "¡Casi! So close!",
        "Best match of the season",
        "El árbitro no vio nada",
        "WHAT A PASS!",
        "Increíble control de balón",
        "That was offside!",
        "¡A por ellos!",
        "Perfect timing",
        "Esta va a ser épica",
        "LET'S GO!!!",
        "¡Qué jugada!",
        "Amazing teamwork",
        "El público está encendido 🔥",
        "THIS IS IT!",
    ]
    
    func startSimulation() {
        // Initial viewer count
        viewerCount = Int.random(in: 1200...2500)
        
        // Add initial messages
        addSimulatedMessage()
        addSimulatedMessage()
        addSimulatedMessage()
        
        // Start message timer (random interval)
        timer = Timer.scheduledTimer(withTimeInterval: Double.random(in: 2.0...5.0), repeats: true) { [weak self] _ in
            self?.addSimulatedMessage()
            // Randomize next interval
            self?.timer?.invalidate()
            self?.timer = Timer.scheduledTimer(withTimeInterval: Double.random(in: 2.0...5.0), repeats: true) { [weak self] _ in
                self?.addSimulatedMessage()
            }
        }
        
        // Start viewer count fluctuation
        viewerTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let change = Int.random(in: -50...100)
            self.viewerCount = max(1000, self.viewerCount + change)
        }
    }
    
    func stopSimulation() {
        timer?.invalidate()
        viewerTimer?.invalidate()
        timer = nil
        viewerTimer = nil
    }
    
    private func addSimulatedMessage() {
        let user = simulatedUsers.randomElement()!
        let messageText = simulatedMessages.randomElement()!
        
        let message = ChatMessage(
            username: user.0,
            text: messageText,
            usernameColor: user.1,
            isModerator: user.2,
            isSubscriber: user.3,
            timestamp: Date()
        )
        
        messages.append(message)
        hasUnreadMessages = true
        
        // Keep only last N messages
        if messages.count > maxMessages {
            messages.removeFirst()
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black
            .ignoresSafeArea()
        
        TV2ChatOverlay()
    }
}


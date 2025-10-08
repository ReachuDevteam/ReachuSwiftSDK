import SwiftUI
import Combine

/// Twitch/Kick-style sliding chat panel that splits screen with video
/// Video shrinks to 60% top, chat takes 40% bottom
/// Works in both portrait and landscape
struct TV2ChatOverlay: View {
    @StateObject private var chatManager = ChatManager()
    @State private var isExpanded = false
    @State private var dragOffset: CGFloat = 0
    
    // Binding to communicate with parent
    var onExpandedChange: ((Bool) -> Void)?
    
    private let expandedHeight: CGFloat = 0.4 // 40% of screen
    private let collapsedHeight: CGFloat = 60
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Spacer()
                
                // Chat Panel
                VStack(spacing: 0) {
                    // Drag Handle
                    dragHandle
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    let translation = value.translation.height
                                    if isExpanded {
                                        // Swiping down when expanded
                                        dragOffset = max(0, translation)
                                    } else {
                                        // Swiping up when collapsed
                                        dragOffset = min(0, translation)
                                    }
                                }
                                .onEnded { value in
                                    let threshold: CGFloat = 50
                                    let velocity = value.predictedEndTranslation.height
                                    
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                        if isExpanded {
                                            if dragOffset > threshold || velocity > 500 {
                                                isExpanded = false
                                                onExpandedChange?(false)
                                            }
                                        } else {
                                            if dragOffset < -threshold || velocity < -500 {
                                                isExpanded = true
                                                onExpandedChange?(true)
                                            }
                                        }
                                        dragOffset = 0
                                    }
                                }
                        )
                    
                    // Chat Content
                    if isExpanded {
                        chatContent
                            .frame(height: geometry.size.height * expandedHeight - collapsedHeight)
                    }
                }
                .frame(height: isExpanded ? geometry.size.height * expandedHeight : collapsedHeight)
                .offset(y: dragOffset)
                .background(
                    RoundedRectangle(cornerRadius: isExpanded ? 0 : 20)
                        .fill(Color.black.opacity(0.95))
                        .shadow(color: Color.black.opacity(0.5), radius: 20, x: 0, y: -5)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: isExpanded ? 0 : 20)
                        .stroke(
                            LinearGradient(
                                colors: [TV2Theme.Colors.primary.opacity(0.3), TV2Theme.Colors.secondary.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .onAppear {
            chatManager.startSimulation()
        }
        .onDisappear {
            chatManager.stopSimulation()
        }
    }
    
    // MARK: - Drag Handle
    
    private var dragHandle: some View {
        VStack(spacing: 8) {
            // Drag indicator
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.white.opacity(0.3))
                .frame(width: 40, height: 5)
                .padding(.top, 8)
            
            // Header
            HStack(spacing: 12) {
                // Live chat icon
                HStack(spacing: 6) {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(TV2Theme.Colors.primary)
                    
                    Text("LIVE CHAT")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // Viewer count
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                    
                    Text("\(chatManager.viewerCount)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                // Expand/Collapse indicator
                Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.leading, 4)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
        .frame(height: collapsedHeight)
        .contentShape(Rectangle())
    }
    
    // MARK: - Chat Content
    
    private var chatContent: some View {
        VStack(spacing: 0) {
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        ForEach(chatManager.messages) { message in
                            ChatMessageRow(message: message)
                                .id(message.id)
                        }
                    }
                    .padding(16)
                }
                .background(Color.black.opacity(0.98))
                .onChange(of: chatManager.messages.count) { _ in
                    if let lastMessage = chatManager.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Chat input (placeholder)
            chatInputBar
        }
    }
    
    // MARK: - Chat Input Bar
    
    private var chatInputBar: some View {
        HStack(spacing: 12) {
            // Avatar placeholder
            Circle()
                .fill(
                    LinearGradient(
                        colors: [TV2Theme.Colors.primary, TV2Theme.Colors.secondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 32, height: 32)
                .overlay(
                    Text("A")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                )
            
            // Input field
            Text("Send a message...")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.4))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.1))
                )
            
            // Send button
            Button(action: {}) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 16))
                    .foregroundColor(TV2Theme.Colors.primary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.95))
    }
}

// MARK: - Chat Message Row

struct ChatMessageRow: View {
    let message: ChatMessage
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // Avatar
            Circle()
                .fill(message.usernameColor.opacity(0.3))
                .frame(width: 32, height: 32)
                .overlay(
                    Text(String(message.username.prefix(1)))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(message.usernameColor)
                )
            
            VStack(alignment: .leading, spacing: 3) {
                // Username and badges
                HStack(spacing: 6) {
                    if message.isModerator {
                        Image(systemName: "shield.fill")
                            .font(.system(size: 11))
                            .foregroundColor(Color.green)
                    }
                    
                    if message.isSubscriber {
                        Image(systemName: "star.fill")
                            .font(.system(size: 11))
                            .foregroundColor(TV2Theme.Colors.secondary)
                    }
                    
                    Text(message.username)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(message.usernameColor)
                    
                    Text(timeAgo(from: message.timestamp))
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.4))
                }
                
                // Message
                Text(message.text)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.95))
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer(minLength: 0)
        }
    }
    
    private func timeAgo(from date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        if seconds < 60 { return "\(seconds)s" }
        let minutes = seconds / 60
        if minutes < 60 { return "\(minutes)m" }
        let hours = minutes / 60
        return "\(hours)h"
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
    
    private var timer: Timer?
    private var viewerTimer: Timer?
    private let maxMessages = 100
    
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
        viewerCount = Int.random(in: 8000...15000)
        
        // Add initial messages
        for _ in 0..<5 {
            addSimulatedMessage()
        }
        
        // Start message timer (random interval)
        scheduleNextMessage()
        
        // Start viewer count fluctuation
        viewerTimer = Timer.scheduledTimer(withTimeInterval: 8.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let change = Int.random(in: -100...200)
            self.viewerCount = max(5000, self.viewerCount + change)
        }
    }
    
    func stopSimulation() {
        timer?.invalidate()
        viewerTimer?.invalidate()
        timer = nil
        viewerTimer = nil
    }
    
    private func scheduleNextMessage() {
        let interval = Double.random(in: 1.5...4.0)
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            self?.addSimulatedMessage()
            self?.scheduleNextMessage()
        }
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
        
        // Keep only last N messages
        if messages.count > maxMessages {
            messages.removeFirst()
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        // Video placeholder
        Rectangle()
            .fill(Color.blue)
            .ignoresSafeArea()
        
        TV2ChatOverlay()
    }
}

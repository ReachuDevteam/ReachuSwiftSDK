import SwiftUI
import Combine

/// Panel de chat deslizante estilo Twitch/Kick que divide la pantalla con el video
/// Video se reduce al 60% arriba, chat ocupa 40% abajo
/// Funciona tanto en vertical como horizontal
struct TV2ChatOverlay: View {
    @StateObject private var chatManager = ChatManager()
    @State private var isExpanded = false
    @State private var dragOffset: CGFloat = 0
    
    // Binding para comunicarse con el padre
    var onExpandedChange: ((Bool) -> Void)?
    
    private let expandedHeight: CGFloat = 0.4 // 40% de la pantalla
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
                    RoundedRectangle(cornerRadius: isExpanded ? 20 : 20)
                        .fill(Color.black.opacity(0.4))
                        .background(
                            RoundedRectangle(cornerRadius: isExpanded ? 20 : 20)
                                .fill(.ultraThinMaterial)
                        )
                        .shadow(color: Color.black.opacity(0.5), radius: 20, x: 0, y: -5)
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
        VStack(spacing: 4) {
            // Drag indicator
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.white.opacity(0.3))
                .frame(width: 32, height: 4)
                .padding(.top, 6)
            
            // Header
            HStack(spacing: 8) {
                // Sponsor badge (top left)
                HStack(spacing: 4) {
                    Text("Sponset av")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    
                    AsyncImage(url: URL(string: "http://event-streamer-angelo100.replit.app/objects/uploads/16475fd2-da1f-4e9f-8eb4-362067b27858")) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: 60, maxHeight: 20)
                        case .empty:
                            ProgressView()
                                .scaleEffect(0.4)
                                .frame(width: 60, height: 20)
                        case .failure:
                            EmptyView()
                        @unknown default:
                            EmptyView()
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.black.opacity(0.3))
                )
                
                Spacer()
                
                Text("LIVE CHAT")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                
                // Expand/Collapse indicator
                Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.leading, 2)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 6)
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
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(chatManager.messages) { message in
                            ChatMessageRow(message: message)
                                .id(message.id)
                        }
                    }
                    .padding(8)
                }
                .background(Color(hex: "120019"))
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
        HStack(spacing: 8) {
            // Avatar placeholder
            Circle()
                .fill(
                    LinearGradient(
                        colors: [TV2Theme.Colors.primary, TV2Theme.Colors.secondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 24, height: 24)
                .overlay(
                    Text("A")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white)
                )
            
            // Input field
            Text("Send a message...")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.4))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
                .padding(.horizontal, 10)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.1))
                )
            
            // Send button
            Button(action: {}) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 13))
                    .foregroundColor(TV2Theme.Colors.primary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(hex: "120019"))
    }
}

// MARK: - Chat Message Row

struct ChatMessageRow: View {
    let message: ChatMessage
    
    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            // Avatar
            Circle()
                .fill(message.usernameColor.opacity(0.3))
                .frame(width: 22, height: 22)
                .overlay(
                    Text(String(message.username.prefix(1)))
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(message.usernameColor)
                )
            
            VStack(alignment: .leading, spacing: 1) {
                // Username and badges
                HStack(spacing: 3) {
                    if message.isModerator {
                        Image(systemName: "shield.fill")
                            .font(.system(size: 8))
                            .foregroundColor(Color.green)
                    }
                    
                    if message.isSubscriber {
                        Image(systemName: "star.fill")
                            .font(.system(size: 8))
                            .foregroundColor(TV2Theme.Colors.secondary)
                    }
                    
                    Text(message.username)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(message.usernameColor)
                    
                    Text(timeAgo(from: message.timestamp))
                        .font(.system(size: 8))
                        .foregroundColor(.white.opacity(0.4))
                }
                
                // Message
                Text(message.text)
                    .font(.system(size: 11))
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
    
    // Mensajes simulados (temática de fútbol, noruego)
    private let simulatedMessages: [String] = [
        "Hvilket mål! 🔥",
        "For en redning!",
        "UTROLIG SPILL!!!",
        "Forsvaret sover...",
        "Dommeren er forferdelig",
        "KOM IGJEN! 💪",
        "Nydelig pasning",
        "Det burde vært straffe",
        "Keeperen er på et annet nivå",
        "SKYT!",
        "Hvorfor skjøt han ikke?",
        "Perfekt posisjonering",
        "Denne kampen er gal",
        "Vi trenger mål nå",
        "Taktikken fungerer",
        "Kom igjen, våkn opp!",
        "Nesten! Så nært!",
        "Beste kampen denne sesongen",
        "Dommeren så ingenting",
        "FOR EN PASNING!",
        "Utrolig ballkontroll",
        "Det var offside!",
        "Kom igjen da!",
        "Perfekt timing",
        "Dette blir episk",
        "KJØR PÅ!!!",
        "Hvilken spilling!",
        "Fantastisk lagspill",
        "Publikum er tent 🔥",
        "NÅ SKJER DET!",
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

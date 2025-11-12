import SwiftUI
import ReachuUI
import ReachuCore

/// Vista que se muestra cuando el casting está activo en Viaplay
/// Permite controlar el video y ver los overlays mientras se castea
struct ViaplayCastingActiveView: View {
    let match: Match
    @StateObject private var castingManager = CastingManager.shared
    @StateObject private var webSocketManager = WebSocketManager()
    @StateObject private var chatManager = ChatManager()
    @EnvironmentObject private var cartManager: CartManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var isPlaying = true
    @State private var isChatExpanded = false
    @State private var chatMessage = ""
    @State private var floatingLikes: [FloatingLike] = []
    
    struct FloatingLike: Identifiable {
        let id = UUID()
        let xOffset: CGFloat
    }
    
    private var sdkClient: SdkClient {
        let config = ReachuConfiguration.shared
        let baseURL = URL(string: config.environment.graphQLURL)!
        return SdkClient(baseUrl: baseURL, apiKey: config.apiKey)
    }
    
    var body: some View {
        ZStack {
            // Background
            Image(match.backgroundImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
                .blur(radius: 20)
            
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            // Contenido principal
            VStack(spacing: 20) {
                // Header
                castingHeader
                
                Spacer()
                
                // Match info
                matchInfo
                
                Spacer()
                
                // Controles
                playbackControls
                
                Spacer()
                    .frame(minHeight: 40)
                
                // Eventos interactivos
                if let poll = webSocketManager.currentPoll {
                    ViaplayCastingPollCardView(
                        poll: poll,
                        onVote: { option in
                            print("📊 [Poll] Votado: \(option)")
                        },
                        onDismiss: {
                            webSocketManager.currentPoll = nil
                        }
                    )
                } else if let productEvent = webSocketManager.currentProduct {
                    ViaplayCastingProductCardView(
                        productEvent: productEvent,
                        sdk: sdkClient,
                        currency: cartManager.currency,
                        country: cartManager.country,
                        onAddToCart: { productDto in
                            if let apiProduct = productDto {
                                print("🛍️ Producto de API: \(apiProduct.title)")
                                // El componente ya agrega al cart internamente
                            }
                        },
                        onDismiss: {
                            webSocketManager.currentProduct = nil
                        }
                    )
                    .environmentObject(cartManager)
                } else if let contest = webSocketManager.currentContest {
                    ViaplayCastingContestCardView(
                        contest: contest,
                        onJoin: {
                            print("🎁 [Contest] Usuario se unió")
                        },
                        onDismiss: {
                            webSocketManager.currentContest = nil
                        }
                    )
                }
                
                // Chat
                simpleChatPanel
            }
            
            // Floating likes overlay
            ForEach(floatingLikes) { like in
                FloatingLikeView()
                    .offset(x: like.xOffset, y: 0)
                    .offset(y: -100)
                    .animation(.easeOut(duration: 2.5), value: floatingLikes.count)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            floatingLikes.removeAll { $0.id == like.id }
                        }
                    }
            }
            
            // Floating cart indicator
            RFloatingCartIndicator(
                customPadding: EdgeInsets(
                    top: 0,
                    leading: 0,
                    bottom: 100,
                    trailing: 16
                )
            )
            .zIndex(1000)
        }
        .navigationBarHidden(true)
        .onAppear {
            webSocketManager.connect()
            chatManager.startSimulation()
        }
        .onDisappear {
            webSocketManager.disconnect()
            chatManager.stopSimulation()
        }
    }
    
    // MARK: - Components
    
    private var castingHeader: some View {
        HStack(alignment: .top) {
            // Back button
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
            }
            
            // Casting info centrada
            VStack(spacing: 4) {
                Text(match.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(match.subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.top, 8)
            
            // Stop Casting button
            Button(action: {
                castingManager.stopCasting()
                dismiss()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "tv.slash")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Stop")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.red.opacity(0.8))
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 50)
    }
    
    private var matchInfo: some View {
        VStack(spacing: 20) {
            // Mensaje de "Casting to..."
            Text("Casting to \(castingManager.selectedDevice?.name ?? "Living TV")")
                .font(.system(size: 17))
                .foregroundColor(.white)
            
            // Progreso/tiempo
            VStack(spacing: 16) {
                // Barra de progreso
                ZStack(alignment: .leading) {
                    // Background
                    Capsule()
                        .fill(Color.white.opacity(0.3))
                        .frame(height: 4)
                    
                    // Progress (simulado al 50%)
                    Capsule()
                        .fill(ViaplayTheme.Colors.pink)
                        .frame(width: (UIScreen.main.bounds.width * 0.6) * 0.5, height: 4)
                }
                .frame(width: UIScreen.main.bounds.width * 0.6, height: 4)
                
                // Tiempo
                HStack {
                    Text("3:24:39")
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("LIVE")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(ViaplayTheme.Colors.pink)
                }
                .frame(width: UIScreen.main.bounds.width * 0.6)
            }
        }
    }
    
    private var playbackControls: some View {
        HStack(spacing: 40) {
            // Rewind
            Button(action: {}) {
                Image(systemName: "gobackward.30")
                    .font(.system(size: 32))
                    .foregroundColor(.white)
            }
            
            // Play/Pause
            Button(action: { isPlaying.toggle() }) {
                ZStack {
                    Circle()
                        .fill(ViaplayTheme.Colors.pink)
                        .frame(width: 70, height: 70)
                    
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                }
            }
            
            // Forward
            Button(action: {}) {
                Image(systemName: "goforward.30")
                    .font(.system(size: 32))
                    .foregroundColor(.white)
            }
        }
    }
    
    // MARK: - Chat Panel
    
    private var simpleChatPanel: some View {
        VStack(spacing: 0) {
            // Drag indicator + Header
            VStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 32, height: 4)
                    .padding(.top, 6)
                
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        isChatExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 8) {
                        // Sponsor badge
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Sponset av")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                            
                            Image("logo1")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: 70, maxHeight: 24)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.black.opacity(0.3))
                        )
                        
                        Spacer(minLength: 0)
                        
                        // Live Chat indicator
                        HStack(spacing: 4) {
                            Text("LIVE CHAT")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                            
                            Image(systemName: isChatExpanded ? "chevron.down" : "chevron.up")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 14)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.bottom, 8)
            }
            
            // Mensajes (cuando está expandido)
            if isChatExpanded {
                Divider()
                    .background(Color.white.opacity(0.2))
                
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(chatManager.messages.suffix(20)) { message in
                                HStack(alignment: .top, spacing: 8) {
                                    Circle()
                                        .fill(message.usernameColor.opacity(0.3))
                                        .frame(width: 28, height: 28)
                                        .overlay(
                                            Text(String(message.username.prefix(1)))
                                                .font(.system(size: 13, weight: .semibold))
                                                .foregroundColor(message.usernameColor)
                                        )
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack(spacing: 4) {
                                            Text(message.username)
                                                .font(.system(size: 13, weight: .bold))
                                                .foregroundColor(message.usernameColor)
                                            
                                            Text(timeAgo(from: message.timestamp))
                                                .font(.system(size: 10))
                                                .foregroundColor(.white.opacity(0.4))
                                        }
                                        
                                        Text(message.text)
                                            .font(.system(size: 14))
                                            .foregroundColor(.white.opacity(0.95))
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    
                                    Spacer(minLength: 0)
                                }
                                .padding(.vertical, 4)
                                .frame(width: 350)
                                .id(message.id)
                            }
                        }
                        .padding(14)
                    }
                    .frame(width: 380, height: 150)
                    .onChange(of: chatManager.messages.count) { _ in
                        if let last = chatManager.messages.last {
                            withAnimation {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                Divider()
                    .background(Color.white.opacity(0.2))
                
                // Input bar
                HStack(spacing: 10) {
                    TextField("Send a message...", text: $chatMessage)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white.opacity(0.15))
                        )
                    
                    Button {
                        sendChatMessage()
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(chatMessage.isEmpty ? .white.opacity(0.3) : ViaplayTheme.Colors.pink)
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(chatMessage.isEmpty ? Color.white.opacity(0.1) : ViaplayTheme.Colors.pink.opacity(0.2))
                            )
                    }
                    .disabled(chatMessage.isEmpty)
                    
                    Button(action: {
                        sendFloatingLike()
                    }) {
                        Image(systemName: "hand.thumbsup.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(ViaplayTheme.Colors.pink)
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(ViaplayTheme.Colors.pink.opacity(0.2))
                            )
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(ViaplayTheme.Colors.black)
            }
        }
        .frame(width: isChatExpanded ? 400 : UIScreen.main.bounds.width, height: isChatExpanded ? 280 : 60)
        .background(
            RoundedRectangle(cornerRadius: isChatExpanded ? 20 : 0)
                .fill(Color.black.opacity(0.4))
                .background(
                    RoundedRectangle(cornerRadius: isChatExpanded ? 20 : 0)
                        .fill(.ultraThinMaterial)
                )
        )
        .animation(.spring(response: 0.3), value: isChatExpanded)
    }
    
    private func sendChatMessage() {
        guard !chatMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let message = ChatMessage(
            username: "Angelo",
            text: chatMessage,
            usernameColor: ViaplayTheme.Colors.pink,
            likes: 0,
            timestamp: Date()
        )
        
        chatManager.addMessage(message)
        chatMessage = ""
    }
    
    private func timeAgo(from date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        if seconds < 60 { return "\(seconds)s" }
        let minutes = seconds / 60
        if minutes < 60 { return "\(minutes)m" }
        let hours = minutes / 60
        return "\(hours)h"
    }
    
    private func sendFloatingLike() {
        let randomOffset = CGFloat.random(in: -80...80)
        let like = FloatingLike(xOffset: randomOffset)
        
        withAnimation {
            floatingLikes.append(like)
        }
    }
}

#Preview {
    ViaplayCastingActiveView(match: Match.barcelonaPSG)
        .environmentObject(CartManager())
}


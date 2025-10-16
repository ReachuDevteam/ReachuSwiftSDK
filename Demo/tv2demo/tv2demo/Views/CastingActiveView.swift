import SwiftUI
import ReachuUI
import ReachuCore

/// Vista que se muestra cuando el casting está activo
/// Permite controlar el video y ver los overlays mientras se castea
struct CastingActiveView: View {
    let match: Match
    @StateObject private var castingManager = CastingManager.shared
    @StateObject private var webSocketManager = WebSocketManager()
    @StateObject private var chatManager = ChatManager()
    @EnvironmentObject private var cartManager: CartManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var isPlaying = true
    
    private var sdkClient: SdkClient {
        SdkClient(
            baseUrl: URL(string: "https://api.reachu.io/graphql")!,
            apiKey: ReachuConfiguration.shared.apiKey
        )
    }
    
    var body: some View {
        ZStack {
            // Background
            Image("football_field_bg")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
                .blur(radius: 20)
            
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            // Contenido principal en VStack simple
            VStack(spacing: 20) {
                // Header
                castingHeader
                
                Spacer()
                
                // Match info
                matchInfo
                
                Spacer()
                
                // Eventos interactivos (cards INLINE con tamaños FIJOS)
                if let poll = webSocketManager.currentPoll {
                    simplePollCard(poll)
                } else if let productEvent = webSocketManager.currentProduct {
                    simpleProductCard(productEvent)
                } else if let contest = webSocketManager.currentContest {
                    simpleContestCard(contest)
                }
                
                Spacer()
                
                // Controles
                playbackControls
                
                // Chat
                simpleChatPanel
                    .padding(.bottom, 20)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            webSocketManager.connect()
        }
        .onDisappear {
            webSocketManager.disconnect()
        }
    }
    
    // MARK: - Simple Inline Cards (tamaños fijos, sin GeometryReader)
    
    private func simplePollCard(_ poll: PollEventData) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(poll.question)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                Spacer(minLength: 0)
                Button("✕") {
                    webSocketManager.currentPoll = nil
                }
                .foregroundColor(.white.opacity(0.6))
            }
            
            ForEach(poll.options, id: \.text) { option in
                Button {
                    print("📊 Voted: \(option.text)")
                } label: {
                    HStack(spacing: 10) {
                        if let avatarUrl = option.avatarUrl, !avatarUrl.isEmpty {
                            AsyncImage(url: URL(string: avatarUrl)) { image in
                                image.resizable().aspectRatio(contentMode: .fit)
                            } placeholder: {
                                Circle().fill(Color.white)
                            }
                            .frame(width: 32, height: 32)
                            .background(Color.white)
                            .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Text(option.text.prefix(1))
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(TV2Theme.Colors.primary)
                                )
                        }
                        
                        Text(option.text)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Spacer(minLength: 0)
                    }
                    .frame(width: 360)
                    .padding(12)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(10)
                }
            }
        }
        .frame(width: 400)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.7))
                .background(.ultraThinMaterial)
        )
    }
    
    private func simpleProductCard(_ productEvent: ProductEventData) -> some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: productEvent.imageUrl)) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.white.opacity(0.1)
            }
            .frame(width: 70, height: 70)
            .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(productEvent.name)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                Text("\(productEvent.price) \(productEvent.currency)")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(TV2Theme.Colors.primary)
            }
            
            Spacer(minLength: 0)
            
            Button("✕") {
                webSocketManager.currentProduct = nil
            }
            .foregroundColor(.white.opacity(0.6))
        }
        .frame(width: 380)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.7))
                .background(.ultraThinMaterial)
        )
    }
    
    private func simpleContestCard(_ contest: ContestEventData) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 28))
                .foregroundColor(TV2Theme.Colors.primary)
                .frame(width: 50, height: 50)
                .background(Circle().fill(TV2Theme.Colors.primary.opacity(0.2)))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(contest.name)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text("Premio: \(contest.prize)")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer(minLength: 0)
            
            Button("✕") {
                webSocketManager.currentContest = nil
            }
            .foregroundColor(.white.opacity(0.6))
        }
        .frame(width: 380)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.7))
                .background(.ultraThinMaterial)
        )
    }
    
    private var simpleChatPanel: some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: "message.fill")
                    .font(.system(size: 13))
                Text("LIVE CHAT")
                    .font(.system(size: 13, weight: .bold))
                Text("(\(chatManager.messages.count))")
                    .font(.system(size: 11))
                    .opacity(0.7)
                Spacer(minLength: 0)
            }
            .foregroundColor(.white)
            .frame(width: 360)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .frame(width: 400)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.7))
                .background(.ultraThinMaterial)
        )
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
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        Capsule()
                            .fill(Color.white.opacity(0.3))
                            .frame(height: 4)
                        
                        // Progress (simulado al 50%)
                        Capsule()
                            .fill(Color.white)
                            .frame(width: geometry.size.width * 0.5, height: 4)
                    }
                }
                .frame(height: 4)
                .padding(.horizontal, 40)
                
                // Tiempo
                HStack {
                    Text("3:24:39")
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("LIVE")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 40)
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
                        .fill(Color.white)
                        .frame(width: 70, height: 70)
                    
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.black)
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
}

#Preview {
    CastingActiveView(match: Match.barcelonaPSG)
        .environmentObject(CartManager())
}


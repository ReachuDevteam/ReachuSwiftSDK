import SwiftUI
import ReachuUI
import ReachuCore

/// Vista que se muestra cuando el casting está activo
/// Permite controlar el video y ver los overlays mientras se castea
struct CastingActiveView: View {
    let match: Match
    @StateObject private var castingManager = CastingManager.shared
    @StateObject private var webSocketManager = WebSocketManager()
    @EnvironmentObject private var cartManager: CartManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var isPlaying = true
    
    var body: some View {
        ZStack {
            // Background - imagen del campo de fútbol (como en TV2)
            Image("football_field_bg")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
                .blur(radius: 20) // Blur para que no distraiga del contenido
            
            // Overlay oscuro para mejor contraste
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header con info de casting
                castingHeader
                
                Spacer()
                
                // Info del partido
                matchInfo
                
                Spacer()
                
                // Controles de reproducción
                playbackControls
                    .padding(.bottom, 40)
            }
            
            // Overlays de WebSocket (polls, productos, contests)
            // Estos se muestran también en la vista de casting
            if let poll = webSocketManager.currentPoll {
                TV2PollOverlay(
                    poll: poll,
                    isChatExpanded: false,
                    onVote: { option in
                        print("Voted: \(option)")
                    },
                    onDismiss: {
                        webSocketManager.currentPoll = nil
                    }
                )
            }
            
            if let product = webSocketManager.currentProduct {
                TV2ProductOverlay(
                    productEvent: product,
                    isChatExpanded: false,
                    sdk: SdkClient(
                        baseUrl: URL(string: "https://api.reachu.io/graphql")!,
                        apiKey: ReachuConfiguration.shared.apiKey
                    ),
                    currency: cartManager.currency,
                    country: cartManager.country,
                    onAddToCart: { productDto in
                        // Agregar al carrito
                        print("Added to cart from casting view")
                    },
                    onDismiss: {
                        webSocketManager.currentProduct = nil
                    }
                )
            }
            
            if let contest = webSocketManager.currentContest {
                TV2ContestOverlay(
                    contest: contest,
                    isChatExpanded: false,
                    onJoin: {
                        print("Joined contest from casting view")
                    },
                    onDismiss: {
                        webSocketManager.currentContest = nil
                    }
                )
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
                Text(castingManager.selectedDevice?.name ?? "Living TV")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("4. divisjon, menn Fotball")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.top, 8)
            
            // Cast icon
            Image(systemName: "tv.and.hifispeaker.fill")
                .font(.system(size: 22))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
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


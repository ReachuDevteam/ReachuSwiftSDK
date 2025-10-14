import SwiftUI

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
            // Background gradient
            LinearGradient(
                colors: [
                    Color(hex: "1a0033"),
                    Color(hex: "0a0015")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header con info de casting
                castingHeader
                
                Spacer()
                
                // Placeholder del TV (simulación de lo que se ve en la TV)
                tvPreview
                
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
        VStack(spacing: 12) {
            HStack {
                // Back button
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                }
                
                Spacer()
                
                // Stop casting button
                Button(action: {
                    castingManager.stopCasting()
                    dismiss()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Stop Casting")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(Color.red.opacity(0.8))
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 50)
            
            // Casting info
            HStack(spacing: 12) {
                Image(systemName: castingManager.selectedDevice?.type.icon ?? "tv")
                    .font(.system(size: 20))
                    .foregroundColor(TV2Theme.Colors.primary)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Casting to \(castingManager.selectedDevice?.name ?? "TV")")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    
                    if let location = castingManager.selectedDevice?.location {
                        Text(location)
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
        }
        .background(Color.black.opacity(0.3))
    }
    
    private var tvPreview: some View {
        VStack(spacing: 16) {
            // Simulación de lo que se ve en la TV
            ZStack {
                // Frame del TV
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black)
                    .aspectRatio(16/9, contentMode: .fit)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 2)
                    )
                
                // Match info en el TV
                VStack(spacing: 8) {
                    Text(match.title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(match.subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                    
                    // Play indicator
                    if isPlaying {
                        Image(systemName: "play.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white.opacity(0.3))
                            .padding(.top, 20)
                    } else {
                        Image(systemName: "pause.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white.opacity(0.3))
                            .padding(.top, 20)
                    }
                }
            }
            .padding(.horizontal, 24)
            
            Text("Kolbotn - Nordstrand 2")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            
            Text("4. divisjon, menn Fotball")
                .font(.system(size: 13))
                .foregroundColor(.gray)
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


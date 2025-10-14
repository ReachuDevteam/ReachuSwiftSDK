import SwiftUI

/// Componente de encuesta/poll para TV2
/// Horizontal: se muestra a la derecha del chat
/// Vertical: se muestra sobre el chat, más pequeño
struct TV2PollOverlay: View {
    let poll: PollEventData
    let isChatExpanded: Bool
    let onVote: (String) -> Void
    let onDismiss: () -> Void
    
    @State private var selectedOption: String?
    @State private var hasVoted = false
    @State private var showResults = false
    @State private var dragOffset: CGFloat = 0
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    private var isLandscape: Bool {
        verticalSizeClass == .compact
    }
    
    // Ajustar bottom padding basado en si el chat está expandido
    private var bottomPadding: CGFloat {
        if isLandscape {
            return 16
        } else {
            return isChatExpanded ? 250 : 80 // Más espacio cuando el chat está expandido
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if isLandscape {
                // Horizontal: lado derecho, más ancho
                Spacer()
                HStack(spacing: 0) {
                    Spacer()
                    pollCard
                        .frame(width: 320) // Más ancho en horizontal
                        .padding(.trailing, 16)
                        .padding(.bottom, 16)
                        .offset(x: dragOffset)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    if value.translation.width > 0 {
                                        dragOffset = value.translation.width
                                    }
                                }
                                .onEnded { value in
                                    if value.translation.width > 100 {
                                        onDismiss()
                                    } else {
                                        withAnimation(.spring()) {
                                            dragOffset = 0
                                        }
                                    }
                                }
                        )
                }
            } else {
                // Vertical: sobre el chat, más compacto
                Spacer()
                pollCard
                    .padding(.horizontal, 16)
                    .padding(.bottom, bottomPadding) // Ajuste dinámico según estado del chat
                    .offset(y: dragOffset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if value.translation.height > 0 {
                                    dragOffset = value.translation.height
                                }
                            }
                            .onEnded { value in
                                if value.translation.height > 100 {
                                    onDismiss()
                                } else {
                                    withAnimation(.spring()) {
                                        dragOffset = 0
                                    }
                                }
                            }
                    )
            }
        }
    }
    
    private var pollCard: some View {
        VStack(spacing: 0) {
            VStack(spacing: isLandscape ? 10 : 10) {
                // Drag indicator
                HStack {
                    if isLandscape {
                        // En horizontal: indicador vertical a la izquierda
                        Capsule()
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 4, height: 32)
                            .padding(.leading, 8)
                        Spacer()
                    } else {
                        // En vertical: indicador horizontal centrado
                        Spacer()
                        Capsule()
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 32, height: 4)
                        Spacer()
                    }
                }
                .padding(.top, 8)
                
                // Sponsor badge arriba a la izquierda
                if let campaignLogo = poll.campaignLogo, !campaignLogo.isEmpty {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Sponset av")
                                .font(.system(size: isLandscape ? 8 : 9, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                            
                            AsyncImage(url: URL(string: campaignLogo)) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(maxWidth: isLandscape ? 70 : 80, maxHeight: isLandscape ? 20 : 24)
                                case .empty:
                                    ProgressView()
                                        .scaleEffect(0.5)
                                        .frame(width: isLandscape ? 70 : 80, height: isLandscape ? 20 : 24)
                                case .failure:
                                    EmptyView()
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        }
                        Spacer()
                    }
                    .padding(.horizontal, isLandscape ? 10 : 12)
                    .padding(.top, 4)
                }
                
                // Title (main question)
            Text(poll.question)
                .font(.system(size: isLandscape ? 14 : 14, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(isLandscape ? 3 : 2)
                .padding(.horizontal, isLandscape ? 12 : 16)
            
            // Subtitle (optional helper text)
            Text("Få raskere tilgang til kampene fra forsiden")
                .font(.system(size: isLandscape ? 10 : 10, weight: .regular))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .lineLimit(isLandscape ? 2 : 1)
                .padding(.horizontal, isLandscape ? 12 : 16)
            
            // Options
            VStack(spacing: isLandscape ? 8 : 6) {
                ForEach(Array(poll.options.enumerated()), id: \.offset) { index, option in
                    pollOptionButton(option: option, index: index)
                }
            }
            
            // Timer o mensaje de votación
            if hasVoted {
                if showResults {
                    // Resultados
                    Text("Takk for at du stemte!")
                        .font(.system(size: isLandscape ? 11 : 10))
                        .foregroundColor(TV2Theme.Colors.primary)
                        .padding(.top, 4)
                } else {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: TV2Theme.Colors.primary))
                        .scaleEffect(0.8)
                        .padding(.top, 4)
                }
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: isLandscape ? 10 : 9))
                    Text("\(poll.duration)s")
                        .font(.system(size: isLandscape ? 11 : 10))
                }
                .foregroundColor(.white.opacity(0.6))
                .padding(.top, 4)
            }
            }
            .padding(isLandscape ? 16 : 14)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.4))
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.ultraThinMaterial)
                    )
            )
            .shadow(color: .black.opacity(0.6), radius: 20, x: 0, y: 8)
            .rotation3DEffect(
                .degrees(showResults ? 180 : 0),
                axis: (x: 0, y: 1, z: 0)
            )
        }
    }
    
    private func pollOptionButton(option: PollOption, index: Int) -> some View {
        Button(action: {
            guard !hasVoted else { return }
            selectedOption = option.text
            hasVoted = true
            onVote(option.text)
            
            // Simular delay para "obtener resultados"
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    showResults = true
                }
            }
        }) {
            HStack(spacing: 10) {
                // Avatar/Icon circle
                if let avatarUrl = option.avatarUrl {
                    // Mostrar imagen/logo si hay avatarUrl
                    AsyncImage(url: URL(string: avatarUrl)) { phase in
                        switch phase {
                        case .success(let image):
                            // Logo/escudo sobre fondo circular
                            Circle()
                                .fill(Color.white.opacity(0.1))
                                .frame(width: isLandscape ? 40 : 36, height: isLandscape ? 40 : 36)
                                .overlay(
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: isLandscape ? 32 : 28, height: isLandscape ? 32 : 28)
                                )
                        case .empty:
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: isLandscape ? 40 : 36, height: isLandscape ? 40 : 36)
                                .overlay(
                                    ProgressView()
                                        .scaleEffect(0.6)
                                )
                        case .failure:
                            // Fallback: primera letra
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "5B5FCF"), Color(hex: "7B7FEF")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: isLandscape ? 40 : 36, height: isLandscape ? 40 : 36)
                                .overlay(
                                    Text(String(option.text.prefix(1)).uppercased())
                                        .font(.system(size: isLandscape ? 16 : 14, weight: .bold))
                                        .foregroundColor(.white)
                                )
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    // Sin avatarUrl: mostrar círculo con primera letra
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "5B5FCF"), Color(hex: "7B7FEF")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: isLandscape ? 40 : 36, height: isLandscape ? 40 : 36)
                        .overlay(
                            Text(String(option.text.prefix(1)).uppercased())
                                .font(.system(size: isLandscape ? 16 : 14, weight: .bold))
                                .foregroundColor(.white)
                        )
                }
                
                Text(option.text)
                    .font(.system(size: isLandscape ? 14 : 12, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: isLandscape ? 20 : 18)
                    .fill(
                        selectedOption == option.text 
                        ? Color(hex: "5B5FCF")
                        : Color(hex: "3A3D5C")
                    )
            )
        }
        .disabled(hasVoted)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        TV2PollOverlay(
            poll: PollEventData(
                id: "poll_test",
                question: "Hvem scorer i denne andre omgangen?",
                options: [
                    PollOption(text: "Lamine Yamal", avatarUrl: "http://event-streamer-angelo100.replit.app/@fs/home/runner/workspace/attached_assets/barcelona_1760348072481.png"),
                    PollOption(text: "Raphina", avatarUrl: nil),
                    PollOption(text: "Dembélé", avatarUrl: nil),
                    PollOption(text: "Vitinha", avatarUrl: nil)
                ],
                duration: 90,
                imageUrl: "http://event-streamer-angelo100.replit.app/@fs/home/runner/workspace/attached_assets/barcelona_1760348072481.png",
                campaignLogo: "http://event-streamer-angelo100.replit.app/objects/uploads/16475fd2-da1f-4e9f-8eb4-362067b27858"
            ),
            isChatExpanded: false,
            onVote: { option in
                print("Votado: \(option)")
            },
            onDismiss: {
                print("Cerrado")
            }
        )
    }
}


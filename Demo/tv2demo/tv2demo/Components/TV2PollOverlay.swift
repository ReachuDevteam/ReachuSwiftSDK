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
                // Horizontal: ocupa lado derecho
                Spacer()
                HStack(spacing: 0) {
                    Spacer()
                    pollCard
                        .frame(width: 240)
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
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: isLandscape ? 12 : 10) {
                // Drag indicator
                Capsule()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 32, height: 4)
                    .padding(.top, 8)
                
                // Title (main question)
            Text(poll.question)
                .font(.system(size: isLandscape ? 16 : 14, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .padding(.horizontal, 16)
            
            // Subtitle (optional helper text)
            Text("Få raskere tilgang til kampene fra forsiden")
                .font(.system(size: isLandscape ? 12 : 10, weight: .regular))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .padding(.horizontal, 16)
            
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
                .fill(Color.black.opacity(0.6))
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
            
            // Sponsor badge en esquina inferior derecha
            if let campaignLogo = poll.campaignLogo, !campaignLogo.isEmpty {
                TV2SponsorBadge(logoUrl: campaignLogo)
                    .padding(.trailing, 12)
                    .padding(.bottom, 12)
            }
        }
    }
    
    private func pollOptionButton(option: String, index: Int) -> some View {
        Button(action: {
            guard !hasVoted else { return }
            selectedOption = option
            hasVoted = true
            onVote(option)
            
            // Simular delay para "obtener resultados"
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    showResults = true
                }
            }
        }) {
            HStack(spacing: 10) {
                // Flag/Icon circle (simulado con gradiente)
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
                        Text(String(option.prefix(1)).uppercased())
                            .font(.system(size: isLandscape ? 16 : 14, weight: .bold))
                            .foregroundColor(.white)
                    )
                
                Text(option)
                    .font(.system(size: isLandscape ? 14 : 12, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: isLandscape ? 20 : 18)
                    .fill(
                        selectedOption == option 
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
                question: "¿Cuál es tu smartphone favorito?",
                options: ["iPhone", "Samsung", "Google Pixel", "Otro"],
                duration: 60,
                campaignLogo: "https://upload.wikimedia.org/wikipedia/commons/thumb/2/24/Adidas_logo.png/800px-Adidas_logo.png"
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


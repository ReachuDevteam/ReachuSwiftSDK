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
                        .frame(width: 280)
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
        VStack(spacing: isLandscape ? 12 : 8) {
            // Drag indicator
            Capsule()
                .fill(Color.white.opacity(0.3))
                .frame(width: 32, height: 4)
                .padding(.top, 8)
            
            // Header
            HStack {
                Text("📊 AVSTEMNING")
                    .font(.system(size: isLandscape ? 11 : 10, weight: .bold))
                    .foregroundColor(TV2Theme.Colors.primary)
                
                Spacer()
            }
            
            // Question
            Text(poll.question)
                .font(.system(size: isLandscape ? 14 : 12, weight: .semibold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(3)
            
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
        .padding(isLandscape ? 16 : 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "120019"))
        )
        .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 5)
        .rotation3DEffect(
            .degrees(showResults ? 180 : 0),
            axis: (x: 0, y: 1, z: 0)
        )
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
            HStack(spacing: 8) {
                // Letter indicator
                Text("\(["A", "B", "C", "D", "E"][index])")
                    .font(.system(size: isLandscape ? 12 : 10, weight: .bold))
                    .foregroundColor(selectedOption == option ? .white : TV2Theme.Colors.primary)
                    .frame(width: isLandscape ? 24 : 20, height: isLandscape ? 24 : 20)
                    .background(
                        Circle()
                            .fill(selectedOption == option ? TV2Theme.Colors.primary : Color.white.opacity(0.1))
                    )
                
                Text(option)
                    .font(.system(size: isLandscape ? 13 : 11, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                if selectedOption == option {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: isLandscape ? 16 : 14))
                        .foregroundColor(TV2Theme.Colors.primary)
                }
            }
            .padding(.horizontal, isLandscape ? 12 : 10)
            .padding(.vertical, isLandscape ? 10 : 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(selectedOption == option ? TV2Theme.Colors.primary.opacity(0.2) : Color.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        selectedOption == option ? TV2Theme.Colors.primary : Color.white.opacity(0.1),
                        lineWidth: selectedOption == option ? 2 : 1
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
                duration: 60
            ),
            onVote: { option in
                print("Votado: \(option)")
            },
            onDismiss: {
                print("Cerrado")
            }
        )
    }
}


import SwiftUI

/// Poll card para casting en Viaplay
/// Copia EXACTA del estilo de tv2demo con colores de Viaplay
struct ViaplayCastingPollCardView: View {
    let poll: PollEventData
    let onVote: (String) -> Void
    let onDismiss: () -> Void
    
    @State private var selectedOption: String?
    @State private var hasVoted = false
    @State private var showResults = false
    @State private var dragOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Front side - Poll question
            if !showResults {
                pollFrontView
                    .rotation3DEffect(
                        .degrees(0),
                        axis: (x: 0, y: 1, z: 0)
                    )
            }
            
            // Back side - Results
            if showResults {
                pollResultsView
                    .rotation3DEffect(
                        .degrees(180),
                        axis: (x: 0, y: 1, z: 0)
                    )
            }
        }
        .rotation3DEffect(
            .degrees(showResults ? 180 : 0),
            axis: (x: 0, y: 1, z: 0),
            perspective: 0.5
        )
        .frame(maxWidth: UIScreen.main.bounds.width - 40) // Margen de 20px a cada lado
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
    
    // MARK: - Front View
    
    private var pollFrontView: some View {
        VStack(spacing: 0) {
            VStack(spacing: 10) {
                // Drag indicator
                Capsule()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 32, height: 4)
                    .padding(.top, 8)
                
                // Sponsor badge arriba a la izquierda (SIEMPRE visible con logo1)
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Sponset av")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Image("logo1")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: 80, maxHeight: 24)
                    }
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.top, 4)
                
                // Question
                Text(poll.question)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, 16)
                
                // Subtitle
                Text("Få raskere tilgang til kampene fra forsiden")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .padding(.horizontal, 16)
                
                // Options
                VStack(spacing: 6) {
                    ForEach(Array(poll.options.enumerated()), id: \.offset) { index, option in
                        pollOptionButton(option: option, index: index)
                    }
                }
                
                // Timer
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 9))
                    Text("\(poll.duration)s")
                        .font(.system(size: 10))
                }
                .foregroundColor(.white.opacity(0.6))
                .padding(.top, 4)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.4))
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.ultraThinMaterial)
                    )
            )
            .shadow(color: .black.opacity(0.6), radius: 20, x: 0, y: 8)
        }
    }
    
    // MARK: - Results View
    
    private var pollResultsView: some View {
        VStack(spacing: 0) {
            VStack(spacing: 10) {
                // Drag indicator
                Capsule()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 32, height: 4)
                    .padding(.top, 8)
                
                // Title
                Text("Resultater")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                
                Text("Takk for at du stemte!")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(ViaplayTheme.Colors.pink)
                    .padding(.horizontal, 16)
                
                // Results bars
                VStack(spacing: 8) {
                    ForEach(Array(poll.options.enumerated()), id: \.offset) { index, option in
                        resultBar(option: option, isSelected: option.text == selectedOption)
                    }
                }
                .padding(.top, 8)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.4))
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.ultraThinMaterial)
                    )
            )
            .shadow(color: .black.opacity(0.6), radius: 20, x: 0, y: 8)
        }
    }
    
    // MARK: - Poll Option Button
    
    private func pollOptionButton(option: PollOption, index: Int) -> some View {
        Button(action: {
            guard !hasVoted else { return }
            selectedOption = option.text
            hasVoted = true
            onVote(option.text)
            
            // Simular delay para "obtener resultados" y luego hacer flip
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeInOut(duration: 0.6)) {
                    showResults = true
                }
            }
        }) {
            HStack(spacing: 10) {
                // Avatar/Icon circle
                if let avatarUrl = option.avatarUrl, !avatarUrl.isEmpty {
                    // Mostrar imagen/logo si hay avatarUrl
                    AsyncImage(url: URL(string: avatarUrl)) { phase in
                        switch phase {
                        case .success(let image):
                            // Logo/escudo sobre fondo circular blanco
                            Circle()
                                .fill(Color.white)
                                .frame(width: 36, height: 36)
                                .overlay(
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 26, height: 26)
                                )
                                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                        case .empty:
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 36, height: 36)
                                .overlay(
                                    ProgressView()
                                        .scaleEffect(0.6)
                                        .tint(.white)
                                )
                        case .failure:
                            // Fallback: primera letra con gradiente de Viaplay
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [ViaplayTheme.Colors.pink.opacity(0.6), ViaplayTheme.Colors.pink.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Text(String(option.text.prefix(1)).uppercased())
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                )
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    // Sin avatarUrl: mostrar círculo con primera letra y gradiente de Viaplay
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [ViaplayTheme.Colors.pink.opacity(0.6), ViaplayTheme.Colors.pink.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)
                        .overlay(
                            Text(String(option.text.prefix(1)).uppercased())
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        )
                }
                
                Text(option.text)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        selectedOption == option.text 
                        ? ViaplayTheme.Colors.pink.opacity(0.6)
                        : Color(hex: "3A3D5C")
                    )
            )
        }
        .disabled(hasVoted)
    }
    
    // MARK: - Result Bar
    
    private func resultBar(option: PollOption, isSelected: Bool) -> some View {
        let percentage = calculatePercentage(for: option)
        
        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(option.text)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(Int(percentage))%")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(isSelected ? ViaplayTheme.Colors.pink : .white)
            }
            
            // Progress bar con GeometryReader para ancho dinámico (como tv2demo)
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.2))
                    
                    // Fill
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? ViaplayTheme.Colors.pink : ViaplayTheme.Colors.pink.opacity(0.6))
                        .frame(width: geometry.size.width * (percentage / 100))
                }
            }
            .frame(height: 6)
        }
        .padding(.horizontal, 16)
    }
    
    private func calculatePercentage(for option: PollOption) -> Double {
        // Simulate results - in production, this would come from the server
        guard let selected = selectedOption else { return 0 }
        
        if option.text == selected {
            return 75.0 // Selected option gets 75%
        } else {
            let remaining = 25.0
            let otherOptions = poll.options.filter { $0.text != selected }.count
            return remaining / Double(otherOptions)
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        ViaplayCastingPollCardView(
            poll: PollEventData(
                id: "1",
                question: "Hvem vinner kampen?",
                options: [
                    PollOption(text: "Barcelona", avatarUrl: "https://upload.wikimedia.org/wikipedia/en/4/47/FC_Barcelona_%28crest%29.svg"),
                    PollOption(text: "PSG", avatarUrl: nil),
                    PollOption(text: "Empate", avatarUrl: nil)
                ],
                duration: 30,
                imageUrl: nil,
                campaignLogo: nil
            ),
            onVote: { _ in },
            onDismiss: {}
        )
    }
}

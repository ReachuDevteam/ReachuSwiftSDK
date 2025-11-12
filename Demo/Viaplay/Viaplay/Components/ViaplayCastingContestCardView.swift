import SwiftUI

/// Contest card para casting en Viaplay
/// Adaptado de tv2demo con colores de Viaplay
struct ViaplayCastingContestCardView: View {
    let contest: ContestEventData
    let onJoin: () -> Void
    let onDismiss: () -> Void
    
    @State private var hasJoined = false
    @State private var showWheel = false
    @State private var wheelRotation: Double = 0
    @State private var finalPrize: String = ""
    @State private var isSpinning = false
    @State private var countdown: Int = 10
    @State private var dragOffset: CGFloat = 0
    
    private let prizes = [
        "🎁 Premio Principal",
        "💰 50% Descuento",
        "🎉 Premio Sorpresa",
        "⭐ Vale Regalo",
        "🏆 Premio Especial",
        "🎊 Descuento 30%"
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            if showWheel {
                wheelView
            } else {
                contestInfoView
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.4))
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                )
        )
        .frame(maxWidth: UIScreen.main.bounds.width - 40)
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
        .onAppear {
            startCountdown()
        }
    }
    
    // MARK: - Contest Info View
    
    private var contestInfoView: some View {
        VStack(spacing: 12) {
            // Drag indicator
            Capsule()
                .fill(Color.white.opacity(0.3))
                .frame(width: 32, height: 4)
            
            // Sponsor badge - logo1 en esquina superior izquierda
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
            
            // Contest name
            Text(contest.name)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            // Prize
            VStack(spacing: 6) {
                Text("PREMIER")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
                
                Text(contest.prize)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(ViaplayTheme.Colors.pink)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
            )
            
            // Info
            VStack(spacing: 8) {
                HStack {
                    Text("Frist: \(contest.deadline)")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.8))
                    Spacer()
                }
                
                HStack {
                    Text("Maks deltakere: \(contest.maxParticipants)")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.8))
                    Spacer()
                }
            }
            
            // Countdown or button
            if hasJoined {
                VStack(spacing: 8) {
                    Text("Du er med!")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color.green)
                    
                    if countdown > 0 {
                        HStack(spacing: 8) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: ViaplayTheme.Colors.pink))
                                .scaleEffect(0.8)
                            
                            Text("Trekking om \(countdown)s...")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
                .padding(.vertical, 12)
            } else {
                Button(action: {
                    hasJoined = true
                    onJoin()
                }) {
                    Text("Bli med!")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(ViaplayTheme.Colors.pink.opacity(0.8))
                        )
                }
            }
        }
    }
    
    // MARK: - Wheel View
    
    private var wheelView: some View {
        VStack(spacing: 16) {
            // Drag indicator
            Capsule()
                .fill(Color.white.opacity(0.3))
                .frame(width: 32, height: 4)
            
            Text("¡Girando la ruleta!")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
            
            // Wheel
            ZStack {
                ForEach(Array(prizes.enumerated()), id: \.offset) { index, prize in
                    Text(prize)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 120)
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(index % 2 == 0 ? ViaplayTheme.Colors.pink.opacity(0.6) : ViaplayTheme.Colors.pink.opacity(0.3))
                        )
                        .rotationEffect(.degrees(Double(index) * 60 + wheelRotation))
                        .offset(y: -80)
                }
            }
            .frame(width: 200, height: 200)
            
            if !finalPrize.isEmpty {
                VStack(spacing: 8) {
                    Text("¡Has ganado!")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color.green)
                    
                    Text(finalPrize)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(ViaplayTheme.Colors.pink)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
        }
        .padding(.vertical, 20)
    }
    
    // MARK: - Helper Functions
    
    private func startCountdown() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if countdown > 0 {
                countdown -= 1
            } else {
                timer.invalidate()
                if hasJoined {
                    withAnimation {
                        showWheel = true
                    }
                    spinWheel()
                }
            }
        }
    }
    
    private func spinWheel() {
        isSpinning = true
        let totalSpins = 5
        let randomPrizeIndex = Int.random(in: 0..<prizes.count)
        let finalRotation = Double(totalSpins * 360) + Double(randomPrizeIndex * 60)
        
        withAnimation(.easeOut(duration: 3.0)) {
            wheelRotation = finalRotation
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            isSpinning = false
            finalPrize = prizes[randomPrizeIndex]
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        ViaplayCastingContestCardView(
            contest: ContestEventData(
                id: "1",
                name: "Predice el resultado final",
                prize: "1000 NOK",
                deadline: "18:00",
                maxParticipants: 100,
                campaignLogo: nil
            ),
            onJoin: {},
            onDismiss: {}
        )
    }
}


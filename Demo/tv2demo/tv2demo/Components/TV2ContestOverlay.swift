import SwiftUI

/// Componente de concurso con ruleta animada
/// Usuario se une con "Bli med", cuando termina el contador muestra ruleta giratoria
struct TV2ContestOverlay: View {
    let contest: ContestEventData
    let onJoin: () -> Void
    let onDismiss: () -> Void
    
    @State private var hasJoined = false
    @State private var showWheel = false
    @State private var wheelRotation: Double = 0
    @State private var finalPrize: String = ""
    @State private var isSpinning = false
    @State private var countdown: Int = 10 // Countdown en segundos
    @State private var dragOffset: CGFloat = 0
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    private var isLandscape: Bool {
        verticalSizeClass == .compact
    }
    
    // Premios de la ruleta
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
            if isLandscape {
                // Horizontal: lado derecho
                Spacer()
                HStack(spacing: 0) {
                    Spacer()
                    contestCard
                        .frame(width: 320)
                        .padding(.trailing, 16)
                        .padding(.bottom, 16)
                        .offset(x: dragOffset)
                        .gesture(dragGesture)
                }
            } else {
                // Vertical: sobre el chat
                Spacer()
                contestCard
                    .padding(.horizontal, 16)
                    .padding(.bottom, 80)
                    .offset(y: dragOffset)
                    .gesture(dragGesture)
            }
        }
        .onAppear {
            startCountdown()
        }
    }
    
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if isLandscape {
                    if value.translation.width > 0 {
                        dragOffset = value.translation.width
                    }
                } else {
                    if value.translation.height > 0 {
                        dragOffset = value.translation.height
                    }
                }
            }
            .onEnded { value in
                let threshold: CGFloat = 100
                if isLandscape {
                    if value.translation.width > threshold {
                        onDismiss()
                    } else {
                        withAnimation(.spring()) {
                            dragOffset = 0
                        }
                    }
                } else {
                    if value.translation.height > threshold {
                        onDismiss()
                    } else {
                        withAnimation(.spring()) {
                            dragOffset = 0
                        }
                    }
                }
            }
    }
    
    private var contestCard: some View {
        VStack(spacing: 0) {
            if showWheel {
                wheelView
            } else {
                contestInfoView
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "120019"))
        )
        .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 5)
    }
    
    // MARK: - Contest Info View
    
    private var contestInfoView: some View {
        VStack(spacing: 12) {
            // Drag indicator
            Capsule()
                .fill(Color.white.opacity(0.3))
                .frame(width: 32, height: 4)
            
            // Header
            HStack {
                Text("🎁 KONKURRANSE")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(TV2Theme.Colors.primary)
                Spacer()
            }
            
            // Contest name
            Text(contest.name)
                .font(.system(size: isLandscape ? 16 : 18, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            // Prize
            VStack(spacing: 6) {
                Text("PREMIER")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
                
                Text(contest.prize)
                    .font(.system(size: isLandscape ? 13 : 14, weight: .semibold))
                    .foregroundColor(TV2Theme.Colors.primary)
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
                    Image(systemName: "calendar")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                    Text("Frist: \(contest.deadline)")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.8))
                    Spacer()
                }
                
                HStack {
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
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
                                .progressViewStyle(CircularProgressViewStyle(tint: TV2Theme.Colors.primary))
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
                    HStack(spacing: 8) {
                        Image(systemName: "party.popper.fill")
                            .font(.system(size: 16))
                        Text("Bli med!")
                            .font(.system(size: 15, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [TV2Theme.Colors.primary, TV2Theme.Colors.secondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
            }
        }
    }
    
    // MARK: - Wheel View
    
    private var wheelView: some View {
        VStack(spacing: 16) {
            // Header
            Text(isSpinning ? "Snurrer..." : "Gratulerer!")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            // Wheel
            ZStack {
                // Pointer at top
                Triangle()
                    .fill(Color.red)
                    .frame(width: 20, height: 25)
                    .offset(y: -140)
                
                // Wheel circle
                ZStack {
                    ForEach(0..<prizes.count, id: \.self) { index in
                        wheelSegment(index: index)
                    }
                }
                .rotationEffect(.degrees(wheelRotation))
                .frame(width: 280, height: 280)
            }
            
            // Prize result
            if !isSpinning && !finalPrize.isEmpty {
                VStack(spacing: 8) {
                    Text("Du vant:")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text(finalPrize)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(TV2Theme.Colors.primary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.1))
                )
            }
        }
    }
    
    private func wheelSegment(index: Int) -> some View {
        let angle = 360.0 / Double(prizes.count)
        let startAngle = angle * Double(index)
        
        return ZStack {
            // Segment background
            Circle()
                .trim(from: CGFloat(startAngle / 360.0), to: CGFloat((startAngle + angle) / 360.0))
                .stroke(segmentColor(index: index), lineWidth: 45)
                .frame(width: 235, height: 235)
            
            // Segment text
            Text(prizes[index])
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white)
                .rotationEffect(.degrees(startAngle + angle / 2))
                .offset(y: -117)
                .rotationEffect(.degrees(-(startAngle + angle / 2)))
        }
        .rotationEffect(.degrees(startAngle + angle / 2))
    }
    
    private func segmentColor(index: Int) -> Color {
        let colors: [Color] = [
            Color(red: 0.48, green: 0.37, blue: 1.0), // Purple
            Color(red: 1.0, green: 0.4, blue: 0.6),   // Pink
            Color(red: 0.3, green: 0.7, blue: 1.0),   // Blue
            Color(red: 1.0, green: 0.6, blue: 0.2),   // Orange
            Color(red: 0.4, green: 0.9, blue: 0.6),   // Green
            Color(red: 0.9, green: 0.3, blue: 0.3)    // Red
        ]
        return colors[index % colors.count]
    }
    
    // MARK: - Helpers
    
    private func startCountdown() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if countdown > 0 {
                countdown -= 1
            } else {
                timer.invalidate()
                if hasJoined {
                    startWheel()
                }
            }
        }
    }
    
    private func startWheel() {
        withAnimation {
            showWheel = true
        }
        
        // Wait a bit then spin
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            spinWheel()
        }
    }
    
    private func spinWheel() {
        isSpinning = true
        
        // Random final position (3-5 full rotations + random angle)
        let rotations = Double.random(in: 3...5)
        let finalAngle = Double.random(in: 0...360)
        let totalRotation = (rotations * 360) + finalAngle
        
        withAnimation(.timingCurve(0.17, 0.67, 0.3, 1.0, duration: 4.0)) {
            wheelRotation = totalRotation
        }
        
        // Show result after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            isSpinning = false
            
            // Calculate which prize based on final angle
            let normalizedAngle = finalAngle.truncatingRemainder(dividingBy: 360)
            let segmentAngle = 360.0 / Double(prizes.count)
            let prizeIndex = Int((360 - normalizedAngle) / segmentAngle) % prizes.count
            finalPrize = prizes[prizeIndex]
        }
    }
}

// MARK: - Triangle Shape

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        TV2ContestOverlay(
            contest: ContestEventData(
                id: "contest_123",
                name: "Gran Sorteo Tech 2024",
                prize: "Gana un MacBook Pro M3, AirPods Pro y más",
                deadline: "2024-12-31",
                maxParticipants: 1000
            ),
            onJoin: {
                print("Usuario se unió")
            },
            onDismiss: {
                print("Cerrado")
            }
        )
    }
}


import SwiftUI

/// Offer Banner View (for NavigationLink)
/// Version without internal button for use with NavigationLink
struct OfferBannerView: View {
    let title: String
    let subtitle: String?
    
    @State private var timeRemaining: TimeInterval = 2 * 24 * 3600 + 2 * 3600 // 2 días, 2 horas
    @State private var timer: Timer?
    
    init(
        title: String = "Ukens tilbud",
        subtitle: String? = "Se denne ukes beste tilbud"
    ) {
        self.title = title
        self.subtitle = subtitle
    }
    
    var body: some View {
        ZStack {
            // Background layer
            backgroundLayer
            
            // Discount badge (top-right)
            discountBadge
            
            // Content (left side)
            contentLayer
        }
        .frame(height: 200)
        .cornerRadius(TV2Theme.CornerRadius.medium)
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        .onAppear {
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    // MARK: - Background
    
    private var backgroundLayer: some View {
        ZStack(alignment: .leading) {
            // Background with image and overlays
            ZStack {
                // Background image (football field)
                Image("football_field_bg")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                
                // Dark overlay solo en el lado izquierdo para legibilidad del texto
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.5),
                        Color.black.opacity(0.2),
                        Color.clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
            .clipped()
        }
    }
    
    // MARK: - Discount Badge
    
    private var discountBadge: some View {
        VStack {
            HStack {
                Spacer()
                
                VStack(spacing: 2) {
                    Text("Opptil")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("-30%")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.red)
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                )
                .padding(.top, TV2Theme.Spacing.md)
                .padding(.trailing, TV2Theme.Spacing.md)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Content
    
    private var contentLayer: some View {
        VStack(alignment: .leading, spacing: TV2Theme.Spacing.sm) {
            // Logo
            Image("logo")
                .resizable()
                .scaledToFit()
                .frame(height: 30)
            
            // Title
            Text(title)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
            
            // Subtitle
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(TV2Theme.Typography.body)
                    .foregroundColor(.white.opacity(0.9))
            }
            
            // Countdown
            Text(countdownText)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.95))
                .padding(.vertical, 4)
            
            // Arrow indicator
            HStack(spacing: TV2Theme.Spacing.xs) {
                Text("Se alle tilbud")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, TV2Theme.Spacing.md)
            .padding(.vertical, TV2Theme.Spacing.sm)
            .background(
                Capsule()
                    .fill(TV2Theme.Colors.primary)
            )
        }
        .padding(.leading, TV2Theme.Spacing.xl)
        .padding(.top, TV2Theme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Countdown Logic
    
    private var countdownText: String {
        let days = Int(timeRemaining) / 86400
        let hours = (Int(timeRemaining) % 86400) / 3600
        let minutes = (Int(timeRemaining) % 3600) / 60
        let seconds = Int(timeRemaining) % 60
        
        var components: [String] = []
        
        if days > 0 {
            components.append("\(days) \(days == 1 ? "dag" : "dager")")
        }
        if hours > 0 {
            components.append("\(hours) \(hours == 1 ? "time" : "timer")")
        }
        if minutes > 0 {
            components.append("\(minutes) \(minutes == 1 ? "minutt" : "minutter")")
        }
        if seconds > 0 || components.isEmpty {
            components.append("\(seconds) \(seconds == 1 ? "sekund" : "sekunder")")
        }
        
        return components.joined(separator: " og ")
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                timer?.invalidate()
            }
        }
    }
}

/// Offer Banner Component (with button)
/// Banner promocional con imagen de fondo para ofertas especiales
struct OfferBanner: View {
    let title: String
    let subtitle: String?
    let onTap: () -> Void
    
    @State private var timeRemaining: TimeInterval = 2 * 24 * 3600 + 2 * 3600 // 2 días, 2 horas
    @State private var timer: Timer?
    
    init(
        title: String = "Ukens tilbud",
        subtitle: String? = "Se denne ukes beste tilbud",
        onTap: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.onTap = onTap
    }
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Background layer
                backgroundLayer
                
                // Discount badge (top-right)
                discountBadge
                
                // Content (left side)
                contentLayer
            }
            .frame(height: 200)
            .cornerRadius(TV2Theme.CornerRadius.medium)
            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
        .onAppear {
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    // MARK: - Background
    
    private var backgroundLayer: some View {
        ZStack(alignment: .leading) {
                // Background with image and overlays
                ZStack {
                    // Background image (football field)
                    Image("football_field_bg")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                    
                    // Dark overlay solo en el lado izquierdo para legibilidad del texto
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.5),
                            Color.black.opacity(0.2),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                }
                .clipped()
        }
    }
    
    // MARK: - Discount Badge
    
    private var discountBadge: some View {
        VStack {
            HStack {
                Spacer()
                
                VStack(spacing: 2) {
                    Text("Opptil")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("-30%")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.red)
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                )
                .padding(.top, TV2Theme.Spacing.md)
                .padding(.trailing, TV2Theme.Spacing.md)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Content
    
    private var contentLayer: some View {
        VStack(alignment: .leading, spacing: TV2Theme.Spacing.sm) {
            // Logo
            Image("logo")
                .resizable()
                .scaledToFit()
                .frame(height: 30)
            
            // Title
            Text(title)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
            
            // Subtitle
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(TV2Theme.Typography.body)
                    .foregroundColor(.white.opacity(0.9))
            }
            
            // Countdown
            Text(countdownText)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.95))
                .padding(.vertical, 4)
            
            // Arrow indicator
            HStack(spacing: TV2Theme.Spacing.xs) {
                Text("Se alle tilbud")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, TV2Theme.Spacing.md)
            .padding(.vertical, TV2Theme.Spacing.sm)
            .background(
                Capsule()
                    .fill(TV2Theme.Colors.primary)
            )
        }
        .padding(.leading, TV2Theme.Spacing.xl)
        .padding(.top, TV2Theme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Countdown Logic
    
    private var countdownText: String {
        let days = Int(timeRemaining) / 86400
        let hours = (Int(timeRemaining) % 86400) / 3600
        let minutes = (Int(timeRemaining) % 3600) / 60
        let seconds = Int(timeRemaining) % 60
        
        var components: [String] = []
        
        if days > 0 {
            components.append("\(days) \(days == 1 ? "dag" : "dager")")
        }
        if hours > 0 {
            components.append("\(hours) \(hours == 1 ? "time" : "timer")")
        }
        if minutes > 0 {
            components.append("\(minutes) \(minutes == 1 ? "minutt" : "minutter")")
        }
        if seconds > 0 || components.isEmpty {
            components.append("\(seconds) \(seconds == 1 ? "sekund" : "sekunder")")
        }
        
        return components.joined(separator: " og ")
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                timer?.invalidate()
            }
        }
    }
}

// MARK: - Scale Button Style
/// Adds a subtle scale animation on tap
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

#Preview {
    ZStack {
        TV2Theme.Colors.background
            .ignoresSafeArea()
        
        VStack(spacing: 20) {
            // Version for NavigationLink (without button)
            OfferBannerView()
                .padding(.horizontal, TV2Theme.Spacing.md)
            
            // Version with button
            OfferBanner {
                print("Banner tapped!")
            }
            .padding(.horizontal, TV2Theme.Spacing.md)
        }
    }
    .preferredColorScheme(.dark)
}


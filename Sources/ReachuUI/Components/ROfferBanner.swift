import SwiftUI
import ReachuCore

/// Dynamic Offer Banner component that receives configuration from backend
public struct ROfferBanner: View {
    let config: OfferBannerConfig
    @State private var timeRemaining: DateComponents?
    @State private var timer: Timer?
    
    public init(config: OfferBannerConfig) {
        self.config = config
    }
    
    public var body: some View {
        ZStack {
            // Background layer
            backgroundLayer
            
            // Content in two columns (same layout as hardcoded banner)
            HStack(alignment: .center, spacing: 16) {
                // Left column: Logo, title, subtitle, countdown
                VStack(alignment: .leading, spacing: 4) {
                    // Logo
                    AsyncImage(url: URL(string: config.logoUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 16)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.clear)
                            .frame(height: 16)
                    }
                    
                    // Title
                    Text(config.title)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    // Subtitle
                    if let subtitle = config.subtitle {
                        Text(subtitle)
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    // Countdown (analog style like hardcoded banner)
                    if let remaining = timeRemaining {
                        analogCountdown(timeRemaining: remaining)
                    }
                }
                
                Spacer()
                
                // Right column: Discount badge + Button (centered vertically)
                VStack(spacing: 8) {
                    // Discount badge
                    Text(config.discountBadgeText)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.8))
                        )
                    
                    // Button
                    Button(action: {
                        if let link = config.ctaLink, let url = URL(string: link) {
                            #if os(iOS)
                            UIApplication.shared.open(url)
                            #endif
                        }
                    }) {
                        HStack(spacing: 6) {
                            Text(config.ctaText)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Image(systemName: "arrow.right")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.purple)
                        )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .frame(height: 160)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        .onAppear {
            startCountdown()
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }
    
    // MARK: - Background Layer (same as hardcoded banner)
    
    private var backgroundLayer: some View {
        ZStack(alignment: .leading) {
            // Background with image and overlays
            ZStack {
                // Background image
                AsyncImage(url: URL(string: config.backgroundImageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                }
                
                // Dark overlay for readability (same gradient as hardcoded)
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.4),
                        Color.black.opacity(0.2)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
            .clipped()
        }
    }
    
    // MARK: - Analog Countdown (same style as hardcoded banner)
    
    private func analogCountdown(timeRemaining: DateComponents) -> some View {
        let days = timeRemaining.day ?? 0
        let hours = timeRemaining.hour ?? 0
        let minutes = timeRemaining.minute ?? 0
        let seconds = timeRemaining.second ?? 0
        
        return HStack(spacing: 4) {
            // Días
            if days > 0 {
                CountdownUnit(value: days, label: days == 1 ? "dag" : "dager")
            }
            
            // Horas
            if days > 0 || hours > 0 {
                CountdownUnit(value: hours, label: hours == 1 ? "time" : "timer")
            }
            
            // Minutos
            CountdownUnit(value: minutes, label: "min")
            
            // Segundos
            CountdownUnit(value: seconds, label: "sek")
        }
        .padding(.vertical, 3)
    }
    
    private func startCountdown() {
        let formatter = ISO8601DateFormatter()
        guard let endDate = formatter.date(from: config.countdownEndDate) else { 
            print("❌ [ROfferBanner] Invalid countdown date: \(config.countdownEndDate)")
            return 
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            let now = Date()
            if now >= endDate {
                timer.invalidate()
                timeRemaining = nil
            } else {
                timeRemaining = Calendar.current.dateComponents(
                    [.day, .hour, .minute, .second],
                    from: now,
                    to: endDate
                )
            }
        }
    }
}

/// Countdown display component
struct CountdownView: View {
    let timeRemaining: DateComponents
    
    var body: some View {
        HStack(spacing: 8) {
            TimeUnit(value: timeRemaining.day ?? 0, label: "dager")
            TimeUnit(value: timeRemaining.hour ?? 0, label: "timer")
            TimeUnit(value: timeRemaining.minute ?? 0, label: "min")
            TimeUnit(value: timeRemaining.second ?? 0, label: "sek")
        }
    }
}

/// Individual time unit display
struct TimeUnit: View {
    let value: Int
    let label: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(String(format: "%02d", value))
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(width: 40, height: 50)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
    }
}

/// Container view that manages the offer banner lifecycle
public struct ROfferBannerContainer: View {
    @StateObject private var componentManager: ComponentManager
    
    public init(campaignId: Int) {
        self._componentManager = StateObject(wrappedValue: ComponentManager(campaignId: campaignId))
    }
    
    public var body: some View {
        Group {
            if let bannerConfig = componentManager.activeBanner {
                ROfferBanner(config: bannerConfig)
            }
        }
        .onAppear {
            Task {
                await componentManager.connect()
            }
        }
        .onDisappear {
            componentManager.disconnect()
        }
    }
}

/// Countdown Unit Component (same style as hardcoded banner)
struct CountdownUnit: View {
    let value: Int
    let label: String
    
    var body: some View {
        VStack(spacing: 1) {
            // Dígitos
            Text(String(format: "%02d", value))
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
                .frame(minWidth: 24)
                .padding(.vertical, 2)
                .padding(.horizontal, 5)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                )
            
            // Label
            Text(label)
                .font(.system(size: 7, weight: .medium))
                .foregroundColor(.white.opacity(0.85))
        }
    }
}

#if DEBUG
/// Preview for development
struct ROfferBanner_Previews: PreviewProvider {
    static var previews: some View {
        ROfferBanner(config: OfferBannerConfig(
            logoUrl: "https://example.com/logo.png",
            title: "Ukens tilbud",
            subtitle: "Se denne ukes beste tilbud",
            backgroundImageUrl: "https://example.com/background.jpg",
            countdownEndDate: "2025-12-31T23:59:59Z",
            discountBadgeText: "Opp til 30%",
            ctaText: "Se alle tilbud →",
            ctaLink: "https://example.com/offers",
            overlayOpacity: 0.4
        ))
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif

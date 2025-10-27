import SwiftUI
import ReachuCore

/// Dynamic Offer Banner component that receives configuration from backend
public struct ROfferBanner: View {
    let config: OfferBannerConfig
    @State private var timeRemaining: DateComponents?
    @State private var timer: Timer?
    @State private var isImageLoaded = false
    @State private var isLogoLoaded = false
    
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
                    AsyncImage(url: URL(string: buildFullURL(from: config.logoUrl))) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 16)
                            .onAppear {
                                isLogoLoaded = true
                            }
                    } placeholder: {
                        // Simple skeleton for logo
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 16)
                    }
                    .onAppear {
                        print("🏷️ [ROfferBanner] Loading logo: \(buildFullURL(from: config.logoUrl))")
                    }
                    
                    // Title
                    if isImageLoaded {
                        Text(config.title)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .transition(.opacity)
                    } else {
                        // Simple skeleton for title
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 24)
                            .frame(maxWidth: 150)
                            .cornerRadius(4)
                    }
                    
                    // Subtitle
                    if let subtitle = config.subtitle {
                        if isImageLoaded {
                            Text(subtitle)
                                .font(.system(size: 11, weight: .regular))
                                .foregroundColor(.white.opacity(0.9))
                                .transition(.opacity)
                        } else {
                            // Simple skeleton for subtitle
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 11)
                                .frame(maxWidth: 120)
                                .cornerRadius(2)
                        }
                    }
                    
                    // Countdown (analog style like hardcoded banner)
                    if let remaining = timeRemaining, isImageLoaded {
                        analogCountdown(timeRemaining: remaining)
                            .transition(.opacity)
                    } else if !isImageLoaded {
                        // Simple skeleton for countdown
                        HStack(spacing: 4) {
                            ForEach(0..<4) { _ in
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 30, height: 20)
                                    .cornerRadius(4)
                            }
                        }
                        .padding(.vertical, 3)
                    }
                }
                
                Spacer()
                
                // Right column: Discount badge + Button (centered vertically)
                VStack(spacing: 8) {
                    // Discount badge
                    if isImageLoaded {
                        Text(config.discountBadgeText)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(Color.black.opacity(0.8))
                            )
                            .transition(.opacity)
                    } else {
                        // Simple skeleton for discount badge
                        Rectangle()
                            .fill(Color.gray.opacity(0.4))
                            .frame(width: 80, height: 32)
                            .cornerRadius(16)
                    }
                    
                    // Button
                    if isImageLoaded {
                        Button(action: {
                            handleCTAAction()
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
                                    .fill(buttonColor)
                            )
                        }
                        .transition(.opacity)
                    } else {
                        // Simple skeleton for button
                        Rectangle()
                            .fill(Color.gray.opacity(0.4))
                            .frame(width: 100, height: 28)
                            .cornerRadius(14)
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
    
    // MARK: - Computed Properties
    
    private var buttonColor: Color {
        if let colorString = config.buttonColor {
            return Color(hex: colorString) ?? Color.purple
        }
        return Color.purple
    }
    
    // MARK: - URL Helper
    
    private func buildFullURL(from path: String) -> String {
        // If it's already a full URL, return as is
        if path.hasPrefix("http://") || path.hasPrefix("https://") {
            return path
        }
        
        // If it's a relative path, prepend the base URL
        let baseURL = "https://event-streamer-angelo100.replit.app"
        return baseURL + path
    }
    
    // MARK: - Background Layer (same as hardcoded banner)
    
    private var backgroundLayer: some View {
        ZStack(alignment: .leading) {
            // Background with image and overlays
            ZStack {
                // Background image
                AsyncImage(url: URL(string: buildFullURL(from: config.backgroundImageUrl))) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .onAppear {
                            isImageLoaded = true
                        }
                } placeholder: {
                    // Simple skeleton for background image
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .overlay(
                            // Subtle shimmer effect
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.clear,
                                            Color.white.opacity(0.1),
                                            Color.clear
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .offset(x: isImageLoaded ? 200 : -200)
                                .animation(
                                    .easeInOut(duration: 2.0)
                                    .repeatForever(autoreverses: false),
                                    value: isImageLoaded
                                )
                        )
                }
                .onAppear {
                    print("🖼️ [ROfferBanner] Loading background image: \(buildFullURL(from: config.backgroundImageUrl))")
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
    
    /// Handle CTA button action with deeplink support
    private func handleCTAAction() {
        // Priority: deeplink > ctaLink
        if let deeplinkUrl = config.deeplinkUrl, !deeplinkUrl.isEmpty {
            handleDeeplink(url: deeplinkUrl, action: config.deeplinkAction)
        } else if let ctaLink = config.ctaLink, !ctaLink.isEmpty {
            handleExternalLink(url: ctaLink)
        } else {
            print("⚠️ [ROfferBanner] No CTA link or deeplink configured")
        }
    }
    
    /// Handle deeplink navigation
    private func handleDeeplink(url: String, action: String?) {
        print("🔗 [ROfferBanner] Handling deeplink: \(url)")
        
        #if os(iOS)
        if let deeplinkURL = URL(string: url) {
            // Check if it's a custom scheme (deeplink)
            if deeplinkURL.scheme != "http" && deeplinkURL.scheme != "https" {
                // Custom deeplink - open with app
                if UIApplication.shared.canOpenURL(deeplinkURL) {
                    UIApplication.shared.open(deeplinkURL) { success in
                        if success {
                            print("✅ [ROfferBanner] Deeplink opened successfully")
                        } else {
                            print("❌ [ROfferBanner] Failed to open deeplink")
                        }
                    }
                } else {
                    print("❌ [ROfferBanner] Cannot handle deeplink: \(url)")
                    // Fallback to external link if available
                    if let fallbackLink = config.ctaLink {
                        handleExternalLink(url: fallbackLink)
                    }
                }
            } else {
                // HTTP/HTTPS link - open in browser
                handleExternalLink(url: url)
            }
        }
        #endif
    }
    
    /// Handle external link (HTTP/HTTPS)
    private func handleExternalLink(url: String) {
        print("🌐 [ROfferBanner] Opening external link: \(url)")
        
        #if os(iOS)
        if let externalURL = URL(string: url) {
            UIApplication.shared.open(externalURL)
        }
        #endif
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
    @StateObject private var componentManager = ComponentManager.shared
    
    public init() {
        // Use the global singleton - no need to pass campaignId
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

// MARK: - Color Extension

extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
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
            overlayOpacity: 0.4,
            buttonColor: "#FF6B35"
        ))
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif

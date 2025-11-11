import SwiftUI
import ReachuCore
import ReachuDesignSystem

#if os(iOS)
import UIKit
#endif

/// Dynamic Offer Banner component that receives configuration from backend
public struct ROfferBanner: View {
    let config: OfferBannerConfig
    
    // Optional parameters to override config values
    let customDeeplink: String?
    let customHeight: CGFloat?
    let customTitleFontSize: CGFloat?
    let customSubtitleFontSize: CGFloat?
    let customBadgeFontSize: CGFloat?
    let customButtonFontSize: CGFloat?
    let onNavigateToStore: (() -> Void)? // Callback para navegar a RProductStore
    
    @State private var timeRemaining: DateComponents?
    @State private var timer: Timer?
    @State private var isImageLoaded = false
    @State private var isLogoLoaded = false
    @State private var countdownEndDate: Date? // Almacenar la fecha parseada
    @State private var timerId: UUID = UUID() // Identificador único para el timer actual
    
    @SwiftUI.Environment(\.colorScheme) private var colorScheme: SwiftUI.ColorScheme
    
    private var adaptiveColors: AdaptiveColors {
        ReachuColors.adaptive(for: colorScheme)
    }
    
    /// Initialize with full config (original method)
    public init(config: OfferBannerConfig) {
        self.config = config
        self.customDeeplink = nil
        self.customHeight = nil
        self.customTitleFontSize = nil
        self.customSubtitleFontSize = nil
        self.customBadgeFontSize = nil
        self.customButtonFontSize = nil
        self.onNavigateToStore = nil
    }
    
    /// Initialize with config and optional custom parameters
    public init(
        config: OfferBannerConfig,
        deeplink: String? = nil,
        height: CGFloat? = nil,
        titleFontSize: CGFloat? = nil,
        subtitleFontSize: CGFloat? = nil,
        badgeFontSize: CGFloat? = nil,
        buttonFontSize: CGFloat? = nil,
        onNavigateToStore: (() -> Void)? = nil
    ) {
        self.config = config
        self.customDeeplink = deeplink
        self.customHeight = height
        self.customTitleFontSize = titleFontSize
        self.customSubtitleFontSize = subtitleFontSize
        self.customBadgeFontSize = badgeFontSize
        self.customButtonFontSize = buttonFontSize
        self.onNavigateToStore = onNavigateToStore
    }
    
    public var body: some View {
        ZStack {
            // Background layer - debe estar primero y ocupar todo el espacio
            backgroundLayer
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea(.all, edges: [])
            
            // Content in two columns (same layout as hardcoded banner)
            HStack(alignment: .center, spacing: 16) {
                // Left column: Logo, title, subtitle, countdown
                VStack(alignment: .leading, spacing: 4) {
                    // Logo
                    logoImageView
                    
                    // Title - siempre mostrar si hay configuración
                    Text(config.title)
                        .font(.system(size: customTitleFontSize ?? 24, weight: .bold))
                        .foregroundColor(adaptiveColors.surface)
                        .opacity(isImageLoaded ? 1.0 : 0.8)
                    
                    // Subtitle
                    if let subtitle = config.subtitle {
                        Text(subtitle)
                            .font(.system(size: customSubtitleFontSize ?? 11, weight: .regular))
                            .foregroundColor(adaptiveColors.surface.opacity(0.9))
                            .opacity(isImageLoaded ? 1.0 : 0.8)
                    }
                    
                    // Countdown (analog style like hardcoded banner)
                    if let remaining = timeRemaining {
                        analogCountdown(timeRemaining: remaining)
                            .opacity(isImageLoaded ? 1.0 : 0.8)
                    }
                }
                
                Spacer()
                
                // Right column: Discount badge + Button (centered vertically)
                VStack(spacing: 8) {
                    // Discount badge
                    Text(config.discountBadgeText)
                        .font(.system(size: customBadgeFontSize ?? 18, weight: .bold))
                        .foregroundColor(adaptiveColors.surface)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(adaptiveColors.textPrimary.opacity(0.8))
                        )
                        .opacity(isImageLoaded ? 1.0 : 0.8)
                    
                    // Button
                    Button(action: {
                        handleCTAAction()
                    }) {
                        HStack(spacing: 6) {
                            Text(config.ctaText)
                                .font(.system(size: customButtonFontSize ?? 12, weight: .semibold))
                                .foregroundColor(adaptiveColors.surface)
                            
                            Image(systemName: "arrow.right")
                                .font(.system(size: (customButtonFontSize ?? 12) - 1, weight: .semibold))
                                .foregroundColor(adaptiveColors.surface)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(buttonColor)
                        )
                    }
                    .opacity(isImageLoaded ? 1.0 : 0.8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .frame(height: customHeight ?? 160)
        .cornerRadius(ReachuBorderRadius.large)
        .reachuCardShadow(for: colorScheme)
        .onAppear {
            // Inicializar isImageLoaded basado en si hay imagen o color de fondo
            if config.backgroundImageUrl != nil && !config.backgroundImageUrl!.isEmpty {
                // Si hay imagen, esperar a que cargue (se actualizará cuando la imagen cargue)
                // Por ahora establecerlo después de un pequeño delay para permitir que la imagen empiece a cargar
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isImageLoaded = true
                }
            } else {
                // Si solo hay color de fondo, mostrar contenido inmediatamente
                isImageLoaded = true
            }
            startCountdown()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UpdateCountdown"))) { notification in
            // Solo actualizar si el timer ID coincide con el actual
            if let notificationTimerId = notification.userInfo?["timerId"] as? String,
               notificationTimerId == timerId.uuidString,
               let remaining = notification.userInfo?["remaining"] as? DateComponents {
                timeRemaining = remaining
            }
        }
        .onChange(of: config.countdownEndDate) { newDate in
            // Reiniciar countdown cuando cambia la fecha del backend
            timer?.invalidate()
            timer = nil
            timeRemaining = nil
            countdownEndDate = nil
            startCountdown()
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
            countdownEndDate = nil
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
        
        // If it's a relative path, prepend the base URL from configuration
        let baseURL = ReachuConfiguration.shared.campaignConfiguration.restAPIBaseURL
        return baseURL + path
    }
    
    // MARK: - Logo Image View
    
    private var logoImageView: some View {
        let logoFullURL = buildFullURL(from: config.logoUrl)
        return LoadedImage(
            url: URL(string: logoFullURL),
            placeholder: AnyView(
                Rectangle()
                    .fill(adaptiveColors.surfaceSecondary.opacity(0.3))
                    .frame(height: 16)
            ),
            errorView: AnyView(
                // Si falla la carga del logo, mostrar un placeholder visible
                Rectangle()
                    .fill(adaptiveColors.surfaceSecondary.opacity(0.3))
                    .frame(height: 16)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 10))
                            .foregroundColor(adaptiveColors.textSecondary.opacity(0.5))
                    )
            )
        )
        .aspectRatio(contentMode: .fit)
        .frame(height: 16)
        .onAppear {
            isLogoLoaded = true
        }
    }
    
    // MARK: - Background Layer (same as hardcoded banner)
    
    private var backgroundLayer: some View {
        Group {
            if let imageUrl = config.backgroundImageUrl, !imageUrl.isEmpty {
                // Usar imagen de fondo
                let fullURL = buildFullURL(from: imageUrl)
                backgroundImageLayer(fullURL: fullURL)
            } else {
                // Usar color de fondo sólido (sin imagen)
                Rectangle()
                    .fill(backgroundColorFromHex(config.backgroundColor) ?? adaptiveColors.surfaceSecondary.opacity(0.2))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onAppear {
                        isImageLoaded = true
                    }
            }
        }
    }
    
    @ViewBuilder
    private func backgroundImageLayer(fullURL: String) -> some View {
        ZStack {
            // Intentar cargar la imagen
            LoadedImage(
                url: URL(string: fullURL),
                placeholder: AnyView(
                    // Placeholder mientras carga - usar backgroundColor si está disponible
                    Rectangle()
                        .fill(backgroundColorFromHex(config.backgroundColor) ?? adaptiveColors.surfaceSecondary.opacity(0.2))
                ),
                errorView: AnyView(
                    // Error view - cuando hay 404 u otro error, mostrar backgroundColor como fallback
                    Rectangle()
                        .fill(backgroundColorFromHex(config.backgroundColor) ?? adaptiveColors.surfaceSecondary.opacity(0.2))
                )
            )
            .aspectRatio(contentMode: .fill)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                // Marcar como cargado después de un pequeño delay para permitir que la imagen empiece a cargar
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    isImageLoaded = true
                }
            }
            
            // Dark overlay para legibilidad (solo si hay imagen cargada exitosamente)
            // El overlay se mostrará incluso si hay error, para mantener consistencia visual
            LinearGradient(
                colors: [
                    adaptiveColors.textPrimary.opacity(config.overlayOpacity ?? 0.4),
                    adaptiveColors.textPrimary.opacity((config.overlayOpacity ?? 0.4) * 0.5)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }
    
    // Helper para convertir hex string a Color
    private func backgroundColorFromHex(_ hex: String?) -> Color? {
        guard let hex = hex, !hex.isEmpty else { return nil }
        
        let hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0xFF00) >> 8) / 255.0
        let b = Double(rgb & 0xFF) / 255.0
        
        return Color(red: r, green: g, blue: b)
    }
    
    // MARK: - Analog Countdown (same style as hardcoded banner)
    
    private func analogCountdown(timeRemaining: DateComponents) -> some View {
        let days = timeRemaining.day ?? 0
        let hours = timeRemaining.hour ?? 0
        let minutes = timeRemaining.minute ?? 0
        let seconds = timeRemaining.second ?? 0
        
        return HStack(spacing: 4) {
            // Days
            if days > 0 {
                CountdownUnit(value: days, label: days == 1 ? "dag" : "dager")
            }
            
            // Hours
            if days > 0 || hours > 0 {
                CountdownUnit(value: hours, label: hours == 1 ? "time" : "timer")
            }
            
            // Minutes
            CountdownUnit(value: minutes, label: "min")
            
            // Seconds
            CountdownUnit(value: seconds, label: "sek")
        }
        .padding(.vertical, 3)
    }
    
    private func startCountdown() {
        // Invalidar timer anterior si existe
        timer?.invalidate()
        timer = nil
        
        // Generar un nuevo ID para este timer
        let currentTimerId = UUID()
        timerId = currentTimerId
        
        // Parsear la fecha una sola vez y almacenarla
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let endDate = formatter.date(from: config.countdownEndDate) else {
            timeRemaining = nil
            countdownEndDate = nil
            return
        }
        
        // Almacenar la fecha parseada
        countdownEndDate = endDate
        
        // Calcular tiempo inicial
        let now = Date()
        if now >= endDate {
            timeRemaining = nil
            return
        }
        
        // Calcular tiempo restante inicial
        timeRemaining = Calendar.current.dateComponents(
            [.day, .hour, .minute, .second],
            from: now,
            to: endDate
        )
        
        // Crear un timer que use la fecha almacenada
        // Capturar la fecha y el ID del timer en constantes locales para el closure
        let finalEndDate = endDate
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            let now = Date()
            if now >= finalEndDate {
                timer.invalidate()
            } else {
                let remaining = Calendar.current.dateComponents(
                    [.day, .hour, .minute, .second],
                    from: now,
                    to: finalEndDate
                )
                // Actualizar timeRemaining solo si este timer sigue siendo el actual
                // Usamos NotificationCenter para comunicar el cambio de forma segura
                NotificationCenter.default.post(
                    name: NSNotification.Name("UpdateCountdown"),
                    object: nil,
                    userInfo: [
                        "remaining": remaining,
                        "timerId": currentTimerId.uuidString
                    ]
                )
            }
        }
        
        // Add timer to RunLoop to ensure it fires
        if let timer = timer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }
    
    /// Handle CTA button action with deeplink support
    private func handleCTAAction() {
        // Priority: onNavigateToStore > customDeeplink > config.deeplinkUrl > ctaLink
        if let onNavigateToStore = onNavigateToStore {
            // Navigate to store view within app
            onNavigateToStore()
        } else if let customDeeplink = customDeeplink, !customDeeplink.isEmpty {
            handleDeeplink(url: customDeeplink, action: nil)
        } else if let deeplinkUrl = config.deeplinkUrl, !deeplinkUrl.isEmpty {
            handleDeeplink(url: deeplinkUrl, action: config.deeplinkAction)
        } else if let ctaLink = config.ctaLink, !ctaLink.isEmpty {
            handleExternalLink(url: ctaLink)
        }
    }
    
    /// Handle deeplink navigation
    private func handleDeeplink(url: String, action: String?) {
        #if os(iOS)
        if let deeplinkURL = URL(string: url) {
            // Check if it's a custom scheme (deeplink)
            if deeplinkURL.scheme != "http" && deeplinkURL.scheme != "https" {
                // Custom deeplink - open with app
                if UIApplication.shared.canOpenURL(deeplinkURL) {
                    UIApplication.shared.open(deeplinkURL)
                } else {
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
    
    @SwiftUI.Environment(\.colorScheme) private var colorScheme: SwiftUI.ColorScheme
    
    private var adaptiveColors: AdaptiveColors {
        ReachuColors.adaptive(for: colorScheme)
    }
    
    var body: some View {
        VStack(spacing: 2) {
            Text(String(format: "%02d", value))
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(adaptiveColors.surface)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(adaptiveColors.surface.opacity(0.7))
        }
        .frame(width: 40, height: 50)
        .background(
            RoundedRectangle(cornerRadius: ReachuBorderRadius.small)
                .stroke(adaptiveColors.surface.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Dynamic Banner Container
/// Dynamic Offer Banner component that automatically loads configuration from backend
/// This component connects to ComponentManager and displays the active banner
/// It handles loading states, errors, and real-time updates via WebSocket
public struct ROfferBannerDynamic: View {
    @StateObject private var componentManager = ComponentManager.shared
    @State private var isLoading = true
    @State private var hasError = false
    @State private var errorMessage: String?
    
    // Optional callback for navigation to store
    let onNavigateToStore: (() -> Void)?
    
    @SwiftUI.Environment(\.colorScheme) private var colorScheme: SwiftUI.ColorScheme
    
    private var adaptiveColors: AdaptiveColors {
        ReachuColors.adaptive(for: colorScheme)
    }
    
    public init(onNavigateToStore: (() -> Void)? = nil) {
        self.onNavigateToStore = onNavigateToStore
    }
    
    public var body: some View {
        Group {
            if let bannerConfig = componentManager.activeBanner {
                // Banner is available - show it with smooth transition
                // Usar .id() para forzar recreación cuando cambia countdownEndDate
                ROfferBanner(
                    config: bannerConfig,
                    onNavigateToStore: onNavigateToStore
                )
                    .id(bannerConfig.countdownEndDate) // Forzar recreación cuando cambia la fecha
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .animation(.easeInOut(duration: 0.3), value: componentManager.activeBanner?.title)
            } else if isLoading && !hasError {
                // Loading state - show skeleton
                loadingSkeleton
            } else if hasError {
                // Error state - show error message (optional, can be hidden)
                errorView
            }
            // If no banner and not loading, show nothing (banner is hidden)
        }
        .onAppear {
            Task {
                await connectToBackend()
            }
        }
        .onDisappear {
            // Note: We don't disconnect here to allow WebSocket to keep receiving updates
            // ComponentManager manages its own lifecycle
        }
        .onChange(of: componentManager.activeBanner) { newBanner in
            // Reset loading state when banner changes
            if newBanner != nil {
                isLoading = false
                hasError = false
            } else if !isLoading {
                // Banner was removed
                isLoading = false
            }
        }
    }
    
    // MARK: - Loading Skeleton
    
    private var loadingSkeleton: some View {
        ZStack {
            // Background skeleton
            Rectangle()
                .fill(adaptiveColors.surfaceSecondary.opacity(0.2))
                .cornerRadius(ReachuBorderRadius.large)
            
            // Content skeleton
            HStack(alignment: .center, spacing: 16) {
                // Left column skeleton
                VStack(alignment: .leading, spacing: 4) {
                    // Logo skeleton
                    Rectangle()
                        .fill(adaptiveColors.surfaceSecondary.opacity(0.3))
                        .frame(width: 100, height: 16)
                        .cornerRadius(ReachuBorderRadius.small)
                    
                    // Title skeleton
                    Rectangle()
                        .fill(adaptiveColors.surfaceSecondary.opacity(0.3))
                        .frame(height: 24)
                        .frame(maxWidth: 150)
                        .cornerRadius(ReachuBorderRadius.small)
                    
                    // Subtitle skeleton
                    Rectangle()
                        .fill(adaptiveColors.surfaceSecondary.opacity(0.2))
                        .frame(height: 11)
                        .frame(maxWidth: 120)
                        .cornerRadius(ReachuBorderRadius.small / 2)
                    
                    // Countdown skeleton
                    HStack(spacing: 4) {
                        ForEach(0..<4) { _ in
                            Rectangle()
                                .fill(adaptiveColors.surfaceSecondary.opacity(0.3))
                                .frame(width: 30, height: 20)
                                .cornerRadius(ReachuBorderRadius.small)
                        }
                    }
                    .padding(.vertical, 3)
                }
                
                Spacer()
                
                // Right column skeleton
                VStack(spacing: 8) {
                    // Badge skeleton
                    Rectangle()
                        .fill(adaptiveColors.surfaceSecondary.opacity(0.4))
                        .frame(width: 80, height: 32)
                        .cornerRadius(ReachuBorderRadius.circle)
                    
                    // Button skeleton
                    Rectangle()
                        .fill(adaptiveColors.surfaceSecondary.opacity(0.4))
                        .frame(width: 100, height: 28)
                        .cornerRadius(ReachuBorderRadius.circle)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .frame(height: 160)
        .cornerRadius(ReachuBorderRadius.large)
        .shimmerEffect()
    }
    
    // MARK: - Error View
    
    private var errorView: some View {
        Group {
            // Optionally show error - for now, just hide the banner
            // Uncomment below if you want to show error state
            /*
            VStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 24))
                    .foregroundColor(adaptiveColors.error)
                
                Text("Failed to load banner")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(adaptiveColors.textPrimary)
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 12))
                        .foregroundColor(adaptiveColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding()
            .frame(height: 160)
            .frame(maxWidth: .infinity)
            .background(adaptiveColors.surfaceSecondary.opacity(0.1))
            .cornerRadius(ReachuBorderRadius.large)
            */
        }
    }
    
    // MARK: - Connection Logic
    
    private func connectToBackend() async {
        isLoading = true
        hasError = false
        errorMessage = nil
        
        do {
            await componentManager.connect()
            
            // Wait a bit for initial load
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            // Check if we got a banner or if connection is established
            if componentManager.activeBanner == nil && componentManager.isConnected {
                // Connected but no active banner - this is normal, not an error
                isLoading = false
            } else if componentManager.activeBanner != nil {
                // Got a banner!
                isLoading = false
            } else {
                // Still loading or connection failed
                isLoading = false
                // Don't set error - might just be no active banner
            }
        } catch {
            hasError = true
            errorMessage = error.localizedDescription
            isLoading = false
            ReachuLogger.error("Failed to connect to banner backend: \(error)", component: "ROfferBannerDynamic")
        }
    }
}

// MARK: - Shimmer Effect Extension (private to avoid conflicts)

private extension View {
    func shimmerEffect() -> some View {
        self.modifier(ShimmerModifier())
    }
}

private struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        Color.clear,
                        Color.white.opacity(0.1),
                        Color.clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase * 200 - 100)
                .animation(
                    .linear(duration: 1.5)
                    .repeatForever(autoreverses: false),
                    value: phase
                )
            )
            .onAppear {
                phase = 1
            }
    }
}

/// Container view that manages the offer banner lifecycle (legacy name - use ROfferBannerDynamic)
@available(*, deprecated, renamed: "ROfferBannerDynamic", message: "Use ROfferBannerDynamic instead")
public struct ROfferBannerContainer: View {
    public var body: some View {
        ROfferBannerDynamic()
    }
}

/// Countdown Unit Component (same style as hardcoded banner)
struct CountdownUnit: View {
    let value: Int
    let label: String
    
    @SwiftUI.Environment(\.colorScheme) private var colorScheme: SwiftUI.ColorScheme
    
    private var adaptiveColors: AdaptiveColors {
        ReachuColors.adaptive(for: colorScheme)
    }
    
    var body: some View {
        VStack(spacing: 1) {
            // Digits
            Text(String(format: "%02d", value))
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(adaptiveColors.surface)
                .frame(minWidth: 24)
                .padding(.vertical, 2)
                .padding(.horizontal, 5)
                .background(
                    RoundedRectangle(cornerRadius: ReachuBorderRadius.small)
                        .fill(adaptiveColors.surface.opacity(0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: ReachuBorderRadius.small)
                                .stroke(adaptiveColors.surface.opacity(0.3), lineWidth: 1)
                        )
                )
            
            // Label
            Text(label)
                .font(.system(size: 7, weight: .medium))
                .foregroundColor(adaptiveColors.surface.opacity(0.85))
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
            backgroundColor: nil,
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

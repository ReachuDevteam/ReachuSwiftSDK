import SwiftUI
import ReachuCore
import ReachuDesignSystem

/// Auto-configured Product Banner component
/// Automatically loads configuration from active campaign
/// Usage: Just drag RProductBanner() into your view - no parameters needed!
public struct RProductBanner: View {
    
    // MARK: - Properties
    
    @ObservedObject private var campaignManager = CampaignManager.shared
    
    @SwiftUI.Environment(\.colorScheme) private var colorScheme: SwiftUI.ColorScheme
    
    // MARK: - Initializer
    
    public init() {
        // No parameters needed - component auto-configures from campaign
    }
    
    // MARK: - Computed Properties
    
    private var adaptiveColors: AdaptiveColors {
        ReachuColors.adaptive(for: colorScheme)
    }
    
    /// Get active product banner component from campaign
    private var activeComponent: Component? {
        campaignManager.getActiveComponent(type: "product_banner")
    }
    
    /// Extract ProductBannerConfig from component
    private var config: ProductBannerConfig? {
        guard let component = activeComponent else {
            print("⚠️ [RProductBanner] No active component found")
            print("   Active components: \(campaignManager.activeComponents.map { "\($0.type)-\($0.id)" })")
            return nil
        }
        
        guard case .productBanner(let config) = component.config else {
            print("⚠️ [RProductBanner] Component config is not ProductBanner")
            print("   Component type: \(component.type)")
            print("   Component ID: \(component.id)")
            return nil
        }
        
        // Log config data for debugging - THIS IS THE DATA FROM BACKEND
        print("📋 [RProductBanner] Config loaded from backend:")
        print("   - productId: \(config.productId)")
        print("   - backgroundImageUrl: \(config.backgroundImageUrl)")
        print("   - title: '\(config.title)'")
        print("   - subtitle: '\(config.subtitle ?? "nil")'")
        print("   - ctaText: '\(config.ctaText)'")
        print("   - ctaLink: \(config.ctaLink ?? "nil")")
        print("   - deeplink: \(config.deeplink ?? "nil")")
        
        // Log styling properties if provided
        if config.titleColor != nil || config.subtitleColor != nil || config.buttonBackgroundColor != nil || 
           config.bannerHeight != nil || config.titleFontSize != nil {
            print("   🎨 Styling properties:")
            if let titleColor = config.titleColor {
                print("      - titleColor: \(titleColor)")
            }
            if let subtitleColor = config.subtitleColor {
                print("      - subtitleColor: \(subtitleColor)")
            }
            if let buttonBg = config.buttonBackgroundColor {
                print("      - buttonBackgroundColor: \(buttonBg)")
            }
            if let buttonText = config.buttonTextColor {
                print("      - buttonTextColor: \(buttonText)")
            }
            if let overlay = config.overlayOpacity {
                print("      - overlayOpacity: \(overlay)")
            }
            if let height = config.bannerHeight {
                print("      - bannerHeight: \(height)")
            }
            if let titleSize = config.titleFontSize {
                print("      - titleFontSize: \(titleSize)")
            }
            if let subtitleSize = config.subtitleFontSize {
                print("      - subtitleFontSize: \(subtitleSize)")
            }
            if let buttonSize = config.buttonFontSize {
                print("      - buttonFontSize: \(buttonSize)")
            }
        }
        
        return config
    }
    
    /// Should show component
    private var shouldShow: Bool {
        // Check SDK availability
        guard ReachuConfiguration.shared.shouldUseSDK else {
            return false
        }
        
        // Check campaign state
        let campaignId = ReachuConfiguration.shared.liveShowConfiguration.campaignId
        guard campaignId > 0 else {
            // No campaign configured - show component (legacy behavior)
            return true
        }
        
        // Campaign must be active and not paused
        guard campaignManager.isCampaignActive,
              campaignManager.currentCampaign?.isPaused != true else {
            return false
        }
        
        // Component must exist and be active
        return activeComponent?.isActive == true && config != nil
    }
    
    // MARK: - Body
    
    public var body: some View {
        Group {
            if !shouldShow {
                EmptyView()
            } else if let config = config {
                // Show banner with config info and product image
                bannerContent(config: config)
                    .id("banner-\(config.productId)-\(config.title)") // Force update when config changes
            } else {
                Color.clear.frame(height: 1)
            }
        }
        .onChange(of: campaignManager.isCampaignActive) { _ in
            loadProductIfNeeded()
        }
        .onChange(of: campaignManager.currentCampaign?.isPaused) { _ in
            loadProductIfNeeded()
        }
        .onChange(of: activeComponent?.id) { _ in
            print("🔄 [RProductBanner] Active component ID changed")
            loadProductIfNeeded()
        }
        .onAppear {
            print("👁️ [RProductBanner] Component appeared")
            print("   Active components count: \(campaignManager.activeComponents.count)")
            print("   Component config: \(config != nil ? "Available" : "Nil")")
            loadProductIfNeeded()
        }
    }
    
    // MARK: - Content Views
    
    private func bannerContent(config: ProductBannerConfig) -> some View {
        // Build full URL from config (handles both relative and absolute URLs)
        let fullImageURL = buildFullURL(from: config.backgroundImageUrl)
        let imageURL = URL(string: fullImageURL)
        
        // Get styling values with defaults
        let bannerHeight = CGFloat(getClampedSize(config.bannerHeight, min: 150, max: 400, default: 200))
        let titleFontSize = CGFloat(getClampedSize(config.titleFontSize, min: 16, max: 32, default: 24))
        let subtitleFontSize = CGFloat(getClampedSize(config.subtitleFontSize, min: 12, max: 20, default: 16))
        let buttonFontSize = CGFloat(getClampedSize(config.buttonFontSize, min: 12, max: 18, default: 14))
        
        // Get colors with defaults
        let titleColor = getColor(from: config.titleColor, defaultColor: .white)
        let subtitleColor = getColor(from: config.subtitleColor, defaultColor: .white.opacity(0.95))
        let buttonBackgroundColor = getColor(from: config.buttonBackgroundColor, defaultColor: adaptiveColors.primary)
        let buttonTextColor = getColor(from: config.buttonTextColor, defaultColor: .white)
        
        // Get overlay opacity with default
        let overlayBottomOpacity = config.overlayOpacity ?? 0.5
        let overlayTopOpacity = (config.overlayOpacity ?? 0.5) * 0.6 // Top is 60% of bottom
        
        return ZStack {
            // Background image from config - THIS IS THE MAIN IMAGE TO SHOW
            AsyncImage(url: imageURL ?? URL(string: "about:blank")) { phase in
                switch phase {
                case .empty:
                    // Loading state - show placeholder
                    Rectangle()
                        .fill(adaptiveColors.surfaceSecondary)
                        .overlay {
                            ProgressView()
                                .tint(.white)
                        }
                        .onAppear {
                            print("⏳ [RProductBanner] Loading background image: \(fullImageURL)")
                            print("   Original path: \(config.backgroundImageUrl)")
                            print("   Full URL: \(fullImageURL)")
                        }
                case .success(let image):
                    // Success - show image
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .onAppear {
                            print("✅ [RProductBanner] Background image loaded successfully from: \(fullImageURL)")
                        }
                case .failure(let error):
                    // Error - show placeholder with error
                    Rectangle()
                        .fill(adaptiveColors.surfaceSecondary)
                        .overlay {
                            VStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundColor(.white)
                                    .font(.system(size: 24))
                                Text("Failed to load image")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        .onAppear {
                            print("❌ [RProductBanner] Failed to load background image: \(error.localizedDescription)")
                            print("   Original path: \(config.backgroundImageUrl)")
                            print("   Full URL: \(fullImageURL)")
                            if let urlError = error as? URLError {
                                print("   URL Error Code: \(urlError.code.rawValue)")
                                print("   URL Error Description: \(urlError.localizedDescription)")
                            }
                        }
                @unknown default:
                    Rectangle()
                        .fill(adaptiveColors.surfaceSecondary)
                }
            }
            .frame(height: bannerHeight)
            .clipped()
            
            // Overlay gradient for text readability (configurable opacity)
            LinearGradient(
                colors: [
                    Color.black.opacity(overlayBottomOpacity),
                    Color.black.opacity(overlayTopOpacity)
                ],
                startPoint: .bottom,
                endPoint: .top
            )
            
            // Content overlay: text from config with configurable styling
            VStack(alignment: .leading, spacing: ReachuSpacing.md) {
                // Title from config - configurable size and color
                Text(config.title)
                    .font(.system(size: titleFontSize, weight: .bold))
                    .foregroundColor(titleColor)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                
                // Subtitle from config - configurable size and color
                if let subtitle = config.subtitle {
                    Text(subtitle)
                        .font(.system(size: subtitleFontSize))
                        .foregroundColor(subtitleColor)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                }
                
                Spacer()
                
                // CTA Button with configurable styling
                Button {
                    navigateToProduct(config: config)
                } label: {
                    Text(config.ctaText)
                        .font(.system(size: buttonFontSize, weight: .semibold))
                        .foregroundColor(buttonTextColor)
                        .padding(.horizontal, ReachuSpacing.lg)
                        .padding(.vertical, ReachuSpacing.sm)
                        .background(buttonBackgroundColor)
                        .cornerRadius(ReachuBorderRadius.medium)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(ReachuSpacing.lg)
        }
        .frame(height: bannerHeight)
        .cornerRadius(ReachuBorderRadius.large)
        .padding(.horizontal, ReachuSpacing.lg)
        .onTapGesture {
            // Tap anywhere on banner to navigate to product
            navigateToProduct(config: config)
        }
    }
    
    // MARK: - Helper Methods
    
    /// Parse hex color string to SwiftUI Color
    /// Supports formats: #RRGGBB, #RRGGBBAA, RRGGBB
    private func parseColor(from hexString: String?) -> Color? {
        guard let hexString = hexString, !hexString.isEmpty else { return nil }
        
        var hex = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove # if present
        if hex.hasPrefix("#") {
            hex.removeFirst()
        }
        
        // Validate length
        guard hex.count == 6 || hex.count == 8 else {
            print("⚠️ [RProductBanner] Invalid hex color format: \(hexString)")
            return nil
        }
        
        // Parse RGB components
        var rgb: UInt64 = 0
        guard Scanner(string: hex).scanHexInt64(&rgb) else {
            print("⚠️ [RProductBanner] Failed to parse hex color: \(hexString)")
            return nil
        }
        
        let r: Double
        let g: Double
        let b: Double
        let a: Double
        
        if hex.count == 8 {
            // Format: RRGGBBAA
            r = Double((rgb >> 24) & 0xFF) / 255.0
            g = Double((rgb >> 16) & 0xFF) / 255.0
            b = Double((rgb >> 8) & 0xFF) / 255.0
            a = Double(rgb & 0xFF) / 255.0
        } else {
            // Format: RRGGBB (alpha = 1.0)
            r = Double((rgb >> 16) & 0xFF) / 255.0
            g = Double((rgb >> 8) & 0xFF) / 255.0
            b = Double(rgb & 0xFF) / 255.0
            a = 1.0
        }
        
        return Color(red: r, green: g, blue: b, opacity: a)
    }
    
    /// Get color with fallback to default
    private func getColor(from hexString: String?, defaultColor: Color) -> Color {
        if let color = parseColor(from: hexString) {
            return color
        }
        return defaultColor
    }
    
    /// Get clamped size value
    private func getClampedSize(_ value: Int?, min: Int, max: Int, default: Int) -> Int {
        guard let value = value else { return `default` }
        return max(min, min(max, value))
    }
    
    /// Build full URL from relative path
    private func buildFullURL(from path: String) -> String {
        // If it's already a full URL, return as is
        if path.hasPrefix("http://") || path.hasPrefix("https://") {
            return path
        }
        
        // If it's a relative path, prepend the base URL from campaign configuration
        let baseURL = ReachuConfiguration.shared.campaignConfiguration.restAPIBaseURL
        return baseURL + path
    }
    
    private func loadProductIfNeeded() {
        // No need to load product - we only use backgroundImageUrl from config
        // ProductId is only used for navigation
        guard let config = config else { return }
        print("📋 [RProductBanner] Banner ready with config:")
        print("   Background image: \(config.backgroundImageUrl)")
        print("   Title: \(config.title)")
        print("   Subtitle: \(config.subtitle ?? "nil")")
        print("   CTA: \(config.ctaText)")
    }
    
    private func navigateToProduct(config: ProductBannerConfig) {
        // Handle deeplink first
        if let deeplink = config.deeplink {
            print("🔗 [RProductBanner] Opening deeplink: \(deeplink)")
            if let url = URL(string: deeplink) {
                #if os(iOS)
                UIApplication.shared.open(url)
                #endif
            }
            return
        }
        
        // Fallback to ctaLink
        if let ctaLink = config.ctaLink {
            print("🔗 [RProductBanner] Opening link: \(ctaLink)")
            if let url = URL(string: ctaLink) {
                #if os(iOS)
                UIApplication.shared.open(url)
                #endif
            }
            return
        }
        
        // Fallback: Use productId to navigate to product detail
        print("🔗 [RProductBanner] Navigating to product detail for ID: \(config.productId)")
        // TODO: Implement product detail navigation in your app
    }
}

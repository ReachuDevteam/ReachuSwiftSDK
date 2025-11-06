import SwiftUI
import ReachuCore
import ReachuUI
import ReachuDesignSystem

#if os(iOS)
import UIKit
#endif

/// Auto-configured Product Banner component
/// Automatically loads configuration from active campaign
/// Usage: Just drag RProductBanner() into your view - no parameters needed!
public struct RProductBanner: View {
    
    // MARK: - Cached Styling Values
    
    /// Internal structure to cache parsed styling values
    /// This avoids recalculating colors, sizes, and URLs on every render
    private struct CachedStyling {
        let imageURL: URL?
        let bannerHeight: CGFloat
        let titleFontSize: CGFloat
        let subtitleFontSize: CGFloat
        let buttonFontSize: CGFloat
        let titleColor: Color
        let subtitleColor: Color
        let buttonBackgroundColor: Color
        let buttonTextColor: Color
        let backgroundColor: Color?  // Background color overlay (from rgba())
        let overlayBottomOpacity: Double
        let overlayTopOpacity: Double
        let textAlignment: SwiftUI.TextAlignment  // "left", "center", "right"
        let contentVerticalAlignment: VerticalAlignment  // "top", "center", "bottom"
        let configId: String // Used to detect config changes
        
        init(config: ProductBannerConfig, adaptiveColors: AdaptiveColors) {
            // Build full URL (cache this)
            let fullImageURL = Self.buildFullURL(from: config.backgroundImageUrl)
            self.imageURL = URL(string: fullImageURL)
            
            // Cache clamped sizes
            self.bannerHeight = CGFloat(Self.getClampedSize(config.bannerHeight, min: 150, max: 400, default: 200))
            self.titleFontSize = CGFloat(Self.getClampedSize(config.titleFontSize, min: 16, max: 32, default: 24))
            self.subtitleFontSize = CGFloat(Self.getClampedSize(config.subtitleFontSize, min: 12, max: 20, default: 16))
            self.buttonFontSize = CGFloat(Self.getClampedSize(config.buttonFontSize, min: 12, max: 18, default: 14))
            
            // Cache parsed colors - use adaptive colors as defaults
            let defaultTextColor = adaptiveColors.textPrimary
            let defaultTextColorSecondary = adaptiveColors.textSecondary
            self.titleColor = Self.getColor(from: config.titleColor, defaultColor: defaultTextColor)
            self.subtitleColor = Self.getColor(from: config.subtitleColor, defaultColor: defaultTextColorSecondary)
            self.buttonBackgroundColor = Self.getColor(from: config.buttonBackgroundColor, defaultColor: adaptiveColors.primary)
            self.buttonTextColor = Self.getColor(from: config.buttonTextColor, defaultColor: defaultTextColor)
            
            // Parse backgroundColor (can be rgba() or hex)
            if let bgColorString = config.backgroundColor {
                self.backgroundColor = Self.parseRGBA(from: bgColorString) ?? Self.parseColor(from: bgColorString)
            } else {
                self.backgroundColor = nil
            }
            
            // Cache overlay opacity (use backgroundColor opacity if available, otherwise use overlayOpacity)
            let overlayOpacity: Double
            if let bgColor = self.backgroundColor,
               let components = bgColor.cgColor?.components,
               components.count >= 4 {
                overlayOpacity = Double(components[3]) // Alpha channel
            } else {
                overlayOpacity = config.overlayOpacity ?? 0.5
            }
            self.overlayBottomOpacity = overlayOpacity
            self.overlayTopOpacity = overlayOpacity * 0.6 // Top is 60% of bottom
            
            // Parse text alignment
            switch config.textAlignment?.lowercased() {
            case "center":
                self.textAlignment = SwiftUI.TextAlignment.center
            case "right":
                self.textAlignment = SwiftUI.TextAlignment.trailing
            default:
                self.textAlignment = SwiftUI.TextAlignment.leading
            }
            
            // Parse vertical alignment
            switch config.contentVerticalAlignment?.lowercased() {
            case "top":
                self.contentVerticalAlignment = .top
            case "center":
                self.contentVerticalAlignment = .center
            default:
                self.contentVerticalAlignment = .bottom
            }
            
            // Create unique identifier for this config (detects changes)
            self.configId = "\(config.productId)-\(config.backgroundImageUrl)-\(config.title)"
        }
        
        /// Build full URL from relative path (static helper)
        private static func buildFullURL(from path: String) -> String {
            if path.hasPrefix("http://") || path.hasPrefix("https://") {
                return path
            }
            let baseURL = ReachuConfiguration.shared.campaignConfiguration.restAPIBaseURL
            return baseURL + path
        }
        
        /// Get clamped size value (static helper)
        private static func getClampedSize(_ value: Int?, min: Int, max: Int, default: Int) -> Int {
            guard let value = value else { return `default` }
            return Swift.max(min, Swift.min(max, value))
        }
        
        /// Get color with fallback (static helper)
        private static func getColor(from hexString: String?, defaultColor: Color) -> Color {
            if let color = parseColor(from: hexString) {
                return color
            }
            return defaultColor
        }
        
        /// Parse rgba() color string (e.g., "rgba(0, 0, 0, 0.5)" or "rgba(128, 128, 128, 0.8)")
        /// Handles both formats: RGB 0-255 or RGB 0-1, alpha always 0-1
        private static func parseRGBA(from rgbaString: String?) -> Color? {
            guard let rgbaString = rgbaString else { return nil }
            
            let cleaned = rgbaString.trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "rgba(", with: "")
                .replacingOccurrences(of: "rgb(", with: "")
                .replacingOccurrences(of: ")", with: "")
            
            let components = cleaned.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            
            guard components.count >= 3 else { return nil }
            
            guard let r = Double(components[0]),
                  let g = Double(components[1]),
                  let b = Double(components[2]) else {
                return nil
            }
            
            // Determine if RGB values are in 0-255 range or 0-1 range
            let isRGB255 = r > 1.0 || g > 1.0 || b > 1.0
            
            let rNormalized: Double
            let gNormalized: Double
            let bNormalized: Double
            
            if isRGB255 {
                // RGB values are in 0-255 range
                rNormalized = r / 255.0
                gNormalized = g / 255.0
                bNormalized = b / 255.0
            } else {
                // RGB values are already in 0-1 range
                rNormalized = r
                gNormalized = g
                bNormalized = b
            }
            
            let a: Double
            if components.count >= 4, let alpha = Double(components[3]) {
                a = alpha // Alpha is always 0-1
            } else {
                a = 1.0
            }
            
            return Color(red: rNormalized, green: gNormalized, blue: bNormalized, opacity: a)
        }
        
        /// Parse hex color string to SwiftUI Color (static helper)
        private static func parseColor(from hexString: String?) -> Color? {
            guard let hexString = hexString, !hexString.isEmpty else { return nil }
            
            var hex = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if hex.hasPrefix("#") {
                hex.removeFirst()
            }
            
            guard hex.count == 6 || hex.count == 8 else { return nil }
            
            var rgb: UInt64 = 0
            guard Scanner(string: hex).scanHexInt64(&rgb) else { return nil }
            
            let r: Double
            let g: Double
            let b: Double
            let a: Double
            
            if hex.count == 8 {
                r = Double((rgb >> 24) & 0xFF) / 255.0
                g = Double((rgb >> 16) & 0xFF) / 255.0
                b = Double((rgb >> 8) & 0xFF) / 255.0
                a = Double(rgb & 0xFF) / 255.0
            } else {
                r = Double((rgb >> 16) & 0xFF) / 255.0
                g = Double((rgb >> 8) & 0xFF) / 255.0
                b = Double(rgb & 0xFF) / 255.0
                a = 1.0
            }
            
            return Color(red: r, green: g, blue: b, opacity: a)
        }
    }
    
    // MARK: - Properties
    
    /// Optional component ID to identify a specific component
    /// If nil, uses the first matching component from the campaign
    private let componentId: String?
    
    @ObservedObject private var campaignManager = CampaignManager.shared
    
    @SwiftUI.Environment(\.colorScheme) private var colorScheme: SwiftUI.ColorScheme
    @EnvironmentObject private var cartManager: CartManager
    
    // Cache parsed styling values - only recalculated when config changes
    @State private var cachedStyling: CachedStyling?
    @State private var currentConfigId: String?
    
    // Product detail overlay state
    @State private var showingProductDetail: Product?
    @State private var isLoadingProduct = false
    
    // MARK: - Initializer
    
    public init(componentId: String? = nil) {
        self.componentId = componentId
    }
    
    // MARK: - Computed Properties
    
    private var adaptiveColors: AdaptiveColors {
        ReachuColors.adaptive(for: colorScheme)
    }
    
    /// Get active product banner component from campaign
    private var activeComponent: Component? {
        campaignManager.getActiveComponent(type: "product_banner", componentId: componentId)
    }
    
    /// Extract ProductBannerConfig from component
    private var config: ProductBannerConfig? {
        guard let component = activeComponent else {
            return nil
        }
        
        guard case .productBanner(let config) = component.config else {
            return nil
        }
        
        return config
    }
    
    /// Update cached styling when config changes
    private func updateCachedStylingIfNeeded() {
        guard let config = config else {
            if cachedStyling != nil {
                cachedStyling = nil
                currentConfigId = nil
            }
            return
        }
        
        let newConfigId = "\(config.productId)-\(config.backgroundImageUrl)-\(config.title)"
        
        // Only recalculate if config actually changed
        if currentConfigId != newConfigId {
            ReachuLogger.debug("Config changed - updating cached styling", component: "RProductBanner")
            ReachuLogger.debug("Old ID: \(currentConfigId ?? "nil"), New ID: \(newConfigId)", component: "RProductBanner")
            
            cachedStyling = CachedStyling(config: config, adaptiveColors: adaptiveColors)
            currentConfigId = newConfigId
            
            // Log config details (only when changed)
            ReachuLogger.debug("Config loaded - productId: \(config.productId), title: '\(config.title)'", component: "RProductBanner")
            if let bannerHeight = config.bannerHeight {
                let clampedHeight = CGFloat(Swift.max(150, Swift.min(400, bannerHeight)))
                ReachuLogger.debug("bannerHeight from backend: \(bannerHeight) -> clamped to: \(clampedHeight)", component: "RProductBanner")
            }
            if config.titleColor != nil || config.bannerHeight != nil {
                ReachuLogger.debug("Styling: Custom colors/sizes provided", component: "RProductBanner")
            }
        }
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
    
    /// Get styling, calculating if needed
    private var effectiveStyling: CachedStyling? {
        guard let config = config else { return nil }
        
        // If we have cached styling and config hasn't changed, use it
        if let cached = cachedStyling,
           let configId = currentConfigId,
           configId == "\(config.productId)-\(config.backgroundImageUrl)-\(config.title)" {
            return cached
        }
        
        // Calculate styling immediately if config is available
        return CachedStyling(config: config, adaptiveColors: adaptiveColors)
    }
    
    public var body: some View {
        Group {
            if !shouldShow {
                EmptyView()
            } else if let config = config, let styling = effectiveStyling {
                // Show banner using styling (cached or freshly calculated)
                bannerContent(config: config, styling: styling)
                    .id("banner-\(currentConfigId ?? "unknown")") // Force update when config changes
                    .onAppear {
                        // Ensure styling is cached after render
                        updateCachedStylingIfNeeded()
                    }
            } else {
                // Show skeleton loader while loading
                skeletonView
            }
        }
        .onChange(of: campaignManager.isCampaignActive) { _ in
            updateCachedStylingIfNeeded()
        }
        .onChange(of: campaignManager.currentCampaign?.isPaused) { _ in
            updateCachedStylingIfNeeded()
        }
        .onChange(of: campaignManager.activeComponents.count) { _ in
            // React immediately when components are loaded/updated
            updateCachedStylingIfNeeded()
        }
        .onChange(of: activeComponent?.id) { _ in
            updateCachedStylingIfNeeded()
        }
        .onChange(of: colorScheme) { _ in
            // Recalculate styling when color scheme changes (for adaptive colors)
            updateCachedStylingIfNeeded()
        }
        .onAppear {
            // Try to update immediately on appear (in case data is already available)
            updateCachedStylingIfNeeded()
        }
        .task {
            // Also try to update after a small delay to catch async updates
            // This ensures we catch components that load right after the view appears
            try? await Task.sleep(nanoseconds: 50_000_000) // 50ms delay
            updateCachedStylingIfNeeded()
        }
        .sheet(item: $showingProductDetail) { product in
            RProductDetailOverlay(
                product: product,
                onDismiss: {
                    showingProductDetail = nil
                }
            )
        }
    }
    
    // MARK: - Skeleton View
    
    /// Skeleton loader shown while banner is loading
    private var skeletonView: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let availableWidth = screenWidth - (ReachuSpacing.md * 2)
            let defaultHeight = Swift.max(150, Swift.min(400, availableWidth * 0.25))
            
            ZStack {
                // Background skeleton
                RoundedRectangle(cornerRadius: ReachuBorderRadius.large)
                    .fill(adaptiveColors.surfaceSecondary)
                    .frame(height: defaultHeight)
                
                // Content skeleton
                VStack(alignment: .leading, spacing: ReachuSpacing.md) {
                    // Title skeleton
                    RoundedRectangle(cornerRadius: ReachuBorderRadius.small)
                        .fill(adaptiveColors.surfaceSecondary.opacity(0.6))
                        .frame(width: 200, height: 24)
                        .shimmerEffect()
                    
                    // Subtitle skeleton
                    RoundedRectangle(cornerRadius: ReachuBorderRadius.small)
                        .fill(adaptiveColors.surfaceSecondary.opacity(0.6))
                        .frame(width: 150, height: 16)
                        .shimmerEffect()
                    
                    Spacer()
                    
                    // Button skeleton
                    RoundedRectangle(cornerRadius: ReachuBorderRadius.medium)
                        .fill(adaptiveColors.surfaceSecondary.opacity(0.6))
                        .frame(width: 120, height: 44)
                        .shimmerEffect()
                }
                .padding(ReachuSpacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, ReachuSpacing.md)
            .frame(height: defaultHeight)
        }
    }
    
    // MARK: - Content Views
    
    /// Banner content using cached styling values (optimized for performance)
    /// All colors, sizes, and URLs are pre-calculated and cached
    /// Uses GeometryReader for responsive sizing based on screen width
    private func bannerContent(config: ProductBannerConfig, styling: CachedStyling) -> some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let availableWidth = screenWidth - (ReachuSpacing.md * 2) // Subtract horizontal padding
            let bannerHeight: CGFloat = {
                // Use ratio-based height if available (better for responsive design)
                // Ratio is based on screen width (e.g., 0.25 = 25% of width)
                if let heightRatio = config.bannerHeightRatio {
                    // Clamp ratio between 0.15 (15%) and 0.6 (60%)
                    let clampedRatio = Swift.max(0.15, Swift.min(0.6, heightRatio))
                    return availableWidth * clampedRatio
                } else if let absoluteHeight = config.bannerHeight {
                    // Fallback to absolute height (in points, already clamped)
                    return CGFloat(Swift.max(150, Swift.min(400, absoluteHeight)))
                } else {
                    // Default: 25% of screen width with min/max constraints
                    let defaultRatio: CGFloat = 0.25
                    let calculatedHeight = availableWidth * defaultRatio
                    return Swift.max(150, Swift.min(400, calculatedHeight))
                }
            }()
            
            ZStack {
                // Background image from config - using cached URL
            AsyncImage(url: styling.imageURL ?? URL(string: "about:blank")) { phase in
                switch phase {
                case .empty:
                    // Loading state - show placeholder
                    Rectangle()
                        .fill(adaptiveColors.surfaceSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: bannerHeight)
                        .overlay {
                            ProgressView()
                                .tint(adaptiveColors.textPrimary)
                        }
                        .onAppear {
                            if let url = styling.imageURL?.absoluteString {
                                ReachuLogger.debug("Loading background image: \(url)", component: "RProductBanner")
                            }
                        }
                case .success(let image):
                    // Success - show image
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity)
                        .frame(height: bannerHeight)
                        .clipped()
                case .failure(let error):
                    // Error - show placeholder with error
                    Rectangle()
                        .fill(adaptiveColors.surfaceSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: bannerHeight)
                        .overlay {
                            VStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundColor(adaptiveColors.textPrimary)
                                    .font(.system(size: 24))
                                Text("Failed to load image")
                                    .font(.caption)
                                    .foregroundColor(adaptiveColors.textSecondary)
                            }
                        }
                        .onAppear {
                            ReachuLogger.error("Failed to load background image: \(error.localizedDescription)", component: "RProductBanner")
                        }
                @unknown default:
                    Rectangle()
                        .fill(adaptiveColors.surfaceSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: bannerHeight)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: bannerHeight)
            .clipped()
            
            // Background color overlay (if provided)
            if let backgroundColor = styling.backgroundColor {
                backgroundColor
                    .frame(maxWidth: .infinity)
                    .frame(height: bannerHeight)
            }
            
            // Overlay gradient for text readability (using cached opacity values)
            // Only show if backgroundColor is not provided (fallback to gradient)
            if styling.backgroundColor == nil {
                LinearGradient(
                    colors: [
                        adaptiveColors.textPrimary.opacity(styling.overlayBottomOpacity),
                        adaptiveColors.textPrimary.opacity(styling.overlayTopOpacity)
                    ],
                    startPoint: .bottom,
                    endPoint: .top
                )
                .frame(maxWidth: .infinity)
                .frame(height: bannerHeight)
            }
            
            // Content overlay: text from config with cached styling values
            // Determine VStack alignment based on text alignment
            let vStackAlignment: HorizontalAlignment = {
                switch styling.textAlignment {
                case .center:
                    return .center
                case .trailing:
                    return .trailing
                default:
                    return .leading
                }
            }()
            
            VStack(alignment: vStackAlignment, spacing: ReachuSpacing.md) {
                // Title from config - using cached size and color
                Text(config.title)
                    .font(.system(size: styling.titleFontSize, weight: .bold))
                    .foregroundColor(styling.titleColor)
                    .multilineTextAlignment(styling.textAlignment)
                    .fixedSize(horizontal: false, vertical: true)
                    .reachuTextShadow(for: colorScheme)
                
                // Subtitle from config - using cached size and color
                    if let subtitle = config.subtitle {
                        Text(subtitle)
                            .font(.system(size: styling.subtitleFontSize))
                            .foregroundColor(styling.subtitleColor)
                            .multilineTextAlignment(styling.textAlignment)
                            .fixedSize(horizontal: false, vertical: true)
                            .reachuTextShadow(for: colorScheme)
                    }
                
                if styling.contentVerticalAlignment == .center || styling.contentVerticalAlignment == .bottom {
                    Spacer()
                }
                
                // CTA Button with cached styling values
                Button {
                    loadAndShowProduct(config: config)
                } label: {
                    Text(config.ctaText)
                        .font(.system(size: styling.buttonFontSize, weight: .semibold))
                        .foregroundColor(styling.buttonTextColor)
                        .padding(.horizontal, ReachuSpacing.md)
                        .padding(.vertical, ReachuSpacing.sm)
                        .background(styling.buttonBackgroundColor)
                        .cornerRadius(ReachuBorderRadius.medium)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                if styling.contentVerticalAlignment == .center || styling.contentVerticalAlignment == .top {
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: Alignment(horizontal: vStackAlignment, vertical: styling.contentVerticalAlignment))
            .padding(ReachuSpacing.md)
            }
            .frame(height: bannerHeight)
            .frame(maxWidth: .infinity)
            .clipped()
            .cornerRadius(ReachuBorderRadius.large)
            .padding(.horizontal, ReachuSpacing.md)
            .onTapGesture {
                // Tap anywhere on banner to show product detail
                loadAndShowProduct(config: config)
            }
        }
        .frame(height: {
            // Calculate banner height for proper layout
            // Use a reasonable default - actual height will be calculated by GeometryReader
            let defaultRatio: CGFloat = 0.25
            return 200 // Default height, will be adjusted by GeometryReader
        }())
    }
    
    // MARK: - Helper Methods
    
    private func loadAndShowProduct(config: ProductBannerConfig) {
        // Handle deeplink first
        if let deeplink = config.deeplink {
            ReachuLogger.debug("Opening deeplink: \(deeplink)", component: "RProductBanner")
            if let url = URL(string: deeplink) {
                #if os(iOS)
                UIApplication.shared.open(url)
                #endif
            }
            return
        }
        
        // Fallback to ctaLink
        if let ctaLink = config.ctaLink {
            ReachuLogger.debug("Opening link: \(ctaLink)", component: "RProductBanner")
            if let url = URL(string: ctaLink) {
                #if os(iOS)
                UIApplication.shared.open(url)
                #endif
            }
            return
        }
        
        // Load product by ID and show detail overlay
        Task {
            await loadProduct(productId: config.productId)
        }
    }
    
    /// Load product by ID and show in detail overlay
    @MainActor
    private func loadProduct(productId: String) async {
        guard !isLoadingProduct else { return }
        
        isLoadingProduct = true
        
        // Get currency and country from CartManager
        let currency = cartManager.currency
        let country = cartManager.country
        
        do {
            // Use ProductService to load product with large images for detail view
            let product = try await ProductService.shared.loadProduct(
                productId: productId,
                currency: currency,
                country: country,
                imageSize: "large"
            )
            
            showingProductDetail = product
            
        } catch ProductServiceError.invalidProductId(let id) {
            ReachuLogger.warning("Invalid productId: \(id)", component: "RProductBanner")
        } catch ProductServiceError.productNotFound(let id) {
            ReachuLogger.warning("Product not found for ID: \(id)", component: "RProductBanner")
        } catch ProductServiceError.invalidConfiguration(let message) {
            ReachuLogger.error("Invalid configuration: \(message)", component: "RProductBanner")
        } catch {
            ReachuLogger.error("Error loading product: \(error.localizedDescription)", component: "RProductBanner")
        }
        
        isLoadingProduct = false
    }
}

// MARK: - Shimmer Effect Extension

private extension View {
    func shimmerEffect() -> some View {
        modifier(ShimmerEffectModifier())
    }
}

private struct ShimmerEffectModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    // Get adaptive colors for shimmer effect
                    let shimmerColor = ReachuColors.adaptive(for: .light).textPrimary.opacity(0.5)
                    LinearGradient(
                        colors: [
                            Color.clear,
                            shimmerColor,
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 0.6)
                    .offset(x: (phase - 0.5) * geometry.size.width * 1.5)
                    .blendMode(.overlay)
                }
            )
            .onAppear {
                phase = 0
                withAnimation(
                    Animation.linear(duration: 1.5)
                        .repeatForever(autoreverses: false)
                ) {
                    phase = 1.0
                }
            }
    }
}

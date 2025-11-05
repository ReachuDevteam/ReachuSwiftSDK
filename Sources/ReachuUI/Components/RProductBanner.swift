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
        // Validate URL before using it
        let imageURL = URL(string: config.backgroundImageUrl)
        
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
                            if let url = imageURL {
                                print("⏳ [RProductBanner] Loading background image: \(url.absoluteString)")
                            } else {
                                print("❌ [RProductBanner] Invalid backgroundImageUrl: '\(config.backgroundImageUrl)'")
                            }
                        }
                case .success(let image):
                    // Success - show image
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .onAppear {
                            print("✅ [RProductBanner] Background image loaded successfully from: \(config.backgroundImageUrl)")
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
                            print("   URL: \(config.backgroundImageUrl)")
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
            .frame(height: 280)
            .clipped()
            
            // Overlay gradient for text readability
            LinearGradient(
                colors: [
                    Color.black.opacity(0.5),
                    Color.black.opacity(0.3)
                ],
                startPoint: .bottom,
                endPoint: .top
            )
            
            // Content overlay: text from config
            VStack(alignment: .leading, spacing: ReachuSpacing.md) {
                // Title from config - larger and bold
                Text(config.title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                
                // Subtitle from config - larger font
                if let subtitle = config.subtitle {
                    Text(subtitle)
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.95))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                }
                
                Spacer()
                
                // CTA Button with text from config - larger and more prominent
                Button {
                    navigateToProduct(config: config)
                } label: {
                    Text(config.ctaText)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, ReachuSpacing.xl)
                        .padding(.vertical, ReachuSpacing.md)
                        .background(adaptiveColors.primary)
                        .cornerRadius(ReachuBorderRadius.large)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(ReachuSpacing.xl)
        }
        .frame(height: 280)
        .cornerRadius(ReachuBorderRadius.large)
        .padding(.horizontal, ReachuSpacing.lg)
        .onTapGesture {
            // Tap anywhere on banner to navigate to product
            navigateToProduct(config: config)
        }
    }
    
    // MARK: - Helper Methods
    
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

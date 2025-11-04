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
        guard let component = activeComponent,
              case .productBanner(let config) = component.config else {
            return nil
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
                // Show banner with config info, productId is only used for navigation
                bannerContent(config: config)
            } else {
                Color.clear.frame(height: 1)
            }
        }
        .onChange(of: campaignManager.isCampaignActive) { _ in
            // React to campaign state changes
        }
        .onChange(of: campaignManager.currentCampaign?.isPaused) { _ in
            // React to campaign pause/resume
        }
        .onChange(of: activeComponent?.id) { _ in
            // React to component changes
        }
    }
    
    // MARK: - Content Views
    
    private func bannerContent(config: ProductBannerConfig) -> some View {
        ZStack {
            // Background image
            AsyncImage(url: URL(string: config.backgroundImageUrl)) { phase in
                switch phase {
                case .empty:
                    Rectangle()
                        .fill(adaptiveColors.surfaceSecondary)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    Rectangle()
                        .fill(adaptiveColors.surfaceSecondary)
                @unknown default:
                    Rectangle()
                        .fill(adaptiveColors.surfaceSecondary)
                }
            }
            .frame(height: 200)
            .clipped()
            
            // Overlay gradient
            LinearGradient(
                colors: [
                    Color.black.opacity(0.6),
                    Color.black.opacity(0.3)
                ],
                startPoint: .bottom,
                endPoint: .top
            )
            
            // Content
            VStack(alignment: .leading, spacing: ReachuSpacing.md) {
                // Title
                Text(config.title)
                    .font(ReachuTypography.headline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                
                // Subtitle
                if let subtitle = config.subtitle {
                    Text(subtitle)
                        .font(ReachuTypography.body)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // CTA Button
                Button {
                    navigateToProduct(config: config)
                } label: {
                    Text(config.ctaText)
                        .font(ReachuTypography.bodyBold)
                        .foregroundColor(.white)
                        .padding(.horizontal, ReachuSpacing.lg)
                        .padding(.vertical, ReachuSpacing.md)
                        .background(adaptiveColors.primary)
                        .cornerRadius(ReachuBorderRadius.medium)
                }
            }
            .padding(ReachuSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 200)
        .cornerRadius(ReachuBorderRadius.large)
        .padding(.horizontal, ReachuSpacing.lg)
        .onTapGesture {
            // Tap anywhere on banner to navigate to product
            navigateToProduct(config: config)
        }
    }
    
    // MARK: - Helper Methods
    
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
        // This would typically open a product detail view in your app
        print("🔗 [RProductBanner] Navigating to product detail for ID: \(config.productId)")
        // TODO: Implement product detail navigation in your app
        // Example: openProductDetail(productId: config.productId)
    }
}

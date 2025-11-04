import SwiftUI
import ReachuCore
import ReachuDesignSystem

/// Auto-configured Product Banner component
/// Automatically loads configuration from active campaign
/// Usage: Just drag RProductBanner() into your view - no parameters needed!
public struct RProductBanner: View {
    
    // MARK: - Properties
    
    @ObservedObject private var campaignManager = CampaignManager.shared
    @StateObject private var viewModel = RProductBannerViewModel()
    
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
                // Show banner with config info and product image
                bannerContent(config: config)
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
            loadProductIfNeeded()
        }
        .onAppear {
            loadProductIfNeeded()
        }
    }
    
    // MARK: - Content Views
    
    private func bannerContent(config: ProductBannerConfig) -> some View {
        ZStack {
            // Background image from config
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
                    Color.black.opacity(0.4),
                    Color.black.opacity(0.2)
                ],
                startPoint: .bottom,
                endPoint: .top
            )
            
            // Content layout: text on left, product image on right
            HStack(spacing: ReachuSpacing.lg) {
                // Left side: Text content
                VStack(alignment: .leading, spacing: ReachuSpacing.md) {
                    // Title
                    Text(config.title)
                        .font(ReachuTypography.headline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                    
                    // Subtitle
                    if let subtitle = config.subtitle {
                        Text(subtitle)
                            .font(ReachuTypography.body)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.leading)
                            .lineLimit(3)
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
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Right side: Product image (if available)
                if let product = viewModel.product, let firstImage = product.images.first {
                    AsyncImage(url: URL(string: firstImage.url)) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .tint(.white)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: 120, maxHeight: 160)
                        case .failure:
                            Image(systemName: "photo")
                                .foregroundColor(.white.opacity(0.5))
                                .font(.system(size: 40))
                        @unknown default:
                            Image(systemName: "photo")
                                .foregroundColor(.white.opacity(0.5))
                                .font(.system(size: 40))
                        }
                    }
                } else {
                    // Placeholder when product is loading or not available
                    ProgressView()
                        .tint(.white)
                        .frame(width: 120, height: 160)
                }
            }
            .padding(ReachuSpacing.lg)
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
    
    private func loadProductIfNeeded() {
        guard let config = config, shouldShow else { return }
        
        Task {
            await viewModel.loadProduct(
                productId: config.productId,
                currency: ReachuConfiguration.shared.marketConfiguration.currencyCode,
                country: ReachuConfiguration.shared.marketConfiguration.countryCode
            )
        }
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

// MARK: - ViewModel

@MainActor
class RProductBannerViewModel: ObservableObject {
    
    @Published var product: Product?
    @Published var isLoading: Bool = false
    
    private var sdk: SdkClient {
        let config = ReachuConfiguration.shared
        let baseURL = URL(string: config.environment.graphQLURL)!
        let apiKey = config.apiKey.isEmpty ? "DEMO_KEY" : config.apiKey
        return SdkClient(baseUrl: baseURL, apiKey: apiKey)
    }
    
    func loadProduct(productId: String, currency: String, country: String) async {
        guard ReachuConfiguration.shared.shouldUseSDK else {
            return
        }
        
        guard !isLoading else { return }
        
        isLoading = true
        
        guard let intProductId = Int(productId) else {
            isLoading = false
            return
        }
        
        do {
            let dtoProducts = try await sdk.channel.product.get(
                currency: currency,
                imageSize: "large",
                barcodeList: nil,
                categoryIds: nil,
                productIds: [intProductId],
                skuList: nil,
                useCache: true,
                shippingCountryCode: country
            )
            
            product = dtoProducts.first?.toDomainProduct()
        } catch {
            // Silently fail - banner shows config info even without product
            product = nil
        }
        
        isLoading = false
    }
}


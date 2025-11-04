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
    
    private var resolvedCurrency: String {
        ReachuConfiguration.shared.marketConfiguration.currencyCode
    }
    
    private var resolvedCountry: String {
        ReachuConfiguration.shared.marketConfiguration.countryCode
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
    
    /// Product to display
    private var product: Product? {
        viewModel.product
    }
    
    /// Should show loading state
    private var shouldShowLoading: Bool {
        viewModel.isLoading && viewModel.product == nil
    }
    
    /// Should show error state
    private var shouldShowError: Bool {
        viewModel.errorMessage != nil && viewModel.product == nil && !viewModel.isMarketUnavailable
    }
    
    /// Should hide component (market unavailable)
    private var shouldHide: Bool {
        viewModel.isMarketUnavailable
    }
    
    // MARK: - Body
    
    public var body: some View {
        Group {
            if !shouldShow {
                EmptyView()
            } else if shouldHide {
                EmptyView()
            } else if shouldShowLoading {
                loadingView
            } else if shouldShowError {
                errorView
            } else if let config = config, let product = product {
                bannerContent(config: config, product: product)
            } else {
                Color.clear.frame(height: 1)
            }
        }
        .onChange(of: campaignManager.isCampaignActive) { _ in
            handleCampaignStateChange()
        }
        .onChange(of: campaignManager.currentCampaign?.isPaused) { _ in
            handleCampaignStateChange()
        }
        .onChange(of: activeComponent?.id) { _ in
            handleComponentChange()
        }
        .onAppear {
            handleComponentChange()
        }
    }
    
    // MARK: - Content Views
    
    private func bannerContent(config: ProductBannerConfig, product: Product) -> some View {
        ZStack {
            // Background image
            AsyncImage(url: URL(string: config.backgroundImageUrl)) { phase in
                switch phase {
                case .empty:
                    Rectangle()
                        .fill(adaptiveColors.backgroundSecondary)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    Rectangle()
                        .fill(adaptiveColors.backgroundSecondary)
                @unknown default:
                    Rectangle()
                        .fill(adaptiveColors.backgroundSecondary)
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
                    handleCTATap(config: config)
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
    }
    
    private var loadingView: some View {
        VStack(spacing: ReachuSpacing.md) {
            ProgressView()
                .tint(adaptiveColors.primary)
            Text("Loading banner...")
                .font(ReachuTypography.caption1)
                .foregroundColor(adaptiveColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
        .padding(.vertical, ReachuSpacing.xl)
    }
    
    private var errorView: some View {
        VStack(spacing: ReachuSpacing.sm) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 32))
                .foregroundColor(adaptiveColors.error)
            
            Text("Error loading banner")
                .font(ReachuTypography.bodyBold)
                .foregroundColor(adaptiveColors.textPrimary)
            
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(ReachuTypography.caption1)
                    .foregroundColor(adaptiveColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, ReachuSpacing.lg)
            }
            
            Button {
                loadProduct()
            } label: {
                Text("Retry")
                    .font(ReachuTypography.caption1.weight(.semibold))
                    .foregroundColor(adaptiveColors.primary)
                    .padding(.horizontal, ReachuSpacing.md)
                    .padding(.vertical, ReachuSpacing.xs)
                    .background(adaptiveColors.primary.opacity(0.1))
                    .cornerRadius(ReachuBorderRadius.medium)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
        .padding(.vertical, ReachuSpacing.xl)
    }
    
    // MARK: - Helper Methods
    
    private func handleCampaignStateChange() {
        if shouldShow {
            loadProduct()
        } else {
            viewModel.product = nil
        }
    }
    
    private func handleComponentChange() {
        if shouldShow {
            loadProduct()
        } else {
            viewModel.product = nil
        }
    }
    
    private func loadProduct() {
        guard let config = config else {
            viewModel.product = nil
            return
        }
        
        Task {
            await viewModel.loadProduct(
                productId: config.productId,
                currency: resolvedCurrency,
                country: resolvedCountry
            )
        }
    }
    
    private func handleCTATap(config: ProductBannerConfig) {
        // Handle deeplink first
        if let deeplink = config.deeplink {
            print("🔗 [RProductBanner] Opening deeplink: \(deeplink)")
            // TODO: Implement deeplink handling
            if let url = URL(string: deeplink) {
                UIApplication.shared.open(url)
            }
        }
        // Fallback to ctaLink
        else if let ctaLink = config.ctaLink {
            print("🔗 [RProductBanner] Opening link: \(ctaLink)")
            if let url = URL(string: ctaLink) {
                UIApplication.shared.open(url)
            }
        }
    }
}

// MARK: - ViewModel

@MainActor
class RProductBannerViewModel: ObservableObject {
    
    @Published var product: Product?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isMarketUnavailable: Bool = false
    
    private var sdk: SdkClient {
        let config = ReachuConfiguration.shared
        let baseURL = URL(string: config.environment.graphQLURL)!
        let apiKey = config.apiKey.isEmpty ? "DEMO_KEY" : config.apiKey
        return SdkClient(baseUrl: baseURL, apiKey: apiKey)
    }
    
    func loadProduct(productId: String, currency: String, country: String) async {
        guard ReachuConfiguration.shared.shouldUseSDK else {
            isMarketUnavailable = true
            isLoading = false
            return
        }
        
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        isMarketUnavailable = false
        
        print("🛍️ [RProductBanner] Loading product with ID: \(productId)")
        
        guard let intProductId = Int(productId) else {
            errorMessage = "Invalid product ID"
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
            print("✅ [RProductBanner] Loaded product: \(product?.name ?? "unknown")")
            
        } catch let error as NotFoundException {
            isMarketUnavailable = true
            errorMessage = nil
            print("⚠️ [RProductBanner] Market not available")
        } catch let error as SdkException {
            if error.code == "NOT_FOUND" || error.status == 404 {
                isMarketUnavailable = true
                errorMessage = nil
            } else {
                errorMessage = error.description
                print("❌ [RProductBanner] Failed to load product: \(error.description)")
            }
        } catch {
            errorMessage = error.localizedDescription
            print("❌ [RProductBanner] Failed to load product: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
}


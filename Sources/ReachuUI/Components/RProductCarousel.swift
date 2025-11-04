import SwiftUI
import ReachuCore
import ReachuDesignSystem

/// Auto-configured Product Carousel component
/// Automatically loads configuration from active campaign
/// Usage: Just drag RProductCarousel() into your view - no parameters needed!
public struct RProductCarousel: View {
    
    // MARK: - Properties
    
    @ObservedObject private var campaignManager = CampaignManager.shared
    @StateObject private var viewModel = RProductCarouselViewModel()
    @State private var currentIndex: Int = 0
    @State private var autoScrollTimer: Timer?
    
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
    
    /// Get active product carousel component from campaign
    private var activeComponent: Component? {
        campaignManager.getActiveComponent(type: "product_carousel")
    }
    
    /// Extract ProductCarouselConfig from component
    private var config: ProductCarouselConfig? {
        guard let component = activeComponent,
              case .productCarousel(let config) = component.config else {
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
    
    /// Products to display
    private var products: [Product] {
        viewModel.products
    }
    
    /// Should show loading state
    private var shouldShowLoading: Bool {
        viewModel.isLoading && viewModel.products.isEmpty
    }
    
    /// Should show error state
    private var shouldShowError: Bool {
        viewModel.errorMessage != nil && viewModel.products.isEmpty && !viewModel.isMarketUnavailable
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
            } else if !products.isEmpty {
                carouselContent
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
        .onDisappear {
            stopAutoScroll()
        }
    }
    
    // MARK: - Content Views
    
    private var carouselContent: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: ReachuSpacing.md) {
                    ForEach(Array(products.enumerated()), id: \.element.id) { index, product in
                        productCardView(product: product)
                            .frame(width: 280) // Fixed width for cards
                            .id(index)
                    }
                }
                .padding(.horizontal, ReachuSpacing.lg)
            }
            .onAppear {
                startAutoScroll(proxy: proxy)
            }
        }
    }
    
    private func productCardView(product: Product) -> some View {
        RProductCard(
            product: product,
            currency: resolvedCurrency,
            country: resolvedCountry
        )
        .padding(.horizontal, ReachuSpacing.md)
    }
    
    private var loadingView: some View {
        VStack(spacing: ReachuSpacing.md) {
            ProgressView()
                .tint(adaptiveColors.primary)
            Text("Loading products...")
                .font(ReachuTypography.caption1)
                .foregroundColor(adaptiveColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, ReachuSpacing.xl)
    }
    
    private var errorView: some View {
        VStack(spacing: ReachuSpacing.sm) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 32))
                .foregroundColor(adaptiveColors.error)
            
            Text("Error loading products")
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
                loadProducts()
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
        .padding(.vertical, ReachuSpacing.xl)
    }
    
    // MARK: - Helper Methods
    
    private func handleCampaignStateChange() {
        if shouldShow {
            loadProducts()
        } else {
            stopAutoScroll()
        }
    }
    
    private func handleComponentChange() {
        if shouldShow {
            loadProducts()
        } else {
            stopAutoScroll()
            viewModel.products = []
        }
    }
    
    private func loadProducts() {
        guard let config = config else {
            viewModel.products = []
            return
        }
        
        Task {
            await viewModel.loadProducts(
                productIds: config.productIds,
                currency: resolvedCurrency,
                country: resolvedCountry
            )
        }
    }
    
    private func startAutoScroll(proxy: ScrollViewProxy) {
        guard let config = config, config.autoPlay, products.count > 1 else {
            return
        }
        
        stopAutoScroll()
        
        autoScrollTimer = Timer.scheduledTimer(withTimeInterval: Double(config.interval) / 1000.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                currentIndex = (currentIndex + 1) % products.count
                proxy.scrollTo(currentIndex, anchor: .leading)
            }
        }
    }
    
    private func stopAutoScroll() {
        autoScrollTimer?.invalidate()
        autoScrollTimer = nil
    }
}

// MARK: - ViewModel

@MainActor
class RProductCarouselViewModel: ObservableObject {
    
    @Published var products: [Product] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isMarketUnavailable: Bool = false
    
    private var sdk: SdkClient {
        let config = ReachuConfiguration.shared
        let baseURL = URL(string: config.environment.graphQLURL)!
        let apiKey = config.apiKey.isEmpty ? "DEMO_KEY" : config.apiKey
        return SdkClient(baseUrl: baseURL, apiKey: apiKey)
    }
    
    func loadProducts(productIds: [String], currency: String, country: String) async {
        guard ReachuConfiguration.shared.shouldUseSDK else {
            isMarketUnavailable = true
            isLoading = false
            return
        }
        
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        isMarketUnavailable = false
        
        print("🛍️ [RProductCarousel] Loading products with IDs: \(productIds)")
        
        do {
            // Convert String IDs to Int IDs
            let intProductIds = productIds.compactMap { Int($0) }
            
            let dtoProducts = try await sdk.channel.product.get(
                currency: currency,
                imageSize: "large",
                barcodeList: nil,
                categoryIds: nil,
                productIds: intProductIds.isEmpty ? nil : intProductIds,
                skuList: nil,
                useCache: true,
                shippingCountryCode: country
            )
            
            products = dtoProducts.map { $0.toDomainProduct() }
            print("✅ [RProductCarousel] Loaded \(products.count) products")
            
        } catch let error as NotFoundException {
            isMarketUnavailable = true
            errorMessage = nil
            print("⚠️ [RProductCarousel] Market not available")
        } catch let error as SdkException {
            if error.code == "NOT_FOUND" || error.status == 404 {
                isMarketUnavailable = true
                errorMessage = nil
            } else {
                errorMessage = error.description
                print("❌ [RProductCarousel] Failed to load products: \(error.description)")
            }
        } catch {
            errorMessage = error.localizedDescription
            print("❌ [RProductCarousel] Failed to load products: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
}


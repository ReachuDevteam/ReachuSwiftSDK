import SwiftUI
import ReachuCore
import ReachuDesignSystem

/// Auto-configured Product Store component
/// Automatically loads configuration from active campaign
/// Usage: Just drag RProductStore() into your view - no parameters needed!
public struct RProductStore: View {
    
    // MARK: - Properties
    
    @ObservedObject private var campaignManager = CampaignManager.shared
    @StateObject private var viewModel = RProductStoreViewModel()
    
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
    
    /// Get active product store component from campaign
    private var activeComponent: Component? {
        campaignManager.getActiveComponent(type: "product_store")
    }
    
    /// Extract ProductStoreConfig from component
    private var config: ProductStoreConfig? {
        guard let component = activeComponent,
              case .productStore(let config) = component.config else {
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
    
    /// Display type (grid or list)
    private var displayType: String {
        config?.displayType ?? "grid"
    }
    
    /// Number of columns
    private var columns: Int {
        config?.columns ?? 2
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
                storeContent
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
    
    private var storeContent: some View {
        Group {
            if displayType == "grid" {
                gridView
            } else {
                listView
            }
        }
    }
    
    private var gridView: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: ReachuSpacing.md), count: self.columns)
        
        return ScrollView {
            LazyVGrid(columns: columns, spacing: ReachuSpacing.md) {
                ForEach(products) { product in
                    RProductCard(
                        product: product,
                        currency: resolvedCurrency,
                        country: resolvedCountry
                    )
                }
            }
            .padding(ReachuSpacing.lg)
        }
    }
    
    private var listView: some View {
        ScrollView {
            LazyVStack(spacing: ReachuSpacing.md) {
                ForEach(products) { product in
                    RProductCard(
                        product: product,
                        currency: resolvedCurrency,
                        country: resolvedCountry
                    )
                }
            }
            .padding(ReachuSpacing.lg)
        }
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
            viewModel.products = []
        }
    }
    
    private func handleComponentChange() {
        if shouldShow {
            loadProducts()
        } else {
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
                mode: config.mode,
                productIds: config.productIds,
                currency: resolvedCurrency,
                country: resolvedCountry
            )
        }
    }
}

// MARK: - ViewModel

@MainActor
class RProductStoreViewModel: ObservableObject {
    
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
    
    func loadProducts(mode: String, productIds: [String]?, currency: String, country: String) async {
        guard ReachuConfiguration.shared.shouldUseSDK else {
            isMarketUnavailable = true
            isLoading = false
            return
        }
        
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        isMarketUnavailable = false
        
        print("🛍️ [RProductStore] Loading products - Mode: \(mode)")
        
        do {
            let intProductIds: [Int]?
            
            if mode == "filtered", let productIds = productIds {
                intProductIds = productIds.compactMap { Int($0) }
                print("   Filtered mode - Product IDs: \(intProductIds ?? [])")
            } else {
                intProductIds = nil
                print("   All mode - Loading all products")
            }
            
            let dtoProducts = try await sdk.channel.product.get(
                currency: currency,
                imageSize: "large",
                barcodeList: nil,
                categoryIds: nil,
                productIds: intProductIds,
                skuList: nil,
                useCache: true,
                shippingCountryCode: country
            )
            
            products = dtoProducts.map { $0.toDomainProduct() }
            print("✅ [RProductStore] Loaded \(products.count) products")
            
        } catch let error as NotFoundException {
            isMarketUnavailable = true
            errorMessage = nil
            print("⚠️ [RProductStore] Market not available")
        } catch let error as SdkException {
            if error.code == "NOT_FOUND" || error.status == 404 {
                isMarketUnavailable = true
                errorMessage = nil
            } else {
                errorMessage = error.description
                print("❌ [RProductStore] Failed to load products: \(error.description)")
            }
        } catch {
            errorMessage = error.localizedDescription
            print("❌ [RProductStore] Failed to load products: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
}


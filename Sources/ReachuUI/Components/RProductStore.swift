import SwiftUI
import ReachuCore
import ReachuDesignSystem

/// Auto-configured Product Store component
/// Automatically loads configuration from active campaign
/// Usage: Just drag RProductStore() into your view - no parameters needed!
public struct RProductStore: View {
    
    // MARK: - Cached Config Values
    
    /// Internal structure to cache parsed config values
    /// This avoids recalculating layout and conversions on every render
    private struct CachedConfig {
        let mode: String
        let productIds: [Int]?
        let displayType: String
        let columns: Int
        let gridItems: [GridItem] // Pre-computed grid layout
        let configId: String // Used to detect config changes
        
        init(config: ProductStoreConfig) {
            self.mode = config.mode
            self.displayType = config.displayType
            self.columns = config.columns
            
            // Cache converted product IDs if available (String → Int)
            if let stringIds = config.productIds, !stringIds.isEmpty {
                self.productIds = stringIds.compactMap { Int($0) }
            } else {
                self.productIds = nil
            }
            
            // Pre-compute grid layout (expensive operation)
            self.gridItems = Array(repeating: GridItem(.flexible(), spacing: ReachuSpacing.md), count: config.columns)
            
            // Create unique identifier for this config (detects changes)
            let productIdsString = config.productIds?.joined(separator: "-") ?? "all"
            self.configId = "\(config.mode)-\(productIdsString)-\(config.displayType)-\(config.columns)"
        }
    }
    
    // MARK: - Properties
    
    /// Optional component ID to identify a specific component
    /// If nil, uses the first matching component from the campaign
    private let componentId: String?
    
    @ObservedObject private var campaignManager = CampaignManager.shared
    @StateObject private var viewModel = RProductStoreViewModel()
    
    // Cache parsed config values - only recalculated when config changes
    @State private var cachedConfig: CachedConfig?
    @State private var currentConfigId: String?
    
    @SwiftUI.Environment(\.colorScheme) private var colorScheme: SwiftUI.ColorScheme
    
    // MARK: - Initializer
    
    public init(componentId: String? = nil) {
        self.componentId = componentId
    }
    
    // MARK: - Computed Properties
    
    private var adaptiveColors: AdaptiveColors {
        ReachuColors.adaptive(for: colorScheme)
    }
    
    /// Get active product store component from campaign
    private var activeComponent: Component? {
        campaignManager.getActiveComponent(type: "product_store", componentId: componentId)
    }
    
    /// Extract ProductStoreConfig from component
    private var config: ProductStoreConfig? {
        guard let component = activeComponent,
              case .productStore(let config) = component.config else {
            return nil
        }
        return config
    }
    
    /// Update cached config when config changes
    private func updateCachedConfigIfNeeded() {
        guard let config = config else {
            if cachedConfig != nil {
                cachedConfig = nil
                currentConfigId = nil
            }
            return
        }
        
        let productIdsString = config.productIds?.joined(separator: "-") ?? "all"
        let newConfigId = "\(config.mode)-\(productIdsString)-\(config.displayType)-\(config.columns)"
        
        // Only recalculate if config actually changed
        if currentConfigId != newConfigId {
            cachedConfig = CachedConfig(config: config)
            currentConfigId = newConfigId
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
            } else if config != nil {
                if !products.isEmpty {
                    storeContent
                } else {
                    // Show empty state message
                    emptyStateView
                }
            } else {
                Color.clear.frame(height: 1)
            }
        }
        .onChange(of: campaignManager.isCampaignActive) { _ in
            updateCachedConfigIfNeeded()
            handleCampaignStateChange()
        }
        .onChange(of: campaignManager.currentCampaign?.isPaused) { _ in
            updateCachedConfigIfNeeded()
            handleCampaignStateChange()
        }
        .onChange(of: activeComponent?.id) { _ in
            updateCachedConfigIfNeeded()
            handleComponentChange()
        }
        .onAppear {
            updateCachedConfigIfNeeded()
            handleComponentChange()
        }
    }
    
    // MARK: - Content Views
    
    private var storeContent: some View {
        Group {
            if let cachedConfig = cachedConfig {
                if cachedConfig.displayType == "grid" {
                    gridView(columns: cachedConfig.gridItems)
                } else {
                    listView
                }
            }
        }
    }
    
    private func gridView(columns: [GridItem]) -> some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: ReachuSpacing.md) {
                ForEach(products) { product in
                    RProductCard(product: product)
                }
            }
            .padding(.horizontal, ReachuSpacing.md)
            .padding(.vertical, ReachuSpacing.md)
        }
    }
    
    private var listView: some View {
        ScrollView {
            LazyVStack(spacing: ReachuSpacing.md) {
                ForEach(products) { product in
                    RProductCard(product: product)
                }
            }
            .padding(.horizontal, ReachuSpacing.md)
            .padding(.vertical, ReachuSpacing.md)
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
    
    private var emptyStateView: some View {
        VStack(spacing: ReachuSpacing.sm) {
            Image(systemName: "cart.badge.questionmark")
                .font(.system(size: 32))
                .foregroundColor(adaptiveColors.textSecondary)
            
            Text("No products available")
                .font(ReachuTypography.bodyBold)
                .foregroundColor(adaptiveColors.textPrimary)
            
            Text("Products will appear here when available")
                .font(ReachuTypography.caption1)
                .foregroundColor(adaptiveColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, ReachuSpacing.lg)
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
        guard let cachedConfig = cachedConfig else {
            viewModel.products = []
            return
        }
        
        Task {
            // Use cached config values (no conversion needed)
            await viewModel.loadProducts(
                mode: cachedConfig.mode,
                productIds: cachedConfig.productIds,
                currency: ReachuConfiguration.shared.marketConfiguration.currencyCode,
                country: ReachuConfiguration.shared.marketConfiguration.countryCode
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
    
    func loadProducts(mode: String, productIds: [Int]?, currency: String, country: String) async {
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
            // Product IDs are already converted to Int (cached)
            let hasValidIds = productIds != nil && !productIds!.isEmpty
            let shouldUseFiltered = mode == "filtered" && hasValidIds
            
            // Determine which IDs to use (if any)
            let idsToUse: [Int]?
            if shouldUseFiltered {
                print("   Filtered mode - Product IDs: \(productIds ?? [])")
                idsToUse = productIds
            } else if mode == "filtered" && !hasValidIds {
                // Filtered mode but no IDs - fallback to all products
                print("⚠️ [RProductStore] Filtered mode requires product IDs but none provided")
                print("   Falling back to loading all products from channel")
                idsToUse = nil
            } else {
                // All mode - load all products
                print("   All mode - Loading all products from channel")
                idsToUse = nil
            }
            
            // Load products with determined IDs
            var dtoProducts = try await sdk.channel.product.get(
                currency: currency,
                imageSize: "large",
                barcodeList: nil,
                categoryIds: nil,
                productIds: idsToUse,
                skuList: nil,
                useCache: true,
                shippingCountryCode: country
            )
            
            print("📦 [RProductStore] API returned \(dtoProducts.count) products")
            
            // Fallback: If filtered mode returned 0 products, try loading all products instead
            if dtoProducts.isEmpty && mode == "filtered" && hasValidIds {
                print("⚠️ [RProductStore] No products found for filtered IDs: \(productIds ?? [])")
                print("   Falling back to loading all products from channel")
                print("   Currency: \(currency), Country: \(country)")
                
                // Retry with all products (no productIds filter)
                dtoProducts = try await sdk.channel.product.get(
                    currency: currency,
                    imageSize: "large",
                    barcodeList: nil,
                    categoryIds: nil,
                    productIds: nil,  // Load all products
                    skuList: nil,
                    useCache: true,
                    shippingCountryCode: country
                )
                
                print("📦 [RProductStore] Fallback returned \(dtoProducts.count) products")
            } else if dtoProducts.isEmpty && hasValidIds {
                print("⚠️ [RProductStore] No products found for IDs: \(productIds ?? [])")
                print("   Currency: \(currency), Country: \(country)")
            }
            
            products = dtoProducts.map { $0.toDomainProduct() }
            print("✅ [RProductStore] Loaded \(products.count) products")
            
            // Clear any previous error if we successfully loaded products
            if !products.isEmpty {
                errorMessage = nil
            } else if mode == "filtered" && (productIds == nil || productIds!.isEmpty) {
                // Only show error if we're in filtered mode and really have no IDs
                errorMessage = "No valid product IDs"
            }
            
        } catch let error as NotFoundException {
            isMarketUnavailable = true
            errorMessage = nil
            print("⚠️ [RProductStore] Market not available: \(error)")
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


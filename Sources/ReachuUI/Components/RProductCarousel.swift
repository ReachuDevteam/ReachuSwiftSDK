import SwiftUI
import ReachuCore
import ReachuDesignSystem

#if os(iOS)
import UIKit
#endif

/// Auto-configured Product Carousel component
/// Automatically loads configuration from active campaign
/// Usage: Just drag RProductCarousel() into your view - no parameters needed!
public struct RProductCarousel: View {
    
    // MARK: - Cached Config Values
    
    /// Internal structure to cache parsed config values
    /// This avoids recalculating conversions and values on every render
    private struct CachedConfig {
        let productIds: [Int]
        let autoPlayInterval: TimeInterval
        let shouldAutoPlay: Bool
        let layout: String // "compact" or "full"
        let configId: String // Used to detect config changes
        
        init(config: ProductCarouselConfig) {
            // Cache converted product IDs (String → Int)
            self.productIds = config.productIds.compactMap { Int($0) }
            
            // Cache auto-play interval conversion (milliseconds → seconds)
            self.autoPlayInterval = Double(config.interval) / 1000.0
            self.shouldAutoPlay = config.autoPlay
            
            // Cache layout (default to "full" if not specified)
            self.layout = config.layout ?? "full"
            
            // Create unique identifier for this config (detects changes)
            self.configId = "\(config.productIds.joined(separator: "-"))-\(config.autoPlay)-\(config.interval)-\(self.layout)"
        }
    }
    
    // MARK: - Properties
    
    @ObservedObject private var campaignManager = CampaignManager.shared
    @StateObject private var viewModel = RProductCarouselViewModel()
    @State private var currentIndex: Int = 0
    @State private var autoScrollTimer: Timer?
    
    // Cache parsed config values - only recalculated when config changes
    @State private var cachedConfig: CachedConfig?
    @State private var currentConfigId: String?
    
    @SwiftUI.Environment(\.colorScheme) private var colorScheme: SwiftUI.ColorScheme
    
    // MARK: - Properties for Demo/Testing
    
    /// Optional layout override for demo/testing purposes
    /// If set, overrides the layout from backend config
    /// Options: "full", "compact", "horizontal"
    private let layout: String?
    
    // MARK: - Initializer
    
    public init(layout: String? = nil) {
        // Optional layout override for demo/testing (e.g., "full", "compact", "horizontal")
        // If nil, uses layout from backend config
        self.layout = layout
    }
    
    // MARK: - Computed Properties
    
    private var adaptiveColors: AdaptiveColors {
        ReachuColors.adaptive(for: colorScheme)
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
    
    /// Update cached config when config changes
    private func updateCachedConfigIfNeeded() {
        guard let config = config else {
            if cachedConfig != nil {
                cachedConfig = nil
                currentConfigId = nil
            }
            return
        }
        
        let newConfigId = "\(config.productIds.joined(separator: "-"))-\(config.autoPlay)-\(config.interval)"
        
        // Only recalculate if config actually changed
        if currentConfigId != newConfigId {
            cachedConfig = CachedConfig(config: config)
            currentConfigId = newConfigId
            
            // Log config details (only when changed)
            print("📋 [RProductCarousel] Config loaded:")
            print("   - productIds (String): \(config.productIds)")
            print("   - productIds converted to Int: \(CachedConfig(config: config).productIds)")
            print("   - autoPlay: \(config.autoPlay)")
            print("   - interval: \(config.interval)ms")
            print("   - converted interval: \(CachedConfig(config: config).autoPlayInterval)s")
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
    
    /// Get effective config, calculating if needed
    private var effectiveConfig: ProductCarouselConfig? {
        guard let config = config else { return nil }
        return config
    }
    
    public var body: some View {
        Group {
            if !shouldShow {
                EmptyView()
            } else if shouldHide {
                EmptyView()
            } else if let config = effectiveConfig {
                if shouldShowLoading || products.isEmpty {
                    skeletonView
                } else {
                    carouselContent
                }
            } else {
                // Show skeleton loader while waiting for config
                skeletonView
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
        .onChange(of: campaignManager.activeComponents.count) { _ in
            // React immediately when components are loaded/updated
            updateCachedConfigIfNeeded()
            handleComponentChange()
        }
        .onChange(of: activeComponent?.id) { _ in
            updateCachedConfigIfNeeded()
            handleComponentChange()
        }
        .onAppear {
            // Try to update immediately on appear (in case data is already available)
            updateCachedConfigIfNeeded()
            handleComponentChange()
        }
        .task {
            // Also try to update after a small delay to catch async updates
            try? await Task.sleep(nanoseconds: 50_000_000) // 50ms delay
            updateCachedConfigIfNeeded()
            handleComponentChange()
        }
        .onDisappear {
            stopAutoScroll()
        }
    }
    
    // MARK: - Content Views
    
    private var carouselContent: some View {
        // Use layout override if provided, otherwise use layout from config
        let currentLayout = layout ?? cachedConfig?.layout ?? "full"
        
        switch currentLayout {
        case "compact":
            return AnyView(carouselContentCompact)
        case "horizontal":
            return AnyView(carouselContentHorizontal)
        default: // "full"
            return AnyView(carouselContentFull)
        }
    }
    
    /// Full layout carousel (default)
    private var carouselContentFull: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let horizontalPadding = ReachuSpacing.md * 2 // Padding on both sides
            // Use full width minus padding
            let cardWidth = screenWidth - horizontalPadding
            let cardHeight = cardWidth * 1.2 // Maintain aspect ratio (height is 1.2x width)
            
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: ReachuSpacing.md) {
                        ForEach(Array(products.enumerated()), id: \.element.id) { index, product in
                            productCardView(product: product)
                                .frame(width: cardWidth, height: cardHeight)
                                .id(index)
                        }
                    }
                    .padding(.horizontal, ReachuSpacing.md)
                }
                .onAppear {
                    startAutoScroll(proxy: proxy)
                }
                .onChange(of: products.count) { _ in
                    // Restart auto-scroll when products change
                    startAutoScroll(proxy: proxy)
                }
                .onChange(of: cachedConfig?.configId) { _ in
                    // Restart auto-scroll when config changes (e.g., interval or autoPlay)
                    startAutoScroll(proxy: proxy)
                }
            }
            .frame(width: screenWidth, height: cardHeight)
        }
        .frame(height: (UIScreen.main.bounds.width - (ReachuSpacing.md * 2)) * 1.2) // Fixed height based on full width
    }
    
    /// Compact layout carousel
    private var carouselContentCompact: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let horizontalPadding = ReachuSpacing.md * 2 // Padding on both sides
            let spacing = ReachuSpacing.sm // Spacing between cards
            // Calculate card width to show 2 cards at once with a bit of preview for the third
            let cardWidth = (screenWidth - horizontalPadding - spacing) / 2.1
            let cardHeight = cardWidth * 0.8 // Shorter aspect ratio for compact
            
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: ReachuSpacing.sm) {
                        ForEach(Array(products.enumerated()), id: \.element.id) { index, product in
                            productCardView(product: product)
                                .frame(width: cardWidth, height: cardHeight)
                                .id(index)
                        }
                    }
                    .padding(.horizontal, ReachuSpacing.md)
                }
                .onAppear {
                    startAutoScroll(proxy: proxy)
                }
                .onChange(of: products.count) { _ in
                    // Restart auto-scroll when products change
                    startAutoScroll(proxy: proxy)
                }
                .onChange(of: cachedConfig?.configId) { _ in
                    // Restart auto-scroll when config changes (e.g., interval or autoPlay)
                    startAutoScroll(proxy: proxy)
                }
            }
        }
        .aspectRatio(2.1 / 1.68, contentMode: .fit) // Maintain aspect ratio for compact layout (2 cards + spacing)
    }
    
    /// Horizontal layout carousel (image left, description right)
    private var carouselContentHorizontal: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let cardWidth = screenWidth * 0.9 // 90% of screen width for horizontal cards
            let cardHeight: CGFloat = 140 // Fixed height for horizontal cards
            
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: ReachuSpacing.md) {
                        ForEach(Array(products.enumerated()), id: \.element.id) { index, product in
                            horizontalProductCardView(product: product)
                                .frame(width: cardWidth, height: cardHeight)
                                .id(index)
                        }
                    }
                    .padding(.horizontal, ReachuSpacing.md)
                }
                .onAppear {
                    startAutoScroll(proxy: proxy)
                }
                .onChange(of: products.count) { _ in
                    // Restart auto-scroll when products change
                    startAutoScroll(proxy: proxy)
                }
                .onChange(of: cachedConfig?.configId) { _ in
                    // Restart auto-scroll when config changes (e.g., interval or autoPlay)
                    startAutoScroll(proxy: proxy)
                }
            }
        }
        .frame(height: 140) // Fixed height for horizontal cards
    }
    
    private func productCardView(product: Product) -> some View {
        RProductCard(product: product)
            .padding(.horizontal, ReachuSpacing.md)
    }
    
    /// Horizontal product card layout (image left, description right)
    private func horizontalProductCardView(product: Product) -> some View {
        HStack(spacing: ReachuSpacing.md) {
            // Image on the left
            if let imageUrl = product.images.first?.url, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        RoundedRectangle(cornerRadius: ReachuBorderRadius.medium)
                            .fill(adaptiveColors.surfaceSecondary)
                            .frame(width: 120, height: 120)
                            .overlay { ProgressView().tint(adaptiveColors.primary) }
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 120, height: 120)
                            .clipped()
                            .cornerRadius(ReachuBorderRadius.medium)
                    case .failure:
                        RoundedRectangle(cornerRadius: ReachuBorderRadius.medium)
                            .fill(adaptiveColors.surfaceSecondary)
                            .frame(width: 120, height: 120)
                            .overlay {
                                Image(systemName: "photo")
                                    .foregroundColor(adaptiveColors.textSecondary)
                            }
                    @unknown default:
                        RoundedRectangle(cornerRadius: ReachuBorderRadius.medium)
                            .fill(adaptiveColors.surfaceSecondary)
                            .frame(width: 120, height: 120)
                    }
                }
            } else {
                RoundedRectangle(cornerRadius: ReachuBorderRadius.medium)
                    .fill(adaptiveColors.surfaceSecondary)
                    .frame(width: 120, height: 120)
            }
            
            // Description on the right
            VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
                Text(product.title)
                    .font(ReachuTypography.bodyBold)
                    .foregroundColor(adaptiveColors.textPrimary)
                    .lineLimit(2)
                
                if let brand = product.brand {
                    Text(brand)
                        .font(ReachuTypography.caption1)
                        .foregroundColor(adaptiveColors.textSecondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Price
                VStack(alignment: .leading, spacing: 2) {
                    Text(product.price.displayAmount)
                        .font(ReachuTypography.bodyBold)
                        .foregroundColor(adaptiveColors.primary)
                    
                    if let compareAtAmount = product.price.displayCompareAtAmount {
                        Text(compareAtAmount)
                            .font(ReachuTypography.caption1)
                            .foregroundColor(adaptiveColors.textSecondary)
                            .strikethrough()
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(ReachuSpacing.md)
        .background(adaptiveColors.surface)
        .cornerRadius(ReachuBorderRadius.large)
        .reachuCardShadow(for: colorScheme)
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
    
    // MARK: - Skeleton View
    
    /// Skeleton loader shown while carousel is loading
    private var skeletonView: some View {
        // Use layout override if provided, otherwise use layout from config
        let currentLayout = layout ?? cachedConfig?.layout ?? "full"
        
        switch currentLayout {
        case "compact":
            return AnyView(skeletonViewCompact)
        case "horizontal":
            return AnyView(skeletonViewHorizontal)
        default: // "full"
            return AnyView(skeletonViewFull)
        }
    }
    
    /// Full layout skeleton (default)
    private var skeletonViewFull: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let horizontalPadding = ReachuSpacing.md * 2 // Padding on both sides
            // Use full width minus padding
            let cardWidth = screenWidth - horizontalPadding
            let cardHeight = cardWidth * 1.2 // Maintain aspect ratio (height is 1.2x width)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: ReachuSpacing.md) {
                    ForEach(0..<3, id: \.self) { _ in
                        skeletonCardViewFull(width: cardWidth, height: cardHeight)
                    }
                }
                .padding(.horizontal, ReachuSpacing.md)
            }
            .frame(width: screenWidth, height: cardHeight)
        }
        .frame(height: (UIScreen.main.bounds.width - (ReachuSpacing.md * 2)) * 1.2) // Fixed height based on full width
    }
    
    /// Compact layout skeleton
    private var skeletonViewCompact: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let horizontalPadding = ReachuSpacing.md * 2 // Padding on both sides
            let spacing = ReachuSpacing.sm // Spacing between cards
            // Calculate card width to show 2 cards at once with a bit of preview for the third
            let cardWidth = (screenWidth - horizontalPadding - spacing) / 2.1
            let cardHeight = cardWidth * 0.8 // Shorter aspect ratio for compact
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: ReachuSpacing.sm) {
                    ForEach(0..<4, id: \.self) { _ in
                        skeletonCardViewCompact(width: cardWidth, height: cardHeight)
                    }
                }
                .padding(.horizontal, ReachuSpacing.md)
            }
        }
        .aspectRatio(2.1 / 1.68, contentMode: .fit) // Maintain aspect ratio for compact skeleton (2 cards + spacing)
    }
    
    private func skeletonCardViewFull(width: CGFloat, height: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: ReachuSpacing.sm) {
            // Image skeleton
            RoundedRectangle(cornerRadius: ReachuBorderRadius.large)
                .fill(adaptiveColors.surfaceSecondary)
                .frame(width: width, height: height * 0.7)
                .shimmerEffect()
            
            // Title skeleton
            RoundedRectangle(cornerRadius: ReachuBorderRadius.small)
                .fill(adaptiveColors.surfaceSecondary.opacity(0.6))
                .frame(width: width * 0.7, height: 16)
                .shimmerEffect()
            
            // Price skeleton
            RoundedRectangle(cornerRadius: ReachuBorderRadius.small)
                .fill(adaptiveColors.surfaceSecondary.opacity(0.6))
                .frame(width: width * 0.4, height: 14)
                .shimmerEffect()
        }
        .frame(width: width, height: height)
        .padding(.horizontal, ReachuSpacing.md)
    }
    
    private func skeletonCardViewCompact(width: CGFloat, height: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
            // Image skeleton (smaller)
            RoundedRectangle(cornerRadius: ReachuBorderRadius.medium)
                .fill(adaptiveColors.surfaceSecondary)
                .frame(width: width, height: height * 0.6)
                .shimmerEffect()
            
            // Title skeleton (shorter)
            RoundedRectangle(cornerRadius: ReachuBorderRadius.small)
                .fill(adaptiveColors.surfaceSecondary.opacity(0.6))
                .frame(width: width * 0.6, height: 12)
                .shimmerEffect()
            
            // Price skeleton (smaller)
            RoundedRectangle(cornerRadius: ReachuBorderRadius.small)
                .fill(adaptiveColors.surfaceSecondary.opacity(0.6))
                .frame(width: width * 0.35, height: 12)
                .shimmerEffect()
        }
        .frame(width: width, height: height)
        .padding(.horizontal, ReachuSpacing.sm)
    }
    
    /// Horizontal layout skeleton
    private var skeletonViewHorizontal: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let cardWidth = screenWidth * 0.9
            let cardHeight: CGFloat = 140
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: ReachuSpacing.md) {
                    ForEach(0..<3, id: \.self) { _ in
                        skeletonHorizontalCardView(width: cardWidth, height: cardHeight)
                    }
                }
                .padding(.horizontal, ReachuSpacing.md)
            }
        }
        .frame(height: 140)
    }
    
    private func skeletonHorizontalCardView(width: CGFloat, height: CGFloat) -> some View {
        HStack(spacing: ReachuSpacing.md) {
            // Image skeleton on the left
            RoundedRectangle(cornerRadius: ReachuBorderRadius.medium)
                .fill(adaptiveColors.surfaceSecondary)
                .frame(width: 120, height: 120)
                .shimmerEffect()
            
            // Description skeleton on the right
            VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
                // Title skeleton
                RoundedRectangle(cornerRadius: ReachuBorderRadius.small)
                    .fill(adaptiveColors.surfaceSecondary.opacity(0.6))
                    .frame(width: width * 0.5, height: 16)
                    .shimmerEffect()
                
                // Brand skeleton
                RoundedRectangle(cornerRadius: ReachuBorderRadius.small)
                    .fill(adaptiveColors.surfaceSecondary.opacity(0.6))
                    .frame(width: width * 0.3, height: 12)
                    .shimmerEffect()
                
                Spacer()
                
                // Price skeleton
                RoundedRectangle(cornerRadius: ReachuBorderRadius.small)
                    .fill(adaptiveColors.surfaceSecondary.opacity(0.6))
                    .frame(width: width * 0.25, height: 14)
                    .shimmerEffect()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(ReachuSpacing.md)
        .frame(width: width, height: height)
        .background(adaptiveColors.surface)
        .cornerRadius(ReachuBorderRadius.large)
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
        guard let cachedConfig = cachedConfig else {
            viewModel.products = []
            return
        }
        
        Task {
            // Use cached Int product IDs (no conversion needed)
            await viewModel.loadProducts(
                productIds: cachedConfig.productIds,
                currency: ReachuConfiguration.shared.marketConfiguration.currencyCode,
                country: ReachuConfiguration.shared.marketConfiguration.countryCode
            )
        }
    }
    
    private func startAutoScroll(proxy: ScrollViewProxy) {
        guard let cachedConfig = cachedConfig,
              cachedConfig.shouldAutoPlay,
              products.count > 1 else {
            return
        }
        
        stopAutoScroll()
        
        // Use cached interval (already converted to TimeInterval)
        autoScrollTimer = Timer.scheduledTimer(withTimeInterval: cachedConfig.autoPlayInterval, repeats: true) { _ in
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
    
    func loadProducts(productIds: [Int], currency: String, country: String) async {
        guard ReachuConfiguration.shared.shouldUseSDK else {
            isMarketUnavailable = true
            isLoading = false
            return
        }
        
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        isMarketUnavailable = false
        
        // Determine if we should load all products or filtered
        let hasValidIds = !productIds.isEmpty
        let idsToUse: [Int]?
        
        if hasValidIds {
            print("🛍️ [RProductCarousel] Loading products with IDs: \(productIds)")
            idsToUse = productIds
        } else {
            print("⚠️ [RProductCarousel] No product IDs provided")
            print("   Falling back to loading all products from channel")
            idsToUse = nil
        }
        
        do {
            let dtoProducts = try await sdk.channel.product.get(
                currency: currency,
                imageSize: "large",
                barcodeList: nil,
                categoryIds: nil,
                productIds: idsToUse,
                skuList: nil,
                useCache: true,
                shippingCountryCode: country
            )
            
            print("📦 [RProductCarousel] API returned \(dtoProducts.count) products")
            if dtoProducts.isEmpty {
                print("⚠️ [RProductCarousel] No products found")
                print("   Currency: \(currency), Country: \(country)")
                print("   💡 This could mean:")
                print("      - Products don't exist in this market")
                print("      - Products are not available for this currency/country")
                print("      - Products are not published/active")
            } else if hasValidIds && dtoProducts.count < productIds.count {
                print("⚠️ [RProductCarousel] Only found \(dtoProducts.count) out of \(productIds.count) products")
                let foundIds = Set(dtoProducts.map { $0.id })
                let requestedIds = Set(productIds)
                let missingIds = requestedIds.subtracting(foundIds)
                print("   Found IDs: \(foundIds.sorted())")
                print("   Missing IDs: \(missingIds.sorted())")
            }
            
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


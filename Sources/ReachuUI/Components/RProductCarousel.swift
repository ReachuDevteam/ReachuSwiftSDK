import SwiftUI
import ReachuCore
import ReachuDesignSystem

#if os(iOS)
import UIKit
#endif

/// Auto-configured Product Carousel component
/// Automatically loads configuration from active campaign
/// 
/// **Usage:**
/// ```swift
/// // Basic usage - uses layout from backend config
/// RProductCarousel()
///
/// // Override layout for testing/comparison
/// RProductCarousel(layout: "full")      // Large vertical cards (full width)
/// RProductCarousel(layout: "compact")   // Small vertical cards (2 cards visible)
/// RProductCarousel(layout: "horizontal") // Horizontal cards (image left, info right)
/// ```
///
/// **Parameters:**
/// - `layout: String?` - Optional layout override. Options: `"full"`, `"compact"`, `"horizontal"`. If `nil`, uses layout from backend config.
///
/// **Backend Configuration (from API):**
/// The component reads configuration from `GET /api/campaigns/{campaignId}/components`:
/// ```json
/// {
///   "components": [{
///     "componentId": "product_carousel_1",
///     "status": "active",
///     "customConfig": {
///       "productIds": ["408841", "408842", "408843"],
///       "autoPlay": true,
///       "interval": 4000,
///       "layout": "full"
///     }
///   }]
/// }
/// ```
///
/// **Configuration Properties:**
/// - `productIds: [String]` - Array of product IDs. **Empty array or missing field loads ALL products from channel.**
/// - `autoPlay: Bool` - Enable/disable auto-scroll (default: `false` if not provided)
/// - `interval: Int` - Auto-scroll interval in milliseconds (default: `3000` if not provided)
/// - `layout: String?` - Layout type: `"full"`, `"compact"`, or `"horizontal"` (default: `"full"`)
///
/// **Layout Details:**
/// - `"full"`: Cards use full width minus padding, height is 2.0x width
/// - `"compact"`: Shows 2 cards at once, each card is ~47% of screen width
/// - `"horizontal"`: Cards are 90% width, 140px height, image left/description right
///
/// **Features:**
/// - ✅ Skeleton loader while loading
/// - ✅ Auto-scroll support (configurable interval)
/// - ✅ Automatic fallback to all products if no IDs provided
/// - ✅ Responsive card sizing
/// - ✅ Uses design system tokens (colors, spacing, shadows, border radius)
public struct RProductCarousel: View {
    
    // MARK: - Cached Config Values
    
    /// Internal structure to cache parsed config values
    /// This avoids recalculating conversions and values on every render
    private struct CachedConfig {
        let productIds: [Int]  // Empty array means "load all products from channel"
        let autoPlayInterval: TimeInterval
        let shouldAutoPlay: Bool
        let layout: String // "compact", "full", or "horizontal"
        let configId: String // Used to detect config changes
        
        init(config: ProductCarouselConfig, layoutOverride: String? = nil) {
            // Cache converted product IDs (String → Int)
            // Empty array means "load all products from channel"
            self.productIds = config.productIds.compactMap { Int($0) }
            
            // Cache auto-play interval conversion (milliseconds → seconds)
            self.autoPlayInterval = Double(config.interval) / 1000.0
            self.shouldAutoPlay = config.autoPlay
            
            // Use layout override if provided, otherwise use layout from config (default to "full")
            self.layout = layoutOverride ?? config.layout ?? "full"
            
            // Create unique identifier for this config (detects changes)
            // Use "all" when productIds is empty to make it clearer
            // Must match the format in updateCachedConfigIfNeeded()
            let productIdsString = config.productIds.isEmpty ? "all" : config.productIds.joined(separator: "-")
            self.configId = "\(productIdsString)-\(config.autoPlay)-\(config.interval)-\(self.layout)"
        }
    }
    
    // MARK: - Properties
    
    @ObservedObject private var campaignManager = CampaignManager.shared
    @StateObject private var viewModel = RProductCarouselViewModel()
    @State private var autoScrollTimer: Timer?
    @State private var showingProductDetail: Product? // For product detail overlay
    @State private var scrollOffset: CGFloat = 0 // For tracking scroll position
    
    // Cache parsed config values - only recalculated when config changes
    @State private var cachedConfig: CachedConfig?
    @State private var currentConfigId: String?
    
    @SwiftUI.Environment(\.colorScheme) private var colorScheme: SwiftUI.ColorScheme
    
    // MARK: - Properties
    
    /// Optional component ID to identify a specific component
    /// If nil, uses the first matching component from the campaign
    private let componentId: String?
    
    // MARK: - Properties for Demo/Testing
    
    /// Optional layout override for demo/testing purposes
    /// If set, overrides the layout from backend config
    /// Options: "full", "compact", "horizontal"
    private let layout: String?
    
    /// Whether to show the "Add to Cart" button in full layout cards
    /// Default: false (button hidden)
    private let showAddToCartButton: Bool
    
    // MARK: - Initializer
    
    public init(componentId: String? = nil, layout: String? = nil, showAddToCartButton: Bool = false) {
        // Optional component ID to identify a specific component
        self.componentId = componentId
        // Optional layout override for demo/testing (e.g., "full", "compact", "horizontal")
        // If nil, uses layout from backend config
        self.layout = layout
        self.showAddToCartButton = showAddToCartButton
    }
    
    // MARK: - Computed Properties
    
    private var adaptiveColors: AdaptiveColors {
        ReachuColors.adaptive(for: colorScheme)
    }
    
    /// Get active product carousel component from campaign
    private var activeComponent: Component? {
        campaignManager.getActiveComponent(type: "product_carousel", componentId: componentId)
    }
    
    /// Extract ProductCarouselConfig from component
    private var config: ProductCarouselConfig? {
        guard let component = activeComponent,
              case .productCarousel(let config) = component.config else {
            return nil
        }
        return config
    }
    
    /// Get a unique identifier based on productIds to detect config changes
    /// This helps detect when productIds change from backend even if component ID stays the same
    private var configProductIdsId: String {
        config?.productIds.joined(separator: "-") ?? ""
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
        
        // Use layout override if provided, otherwise use layout from config
        let effectiveLayout = layout ?? config.layout ?? "full"
        
        // Use "all" when productIds is empty to match CachedConfig.init
        let productIdsString = config.productIds.isEmpty ? "all" : config.productIds.joined(separator: "-")
        let newConfigId = "\(productIdsString)-\(config.autoPlay)-\(config.interval)-\(effectiveLayout)"
        
        // Only recalculate if config actually changed
        if currentConfigId != newConfigId {
            cachedConfig = CachedConfig(config: config, layoutOverride: layout)
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
            // No campaign configured - show component if config exists (legacy behavior)
            return config != nil
        }
        
        // Campaign must be active and not paused
        guard campaignManager.isCampaignActive,
              campaignManager.currentCampaign?.isPaused != true else {
            return false
        }
        
        // Component must exist and be active
        // Also check if config can be extracted (component might exist but config decoding failed)
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
            } else if effectiveConfig != nil {
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
            handleCampaignStateChange()
        }
        .onChange(of: campaignManager.currentCampaign?.isPaused) { _ in
            handleCampaignStateChange()
        }
        .onChange(of: campaignManager.activeComponents.count) { _ in
            // React immediately when components are loaded/updated
            handleComponentChange()
        }
        .onChange(of: activeComponent?.id) { _ in
            handleComponentChange()
        }
        .onChange(of: configProductIdsId) { _ in
            // React to productIds changes from backend (even if component ID doesn't change)
            handleComponentChange()
        }
        .onAppear {
            // Initialize on appear
            handleComponentChange()
        }
        .task {
            // Also try to update after a small delay to catch async updates
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms delay
            handleComponentChange()
        }
        .onDisappear {
            stopAutoScroll()
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
            let cardHeight = cardWidth * 1.3 // Balanced aspect ratio (approximately 3:4)
            
            VStack(spacing: 4) { // Reduced spacing between card and indicators for full layout
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: ReachuSpacing.md) {
                            ForEach(Array(products.enumerated()), id: \.element.id) { index, product in
                                productCardView(product: product)
                                    .frame(width: cardWidth, height: cardHeight)
                                    .id(index)
                                    .background(
                                        GeometryReader { geo in
                                            Color.clear.preference(
                                                key: ScrollOffsetPreferenceKey.self,
                                                value: geo.frame(in: .named("scroll")).minX
                                            )
                                        }
                                    )
                            }
                        }
                        .padding(.horizontal, ReachuSpacing.md)
                    }
                    .coordinateSpace(name: "scroll")
                    .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                        // Calculate current index based on scroll position
                        let cardWidthWithSpacing = cardWidth + ReachuSpacing.md
                        let index = Int(round(-value / cardWidthWithSpacing))
                        if index >= 0 && index < viewModel.products.count {
                            viewModel.currentIndex = index
                        }
                    }
                    .onAppear {
                        startAutoScroll(proxy: proxy)
                    }
                    .onChange(of: viewModel.products.count) { _ in
                        // Restart auto-scroll when products change
                        startAutoScroll(proxy: proxy)
                        viewModel.currentIndex = 0
                    }
                    .onChange(of: cachedConfig?.configId) { _ in
                        // Restart auto-scroll when config changes (e.g., interval or autoPlay)
                        startAutoScroll(proxy: proxy)
                    }
                }
                .frame(width: screenWidth, height: cardHeight)
                
                // Page indicators (closer spacing for full layout)
                if viewModel.products.count > 1 {
                    pageIndicatorsFull
                }
            }
        }
        .aspectRatio(1.0 / 1.3, contentMode: .fit) // Maintain balanced aspect ratio
    }
    
    /// Compact layout carousel
    private var carouselContentCompact: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let horizontalPadding = ReachuSpacing.md * 2 // Padding on both sides
            let spacing = ReachuSpacing.md // Spacing between cards
            // Calculate card width to show 2 cards at once
            let cardWidth = (screenWidth - horizontalPadding - spacing) / 2.0
            
            VStack(spacing: ReachuSpacing.sm) {
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: ReachuSpacing.md) {
                            ForEach(Array(products.enumerated()), id: \.element.id) { index, product in
                                productCardView(product: product)
                                    .frame(width: cardWidth) // Let card height adjust naturally
                                    .id(index)
                                    .background(
                                        GeometryReader { geo in
                                            Color.clear.preference(
                                                key: ScrollOffsetPreferenceKey.self,
                                                value: geo.frame(in: .named("scroll")).minX
                                            )
                                        }
                                    )
                            }
                        }
                        .padding(.horizontal, ReachuSpacing.md)
                    }
                    .coordinateSpace(name: "scroll")
                    .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                        // Calculate current index based on scroll position
                        let cardWidthWithSpacing = cardWidth + ReachuSpacing.md
                        let index = Int(round(-value / cardWidthWithSpacing))
                        if index >= 0 && index < viewModel.products.count {
                            viewModel.currentIndex = index
                        }
                    }
                    .onAppear {
                        startAutoScroll(proxy: proxy)
                    }
                    .onChange(of: viewModel.products.count) { _ in
                        // Restart auto-scroll when products change
                        startAutoScroll(proxy: proxy)
                        viewModel.currentIndex = 0
                    }
                    .onChange(of: cachedConfig?.configId) { _ in
                        // Restart auto-scroll when config changes (e.g., interval or autoPlay)
                        startAutoScroll(proxy: proxy)
                    }
                }
                
                // Page indicators
                if viewModel.products.count > 1 {
                    pageIndicators
                }
            }
        }
        .frame(height: 300) // Fixed height to prevent overlap with other components
    }
    
    /// Horizontal layout carousel (image left, description right)
    private var carouselContentHorizontal: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let cardWidth = screenWidth * 0.9 // 90% of screen width for horizontal cards
            let cardHeight: CGFloat = 110 // Reduced height for horizontal cards
            
            VStack(spacing: ReachuSpacing.sm) {
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: ReachuSpacing.md) {
                            ForEach(Array(products.enumerated()), id: \.element.id) { index, product in
                                horizontalProductCardView(product: product)
                                    .frame(width: cardWidth, height: cardHeight)
                                    .id(index)
                                    .background(
                                        GeometryReader { geo in
                                            Color.clear.preference(
                                                key: ScrollOffsetPreferenceKey.self,
                                                value: geo.frame(in: .named("scroll")).minX
                                            )
                                        }
                                    )
                            }
                        }
                        .padding(.horizontal, ReachuSpacing.md)
                    }
                    .coordinateSpace(name: "scroll")
                    .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                        // Calculate current index based on scroll position
                        let cardWidthWithSpacing = cardWidth + ReachuSpacing.md
                        let index = Int(round(-value / cardWidthWithSpacing))
                        if index >= 0 && index < viewModel.products.count {
                            viewModel.currentIndex = index
                        }
                    }
                    .onAppear {
                        startAutoScroll(proxy: proxy)
                    }
                    .onChange(of: viewModel.products.count) { _ in
                        // Restart auto-scroll when products change
                        startAutoScroll(proxy: proxy)
                        viewModel.currentIndex = 0
                    }
                    .onChange(of: cachedConfig?.configId) { _ in
                        // Restart auto-scroll when config changes (e.g., interval or autoPlay)
                        startAutoScroll(proxy: proxy)
                    }
                }
                
                // Page indicators
                if viewModel.products.count > 1 {
                    pageIndicators
                }
            }
        }
        .frame(height: 110) // Reduced height for horizontal cards
    }
    
    private func productCardView(product: Product) -> some View {
        let currentLayout = layout ?? cachedConfig?.layout ?? "full"
        
        // Use custom layout for "full" to avoid oversized hero variant
        if currentLayout == "full" {
            return AnyView(fullLayoutProductCardView(product: product))
        } else {
            // For compact and horizontal layouts, use grid variant without extra padding
            return AnyView(RProductCard(product: product, variant: .grid))
        }
    }
    
    /// Custom full layout product card with balanced sizing
    @ViewBuilder
    private func fullLayoutProductCardView(product: Product) -> some View {
        let adaptiveColors = ReachuColors.adaptive(for: colorScheme)
        
        // Sort images by order field (prioritizing 0 and 1)
        let sortedImages = product.images.sorted { first, second in
            let firstPriority = (first.order == 0 || first.order == 1) ? first.order : Int.max
            let secondPriority = (second.order == 0 || second.order == 1) ? second.order : Int.max
            
            if firstPriority != secondPriority {
                return firstPriority < secondPriority
            }
            return first.order < second.order
        }
        
        let primaryImageUrl = sortedImages.first?.url
        
        Button(action: {
            // Handle tap - show product detail
            showingProductDetail = product
        }) {
            VStack(alignment: .leading, spacing: 0) {
                // Product Image
                if let imageUrl = primaryImageUrl, let url = URL(string: imageUrl) {
                    LoadedImage(
                        url: url,
                        placeholder: AnyView(Rectangle()
                            .fill(adaptiveColors.surfaceSecondary)
                            .overlay { ProgressView().tint(adaptiveColors.primary) }),
                        errorView: AnyView(Rectangle()
                            .fill(adaptiveColors.surfaceSecondary)
                            .overlay {
                                Image(systemName: "photo")
                                    .foregroundColor(adaptiveColors.textSecondary)
                            })
                    )
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity) // Use full width, let height adjust naturally
                } else {
                    Rectangle()
                        .fill(adaptiveColors.surfaceSecondary)
                        .frame(height: 200)
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundColor(adaptiveColors.textSecondary)
                        }
                }
                
                // Product Info
                VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
                    if let brand = product.brand {
                        Text(brand)
                            .font(.system(size: 10, weight: .medium)) // Smaller brand text
                            .foregroundColor(adaptiveColors.textSecondary)
                            .textCase(.uppercase)
                    }
                    
                    Text(product.title)
                        .font(.system(size: 14, weight: .semibold)) // Smaller title
                        .foregroundColor(adaptiveColors.textPrimary)
                        .lineLimit(2)
                    
                    HStack {
                        // Price
                        VStack(alignment: .leading, spacing: 2) {
                            Text(product.price.displayAmount)
                                .font(.system(size: 16, weight: .bold)) // Adjusted price size
                                .foregroundColor(adaptiveColors.priceColor)
                            
                            if let compareAtAmount = product.price.displayCompareAtAmount {
                                Text(compareAtAmount)
                                    .font(.system(size: 12, weight: .regular)) // Smaller compare price
                                    .foregroundColor(adaptiveColors.textSecondary)
                                    .strikethrough()
                            } else {
                                // Spacer to maintain consistent height
                                Text("")
                                    .font(.system(size: 12, weight: .regular))
                                    .opacity(0)
                            }
                        }
                        .frame(minHeight: 32)  // Fixed minimum height for consistent card sizes
                        
                        if showAddToCartButton {
                            Spacer()
                            
                            // Add to Cart Button (only shown if showAddToCartButton is true)
                            Button(action: {
                                // Handle add to cart - prevent tap propagation to card
                                // TODO: Add actual cart functionality if needed
                            }) {
                                RButton(
                                    title: RLocalizedString(ReachuTranslationKey.addToCart.rawValue),
                                    style: .primary,
                                    size: .medium,
                                    isLoading: false
                                ) {
                                    // Empty - action handled by Button wrapper
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(ReachuSpacing.md)
            }
            .background(adaptiveColors.surface)
            .cornerRadius(ReachuBorderRadius.large)
            .reachuCardShadow(for: colorScheme)
            .padding(.horizontal, ReachuSpacing.md)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    /// Horizontal product card layout (image left, description right)
    private func horizontalProductCardView(product: Product) -> some View {
        Button(action: {
            // Handle tap - show product detail
            showingProductDetail = product
        }) {
            HStack(spacing: ReachuSpacing.sm) { // Reduced spacing
                // Image on the left (smaller)
                if let imageUrl = product.images.first?.url, let url = URL(string: imageUrl) {
                    LoadedImage(
                        url: url,
                        placeholder: AnyView(RoundedRectangle(cornerRadius: ReachuBorderRadius.medium)
                            .fill(adaptiveColors.surfaceSecondary)
                            .frame(width: 90, height: 90)
                            .overlay { ProgressView().tint(adaptiveColors.primary) }),
                        errorView: AnyView(RoundedRectangle(cornerRadius: ReachuBorderRadius.medium)
                            .fill(adaptiveColors.surfaceSecondary)
                            .frame(width: 90, height: 90)
                            .overlay {
                                Image(systemName: "photo")
                                    .foregroundColor(adaptiveColors.textSecondary)
                            })
                    )
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 90, height: 90)
                    .clipped()
                    .cornerRadius(ReachuBorderRadius.medium)
                } else {
                    RoundedRectangle(cornerRadius: ReachuBorderRadius.medium)
                        .fill(adaptiveColors.surfaceSecondary)
                        .frame(width: 90, height: 90) // Reduced image size
                }
                
                // Description on the right
                VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
                    Text(product.title)
                        .font(.system(size: 13, weight: .semibold)) // Smaller title
                        .foregroundColor(adaptiveColors.textPrimary)
                        .lineLimit(2)
                    
                    if let brand = product.brand {
                        Text(brand)
                            .font(.system(size: 10, weight: .regular)) // Smaller brand
                            .foregroundColor(adaptiveColors.textSecondary)
                            .lineLimit(1)
                    }
                    
                    // Price (moved up, right after brand)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(product.price.displayAmount)
                            .font(.system(size: 14, weight: .bold)) // Smaller price
                            .foregroundColor(adaptiveColors.priceColor)
                        
                        if let compareAtAmount = product.price.displayCompareAtAmount {
                            Text(compareAtAmount)
                                .font(.system(size: 11, weight: .regular)) // Smaller compare price
                                .foregroundColor(adaptiveColors.textSecondary)
                                .strikethrough()
                        } else {
                            // Spacer to maintain consistent height
                            Text("")
                                .font(.system(size: 11, weight: .regular))
                                .opacity(0)
                        }
                    }
                    .frame(minHeight: 28)  // Fixed minimum height for consistent card sizes
                    
                    Spacer() // Push everything to top
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(ReachuSpacing.sm) // Reduced padding
            .background(adaptiveColors.surface)
            .cornerRadius(ReachuBorderRadius.large)
            .reachuCardShadow(for: colorScheme)
        }
        .buttonStyle(PlainButtonStyle())
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
                loadProductsIfNeeded()
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
            let cardHeight = cardWidth * 1.3 // Balanced aspect ratio (approximately 3:4)
            
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
        .aspectRatio(1.0 / 1.3, contentMode: .fit) // Maintain balanced aspect ratio
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
        // Update cached config first
        updateCachedConfigIfNeeded()
        
        if shouldShow {
            loadProductsIfNeeded()
        } else {
            stopAutoScroll()
            viewModel.products = []
        }
    }
    
    private func handleComponentChange() {
        // Update cached config first
        updateCachedConfigIfNeeded()
        
        if shouldShow {
            loadProductsIfNeeded()
        } else {
            stopAutoScroll()
            viewModel.products = []
        }
    }
    
    /// Load products if config is available, otherwise wait for config
    private func loadProductsIfNeeded() {
        // If we have cached config, load products immediately
        if let cachedConfig = cachedConfig {
            loadProducts(with: cachedConfig)
        } else if config != nil {
            // Config exists but cachedConfig not created yet - update cache and load
            updateCachedConfigIfNeeded()
            if let cachedConfig = cachedConfig {
                loadProducts(with: cachedConfig)
            }
        } else {
            // No config yet - clear products and wait
            viewModel.products = []
        }
    }
    
    private func loadProducts(with cachedConfig: CachedConfig) {
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
              viewModel.products.count > 1 else {
            return
        }
        
        stopAutoScroll()
        
        // Use cached interval (already converted to TimeInterval)
        let productCount = viewModel.products.count
        guard productCount > 0 else { return }
        
        // Store references safely
        let timerProxy = proxy
        let viewModelRef = viewModel
        
        autoScrollTimer = Timer.scheduledTimer(withTimeInterval: cachedConfig.autoPlayInterval, repeats: true) { timer in
            // Access must be on main thread
            Task { @MainActor in
                guard viewModelRef.products.count > 0 else {
                    timer.invalidate()
                    return
                }
                
                let currentCount = viewModelRef.products.count
                guard currentCount > 0 else { return }
                
                withAnimation(.easeInOut(duration: 0.5)) {
                    // Update index through ViewModel (safe)
                    let nextIndex = (viewModelRef.currentIndex + 1) % currentCount
                    viewModelRef.currentIndex = nextIndex
                    timerProxy.scrollTo(nextIndex, anchor: .leading)
                }
            }
        }
    }
    
    private func stopAutoScroll() {
        autoScrollTimer?.invalidate()
        autoScrollTimer = nil
    }
    
    /// Page indicators (dots) for carousel
    private var pageIndicators: some View {
        HStack(spacing: ReachuSpacing.xs) {
            ForEach(0..<viewModel.products.count, id: \.self) { index in
                Circle()
                    .fill(index == viewModel.currentIndex ? adaptiveColors.primary : adaptiveColors.textSecondary.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .animation(.easeInOut(duration: 0.2), value: viewModel.currentIndex)
            }
        }
        .padding(.vertical, ReachuSpacing.xs)
    }
    
    /// Page indicators for full layout (tighter spacing)
    private var pageIndicatorsFull: some View {
        HStack(spacing: 4) { // Fixed smaller spacing for full layout
            ForEach(0..<viewModel.products.count, id: \.self) { index in
                Circle()
                    .fill(index == viewModel.currentIndex ? adaptiveColors.primary : adaptiveColors.textSecondary.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .animation(.easeInOut(duration: 0.2), value: viewModel.currentIndex)
            }
        }
        .padding(.vertical, ReachuSpacing.xs)
    }
}

// MARK: - ViewModel

@MainActor
class RProductCarouselViewModel: ObservableObject {
    
    @Published var products: [Product] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isMarketUnavailable: Bool = false
    @Published var currentIndex: Int = 0 // Move currentIndex to ViewModel for safe Timer access
    
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
        let idsToUse: [Int]? = productIds.isEmpty ? nil : productIds
        
        do {
            // Use ProductService to load products
            products = try await ProductService.shared.loadProducts(
                productIds: idsToUse,
                currency: currency,
                country: country
            )
            
            if products.isEmpty {
                ReachuLogger.warning("No products found - Currency: \(currency), Country: \(country)", component: "RProductCarousel")
            }
            
        } catch ProductServiceError.invalidConfiguration(let message) {
            errorMessage = message
            ReachuLogger.error("Invalid configuration: \(message)", component: "RProductCarousel")
        } catch ProductServiceError.sdkError(let error) {
            if error.code == "NOT_FOUND" || error.status == 404 {
                isMarketUnavailable = true
                errorMessage = nil
                ReachuLogger.warning("Market not available", component: "RProductCarousel")
            } else {
                errorMessage = error.message
                ReachuLogger.error("Failed to load products: \(error.message)", component: "RProductCarousel")
            }
        } catch ProductServiceError.networkError(let error) {
            errorMessage = error.localizedDescription
            ReachuLogger.error("Network error: \(error.localizedDescription)", component: "RProductCarousel")
        } catch {
            errorMessage = error.localizedDescription
            ReachuLogger.error("Failed to load products: \(error.localizedDescription)", component: "RProductCarousel")
        }
        
        isLoading = false
    }
}

// MARK: - Scroll Offset Preference Key

private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

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


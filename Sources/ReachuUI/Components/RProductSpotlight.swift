import SwiftUI
import ReachuCore
import ReachuUI
import ReachuDesignSystem

#if os(iOS)
import UIKit
#endif

/// Auto-configured Product Spotlight component
/// Automatically loads configuration from active campaign
/// 
/// **Usage:**
/// ```swift
/// // Basic usage - uses first product_spotlight component from backend
/// RProductSpotlight()
///
/// // Specific component ID - uses a specific product_spotlight component
/// RProductSpotlight(componentId: "product-spotlight-1")
/// RProductSpotlight(componentId: "product-spotlight-2")
/// ```
///
/// **Parameters:**
/// - `componentId: String?` - Optional component ID to identify a specific component. If `nil`, uses the first matching component.
/// - `variant: RProductCard.Variant?` - Optional card variant override. Options: `.grid`, `.list`, `.hero`, `.minimal`. If `nil`, uses `.hero` (default).
/// - `showAddToCartButton: Bool` - Whether to show the "Add to Cart" button in hero variant. Default: `true`. Button only shows if product has no variants.
///
/// **Backend Configuration (from API):**
/// The component reads configuration from `GET /api/campaigns/{campaignId}/components`:
/// ```json
/// {
///   "components": [{
///     "componentId": "product-spotlight-1",
///     "status": "active",
///     "customConfig": {
///       "productId": "408841",
///       "highlightText": "Feature Product"
///     }
///   }]
/// }
/// ```
///
/// **Configuration Properties:**
/// - `productId: String` - Product ID to display
/// - `highlightText: String?` - Optional text to display as a badge/highlight
///
/// **Features:**
/// - ✅ Skeleton loader while loading
/// - ✅ Multiple card variants (hero, grid, list, minimal)
/// - ✅ Highlight badge with custom text
/// - ✅ Clickable card opens product detail overlay
public struct RProductSpotlight: View {
    
    // MARK: - Properties
    
    /// Optional component ID to identify a specific component
    /// If nil, uses the first matching component from the campaign
    private let componentId: String?
    
    /// Optional card variant override for demo/testing
    /// If nil, uses .hero (default)
    private let variant: RProductCard.Variant?
    
    /// Whether to show the "Add to Cart" button in hero variant
    /// Default: true. Button only shows if product has no variants.
    private let showAddToCartButton: Bool
    
    @ObservedObject private var campaignManager = CampaignManager.shared
    @StateObject private var viewModel = RProductSpotlightViewModel()
    
    @SwiftUI.Environment(\.colorScheme) private var colorScheme: SwiftUI.ColorScheme
    @EnvironmentObject private var cartManager: CartManager
    
    @State private var showingProductDetail: Product?
    
    // Cache parsed config values - only recalculated when config changes
    @State private var cachedProductId: String?
    @State private var cachedHighlightText: String?
    @State private var currentConfigId: String?
    
    // Computed colors based on current color scheme
    private var adaptiveColors: AdaptiveColors {
        ReachuColors.adaptive(for: colorScheme)
    }
    
    // MARK: - Initializer
    
    public init(componentId: String? = nil, variant: RProductCard.Variant? = nil, showAddToCartButton: Bool = true) {
        self.componentId = componentId
        self.variant = variant
        self.showAddToCartButton = showAddToCartButton
    }
    
    // MARK: - Computed Properties
    
    /// Get active product spotlight component from campaign
    private var activeComponent: Component? {
        campaignManager.getActiveComponent(type: "product_spotlight", componentId: componentId)
    }
    
    /// Extract ProductSpotlightConfig from component
    private var config: ProductSpotlightConfig? {
        guard let component = activeComponent,
              case .productSpotlight(let config) = component.config else {
            return nil
        }
        return config
    }
    
    /// Update cached config when config changes
    private func updateCachedConfigIfNeeded() {
        guard let config = config else {
            if cachedProductId != nil {
                cachedProductId = nil
                cachedHighlightText = nil
                currentConfigId = nil
            }
            return
        }
        
        let newConfigId = "\(config.productId)-\(config.highlightText ?? "")"
        
        // Only recalculate if config actually changed
        if currentConfigId != newConfigId {
            cachedProductId = config.productId
            cachedHighlightText = config.highlightText
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
            } else if let config = config {
                if shouldShowLoading {
                    skeletonView
                } else if shouldShowError {
                    errorView
                } else if let product = product {
                    spotlightContentView(product: product, highlightText: cachedHighlightText)
                } else {
                    emptyStateView
                }
            }
        }
        .onAppear {
            updateCachedConfigIfNeeded()
            loadProductIfNeeded()
        }
        .onChange(of: campaignManager.activeComponents.count) { _ in
            updateCachedConfigIfNeeded()
            loadProductIfNeeded()
        }
        .onChange(of: cachedProductId) { _ in
            loadProductIfNeeded()
        }
        .task {
            // Small delay to ensure campaign components are loaded
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            updateCachedConfigIfNeeded()
            loadProductIfNeeded()
        }
    }
    
    // MARK: - Content Views
    
    /// Main spotlight content view with product card and highlight badge
    private func spotlightContentView(product: Product, highlightText: String?) -> some View {
        VStack(spacing: ReachuSpacing.md) {
            // Highlight badge (if provided) - only show for hero variant
            if let highlightText = highlightText, !highlightText.isEmpty, variant == nil || variant == .hero {
                Text(highlightText)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(adaptiveColors.surface)
                    .padding(.horizontal, ReachuSpacing.md)
                    .padding(.vertical, ReachuSpacing.xs)
                    .background(
                        Capsule()
                            .fill(adaptiveColors.primary)
                    )
                    .padding(.horizontal, ReachuSpacing.md)
            }
            
            // Use custom hero layout if hero variant, otherwise use RProductCard
            if variant == nil || variant == .hero {
                customHeroLayout(product: product)
                    .padding(.horizontal, ReachuSpacing.md)
            } else {
                // For other variants, use RProductCard directly
                RProductCard(
                    product: product,
                    variant: variant!,
                    showBrand: ReachuConfiguration.shared.uiConfiguration.showProductBrands,
                    showDescription: ReachuConfiguration.shared.uiConfiguration.showProductDescriptions,
                    showProductDetail: true
                )
                .padding(.horizontal, ReachuSpacing.md)
            }
        }
    }
    
    /// Custom hero layout with smaller fonts and conditional Add to Cart button
    private func customHeroLayout(product: Product) -> some View {
        Button(action: {
            showingProductDetail = product
        }) {
            VStack(alignment: .leading, spacing: ReachuSpacing.md) {
                // Large Product Images with pagination
                productImagesView(product: product, height: 300)
                
                VStack(alignment: .leading, spacing: ReachuSpacing.sm) {
                    if ReachuConfiguration.shared.uiConfiguration.showProductBrands, let brand = product.brand {
                        Text(brand)
                            .font(.system(size: 11, weight: .medium)) // Smaller than default
                            .foregroundColor(adaptiveColors.textSecondary)
                            .textCase(.uppercase)
                    }
                    
                    Text(product.title)
                        .font(.system(size: 18, weight: .semibold)) // Smaller than ReachuTypography.title2
                        .foregroundColor(adaptiveColors.textPrimary)
                        .lineLimit(3)
                    
                    if ReachuConfiguration.shared.uiConfiguration.showProductDescriptions, let description = product.description {
                        Text(description)
                            .font(.system(size: 14, weight: .regular)) // Smaller than ReachuTypography.body
                            .foregroundColor(adaptiveColors.textSecondary)
                            .lineLimit(3)
                    }
                    
                    HStack {
                        // Price
                        VStack(alignment: .leading, spacing: 2) {
                            Text(product.price.displayAmount)
                                .font(.system(size: 18, weight: .semibold)) // Smaller than ReachuTypography.title3
                                .foregroundColor(adaptiveColors.primary)
                            
                            if let compareAtAmount = product.price.displayCompareAtAmount {
                                Text(compareAtAmount)
                                    .font(.system(size: 14, weight: .regular)) // Smaller than ReachuTypography.caption1
                                    .foregroundColor(adaptiveColors.textSecondary)
                                    .strikethrough()
                            }
                        }
                        
                        Spacer()
                        
                        // Add to Cart button - only show if no variants and showAddToCartButton is true
                        if showAddToCartButton && product.variants.isEmpty && (product.quantity ?? 0) > 0 {
                            Button(action: {
                                // Stop propagation to parent button
                                Task {
                                    await cartManager.addProduct(product, quantity: 1)
                                }
                            }) {
                                Text(RLocalizedString(ReachuTranslationKey.addToCart.rawValue))
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(adaptiveColors.surface)
                                    .padding(.horizontal, ReachuSpacing.md)
                                    .padding(.vertical, ReachuSpacing.sm)
                                    .background(adaptiveColors.primary)
                                    .cornerRadius(ReachuBorderRadius.medium)
                            }
                            .buttonStyle(PlainButtonStyle()) // Prevent double tap
                        }
                    }
                }
                .padding(ReachuSpacing.md) // Smaller padding than ReachuSpacing.lg
            }
            .background(adaptiveColors.surface)
            .cornerRadius(ReachuBorderRadius.xl)
            .reachuCardShadow(for: colorScheme)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(item: $showingProductDetail) { product in
            RProductDetailOverlay(
                product: product,
                onDismiss: {
                    showingProductDetail = nil
                }
            )
        }
    }
    
    /// Product images view with pagination support
    private func productImagesView(product: Product, height: CGFloat) -> some View {
        let sortedImages = product.images.sorted { first, second in
            let firstPriority = (first.order == 0 || first.order == 1) ? first.order : Int.max
            let secondPriority = (second.order == 0 || second.order == 1) ? second.order : Int.max
            if firstPriority != secondPriority {
                return firstPriority < secondPriority
            }
            return first.order < second.order
        }
        
        let primaryImageUrl = sortedImages.first?.url
        
        return VStack(spacing: 0) {
            if sortedImages.count > 1 {
                TabView {
                    ForEach(sortedImages, id: \.id) { image in
                        productImageView(imageUrl: image.url, height: height)
                            .tag(image.id)
                    }
                }
#if os(iOS) || os(tvOS) || os(watchOS)
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
#endif
                .frame(height: height)
            } else {
                productImageView(imageUrl: primaryImageUrl, height: height)
            }
        }
        .cornerRadius(ReachuBorderRadius.medium)
    }
    
    /// Single product image view
    private func productImageView(imageUrl: String?, height: CGFloat) -> some View {
        let imageURL = URL(string: imageUrl ?? "")
        
        return AsyncImage(url: imageURL) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            case .failure(_):
                Rectangle()
                    .fill(adaptiveColors.background)
                    .overlay(
                        VStack(spacing: ReachuSpacing.xs) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.title2)
                                .foregroundColor(adaptiveColors.error)
                            Text(RLocalizedString(ReachuTranslationKey.noImageAvailable.rawValue))
                                .font(ReachuTypography.caption1)
                                .foregroundColor(adaptiveColors.error)
                        }
                    )
            case .empty:
                Rectangle()
                    .fill(adaptiveColors.background)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.title2)
                            .foregroundColor(adaptiveColors.textSecondary)
                    )
            @unknown default:
                Rectangle()
                    .fill(adaptiveColors.background)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.title2)
                            .foregroundColor(adaptiveColors.textSecondary)
                    )
            }
        }
        .frame(height: height)
        .clipped()
        .cornerRadius(ReachuBorderRadius.medium)
    }
    
    // MARK: - Skeleton View
    
    /// Skeleton loader shown while product is loading
    private var skeletonView: some View {
        VStack(spacing: ReachuSpacing.md) {
            // Highlight badge skeleton
            RoundedRectangle(cornerRadius: ReachuBorderRadius.circle)
                .fill(adaptiveColors.surfaceSecondary.opacity(0.6))
                .frame(width: 120, height: 28)
                .padding(.horizontal, ReachuSpacing.md)
                .shimmerEffect()
            
            // Hero card skeleton
            VStack(spacing: ReachuSpacing.lg) {
                // Image skeleton
                RoundedRectangle(cornerRadius: ReachuBorderRadius.medium)
                    .fill(adaptiveColors.surfaceSecondary.opacity(0.6))
                    .frame(height: 300)
                    .shimmerEffect()
                
                // Content skeleton
                VStack(alignment: .leading, spacing: ReachuSpacing.sm) {
                    // Brand skeleton
                    RoundedRectangle(cornerRadius: ReachuBorderRadius.small)
                        .fill(adaptiveColors.surfaceSecondary.opacity(0.6))
                        .frame(width: 100, height: 12)
                        .shimmerEffect()
                    
                    // Title skeleton
                    RoundedRectangle(cornerRadius: ReachuBorderRadius.small)
                        .fill(adaptiveColors.surfaceSecondary.opacity(0.6))
                        .frame(height: 20)
                        .shimmerEffect()
                    
                    RoundedRectangle(cornerRadius: ReachuBorderRadius.small)
                        .fill(adaptiveColors.surfaceSecondary.opacity(0.6))
                        .frame(width: 200, height: 20)
                        .shimmerEffect()
                    
                    // Description skeleton
                    RoundedRectangle(cornerRadius: ReachuBorderRadius.small)
                        .fill(adaptiveColors.surfaceSecondary.opacity(0.6))
                        .frame(height: 14)
                        .shimmerEffect()
                    
                    RoundedRectangle(cornerRadius: ReachuBorderRadius.small)
                        .fill(adaptiveColors.surfaceSecondary.opacity(0.6))
                        .frame(width: 250, height: 14)
                        .shimmerEffect()
                    
                    // Price and button skeleton
                    HStack {
                        RoundedRectangle(cornerRadius: ReachuBorderRadius.small)
                            .fill(adaptiveColors.surfaceSecondary.opacity(0.6))
                            .frame(width: 80, height: 24)
                            .shimmerEffect()
                        
                        Spacer()
                        
                        RoundedRectangle(cornerRadius: ReachuBorderRadius.medium)
                            .fill(adaptiveColors.surfaceSecondary.opacity(0.6))
                            .frame(width: 120, height: 44)
                            .shimmerEffect()
                    }
                }
                .padding(ReachuSpacing.lg)
            }
            .background(adaptiveColors.surface)
            .cornerRadius(ReachuBorderRadius.xl)
            .reachuCardShadow(for: colorScheme)
            .padding(.horizontal, ReachuSpacing.md)
        }
        .padding(.vertical, ReachuSpacing.md)
    }
    
    // MARK: - Error & Empty States
    
    private var errorView: some View {
        VStack(spacing: ReachuSpacing.sm) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 32))
                .foregroundColor(adaptiveColors.error)
            
            Text("Error loading product")
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
                loadProductIfNeeded()
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
        .padding(.horizontal, ReachuSpacing.md)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: ReachuSpacing.sm) {
            Image(systemName: "photo")
                .font(.system(size: 32))
                .foregroundColor(adaptiveColors.textSecondary)
            
            Text("Product not available")
                .font(ReachuTypography.bodyBold)
                .foregroundColor(adaptiveColors.textPrimary)
            
            Text("The product will appear here when available")
                .font(ReachuTypography.caption1)
                .foregroundColor(adaptiveColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, ReachuSpacing.lg)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, ReachuSpacing.xl)
        .padding(.horizontal, ReachuSpacing.md)
    }
    
    // MARK: - Helper Methods
    
    /// Load product if needed
    private func loadProductIfNeeded() {
        guard let productIdString = cachedProductId,
              let productId = Int(productIdString) else {
            return
        }
        
        let currency = ReachuConfiguration.shared.marketConfiguration.currencyCode
        let country = ReachuConfiguration.shared.marketConfiguration.countryCode
        
        Task {
            await viewModel.loadProduct(
                productId: productId,
                currency: currency,
                country: country
            )
        }
    }
}

// MARK: - View Model

/// ViewModel for RProductSpotlight
@MainActor
private class RProductSpotlightViewModel: ObservableObject {
    @Published var product: Product?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isMarketUnavailable: Bool = false
    
    func loadProduct(productId: Int, currency: String, country: String) async {
        guard ReachuConfiguration.shared.shouldUseSDK else {
            isMarketUnavailable = true
            isLoading = false
            return
        }
        
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        isMarketUnavailable = false
        
        do {
            // Use ProductService to load product
            product = try await ProductService.shared.loadProduct(
                productId: productId,
                currency: currency,
                country: country
            )
            
        } catch ProductServiceError.productNotFound(let id) {
            errorMessage = "Product not found"
            ReachuLogger.warning("Product not found for ID: \(id) - Currency: \(currency), Country: \(country)", component: "RProductSpotlight")
        } catch ProductServiceError.invalidConfiguration(let message) {
            errorMessage = "Invalid configuration"
            ReachuLogger.error("Invalid configuration: \(message)", component: "RProductSpotlight")
        } catch ProductServiceError.sdkError(let error) {
            if error.code == "NOT_FOUND" || error.status == 404 {
                isMarketUnavailable = true
                errorMessage = nil
                ReachuLogger.warning("Market not available", component: "RProductSpotlight")
            } else {
                errorMessage = error.message ?? "Failed to load product"
                ReachuLogger.error("Error loading product: \(error.message ?? "Unknown error")", component: "RProductSpotlight")
            }
        } catch {
            errorMessage = "Failed to load product"
            ReachuLogger.error("Unexpected error: \(error.localizedDescription)", component: "RProductSpotlight")
        }
        
        isLoading = false
    }
}

// MARK: - Shimmer Effect Modifier

/// Shimmer effect modifier for skeleton loaders
private struct ShimmerEffectModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.clear,
                            ReachuColors.adaptive(for: .light).textPrimary.opacity(0.5),
                            Color.clear
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: -geometry.size.width + phase * geometry.size.width * 2)
                }
            )
            .onAppear {
                withAnimation(
                    Animation.linear(duration: 1.5)
                        .repeatForever(autoreverses: false)
                ) {
                    phase = 1.0
                }
            }
    }
}

private extension View {
    func shimmerEffect() -> some View {
        modifier(ShimmerEffectModifier())
    }
}


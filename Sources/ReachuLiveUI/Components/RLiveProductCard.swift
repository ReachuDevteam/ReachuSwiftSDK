import SwiftUI
import ReachuCore
import ReachuLiveShow
import ReachuDesignSystem
import ReachuUI

/// Live Product Card component - horizontal layout with full configuration integration
public struct RLiveProductCard: View {
    
    // MARK: - Properties
    private let product: LiveProduct
    
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var cartManager: CartManager
    @State private var showProductDetail = false
    
    // Configuration
    private var config: ReachuConfiguration { ReachuConfiguration.shared }
    private var theme: ReachuTheme { config.theme }
    private var uiConfig: UIConfiguration { config.uiConfiguration }
    
    // Colors based on theme and color scheme
    private var adaptiveColors: AdaptiveColors {
        ReachuColors.adaptive(for: colorScheme)
    }
    
    // Convert LiveProduct to Product for detail overlay
    private var productForDetail: Product {
        product.asProduct
    }
    
    public init(product: LiveProduct) {
        self.product = product
    }
    
    // MARK: - Body
    public var body: some View {
        HStack(spacing: ReachuSpacing.sm) {
            // Product image (smaller)
            productImage
            
            // Product info (compact)
            productInfo
            
            // Live indicator only
            liveIndicator
        }
        .padding(ReachuSpacing.sm)
        .background(backgroundView)
        .overlay(borderView)
        .cornerRadius(theme.borderRadius.medium)
        .onTapGesture {
            showProductDetail = true
        }
        .sheet(isPresented: $showProductDetail) {
            RProductDetailOverlay(
                product: productForDetail,
                onAddToCart: { product in
                    // Handle add to cart from detail overlay
                    Task {
                        await cartManager.addProduct(product, quantity: 1)
                    }
                }
            )
            .environmentObject(cartManager)
        }
    }
    
    // MARK: - Product Image
    
    @ViewBuilder
    private var productImage: some View {
        AsyncImage(url: URL(string: product.imageUrl)) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            Rectangle()
                .fill(adaptiveColors.surfaceSecondary)
                .overlay(
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: adaptiveColors.primary))
                        .scaleEffect(0.8)
                )
        }
        .frame(width: 60, height: 60)
        .cornerRadius(theme.borderRadius.small)
        .clipped()
    }
    
    // MARK: - Product Info
    
    @ViewBuilder
    private var productInfo: some View {
        VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
            // Product title (smaller)
            Text(product.title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(adaptiveColors.textPrimary)
                .lineLimit(1)
                .multilineTextAlignment(.leading)
            
            // Brand name (smaller)
            Text("COSMED BEAUTY")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(adaptiveColors.textSecondary)
                .lineLimit(1)
            
            // Price section (compact)
            priceSection
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Price Section
    
    @ViewBuilder
    private var priceSection: some View {
        HStack(spacing: ReachuSpacing.xs) {
            // Current price (smaller)
            Text(product.price.formattedPrice)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.red)
            
            // Original price (strikethrough, smaller)
            if let originalPrice = product.originalPrice {
                Text(originalPrice.formattedPrice)
                    .font(.system(size: 12))
                    .foregroundColor(adaptiveColors.textTertiary)
                    .strikethrough()
            }
            
            Spacer()
        }
    }
    
    // MARK: - Live Indicator
    
    @ViewBuilder
    private var liveIndicator: some View {
        VStack {
            Circle()
                .fill(.red)
                .frame(width: 8, height: 8)
            
            Spacer()
        }
    }
    
    // MARK: - Background & Border
    
    @ViewBuilder
    private var backgroundView: some View {
        Rectangle()
            .fill(adaptiveColors.surface.opacity(0.9))
    }
    
    @ViewBuilder
    private var borderView: some View {
        if uiConfig.enableProductCardAnimations {
            Rectangle()
                .stroke(adaptiveColors.border, lineWidth: 1)
        } else {
            Rectangle()
                .stroke(Color.clear, lineWidth: 0)
        }
    }
    
    // Actions removed - now handled by RProductDetailOverlay
}

// MARK: - Preview

#Preview("Light Mode") {
    VStack(spacing: 20) {
        RLiveProductCard(product: DemoProductData.featuredProducts[0])
            .environmentObject(CartManager())
        
        RLiveProductCard(product: DemoProductData.featuredProducts[1])
            .environmentObject(CartManager())
    }
    .padding()
    .background(Color.black.opacity(0.8))
}

#Preview("Dark Mode") {
    VStack(spacing: 20) {
        RLiveProductCard(product: DemoProductData.featuredProducts[0])
            .environmentObject(CartManager())
        
        RLiveProductCard(product: DemoProductData.featuredProducts[1])
            .environmentObject(CartManager())
    }
    .padding()
    .background(Color.black.opacity(0.8))
    .preferredColorScheme(.dark)
}

import SwiftUI
import ReachuCore
import ReachuLiveShow
import ReachuDesignSystem
import ReachuUI

/// Live Product Card component - horizontal layout with full configuration integration
public struct RLiveProductCard: View {
    
    // MARK: - Properties
    private let product: LiveProduct
    private let onAddToCart: (LiveProduct) -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    // Configuration
    private var config: ReachuConfiguration { ReachuConfiguration.shared }
    private var theme: ReachuTheme { config.theme }
    private var uiConfig: UIConfiguration { config.uiConfiguration }
    
    // Colors based on theme and color scheme
    private var adaptiveColors: AdaptiveColors {
        ReachuColors.adaptive(for: colorScheme)
    }
    
    public init(
        product: LiveProduct,
        onAddToCart: @escaping (LiveProduct) -> Void
    ) {
        self.product = product
        self.onAddToCart = onAddToCart
    }
    
    // MARK: - Body
    public var body: some View {
        HStack(spacing: ReachuSpacing.md) {
            // Product image
            productImage
            
            // Product info (expanded)
            productInfo
            
            // Action section
            actionSection
        }
        .padding(ReachuSpacing.md)
        .background(backgroundView)
        .overlay(borderView)
        .cornerRadius(theme.borderRadius.medium)
        .shadow(
            color: uiConfig.enableProductCardAnimations ? 
                Color.black.opacity(0.1) : Color.clear,
            radius: 4,
            x: 0,
            y: 2
        )
        .onTapGesture {
            handleTap()
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
        .frame(width: 80, height: 80)
        .cornerRadius(theme.borderRadius.small)
        .clipped()
    }
    
    // MARK: - Product Info
    
    @ViewBuilder
    private var productInfo: some View {
        VStack(alignment: .leading, spacing: ReachuSpacing.sm) {
            // Product title
            Text(product.title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(adaptiveColors.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            // Brand name
            Text("COSMED BEAUTY")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(adaptiveColors.textSecondary)
                .lineLimit(1)
            
            // Price section
            priceSection
            
            // Special offer or discount
            if let specialOffer = product.specialOffer, !specialOffer.isEmpty {
                Text(specialOffer)
                    .font(.system(size: 11))
                    .foregroundColor(adaptiveColors.textTertiary)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Price Section
    
    @ViewBuilder
    private var priceSection: some View {
        HStack(spacing: ReachuSpacing.sm) {
            // Current price
            Text(product.price.formattedPrice)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.red)
            
            // Original price (strikethrough)
            if let originalPrice = product.originalPrice {
                Text(originalPrice.formattedPrice)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(adaptiveColors.textTertiary)
                    .strikethrough()
            }
            
            // Discount badge
            if let discount = product.discount, !discount.isEmpty {
                Text(discount)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(.red)
                    )
            }
            
            Spacer()
        }
    }
    
    // MARK: - Action Section
    
    @ViewBuilder
    private var actionSection: some View {
        VStack(spacing: ReachuSpacing.sm) {
            // Stock indicator
            if let stockCount = product.stockCount, stockCount <= 10 {
                Text("\(stockCount) left")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.orange)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color.orange.opacity(0.2))
                    )
            }
            
            // Add to cart button
            Button {
                handleTap()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 14))
                    Text("Add")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, ReachuSpacing.md)
                .padding(.vertical, ReachuSpacing.sm)
                .background(
                    Capsule()
                        .fill(adaptiveColors.primary)
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // Live indicator
            HStack(spacing: 4) {
                Circle()
                    .fill(.red)
                    .frame(width: 6, height: 6)
                Text("LIVE")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.red)
            }
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
    
    // MARK: - Actions
    
    private func handleTap() {
        onAddToCart(product)
        
        // Haptic feedback if enabled
        if uiConfig.enableHapticFeedback {
            #if os(iOS)
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            #endif
        }
    }
}

// MARK: - Preview

#Preview("Light Mode") {
    VStack(spacing: 20) {
        RLiveProductCard(
            product: DemoProductData.featuredProducts[0]
        ) { product in
            print("Added to cart: \(product.title)")
        }
        
        RLiveProductCard(
            product: DemoProductData.featuredProducts[1]
        ) { product in
            print("Added to cart: \(product.title)")
        }
    }
    .padding()
    .background(Color.black.opacity(0.8))
}

#Preview("Dark Mode") {
    VStack(spacing: 20) {
        RLiveProductCard(
            product: DemoProductData.featuredProducts[0]
        ) { product in
            print("Added to cart: \(product.title)")
        }
        
        RLiveProductCard(
            product: DemoProductData.featuredProducts[1]
        ) { product in
            print("Added to cart: \(product.title)")
        }
    }
    .padding()
    .background(Color.black.opacity(0.8))
    .preferredColorScheme(.dark)
}

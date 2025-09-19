import SwiftUI
import ReachuCore
import ReachuDesignSystem

#if DEBUG
import ReachuTesting
#endif

/// Reachu Product Card Component
/// 
/// A flexible product card that adapts to different layouts and use cases.
/// Uses the modular design system for consistent styling.
///
/// **Usage:**
/// ```swift
/// // Basic usage (grid layout)
/// RProductCard(product: product)
///
/// // Different variants
/// RProductCard(product: product, variant: .list)
/// RProductCard(product: product, variant: .hero)
/// RProductCard(product: product, variant: .minimal)
/// 
/// // With customization
/// RProductCard(product: product, variant: .grid, showBrand: false)
/// ```
public struct RProductCard: View {
    
    // MARK: - Variant Types
    public enum Variant {
        case grid      // Default: Vertical layout for product grids
        case list      // Horizontal layout for search results
        case hero      // Large featured product display
        case minimal   // Compact for carousels/suggestions
    }
    
    // MARK: - Properties
    private let product: Product
    private let variant: Variant
    private let showBrand: Bool
    private let showDescription: Bool
    private let onTap: (() -> Void)?
    private let onAddToCart: (() -> Void)?
    
    // MARK: - Initializer
    public init(
        product: Product,
        variant: Variant = .grid,
        showBrand: Bool = true,
        showDescription: Bool = false,
        onTap: (() -> Void)? = nil,
        onAddToCart: (() -> Void)? = nil
    ) {
        self.product = product
        self.variant = variant
        self.showBrand = showBrand
        self.showDescription = showDescription
        self.onTap = onTap
        self.onAddToCart = onAddToCart
    }
    
    // MARK: - Body
    public var body: some View {
        Button(action: { onTap?() }) {
            switch variant {
            case .grid:
                gridLayout
            case .list:
                listLayout
            case .hero:
                heroLayout
            case .minimal:
                minimalLayout
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Layout Variants
    
    /// Grid Layout - Vertical card for product catalogs
    private var gridLayout: some View {
        VStack(alignment: .leading, spacing: ReachuSpacing.sm) {
            // Product Image
            productImage(height: 160)
            
            // Product Info
            VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
                if showBrand, let brand = product.brand {
                    Text(brand)
                        .font(ReachuTypography.caption1)
                        .foregroundColor(ReachuColors.textSecondary)
                        .lineLimit(1)
                }
                
                Text(product.title)
                    .font(ReachuTypography.headline)
                    .foregroundColor(ReachuColors.textPrimary)
                    .lineLimit(2)
                
                if showDescription, let description = product.description {
                    Text(description)
                        .font(ReachuTypography.caption1)
                        .foregroundColor(ReachuColors.textSecondary)
                        .lineLimit(2)
                }
                
                // Price and Action
                HStack {
                    priceView
                    Spacer()
                    addToCartButton
                }
            }
            .padding(ReachuSpacing.md)
        }
        .background(ReachuColors.surface)
        .cornerRadius(ReachuBorderRadius.large)
        .shadow(color: ReachuColors.textPrimary.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    /// List Layout - Horizontal card for search results
    private var listLayout: some View {
        HStack(spacing: ReachuSpacing.md) {
            // Product Image (smaller for list)
            productImage(height: 80)
                .frame(width: 80)
            
            // Product Info
            VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
                if showBrand, let brand = product.brand {
                    Text(brand)
                        .font(ReachuTypography.caption1)
                        .foregroundColor(ReachuColors.textSecondary)
                        .lineLimit(1)
                }
                
                Text(product.title)
                    .font(ReachuTypography.body)
                    .foregroundColor(ReachuColors.textPrimary)
                    .lineLimit(2)
                
                if showDescription, let description = product.description {
                    Text(description)
                        .font(ReachuTypography.caption1)
                        .foregroundColor(ReachuColors.textSecondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                HStack {
                    priceView
                    Spacer()
                    addToCartButton
                }
            }
            
            Spacer()
        }
        .padding(ReachuSpacing.md)
        .background(ReachuColors.surface)
        .cornerRadius(ReachuBorderRadius.medium)
        .shadow(color: ReachuColors.textPrimary.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    /// Hero Layout - Large featured product
    private var heroLayout: some View {
        VStack(alignment: .leading, spacing: ReachuSpacing.lg) {
            // Large Product Image
            productImage(height: 240)
            
            VStack(alignment: .leading, spacing: ReachuSpacing.sm) {
                if showBrand, let brand = product.brand {
                    Text(brand)
                        .font(ReachuTypography.caption1)
                        .foregroundColor(ReachuColors.textSecondary)
                        .textCase(.uppercase)
                }
                
                Text(product.title)
                    .font(ReachuTypography.title2)
                    .foregroundColor(ReachuColors.textPrimary)
                    .lineLimit(3)
                
                if showDescription, let description = product.description {
                    Text(description)
                        .font(ReachuTypography.body)
                        .foregroundColor(ReachuColors.textSecondary)
                        .lineLimit(3)
                }
                
                HStack {
                    priceView
                    Spacer()
                    RButton(title: "Add to Cart", style: .primary, size: .large) {
                        onAddToCart?()
                    }
                    .disabled(!isInStock)
                }
            }
            .padding(ReachuSpacing.lg)
        }
        .background(ReachuColors.surface)
        .cornerRadius(ReachuBorderRadius.xl)
        .shadow(color: ReachuColors.textPrimary.opacity(0.15), radius: 8, x: 0, y: 4)
    }
    
    /// Minimal Layout - Compact for carousels
    private var minimalLayout: some View {
        VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
            // Compact Product Image
            productImage(height: 100)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(product.title)
                    .font(ReachuTypography.caption1)
                    .foregroundColor(ReachuColors.textPrimary)
                    .lineLimit(2)
                
                priceView
            }
            .padding(ReachuSpacing.sm)
        }
        .frame(width: 120)
        .background(ReachuColors.surface)
        .cornerRadius(ReachuBorderRadius.medium)
        .shadow(color: ReachuColors.textPrimary.opacity(0.08), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Reusable Components
    
    private func productImage(height: CGFloat) -> some View {
        AsyncImage(url: URL(string: product.images.first?.url ?? "")) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            Rectangle()
                .fill(ReachuColors.background)
                .overlay(
                    Image(systemName: "photo")
                        .font(.title2)
                        .foregroundColor(ReachuColors.textSecondary)
                )
        }
        .frame(height: height)
        .clipped()
        .cornerRadius(ReachuBorderRadius.medium)
    }
    
    private var priceView: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(product.price.displayAmount)
                .font(variant == .hero ? ReachuTypography.title3 : ReachuTypography.body)
                .fontWeight(.semibold)
                .foregroundColor(ReachuColors.primary)
            
            if let compareAtAmount = product.price.displayCompareAtAmount {
                Text(compareAtAmount)
                    .font(ReachuTypography.caption1)
                    .foregroundColor(ReachuColors.textSecondary)
                    .strikethrough()
            }
        }
    }
    
    private var addToCartButton: some View {
        Group {
            if variant == .minimal {
                // No button in minimal variant
                EmptyView()
            } else if isInStock {
                RButton(
                    title: variant == .list ? "Add" : "Add to Cart",
                    style: .primary,
                    size: variant == .list ? .small : .medium
                ) {
                    onAddToCart?()
                }
            } else {
                Text("Out of Stock")
                    .font(ReachuTypography.caption1)
                    .foregroundColor(ReachuColors.error)
                    .padding(.horizontal, ReachuSpacing.sm)
                    .padding(.vertical, ReachuSpacing.xs)
                    .background(ReachuColors.error.opacity(0.1))
                    .cornerRadius(ReachuBorderRadius.small)
            }
        }
    }
    
    private var isInStock: Bool {
        (product.quantity ?? 0) > 0
    }
}

// MARK: - Previews

#Preview("Grid Variant") {
    VStack(spacing: ReachuSpacing.lg) {
        RProductCard(
            product: MockDataProvider.shared.sampleProducts[0],
            variant: .grid,
            onTap: { print("Product tapped") },
            onAddToCart: { print("Add to cart tapped") }
        )
    }
    .padding()
    .background(ReachuColors.background)
}

#Preview("List Variant") {
    VStack(spacing: ReachuSpacing.md) {
        ForEach(MockDataProvider.shared.sampleProducts.prefix(3)) { product in
            RProductCard(
                product: product,
                variant: .list,
                onTap: { print("Product \(product.title) tapped") },
                onAddToCart: { print("Add \(product.title) to cart") }
            )
        }
    }
    .padding()
    .background(ReachuColors.background)
}

#Preview("Hero Variant") {
    RProductCard(
        product: MockDataProvider.shared.sampleProducts[0],
        variant: .hero,
        showDescription: true,
        onTap: { print("Hero product tapped") },
        onAddToCart: { print("Hero add to cart") }
    )
    .padding()
    .background(ReachuColors.background)
}

#Preview("Minimal Variant") {
    ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: ReachuSpacing.sm) {
            ForEach(MockDataProvider.shared.sampleProducts) { product in
                RProductCard(
                    product: product,
                    variant: .minimal,
                    onTap: { print("Minimal product \(product.title) tapped") }
                )
            }
        }
        .padding(.horizontal)
    }
    .background(ReachuColors.background)
}

#Preview("All Variants Comparison") {
    ScrollView {
        VStack(spacing: ReachuSpacing.xl) {
            VStack(alignment: .leading) {
                Text("Grid Variant")
                    .font(ReachuTypography.headline)
                    .padding(.horizontal)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: ReachuSpacing.md) {
                    ForEach(MockDataProvider.shared.sampleProducts.prefix(2)) { product in
                        RProductCard(product: product, variant: .grid)
                    }
                }
                .padding(.horizontal)
            }
            
            VStack(alignment: .leading) {
                Text("List Variant")
                    .font(ReachuTypography.headline)
                    .padding(.horizontal)
                
                VStack(spacing: ReachuSpacing.sm) {
                    ForEach(MockDataProvider.shared.sampleProducts.prefix(2)) { product in
                        RProductCard(product: product, variant: .list)
                    }
                }
                .padding(.horizontal)
            }
            
            VStack(alignment: .leading) {
                Text("Hero Variant")
                    .font(ReachuTypography.headline)
                    .padding(.horizontal)
                
                RProductCard(
                    product: MockDataProvider.shared.sampleProducts[0],
                    variant: .hero,
                    showDescription: true
                )
                .padding(.horizontal)
            }
            
            VStack(alignment: .leading) {
                Text("Minimal Variant")
                    .font(ReachuTypography.headline)
                    .padding(.horizontal)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: ReachuSpacing.sm) {
                        ForEach(MockDataProvider.shared.sampleProducts) { product in
                            RProductCard(product: product, variant: .minimal)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding(.vertical)
    }
    .background(ReachuColors.background)
}

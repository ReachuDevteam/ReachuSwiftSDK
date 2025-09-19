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
            // Product Images with pagination
            productImagesView(height: 160, showPagination: sortedImages.count > 1)
            
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
            // Product Image (single image for list)
            productImageView(height: 80, width: 80)
            
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
            // Large Product Images with full pagination
            productImagesView(height: 300, showPagination: sortedImages.count > 1)
            
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
            // Compact Product Image (single image only)
            productImageView(height: 100, width: 120)
            
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
    
    // MARK: - Image Components
    
    /// Multiple images view with pagination for grid and hero variants
    private func productImagesView(height: CGFloat, showPagination: Bool) -> some View {
        VStack(spacing: 0) {
            if sortedImages.count > 1 && showPagination {
                // Multiple images with TabView for pagination
                TabView {
                    ForEach(sortedImages, id: \.id) { image in
                        productImageView(
                            height: height,
                            imageUrl: image.url
                        )
                        .tag(image.id)
                    }
                }
#if os(iOS) || os(tvOS) || os(watchOS)
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
#endif
                .frame(height: height)
            } else {
                // Single image or fallback
                productImageView(height: height)
            }
        }
        .cornerRadius(ReachuBorderRadius.medium)
    }
    
    /// Single image view with error handling and placeholders
    private func productImageView(height: CGFloat, width: CGFloat? = nil, imageUrl: String? = nil) -> some View {
        let urlString = imageUrl ?? primaryImageUrl
        let imageURL = URL(string: urlString ?? "")
        
        return AsyncImage(url: imageURL) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            case .failure(_):
                // Imagen rota - mostrar placeholder con ícono de error
                placeholderView(systemImage: "exclamationmark.triangle", color: ReachuColors.error)
            case .empty:
                // Cargando - mostrar placeholder con ícono de carga
                placeholderView(systemImage: "photo", color: ReachuColors.textSecondary)
            @unknown default:
                // Fallback - mostrar placeholder genérico
                placeholderView(systemImage: "photo", color: ReachuColors.textSecondary)
            }
        }
        .frame(width: width, height: height)
        .clipped()
        .cornerRadius(ReachuBorderRadius.medium)
    }
    
    /// Placeholder view for loading/error states
    private func placeholderView(systemImage: String, color: Color) -> some View {
        Rectangle()
            .fill(ReachuColors.background)
            .overlay(
                VStack(spacing: ReachuSpacing.xs) {
                    Image(systemName: systemImage)
                        .font(.title2)
                        .foregroundColor(color)
                    
                    if systemImage == "exclamationmark.triangle" {
                        Text("Image unavailable")
                            .font(ReachuTypography.caption1)
                            .foregroundColor(color)
                            .multilineTextAlignment(.center)
                    }
                }
            )
    }
    
    // MARK: - Reusable Components
    
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
    
    // MARK: - Computed Properties
    
    private var isInStock: Bool {
        (product.quantity ?? 0) > 0
    }
    
    /// Imágenes ordenadas por el campo 'order', priorizando 0 y 1
    private var sortedImages: [ProductImage] {
        let images = product.images
        
        // Si no hay imágenes, retornar array vacío
        guard !images.isEmpty else { return [] }
        
        // Ordenar por el campo 'order', con 0 y 1 al inicio
        return images.sorted { first, second in
            // Priorizar order 0 y 1
            let firstPriority = (first.order == 0 || first.order == 1) ? first.order : Int.max
            let secondPriority = (second.order == 0 || second.order == 1) ? second.order : Int.max
            
            if firstPriority != secondPriority {
                return firstPriority < secondPriority
            }
            
            // Si ambos tienen la misma prioridad, ordenar por order normal
            return first.order < second.order
        }
    }
    
    /// URL de la imagen principal (primera en el orden)
    private var primaryImageUrl: String? {
        sortedImages.first?.url
    }
}

// MARK: - Previews

#if DEBUG
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
#endif

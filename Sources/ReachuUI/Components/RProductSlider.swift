import SwiftUI
import ReachuCore
import ReachuDesignSystem

#if DEBUG
import ReachuTesting
#endif

/// Reachu Product Slider Component
///
/// A horizontal scrolling component for displaying a collection of products.
/// Perfect for featured products, recommendations, or category showcases.
public struct RProductSlider: View {
    
    // MARK: - Layout Style
    public enum Layout {
        case compact    // Minimal cards with fixed width
        case cards      // Grid-style cards with flexible width
        case featured   // Hero-style cards for highlights
        
        var cardVariant: RProductCard.Variant {
            switch self {
            case .compact: return .minimal
            case .cards: return .grid
            case .featured: return .hero
            }
        }
        
        var cardWidth: CGFloat? {
            switch self {
            case .compact: return 120
            case .cards: return 180
            case .featured: return 280
            }
        }
        
        var spacing: CGFloat {
            switch self {
            case .compact: return ReachuSpacing.sm
            case .cards: return ReachuSpacing.md
            case .featured: return ReachuSpacing.lg
            }
        }
    }
    
    // MARK: - Properties
    private let title: String?
    private let products: [Product]
    private let layout: Layout
    private let showSeeAll: Bool
    private let maxItems: Int?
    private let onProductTap: ((Product) -> Void)?
    private let onAddToCart: ((Product) -> Void)?
    private let onSeeAllTap: (() -> Void)?
    
    // MARK: - Initializer
    public init(
        title: String? = nil,
        products: [Product],
        layout: Layout = .cards,
        showSeeAll: Bool = false,
        maxItems: Int? = nil,
        onProductTap: ((Product) -> Void)? = nil,
        onAddToCart: ((Product) -> Void)? = nil,
        onSeeAllTap: (() -> Void)? = nil
    ) {
        self.title = title
        self.products = products
        self.layout = layout
        self.showSeeAll = showSeeAll
        self.maxItems = maxItems
        self.onProductTap = onProductTap
        self.onAddToCart = onAddToCart
        self.onSeeAllTap = onSeeAllTap
    }
    
    // MARK: - Body
    public var body: some View {
        VStack(alignment: .leading, spacing: ReachuSpacing.md) {
            // Header with title and see all button
            if let title = title {
                headerView(title: title)
            }
            
            // Products slider
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: layout.spacing) {
                    ForEach(displayedProducts) { product in
                        productCardView(product: product)
                    }
                }
                .padding(.horizontal, ReachuSpacing.lg)
            }
        }
    }
    
    // MARK: - Header View
    private func headerView(title: String) -> some View {
        HStack {
            Text(title)
                .font(ReachuTypography.headline)
                .foregroundColor(ReachuColors.textPrimary)
            
            Spacer()
            
            if showSeeAll {
                Button(action: { onSeeAllTap?() }) {
                    HStack(spacing: ReachuSpacing.xs) {
                        Text("See All")
                            .font(ReachuTypography.callout)
                            .foregroundColor(ReachuColors.primary)
                        
                        Image(systemName: "arrow.right")
                            .font(.caption)
                            .foregroundColor(ReachuColors.primary)
                    }
                }
            }
        }
        .padding(.horizontal, ReachuSpacing.lg)
    }
    
    // MARK: - Product Card View
    private func productCardView(product: Product) -> some View {
        Group {
            if let cardWidth = layout.cardWidth {
                // Fixed width cards
                RProductCard(
                    product: product,
                    variant: layout.cardVariant,
                    showBrand: layout != .compact,
                    showDescription: layout == .featured,
                    onTap: { onProductTap?(product) },
                    onAddToCart: layout != .compact ? { onAddToCart?(product) } : nil
                )
                .frame(width: cardWidth)
            } else {
                // Flexible width cards
                RProductCard(
                    product: product,
                    variant: layout.cardVariant,
                    showBrand: layout != .compact,
                    showDescription: layout == .featured,
                    onTap: { onProductTap?(product) },
                    onAddToCart: layout != .compact ? { onAddToCart?(product) } : nil
                )
            }
        }
    }
    
    // MARK: - Computed Properties
    private var displayedProducts: [Product] {
        if let maxItems = maxItems {
            return Array(products.prefix(maxItems))
        }
        return products
    }
}

// MARK: - Convenience Initializers
extension RProductSlider {
    
    /// Featured products slider with hero layout
    public static func featured(
        title: String = "Featured Products",
        products: [Product],
        maxItems: Int = 5,
        onProductTap: ((Product) -> Void)? = nil,
        onAddToCart: ((Product) -> Void)? = nil,
        onSeeAllTap: (() -> Void)? = nil
    ) -> RProductSlider {
        return RProductSlider(
            title: title,
            products: products,
            layout: .featured,
            showSeeAll: true,
            maxItems: maxItems,
            onProductTap: onProductTap,
            onAddToCart: onAddToCart,
            onSeeAllTap: onSeeAllTap
        )
    }
    
    /// Recommendations slider with compact layout
    public static func recommendations(
        title: String = "You Might Like",
        products: [Product],
        maxItems: Int = 8,
        onProductTap: ((Product) -> Void)? = nil,
        onSeeAllTap: (() -> Void)? = nil
    ) -> RProductSlider {
        return RProductSlider(
            title: title,
            products: products,
            layout: .compact,
            showSeeAll: true,
            maxItems: maxItems,
            onProductTap: onProductTap,
            onSeeAllTap: onSeeAllTap
        )
    }
    
    /// Category products slider with card layout
    public static func category(
        title: String,
        products: [Product],
        maxItems: Int = 6,
        onProductTap: ((Product) -> Void)? = nil,
        onAddToCart: ((Product) -> Void)? = nil,
        onSeeAllTap: (() -> Void)? = nil
    ) -> RProductSlider {
        return RProductSlider(
            title: title,
            products: products,
            layout: .cards,
            showSeeAll: true,
            maxItems: maxItems,
            onProductTap: onProductTap,
            onAddToCart: onAddToCart,
            onSeeAllTap: onSeeAllTap
        )
    }
}

// MARK: - SwiftUI Previews
#if DEBUG
#Preview("Product Slider") {
    VStack {
        Text("RProductSlider Preview")
            .font(.title)
            .padding()
        
        Text("Use in demo app to see full functionality")
            .font(.caption)
            .foregroundColor(.secondary)
    }
}
#endif

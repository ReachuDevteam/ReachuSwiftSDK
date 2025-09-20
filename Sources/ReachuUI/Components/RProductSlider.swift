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
        case compact    // Minimal cards with fixed width (120pt)
        case cards      // Grid-style cards with flexible width (180pt)
        case featured   // Hero-style cards for highlights (280pt)
        case wide       // Wide list-style cards for detailed browsing (320pt)
        case showcase   // Extra large premium cards for special promotions (360pt)
        case micro      // Tiny cards for dense recommendations (80pt)
        
        var cardVariant: RProductCard.Variant {
            switch self {
            case .compact: return .minimal
            case .cards: return .grid
            case .featured: return .hero
            case .wide: return .list
            case .showcase: return .hero
            case .micro: return .minimal
            }
        }
        
        var cardWidth: CGFloat? {
            switch self {
            case .compact: return 120
            case .cards: return 180
            case .featured: return 280
            case .wide: return 320
            case .showcase: return 360
            case .micro: return 80
            }
        }
        
        var spacing: CGFloat {
            switch self {
            case .compact: return ReachuSpacing.sm
            case .cards: return ReachuSpacing.md
            case .featured: return ReachuSpacing.lg
            case .wide: return ReachuSpacing.md
            case .showcase: return ReachuSpacing.xl
            case .micro: return ReachuSpacing.xs
            }
        }
        
        var showsDescription: Bool {
            switch self {
            case .featured, .showcase, .wide: return true
            case .compact, .cards, .micro: return false
            }
        }
        
        var showsBrand: Bool {
            switch self {
            case .micro: return false
            case .compact, .cards, .featured, .wide, .showcase: return true
            }
        }
        
        var allowsAddToCart: Bool {
            switch self {
            case .micro, .compact: return false
            case .cards, .featured, .wide, .showcase: return true
            }
        }
    }
    
    // MARK: - Properties
    private let title: String?
    private let products: [ProductDto]
    private let layout: Layout
    private let showSeeAll: Bool
    private let maxItems: Int?
    private let onProductTap: ((ProductDto) -> Void)?
    private let onAddToCart: ((ProductDto) -> Void)?
    private let onSeeAllTap: (() -> Void)?
    
    // MARK: - Initializer
    public init(
        title: String? = nil,
        products: [ProductDto],
        layout: Layout = .cards,
        showSeeAll: Bool = false,
        maxItems: Int? = nil,
        onProductTap: ((ProductDto) -> Void)? = nil,
        onAddToCart: ((ProductDto) -> Void)? = nil,
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
                    showBrand: layout.showsBrand,
                    showDescription: layout.showsDescription,
                    onTap: { onProductTap?(product) },
                    onAddToCart: layout.allowsAddToCart ? { onAddToCart?(product) } : nil
                )
                .frame(width: cardWidth)
            } else {
                // Flexible width cards
                RProductCard(
                    product: product,
                    variant: layout.cardVariant,
                    showBrand: layout.showsBrand,
                    showDescription: layout.showsDescription,
                    onTap: { onProductTap?(product) },
                    onAddToCart: layout.allowsAddToCart ? { onAddToCart?(product) } : nil
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
        products: [ProductDto],
        maxItems: Int = 5,
        onProductTap: ((ProductDto) -> Void)? = nil,
        onAddToCart: ((ProductDto) -> Void)? = nil,
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
        products: [ProductDto],
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
        products: [ProductDto],
        maxItems: Int = 6,
        onProductTap: ((ProductDto) -> Void)? = nil,
        onAddToCart: ((ProductDto) -> Void)? = nil,
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
    
    /// Wide detailed slider for comprehensive product browsing
    public static func detailed(
        title: String,
        products: [ProductDto],
        maxItems: Int = 4,
        onProductTap: ((ProductDto) -> Void)? = nil,
        onAddToCart: ((ProductDto) -> Void)? = nil,
        onSeeAllTap: (() -> Void)? = nil
    ) -> RProductSlider {
        return RProductSlider(
            title: title,
            products: products,
            layout: .wide,
            showSeeAll: true,
            maxItems: maxItems,
            onProductTap: onProductTap,
            onAddToCart: onAddToCart,
            onSeeAllTap: onSeeAllTap
        )
    }
    
    /// Premium showcase slider for high-end products
    public static func showcase(
        title: String = "Premium Collection",
        products: [ProductDto],
        maxItems: Int = 3,
        onProductTap: ((ProductDto) -> Void)? = nil,
        onAddToCart: ((ProductDto) -> Void)? = nil,
        onSeeAllTap: (() -> Void)? = nil
    ) -> RProductSlider {
        return RProductSlider(
            title: title,
            products: products,
            layout: .showcase,
            showSeeAll: true,
            maxItems: maxItems,
            onProductTap: onProductTap,
            onAddToCart: onAddToCart,
            onSeeAllTap: onSeeAllTap
        )
    }
    
    /// Micro slider for dense product lists (footer, related items)
    public static func micro(
        title: String = "Related",
        products: [ProductDto],
        maxItems: Int = 12,
        onProductTap: ((Product) -> Void)? = nil,
        onSeeAllTap: (() -> Void)? = nil
    ) -> RProductSlider {
        return RProductSlider(
            title: title,
            products: products,
            layout: .micro,
            showSeeAll: false,
            maxItems: maxItems,
            onProductTap: onProductTap,
            onSeeAllTap: onSeeAllTap
        )
    }
}

// MARK: - SwiftUI Previews
#if DEBUG
#Preview("Showcase Layout") {
    ScrollView {
        RProductSlider.showcase(
            title: "Premium Collection",
            products: Array(MockDataProvider.shared.sampleProducts.prefix(3)),
            onProductTap: { product in
                print("Showcase tapped: \(product.title)")
            },
            onAddToCart: { product in
                print("Add showcase to cart: \(product.title)")
            },
            onSeeAllTap: {
                print("See all showcase")
            }
        )
    }
}

#Preview("Wide Layout") {
    ScrollView {
        RProductSlider.detailed(
            title: "Detailed Browse",
            products: Array(MockDataProvider.shared.sampleProducts.prefix(4)),
            onProductTap: { product in
                print("Wide tapped: \(product.title)")
            },
            onAddToCart: { product in
                print("Add wide to cart: \(product.title)")
            },
            onSeeAllTap: {
                print("See all detailed")
            }
        )
    }
}

#Preview("Featured Layout") {
    ScrollView {
        RProductSlider.featured(
            title: "Featured Products",
            products: Array(MockDataProvider.shared.sampleProducts.prefix(5)),
            onProductTap: { product in
                print("Featured tapped: \(product.title)")
            },
            onAddToCart: { product in
                print("Add featured to cart: \(product.title)")
            },
            onSeeAllTap: {
                print("See all featured")
            }
        )
    }
}

#Preview("Cards Layout") {
    ScrollView {
        RProductSlider.category(
            title: "Electronics",
            products: Array(MockDataProvider.shared.sampleProducts.prefix(6)),
            onProductTap: { product in
                print("Cards tapped: \(product.title)")
            },
            onAddToCart: { product in
                print("Add cards to cart: \(product.title)")
            },
            onSeeAllTap: {
                print("See all electronics")
            }
        )
    }
}

#Preview("Compact Layout") {
    ScrollView {
        RProductSlider.recommendations(
            title: "You Might Like",
            products: Array(MockDataProvider.shared.sampleProducts.prefix(8)),
            onProductTap: { product in
                print("Compact tapped: \(product.title)")
            },
            onSeeAllTap: {
                print("See all recommendations")
            }
        )
    }
}

#Preview("Micro Layout") {
    ScrollView {
        RProductSlider.micro(
            title: "Related Items",
            products: Array(MockDataProvider.shared.sampleProducts.prefix(12)),
            onProductTap: { product in
                print("Micro tapped: \(product.title)")
            },
            onSeeAllTap: {
                print("See all related")
            }
        )
    }
}

#Preview("All Layouts Comparison") {
    ScrollView {
        VStack(spacing: ReachuSpacing.xl) {
            // Showcase
            RProductSlider.showcase(
                title: "Showcase (360pt)",
                products: Array(MockDataProvider.shared.sampleProducts.prefix(2)),
                onProductTap: { _ in },
                onAddToCart: { _ in }
            )
            
            // Wide
            RProductSlider.detailed(
                title: "Wide (320pt)",
                products: Array(MockDataProvider.shared.sampleProducts.prefix(3)),
                onProductTap: { _ in },
                onAddToCart: { _ in }
            )
            
            // Featured
            RProductSlider.featured(
                title: "Featured (280pt)",
                products: Array(MockDataProvider.shared.sampleProducts.prefix(4)),
                onProductTap: { _ in },
                onAddToCart: { _ in }
            )
            
            // Cards
            RProductSlider.category(
                title: "Cards (180pt)",
                products: Array(MockDataProvider.shared.sampleProducts.prefix(5)),
                onProductTap: { _ in },
                onAddToCart: { _ in }
            )
            
            // Compact
            RProductSlider.recommendations(
                title: "Compact (120pt)",
                products: Array(MockDataProvider.shared.sampleProducts.prefix(6)),
                onProductTap: { _ in }
            )
            
            // Micro
            RProductSlider.micro(
                title: "Micro (80pt)",
                products: Array(MockDataProvider.shared.sampleProducts.prefix(8)),
                onProductTap: { _ in }
            )
        }
        .padding(.vertical)
    }
}
#endif

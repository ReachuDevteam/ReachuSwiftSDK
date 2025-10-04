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
    private let products: [Product]
    private let layout: Layout
    private let showSeeAll: Bool
    private let maxItems: Int?
    private let onProductTap: ((Product) -> Void)?
    private let onAddToCart: ((Product) -> Void)?
    private let onSeeAllTap: (() -> Void)?
    
    // Environment for adaptive colors
    @SwiftUI.Environment(\.colorScheme) private var colorScheme: SwiftUI.ColorScheme
    
    
    // Animation states
    @State private var addedProductId: Int?
    @State private var sliderScale: CGFloat = 1.0
    
    // MARK: - Initializer
    public init(
        title: String? = nil,
        products: [Product]? = nil,
        layout: Layout = .cards,
        showSeeAll: Bool = false,
        maxItems: Int? = nil,
        onProductTap: ((Product) -> Void)? = nil,
        onAddToCart: ((Product) -> Void)? = nil,
        onSeeAllTap: (() -> Void)? = nil
    ) {
        self.title = title
        // Use provided products or fallback to mock data for demos/testing
        #if DEBUG
        self.products = products ?? MockDataProvider.shared.sampleProducts
        #else
        self.products = products ?? []
        #endif
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
            .scaleEffect(sliderScale)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: sliderScale)
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
    
    // MARK: - Animation Functions
    
    private func animateAddToCart(for product: Product) {
        // Haptic feedback
        #if os(iOS)
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        #endif
        
        // Store the added product ID for visual feedback
        addedProductId = product.id
        
        // Slight scale animation for the entire slider
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            sliderScale = 1.02
        }
        
        // Return to normal scale
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                sliderScale = 1.0
            }
        }
        
        // Reset added product highlight after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeOut(duration: 0.3)) {
                addedProductId = nil
            }
        }
        
        // Call the original callback
        onAddToCart?(product)
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
                    onAddToCart: layout.allowsAddToCart ? { animateAddToCart(for: product) } : nil
                )
                .frame(width: cardWidth)
                .scaleEffect(addedProductId == product.id ? 1.05 : 1.0)
                .overlay(
                    RoundedRectangle(cornerRadius: ReachuBorderRadius.large)
                        .stroke(ReachuColors.success, lineWidth: addedProductId == product.id ? 2 : 0)
                        .animation(.easeInOut(duration: 0.3), value: addedProductId)
                )
            } else {
                // Flexible width cards
                RProductCard(
                    product: product,
                    variant: layout.cardVariant,
                    showBrand: layout.showsBrand,
                    showDescription: layout.showsDescription,
                    onTap: { onProductTap?(product) },
                    onAddToCart: layout.allowsAddToCart ? { animateAddToCart(for: product) } : nil
                )
                .scaleEffect(addedProductId == product.id ? 1.05 : 1.0)
                .overlay(
                    RoundedRectangle(cornerRadius: ReachuBorderRadius.large)
                        .stroke(ReachuColors.success, lineWidth: addedProductId == product.id ? 2 : 0)
                        .animation(.easeInOut(duration: 0.3), value: addedProductId)
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
    
    /// Wide detailed slider for comprehensive product browsing
    public static func detailed(
        title: String,
        products: [Product],
        maxItems: Int = 4,
        onProductTap: ((Product) -> Void)? = nil,
        onAddToCart: ((Product) -> Void)? = nil,
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
        products: [Product],
        maxItems: Int = 3,
        onProductTap: ((Product) -> Void)? = nil,
        onAddToCart: ((Product) -> Void)? = nil,
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
        products: [Product],
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

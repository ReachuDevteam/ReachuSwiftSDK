import SwiftUI
import ReachuDesignSystem

public struct ProductCatalogDemoView: View {
    @State private var products: [Product] = [
        Product(id: "1", name: "iPhone 15 Pro", price: 999.99, category: "Electronics", image: "📱", inStock: true),
        Product(id: "2", name: "AirPods Pro", price: 249.99, category: "Electronics", image: "🎧", inStock: true),
        Product(id: "3", name: "MacBook Air", price: 1299.99, category: "Computers", image: "💻", inStock: false),
        Product(id: "4", name: "Apple Watch", price: 399.99, category: "Wearables", image: "⌚", inStock: true),
        Product(id: "5", name: "iPad Pro", price: 799.99, category: "Tablets", image: "📱", inStock: true),
        Product(id: "6", name: "Magic Keyboard", price: 179.99, category: "Accessories", image: "⌨️", inStock: true),
    ]
    
    @State private var selectedCategory = "All"
    private let categories = ["All", "Electronics", "Computers", "Wearables", "Tablets", "Accessories"]
    
    public init() {}
    
    private var filteredProducts: [Product] {
        if selectedCategory == "All" {
            return products
        }
        return products.filter { $0.category == selectedCategory }
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Category Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: ReachuSpacing.sm) {
                    ForEach(categories, id: \.self) { category in
                        CategoryChip(
                            title: category,
                            isSelected: selectedCategory == category
                        ) {
                            selectedCategory = category
                        }
                    }
                }
                .padding(.horizontal, ReachuSpacing.lg)
            }
            .padding(.vertical, ReachuSpacing.md)
            .background(ReachuColors.background)
            
            // Products Grid
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: ReachuSpacing.md) {
                    ForEach(filteredProducts) { product in
                        ProductCard(product: product) {
                            addToCart(product: product)
                        }
                    }
                }
                .padding(ReachuSpacing.lg)
            }
        }
        .navigationTitle("Products")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
    
    private func addToCart(product: Product) {
        print("Added \(product.name) to cart")
        // TODO: Integrar con ReachuCore cuando esté implementado
    }
}

struct Product: Identifiable {
    let id: String
    let name: String
    let price: Double
    let category: String
    let image: String
    let inStock: Bool
}

struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(ReachuTypography.callout)
                .padding(.horizontal, ReachuSpacing.md)
                .padding(.vertical, ReachuSpacing.sm)
                .background(
                    isSelected ? ReachuColors.primary : ReachuColors.surface
                )
                .foregroundColor(
                    isSelected ? .white : ReachuColors.textPrimary
                )
                .cornerRadius(ReachuBorderRadius.medium)
        }
    }
}

struct ProductCard: View {
    let product: Product
    let onAddToCart: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: ReachuSpacing.sm) {
            // Product Image
            VStack {
                Text(product.image)
                    .font(.system(size: 50))
                    .frame(maxWidth: .infinity, minHeight: 100)
                    .background(ReachuColors.background)
                    .cornerRadius(ReachuBorderRadius.medium)
            }
            
            // Product Info
            VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
                Text(product.name)
                    .font(ReachuTypography.body)
                    .fontWeight(.medium)
                    .lineLimit(2)
                
                Text(product.category)
                    .font(ReachuTypography.caption1)
                    .foregroundColor(ReachuColors.textSecondary)
                
                HStack {
                    Text("$\(product.price, specifier: "%.2f")")
                        .font(ReachuTypography.body)
                        .fontWeight(.semibold)
                        .foregroundColor(ReachuColors.primary)
                    
                    Spacer()
                    
                    if !product.inStock {
                        Text("Out of Stock")
                            .font(ReachuTypography.caption1)
                            .foregroundColor(ReachuColors.error)
                    }
                }
            }
            
            // Add to Cart Button
            RButton(
                title: product.inStock ? "Add to Cart" : "Out of Stock",
                style: product.inStock ? .primary : .secondary,
                isDisabled: !product.inStock
            ) {
                if product.inStock {
                    onAddToCart()
                }
            }
        }
        .padding(ReachuSpacing.md)
        .background(ReachuColors.surface)
        .cornerRadius(ReachuBorderRadius.large)
        .shadow(color: ReachuColors.textPrimary.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    NavigationView {
        ProductCatalogDemoView()
    }
}

//
//  ContentView.swift
//  ReachuDemoApp
//
//  Created by Angelo Sepulveda on 19/09/2025.
//

import SwiftUI
import ReachuDesignSystem

struct ContentView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: ReachuSpacing.xl) {
                    VStack(spacing: ReachuSpacing.md) {
                        Text("Reachu SDK")
                            .font(ReachuTypography.largeTitle)
                            .foregroundColor(ReachuColors.primary)
                        
                        Text("Demo iOS App")
                            .font(ReachuTypography.body)
                            .foregroundColor(ReachuColors.textPrimary)
                    }
                    .padding(.top, ReachuSpacing.xl)
                    
                    // Demo Sections
                    VStack(spacing: ReachuSpacing.lg) {
                        DemoSection(icon: "paintbrush.fill", title: "Design System", description: "Explore UI components and tokens") {
                            DesignSystemDemoView()
                        }
                        
                        DemoSection(icon: "bag.fill", title: "Product Catalog", description: "Browse and add products to cart") {
                            ProductCatalogDemoView()
                        }
                        
                        DemoSection(icon: "rectangle.stack.fill", title: "Product Sliders", description: "Horizontal scrolling product collections") {
                            ProductSliderDemoView()
                        }
                        
                        DemoSection(icon: "cart.fill", title: "Shopping Cart", description: "Manage items in your cart") {
                            ShoppingCartDemoView()
                        }
                        
                        DemoSection(icon: "creditcard.fill", title: "Checkout Flow", description: "Simulate the checkout process") {
                            CheckoutDemoView()
                        }
                    }
                    .padding(.horizontal, ReachuSpacing.lg)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, ReachuSpacing.xl)
            }
            .navigationTitle("Reachu Demo")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct DemoSection<Destination: View>: View {
    let icon: String
    let title: String
    let description: String
    @ViewBuilder let destination: () -> Destination
    
    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: ReachuSpacing.md) {
                Text(icon)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
                    Text(title)
                        .font(ReachuTypography.headline)
                        .foregroundColor(ReachuColors.textPrimary)
                    
                        Text(description)
                            .font(ReachuTypography.body)
                            .foregroundColor(ReachuColors.textSecondary)
                }
                
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(ReachuColors.textTertiary)
            }
            .padding(ReachuSpacing.lg)
            .background(ReachuColors.surface)
            .cornerRadius(ReachuBorderRadius.large)
            .shadow(color: ReachuColors.textPrimary.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Demo Views
struct DesignSystemDemoView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ReachuSpacing.lg) {
                Text("Reachu Design System")
                    .font(ReachuTypography.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom, ReachuSpacing.md)

                // MARK: - Colors
                VStack(alignment: .leading, spacing: ReachuSpacing.sm) {
                    Text("Colors")
                        .font(ReachuTypography.title2)
                        .fontWeight(.semibold)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: ReachuSpacing.sm) {
                        ColorSwatch(name: "Primary", color: ReachuColors.primary)
                        ColorSwatch(name: "Secondary", color: ReachuColors.secondary)
                        ColorSwatch(name: "Success", color: ReachuColors.success)
                        ColorSwatch(name: "Warning", color: ReachuColors.warning)
                        ColorSwatch(name: "Error", color: ReachuColors.error)
                        ColorSwatch(name: "Info", color: ReachuColors.info)
                        ColorSwatch(name: "Background", color: ReachuColors.background)
                        ColorSwatch(name: "Surface", color: ReachuColors.surface)
                        ColorSwatch(name: "Text Primary", color: ReachuColors.textPrimary)
                        ColorSwatch(name: "Text Secondary", color: ReachuColors.textSecondary)
                    }
                }

                // MARK: - Typography
                VStack(alignment: .leading, spacing: ReachuSpacing.sm) {
                    Text("Typography")
                        .font(ReachuTypography.title2)
                        .fontWeight(.semibold)
                    Text("Large Title")
                        .font(ReachuTypography.largeTitle)
                    Text("Title 1")
                        .font(ReachuTypography.title1)
                    Text("Headline")
                        .font(ReachuTypography.headline)
                    Text("Body")
                        .font(ReachuTypography.body)
                    Text("Caption 1")
                        .font(ReachuTypography.caption1)
                }

                // MARK: - Buttons
                VStack(alignment: .leading, spacing: ReachuSpacing.md) {
                    Text("Buttons")
                        .font(ReachuTypography.title2)
                        .fontWeight(.semibold)

                    RButton(title: "Primary Button", style: .primary) {
                        print("Primary Tapped")
                    }
                    RButton(title: "Secondary Button", style: .secondary) {
                        print("Secondary Tapped")
                    }
                    RButton(title: "Tertiary Button", style: .tertiary) {
                        print("Tertiary Tapped")
                    }
                    RButton(title: "Destructive Button", style: .destructive) {
                        print("Destructive Tapped")
                    }
                    RButton(title: "Ghost Button", style: .ghost) {
                        print("Ghost Tapped")
                    }
                    RButton(title: "Disabled Button", style: .primary, isDisabled: true) {
                        print("Disabled Tapped")
                    }
                }
            }
        }
        .padding()
        .navigationTitle("Design System")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ColorSwatch: View {
    let name: String
    let color: Color
    
    var body: some View {
        VStack {
            RoundedRectangle(cornerRadius: ReachuBorderRadius.medium)
                .fill(color)
                .frame(height: 60)
                .overlay(
                    RoundedRectangle(cornerRadius: ReachuBorderRadius.medium)
                        .stroke(ReachuColors.textPrimary.opacity(0.2), lineWidth: 1)
                )
            
            Text(name)
                .font(ReachuTypography.caption1)
                .foregroundColor(ReachuColors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
}

struct ProductCatalogDemoView: View {
    @State private var selectedVariant: ProductCardVariant = .grid
    private let products = DemoProductData.sampleProducts
    
    var body: some View {
        VStack(spacing: 0) {
            // Variant Selector
            VStack(spacing: ReachuSpacing.sm) {
                Text("Choose Layout")
                    .font(ReachuTypography.headline)
                    .foregroundColor(ReachuColors.textPrimary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: ReachuSpacing.sm) {
                        VariantButton(title: "Grid", variant: .grid, selected: selectedVariant == .grid) {
                            selectedVariant = .grid
                        }
                        VariantButton(title: "List", variant: .list, selected: selectedVariant == .list) {
                            selectedVariant = .list
                        }
                        VariantButton(title: "Hero", variant: .hero, selected: selectedVariant == .hero) {
                            selectedVariant = .hero
                        }
                        VariantButton(title: "Minimal", variant: .minimal, selected: selectedVariant == .minimal) {
                            selectedVariant = .minimal
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical, ReachuSpacing.md)
            .background(ReachuColors.surfaceSecondary)
            
            // Products Display
            ScrollView {
                Group {
                    switch selectedVariant {
                    case .grid:
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: ReachuSpacing.md) {
                            ForEach(products) { product in
                                SimpleProductCard(
                                    product: product,
                                    variant: .grid,
                                    onTap: { print("Tapped: \(product.title)") },
                                    onAddToCart: { print("Add to cart: \(product.title)") }
                                )
                            }
                        }
                        .padding(ReachuSpacing.lg)
                        
                    case .list:
                        LazyVStack(spacing: ReachuSpacing.sm) {
                            ForEach(products) { product in
                                SimpleProductCard(
                                    product: product,
                                    variant: .list,
                                    onTap: { print("Tapped: \(product.title)") },
                                    onAddToCart: { print("Add to cart: \(product.title)") }
                                )
                            }
                        }
                        .padding(ReachuSpacing.lg)
                        
                    case .hero:
                        LazyVStack(spacing: ReachuSpacing.xl) {
                            ForEach(products) { product in
                                SimpleProductCard(
                                    product: product,
                                    variant: .hero,
                                    showDescription: true,
                                    onTap: { print("Tapped: \(product.title)") },
                                    onAddToCart: { print("Add to cart: \(product.title)") }
                                )
                            }
                        }
                        .padding(ReachuSpacing.lg)
                        
                    case .minimal:
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: ReachuSpacing.sm) {
                                ForEach(products) { product in
                                    SimpleProductCard(
                                        product: product,
                                        variant: .minimal,
                                        onTap: { print("Tapped: \(product.title)") }
                                    )
                                }
                            }
                            .padding(.horizontal, ReachuSpacing.lg)
                        }
                        .padding(.vertical, ReachuSpacing.lg)
                    }
                }
            }
        }
        .navigationTitle("Product Cards")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct VariantButton: View {
    let title: String
    let variant: ProductCardVariant
    let selected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(ReachuTypography.caption1)
                .fontWeight(.medium)
                .foregroundColor(selected ? .white : ReachuColors.primary)
                .padding(.horizontal, ReachuSpacing.md)
                .padding(.vertical, ReachuSpacing.xs)
                .background(selected ? ReachuColors.primary : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: ReachuBorderRadius.circle)
                        .stroke(ReachuColors.primary, lineWidth: 1)
                )
                .cornerRadius(ReachuBorderRadius.circle)
        }
    }
}


struct ShoppingCartDemoView: View {
    var body: some View {
        VStack {
            Text("Shopping Cart")
                .font(ReachuTypography.largeTitle)
            
            Text("Coming soon...")
                .font(ReachuTypography.body)
                .foregroundColor(ReachuColors.textSecondary)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Cart")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct CheckoutDemoView: View {
    var body: some View {
        VStack {
            Text("Checkout")
                .font(ReachuTypography.largeTitle)
            
            Text("Coming soon...")
                .font(ReachuTypography.body)
                .foregroundColor(ReachuColors.textSecondary)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Checkout")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Product Slider Layout Variants
enum ProductSliderLayout: String, CaseIterable {
    case showcase = "Showcase"
    case wide = "Wide"  
    case featured = "Featured"
    case cards = "Cards"
    case compact = "Compact"
    case micro = "Micro"
}

struct ProductSliderDemoView: View {
    @State private var selectedLayout: ProductSliderLayout = .featured
    private let products = DemoProductData.sampleProducts
    
    var body: some View {
        VStack(spacing: 0) {
            // Layout Selector
            VStack(spacing: ReachuSpacing.sm) {
                Text("Choose Layout Style")
                    .font(ReachuTypography.headline)
                    .foregroundColor(ReachuColors.textPrimary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: ReachuSpacing.sm) {
                        ForEach(ProductSliderLayout.allCases, id: \.self) { layout in
                            SliderLayoutButton(
                                title: layout.rawValue,
                                layout: layout,
                                selected: selectedLayout == layout
                            ) {
                                selectedLayout = layout
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical, ReachuSpacing.md)
            .background(ReachuColors.surfaceSecondary)
            
            // Layout Information
            VStack(spacing: ReachuSpacing.sm) {
                layoutInfo
            }
            .padding(.horizontal, ReachuSpacing.lg)
            .padding(.vertical, ReachuSpacing.md)
            .background(ReachuColors.surface)
            
            // Selected Layout Display
            ScrollView {
                VStack(spacing: ReachuSpacing.xl) {
                    selectedSliderView
                }
                .padding(.vertical, ReachuSpacing.lg)
            }
        }
        .navigationTitle("Product Sliders")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    @ViewBuilder
    private var selectedSliderView: some View {
        switch selectedLayout {
        case .showcase:
            showcaseSlider
        case .wide:
            wideSlider
        case .featured:
            featuredSlider
        case .cards:
            cardsSlider
        case .compact:
            compactSlider
        case .micro:
            microSlider
        }
    }
    
    private var showcaseSlider: some View {
        VStack(alignment: .leading, spacing: ReachuSpacing.md) {
            Text("Premium Collection")
                .font(ReachuTypography.headline)
                .padding(.horizontal, ReachuSpacing.lg)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: ReachuSpacing.xl) {
                    ForEach(Array(products.prefix(3))) { product in
                        SimpleProductCard(
                            product: product,
                            variant: .hero,
                            showDescription: true,
                            onTap: { print("Showcase: \(product.title)") },
                            onAddToCart: { print("Add showcase: \(product.title)") }
                        )
                        .frame(width: 360)
                    }
                }
                .padding(.horizontal, ReachuSpacing.lg)
            }
        }
    }
    
    private var wideSlider: some View {
        VStack(alignment: .leading, spacing: ReachuSpacing.md) {
            HStack {
                Text("Detailed Browse")
                    .font(ReachuTypography.headline)
                
                Spacer()
                
                Button("See All") {
                    print("See all detailed")
                }
                .font(ReachuTypography.callout)
                .foregroundColor(ReachuColors.primary)
            }
            .padding(.horizontal, ReachuSpacing.lg)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: ReachuSpacing.md) {
                    ForEach(Array(products.prefix(4))) { product in
                        SimpleProductCard(
                            product: product,
                            variant: .list,
                            showDescription: true,
                            onTap: { print("Wide: \(product.title)") },
                            onAddToCart: { print("Add wide: \(product.title)") }
                        )
                        .frame(width: 320)
                    }
                }
                .padding(.horizontal, ReachuSpacing.lg)
            }
        }
    }
    
    private var featuredSlider: some View {
        VStack(alignment: .leading, spacing: ReachuSpacing.md) {
            HStack {
                Text("Featured Products")
                    .font(ReachuTypography.headline)
                
                Spacer()
                
                Button("See All") {
                    print("See all featured")
                }
                .font(ReachuTypography.callout)
                .foregroundColor(ReachuColors.primary)
            }
            .padding(.horizontal, ReachuSpacing.lg)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: ReachuSpacing.lg) {
                    ForEach(Array(products.prefix(5))) { product in
                        SimpleProductCard(
                            product: product,
                            variant: .hero,
                            showDescription: true,
                            onTap: { print("Featured: \(product.title)") },
                            onAddToCart: { print("Add featured: \(product.title)") }
                        )
                        .frame(width: 280)
                    }
                }
                .padding(.horizontal, ReachuSpacing.lg)
            }
        }
    }
    
    private var cardsSlider: some View {
        VStack(alignment: .leading, spacing: ReachuSpacing.md) {
            HStack {
                Text("Electronics")
                    .font(ReachuTypography.headline)
                
                Spacer()
                
                Button("See All") {
                    print("See all electronics")
                }
                .font(ReachuTypography.callout)
                .foregroundColor(ReachuColors.primary)
            }
            .padding(.horizontal, ReachuSpacing.lg)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: ReachuSpacing.md) {
                    ForEach(Array(products.prefix(6))) { product in
                        SimpleProductCard(
                            product: product,
                            variant: .grid,
                            onTap: { print("Cards: \(product.title)") },
                            onAddToCart: { print("Add cards: \(product.title)") }
                        )
                        .frame(width: 180)
                    }
                }
                .padding(.horizontal, ReachuSpacing.lg)
            }
        }
    }
    
    private var compactSlider: some View {
        VStack(alignment: .leading, spacing: ReachuSpacing.md) {
            HStack {
                Text("You Might Like")
                    .font(ReachuTypography.headline)
                
                Spacer()
                
                Button("See All") {
                    print("See all recommendations")
                }
                .font(ReachuTypography.callout)
                .foregroundColor(ReachuColors.primary)
            }
            .padding(.horizontal, ReachuSpacing.lg)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: ReachuSpacing.sm) {
                    ForEach(Array(products.prefix(8))) { product in
                        SimpleProductCard(
                            product: product,
                            variant: .minimal,
                            onTap: { print("Compact: \(product.title)") }
                        )
                        .frame(width: 120)
                    }
                }
                .padding(.horizontal, ReachuSpacing.lg)
            }
        }
    }
    
    private var microSlider: some View {
        VStack(alignment: .leading, spacing: ReachuSpacing.md) {
            Text("Related Items")
                .font(ReachuTypography.headline)
                .padding(.horizontal, ReachuSpacing.lg)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: ReachuSpacing.xs) {
                    ForEach(Array(products.prefix(12))) { product in
                        VStack(spacing: ReachuSpacing.xs) {
                            AsyncImage(url: URL(string: product.images.first?.url ?? "")) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Rectangle()
                                    .fill(ReachuColors.background)
                                    .overlay(
                                        Image(systemName: "photo")
                                            .foregroundColor(ReachuColors.textSecondary)
                                    )
                            }
                            .frame(width: 60, height: 60)
                            .clipped()
                            .cornerRadius(ReachuBorderRadius.small)
                            
                            Text(product.title)
                                .font(ReachuTypography.caption2)
                                .foregroundColor(ReachuColors.textPrimary)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                            
                            Text(product.price.displayAmount)
                                .font(ReachuTypography.caption1)
                                .fontWeight(.semibold)
                                .foregroundColor(ReachuColors.primary)
                        }
                        .frame(width: 80)
                        .onTapGesture {
                            print("Micro: \(product.title)")
                        }
                    }
                }
                .padding(.horizontal, ReachuSpacing.lg)
            }
        }
    }
    
    @ViewBuilder
    private var layoutInfo: some View {
        switch selectedLayout {
        case .showcase:
            LayoutInfoCard(
                title: "Showcase Layout",
                width: "360pt",
                description: "Premium layout for luxury products and special collections with maximum visual impact",
                useCase: "Premium brands, luxury items, special editions"
            )
        case .wide:
            LayoutInfoCard(
                title: "Wide Layout", 
                width: "320pt",
                description: "Comprehensive layout for detailed product browsing and comparison",
                useCase: "Product specifications, detailed comparison, reviews"
            )
        case .featured:
            LayoutInfoCard(
                title: "Featured Layout",
                width: "280pt", 
                description: "Large cards for highlighting premium products and promotions",
                useCase: "Homepage banners, new arrivals, special offers"
            )
        case .cards:
            LayoutInfoCard(
                title: "Cards Layout",
                width: "180pt",
                description: "Medium cards for browsing product collections efficiently", 
                useCase: "Category listings, search results, related products"
            )
        case .compact:
            LayoutInfoCard(
                title: "Compact Layout",
                width: "120pt",
                description: "Small cards for recommendations and space-constrained areas",
                useCase: "Recently viewed, suggestions, quick picks"
            )
        case .micro:
            LayoutInfoCard(
                title: "Micro Layout",
                width: "80pt",
                description: "Ultra-compact cards for dense product listings",
                useCase: "Footer recommendations, accessories, related items"
            )
        }
    }
}

struct SliderLayoutButton: View {
    let title: String
    let layout: ProductSliderLayout
    let selected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(ReachuTypography.caption1)
                .fontWeight(.medium)
                .foregroundColor(selected ? .white : ReachuColors.primary)
                .padding(.horizontal, ReachuSpacing.md)
                .padding(.vertical, ReachuSpacing.xs)
                .background(selected ? ReachuColors.primary : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: ReachuBorderRadius.circle)
                        .stroke(ReachuColors.primary, lineWidth: 1)
                )
                .cornerRadius(ReachuBorderRadius.circle)
        }
    }
}

struct LayoutInfoCard: View {
    let title: String
    let width: String
    let description: String
    let useCase: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
            HStack {
                Text(title)
                    .font(ReachuTypography.bodyBold)
                    .foregroundColor(ReachuColors.textPrimary)
                
                Spacer()
                
                Text(width)
                    .font(ReachuTypography.caption1)
                    .foregroundColor(ReachuColors.textSecondary)
                    .padding(.horizontal, ReachuSpacing.sm)
                    .padding(.vertical, ReachuSpacing.xs)
                    .background(ReachuColors.background)
                    .cornerRadius(ReachuBorderRadius.small)
            }
            
            Text(description)
                .font(ReachuTypography.body)
                .foregroundColor(ReachuColors.textSecondary)
            
            Text("Use case: \(useCase)")
                .font(ReachuTypography.caption1)
                .foregroundColor(ReachuColors.textTertiary)
        }
        .padding(ReachuSpacing.md)
        .background(ReachuColors.surface)
        .cornerRadius(ReachuBorderRadius.medium)
        .shadow(color: ReachuColors.textPrimary.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Demo Models and Components

enum ProductCardVariant {
    case grid, list, hero, minimal
}

struct DemoProduct: Identifiable, Codable {
    let id: Int
    let title: String
    let brand: String?
    let description: String?
    let sku: String
    let quantity: Int?
    let price: DemoPrice
    let images: [DemoProductImage]
    
    init(id: Int, title: String, brand: String? = nil, description: String? = nil, sku: String, quantity: Int? = nil, price: DemoPrice, images: [DemoProductImage] = []) {
        self.id = id
        self.title = title
        self.brand = brand
        self.description = description
        self.sku = sku
        self.quantity = quantity
        self.price = price
        self.images = images
    }
}

struct DemoPrice: Codable {
    let amount: Float
    let currency_code: String
    let compare_at: Float?
    
    init(amount: Float, currency_code: String, compare_at: Float? = nil) {
        self.amount = amount
        self.currency_code = currency_code
        self.compare_at = compare_at
    }
    
    var displayAmount: String {
        "\(currency_code) \(String(format: "%.2f", amount))"
    }
    
    var displayCompareAtAmount: String? {
        if let compareAt = compare_at {
            return "\(currency_code) \(String(format: "%.2f", compareAt))"
        }
        return nil
    }
}

struct DemoProductImage: Identifiable, Codable {
    let id: String
    let url: String
    let order: Int
    
    init(id: String, url: String, order: Int = 0) {
        self.id = id
        self.url = url
        self.order = order
    }
}

class DemoProductData {
    static let sampleProducts: [DemoProduct] = [
        DemoProduct(
            id: 101,
            title: "Reachu Wireless Headphones",
            brand: "Reachu Audio",
            description: "Experience immersive sound with premium noise-cancelling technology and crystal clear audio quality.",
            sku: "RCH-HP-001",
            quantity: 50,
            price: DemoPrice(amount: 199.99, currency_code: "USD", compare_at: 249.99),
            images: [
                DemoProductImage(id: "img101-1", url: "https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=400&h=300&fit=crop&crop=center", order: 0),
                DemoProductImage(id: "img101-2", url: "https://images.unsplash.com/photo-1583394838336-acd977736f90?w=400&h=300&fit=crop&crop=center", order: 1),
                DemoProductImage(id: "img101-3", url: "https://images.unsplash.com/photo-1487215078519-e21cc028cb29?w=400&h=300&fit=crop&crop=center", order: 2)
            ]
        ),
        DemoProduct(
            id: 102,
            title: "Reachu Smart Watch Series 5",
            brand: "Reachu Wearables",
            description: "Track your fitness, monitor your health, and stay connected with our latest smartwatch featuring advanced sensors.",
            sku: "RCH-SW-005",
            quantity: 30,
            price: DemoPrice(amount: 349.99, currency_code: "USD"),
            images: [
                DemoProductImage(id: "img102-1", url: "https://images.unsplash.com/photo-1434493789847-2f02dc6ca35d?w=400&h=300&fit=crop&crop=center", order: 1),
                DemoProductImage(id: "img102-2", url: "https://images.unsplash.com/photo-1544117519-31a4b719223d?w=400&h=300&fit=crop&crop=center", order: 0)
            ]
        ),
        DemoProduct(
            id: 103,
            title: "Reachu Minimalist Backpack",
            brand: "Reachu Gear",
            description: "Stylish and durable backpack perfect for daily commutes, travel, and outdoor adventures.",
            sku: "RCH-BP-001",
            quantity: 0, // Out of stock
            price: DemoPrice(amount: 89.99, currency_code: "USD", compare_at: 100.00),
            images: [
                DemoProductImage(id: "img103-1", url: "https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=400&h=300&fit=crop&crop=center", order: 0),
                DemoProductImage(id: "img103-2", url: "https://images.unsplash.com/photo-1622560480605-d83c853bc5c3?w=400&h=300&fit=crop&crop=center", order: 1),
                DemoProductImage(id: "img103-3", url: "https://images.unsplash.com/photo-1581605405669-fcdf81165afa?w=400&h=300&fit=crop&crop=center", order: 2)
            ]
        ),
        DemoProduct(
            id: 104,
            title: "Reachu Wireless Charging Pad",
            brand: "Reachu Power",
            description: "Fast and convenient wireless charging for all your devices with sleek design and safety features.",
            sku: "RCH-CP-002",
            quantity: 15, // Back in stock
            price: DemoPrice(amount: 39.99, currency_code: "USD"),
            images: [
                DemoProductImage(id: "img104-1", url: "https://images.unsplash.com/photo-1585338447937-7082f8fc763d?w=400&h=300&fit=crop&crop=center", order: 0),
                DemoProductImage(id: "img104-2", url: "https://images.unsplash.com/photo-1609592373050-87a8f2e04f40?w=400&h=300&fit=crop&crop=center", order: 1)
            ]
        ),
        DemoProduct(
            id: 105,
            title: "Reachu Bluetooth Speaker",
            brand: "Reachu Audio",
            description: "Portable bluetooth speaker with 360-degree sound, waterproof design, and 12-hour battery life.",
            sku: "RCH-BT-003",
            quantity: 25,
            price: DemoPrice(amount: 79.99, currency_code: "USD", compare_at: 99.99),
            images: [
                DemoProductImage(id: "img105-1", url: "https://images.unsplash.com/photo-1608043152269-423dbba4e7e1?w=400&h=300&fit=crop&crop=center", order: 1),
                DemoProductImage(id: "img105-2", url: "https://images.unsplash.com/photo-1588422904075-be4be63e1bd6?w=400&h=300&fit=crop&crop=center", order: 0),
                DemoProductImage(id: "img105-3", url: "https://images.unsplash.com/photo-1545454675-3531b543be5d?w=400&h=300&fit=crop&crop=center", order: 2)
            ]
        ),
        DemoProduct(
            id: 106,
            title: "Reachu Gaming Mouse",
            brand: "Reachu Gaming",
            description: "High-precision gaming mouse with customizable RGB lighting and ergonomic design.",
            sku: "RCH-GM-004",
            quantity: 40,
            price: DemoPrice(amount: 59.99, currency_code: "USD"),
            images: [
                DemoProductImage(id: "img106-1", url: "https://images.unsplash.com/photo-1527814050087-3793815479db?w=400&h=300&fit=crop&crop=center", order: 0),
                DemoProductImage(id: "img106-2", url: "https://images.unsplash.com/photo-1615663245857-ac93bb7c39e7?w=400&h=300&fit=crop&crop=center", order: 1)
            ]
        )
    ]
}

struct SimpleProductCard: View {
    let product: DemoProduct
    let variant: ProductCardVariant
    let showBrand: Bool
    let showDescription: Bool
    let onTap: (() -> Void)?
    let onAddToCart: (() -> Void)?
    
    init(
        product: DemoProduct,
        variant: ProductCardVariant = .grid,
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
    
    var body: some View {
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
    
    private var gridLayout: some View {
        VStack(alignment: .leading, spacing: ReachuSpacing.sm) {
            productImage(height: 160)
            
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
    
    private var listLayout: some View {
        HStack(spacing: ReachuSpacing.md) {
            productImage(height: 80)
                .frame(width: 80)
            
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
    
    private var heroLayout: some View {
        VStack(alignment: .leading, spacing: ReachuSpacing.lg) {
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
    
    private var minimalLayout: some View {
        VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
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
    
    private func productImage(height: CGFloat) -> some View {
        Group {
            // Single image for list and minimal variants
            if variant == .list || variant == .minimal {
                singleImageView(height: height)
            } else {
                // Multiple images with TabView for grid and hero variants
                multipleImagesView(height: height)
            }
        }
    }
    
    /// Multiple images view with pagination for grid and hero variants
    private func multipleImagesView(height: CGFloat) -> some View {
        VStack(spacing: 0) {
            if sortedImages.count > 1 {
                // Multiple images with TabView for pagination
                TabView {
                    ForEach(sortedImages, id: \.id) { image in
                        singleImageView(height: height, imageUrl: image.url)
                            .tag(image.id)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                .frame(height: height)
            } else {
                // Single image or fallback
                singleImageView(height: height)
            }
        }
        .cornerRadius(ReachuBorderRadius.medium)
    }
    
    /// Single image view with error handling and placeholders
    private func singleImageView(height: CGFloat, imageUrl: String? = nil) -> some View {
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
                placeholderView(systemImage: "exclamationmark.triangle", color: ReachuColors.error, text: "Image unavailable")
            case .empty:
                // Cargando - mostrar placeholder con ícono de carga
                placeholderView(systemImage: "photo", color: ReachuColors.textSecondary, text: nil)
            @unknown default:
                // Fallback - mostrar placeholder genérico
                placeholderView(systemImage: "photo", color: ReachuColors.textSecondary, text: nil)
            }
        }
        .frame(height: height)
        .clipped()
        .cornerRadius(ReachuBorderRadius.medium)
    }
    
    /// Placeholder view for loading/error states
    private func placeholderView(systemImage: String, color: Color, text: String?) -> some View {
        Rectangle()
            .fill(ReachuColors.background)
            .overlay(
                VStack(spacing: ReachuSpacing.xs) {
                    Image(systemName: systemImage)
                        .font(.title2)
                        .foregroundColor(color)
                    
                    if let text = text {
                        Text(text)
                            .font(ReachuTypography.caption1)
                            .foregroundColor(color)
                            .multilineTextAlignment(.center)
                    }
                }
            )
    }
    
    // MARK: - Computed Properties
    
    /// Imágenes ordenadas por el campo 'order', priorizando 0 y 1
    private var sortedImages: [DemoProductImage] {
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

#Preview {
    ContentView()
}
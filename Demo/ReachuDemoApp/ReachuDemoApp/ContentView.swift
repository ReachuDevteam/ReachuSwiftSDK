//
//  ContentView.swift
//  ReachuDemoApp
//
//  Created by Angelo Sepulveda on 19/09/2025.
//

import SwiftUI
import ReachuCore
import ReachuDesignSystem
import ReachuUI
import ReachuTesting
import ReachuLiveShow

struct ContentView: View {
    @StateObject private var cartManager = CartManager()
    
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
                        DemoSection(title: "Product Catalog", description: "Browse and add products to cart") {
                            ProductCatalogDemoView()
                                .environmentObject(cartManager)
                        }
                        
                        DemoSection(title: "Product Sliders", description: "Horizontal scrolling product collections") {
                            ProductSliderDemoView()
                                .environmentObject(cartManager)
                        }
                        
                        DemoSection(title: "Shopping Cart", description: "Manage items in your cart") {
                            ShoppingCartDemoView()
                                .environmentObject(cartManager)
                        }
                        
                        DemoSection(title: "Checkout Flow", description: "Simulate the checkout process") {
                            CheckoutDemoView()
                                .environmentObject(cartManager)
                        }
                        
                        DemoSection(title: "Floating Cart Options", description: "Test different positions and styles") {
                            FloatingCartDemoView()
                                .environmentObject(cartManager)
                        }

                        DemoSection(title: "Live Show Player", description: "Simple HLS player demo (Vimeo URL fallback)") {
                            LiveShowDemoView()
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
        .environmentObject(cartManager)
        .sheet(isPresented: $cartManager.isCheckoutPresented) {
            RCheckoutOverlay()
                .environmentObject(cartManager)
        }
        .overlay {
            // Global floating cart indicator
            RFloatingCartIndicator()
                .environmentObject(cartManager)
        }
        .overlay {
            // Global toast notifications
            RToastOverlay()
        }
    }
}

struct DemoSection<Destination: View>: View {
    let title: String
    let description: String
    @ViewBuilder let destination: () -> Destination
    
    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: ReachuSpacing.md) {
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

struct ProductCatalogDemoView: View {
    @EnvironmentObject var cartManager: CartManager
    @State private var isSelectedVariant: RProductCard.Variant = .grid
    private let products = MockDataProvider.shared.sampleProducts
    
    var body: some View {
        VStack(spacing: 0) {
            // Variant Selector
            VStack(spacing: ReachuSpacing.sm) {
                Text("Choose Layout")
                    .font(ReachuTypography.headline)
                    .foregroundColor(ReachuColors.textPrimary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: ReachuSpacing.sm) {
                        VariantButton(title: "Grid", isSelected: isSelectedVariant == .grid) {
                            isSelectedVariant = .grid
                        }
                        VariantButton(title: "List", isSelected: isSelectedVariant == .list) {
                            isSelectedVariant = .list
                        }
                        VariantButton(title: "Hero", isSelected: isSelectedVariant == .hero) {
                            isSelectedVariant = .hero
                        }
                        VariantButton(title: "Minimal", isSelected: isSelectedVariant == .minimal) {
                            isSelectedVariant = .minimal
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
                    switch isSelectedVariant {
                    case .grid:
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: ReachuSpacing.md) {
                            ForEach(products) { product in
                                RProductCard(
                                    product: product,
                                    variant: .grid,
                                    onTap: { print("Tapped: \(product.title)") },
                                    onAddToCart: {
                                        Task {
                                            await cartManager.addProduct(product)
                                        }
                                    }
                                )
                            }
                        }
                        .padding(ReachuSpacing.lg)
                        
                    case .list:
                        LazyVStack(spacing: ReachuSpacing.sm) {
                            ForEach(products) { product in
                                RProductCard(
                                    product: product,
                                    variant: .list,
                                    onTap: { print("Tapped: \(product.title)") },
                                    onAddToCart: {
                                        Task {
                                            await cartManager.addProduct(product)
                                        }
                                    }
                                )
                            }
                        }
                        .padding(ReachuSpacing.lg)
                        
                    case .hero:
                        LazyVStack(spacing: ReachuSpacing.xl) {
                            ForEach(products) { product in
                                RProductCard(
                                    product: product,
                                    variant: .hero,
                                    showDescription: true,
                                    onTap: { print("Tapped: \(product.title)") },
                                    onAddToCart: {
                                        Task {
                                            await cartManager.addProduct(product)
                                        }
                                    }
                                )
                            }
                        }
                        .padding(ReachuSpacing.lg)
                        
                    case .minimal:
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: ReachuSpacing.sm) {
                                ForEach(products) { product in
                                    RProductCard(
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
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(ReachuTypography.caption1)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : ReachuColors.primary)
                .padding(.horizontal, ReachuSpacing.md)
                .padding(.vertical, ReachuSpacing.xs)
                .background(isSelected ? ReachuColors.primary : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: ReachuBorderRadius.circle)
                        .stroke(ReachuColors.primary, lineWidth: 1)
                )
                .cornerRadius(ReachuBorderRadius.circle)
        }
    }
}


struct ShoppingCartDemoView: View {
    @EnvironmentObject var cartManager: CartManager
    
    var body: some View {
        VStack(spacing: ReachuSpacing.lg) {
            // Header
            VStack(spacing: ReachuSpacing.sm) {
                Text("Shopping Cart")
                    .font(ReachuTypography.largeTitle)
                    .foregroundColor(ReachuColors.primary)
                
                HStack {
                    Text("\(cartManager.itemCount) items")
                        .font(ReachuTypography.body)
                        .foregroundColor(ReachuColors.textSecondary)
                    
                    Spacer()
                    
                    Text("Total: \(cartManager.currency) \(String(format: "%.2f", cartManager.cartTotal))")
                        .font(ReachuTypography.headline)
                        .foregroundColor(ReachuColors.primary)
                }
                .padding(.horizontal, ReachuSpacing.lg)
            }
            .padding(.top, ReachuSpacing.lg)
            
            if cartManager.items.isEmpty {
                // Empty cart
                VStack(spacing: ReachuSpacing.lg) {
                    Spacer()
                    
                    Image(systemName: "cart")
                        .font(.system(size: 48))
                        .foregroundColor(ReachuColors.textSecondary)
                    
                    Text("Your cart is empty")
                        .font(ReachuTypography.headline)
                        .foregroundColor(ReachuColors.textSecondary)
                    
                    Text("Add some products from the catalog")
                        .font(ReachuTypography.body)
                        .foregroundColor(ReachuColors.textTertiary)
                    
                    Spacer()
                }
            } else {
                // Cart items
                ScrollView {
                    LazyVStack(spacing: ReachuSpacing.md) {
                        ForEach(cartManager.items) { item in
                            CartItemRowDemo(item: item, cartManager: cartManager)
                        }
                    }
                    .padding(.horizontal, ReachuSpacing.lg)
                }
                
                // Checkout button
                VStack(spacing: 0) {
                    Divider()
                    
                    RButton(
                        title: "Proceed to Checkout",
                        style: .primary,
                        size: .large,
                        isLoading: cartManager.isLoading
                    ) {
                        cartManager.showCheckout()
                    }
                    .padding(.horizontal, ReachuSpacing.lg)
                    .padding(.vertical, ReachuSpacing.md)
                }
                .background(ReachuColors.surface)
            }
        }
        .navigationTitle("Cart")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !cartManager.items.isEmpty {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear") {
                        Task {
                            await cartManager.clearCart()
                        }
                    }
                    .foregroundColor(ReachuColors.error)
                }
            }
        }
    }
}

struct CheckoutDemoView: View {
    @EnvironmentObject var cartManager: CartManager
    
    var body: some View {
        VStack(spacing: ReachuSpacing.xl) {
            VStack(spacing: ReachuSpacing.lg) {
                Text("Checkout Demo")
                    .font(ReachuTypography.largeTitle)
                    .foregroundColor(ReachuColors.primary)
                
                Text("This demo shows the checkout system integration")
                    .font(ReachuTypography.body)
                    .foregroundColor(ReachuColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, ReachuSpacing.xl)
            
            VStack(spacing: ReachuSpacing.lg) {
                // Cart Summary
                VStack(alignment: .leading, spacing: ReachuSpacing.sm) {
                    Text("Current Cart")
                        .font(ReachuTypography.headline)
                        .foregroundColor(ReachuColors.textPrimary)
                    
                    HStack {
                        Text("Items:")
                        Spacer()
                        Text("\(cartManager.itemCount)")
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text("Total:")
                        Spacer()
                        Text("\(cartManager.currency) \(String(format: "%.2f", cartManager.cartTotal))")
                            .fontWeight(.semibold)
                            .foregroundColor(ReachuColors.primary)
                    }
                }
                .padding(ReachuSpacing.md)
                .background(ReachuColors.surface)
                .cornerRadius(ReachuBorderRadius.medium)
                .shadow(color: ReachuColors.textPrimary.opacity(0.1), radius: 2, x: 0, y: 1)
                
                // Add Sample Products
                VStack(alignment: .leading, spacing: ReachuSpacing.md) {
                    Text("Quick Add to Cart")
                        .font(ReachuTypography.headline)
                        .foregroundColor(ReachuColors.textPrimary)
                    
                    let sampleProducts = Array(MockDataProvider.shared.sampleProducts.prefix(3))
                    ForEach(sampleProducts) { product in
                        HStack {
                            VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
                                Text(product.title)
                                    .font(ReachuTypography.bodyBold)
                                    .lineLimit(1)
                                
                                Text("\(product.price.currency_code) \(String(format: "%.2f", product.price.amount))")
                                    .font(ReachuTypography.body)
                                    .foregroundColor(ReachuColors.primary)
                            }
                            
                            Spacer()
                            
                            RButton(
                                title: "Add",
                                style: .secondary,
                                size: .small,
                                isLoading: cartManager.isLoading
                            ) {
                                Task {
                                    await cartManager.addProduct(product)
                                }
                            }
                        }
                        .padding(ReachuSpacing.sm)
                        .background(ReachuColors.surfaceSecondary)
                        .cornerRadius(ReachuBorderRadius.small)
                    }
                }
                
                // Checkout Button
                VStack(spacing: ReachuSpacing.sm) {
                    RButton(
                        title: "Open Checkout Overlay",
                        style: .primary,
                        size: .large,
                        isDisabled: cartManager.items.isEmpty
                    ) {
                        cartManager.showCheckout()
                    }
                    
                    if cartManager.items.isEmpty {
                        Text("Add items to enable checkout")
                            .font(ReachuTypography.caption1)
                            .foregroundColor(ReachuColors.textSecondary)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, ReachuSpacing.lg)
        }
        .navigationTitle("Checkout")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !cartManager.items.isEmpty {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear Cart") {
                        Task {
                            await cartManager.clearCart()
                        }
                    }
                    .foregroundColor(ReachuColors.error)
                }
            }
        }
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
    @EnvironmentObject var cartManager: CartManager
    @State private var isSelectedLayout: ProductSliderLayout = .featured
    private let products = MockDataProvider.shared.sampleProducts
    
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
                                isSelected: isSelectedLayout == layout
                            ) {
                                isSelectedLayout = layout
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
        switch isSelectedLayout {
        case .showcase:
            RProductSlider(
                title: "Premium Collection",
                products: Array(products.prefix(3)),
                layout: .showcase,
                showSeeAll: true,
                onProductTap: { product in
                    print("Showcase tapped: \(product.title)")
                },
                onAddToCart: { product in
                    Task {
                        await cartManager.addProduct(product)
                    }
                },
                onSeeAllTap: {
                    print("See all showcase")
                }
            )
            
        case .wide:
            RProductSlider(
                title: "Detailed Browse",
                products: Array(products.prefix(4)),
                layout: .wide,
                showSeeAll: true,
                onProductTap: { product in
                    print("Wide tapped: \(product.title)")
                },
                onAddToCart: { product in
                    Task {
                        await cartManager.addProduct(product)
                    }
                },
                onSeeAllTap: {
                    print("See all wide")
                }
            )
            
        case .featured:
            RProductSlider(
                title: "Featured Products",
                products: Array(products.prefix(5)),
                layout: .featured,
                showSeeAll: true,
                onProductTap: { product in
                    print("Featured tapped: \(product.title)")
                },
                onAddToCart: { product in
                    Task {
                        await cartManager.addProduct(product)
                    }
                },
                onSeeAllTap: {
                    print("See all featured")
                }
            )
            
        case .cards:
            RProductSlider(
                title: "Electronics",
                products: Array(products.prefix(6)),
                layout: .cards,
                showSeeAll: true,
                onProductTap: { product in
                    print("Cards tapped: \(product.title)")
                },
                onAddToCart: { product in
                    Task {
                        await cartManager.addProduct(product)
                    }
                },
                onSeeAllTap: {
                    print("See all cards")
                }
            )
            
        case .compact:
            RProductSlider(
                title: "You Might Like",
                products: Array(products.prefix(8)),
                layout: .compact,
                showSeeAll: true,
                onProductTap: { product in
                    print("Compact tapped: \(product.title)")
                },
                onSeeAllTap: {
                    print("See all recommendations")
                }
            )
            
        case .micro:
            RProductSlider(
                title: "Related Items",
                products: Array(products.prefix(12)),
                layout: .micro,
                showSeeAll: true,
                onProductTap: { product in
                    print("Micro tapped: \(product.title)")
                },
                onSeeAllTap: {
                    print("See all related")
                }
            )
        }
    }
    
    @ViewBuilder
    private var layoutInfo: some View {
        switch isSelectedLayout {
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
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(ReachuTypography.caption1)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : ReachuColors.primary)
                .padding(.horizontal, ReachuSpacing.md)
                .padding(.vertical, ReachuSpacing.xs)
                .background(isSelected ? ReachuColors.primary : Color.clear)
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

// MARK: - Live Show Demo View
import AVKit

struct LiveShowDemoView: View {
    //let fallback = URL(string: "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8")
    //private let fallback = URL(string: "https://player.vimeo.com/video/1029631656?h=0ff2313a99")
    private let fallback = URL(string: "https://live-ak2.vimeocdn.com/c24948a1-8510-47b9-a65f-a5ba4ccce999/hls.m3u8?hdnts=exp%3D1758656274~acl%3D%252Fc24948a1-8510-47b9-a65f-a5ba4ccce999%252Fhls.m3u8%252A~hmac%3Dd5c00e0a1c814c6b2190f71c27a567ce658ed4248e81955c2a5b2a10ef4e480a")
    //private let fallback = URL(string: "https://vimeo.com/event/5342050")
    private let endpoint = URL(string: "https://example.com/refresh-hls")! // Reemplazar con tu API real
    var body: some View {
        VStack(spacing: ReachuSpacing.md) {
            Text("Live Show Player Demo")
                .font(ReachuTypography.headline)
                .foregroundColor(ReachuColors.textPrimary)
            ReachuLiveShowPlayer.playerView(
                liveStreamId: "test", // simula que no hay streamId => usa fallback
                fallbackURL: fallback,
                config: ReachuLiveShowPlayer.Configuration(refreshHLSEndpoint: endpoint, apiKey: ""),
                isMuted: true,
                autoplay: true
            )
            .frame(height: UIScreen.main.bounds.height * 0.7)
            .cornerRadius(12)
        }
        .padding()
        .navigationTitle("Live Show")
        .navigationBarTitleDisplayMode(.inline)
    }
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

// MARK: - Cart Item Row for Demo

struct CartItemRowDemo: View {
    let item: CartManager.CartItem
    let cartManager: CartManager
    
    var body: some View {
        HStack(spacing: ReachuSpacing.md) {
            // Product Image
            AsyncImage(url: URL(string: item.imageUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(ReachuColors.background)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundColor(ReachuColors.textSecondary)
                    }
            }
            .frame(width: 60, height: 60)
            .cornerRadius(ReachuBorderRadius.medium)
            
            // Product Info
            VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
                Text(item.title)
                    .font(ReachuTypography.bodyBold)
                    .lineLimit(2)
                
                if let brand = item.brand {
                    Text(brand)
                        .font(ReachuTypography.caption1)
                        .foregroundColor(ReachuColors.textSecondary)
                }
                
                Text("\(item.currency) \(String(format: "%.2f", item.price))")
                    .font(ReachuTypography.body)
                    .foregroundColor(ReachuColors.primary)
            }
            
            Spacer()
            
            // Quantity Controls
            VStack(spacing: ReachuSpacing.xs) {
                HStack(spacing: ReachuSpacing.xs) {
                    Button("-") {
                        if item.quantity > 1 {
                            Task {
                                await cartManager.updateQuantity(for: item, to: item.quantity - 1)
                            }
                        }
                    }
                    .frame(width: 32, height: 32)
                    .background(ReachuColors.background)
                    .cornerRadius(ReachuBorderRadius.small)
                    
                    Text("\(item.quantity)")
                        .font(ReachuTypography.bodyBold)
                        .frame(minWidth: 24)
                    
                    Button("+") {
                        Task {
                            await cartManager.updateQuantity(for: item, to: item.quantity + 1)
                        }
                    }
                    .frame(width: 32, height: 32)
                    .background(ReachuColors.background)
                    .cornerRadius(ReachuBorderRadius.small)
                }
                
                Button("Remove") {
                    Task {
                        await cartManager.removeItem(item)
                    }
                }
                .font(ReachuTypography.caption1)
                .foregroundColor(ReachuColors.error)
            }
        }
        .padding(ReachuSpacing.md)
        .background(ReachuColors.surface)
        .cornerRadius(ReachuBorderRadius.medium)
        .shadow(color: ReachuColors.textPrimary.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Floating Cart Demo View
struct FloatingCartDemoView: View {
    @EnvironmentObject var cartManager: CartManager
    @State private var selectedPosition: RFloatingCartIndicator.Position = .bottomRight
    @State private var selectedDisplayMode: RFloatingCartIndicator.DisplayMode = .full
    @State private var selectedSize: RFloatingCartIndicator.Size = .medium
    @State private var showConfiguredIndicator = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Configuration Section
            VStack(spacing: ReachuSpacing.lg) {
                Text("Configure Floating Cart")
                    .font(ReachuTypography.headline)
                    .foregroundColor(ReachuColors.textPrimary)
                
                // Position Selection
                VStack(alignment: .leading, spacing: ReachuSpacing.sm) {
                    Text("Position")
                        .font(ReachuTypography.bodyBold)
                        .foregroundColor(ReachuColors.textPrimary)
                    
                    VStack(spacing: ReachuSpacing.sm) {
                        // Top row
                        HStack(spacing: ReachuSpacing.sm) {
                            PositionButton(position: .topLeft, isSelected: selectedPosition == .topLeft) { selectedPosition = .topLeft }
                            PositionButton(position: .topCenter, isSelected: selectedPosition == .topCenter) { selectedPosition = .topCenter }
                            PositionButton(position: .topRight, isSelected: selectedPosition == .topRight) { selectedPosition = .topRight }
                        }
                        
                        // Center row
                        HStack(spacing: ReachuSpacing.sm) {
                            PositionButton(position: .centerLeft, isSelected: selectedPosition == .centerLeft) { selectedPosition = .centerLeft }
                            Spacer().frame(width: 80) // Empty space for center
                            PositionButton(position: .centerRight, isSelected: selectedPosition == .centerRight) { selectedPosition = .centerRight }
                        }
                        
                        // Bottom row
                        HStack(spacing: ReachuSpacing.sm) {
                            PositionButton(position: .bottomLeft, isSelected: selectedPosition == .bottomLeft) { selectedPosition = .bottomLeft }
                            PositionButton(position: .bottomCenter, isSelected: selectedPosition == .bottomCenter) { selectedPosition = .bottomCenter }
                            PositionButton(position: .bottomRight, isSelected: selectedPosition == .bottomRight) { selectedPosition = .bottomRight }
                        }
                    }
                }
                
                // Display Mode Selection
                VStack(alignment: .leading, spacing: ReachuSpacing.sm) {
                    Text("Display Mode")
                        .font(ReachuTypography.bodyBold)
                        .foregroundColor(ReachuColors.textPrimary)
                    
                    HStack(spacing: ReachuSpacing.sm) {
                        ForEach([
                            RFloatingCartIndicator.DisplayMode.full,
                            .compact,
                            .minimal,
                            .iconOnly
                        ], id: \.self) { mode in
                            ModeButton(
                                mode: mode,
                                isSelected: selectedDisplayMode == mode
                            ) {
                                selectedDisplayMode = mode
                            }
                        }
                    }
                }
                
                // Size Selection
                VStack(alignment: .leading, spacing: ReachuSpacing.sm) {
                    Text("Size")
                        .font(ReachuTypography.bodyBold)
                        .foregroundColor(ReachuColors.textPrimary)
                    
                    HStack(spacing: ReachuSpacing.sm) {
                        ForEach([
                            RFloatingCartIndicator.Size.small,
                            .medium,
                            .large
                        ], id: \.self) { size in
                            SizeButton(
                                size: size,
                                isSelected: selectedSize == size
                            ) {
                                selectedSize = size
                            }
                        }
                    }
                }
                
                // Preview Button
                RButton(
                    title: showConfiguredIndicator ? "Hide Preview" : "Show Preview",
                    style: showConfiguredIndicator ? .secondary : .primary,
                    icon: showConfiguredIndicator ? "eye.slash" : "eye"
                ) {
                    showConfiguredIndicator.toggle()
                }
            }
            .padding(ReachuSpacing.lg)
            .background(ReachuColors.surface)
            .cornerRadius(ReachuBorderRadius.large)
            .shadow(color: ReachuColors.textPrimary.opacity(0.1), radius: 4, x: 0, y: 2)
            .padding(.horizontal, ReachuSpacing.lg)
            
            Spacer()
            
            if !showConfiguredIndicator {
                Text("Add items to cart to see the floating cart indicator")
                    .font(ReachuTypography.body)
                    .foregroundColor(ReachuColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(ReachuSpacing.lg)
            }
        }
        .navigationTitle("Floating Cart")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if showConfiguredIndicator {
                RFloatingCartIndicator(
                    position: selectedPosition,
                    displayMode: selectedDisplayMode,
                    size: selectedSize
                )
                .environmentObject(cartManager)
            }
        }
        .onAppear {
            // Add a sample product if cart is empty
            if cartManager.itemCount == 0 {
                Task {
                    await cartManager.addProduct(MockDataProvider.shared.sampleProducts[0])
                }
            }
        }
    }
}

// MARK: - Helper Buttons
struct PositionButton: View {
    let position: RFloatingCartIndicator.Position
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(position.displayName)
                .font(ReachuTypography.caption1)
                .foregroundColor(isSelected ? .white : ReachuColors.textPrimary)
                .padding(.horizontal, ReachuSpacing.sm)
                .padding(.vertical, ReachuSpacing.xs)
                .background(isSelected ? ReachuColors.primary : ReachuColors.background)
                .cornerRadius(ReachuBorderRadius.small)
        }
    }
}

struct ModeButton: View {
    let mode: RFloatingCartIndicator.DisplayMode
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(mode.displayName)
                .font(ReachuTypography.caption1)
                .foregroundColor(isSelected ? .white : ReachuColors.textPrimary)
                .padding(.horizontal, ReachuSpacing.sm)
                .padding(.vertical, ReachuSpacing.xs)
                .background(isSelected ? ReachuColors.primary : ReachuColors.background)
                .cornerRadius(ReachuBorderRadius.small)
        }
    }
}

struct SizeButton: View {
    let size: RFloatingCartIndicator.Size
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(size.displayName)
                .font(ReachuTypography.caption1)
                .foregroundColor(isSelected ? .white : ReachuColors.textPrimary)
                .padding(.horizontal, ReachuSpacing.sm)
                .padding(.vertical, ReachuSpacing.xs)
                .background(isSelected ? ReachuColors.primary : ReachuColors.background)
                .cornerRadius(ReachuBorderRadius.small)
        }
    }
}

// MARK: - Display Name Extensions
extension RFloatingCartIndicator.Position {
    var displayName: String {
        switch self {
        case .topLeft: return "Top Left"
        case .topCenter: return "Top Center"
        case .topRight: return "Top Right"
        case .centerLeft: return "Center Left"
        case .centerRight: return "Center Right"
        case .bottomLeft: return "Bottom Left"
        case .bottomCenter: return "Bottom Center"
        case .bottomRight: return "Bottom Right"
        }
    }
}

extension RFloatingCartIndicator.DisplayMode {
    var displayName: String {
        switch self {
        case .full: return "Full"
        case .compact: return "Compact"
        case .minimal: return "Minimal"
        case .iconOnly: return "Icon Only"
        }
    }
}

extension RFloatingCartIndicator.Size {
    var displayName: String {
        switch self {
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        }
    }
}

#Preview {
    ContentView()
}

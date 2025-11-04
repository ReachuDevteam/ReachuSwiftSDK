//
//  ContentView.swift
//  ReachuDemoApp
//
//  Created by Angelo Sepulveda on 19/09/2025.
//

import AVKit
import ReachuCore
import ReachuDesignSystem
import ReachuLiveShow
import ReachuLiveUI
import ReachuTesting
import ReachuUI
import SwiftUI

struct ContentView: View {
    @StateObject private var cartManager = CartManager()
    @StateObject private var checkoutDraft = CheckoutDraft()

    @Environment(\.colorScheme) private var colorScheme

    // Colors based on theme and color scheme
    private var adaptiveColors: AdaptiveColors {
        ReachuColors.adaptive(for: colorScheme)
    }
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: ReachuSpacing.xl) {
                    VStack(spacing: ReachuSpacing.md) {
                        Text("Reachu SDK")
                            .font(ReachuTypography.largeTitle)
                            .foregroundColor(adaptiveColors.primary)

                        Text("Demo iOS App")
                            .font(ReachuTypography.body)
                            .foregroundColor(adaptiveColors.textPrimary)
                    }
                    .padding(.top, ReachuSpacing.xl)

                    RMarketSelector()
                        .environmentObject(cartManager)

                    // NEW: Auto-Loading Product Slider Demo
                    VStack(alignment: .leading, spacing: ReachuSpacing.sm) {
                        Text("🚀 Auto-Loading Products")
                            .font(ReachuTypography.headline)
                            .foregroundColor(adaptiveColors.textPrimary)
                            .padding(.horizontal, ReachuSpacing.lg)
                        
                        Text("Products load automatically from the API - no manual code needed!")
                            .font(ReachuTypography.caption1)
                            .foregroundColor(adaptiveColors.textSecondary)
                            .padding(.horizontal, ReachuSpacing.lg)
                        
                        // Automatically loads products from API
                        RProductSlider(
                            title: "Featured Products",
                            layout: .cards,
                            showSeeAll: true,
                            onProductTap: { product in
                                print("Tapped: \(product.title)")
                            },
                            onAddToCart: { product in
                                Task {
                                    await cartManager.addProduct(product)
                                }
                            },
                            currency: cartManager.currency,
                            country: cartManager.country
                        )
                        .environmentObject(cartManager)
                    }
                    .padding(.vertical, ReachuSpacing.md)

                    // NEW: Auto-Configured Campaign Components
                    VStack(alignment: .leading, spacing: ReachuSpacing.md) {
                        Text("✨ Auto-Configured Campaign Components")
                            .font(ReachuTypography.headline)
                            .foregroundColor(adaptiveColors.textPrimary)
                            .padding(.horizontal, ReachuSpacing.lg)
                        
                        Text("These components automatically configure themselves from the active campaign!")
                            .font(ReachuTypography.caption1)
                            .foregroundColor(adaptiveColors.textSecondary)
                            .padding(.horizontal, ReachuSpacing.lg)
                        
                        // Product Banner (auto-configured)
                        RProductBanner()
                            .padding(.horizontal, ReachuSpacing.lg)
                        
                        // Product Carousel (auto-configured)
                        VStack(alignment: .leading, spacing: ReachuSpacing.sm) {
                            Text("Featured Products")
                                .font(ReachuTypography.headline)
                                .foregroundColor(adaptiveColors.textPrimary)
                                .padding(.horizontal, ReachuSpacing.lg)
                            
                            RProductCarousel()
                        }
                        
                        // Product Store (auto-configured)
                        VStack(alignment: .leading, spacing: ReachuSpacing.sm) {
                            Text("Product Store")
                                .font(ReachuTypography.headline)
                                .foregroundColor(adaptiveColors.textPrimary)
                                .padding(.horizontal, ReachuSpacing.lg)
                            
                            RProductStore()
                        }
                    }
                    .padding(.vertical, ReachuSpacing.md)

                    // Demo Sections
                    VStack(spacing: ReachuSpacing.lg) {
                        DemoSection(
                            title: "Product Catalog", description: "Browse and add products to cart"
                        ) {
                            ProductCatalogDemoView()
                                .environmentObject(cartManager)
                                .environmentObject(checkoutDraft)
                        }

                        DemoSection(
                            title: "Product Sliders",
                            description: "Horizontal scrolling product collections"
                        ) {
                            ProductSliderDemoView()
                                .environmentObject(cartManager)
                                .environmentObject(checkoutDraft)
                        }

                        DemoSection(
                            title: "Shopping Cart", description: "Manage items in your cart"
                        ) {
                            ShoppingCartDemoView()
                                .environmentObject(cartManager)
                                .environmentObject(checkoutDraft)
                        }

                        DemoSection(
                            title: "Checkout Flow", description: "Simulate the checkout process"
                        ) {
                            CheckoutDemoView()
                                .environmentObject(cartManager)
                                .environmentObject(checkoutDraft)
                        }

                        DemoSection(
                            title: "Floating Cart Options",
                            description: "Test different positions and styles"
                        ) {
                            FloatingCartDemoView()
                                .environmentObject(cartManager)
                                .environmentObject(checkoutDraft)
                        }

                        DemoSection(
                            title: "Live Show Experience",
                            description: "Interactive live streaming with shopping"
                        ) {
                            LiveShowDemoView()
                                .environmentObject(cartManager)
                                .environmentObject(checkoutDraft)
                        }
                    }
                    .padding(.horizontal, ReachuSpacing.lg)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, ReachuSpacing.xl)
            }
            .navigationTitle("Reachu Demo")
            .navigationBarTitleDisplayMode(.inline)
            .background(adaptiveColors.background)
            .preferredColorScheme(nil)  // Respect system setting
            .onChange(of: colorScheme) { newColorScheme in
                print(
                    "🎨 [Demo] Color scheme changed to: \(newColorScheme == .dark ? "dark" : "light")"
                )

                // Update static ReachuColors to match new color scheme
                ReachuColors.updateForColorScheme(newColorScheme)

                // Also reload configuration to ensure everything is in sync
                do {
                    try ConfigurationLoader.loadConfiguration()
                    print("✅ [Demo] Configuration reloaded for theme change")
                } catch {
                    print("❌ [Demo] Failed to reload configuration: \(error)")
                }
            }
        }
        .environmentObject(cartManager)
        .environmentObject(checkoutDraft)
        .sheet(isPresented: $cartManager.isCheckoutPresented) {
            RCheckoutOverlay()
                .environmentObject(cartManager)
                .environmentObject(checkoutDraft)
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
        .overlay {
            // Global live stream overlay
            LiveStreamGlobalOverlay()
                .environmentObject(cartManager)
        }
    }
}

struct DemoSection<Destination: View>: View {
    let title: String
    let description: String
    @ViewBuilder let destination: () -> Destination

    @Environment(\.colorScheme) private var colorScheme

    // Colors based on theme and color scheme
    private var adaptiveColors: AdaptiveColors {
        ReachuColors.adaptive(for: colorScheme)
    }

    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: ReachuSpacing.md) {
                VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
                    Text(title)
                        .font(ReachuTypography.headline)
                        .foregroundColor(adaptiveColors.textPrimary)

                    Text(description)
                        .font(ReachuTypography.body)
                        .foregroundColor(adaptiveColors.textSecondary)
                }

                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(adaptiveColors.textTertiary)
            }
            .padding(ReachuSpacing.lg)
            .background(adaptiveColors.surface)
            .cornerRadius(ReachuBorderRadius.large)
            .shadow(color: adaptiveColors.textPrimary.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Demo Views

struct ProductCatalogDemoView: View {
    @EnvironmentObject var cartManager: CartManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var isSelectedVariant: RProductCard.Variant = .grid

    // Colors based on theme and color scheme
    private var adaptiveColors: AdaptiveColors {
        ReachuColors.adaptive(for: colorScheme)
    }

    private var products: [Product] {
        cartManager.products
    }

    private var isLoadingProducts: Bool {
        cartManager.isProductsLoading
    }

    private var productsErrorMessage: String? {
        cartManager.productsErrorMessage
    }

    var body: some View {
        VStack(spacing: 0) {
            // Variant Selector
            VStack(spacing: ReachuSpacing.sm) {
                Text("Choose Layout")
                    .font(ReachuTypography.headline)
                    .foregroundColor(adaptiveColors.textPrimary)

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
            .background(adaptiveColors.surfaceSecondary)

            // Products Display
            ScrollView {
                Group {
                    if isLoadingProducts && products.isEmpty {
                        ProgressView("Loading products…")
                            .progressViewStyle(CircularProgressViewStyle())
                            .tint(adaptiveColors.primary)
                            .frame(maxWidth: .infinity)
                            .padding(ReachuSpacing.lg)
                    } else if let errorMessage = productsErrorMessage {
                        VStack(spacing: ReachuSpacing.sm) {
                            Text("Unable to load products")
                                .font(ReachuTypography.bodyBold)
                                .foregroundColor(adaptiveColors.textPrimary)

                            Text(errorMessage)
                                .font(ReachuTypography.caption1)
                                .foregroundColor(adaptiveColors.textSecondary)
                                .multilineTextAlignment(.center)

                            Button("Retry") {
                                Task {
                                    await cartManager.reloadProducts()
                                }
                            }
                            .font(ReachuTypography.caption1)
                            .padding(.horizontal, ReachuSpacing.md)
                            .padding(.vertical, ReachuSpacing.xs)
                            .background(adaptiveColors.primary.opacity(0.12))
                            .cornerRadius(ReachuBorderRadius.circle)
                        }
                        .padding(ReachuSpacing.lg)
                        .frame(maxWidth: .infinity)
                        .background(adaptiveColors.surface)
                        .cornerRadius(ReachuBorderRadius.large)
                        .shadow(color: adaptiveColors.textPrimary.opacity(0.08), radius: 8, x: 0, y: 2)
                    } else if products.isEmpty {
                        Text("No products available right now.")
                            .font(ReachuTypography.body)
                            .foregroundColor(adaptiveColors.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(ReachuSpacing.lg)
                            .background(adaptiveColors.surface)
                            .cornerRadius(ReachuBorderRadius.large)
                            .shadow(color: adaptiveColors.textPrimary.opacity(0.05), radius: 6, x: 0, y: 2)
                    } else {
                        variantView
                    }
                }
            }
        }
        .navigationTitle("Product Cards")
        .navigationBarTitleDisplayMode(.inline)
        .background(adaptiveColors.background)
        .task {
            await cartManager.loadProductsIfNeeded()
        }
    }

    @ViewBuilder
    private var variantView: some View {
        switch isSelectedVariant {
        case .grid:
            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                ], spacing: ReachuSpacing.md
            ) {
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

struct VariantButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    // Colors based on theme and color scheme
    private var adaptiveColors: AdaptiveColors {
        ReachuColors.adaptive(for: colorScheme)
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(ReachuTypography.caption1)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : adaptiveColors.primary)
                .padding(.horizontal, ReachuSpacing.md)
                .padding(.vertical, ReachuSpacing.xs)
                .background(isSelected ? adaptiveColors.primary : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: ReachuBorderRadius.circle)
                        .stroke(adaptiveColors.primary, lineWidth: 1)
                )
                .cornerRadius(ReachuBorderRadius.circle)
        }
    }
}

struct ShoppingCartDemoView: View {
    @EnvironmentObject var cartManager: CartManager
    @EnvironmentObject var checkoutDraft: CheckoutDraft
    @Environment(\.colorScheme) private var colorScheme

    // Colors based on theme and color scheme
    private var adaptiveColors: AdaptiveColors {
        ReachuColors.adaptive(for: colorScheme)
    }

    var body: some View {
        VStack(spacing: ReachuSpacing.lg) {
            // Header
            VStack(spacing: ReachuSpacing.sm) {
                Text("Shopping Cart")
                    .font(ReachuTypography.largeTitle)
                    .foregroundColor(adaptiveColors.primary)

                HStack {
                    Text("\(cartManager.itemCount) items")
                        .font(ReachuTypography.body)
                        .foregroundColor(adaptiveColors.textSecondary)

                    Spacer()

                    Text(
                        "Total: \(cartManager.currencySymbol) \(String(format: "%.2f", cartManager.cartTotal)) \(cartManager.currency)"
                    )
                    .font(ReachuTypography.headline)
                    .foregroundColor(adaptiveColors.primary)
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
                        .foregroundColor(adaptiveColors.textSecondary)

                    Text("Your cart is empty")
                        .font(ReachuTypography.headline)
                        .foregroundColor(adaptiveColors.textSecondary)

                    Text("Add some products from the catalog")
                        .font(ReachuTypography.body)
                        .foregroundColor(adaptiveColors.textTertiary)

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
                        Task {
                            _ = await cartManager.applyCheapestShippingPerSupplier()

                            guard let chkId = await cartManager.createCheckout() else {
                                cartManager.showCheckout()
                                return
                            }

                            let addr: [String: Any] = [
                                "address1": checkoutDraft.address1,
                                "address2": checkoutDraft.address2,
                                "city": checkoutDraft.city,
                                "company": "",
                                "country": checkoutDraft.countryName,
                                "country_code": cartManager.country,
                                "email": checkoutDraft.email,
                                "first_name": checkoutDraft.firstName,
                                "last_name": checkoutDraft.lastName,
                                "phone": checkoutDraft.phone,
                                "phone_code": checkoutDraft.phoneCountryCode.replacingOccurrences(
                                    of: "+", with: ""),
                                "province": checkoutDraft.province,
                                "province_code": "",
                                "zip": checkoutDraft.zip,
                            ]

                            _ = await cartManager.updateCheckout(
                                checkoutId: chkId,
                                email: checkoutDraft.email,
                                successUrl: nil,
                                cancelUrl: nil,
                                paymentMethod: checkoutDraft.paymentMethodRaw.capitalized,
                                shippingAddress: addr,
                                billingAddress: addr,
                                acceptsTerms: checkoutDraft.acceptsTerms,
                                acceptsPurchaseConditions: checkoutDraft.acceptsPurchaseConditions
                            )

                            cartManager.showCheckout()
                        }
                    }

                    .padding(.horizontal, ReachuSpacing.lg)
                    .padding(.vertical, ReachuSpacing.md)
                }
                .background(adaptiveColors.surface)
            }
        }
        .navigationTitle("Cart")
        .navigationBarTitleDisplayMode(.inline)
        .background(adaptiveColors.background)
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
    @Environment(\.colorScheme) private var colorScheme

    // Colors based on theme and color scheme
    private var adaptiveColors: AdaptiveColors {
        ReachuColors.adaptive(for: colorScheme)
    }

    var body: some View {
        VStack(spacing: ReachuSpacing.xl) {
            VStack(spacing: ReachuSpacing.lg) {
                Text("Checkout Demo")
                    .font(ReachuTypography.largeTitle)
                    .foregroundColor(adaptiveColors.primary)

                Text("This demo shows the checkout system integration")
                    .font(ReachuTypography.body)
                    .foregroundColor(adaptiveColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, ReachuSpacing.xl)

            VStack(spacing: ReachuSpacing.lg) {
                // Cart Summary
                VStack(alignment: .leading, spacing: ReachuSpacing.sm) {
                    Text("Current Cart")
                        .font(ReachuTypography.headline)
                        .foregroundColor(adaptiveColors.textPrimary)

                    HStack {
                        Text("Items:")
                        Spacer()
                        Text("\(cartManager.itemCount)")
                            .fontWeight(.semibold)
                    }

                    HStack {
                        Text("Total:")
                        Spacer()
                        Text(
                            "\(cartManager.currencySymbol) \(String(format: "%.2f", cartManager.cartTotal)) \(cartManager.currency)"
                        )
                        .fontWeight(.semibold)
                        .foregroundColor(adaptiveColors.primary)
                    }
                }
                .padding(ReachuSpacing.md)
                .background(adaptiveColors.surface)
                .cornerRadius(ReachuBorderRadius.medium)
                .shadow(color: adaptiveColors.textPrimary.opacity(0.1), radius: 2, x: 0, y: 1)

                // Add Sample Products
                VStack(alignment: .leading, spacing: ReachuSpacing.md) {
                    Text("Quick Add to Cart")
                        .font(ReachuTypography.headline)
                        .foregroundColor(adaptiveColors.textPrimary)

                    let sampleProducts = Array(MockDataProvider.shared.sampleProducts.prefix(3))
                    ForEach(sampleProducts) { product in
                        HStack {
                            VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
                                Text(product.title)
                                    .font(ReachuTypography.bodyBold)
                                    .lineLimit(1)

                                Text(
                                    "\(product.price.currency_code) \(String(format: "%.2f", product.price.amount))"
                                )
                                .font(ReachuTypography.body)
                                .foregroundColor(adaptiveColors.primary)
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
                        .background(adaptiveColors.surfaceSecondary)
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
                            .foregroundColor(adaptiveColors.textSecondary)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, ReachuSpacing.lg)
        }
        .navigationTitle("Checkout")
        .navigationBarTitleDisplayMode(.inline)
        .background(adaptiveColors.background)
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
    @Environment(\.colorScheme) private var colorScheme
    @State private var isSelectedLayout: ProductSliderLayout = .featured

    // Colors based on theme and color scheme
    private var adaptiveColors: AdaptiveColors {
        ReachuColors.adaptive(for: colorScheme)
    }

    private var products: [Product] {
        cartManager.products
    }

    private var isLoadingProducts: Bool {
        cartManager.isProductsLoading
    }

    private var productsErrorMessage: String? {
        cartManager.productsErrorMessage
    }

    var body: some View {
        VStack(spacing: 0) {
            // Layout Selector
            VStack(spacing: ReachuSpacing.sm) {
                Text("Choose Layout Style")
                    .font(ReachuTypography.headline)
                    .foregroundColor(adaptiveColors.textPrimary)

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
            .background(adaptiveColors.surfaceSecondary)

            // Layout Information
            VStack(spacing: ReachuSpacing.sm) {
                layoutInfo
            }
            .padding(.horizontal, ReachuSpacing.lg)
            .padding(.vertical, ReachuSpacing.md)
            .background(adaptiveColors.surfaceSecondary)

            // Selected Layout Display
            ScrollView {
                VStack(spacing: ReachuSpacing.xl) {
                    if isLoadingProducts && products.isEmpty {
                        ProgressView("Loading products…")
                            .progressViewStyle(CircularProgressViewStyle())
                            .tint(adaptiveColors.primary)
                            .frame(maxWidth: .infinity)
                            .padding(ReachuSpacing.lg)
                    } else if let errorMessage = productsErrorMessage {
                        VStack(spacing: ReachuSpacing.sm) {
                            Text("Unable to load products")
                                .font(ReachuTypography.bodyBold)
                                .foregroundColor(adaptiveColors.textPrimary)

                            Text(errorMessage)
                                .font(ReachuTypography.caption1)
                                .foregroundColor(adaptiveColors.textSecondary)
                                .multilineTextAlignment(.center)

                            Button("Retry") {
                                Task {
                                    await cartManager.reloadProducts()
                                }
                            }
                            .font(ReachuTypography.caption1)
                            .padding(.horizontal, ReachuSpacing.md)
                            .padding(.vertical, ReachuSpacing.xs)
                            .background(adaptiveColors.primary.opacity(0.12))
                            .cornerRadius(ReachuBorderRadius.circle)
                        }
                        .padding(ReachuSpacing.lg)
                        .frame(maxWidth: .infinity)
                        .background(adaptiveColors.surface)
                        .cornerRadius(ReachuBorderRadius.large)
                        .shadow(color: adaptiveColors.textPrimary.opacity(0.08), radius: 8, x: 0, y: 2)
                    } else if products.isEmpty {
                        Text("No products available right now.")
                            .font(ReachuTypography.body)
                            .foregroundColor(adaptiveColors.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(ReachuSpacing.lg)
                            .background(adaptiveColors.surface)
                            .cornerRadius(ReachuBorderRadius.large)
                            .shadow(color: adaptiveColors.textPrimary.opacity(0.05), radius: 6, x: 0, y: 2)
                    } else {
                        selectedSliderView
                    }
                }
                .padding(.vertical, ReachuSpacing.lg)
            }
        }
        .navigationTitle("Product Sliders")
        .navigationBarTitleDisplayMode(.inline)
        .background(adaptiveColors.background)
        .task {
            await cartManager.loadProductsIfNeeded()
        }
    }

    @ViewBuilder
    private var selectedSliderView: some View {
        switch isSelectedLayout {
        case .showcase:
            RProductSlider(
                title: "Premium Collection",
                products: productSlice(3),
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
                products: productSlice(4),
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
                products: productSlice(5),
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
                products: productSlice(6),
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
                products: productSlice(8),
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
                products: productSlice(12),
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

    private func productSlice(_ limit: Int) -> [Product] {
        Array(products.prefix(limit))
    }

    @ViewBuilder
    private var layoutInfo: some View {
        switch isSelectedLayout {
        case .showcase:
            LayoutInfoCard(
                title: "Showcase Layout",
                width: "360pt",
                description:
                    "Premium layout for luxury products and special collections with maximum visual impact",
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

    @Environment(\.colorScheme) private var colorScheme

    // Colors based on theme and color scheme
    private var adaptiveColors: AdaptiveColors {
        ReachuColors.adaptive(for: colorScheme)
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(ReachuTypography.caption1)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : adaptiveColors.primary)
                .padding(.horizontal, ReachuSpacing.md)
                .padding(.vertical, ReachuSpacing.xs)
                .background(isSelected ? adaptiveColors.primary : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: ReachuBorderRadius.circle)
                        .stroke(adaptiveColors.primary, lineWidth: 1)
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

    @Environment(\.colorScheme) private var colorScheme

    // Colors based on theme and color scheme
    private var adaptiveColors: AdaptiveColors {
        ReachuColors.adaptive(for: colorScheme)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
            HStack {
                Text(title)
                    .font(ReachuTypography.bodyBold)
                    .foregroundColor(adaptiveColors.textPrimary)

                Spacer()

                Text(width)
                    .font(ReachuTypography.caption1)
                    .foregroundColor(adaptiveColors.textSecondary)
                    .padding(.horizontal, ReachuSpacing.sm)
                    .padding(.vertical, ReachuSpacing.xs)
                    .background(adaptiveColors.background)
                    .cornerRadius(ReachuBorderRadius.small)
            }

            Text(description)
                .font(ReachuTypography.body)
                .foregroundColor(adaptiveColors.textSecondary)

            Text("Use case: \(useCase)")
                .font(ReachuTypography.caption1)
                .foregroundColor(adaptiveColors.textTertiary)
        }
        .padding(ReachuSpacing.md)
        .background(adaptiveColors.surface)
        .cornerRadius(ReachuBorderRadius.medium)
        .shadow(color: adaptiveColors.textPrimary.opacity(0.05), radius: 2, x: 0, y: 1)
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

    init(
        id: Int, title: String, brand: String? = nil, description: String? = nil, sku: String,
        quantity: Int? = nil, price: DemoPrice, images: [DemoProductImage] = []
    ) {
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
            description:
                "Experience immersive sound with premium noise-cancelling technology and crystal clear audio quality.",
            sku: "RCH-HP-001",
            quantity: 50,
            price: DemoPrice(amount: 199.99, currency_code: "USD", compare_at: 249.99),
            images: [
                DemoProductImage(
                    id: "img101-1",
                    url:
                        "https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=400&h=300&fit=crop&crop=center",
                    order: 0),
                DemoProductImage(
                    id: "img101-2",
                    url:
                        "https://images.unsplash.com/photo-1583394838336-acd977736f90?w=400&h=300&fit=crop&crop=center",
                    order: 1),
                DemoProductImage(
                    id: "img101-3",
                    url:
                        "https://images.unsplash.com/photo-1487215078519-e21cc028cb29?w=400&h=300&fit=crop&crop=center",
                    order: 2),
            ]
        ),
        DemoProduct(
            id: 102,
            title: "Reachu Smart Watch Series 5",
            brand: "Reachu Wearables",
            description:
                "Track your fitness, monitor your health, and stay connected with our latest smartwatch featuring advanced sensors.",
            sku: "RCH-SW-005",
            quantity: 30,
            price: DemoPrice(amount: 349.99, currency_code: "USD"),
            images: [
                DemoProductImage(
                    id: "img102-1",
                    url:
                        "https://images.unsplash.com/photo-1434493789847-2f02dc6ca35d?w=400&h=300&fit=crop&crop=center",
                    order: 1),
                DemoProductImage(
                    id: "img102-2",
                    url:
                        "https://images.unsplash.com/photo-1544117519-31a4b719223d?w=400&h=300&fit=crop&crop=center",
                    order: 0),
            ]
        ),
        DemoProduct(
            id: 103,
            title: "Reachu Minimalist Backpack",
            brand: "Reachu Gear",
            description:
                "Stylish and durable backpack perfect for daily commutes, travel, and outdoor adventures.",
            sku: "RCH-BP-001",
            quantity: 0,  // Out of stock
            price: DemoPrice(amount: 89.99, currency_code: "USD", compare_at: 100.00),
            images: [
                DemoProductImage(
                    id: "img103-1",
                    url:
                        "https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=400&h=300&fit=crop&crop=center",
                    order: 0),
                DemoProductImage(
                    id: "img103-2",
                    url:
                        "https://images.unsplash.com/photo-1622560480605-d83c853bc5c3?w=400&h=300&fit=crop&crop=center",
                    order: 1),
                DemoProductImage(
                    id: "img103-3",
                    url:
                        "https://images.unsplash.com/photo-1581605405669-fcdf81165afa?w=400&h=300&fit=crop&crop=center",
                    order: 2),
            ]
        ),
        DemoProduct(
            id: 104,
            title: "Reachu Wireless Charging Pad",
            brand: "Reachu Power",
            description:
                "Fast and convenient wireless charging for all your devices with sleek design and safety features.",
            sku: "RCH-CP-002",
            quantity: 15,  // Back in stock
            price: DemoPrice(amount: 39.99, currency_code: "USD"),
            images: [
                DemoProductImage(
                    id: "img104-1",
                    url:
                        "https://images.unsplash.com/photo-1585338447937-7082f8fc763d?w=400&h=300&fit=crop&crop=center",
                    order: 0),
                DemoProductImage(
                    id: "img104-2",
                    url:
                        "https://images.unsplash.com/photo-1609592373050-87a8f2e04f40?w=400&h=300&fit=crop&crop=center",
                    order: 1),
            ]
        ),
        DemoProduct(
            id: 105,
            title: "Reachu Bluetooth Speaker",
            brand: "Reachu Audio",
            description:
                "Portable bluetooth speaker with 360-degree sound, waterproof design, and 12-hour battery life.",
            sku: "RCH-BT-003",
            quantity: 25,
            price: DemoPrice(amount: 79.99, currency_code: "USD", compare_at: 99.99),
            images: [
                DemoProductImage(
                    id: "img105-1",
                    url:
                        "https://images.unsplash.com/photo-1608043152269-423dbba4e7e1?w=400&h=300&fit=crop&crop=center",
                    order: 1),
                DemoProductImage(
                    id: "img105-2",
                    url:
                        "https://images.unsplash.com/photo-1588422904075-be4be63e1bd6?w=400&h=300&fit=crop&crop=center",
                    order: 0),
                DemoProductImage(
                    id: "img105-3",
                    url:
                        "https://images.unsplash.com/photo-1545454675-3531b543be5d?w=400&h=300&fit=crop&crop=center",
                    order: 2),
            ]
        ),
        DemoProduct(
            id: 106,
            title: "Reachu Gaming Mouse",
            brand: "Reachu Gaming",
            description:
                "High-precision gaming mouse with customizable RGB lighting and ergonomic design.",
            sku: "RCH-GM-004",
            quantity: 40,
            price: DemoPrice(amount: 59.99, currency_code: "USD"),
            images: [
                DemoProductImage(
                    id: "img106-1",
                    url:
                        "https://images.unsplash.com/photo-1527814050087-3793815479db?w=400&h=300&fit=crop&crop=center",
                    order: 0),
                DemoProductImage(
                    id: "img106-2",
                    url:
                        "https://images.unsplash.com/photo-1615663245857-ac93bb7c39e7?w=400&h=300&fit=crop&crop=center",
                    order: 1),
            ]
        ),
    ]
}

struct SimpleProductCard: View {
    let product: DemoProduct
    let variant: ProductCardVariant
    let showBrand: Bool
    let showDescription: Bool
    let onTap: (() -> Void)?
    let onAddToCart: (() -> Void)?

    @Environment(\.colorScheme) private var colorScheme

    // Colors based on theme and color scheme
    private var adaptiveColors: AdaptiveColors {
        ReachuColors.adaptive(for: colorScheme)
    }

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
                        .foregroundColor(adaptiveColors.textSecondary)
                        .lineLimit(1)
                }

                Text(product.title)
                    .font(ReachuTypography.headline)
                    .foregroundColor(adaptiveColors.textPrimary)
                    .lineLimit(2)

                if showDescription, let description = product.description {
                    Text(description)
                        .font(ReachuTypography.caption1)
                        .foregroundColor(adaptiveColors.textSecondary)
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
        .background(adaptiveColors.surface)
        .cornerRadius(ReachuBorderRadius.large)
        .shadow(color: adaptiveColors.textPrimary.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    private var listLayout: some View {
        HStack(spacing: ReachuSpacing.md) {
            productImage(height: 80)
                .frame(width: 80)

            VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
                if showBrand, let brand = product.brand {
                    Text(brand)
                        .font(ReachuTypography.caption1)
                        .foregroundColor(adaptiveColors.textSecondary)
                        .lineLimit(1)
                }

                Text(product.title)
                    .font(ReachuTypography.body)
                    .foregroundColor(adaptiveColors.textPrimary)
                    .lineLimit(2)

                if showDescription, let description = product.description {
                    Text(description)
                        .font(ReachuTypography.caption1)
                        .foregroundColor(adaptiveColors.textSecondary)
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
        .background(adaptiveColors.surface)
        .cornerRadius(ReachuBorderRadius.medium)
        .shadow(color: adaptiveColors.textPrimary.opacity(0.05), radius: 2, x: 0, y: 1)
    }

    private var heroLayout: some View {
        VStack(alignment: .leading, spacing: ReachuSpacing.lg) {
            productImage(height: 240)

            VStack(alignment: .leading, spacing: ReachuSpacing.sm) {
                if showBrand, let brand = product.brand {
                    Text(brand)
                        .font(ReachuTypography.caption1)
                        .foregroundColor(adaptiveColors.textSecondary)
                        .textCase(.uppercase)
                }

                Text(product.title)
                    .font(ReachuTypography.title2)
                    .foregroundColor(adaptiveColors.textPrimary)
                    .lineLimit(3)

                if showDescription, let description = product.description {
                    Text(description)
                        .font(ReachuTypography.body)
                        .foregroundColor(adaptiveColors.textSecondary)
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
        .background(adaptiveColors.surface)
        .cornerRadius(ReachuBorderRadius.xl)
        .shadow(color: adaptiveColors.textPrimary.opacity(0.15), radius: 8, x: 0, y: 4)
    }

    private var minimalLayout: some View {
        VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
            productImage(height: 100)

            VStack(alignment: .leading, spacing: 2) {
                Text(product.title)
                    .font(ReachuTypography.caption1)
                    .foregroundColor(adaptiveColors.textPrimary)
                    .lineLimit(2)

                priceView
            }
            .padding(ReachuSpacing.sm)
        }
        .frame(width: 120)
        .background(adaptiveColors.surface)
        .cornerRadius(ReachuBorderRadius.medium)
        .shadow(color: adaptiveColors.textPrimary.opacity(0.08), radius: 2, x: 0, y: 1)
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
                placeholderView(
                    systemImage: "exclamationmark.triangle", color: ReachuColors.error,
                    text: "Image unavailable")
            case .empty:
                // Cargando - mostrar placeholder con ícono de carga
                placeholderView(
                    systemImage: "photo", color: adaptiveColors.textSecondary, text: nil)
            @unknown default:
                // Fallback - mostrar placeholder genérico
                placeholderView(
                    systemImage: "photo", color: adaptiveColors.textSecondary, text: nil)
            }
        }
        .frame(height: height)
        .clipped()
        .cornerRadius(ReachuBorderRadius.medium)
    }

    /// Placeholder view for loading/error states
    private func placeholderView(systemImage: String, color: Color, text: String?) -> some View {
        Rectangle()
            .fill(adaptiveColors.background)
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
                .foregroundColor(adaptiveColors.primary)

            if let compareAtAmount = product.price.displayCompareAtAmount {
                Text(compareAtAmount)
                    .font(ReachuTypography.caption1)
                    .foregroundColor(adaptiveColors.textSecondary)
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
    @Environment(\.colorScheme) private var colorScheme

    // Colors based on theme and color scheme
    private var adaptiveColors: AdaptiveColors {
        ReachuColors.adaptive(for: colorScheme)
    }

    var body: some View {
        HStack(spacing: ReachuSpacing.md) {
            // Product Image
            AsyncImage(url: URL(string: item.imageUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(adaptiveColors.background)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundColor(adaptiveColors.textSecondary)
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
                        .foregroundColor(adaptiveColors.textSecondary)
                }

                if let variant = item.variantTitle, !variant.isEmpty {
                    Text("Variant: \(variant)")
                        .font(ReachuTypography.caption2)
                        .foregroundColor(adaptiveColors.textTertiary)
                }

                Text("\(cartManager.currencySymbol) \(String(format: "%.2f", item.price)) \(item.currency)")
                    .font(ReachuTypography.body)
                    .foregroundColor(adaptiveColors.primary)
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
                    .background(adaptiveColors.background)
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
                    .background(adaptiveColors.background)
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
        .background(adaptiveColors.surface)
        .cornerRadius(ReachuBorderRadius.medium)
        .shadow(color: adaptiveColors.textPrimary.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Floating Cart Demo View
struct FloatingCartDemoView: View {
    @EnvironmentObject var cartManager: CartManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedPosition: RFloatingCartIndicator.Position = .bottomRight
    @State private var selectedDisplayMode: RFloatingCartIndicator.DisplayMode = .full
    @State private var selectedSize: RFloatingCartIndicator.Size = .medium
    @State private var showConfiguredIndicator = false

    // Colors based on theme and color scheme
    private var adaptiveColors: AdaptiveColors {
        ReachuColors.adaptive(for: colorScheme)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Configuration Section
            VStack(spacing: ReachuSpacing.lg) {
                Text("Configure Floating Cart")
                    .font(ReachuTypography.headline)
                    .foregroundColor(adaptiveColors.textPrimary)

                // Position Selection
                VStack(alignment: .leading, spacing: ReachuSpacing.sm) {
                    Text("Position")
                        .font(ReachuTypography.bodyBold)
                        .foregroundColor(adaptiveColors.textPrimary)

                    VStack(spacing: ReachuSpacing.sm) {
                        // Top row
                        HStack(spacing: ReachuSpacing.sm) {
                            PositionButton(
                                position: .topLeft, isSelected: selectedPosition == .topLeft
                            ) { selectedPosition = .topLeft }
                            PositionButton(
                                position: .topCenter, isSelected: selectedPosition == .topCenter
                            ) { selectedPosition = .topCenter }
                            PositionButton(
                                position: .topRight, isSelected: selectedPosition == .topRight
                            ) { selectedPosition = .topRight }
                        }

                        // Center row
                        HStack(spacing: ReachuSpacing.sm) {
                            PositionButton(
                                position: .centerLeft, isSelected: selectedPosition == .centerLeft
                            ) { selectedPosition = .centerLeft }
                            Spacer().frame(width: 80)  // Empty space for center
                            PositionButton(
                                position: .centerRight, isSelected: selectedPosition == .centerRight
                            ) { selectedPosition = .centerRight }
                        }

                        // Bottom row
                        HStack(spacing: ReachuSpacing.sm) {
                            PositionButton(
                                position: .bottomLeft, isSelected: selectedPosition == .bottomLeft
                            ) { selectedPosition = .bottomLeft }
                            PositionButton(
                                position: .bottomCenter,
                                isSelected: selectedPosition == .bottomCenter
                            ) { selectedPosition = .bottomCenter }
                            PositionButton(
                                position: .bottomRight, isSelected: selectedPosition == .bottomRight
                            ) { selectedPosition = .bottomRight }
                        }
                    }
                }

                // Display Mode Selection
                VStack(alignment: .leading, spacing: ReachuSpacing.sm) {
                    Text("Display Mode")
                        .font(ReachuTypography.bodyBold)
                        .foregroundColor(adaptiveColors.textPrimary)

                    HStack(spacing: ReachuSpacing.sm) {
                        ForEach(
                            [
                                RFloatingCartIndicator.DisplayMode.full,
                                .compact,
                                .minimal,
                                .iconOnly,
                            ], id: \.self
                        ) { mode in
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
                        .foregroundColor(adaptiveColors.textPrimary)

                    HStack(spacing: ReachuSpacing.sm) {
                        ForEach(
                            [
                                RFloatingCartIndicator.Size.small,
                                .medium,
                                .large,
                            ], id: \.self
                        ) { size in
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
            .background(adaptiveColors.surface)
            .cornerRadius(ReachuBorderRadius.large)
            .shadow(color: adaptiveColors.textPrimary.opacity(0.1), radius: 4, x: 0, y: 2)
            .padding(.horizontal, ReachuSpacing.lg)

            Spacer()

            if !showConfiguredIndicator {
                Text("Add items to cart to see the floating cart indicator")
                    .font(ReachuTypography.body)
                    .foregroundColor(adaptiveColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(ReachuSpacing.lg)
            }
        }
        .navigationTitle("Floating Cart")
        .navigationBarTitleDisplayMode(.inline)
        .background(adaptiveColors.background)
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
    @Environment(\.colorScheme) private var colorScheme

    // Colors based on theme and color scheme
    private var adaptiveColors: AdaptiveColors {
        ReachuColors.adaptive(for: colorScheme)
    }

    var body: some View {
        Button(action: action) {
            Text(position.displayName)
                .font(ReachuTypography.caption1)
                .foregroundColor(isSelected ? .white : adaptiveColors.textPrimary)
                .padding(.horizontal, ReachuSpacing.sm)
                .padding(.vertical, ReachuSpacing.xs)
                .background(isSelected ? adaptiveColors.primary : adaptiveColors.background)
                .cornerRadius(ReachuBorderRadius.small)
        }
    }
}

struct ModeButton: View {
    let mode: RFloatingCartIndicator.DisplayMode
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    // Colors based on theme and color scheme
    private var adaptiveColors: AdaptiveColors {
        ReachuColors.adaptive(for: colorScheme)
    }

    var body: some View {
        Button(action: action) {
            Text(mode.displayName)
                .font(ReachuTypography.caption1)
                .foregroundColor(isSelected ? .white : adaptiveColors.textPrimary)
                .padding(.horizontal, ReachuSpacing.sm)
                .padding(.vertical, ReachuSpacing.xs)
                .background(isSelected ? adaptiveColors.primary : adaptiveColors.background)
                .cornerRadius(ReachuBorderRadius.small)
        }
    }
}

struct SizeButton: View {
    let size: RFloatingCartIndicator.Size
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    // Colors based on theme and color scheme
    private var adaptiveColors: AdaptiveColors {
        ReachuColors.adaptive(for: colorScheme)
    }

    var body: some View {
        Button(action: action) {
            Text(size.displayName)
                .font(ReachuTypography.caption1)
                .foregroundColor(isSelected ? .white : adaptiveColors.textPrimary)
                .padding(.horizontal, ReachuSpacing.sm)
                .padding(.vertical, ReachuSpacing.xs)
                .background(isSelected ? adaptiveColors.primary : adaptiveColors.background)
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

// MARK: - Live Stream Overlay

struct LiveStreamGlobalOverlay: View {
    @ObservedObject private var liveShowManager = LiveShowManager.shared
    @EnvironmentObject private var cartManager: CartManager
    @State private var player: AVPlayer?
    @State private var videoStatus: String = "Not loaded"

    var body: some View {
        ZStack {
            // Full screen LiveShow overlay - Use the complete component
            if liveShowManager.isLiveShowVisible {
                RLiveShowFullScreenOverlay()
                    .environmentObject(cartManager)
            } else if false,  // Disabled old overlay
                let stream = liveShowManager.currentStream
            {

                // Video Player Background
                if let player = player {
                    VideoPlayer(player: player)
                        .ignoresSafeArea()
                        .onAppear {
                            player.play()
                        }
                        .onDisappear {
                            player.pause()
                        }
                } else {
                    // Fallback gradient background
                    LinearGradient(
                        colors: [
                            Color.purple.opacity(0.8),
                            Color.blue.opacity(0.6),
                            Color.indigo.opacity(0.9),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                }

                // Dark overlay for UI readability
                Color.black.opacity(0.3)
                    .ignoresSafeArea()

                VStack(spacing: 0) {

                    // Top section with LIVE indicator on the right
                    HStack {
                        Spacer()

                        // Live indicator (moved to right)
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                            Text("LIVE")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(15)
                    }
                    .padding(.top, 50)
                    .padding(.horizontal, 20)

                    Spacer()

                    // Stream info (centered)
                    VStack(spacing: 12) {
                        Text(stream.title)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)

                        Text("by \(stream.streamer.name)")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.8))

                        Text("Layout: \(liveShowManager.layout.displayName)")
                            .font(.system(size: 14))
                            .foregroundColor(.yellow)

                        Text("Video Status: \(videoStatus)")
                            .font(.system(size: 12))
                            .foregroundColor(.orange)
                    }

                    Spacer()

                    // Controls (bottom)
                    HStack(spacing: 20) {
                        Button("Mini Player") {
                            liveShowManager.showMiniPlayer()
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .cornerRadius(15)

                        Button("Close") {
                            liveShowManager.hideLiveStream()
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.red)
                        .cornerRadius(15)
                    }
                    .padding(.bottom, 80)
                }
                .padding()
                .onAppear {
                    setupVideoPlayer()
                }
                .onDisappear {
                    player?.pause()
                    player = nil
                }
            }

            // Mini player indicator
            if liveShowManager.isMiniPlayerVisible,
                let stream = liveShowManager.currentStream
            {

                VStack {
                    Spacer()
                    HStack {
                        Spacer()

                        // Simple mini player
                        VStack(spacing: 4) {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 4, height: 4)
                                Text("LIVE")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(.white)
                            }

                            Text(stream.streamer.name)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white)
                                .lineLimit(1)

                            Button("Expand") {
                                liveShowManager.expandFromMiniPlayer()
                            }
                            .font(.system(size: 8))
                            .foregroundColor(.white)
                        }
                        .padding(8)
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(8)
                        .onTapGesture {
                            liveShowManager.hideLiveStream()
                        }
                    }
                    .padding()
                }
            }

            // Floating indicator
            if liveShowManager.hasActiveLiveStreams && liveShowManager.isIndicatorVisible
                && !liveShowManager.isWatchingLiveStream
            {

                VStack {
                    HStack {
                        Spacer()

                        Button(action: {
                            if let stream = liveShowManager.featuredLiveStream {
                                liveShowManager.showLiveStream(stream, layout: .fullScreenOverlay)
                            }
                        }) {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 6, height: 6)

                                Text("LIVE")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)

                                if let stream = liveShowManager.featuredLiveStream {
                                    Text(stream.streamer.name)
                                        .font(.system(size: 10))
                                        .foregroundColor(.white)
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.black.opacity(0.8))
                            .cornerRadius(15)
                        }
                    }
                    .padding()

                    Spacer()
                }
            }
        }
    }

    // MARK: - Video Setup
    private func setupVideoPlayer() {
        print("🎬 [LiveShow] Iniciando setup del video...")

        // Para video público de Vimeo necesitamos usar la API o embed
        // Por ahora usamos videos que funcionan directamente
        let workingUrls = [
            "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
            "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
            "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
            "https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4",
        ]

        print("📝 [LiveShow] NOTA: Tu video de Vimeo (1029631656) requiere autenticación API")
        print("📝 [LiveShow] Usando video de demostración mientras tanto")

        tryVideoUrls(workingUrls, index: 0)
    }

    private func tryVideoUrls(_ urls: [String], index: Int) {
        guard index < urls.count else {
            print("❌ [LiveShow] No se pudo cargar ninguna URL de video")
            return
        }

        let urlString = urls[index]
        print("🔄 [LiveShow] Intentando URL [\(index + 1)/\(urls.count)]: \(urlString)")

        guard let url = URL(string: urlString) else {
            print("❌ [LiveShow] URL inválida: \(urlString)")
            tryVideoUrls(urls, index: index + 1)
            return
        }

        setupPlayerWithURL(url, isLastAttempt: index == urls.count - 1)
    }

    private func setupPlayerWithURL(_ url: URL, isLastAttempt: Bool = false) {
        print("📹 [LiveShow] Configurando player con URL: \(url.absoluteString)")
        videoStatus = "Loading..."

        player = AVPlayer(url: url)
        player?.isMuted = true
        player?.actionAtItemEnd = .none

        // Intentar reproducir
        player?.play()
        print("▶️ [LiveShow] Iniciando reproducción...")

        // Verificar después de 3 segundos si está funcionando
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if let currentItem = self.player?.currentItem {
                switch currentItem.status {
                case .readyToPlay:
                    print("✅ [LiveShow] Video cargado correctamente")
                    self.videoStatus = "Playing"
                    self.setupVideoLoop()
                case .failed:
                    print(
                        "❌ [LiveShow] Error al cargar video: \(currentItem.error?.localizedDescription ?? "Unknown error")"
                    )
                    self.videoStatus =
                        "Failed: \(currentItem.error?.localizedDescription ?? "Unknown")"
                    if !isLastAttempt {
                        // Intentar siguiente URL
                        let currentIndex = self.getCurrentUrlIndex(url)
                        self.tryVideoUrls(self.getVimeoUrls(), index: currentIndex + 1)
                    }
                case .unknown:
                    print("⚠️ [LiveShow] Estado del video desconocido")
                    self.videoStatus = "Unknown"
                default:
                    print("🔄 [LiveShow] Video aún cargando...")
                    self.videoStatus = "Still loading..."
                }
            }
        }
    }

    private func getVimeoUrls() -> [String] {
        return [
            "https://player.vimeo.com/video/1029631656",
            "https://vimeo.com/1029631656/download",
            "https://player.vimeo.com/external/1029631656.m3u8",
            "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
        ]
    }

    private func getCurrentUrlIndex(_ url: URL) -> Int {
        let urls = getVimeoUrls()
        return urls.firstIndex(of: url.absoluteString) ?? 0
    }

    private func setupVideoLoop() {
        // Loop del video
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem,
            queue: .main
        ) { _ in
            print("🔄 [LiveShow] Video terminó, reiniciando loop...")
            self.player?.seek(to: .zero)
            self.player?.play()
        }
    }

}

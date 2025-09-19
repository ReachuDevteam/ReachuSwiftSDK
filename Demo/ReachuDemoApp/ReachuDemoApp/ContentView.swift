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
    @State private var products: [Product] = []
    @State private var isLoading = true
    private let mockService = MockReachuService.shared
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading products...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: ReachuSpacing.md) {
                        ForEach(products) { product in
                            ProductCardView(product: product)
                        }
                    }
                    .padding(ReachuSpacing.lg)
                }
            }
        }
        .navigationTitle("Products")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadProducts()
        }
    }
    
    private func loadProducts() async {
        do {
            products = try await mockService.getProducts()
            isLoading = false
        } catch {
            isLoading = false
            print("Error loading products: \(error)")
        }
    }
}

struct ProductCardView: View {
    let product: Product
    
    var body: some View {
        VStack(alignment: .leading, spacing: ReachuSpacing.sm) {
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
            .frame(height: 120)
            .clipShape(RoundedRectangle(cornerRadius: ReachuBorderRadius.medium))
            
            VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
                Text(product.title)
                    .font(ReachuTypography.headline)
                    .lineLimit(2)
                    .foregroundColor(ReachuColors.textPrimary)
                
                if let brand = product.brand {
                    Text(brand)
                        .font(ReachuTypography.caption1)
                        .foregroundColor(ReachuColors.textSecondary)
                }
                
                HStack {
                    Text(product.price.displayAmount)
                        .font(ReachuTypography.body)
                        .fontWeight(.semibold)
                        .foregroundColor(ReachuColors.primary)
                    
                    Spacer()
                    
                    if let quantity = product.quantity, quantity > 0 {
                        RButton(title: "Add", style: .primary, size: .small) {
                            print("Add \(product.title) to cart")
                        }
                    } else {
                        Text("Out of Stock")
                            .font(ReachuTypography.caption1)
                            .foregroundColor(ReachuColors.error)
                    }
                }
            }
        }
        .padding(ReachuSpacing.md)
        .background(ReachuColors.surface)
        .cornerRadius(ReachuBorderRadius.large)
        .shadow(color: ReachuColors.textPrimary.opacity(0.1), radius: 4, x: 0, y: 2)
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

#Preview {
    ContentView()
}
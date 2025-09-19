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
    var body: some View {
        ScrollView {
            VStack(spacing: ReachuSpacing.xl) {
                // Header
                VStack(spacing: ReachuSpacing.md) {
                    Text("Product Catalog Demo")
                        .font(ReachuTypography.largeTitle)
                        .foregroundColor(ReachuColors.primary)
                    
                    Text("Showing the RProductCard component with real images and improved features")
                        .font(ReachuTypography.body)
                        .foregroundColor(ReachuColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, ReachuSpacing.xl)
                
                // Features List
                VStack(alignment: .leading, spacing: ReachuSpacing.lg) {
                    Text("✅ Component Features")
                        .font(ReachuTypography.headline)
                        .foregroundColor(ReachuColors.textPrimary)
                    
                    VStack(alignment: .leading, spacing: ReachuSpacing.sm) {
                        FeatureRow(icon: "🖼️", title: "Real Images", description: "High-quality Unsplash images with error handling")
                        FeatureRow(icon: "🎠", title: "Multiple Images", description: "Swipe through product images with TabView")
                        FeatureRow(icon: "🎯", title: "Smart Ordering", description: "Images ordered by 'order' field (0,1 priority)")
                        FeatureRow(icon: "📱", title: "4 Variants", description: "Grid, List, Hero, and Minimal layouts")
                        FeatureRow(icon: "⚠️", title: "Error States", description: "Intelligent placeholders for broken/loading images")
                        FeatureRow(icon: "🎨", title: "Design System", description: "Uses ReachuDesignSystem tokens consistently")
                    }
                }
                .padding(ReachuSpacing.lg)
                .background(ReachuColors.surface)
                .cornerRadius(ReachuBorderRadius.large)
                .shadow(color: ReachuColors.textPrimary.opacity(0.1), radius: 4, x: 0, y: 2)
                
                // SDK Status
                VStack(spacing: ReachuSpacing.md) {
                    Text("🚀 SDK Status")
                        .font(ReachuTypography.headline)
                        .foregroundColor(ReachuColors.success)
                    
                    VStack(alignment: .leading, spacing: ReachuSpacing.sm) {
                        StatusRow(status: .success, title: "RProductCard", description: "Complete with all variants")
                        StatusRow(status: .success, title: "Image System", description: "AsyncImage with error handling")
                        StatusRow(status: .success, title: "Mock Data", description: "6 products with real Unsplash images")
                        StatusRow(status: .success, title: "Design System", description: "Colors, typography, spacing tokens")
                        StatusRow(status: .pending, title: "RProductSlider", description: "Coming next - array-based component")
                    }
                }
                .padding(ReachuSpacing.lg)
                .background(ReachuColors.surfaceSecondary)
                .cornerRadius(ReachuBorderRadius.large)
                
                // Next Steps
                VStack(spacing: ReachuSpacing.md) {
                    Text("📋 Next Steps")
                        .font(ReachuTypography.headline)
                        .foregroundColor(ReachuColors.textPrimary)
                    
                    Text("To see the RProductCard in action, you need to configure ReachuUI and ReachuTesting dependencies in the Xcode project. The component is ready and working in the SDK!")
                        .font(ReachuTypography.body)
                        .foregroundColor(ReachuColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(ReachuSpacing.lg)
                .background(ReachuColors.info.opacity(0.1))
                .cornerRadius(ReachuBorderRadius.medium)
            }
            .padding(ReachuSpacing.lg)
        }
        .navigationTitle("Product Catalog")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: ReachuSpacing.md) {
            Text(icon)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(ReachuTypography.body)
                    .fontWeight(.semibold)
                    .foregroundColor(ReachuColors.textPrimary)
                
                Text(description)
                    .font(ReachuTypography.caption1)
                    .foregroundColor(ReachuColors.textSecondary)
            }
            
            Spacer()
        }
    }
}

struct StatusRow: View {
    enum Status {
        case success, pending, warning
        
        var color: Color {
            switch self {
            case .success: return ReachuColors.success
            case .pending: return ReachuColors.warning
            case .warning: return ReachuColors.error
            }
        }
        
        var icon: String {
            switch self {
            case .success: return "✅"
            case .pending: return "⏳"
            case .warning: return "⚠️"
            }
        }
    }
    
    let status: Status
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: ReachuSpacing.md) {
            Text(status.icon)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(ReachuTypography.body)
                    .fontWeight(.semibold)
                    .foregroundColor(ReachuColors.textPrimary)
                
                Text(description)
                    .font(ReachuTypography.caption1)
                    .foregroundColor(status.color)
            }
            
            Spacer()
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

#Preview {
    ContentView()
}
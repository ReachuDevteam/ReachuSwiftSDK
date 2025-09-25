import SwiftUI
import ReachuCore
import ReachuLiveShow
import ReachuDesignSystem
import ReachuUI

/// Products grid overlay that slides from bottom (80% height)
public struct RLiveProductsGridOverlay: View {
    
    // MARK: - Properties
    private let products: [LiveProduct]
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var cartManager: CartManager
    @State private var selectedProduct: Product?
    
    // Configuration
    private var config: ReachuConfiguration { ReachuConfiguration.shared }
    private var theme: ReachuTheme { config.theme }
    private var uiConfig: UIConfiguration { config.uiConfiguration }
    
    // Colors based on theme
    private var adaptiveColors: AdaptiveColors {
        ReachuColors.adaptive(for: colorScheme)
    }
    
    // Grid configuration from ReachuConfiguration
    private var gridColumns: [GridItem] {
        let columnCount = 2 // Could be from uiConfig in future
        return Array(repeating: GridItem(.flexible(), spacing: ReachuSpacing.md), count: columnCount)
    }
    
    public init(products: [LiveProduct]) {
        self.products = products
    }
    
    // MARK: - Body
    public var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Header with close
                headerSection
                
                // Products grid
                ScrollView {
                    LazyVGrid(columns: gridColumns, spacing: ReachuSpacing.md) {
                        ForEach(products) { liveProduct in
                            RProductCard(
                                product: liveProduct.asProduct,
                                variant: .grid,
                                showDescription: uiConfig.showProductBrands
                            )
                            .environmentObject(cartManager)
                            .onTapGesture {
                                selectedProduct = liveProduct.asProduct
                            }
                        }
                    }
                    .padding(.horizontal, ReachuSpacing.lg)
                    .padding(.bottom, ReachuSpacing.xl)
                }
            }
            .frame(height: geometry.size.height * 0.8) // 80% of screen height
            .background(adaptiveColors.background)
            .cornerRadius(ReachuBorderRadius.large)
            .shadow(
                color: Color.black.opacity(0.3),
                radius: 20,
                x: 0,
                y: -10
            )
        }
        // Remove iOS 16+ only modifiers for compatibility
        .sheet(item: $selectedProduct) { product in
            RProductDetailOverlay(
                product: product,
                onAddToCart: { product in
                    Task {
                        await cartManager.addProduct(product, quantity: 1)
                    }
                    // Close both overlays after adding
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        selectedProduct = nil
                        dismiss()
                    }
                }
            )
            .environmentObject(cartManager)
        }
    }
    
    // MARK: - Header Section
    
    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: ReachuSpacing.sm) {
            // Drag indicator
            Capsule()
                .fill(adaptiveColors.textTertiary)
                .frame(width: 40, height: 4)
                .padding(.top, ReachuSpacing.sm)
            
            // Header content
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Featured Products")
                        .font(ReachuTypography.title2)
                        .foregroundColor(adaptiveColors.textPrimary)
                    
                    Text("\(products.count) items available")
                        .font(ReachuTypography.body)
                        .foregroundColor(adaptiveColors.textSecondary)
                }
                
                Spacer()
                
                Button("Close") {
                    dismiss()
                }
                .font(ReachuTypography.body)
                .foregroundColor(adaptiveColors.primary)
            }
                .padding(.horizontal, ReachuSpacing.lg)
                .padding(.bottom, ReachuSpacing.md)
            
            Divider()
                .background(adaptiveColors.border)
        }
    }
}

// Corner radius extensions removed - using standard cornerRadius

// MARK: - Preview

#Preview {
    RLiveProductsGridOverlay(products: DemoProductData.featuredProducts)
        .environmentObject(CartManager())
}

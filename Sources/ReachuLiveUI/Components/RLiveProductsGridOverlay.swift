import SwiftUI
import ReachuCore
import ReachuLiveShow
import ReachuDesignSystem
import ReachuUI

#if os(iOS)
import UIKit
#endif

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
        VStack(spacing: 0) {
            // Header with close
            headerSection
            
            // Products grid (responsive)
            ScrollView {
                LazyVGrid(columns: gridColumns, spacing: ReachuSpacing.lg) {
                    ForEach(products) { liveProduct in
                        RProductCard(
                            product: liveProduct.asProduct,
                            variant: .grid,
                            showDescription: false
                        )
                        .environmentObject(cartManager)
                        .onTapGesture {
                            selectedProduct = liveProduct.asProduct
                        }
                    }
                }
                .padding(.horizontal, ReachuSpacing.lg)
                .padding(.top, ReachuSpacing.md)
                .padding(.bottom, ReachuSpacing.xl)
            }
        }
        .frame(maxHeight: 600) // Fixed height for compatibility
        .background(adaptiveColors.background)
        .cornerRadius(ReachuBorderRadius.large)
        .shadow(
            color: Color.black.opacity(0.2),
            radius: 15,
            x: 0,
            y: -5
        )
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
    
    // Responsive title size based on configuration
    private var titleFontSize: CGFloat {
        // Use configuration for responsive sizing
        return 18 // Fixed size for compatibility, could be from config
    }
    
    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: ReachuSpacing.sm) {
            // Drag indicator
            Capsule()
                .fill(adaptiveColors.textTertiary)
                .frame(width: 40, height: 4)
                .padding(.top, ReachuSpacing.sm)
            
            // Header content with avatar and subtitle
            HStack {
                // Avatar + Title section
                HStack(spacing: ReachuSpacing.sm) {
                    // Live stream avatar
                    AsyncImage(url: URL(string: "https://storage.googleapis.com/tipio-images/1756737999235-012.png")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(adaptiveColors.surfaceSecondary)
                    }
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Featured Products")
                            .font(.system(size: titleFontSize, weight: .semibold))
                            .foregroundColor(adaptiveColors.textPrimary)
                        
                        Text("Live Shopping • \(products.count) items")
                            .font(.system(size: 12))
                            .foregroundColor(adaptiveColors.textSecondary)
                    }
                }
                
                Spacer()
                
                Button("Close") {
                    dismiss()
                }
                .font(.system(size: 14))
                .foregroundColor(adaptiveColors.primary)
            }
            .padding(.horizontal, ReachuSpacing.lg)
            .padding(.bottom, ReachuSpacing.sm)
            
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

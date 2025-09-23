import SwiftUI
import ReachuCore
import ReachuDesignSystem

#if DEBUG
import ReachuTesting
#endif

/// Product Detail Overlay Component
///
/// A full-screen modal overlay that displays comprehensive product information.
/// Provides detailed product view with image gallery, specifications, and cart actions.
///
/// **Usage:**
/// ```swift
/// @State private var selectedProduct: Product?
/// 
/// // Show overlay
/// .sheet(item: $selectedProduct) { product in
///     RProductDetailOverlay(product: product)
///         .environmentObject(cartManager)
/// }
/// ```
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public struct RProductDetailOverlay: View {
    
    // MARK: - Properties
    private let product: Product
    private let onDismiss: (() -> Void)?
    private let onAddToCart: ((Product) -> Void)?
    
    // MARK: - Environment
    @EnvironmentObject private var cartManager: CartManager
    @SwiftUI.Environment(\.dismiss) private var dismiss: DismissAction
    @SwiftUI.Environment(\.colorScheme) private var colorScheme: SwiftUI.ColorScheme
    
    
    // MARK: - State
    @State private var selectedImageIndex = 0
    @State private var isAddingToCart = false
    @State private var showCheckmark = false
    @State private var buttonScale: CGFloat = 1.0
    @State private var selectedVariant: Variant?
    @State private var quantity = 1
    
    // MARK: - Computed Properties
    private var displayImages: [ProductImage] {
        product.images.sorted { $0.order < $1.order }
    }
    
    private var isInStock: Bool {
        if let variant = selectedVariant {
            return (variant.quantity ?? 0) > 0
        }
        return (product.quantity ?? 0) > 0
    }
    
    private var currentPrice: Price {
        selectedVariant?.price ?? product.price
    }
    
    // MARK: - Initializer
    public init(
        product: Product,
        onDismiss: (() -> Void)? = nil,
        onAddToCart: ((Product) -> Void)? = nil
    ) {
        self.product = product
        self.onDismiss = onDismiss
        self.onAddToCart = onAddToCart
    }
    
    // MARK: - Body
    public var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Image Gallery
                    imageGallerySection
                    
                    // Product Information
                    VStack(spacing: ReachuSpacing.lg) {
                        productInfoSection
                        variantSelectionSection
                        quantitySelectionSection
                        descriptionSection
                        specificationsSection
                    }
                    .padding(.horizontal, ReachuSpacing.lg)
                    .padding(.bottom, ReachuSpacing.xl)
                }
            }
            .navigationTitle(product.title)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        onDismiss?()
                        dismiss()
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                // Bottom Action Bar
                bottomActionBar
            }
        }
        
        .onAppear {
            // Select first variant by default
            selectedVariant = product.variants.first
        }
    }
    
    // MARK: - Image Gallery Section
    private var imageGallerySection: some View {
        VStack(spacing: ReachuSpacing.md) {
            if displayImages.isEmpty {
                // Placeholder when no images
                RoundedRectangle(cornerRadius: ReachuBorderRadius.large)
                    .fill(ReachuColors.background)
                    .frame(height: 300)
                    .overlay {
                        VStack(spacing: ReachuSpacing.sm) {
                            Image(systemName: "photo")
                                .font(.system(size: 48))
                                .foregroundColor(ReachuColors.textSecondary)
                            Text("No Image Available")
                                .font(ReachuTypography.body)
                                .foregroundColor(ReachuColors.textSecondary)
                        }
                    }
            } else if displayImages.count == 1 {
                // Single image
                AsyncImage(url: URL(string: displayImages[0].url)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    case .failure(_):
                        RoundedRectangle(cornerRadius: ReachuBorderRadius.large)
                            .fill(ReachuColors.background)
                            .overlay {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundColor(ReachuColors.error)
                            }
                    case .empty:
                        RoundedRectangle(cornerRadius: ReachuBorderRadius.large)
                            .fill(ReachuColors.background)
                            .overlay {
                                ProgressView()
                            }
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(height: 300)
                .cornerRadius(ReachuBorderRadius.large)
            } else {
                // Multiple images with gallery
                VStack(spacing: ReachuSpacing.md) {
                    // Main image display
                    TabView(selection: $selectedImageIndex) {
                        ForEach(Array(displayImages.enumerated()), id: \.element.id) { index, image in
                            AsyncImage(url: URL(string: image.url)) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                case .failure(_):
                                    RoundedRectangle(cornerRadius: ReachuBorderRadius.large)
                                        .fill(ReachuColors.background)
                                        .overlay {
                                            Image(systemName: "exclamationmark.triangle")
                                                .foregroundColor(ReachuColors.error)
                                        }
                                case .empty:
                                    RoundedRectangle(cornerRadius: ReachuBorderRadius.large)
                                        .fill(ReachuColors.background)
                                        .overlay {
                                            ProgressView()
                                        }
                                @unknown default:
                                    EmptyView()
                                }
                            }
                            .tag(index)
                        }
                    }
                    .frame(height: 300)
                    #if os(iOS) || os(tvOS) || os(watchOS)
                    .tabViewStyle(.page(indexDisplayMode: .always))
                    #endif
                    
                    // Thumbnail gallery
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: ReachuSpacing.sm) {
                            ForEach(Array(displayImages.enumerated()), id: \.element.id) { index, image in
                                AsyncImage(url: URL(string: image.url)) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    case .failure(_):
                                        RoundedRectangle(cornerRadius: ReachuBorderRadius.small)
                                            .fill(ReachuColors.background)
                                            .overlay {
                                                Image(systemName: "exclamationmark.triangle")
                                                    .font(.caption)
                                                    .foregroundColor(ReachuColors.error)
                                            }
                                    case .empty:
                                        RoundedRectangle(cornerRadius: ReachuBorderRadius.small)
                                            .fill(ReachuColors.background)
                                            .overlay {
                                                ProgressView()
                                                    .scaleEffect(0.5)
                                            }
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: ReachuBorderRadius.small))
                                .overlay {
                                    RoundedRectangle(cornerRadius: ReachuBorderRadius.small)
                                        .stroke(
                                            selectedImageIndex == index ? ReachuColors.primary : ReachuColors.border,
                                            lineWidth: selectedImageIndex == index ? 2 : 1
                                        )
                                }
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        selectedImageIndex = index
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, ReachuSpacing.lg)
                    }
                }
            }
        }
        .padding(.top, ReachuSpacing.md)
    }
    
    // MARK: - Product Info Section
    private var productInfoSection: some View {
        VStack(alignment: .leading, spacing: ReachuSpacing.md) {
            // Title and Brand
            VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
                Text(product.title)
                    .font(ReachuTypography.title2)
                    .foregroundColor(ReachuColors.textPrimary)
                
                if let brand = product.brand, !brand.isEmpty {
                    Text(brand)
                        .font(ReachuTypography.subheadline)
                        .foregroundColor(ReachuColors.textSecondary)
                }
            }
            
            // Price and Stock
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
                    // Current price
                    Text("$\(String(format: "%.2f", currentPrice.amount))")
                        .font(ReachuTypography.title3)
                        .foregroundColor(ReachuColors.textPrimary)
                    
                    // Compare at price (if available)
                    if let compareAt = currentPrice.compare_at, compareAt > currentPrice.amount {
                        Text("$\(String(format: "%.2f", compareAt))")
                            .font(ReachuTypography.body)
                            .foregroundColor(ReachuColors.textSecondary)
                            .strikethrough()
                    }
                }
                
                Spacer()
                
                // Stock status
                stockStatusBadge
            }
        }
    }
    
    // MARK: - Variant Selection Section
    private var variantSelectionSection: some View {
        VStack(alignment: .leading, spacing: ReachuSpacing.md) {
            if !product.variants.isEmpty {
                VStack(alignment: .leading, spacing: ReachuSpacing.sm) {
                    Text("Options")
                        .font(ReachuTypography.headline)
                        .foregroundColor(ReachuColors.textPrimary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: ReachuSpacing.sm) {
                            ForEach(product.variants, id: \.id) { variant in
                                Button {
                                    selectedVariant = variant
                                } label: {
                                    Text(variant.title)
                                        .font(ReachuTypography.body)
                                        .padding(.horizontal, ReachuSpacing.md)
                                        .padding(.vertical, ReachuSpacing.sm)
                                        .background(
                                            selectedVariant?.id == variant.id ? 
                                            ReachuColors.primary : ReachuColors.surface
                                        )
                                        .foregroundColor(
                                            selectedVariant?.id == variant.id ? 
                                            .white : ReachuColors.textPrimary
                                        )
                                        .cornerRadius(ReachuBorderRadius.medium)
                                        .overlay {
                                            RoundedRectangle(cornerRadius: ReachuBorderRadius.medium)
                                                .stroke(ReachuColors.border, lineWidth: 1)
                                        }
                                }
                                .disabled((variant.quantity ?? 0) <= 0)
                                .opacity((variant.quantity ?? 0) <= 0 ? 0.5 : 1.0)
                            }
                        }
                        .padding(.horizontal, ReachuSpacing.lg)
                    }
                }
            }
        }
    }
    
    // MARK: - Quantity Selection Section
    private var quantitySelectionSection: some View {
        VStack(alignment: .leading, spacing: ReachuSpacing.sm) {
            Text("Quantity")
                .font(ReachuTypography.headline)
                .foregroundColor(ReachuColors.textPrimary)
            
            HStack(spacing: ReachuSpacing.md) {
                // Decrease button
                Button {
                    if quantity > 1 {
                        quantity -= 1
                    }
                } label: {
                    Image(systemName: "minus")
                        .font(.body)
                        .foregroundColor(quantity > 1 ? ReachuColors.textPrimary : ReachuColors.textSecondary)
                        .frame(width: 44, height: 44)
                        .background(ReachuColors.surface)
                        .cornerRadius(ReachuBorderRadius.medium)
                        .overlay {
                            RoundedRectangle(cornerRadius: ReachuBorderRadius.medium)
                                .stroke(ReachuColors.border, lineWidth: 1)
                        }
                }
                .disabled(quantity <= 1)
                
                // Current quantity
                Text("\(quantity)")
                    .font(ReachuTypography.headline)
                    .foregroundColor(ReachuColors.textPrimary)
                    .frame(minWidth: 40)
                
                // Increase button
                Button {
                    let maxQuantity = selectedVariant?.quantity ?? product.quantity ?? 0
                    if quantity < maxQuantity {
                        quantity += 1
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.body)
                        .foregroundColor(
                            quantity < (selectedVariant?.quantity ?? product.quantity ?? 0) ? 
                            ReachuColors.textPrimary : ReachuColors.textSecondary
                        )
                        .frame(width: 44, height: 44)
                        .background(ReachuColors.surface)
                        .cornerRadius(ReachuBorderRadius.medium)
                        .overlay {
                            RoundedRectangle(cornerRadius: ReachuBorderRadius.medium)
                                .stroke(ReachuColors.border, lineWidth: 1)
                        }
                }
                .disabled(quantity >= (selectedVariant?.quantity ?? product.quantity ?? 0))
                
                Spacer()
                
                // Total price for quantity
                VStack(alignment: .trailing) {
                    Text("Total")
                        .font(ReachuTypography.caption1)
                        .foregroundColor(ReachuColors.textSecondary)
                    Text("$\(String(format: "%.2f", Double(currentPrice.amount) * Double(quantity)))")
                        .font(ReachuTypography.title3)
                        .foregroundColor(ReachuColors.textPrimary)
                }
            }
        }
    }
    
    // MARK: - Description Section
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: ReachuSpacing.sm) {
            if let description = product.description, !description.isEmpty {
                Text("Description")
                    .font(ReachuTypography.headline)
                    .foregroundColor(ReachuColors.textPrimary)
                
                Text(description)
                    .font(ReachuTypography.body)
                    .foregroundColor(ReachuColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    
    // MARK: - Specifications Section
    private var specificationsSection: some View {
        VStack(alignment: .leading, spacing: ReachuSpacing.sm) {
            Text("Details")
                .font(ReachuTypography.headline)
                .foregroundColor(ReachuColors.textPrimary)
            
            VStack(spacing: ReachuSpacing.xs) {
                if !product.sku.isEmpty {
                    specificationRow(title: "SKU", value: product.sku)
                }
                
                if let categories = product.categories, !categories.isEmpty {
                    specificationRow(
                        title: "Category", 
                        value: categories.map(\.name).joined(separator: ", ")
                    )
                }
                
                if !product.supplier.isEmpty {
                    specificationRow(title: "Supplier", value: product.supplier)
                }
                
                specificationRow(title: "Stock", value: "\(selectedVariant?.quantity ?? product.quantity ?? 0) available")
            }
        }
    }
    
    // MARK: - Helper Views
    private func specificationRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(ReachuTypography.body)
                .foregroundColor(ReachuColors.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(ReachuTypography.body)
                .foregroundColor(ReachuColors.textPrimary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, ReachuSpacing.xs)
    }
    
    private var stockStatusBadge: some View {
        HStack(spacing: ReachuSpacing.xs) {
            Circle()
                .fill(isInStock ? ReachuColors.success : ReachuColors.error)
                .frame(width: 8, height: 8)
            
            Text(isInStock ? "In Stock" : "Out of Stock")
                .font(ReachuTypography.caption1)
                .foregroundColor(isInStock ? ReachuColors.success : ReachuColors.error)
        }
        .padding(.horizontal, ReachuSpacing.sm)
        .padding(.vertical, ReachuSpacing.xs)
        .background(
            (isInStock ? ReachuColors.success : ReachuColors.error).opacity(0.1)
        )
        .cornerRadius(ReachuBorderRadius.small)
    }
    
    // MARK: - Bottom Action Bar
    private var bottomActionBar: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: ReachuSpacing.md) {
                // Add to Cart Button
                RButton(
                    title: showCheckmark ? "Added!" : "Add to Cart",
                    style: .primary,
                    size: .large,
                    isLoading: isAddingToCart,
                    icon: showCheckmark ? "checkmark" : nil
                ) {
                    addToCart()
                }
                .disabled(!isInStock || isAddingToCart)
                .scaleEffect(buttonScale)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: buttonScale)
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, ReachuSpacing.lg)
            .padding(.vertical, ReachuSpacing.md)
            .background(.ultraThinMaterial)
        }
    }
    
    // MARK: - Actions
    private func addToCart() {
        // Animate button
        withAnimation(.easeInOut(duration: 0.1)) {
            buttonScale = 0.95
            isAddingToCart = true
        }
        
        // Scale back and show success
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                buttonScale = 1.0
                showCheckmark = true
            }
        }
        
        // Reset after showing success
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 0.3)) {
                showCheckmark = false
                isAddingToCart = false
            }
        }
        
        // Add to cart
        Task {
            await cartManager.addProduct(product, quantity: quantity)
        }
        
        // Call callback
        onAddToCart?(product)
        
        // Haptic feedback
        #if os(iOS)
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        #endif
    }
}

// MARK: - Preview
#if DEBUG
#Preview("Product Detail Overlay") {
    struct PreviewWrapper: View {
        @StateObject private var cartManager = CartManager()
        @State private var selectedProduct: Product? = MockDataProvider.shared.sampleProducts.first
        
        var body: some View {
            Button("Show Product Detail") {
                selectedProduct = MockDataProvider.shared.sampleProducts.first
            }
            .sheet(item: $selectedProduct) { product in
                RProductDetailOverlay(product: product)
                    .environmentObject(cartManager)
            }
        }
    }
    
    return PreviewWrapper()
}
#endif

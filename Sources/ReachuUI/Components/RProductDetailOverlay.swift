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
    @State private var selectedOptions: [String: String] = [:] // option_name: selected_value
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
                    VStack(spacing: ReachuSpacing.md) {
                        productInfoSection
                        variantSelectionSection
                        quantitySelectionSection
                        descriptionSection
                        specificationsSection
                    }
                    .padding(.horizontal, ReachuSpacing.lg)
                    .padding(.top, ReachuSpacing.lg)
                    .padding(.bottom, ReachuSpacing.lg)
                }
            }
            .navigationTitle("Product Details")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
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
            // Initialize default options and variant
            initializeDefaultOptions()
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
                .frame(height: 240)
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
        VStack(alignment: .leading, spacing: ReachuSpacing.sm) {
            // Title and Brand
            VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
                Text(product.title)
                    .font(ReachuTypography.title3)
                    .foregroundColor(ReachuColors.textPrimary)
                    .lineLimit(2)
                
                if let brand = product.brand, !brand.isEmpty {
                    Text(brand)
                        .font(ReachuTypography.body)
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
        VStack(alignment: .leading, spacing: ReachuSpacing.sm) {
            if !product.variants.isEmpty {
                VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
                    Text("Options")
                        .font(ReachuTypography.caption1)
                        .fontWeight(.semibold)
                        .foregroundColor(ReachuColors.textPrimary)
                    
                    // Group variants by option type (Color, Size, etc.)
                    let variantOptions = groupVariantsByOptions()
                    
                    VStack(alignment: .leading, spacing: ReachuSpacing.sm) {
                        ForEach(Array(variantOptions.keys.sorted()), id: \.self) { optionName in
                            VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
                                Text(optionName)
                                    .font(ReachuTypography.caption2)
                                    .fontWeight(.medium)
                                    .foregroundColor(ReachuColors.textSecondary)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: ReachuSpacing.sm) {
                                        ForEach(variantOptions[optionName] ?? [], id: \.self) { optionValue in
                                            Button {
                                                selectedOptions[optionName] = optionValue
                                                updateSelectedVariant()
                                            } label: {
                                                Text(optionValue)
                                                    .font(ReachuTypography.caption1)
                                                    .padding(.horizontal, ReachuSpacing.sm)
                                                    .padding(.vertical, ReachuSpacing.xs)
                                                    .background(
                                                        selectedOptions[optionName] == optionValue ? 
                                                        ReachuColors.primary : ReachuColors.surface
                                                    )
                                                    .foregroundColor(
                                                        selectedOptions[optionName] == optionValue ? 
                                                        .white : ReachuColors.textPrimary
                                                    )
                                                    .cornerRadius(ReachuBorderRadius.small)
                                                    .overlay {
                                                        RoundedRectangle(cornerRadius: ReachuBorderRadius.small)
                                                            .stroke(ReachuColors.border, lineWidth: 1)
                                                    }
                                            }
                                        }
                                    }
                                    .padding(.horizontal, ReachuSpacing.lg)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Quantity Selection Section
    private var quantitySelectionSection: some View {
        VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
            Text("Quantity")
                .font(ReachuTypography.caption1)
                .fontWeight(.semibold)
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
                        .frame(width: 36, height: 36)
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
                    .font(ReachuTypography.body)
                    .fontWeight(.semibold)
                    .foregroundColor(ReachuColors.textPrimary)
                    .frame(minWidth: 36)
                
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
                        .frame(width: 36, height: 36)
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
        VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
            if let description = product.description, !description.isEmpty {
                Text("Description")
                    .font(ReachuTypography.caption1)
                    .fontWeight(.semibold)
                    .foregroundColor(ReachuColors.textPrimary)
                
                Text(description)
                    .font(ReachuTypography.caption1)
                    .foregroundColor(ReachuColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(3)
            }
        }
    }
    
    // MARK: - Specifications Section
    private var specificationsSection: some View {
        VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
            Text("Details")
                .font(ReachuTypography.caption1)
                .fontWeight(.semibold)
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
                .font(ReachuTypography.caption1)
                .foregroundColor(ReachuColors.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(ReachuTypography.caption1)
                .foregroundColor(ReachuColors.textPrimary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 2)
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
            // Subtle top separator
            Rectangle()
                .fill(ReachuColors.border.opacity(0.3))
                .frame(height: 0.5)
            
            // Full-width sexy button
            Button(action: addToCart) {
                HStack(spacing: ReachuSpacing.sm) {
                    // Icon
                    if showCheckmark {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    } else if isAddingToCart {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "cart.badge.plus")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    // Button text
                    Text(showCheckmark ? "Added to Cart!" : isAddingToCart ? "Adding..." : "Add to Cart")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Price
                    if !isAddingToCart && !showCheckmark {
                        Text("$\(String(format: "%.2f", Double(currentPrice.amount) * Double(quantity)))")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, ReachuSpacing.lg)
                .padding(.vertical, ReachuSpacing.sm)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: ReachuBorderRadius.medium)
                        .fill(
                            LinearGradient(
                                colors: [
                                    ReachuColors.primary,
                                    ReachuColors.primary.opacity(0.8)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: ReachuBorderRadius.medium)
                        .stroke(ReachuColors.primary.opacity(0.3), lineWidth: 1)
                )
                .shadow(
                    color: ReachuColors.primary.opacity(0.3),
                    radius: 8,
                    x: 0,
                    y: 4
                )
            }
            .disabled(!isInStock || isAddingToCart)
            .scaleEffect(buttonScale)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: buttonScale)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: showCheckmark)
            .padding(.horizontal, ReachuSpacing.lg)
            .padding(.vertical, ReachuSpacing.sm)
            .background(ReachuColors.surface.opacity(0.95))
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
    
    // MARK: - Helper Functions for Variants
    
    /// Group variants by option types (Color, Size, etc.)
    private func groupVariantsByOptions() -> [String: [String]] {
        var options: [String: Set<String>] = [:]
        
        for variant in product.variants {
            // Extract option name and value from variant title
            // Example: "Black - Large" → ["Color": "Black", "Size": "Large"]
            let components = variant.title.components(separatedBy: " - ")
            
            if components.count == 1 {
                // Single option (e.g., "Black")
                options["Color", default: Set()].insert(components[0])
            } else if components.count == 2 {
                // Two options (e.g., "Black - Large")
                options["Color", default: Set()].insert(components[0])
                options["Size", default: Set()].insert(components[1])
            }
        }
        
        // Convert Set to Array and sort
        return options.mapValues { Array($0).sorted() }
    }
    
    /// Update selected variant based on selected options
    private func updateSelectedVariant() {
        // Find variant that matches selected options
        for variant in product.variants {
            let components = variant.title.components(separatedBy: " - ")
            
            var matches = true
            if components.count == 1 {
                // Single option
                if selectedOptions["Color"] != components[0] {
                    matches = false
                }
            } else if components.count == 2 {
                // Two options
                if selectedOptions["Color"] != components[0] || selectedOptions["Size"] != components[1] {
                    matches = false
                }
            }
            
            if matches {
                selectedVariant = variant
                break
            }
        }
    }
    
    /// Initialize default options from first variant
    private func initializeDefaultOptions() {
        guard let firstVariant = product.variants.first else {
            selectedVariant = nil
            return
        }
        
        let components = firstVariant.title.components(separatedBy: " - ")
        
        if components.count == 1 {
            // Single option
            selectedOptions["Color"] = components[0]
        } else if components.count == 2 {
            // Two options
            selectedOptions["Color"] = components[0]
            selectedOptions["Size"] = components[1]
        }
        
        selectedVariant = firstVariant
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

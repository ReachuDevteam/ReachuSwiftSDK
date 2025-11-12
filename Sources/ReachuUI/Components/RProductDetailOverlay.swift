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
    
    // MARK: - Configuration
    private var productDetailConfig: ProductDetailConfiguration {
        ReachuConfiguration.shared.productDetailConfiguration
    }
    
    private var adaptiveColors: AdaptiveColors {
        ReachuColors.adaptive(for: colorScheme)
    }
    
    // MARK: - State
    @State private var selectedImageIndex = 0
    @State private var isAddingToCart = false
    @State private var showCheckmark = false
    @State private var buttonScale: CGFloat = 1.0
    @State private var selectedVariant: Variant?
    @State private var selectedOptions: [String: String] = [:] // option_name: selected_value
    @State private var quantity = 1
    @State private var showSuccessAnimation = false
    @State private var showToastOverModal = false
    @State private var imageLoaded = false
    
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
    
    /// Current price with taxes if available (what customer actually pays)
    private var currentPriceWithTaxes: Float {
        currentPrice.amount_incl_taxes ?? currentPrice.amount
    }
    
    /// Compare at price with taxes if available
    private var compareAtWithTaxes: Float? {
        currentPrice.compare_at_incl_taxes ?? currentPrice.compare_at
    }
    
    private var displayCurrencySymbol: String {
        let symbol = cartManager.currencySymbol
        if !symbol.isEmpty {
            return symbol
        }
        return currentPrice.currency_code
    }

    private func formatted(amount: Double) -> String {
        let symbol = displayCurrencySymbol
        let separator = symbol.count > 1 ? " " : ""
        return "\(symbol)\(separator)\(String(format: "%.2f", amount))"
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
        // Hide if SDK should not be used (market not available) or campaign not active
        if !ReachuConfiguration.shared.shouldUseSDK || !CampaignManager.shared.isCampaignActive {
            EmptyView()
        } else {
            productDetailContent
        }
    }
    
    private var productDetailContent: some View {
        NavigationView {
            ZStack(alignment: .top) {
                ScrollView {
                    VStack(spacing: 0) {
                    // Image Gallery first (edge to edge)
                    ZStack(alignment: .top) {
                        imageGallerySection
                        
                        // Drawer handle overlay on image
                        VStack {
                            Capsule()
                                .fill(adaptiveColors.surface.opacity(0.8))
                                .frame(width: 36, height: 5)
                                .reachuTextShadow(for: colorScheme)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 12)
                        .padding(.bottom, 8)
                        .background(adaptiveColors.textPrimary.opacity(0.01)) // Invisible but tappable
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture()
                                .onEnded { value in
                                    if value.translation.height > 50 {
                                        onDismiss?()
                                        dismiss()
                                    }
                                }
                        )
                    }
                    
                    // Product Information (only show after image loads)
                    if imageLoaded || displayImages.isEmpty {
                        VStack(alignment: .leading, spacing: ReachuSpacing.md) {
                            productInfoSection
                            variantSelectionSection
                            quantitySelectionSection
                            
                            if productDetailConfig.showDescription {
                                descriptionSection
                            }
                            
                            if productDetailConfig.showSpecifications {
                                specificationsSection
                            }
                        }
                        .padding(.horizontal, ReachuSpacing.lg)
                        .padding(.top, ReachuSpacing.lg)
                        .padding(.bottom, ReachuSpacing.lg)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                    }
                }
                #if os(iOS)
                .navigationBarHidden(true)
                #endif
                .toolbar {
                    // No close button - use drawer handle instead
                }
                .safeAreaInset(edge: .bottom) {
                    // Bottom Action Bar (only show after image loads)
                    if imageLoaded || displayImages.isEmpty {
                        bottomActionBar
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                
                // Overlay Close Button
                if productDetailConfig.showCloseButton && productDetailConfig.closeButtonStyle != .navigationBar {
                    overlayCloseButton
                }
            }
        }
        .modifier(ProductDetailPresentationModifier(config: productDetailConfig))
        
        .onAppear {
            // Initialize default options and variant
            initializeDefaultOptions()
        }
        .overlay {
            // Success animation overlay
            if showSuccessAnimation {
                successAnimationOverlay
            } else {
                EmptyView()
            }
        }
        .overlay {
            // Toast notification over modal
            if showToastOverModal {
                toastOverlayView
            } else {
                EmptyView()
            }
        }
    }
    
    // MARK: - Image Gallery Section
    private var imageGallerySection: some View {
        VStack(spacing: 0) {
            if displayImages.isEmpty {
                // Placeholder when no images
                RoundedRectangle(cornerRadius: productDetailConfig.imageCornerRadius)
                    .fill(ReachuColors.background)
                    .frame(height: 300)
                    .overlay {
                        VStack(spacing: ReachuSpacing.sm) {
                            Image(systemName: "photo")
                                .font(.system(size: 48))
                                .foregroundColor(ReachuColors.textSecondary)
                            Text(RLocalizedString(ReachuTranslationKey.noImageAvailable.rawValue))
                                .font(ReachuTypography.body)
                                .foregroundColor(ReachuColors.textSecondary)
                        }
                    }
            } else if displayImages.count == 1 {
                // Single image - full width, edge to edge
                LoadedImage(
                    url: URL(string: displayImages[0].url),
                    placeholder: AnyView(RoundedRectangle(cornerRadius: productDetailConfig.imageCornerRadius)
                        .fill(ReachuColors.background)
                        .overlay { ProgressView() }),
                    errorView: AnyView(RoundedRectangle(cornerRadius: productDetailConfig.imageCornerRadius)
                        .fill(ReachuColors.background)
                        .overlay {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(ReachuColors.error)
                        })
                )
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity)
                .frame(height: productDetailConfig.imageHeight ?? 400)
                .clipped()
                .onAppear {
                    imageLoaded = true
                }
                .background(Color.clear)
            } else {
                // Multiple images with gallery
                VStack(spacing: ReachuSpacing.md) {
                    // Main image display
                    TabView(selection: $selectedImageIndex) {
                        ForEach(Array(displayImages.enumerated()), id: \.element.id) { index, image in
                            LoadedImage(
                                url: URL(string: image.url),
                                placeholder: AnyView(RoundedRectangle(cornerRadius: productDetailConfig.imageCornerRadius)
                                    .fill(ReachuColors.background)
                                    .overlay { ProgressView() }),
                                errorView: AnyView(RoundedRectangle(cornerRadius: productDetailConfig.imageCornerRadius)
                                    .fill(ReachuColors.background)
                                    .overlay {
                                        Image(systemName: "exclamationmark.triangle")
                                            .foregroundColor(ReachuColors.error)
                                    })
                            )
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: .infinity)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: productDetailConfig.imageCornerRadius))
                            .onAppear {
                                if index == 0 {
                                    imageLoaded = true
                                }
                            }
                            .tag(index)
                        }
                    }
                    .frame(height: productDetailConfig.imageHeight ?? 300)
                    #if os(iOS) || os(tvOS) || os(watchOS)
                    .tabViewStyle(.page(indexDisplayMode: productDetailConfig.showImageGallery ? .always : .never))
                    #endif
                    
                    // Thumbnail gallery (conditionally shown)
                    if productDetailConfig.showImageGallery {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: ReachuSpacing.sm) {
                                ForEach(Array(displayImages.enumerated()), id: \.element.id) { index, image in
                                    LoadedImage(
                                        url: URL(string: image.url),
                                        placeholder: AnyView(RoundedRectangle(cornerRadius: ReachuBorderRadius.small)
                                            .fill(ReachuColors.background)
                                            .overlay {
                                                ProgressView()
                                                    .scaleEffect(0.5)
                                            }),
                                        errorView: AnyView(RoundedRectangle(cornerRadius: ReachuBorderRadius.small)
                                            .fill(ReachuColors.background)
                                            .overlay {
                                                Image(systemName: "exclamationmark.triangle")
                                                    .font(.caption)
                                                    .foregroundColor(ReachuColors.error)
                                            })
                                    )
                                    .aspectRatio(contentMode: .fill)
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
        }
        .padding(.top, productDetailConfig.imageFullWidth ? 0 : ReachuSpacing.md)
        .padding(.horizontal, productDetailConfig.imageFullWidth ? 0 : ReachuSpacing.lg)
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
                    // Current price - use price with taxes if available (what customer actually pays)
                    Text(formatted(amount: Double(currentPriceWithTaxes)))
                        .font(ReachuTypography.title3)
                        .foregroundColor(adaptiveColors.priceColor)
                    
                    // Compare at price (if available) - use compare at with taxes if available
                    if let compareAt = compareAtWithTaxes, compareAt > currentPriceWithTaxes {
                        Text(formatted(amount: Double(compareAt)))
                            .font(ReachuTypography.body)
                            .foregroundColor(adaptiveColors.textSecondary)
                            .strikethrough()
                    } else {
                        // Spacer to maintain consistent height
                        Text("")
                            .font(ReachuTypography.body)
                            .opacity(0)
                    }
                }
                .frame(minHeight: 50)  // Fixed minimum height for consistent layout
                
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
                    Text(RLocalizedString(ReachuTranslationKey.options.rawValue))
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
                                                        adaptiveColors.surface : ReachuColors.textPrimary
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
            Text(RLocalizedString(ReachuTranslationKey.quantity.rawValue))
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
            }
        }
    }
    
    // MARK: - Description Section
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
            if let description = product.description, !description.isEmpty {
                Text(RLocalizedString(ReachuTranslationKey.productDescription.rawValue))
                    .font(ReachuTypography.caption1)
                    .fontWeight(.semibold)
                    .foregroundColor(ReachuColors.textPrimary)
                
                Text(cleanHTMLString(description))
                    .font(ReachuTypography.caption1)
                    .foregroundColor(ReachuColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(3)
            }
        }
    }
    
    // MARK: - HTML Cleaning Helper
    
    /// Limpia tags HTML de un string
    private func cleanHTMLString(_ html: String) -> String {
        // Remover tags HTML
        var cleaned = html.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        // Decodificar entidades HTML comunes
        cleaned = cleaned.replacingOccurrences(of: "&nbsp;", with: " ")
        cleaned = cleaned.replacingOccurrences(of: "&amp;", with: "&")
        cleaned = cleaned.replacingOccurrences(of: "&lt;", with: "<")
        cleaned = cleaned.replacingOccurrences(of: "&gt;", with: ">")
        cleaned = cleaned.replacingOccurrences(of: "&quot;", with: "\"")
        cleaned = cleaned.replacingOccurrences(of: "&#39;", with: "'")
        // Clean multiple spaces and line breaks
        cleaned = cleaned.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Specifications Section
    private var specificationsSection: some View {
        VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
            Text(RLocalizedString(ReachuTranslationKey.productDetails.rawValue))
                .font(ReachuTypography.caption1)
                .fontWeight(.semibold)
                .foregroundColor(ReachuColors.textPrimary)
            
            VStack(spacing: ReachuSpacing.xs) {
                if !product.sku.isEmpty {
                    specificationRow(title: RLocalizedString(ReachuTranslationKey.sku.rawValue), value: product.sku)
                }
                
                if let categories = product.categories, !categories.isEmpty {
                    specificationRow(
                        title: RLocalizedString(ReachuTranslationKey.category.rawValue), 
                        value: categories.map(\.name).joined(separator: ", ")
                    )
                }
                
                if !product.supplier.isEmpty {
                    specificationRow(title: RLocalizedString(ReachuTranslationKey.supplier.rawValue), value: product.supplier)
                }
                
                specificationRow(title: RLocalizedString(ReachuTranslationKey.stock.rawValue), value: "\(selectedVariant?.quantity ?? product.quantity ?? 0) \(RLocalizedString(ReachuTranslationKey.available.rawValue))")
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
                            .foregroundColor(adaptiveColors.surface)
                    } else if isAddingToCart {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: adaptiveColors.surface))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "cart.badge.plus")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(adaptiveColors.surface)
                    }
                    
                    // Button text
                    Text(showCheckmark ? RLocalizedString(ReachuTranslationKey.completePurchase.rawValue) : isAddingToCart ? RLocalizedString(ReachuTranslationKey.loading.rawValue) : RLocalizedString(ReachuTranslationKey.addToCart.rawValue))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(adaptiveColors.surface)
                    
                    Spacer()
                    
                    // Price - use price with taxes if available (what customer actually pays)
                    if !isAddingToCart && !showCheckmark {
                        Text(formatted(amount: Double(currentPriceWithTaxes) * Double(quantity)))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(adaptiveColors.surface)
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
                .reachuCardShadow(for: colorScheme)
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
        // Start loading animation
        withAnimation(.easeInOut(duration: 0.1)) {
            buttonScale = 0.95
            isAddingToCart = true
        }
        
        // Scale back button
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                buttonScale = 1.0
            }
        }
        
        // Haptic feedback
        #if os(iOS)
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        #endif
        
        // Track product added to cart
        let priceToTrack = selectedVariant?.price.amount ?? product.price.amount
        AnalyticsManager.shared.trackProductAddedToCart(
            productId: String(product.id),
            productName: product.title,
            quantity: quantity,
            productPrice: Double(priceToTrack),
            productCurrency: product.price.currency_code,
            source: "product_detail"
        )
        
        // Add to cart 
        Task {
            await cartManager.addProduct(product, variant: selectedVariant, quantity: quantity)
            
            // Show quick success animation then close modal
            await MainActor.run {
                // Show success animation briefly
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    showSuccessAnimation = true
                }
                
                // Close modal after brief animation (0.6 seconds)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    // Call callback before dismissing
                    onAddToCart?(product)
                    
                    // Close modal
                    dismiss()
                }
            }
        }
    }
    
    // MARK: - Helper Functions for Variants    
    private var sortedOptions: [Option] {
        guard let options = product.options else { return [] }
        return options.sorted { $0.order < $1.order }
    }
    
    private func parseVariantTitle(_ title: String) -> [String] {
        let components = title.components(separatedBy: "-")
        if components.count == 1 {
            return title.components(separatedBy: " - ")
        }
        return components.map { $0.trimmingCharacters(in: .whitespaces) }
    }
    
    private func groupVariantsByOptions() -> [String: [String]] {
        let sortedOpts = sortedOptions
        guard !sortedOpts.isEmpty else { return [:] }
        
        var options: [String: Set<String>] = [:]
        for option in sortedOpts {
            options[option.name] = Set<String>()
        }
        
        for variant in product.variants {
            let components = parseVariantTitle(variant.title)            
            for (index, value) in components.enumerated() {
                if index < sortedOpts.count {
                    let optionName = sortedOpts[index].name
                    options[optionName, default: Set()].insert(value.trimmingCharacters(in: .whitespaces))
                }
            }
        }
        let orderedPairs: [(String, [String])] = sortedOpts.map { opt in
            (opt.name, Array(options[opt.name] ?? []).sorted())
        }
        return Dictionary(uniqueKeysWithValues: orderedPairs)
    }
    
    /// Update selected variant based on selected options
    private func updateSelectedVariant() {
        let sortedOpts = sortedOptions
        guard !sortedOpts.isEmpty else {
            selectedVariant = product.variants.first
            return
        }
        
        // Find variant that matches selected options
        for variant in product.variants {
            let components = parseVariantTitle(variant.title)
            
            var matches = true            
            for (index, option) in sortedOpts.enumerated() {
                if index < components.count {
                    let expectedValue = components[index].trimmingCharacters(in: .whitespaces)

                    if let selectedValue = selectedOptions[option.name], selectedValue != expectedValue {
                        matches = false
                        break
                    }
                } else {
                    matches = false
                    break
                }
            }
            
            if matches {
                for option in sortedOpts {
                    if selectedOptions[option.name] == nil {
                        matches = false
                        break
                    }
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
        
        let sortedOpts = sortedOptions
        guard !sortedOpts.isEmpty else {
            selectedVariant = firstVariant
            return
        }
        
        let components = parseVariantTitle(firstVariant.title)        
        for (index, value) in components.enumerated() {
            if index < sortedOpts.count {
                let optionName = sortedOpts[index].name
                selectedOptions[optionName] = value.trimmingCharacters(in: .whitespaces)
            }
        }
        
        selectedVariant = firstVariant
    }
    
    // MARK: - Success Animation Overlay
    
    @ViewBuilder
    private var successAnimationOverlay: some View {
        ZStack {
            // Semi-transparent background
            adaptiveColors.textPrimary.opacity(0.3)
                .ignoresSafeArea()
            
            // Success animation
            VStack(spacing: ReachuSpacing.md) {
                // Animated circle with checkmark
                ZStack {
                    Circle()
                        .fill(ReachuColors.success)
                        .frame(width: 80, height: 80)
                        .scaleEffect(showSuccessAnimation ? 1.0 : 0.5)
                        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: showSuccessAnimation)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(adaptiveColors.surface)
                        .scaleEffect(showSuccessAnimation ? 1.0 : 0.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6).delay(0.2), value: showSuccessAnimation)
                }
                
                // Success text
                VStack(spacing: ReachuSpacing.xs) {
                    Text(RLocalizedString(ReachuTranslationKey.completePurchase.rawValue))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(adaptiveColors.surface)
                        .opacity(showSuccessAnimation ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 0.3).delay(0.4), value: showSuccessAnimation)
                    
                    Text("\(quantity) × \(product.title)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(adaptiveColors.surface.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .opacity(showSuccessAnimation ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 0.3).delay(0.5), value: showSuccessAnimation)
                }
            }
            .padding(ReachuSpacing.xl)
            .background(
                RoundedRectangle(cornerRadius: ReachuBorderRadius.large)
                    .fill(adaptiveColors.textPrimary.opacity(0.8))
            )
            .scaleEffect(showSuccessAnimation ? 1.0 : 0.8)
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: showSuccessAnimation)
        }
    }
    
    // MARK: - Toast Overlay View
    
    @ViewBuilder
    private var toastOverlayView: some View {
        VStack {
            HStack(spacing: ReachuSpacing.sm) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(ReachuColors.success)
                
                Text("Added \(product.title) to cart")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(ReachuColors.textPrimary)
                    .lineLimit(1)
                
                Spacer()
            }
            .padding(.horizontal, ReachuSpacing.md)
            .padding(.vertical, ReachuSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: ReachuBorderRadius.medium)
                    .fill(ReachuColors.surface)
                    .reachuCardShadow(for: colorScheme)
            )
            .padding(.horizontal, ReachuSpacing.lg)
            .padding(.top, ReachuSpacing.lg)
            
            Spacer()
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }
    
    // MARK: - Overlay Close Button
    private var overlayCloseButton: some View {
        Button(action: {
            onDismiss?()
            dismiss()
        }) {
            ZStack {
                Circle()
                    .fill(adaptiveColors.textPrimary.opacity(0.6))
                    .frame(width: 36, height: 36)
                
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(adaptiveColors.surface)
            }
        }
        .padding(.top, 16)
        .padding(.leading, productDetailConfig.closeButtonStyle == .overlayTopLeft ? 16 : 0)
        .padding(.trailing, productDetailConfig.closeButtonStyle == .overlayTopRight ? 16 : 0)
        .frame(maxWidth: .infinity, alignment: productDetailConfig.closeButtonStyle == .overlayTopLeft ? .leading : .trailing)
    }
}

// MARK: - View Modifiers

/// Custom ViewModifier to apply presentation detents based on configuration
struct ProductDetailPresentationModifier: ViewModifier {
    let config: ProductDetailConfiguration
    
    @ViewBuilder
    func body(content: Content) -> some View {
        #if os(iOS)
        if #available(iOS 16.0, *) {
            if config.dismissOnTapOutside {
                if #available(iOS 16.4, *) {
                    content
                        .presentationDetents(presentationDetentsSet)
                        .presentationBackgroundInteraction(.enabled(upThrough: .large))
                } else {
                    content
                        .presentationDetents(presentationDetentsSet)
                }
            } else {
                content
                    .presentationDetents(presentationDetentsSet)
            }
        } else {
            content
        }
        #else
        content
        #endif
    }
    
    #if os(iOS)
    @available(iOS 16.0, *)
    private var presentationDetentsSet: Set<PresentationDetent> {
        switch config.modalHeight {
        case .full:
            return [.large]
        case .threeQuarters:
            return [.fraction(0.75), .large]
        case .half:
            return [.medium, .large]
        }
    }
    #endif
}

// MARK: - View Extensions
extension View {
    /// Conditionally apply a view modifier
    @ViewBuilder
    func `if`<Transform: View>(
        _ condition: Bool,
        transform: (Self) -> Transform
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
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

import SwiftUI
import ReachuCore
import ReachuUI

/// Componente para mostrar un producto individual
/// Estilo basado en las cards del SDK de Reachu
/// Los productos se fetchean desde la API de Reachu usando el ID del WebSocket
struct ViaplayProductOverlay: View {
    let productEvent: ProductEventData  // Datos del WebSocket (incluye ID y fallback)
    let isChatExpanded: Bool
    let sdk: SdkClient
    let currency: String
    let country: String
    let onAddToCart: (ProductDto?) -> Void  // Pasa el producto real de la API si está disponible
    let onDismiss: () -> Void
    
    @StateObject private var viewModel: ProductFetchViewModel
    @State private var dragOffset: CGFloat = 0
    @State private var showCheckmark = false
    @State private var showProductDetail = false
    @EnvironmentObject private var cartManager: CartManager
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    init(
        productEvent: ProductEventData,
        isChatExpanded: Bool,
        sdk: SdkClient,
        currency: String,
        country: String,
        onAddToCart: @escaping (ProductDto?) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.productEvent = productEvent
        self.isChatExpanded = isChatExpanded
        self.sdk = sdk
        self.currency = currency
        self.country = country
        self.onAddToCart = onAddToCart
        self.onDismiss = onDismiss
        
        // Inicializar el ViewModel
        let vm = ProductFetchViewModel(sdk: sdk, currency: currency, country: country)
        _viewModel = StateObject(wrappedValue: vm)
    }
    
    private var isLandscape: Bool {
        verticalSizeClass == .compact
    }
    
    // Ajustar bottom padding basado en si el chat está expandido
    private var bottomPadding: CGFloat {
        if isLandscape {
            return isChatExpanded ? 250 : 156 // En landscape, espacio para el chat con 2 mensajes (140 + 16)
        } else {
            return isChatExpanded ? 250 : 80 // Más espacio cuando el chat está expandido
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if isLandscape {
                // Horizontal: lado derecho, ancho suficiente para contenido
                Spacer()
                HStack(spacing: 0) {
                    Spacer()
                    productCard
                        .frame(width: 280)
                        .padding(.trailing, 16)
                        .padding(.bottom, 16)
                        .offset(x: dragOffset)
                        .gesture(dragGesture)
                }
            } else {
                // Vertical: sobre el chat
                Spacer()
                productCard
                    .padding(.horizontal, 16)
                    .padding(.bottom, bottomPadding)
                    .offset(y: dragOffset)
                    .gesture(dragGesture)
            }
        }
        .task(id: productEvent.productId) {
            // Fetch del producto cuando aparece el componente o cambia el productId
            await viewModel.fetchProduct(productId: productEvent.productId)
        }
        .onChange(of: productEvent.productId) { newProductId in
            // Asegurar que el fetch se ejecute cuando cambia el productId
            Task {
                await viewModel.fetchProduct(productId: newProductId)
            }
        }
        .sheet(isPresented: $showProductDetail) {
            if let apiProduct = viewModel.product {
                // Convertir ProductDto a Product para el overlay
                RProductDetailOverlay(
                    product: convertDtoToProduct(apiProduct),
                    onDismiss: {
                        showProductDetail = false
                    },
                    onAddToCart: { product in
                        // RProductDetailOverlay ya agrega al cart internamente
                        // Solo cerramos el modal y mostramos feedback
                        showProductDetail = false
                        showCheckmark = true
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            showCheckmark = false
                        }
                    }
                )
                .environmentObject(cartManager)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    /// Nombre del producto (API > WebSocket fallback)
    private var displayName: String {
        if let apiProduct = viewModel.product {
            return apiProduct.title
        }
        return productEvent.name
    }
    
    /// Descripción del producto (API > WebSocket fallback)
    private var displayDescription: String {
        let rawDescription: String
        if let apiProduct = viewModel.product {
            rawDescription = apiProduct.description ?? ""
        } else {
            rawDescription = productEvent.description
        }
        // Limpiar HTML tags
        return cleanHTMLString(rawDescription)
    }
    
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
        // Limpiar espacios múltiples y saltos de línea
        cleaned = cleaned.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Precio formateado del producto (API > WebSocket fallback)
    private var displayPrice: String {
        if let apiProduct = viewModel.product {
            // Use price with taxes if available, otherwise use base price
            let priceToShow = apiProduct.price.amountInclTaxes ?? apiProduct.price.amount
            return "\(apiProduct.price.currencyCode) \(String(format: "%.2f", priceToShow))"
        }
        return productEvent.price
    }
    
    /// URL de la imagen del producto (API > WebSocket fallback)
    private var displayImageUrl: String {
        if let apiProduct = viewModel.product,
           let firstImage = apiProduct.images.first {
            return firstImage.url
        }
        return productEvent.imageUrl
    }
    
    /// campaignLogo siempre viene del WebSocket
    private var displayCampaignLogo: String? {
        return productEvent.campaignLogo
    }
    
    private var discountPercentage: Int? {
        guard let apiProduct = viewModel.product else { return nil }
        
        // Use prices with taxes for discount calculation
        let currentPrice = apiProduct.price.amountInclTaxes ?? apiProduct.price.amount
        let originalPrice = apiProduct.price.compareAtInclTaxes ?? apiProduct.price.compareAt
        
        guard let compareAt = originalPrice, compareAt > currentPrice else {
            return nil
        }
        
        let discount = ((compareAt - currentPrice) / compareAt) * 100
        return Int(discount.rounded())
    }
    
    private var shouldShowDiscountBadge: Bool {
        guard ReachuConfiguration.shared.uiConfiguration.showDiscountBadge else {
            return false
        }
        return discountPercentage != nil && (discountPercentage ?? 0) > 0
    }
    
    // MARK: - Conversion Helper
    
    /// Convierte ProductDto a Product para usar con RProductDetailOverlay
    private func convertDtoToProduct(_ dto: ProductDto) -> Product {
        // Limpiar HTML de la descripción
        let cleanDescription = dto.description.map { cleanHTMLString($0) }
        
        return Product(
            id: dto.id,
            title: dto.title,
            brand: dto.brand,
            description: cleanDescription,
            tags: dto.tags,
            sku: dto.sku,
            quantity: dto.quantity,
            price: Price(
                amount: Float(dto.price.amount),
                currency_code: dto.price.currencyCode,
                amount_incl_taxes: dto.price.amountInclTaxes.map { Float($0) },
                tax_amount: dto.price.taxAmount.map { Float($0) },
                tax_rate: dto.price.taxRate.map { Float($0) },
                compare_at: dto.price.compareAt.map { Float($0) },
                compare_at_incl_taxes: dto.price.compareAtInclTaxes.map { Float($0) }
            ),
            variants: dto.variants.map { v in
                Variant(
                    id: v.id,
                    barcode: v.barcode,
                    price: Price(
                        amount: Float(v.price.amount),
                        currency_code: v.price.currencyCode,
                        amount_incl_taxes: v.price.amountInclTaxes.map { Float($0) },
                        tax_amount: v.price.taxAmount.map { Float($0) },
                        tax_rate: v.price.taxRate.map { Float($0) },
                        compare_at: v.price.compareAt.map { Float($0) },
                        compare_at_incl_taxes: v.price.compareAtInclTaxes.map { Float($0) }
                    ),
                    quantity: v.quantity,
                    sku: v.sku,
                    title: v.title,
                    images: v.images.map { ProductImage(id: $0.id, url: $0.url, width: $0.width, height: $0.height, order: $0.order ?? 0) }
                )
            },
            barcode: dto.barcode,
            options: dto.options.map { Option(id: $0.id, name: $0.name, order: $0.order, values: $0.values) },
            categories: dto.categories?.map { _Category(id: $0.id, name: $0.name) },
            images: dto.images.map { ProductImage(id: $0.id, url: $0.url, width: $0.width, height: $0.height, order: $0.order ?? 0) },
            product_shipping: nil,
            supplier: dto.supplier,
            supplier_id: dto.supplierId,
            imported_product: dto.importedProduct,
            referral_fee: dto.referralFee,
            options_enabled: dto.optionsEnabled,
            digital: dto.digital,
            origin: dto.origin,
            return: nil
        )
    }
    
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if isLandscape {
                    if value.translation.width > 0 {
                        dragOffset = value.translation.width
                    }
                } else {
                    if value.translation.height > 0 {
                        dragOffset = value.translation.height
                    }
                }
            }
            .onEnded { value in
                let threshold: CGFloat = 100
                if isLandscape {
                    if value.translation.width > threshold {
                        onDismiss()
                    } else {
                        withAnimation(.spring()) {
                            dragOffset = 0
                        }
                    }
                } else {
                    if value.translation.height > threshold {
                        onDismiss()
                    } else {
                        withAnimation(.spring()) {
                            dragOffset = 0
                        }
                    }
                }
            }
    }
    
    private var productCard: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                // Drag indicator
                Capsule()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 40, height: 4)
                    .padding(.top, 4)
                
                // Loading indicator sutil mientras se carga
                if viewModel.isLoading {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.7)
                            .tint(.white)
                        Text("Cargando producto...")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.vertical, 4)
                }
                
                // Sponsor badge arriba a la izquierda
                if let campaignLogo = displayCampaignLogo, !campaignLogo.isEmpty {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Sponset av")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                            
                            AsyncImage(url: URL(string: campaignLogo)) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(maxWidth: 80, maxHeight: 24)
                                case .empty:
                                    ProgressView()
                                        .scaleEffect(0.5)
                                        .frame(width: 80, height: 24)
                                case .failure:
                                    EmptyView()
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 2)
                }
                
                // Producto con imagen pequeña a la izquierda
                HStack(alignment: .top, spacing: 12) {
                    // Imagen del producto pequeña
                    ZStack(alignment: .topTrailing) {
                        AsyncImage(url: URL(string: displayImageUrl)) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(width: 90, height: 90)
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 90, height: 90)
                                    .clipped()
                                    .cornerRadius(12)
                            case .failure:
                                Color.gray.opacity(0.3)
                                    .frame(width: 90, height: 90)
                                    .cornerRadius(12)
                                    .overlay(
                                        Image(systemName: "photo")
                                            .font(.system(size: 24))
                                            .foregroundColor(.white.opacity(0.5))
                                    )
                            @unknown default:
                                EmptyView()
                            }
                        }
                        
                        // Tag de descuento diagonal (calculado dinámicamente)
                        if shouldShowDiscountBadge, let discount = discountPercentage {
                            Text("-\(discount)%")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    ViaplayTheme.Colors.pink
                                )
                                .rotationEffect(.degrees(-10))
                                .offset(x: 8, y: -8)
                                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                    }
                    
                    // Información del producto a la derecha
                    VStack(alignment: .leading, spacing: 6) {
                        Text(displayName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(2)
                        
                        if !displayDescription.isEmpty {
                            Text(displayDescription)
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.7))
                                .lineLimit(2)
                        }
                        
                        // Precio
                        Text(displayPrice)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(ViaplayTheme.Colors.pink)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // Botón para ver detalles (NO agrega directamente)
                Button(action: {
                    // Siempre abrir el product detail modal
                    if viewModel.product != nil {
                        showProductDetail = true
                    }
                    // Si el producto aún no ha cargado, no hace nada (espera a que cargue)
                }) {
                    HStack(spacing: 6) {
                        if showCheckmark {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14))
                            Text("Lagt til!")
                                .font(.system(size: 13, weight: .semibold))
                        } else {
                            Text("Legg til")
                                .font(.system(size: 13, weight: .semibold))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(showCheckmark ? Color.green : (viewModel.product != nil ? ViaplayTheme.Colors.pink.opacity(0.8) : Color.gray))
                    )
                }
                .disabled(showCheckmark || viewModel.product == nil)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.4))
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.ultraThinMaterial)
                    )
            )
            .shadow(color: .black.opacity(0.6), radius: 20, x: 0, y: 8)
        }
    }
}

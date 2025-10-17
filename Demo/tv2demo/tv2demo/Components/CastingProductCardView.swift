import SwiftUI
import ReachuCore
import ReachuUI

/// Wrapper de TV2ProductOverlay.productCard con ProductFetchViewModel propio
/// Carga datos desde Reachu API y los muestra
struct CastingProductCardView: View {
    let productEvent: ProductEventData
    let sdk: SdkClient
    let currency: String
    let country: String
    let onAddToCart: (ProductDto?) -> Void
    let onDismiss: () -> Void
    
    @StateObject private var viewModel: ProductFetchViewModel
    @State private var showCheckmark = false
    @State private var showProductDetail = false
    @State private var dragOffset: CGFloat = 0
    
    init(
        productEvent: ProductEventData,
        sdk: SdkClient,
        currency: String,
        country: String,
        onAddToCart: @escaping (ProductDto?) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.productEvent = productEvent
        self.sdk = sdk
        self.currency = currency
        self.country = country
        self.onAddToCart = onAddToCart
        self.onDismiss = onDismiss
        
        // Crear ProductFetchViewModel NUEVO para este producto
        let vm = ProductFetchViewModel(sdk: sdk, currency: currency, country: country)
        _viewModel = StateObject(wrappedValue: vm)
    }
    
    // MARK: - Computed Properties (COPIADAS de TV2ProductOverlay)
    
    private var displayName: String {
        if let apiProduct = viewModel.product {
            return apiProduct.title
        }
        return productEvent.name
    }
    
    private var displayDescription: String {
        let rawDescription: String
        if let apiProduct = viewModel.product {
            rawDescription = apiProduct.description ?? ""
        } else {
            rawDescription = productEvent.description
        }
        return rawDescription
    }
    
    private var displayPrice: String {
        if let apiProduct = viewModel.product {
            return "\(apiProduct.price.currencyCode) \(String(format: "%.2f", apiProduct.price.amount))"
        }
        return productEvent.price
    }
    
    private var displayImageUrl: String {
        if let apiProduct = viewModel.product,
           let firstImage = apiProduct.images.first {
            return firstImage.url
        }
        return productEvent.imageUrl
    }
    
    private var displayCampaignLogo: String? {
        return productEvent.campaignLogo
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                // Drag indicator
                Capsule()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 40, height: 4)
                    .padding(.top, 4)
                
                // Loading indicator
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
                
                // Sponsor badge
                if let campaignLogo = displayCampaignLogo, !campaignLogo.isEmpty {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Sponset av")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                            
                            AsyncImage(url: URL(string: campaignLogo)) { phase in
                                switch phase {
                                case .success(let image):
                                    image.resizable().aspectRatio(contentMode: .fit).frame(maxWidth: 80, maxHeight: 24)
                                case .empty:
                                    ProgressView().scaleEffect(0.5).frame(width: 80, height: 24)
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
                
                // Producto
                HStack(alignment: .top, spacing: 12) {
                    // Imagen
                    ZStack(alignment: .topTrailing) {
                        AsyncImage(url: URL(string: displayImageUrl)) { phase in
                            switch phase {
                            case .empty:
                                ProgressView().frame(width: 90, height: 90)
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
                        
                        // Tag descuento
                        Text("30% OFF")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(hex: "E93CAC"))
                            .rotationEffect(.degrees(-10))
                            .offset(x: 8, y: -8)
                            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                    
                    // Info
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
                        
                        Text(displayPrice)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(TV2Theme.Colors.primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // Botón
                Button(action: {
                    if viewModel.product != nil {
                        showProductDetail = true
                    } else {
                        onAddToCart(nil)
                        showCheckmark = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            showCheckmark = false
                        }
                    }
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
                            .fill(showCheckmark ? Color.green : Color(hex: "2C0D65"))
                    )
                }
                .disabled(showCheckmark)
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
        }
        .frame(maxWidth: UIScreen.main.bounds.width - 40) // Margen de 20px a cada lado
        .offset(y: dragOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    if value.translation.height > 0 {
                        dragOffset = value.translation.height
                    }
                }
                .onEnded { value in
                    if value.translation.height > 100 {
                        onDismiss()
                    } else {
                        withAnimation(.spring()) {
                            dragOffset = 0
                        }
                    }
                }
        )
        .task {
            await viewModel.fetchProduct(productId: productEvent.productId)
        }
        .sheet(isPresented: $showProductDetail) {
            if let apiProduct = viewModel.product {
                RProductDetailOverlay(
                    product: convertDtoToProduct(apiProduct),
                    onDismiss: {
                        showProductDetail = false
                    },
                    onAddToCart: { product in
                        onAddToCart(viewModel.product)
                        showProductDetail = false
                        showCheckmark = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            showCheckmark = false
                        }
                    }
                )
            }
        }
    }
    
    // MARK: - Conversion Helper
    
    private func convertDtoToProduct(_ dto: ProductDto) -> Product {
        return Product(
            id: dto.id,
            title: dto.title,
            brand: dto.brand,
            description: dto.description,
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
}


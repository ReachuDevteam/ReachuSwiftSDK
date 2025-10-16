import SwiftUI
import ReachuUI
import ReachuCore

/// Vista que se muestra cuando el casting está activo
/// Permite controlar el video y ver los overlays mientras se castea
struct CastingActiveView: View {
    let match: Match
    @StateObject private var castingManager = CastingManager.shared
    @StateObject private var webSocketManager = WebSocketManager()
    @EnvironmentObject private var cartManager: CartManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var isPlaying = true
    @State private var isChatExpanded = false
    @State private var showPoll = false
    @State private var showProduct = false
    @State private var showContest = false
    @State private var showControls = true
    
    private var sdkClient: SdkClient {
        SdkClient(
            baseUrl: URL(string: "https://api.reachu.io/graphql")!,
            apiKey: ReachuConfiguration.shared.apiKey
        )
    }
    
    var body: some View {
        ZStack {
            // Background
            Image("football_field_bg")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
                .blur(radius: 20)
            
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            // Contenido principal con ALTA prioridad de z-index
            VStack(spacing: 0) {
                // Header
                castingHeader
                
                Spacer()
                
                // Match info
                matchInfo
                
                Spacer()
                
                // Controles
                playbackControls
            }
            .zIndex(1) // Asegurar que esté encima del fondo
            
            // Contest Overlay
            if let contest = webSocketManager.currentContest, showContest {
                TV2ContestOverlay(
                    contest: contest,
                    isChatExpanded: isChatExpanded,
                    onJoin: {
                        print("🎁 [Contest] Usuario se unió: \(contest.name)")
                    },
                    onDismiss: {
                        withAnimation {
                            showContest = false
                        }
                    }
                )
                .zIndex(2)
            }
            
            // Product Overlay
            if let productEvent = webSocketManager.currentProduct, showProduct {
                TV2ProductOverlay(
                    productEvent: productEvent,
                    isChatExpanded: isChatExpanded,
                    sdk: sdkClient,
                    currency: cartManager.currency,
                    country: cartManager.country,
                    onAddToCart: { productDto in
                        if let apiProduct = productDto {
                            print("🛍️ [Product] Agregando producto al carrito: \(apiProduct.title)")
                            let product = convertDtoToProduct(apiProduct)
                            Task {
                                await cartManager.addProduct(product, quantity: 1)
                                print("✅ [Product] Producto agregado al carrito")
                            }
                        } else {
                            print("⚠️ [Product] Producto aún no disponible: \(productEvent.name)")
                        }
                    },
                    onDismiss: {
                        withAnimation {
                            showProduct = false
                        }
                    }
                )
                .zIndex(3)
            }
            
            // Poll Overlay
            if let poll = webSocketManager.currentPoll, showPoll {
                TV2PollOverlay(
                    poll: poll,
                    isChatExpanded: isChatExpanded,
                    onVote: { option in
                        print("📊 [Poll] Votado: \(option)")
                    },
                    onDismiss: {
                        withAnimation {
                            showPoll = false
                        }
                    }
                )
                .zIndex(4)
            }
            
            // Chat Overlay (SIEMPRE en el top)
            TV2ChatOverlay(
                showControls: $showControls,
                onExpandedChange: { expanded in
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                        isChatExpanded = expanded
                    }
                }
            )
            .zIndex(5)
        }
        .navigationBarHidden(true)
        .onAppear {
            webSocketManager.connect()
        }
        .onDisappear {
            webSocketManager.disconnect()
        }
        .onChange(of: webSocketManager.currentPoll) { newPoll in
            withAnimation {
                showPoll = newPoll != nil
            }
        }
        .onChange(of: webSocketManager.currentProduct) { newProduct in
            withAnimation {
                showProduct = newProduct != nil
            }
        }
        .onChange(of: webSocketManager.currentContest) { newContest in
            withAnimation {
                showContest = newContest != nil
            }
        }
    }
    
    // MARK: - Components
    
    private var castingHeader: some View {
        HStack(alignment: .top) {
            // Back button
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
            }
            
            // Casting info centrada
            VStack(spacing: 4) {
                Text(match.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(match.subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.top, 8)
            
            // Stop Casting button
            Button(action: {
                castingManager.stopCasting()
                dismiss()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "tv.slash")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Stop")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.red.opacity(0.8))
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 50)
    }
    
    private var matchInfo: some View {
        VStack(spacing: 20) {
            // Mensaje de "Casting to..."
            Text("Casting to \(castingManager.selectedDevice?.name ?? "Living TV")")
                .font(.system(size: 17))
                .foregroundColor(.white)
            
            // Progreso/tiempo
            VStack(spacing: 16) {
                // Barra de progreso
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        Capsule()
                            .fill(Color.white.opacity(0.3))
                            .frame(height: 4)
                        
                        // Progress (simulado al 50%)
                        Capsule()
                            .fill(Color.white)
                            .frame(width: geometry.size.width * 0.5, height: 4)
                    }
                }
                .frame(height: 4)
                .padding(.horizontal, 40)
                
                // Tiempo
                HStack {
                    Text("3:24:39")
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("LIVE")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 40)
            }
        }
    }
    
    private var playbackControls: some View {
        HStack(spacing: 40) {
            // Rewind
            Button(action: {}) {
                Image(systemName: "gobackward.30")
                    .font(.system(size: 32))
                    .foregroundColor(.white)
            }
            
            // Play/Pause
            Button(action: { isPlaying.toggle() }) {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 70, height: 70)
                    
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.black)
                }
            }
            
            // Forward
            Button(action: {}) {
                Image(systemName: "goforward.30")
                    .font(.system(size: 32))
                    .foregroundColor(.white)
            }
        }
    }
    
    // MARK: - Conversion Helpers (copiadas de TV2VideoPlayer)
    
    private func convertPrice(_ priceDto: PriceDto) -> Price {
        return Price(
            amount: Float(priceDto.amount),
            currency_code: priceDto.currencyCode,
            amount_incl_taxes: priceDto.amountInclTaxes.map { Float($0) },
            tax_amount: priceDto.taxAmount.map { Float($0) },
            tax_rate: priceDto.taxRate.map { Float($0) },
            compare_at: priceDto.compareAt.map { Float($0) },
            compare_at_incl_taxes: priceDto.compareAtInclTaxes.map { Float($0) }
        )
    }
    
    private func convertImages(_ imageDtos: [ProductImageDto]) -> [ProductImage] {
        return imageDtos.map { 
            ProductImage(
                id: $0.id, 
                url: $0.url, 
                width: $0.width, 
                height: $0.height, 
                order: $0.order ?? 0
            ) 
        }
    }
    
    private func convertVariants(_ variantDtos: [VariantDto]) -> [Variant] {
        return variantDtos.map { variantDto in
            Variant(
                id: variantDto.id,
                barcode: variantDto.barcode,
                price: convertPrice(variantDto.price),
                quantity: variantDto.quantity,
                sku: variantDto.sku,
                title: variantDto.title,
                images: convertImages(variantDto.images)
            )
        }
    }
    
    private func convertDtoToProduct(_ dto: ProductDto) -> Product {
        let price = convertPrice(dto.price)
        let variants = convertVariants(dto.variants)
        let images = convertImages(dto.images)
        
        let options = dto.options.map { 
            Option(
                id: $0.id, 
                name: $0.name, 
                order: $0.order, 
                values: $0.values
            ) 
        }
        
        let categories = dto.categories?.map { 
            _Category(id: $0.id, name: $0.name) 
        }
        
        let shipping = dto.productShipping?.map { s in
            ProductShipping(
                id: s.id,
                name: s.name,
                description: s.description,
                custom_price_enabled: s.customPriceEnabled,
                default: s.defaultOption,
                shipping_country: s.shippingCountry?.map { sc in
                    ShippingCountry(
                        id: sc.id,
                        country: sc.country,
                        price: BasePrice(
                            amount: Float(sc.price.amount),
                            currency_code: sc.price.currencyCode,
                            amount_incl_taxes: sc.price.amountInclTaxes.map { Float($0) },
                            tax_amount: sc.price.taxAmount.map { Float($0) },
                            tax_rate: sc.price.taxRate.map { Float($0) }
                        )
                    )
                }
            )
        }
        
        let returnInfo = dto.returnInfo.map { r in
            ReturnInfo(
                return_right: r.returnRight,
                return_label: r.returnLabel,
                return_cost: r.returnCost.map { Float($0) },
                supplier_policy: r.supplierPolicy,
                return_address: r.returnAddress.map { ra in
                    ReturnAddress(
                        same_as_business: ra.sameAsBusiness,
                        same_as_warehouse: ra.sameAsWarehouse,
                        country: ra.country,
                        timezone: ra.timezone,
                        address: ra.address,
                        address_2: ra.address2,
                        post_code: ra.postCode,
                        return_city: ra.returnCity
                    )
                }
            )
        }
        
        return Product(
            id: dto.id,
            title: dto.title,
            brand: dto.brand,
            description: dto.description,
            tags: dto.tags,
            sku: dto.sku,
            quantity: dto.quantity,
            price: price,
            variants: variants,
            barcode: dto.barcode,
            options: options,
            categories: categories,
            images: images,
            product_shipping: shipping,
            supplier: dto.supplier,
            supplier_id: dto.supplierId,
            imported_product: dto.importedProduct,
            referral_fee: dto.referralFee,
            options_enabled: dto.optionsEnabled,
            digital: dto.digital,
            origin: dto.origin,
            return: returnInfo
        )
    }
}

#Preview {
    CastingActiveView(match: Match.barcelonaPSG)
        .environmentObject(CartManager())
}


import SwiftUI
import ReachuUI
import ReachuCore

/// Vista que se muestra cuando el casting está activo
/// Permite controlar el video y ver los overlays mientras se castea
struct CastingActiveView: View {
    let match: Match
    @StateObject private var castingManager = CastingManager.shared
    @StateObject private var webSocketManager = WebSocketManager()
    @StateObject private var chatManager = ChatManager()
    @EnvironmentObject private var cartManager: CartManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var isPlaying = true
    @State private var isChatExpanded = false
    @State private var chatMessage = ""
    @State private var hasVotedInPoll = false
    @State private var selectedPollOption: String?
    @State private var showProductDetail = false
    @State private var selectedProduct: Product?
    @StateObject private var productViewModel: ProductFetchViewModel
    
    private var sdkClient: SdkClient {
        SdkClient(
            baseUrl: URL(string: "https://api.reachu.io/graphql")!,
            apiKey: ReachuConfiguration.shared.apiKey
        )
    }
    
    init(match: Match) {
        self.match = match
        let sdk = SdkClient(
            baseUrl: URL(string: "https://api.reachu.io/graphql")!,
            apiKey: ReachuConfiguration.shared.apiKey
        )
        _productViewModel = StateObject(wrappedValue: ProductFetchViewModel(
            sdk: sdk,
            currency: "NOK",
            country: "NO"
        ))
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
            
            // Contenido principal en VStack simple
            VStack(spacing: 20) {
                // Header
                castingHeader
                
                Spacer()
                
                // Match info
                matchInfo
                
                Spacer()
                
                // Eventos interactivos (cards INLINE con tamaños FIJOS)
                if let poll = webSocketManager.currentPoll {
                    simplePollCard(poll)
                } else if let productEvent = webSocketManager.currentProduct {
                    simpleProductCard(productEvent)
                } else if let contest = webSocketManager.currentContest {
                    simpleContestCard(contest)
                }
                
                Spacer()
                
                // Controles (se mueven hacia arriba cuando chat se expande)
                playbackControls
                    .offset(y: isChatExpanded ? -150 : 0)
                    .animation(.spring(response: 0.3), value: isChatExpanded)
                
                // Espacio dinámico
                Spacer()
                    .frame(height: isChatExpanded ? 0 : 20)
                
                // Chat
                simpleChatPanel
                    .padding(.bottom, 20)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            webSocketManager.connect()
            chatManager.startSimulation()
        }
        .onDisappear {
            webSocketManager.disconnect()
            chatManager.stopSimulation()
        }
        .onChange(of: webSocketManager.currentPoll) { _ in
            hasVotedInPoll = false
            selectedPollOption = nil
        }
        .sheet(isPresented: $showProductDetail) {
            if let product = selectedProduct {
                RProductDetailOverlay(
                    product: product,
                    onDismiss: {
                        showProductDetail = false
                    },
                    onAddToCart: { product in
                        Task {
                            await cartManager.addProduct(product, quantity: 1)
                            print("✅ Producto agregado al carrito desde casting view")
                        }
                        showProductDetail = false
                    }
                )
                .environmentObject(cartManager)
            }
        }
    }
    
    // MARK: - Simple Inline Cards (tamaños fijos, sin GeometryReader)
    
    private func simplePollCard(_ poll: PollEventData) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(poll.question)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                    Text("\(poll.duration)s")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                }
                Spacer(minLength: 0)
                Button("✕") {
                    webSocketManager.currentPoll = nil
                    hasVotedInPoll = false
                    selectedPollOption = nil
                }
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.6))
            }
            
            if hasVotedInPoll {
                // Resultados
                ForEach(poll.options, id: \.text) { option in
                    HStack(spacing: 10) {
                        if let avatarUrl = option.avatarUrl, !avatarUrl.isEmpty {
                            AsyncImage(url: URL(string: avatarUrl)) { image in
                                image.resizable().aspectRatio(contentMode: .fit)
                            } placeholder: {
                                Circle().fill(Color.white)
                            }
                            .frame(width: 28, height: 28)
                            .background(Color.white)
                            .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Text(option.text.prefix(1))
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(TV2Theme.Colors.primary)
                                )
                        }
                        
                        Text(option.text)
                            .font(.system(size: 13, weight: option.text == selectedPollOption ? .bold : .medium))
                            .foregroundColor(.white)
                            .frame(width: 70, alignment: .leading)
                        
                        // Barra de progreso
                        let percentage: CGFloat = option.text == selectedPollOption ? 75 : 12.5
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color.white.opacity(0.15))
                                .frame(width: 180, height: 26)
                            
                            RoundedRectangle(cornerRadius: 5)
                                .fill(option.text == selectedPollOption ? TV2Theme.Colors.primary : Color.white.opacity(0.3))
                                .frame(width: 180 * (percentage / 100), height: 26)
                        }
                        
                        Text("\(Int(percentage))%")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 35, alignment: .trailing)
                    }
                }
            } else {
                // Opciones para votar
                ForEach(poll.options, id: \.text) { option in
                    Button {
                        selectedPollOption = option.text
                        hasVotedInPoll = true
                        print("📊 Voted: \(option.text)")
                    } label: {
                        HStack(spacing: 10) {
                            if let avatarUrl = option.avatarUrl, !avatarUrl.isEmpty {
                                AsyncImage(url: URL(string: avatarUrl)) { image in
                                    image.resizable().aspectRatio(contentMode: .fit)
                                } placeholder: {
                                    Circle().fill(Color.white)
                                }
                                .frame(width: 32, height: 32)
                                .background(Color.white)
                                .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Text(option.text.prefix(1))
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(TV2Theme.Colors.primary)
                                    )
                            }
                            
                            Text(option.text)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Spacer(minLength: 0)
                        }
                        .frame(width: 360)
                        .padding(12)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(10)
                    }
                }
            }
        }
        .frame(width: 400)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.4))
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                )
                .shadow(color: Color.black.opacity(0.4), radius: 12, x: 0, y: 4)
        )
    }
    
    private func simpleProductCard(_ productEvent: ProductEventData) -> some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                // Drag indicator
                Capsule()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 40, height: 4)
                    .padding(.top, 4)
                
                // Loading indicator sutil mientras se carga
                if productViewModel.isLoading {
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
                
                // Sponsor badge (si existe)
                if let campaignLogo = productEvent.campaignLogo, !campaignLogo.isEmpty {
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
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 2)
                }
                
                // Producto con imagen pequeña a la izquierda
                HStack(alignment: .top, spacing: 12) {
                    // Imagen del producto - API > WebSocket fallback (IGUAL que TV2ProductOverlay)
                    ZStack(alignment: .topTrailing) {
                        let displayImageUrl: String = {
                            if let apiProduct = productViewModel.product,
                               let firstImage = apiProduct.images.first {
                                return firstImage.url
                            }
                            return productEvent.imageUrl
                        }()
                        
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
                        
                        // Tag de descuento diagonal (si está configurado)
                        if ReachuConfiguration.shared.uiConfiguration.showDiscountBadge,
                           let badgeText = ReachuConfiguration.shared.uiConfiguration.discountBadgeText {
                            Text(badgeText)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(hex: "E93CAC"))
                                .rotationEffect(.degrees(-10))
                                .offset(x: 8, y: -8)
                                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                    }
                    
                    // Información del producto (API > WebSocket fallback)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(productViewModel.product?.title ?? productEvent.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(2)
                        
                        let description = productViewModel.product?.description ?? productEvent.description
                        if !description.isEmpty {
                            Text(description)
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.7))
                                .lineLimit(2)
                        }
                        
                        // Precio (API > WebSocket fallback)
                        if let apiProduct = productViewModel.product {
                            Text("\(apiProduct.price.currencyCode) \(String(format: "%.2f", apiProduct.price.amount))")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(TV2Theme.Colors.primary)
                        } else {
                            Text("\(productEvent.currency) \(productEvent.price)")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(TV2Theme.Colors.primary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 12)
                
                // Botón para ver detalles
                Button {
                    if let apiProduct = productViewModel.product {
                        // Convertir ProductDto a Product y mostrar detail
                        selectedProduct = convertDtoToProduct(apiProduct)
                        showProductDetail = true
                    } else {
                        print("⚠️ Producto aún no disponible desde API")
                    }
                } label: {
                    Text("Legg til")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(productViewModel.product != nil ? TV2Theme.Colors.primary : Color.gray)
                        )
                }
                .disabled(productViewModel.product == nil)
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
            .padding(.vertical, 8)
        }
        .frame(width: 280)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.4))
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                )
                .shadow(color: Color.black.opacity(0.6), radius: 20, x: 0, y: -8)
        )
        .task {
            // Fetch del producto usando productId (campo correcto del WebSocket: "productId":"408841")
            await productViewModel.fetchProduct(productId: productEvent.productId)
        }
    }
    
    private func simpleContestCard(_ contest: ContestEventData) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 28))
                .foregroundColor(TV2Theme.Colors.primary)
                .frame(width: 50, height: 50)
                .background(Circle().fill(TV2Theme.Colors.primary.opacity(0.2)))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(contest.name)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text("Premio: \(contest.prize)")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer(minLength: 0)
            
            Button("✕") {
                webSocketManager.currentContest = nil
            }
            .foregroundColor(.white.opacity(0.6))
        }
        .frame(width: 380)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.4))
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                )
                .shadow(color: Color.black.opacity(0.4), radius: 12, x: 0, y: 4)
        )
    }
    
    private var simpleChatPanel: some View {
        VStack(spacing: 0) {
            // Drag indicator + Header (estilo EXACTO de TV2ChatOverlay)
            VStack(spacing: 4) {
                // Drag indicator
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 32, height: 4)
                    .padding(.top, 6)
                
                // Header
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        isChatExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 8) {
                        // Sponsor badge (top left)
                        HStack(spacing: 4) {
                            Text("Sponset av")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                            
                            AsyncImage(url: URL(string: "http://event-streamer-angelo100.replit.app/objects/uploads/16475fd2-da1f-4e9f-8eb4-362067b27858")) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(maxWidth: 70, maxHeight: 24)
                                case .empty:
                                    ProgressView()
                                        .scaleEffect(0.5)
                                        .frame(width: 70, height: 24)
                                case .failure:
                                    EmptyView()
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.black.opacity(0.3))
                        )
                        
                        Spacer(minLength: 0)
                        
                        // Live Chat indicator
                        HStack(spacing: 4) {
                            Text("LIVE CHAT")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                            
                            // Expand/Collapse indicator
                            Image(systemName: isChatExpanded ? "chevron.down" : "chevron.up")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                    }
                    .frame(width: 360)
                    .padding(.horizontal, 14)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.bottom, 8)
            }
            
            // Mensajes (cuando está expandido)
            if isChatExpanded {
                Divider()
                    .background(Color.white.opacity(0.2))
                
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(chatManager.messages.suffix(20)) { message in
                                HStack(alignment: .top, spacing: 8) {
                                    // Avatar (estilo EXACTO de TV2ChatOverlay)
                                    Circle()
                                        .fill(message.usernameColor.opacity(0.3))
                                        .frame(width: 28, height: 28)
                                        .overlay(
                                            Text(String(message.username.prefix(1)))
                                                .font(.system(size: 13, weight: .semibold))
                                                .foregroundColor(message.usernameColor)
                                        )
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        // Username and time
                                        HStack(spacing: 4) {
                                            Text(message.username)
                                                .font(.system(size: 13, weight: .bold))
                                                .foregroundColor(message.usernameColor)
                                            
                                            Text(timeAgo(from: message.timestamp))
                                                .font(.system(size: 10))
                                                .foregroundColor(.white.opacity(0.4))
                                        }
                                        
                                        // Message
                                        Text(message.text)
                                            .font(.system(size: 14))
                                            .foregroundColor(.white.opacity(0.95))
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    
                                    Spacer(minLength: 0)
                                }
                                .padding(.vertical, 4)
                                .frame(width: 350)
                                .id(message.id)
                            }
                        }
                        .padding(14)
                    }
                    .frame(width: 380, height: 160)
                    .onChange(of: chatManager.messages.count) { _ in
                        if let last = chatManager.messages.last {
                            withAnimation {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                Divider()
                    .background(Color.white.opacity(0.2))
                
                // Input bar (estilo EXACTO de TV2ChatOverlay)
                HStack(spacing: 12) {
                    TextField("Send a message...", text: $chatMessage)
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color.white.opacity(0.15))
                        )
                    
                    Button {
                        sendChatMessage()
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(chatMessage.isEmpty ? .white.opacity(0.3) : TV2Theme.Colors.primary)
                            .padding(10)
                            .background(
                                Circle()
                                    .fill(chatMessage.isEmpty ? Color.white.opacity(0.1) : TV2Theme.Colors.primary.opacity(0.2))
                            )
                    }
                    .disabled(chatMessage.isEmpty)
                }
                .frame(width: 360)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .padding(.bottom, 8)
                .background(Color(hex: "120019"))
            }
        }
        .frame(width: 400)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.4))
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                )
                .shadow(color: Color.black.opacity(0.6), radius: 20, x: 0, y: -8)
        )
        .animation(.spring(response: 0.3), value: isChatExpanded)
    }
    
    private func sendChatMessage() {
        guard !chatMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let message = ChatMessage(
            username: "Angelo",
            text: chatMessage,
            usernameColor: TV2Theme.Colors.secondary,
            likes: 0,
            timestamp: Date()
        )
        
        chatManager.addMessage(message)
        chatMessage = ""
    }
    
    private func timeAgo(from date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        if seconds < 60 { return "\(seconds)s" }
        let minutes = seconds / 60
        if minutes < 60 { return "\(minutes)m" }
        let hours = minutes / 60
        return "\(hours)h"
    }
    
    // MARK: - Conversion Helpers (from TV2VideoPlayer)
    
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
            Option(id: $0.id, name: $0.name, order: $0.order, values: $0.values) 
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
}

#Preview {
    CastingActiveView(match: Match.barcelonaPSG)
        .environmentObject(CartManager())
}


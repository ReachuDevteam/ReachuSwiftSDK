//
//  ViaplayVideoPlayerWithEntertainment.swift
//  Viaplay
//
//  Enhanced video player with entertainment components integration
//  This is an example of how to integrate EntertainmentOverlay with the existing video player
//

import SwiftUI
import AVKit
import AVFoundation
import Combine
import ReachuCore
import ReachuUI

/// Enhanced Viaplay Video Player with Entertainment Components
/// This demonstrates how to add interactive entertainment features to the existing player
struct ViaplayVideoPlayerWithEntertainment: View {
    let match: Match
    let onDismiss: () -> Void
    
    @StateObject private var playerViewModel = VideoPlayerViewModel()
    @StateObject private var webSocketManager = WebSocketManager()
    @StateObject private var entertainmentManager: EntertainmentManager
    @EnvironmentObject private var cartManager: CartManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    @State private var isChatExpanded = false
    @State private var showPoll = false
    @State private var showProduct = false
    @State private var showContest = false
    @State private var showCheckout = false
    @State private var isLoadingVideo = true
    
    // Initialize with user ID
    init(match: Match, onDismiss: @escaping () -> Void) {
        self.match = match
        self.onDismiss = onDismiss
        
        // Initialize entertainment manager with user ID
        // In production, get this from authentication
        _entertainmentManager = StateObject(wrappedValue: EntertainmentManager(userId: "viaplay-user-123"))
    }
    
    // SDK Client para fetch de productos
    private var sdkClient: SdkClient {
        let config = ReachuConfiguration.shared
        let baseURL = URL(string: config.environment.graphQLURL)!
        return SdkClient(baseUrl: baseURL, apiKey: config.apiKey)
    }
    
    // Detect landscape orientation
    private var isLandscape: Bool {
        verticalSizeClass == .compact
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Video Player Layer (existing implementation)
                VStack(spacing: 0) {
                    ZStack {
                        if let player = playerViewModel.player {
                            CustomVideoPlayerView(player: player)
                                .aspectRatio(16/9, contentMode: .fit)
                                .onAppear {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        isLoadingVideo = false
                                    }
                                }
                        }
                        
                        if isLoadingVideo {
                            ZStack {
                                Color.black.opacity(0.9)
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 0.96, green: 0.08, blue: 0.42)))
                                    .scaleEffect(2.0)
                            }
                            .transition(.opacity)
                        }
                    }
                    .frame(height: isChatExpanded ? geometry.size.height * 0.6 : geometry.size.height)
                    .background(Color.black)
                    
                    if isChatExpanded {
                        Spacer()
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    playerViewModel.toggleControlsVisibility()
                }
                .ignoresSafeArea()
            
                // Overlay Controls (existing implementation)
                if playerViewModel.showControls {
                    VStack {
                        topBar
                        Spacer()
                        bottomControls
                    }
                    .transition(.opacity)
                    .allowsHitTesting(true)
                }

                // Chat Overlay (existing)
                ZStack {
                    ViaplayChatOverlay(
                        showControls: $playerViewModel.showControls,
                        onExpandedChange: { expanded in
                            isChatExpanded = expanded
                        }
                    )
                }
                
                // Live Badge (existing)
                VStack {
                    HStack {
                        Spacer()
                        liveBadge
                            .padding(.top, isLandscape ? 8 : 24)
                            .padding(.trailing, 16)
                    }
                    Spacer()
                }
                
                // 🎯 NEW: Entertainment Overlay
                // This is the new interactive entertainment layer
                EntertainmentOverlay(manager: entertainmentManager)
                    .zIndex(100) // Above chat but below checkout
                
                // Poll Overlay (existing - could be replaced by entertainment components)
                if let poll = webSocketManager.currentPoll, showPoll {
                    ViaplayPollOverlay(
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
                }
                
                // Product Overlay (existing)
                if let productEvent = webSocketManager.currentProduct, showProduct {
                    ViaplayProductOverlay(
                        productEvent: productEvent,
                        isChatExpanded: isChatExpanded,
                        sdk: sdkClient,
                        currency: cartManager.currency,
                        country: cartManager.country,
                        onAddToCart: { productDto in
                            if let apiProduct = productDto {
                                print("🛍️ [Product] Agregando producto: \(apiProduct.title)")
                                let product = convertDtoToProduct(apiProduct)
                                Task {
                                    await cartManager.addProduct(product, quantity: 1)
                                }
                            }
                        },
                        onDismiss: {
                            withAnimation {
                                showProduct = false
                            }
                        }
                    )
                }
                
                // Contest Overlay (existing)
                if let contest = webSocketManager.currentContest, showContest {
                    ViaplayContestOverlay(
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
                }
                
                // Floating cart indicator (existing)
                RFloatingCartIndicator(
                    customPadding: EdgeInsets(
                        top: 0,
                        leading: 0,
                        bottom: 100,
                        trailing: 16
                    ),
                    onTap: {
                        showCheckout = true
                    }
                )
                .zIndex(1000)
            }
        }
        .sheet(isPresented: $showCheckout) {
            RCheckoutOverlay()
                .environmentObject(cartManager)
        }
        .ignoresSafeArea()
        .onAppear {
            playerViewModel.setupPlayer()
            setOrientation(.allButUpsideDown)
            
            // Connect WebSocket
            webSocketManager.connect()
            
            // 🎯 NEW: Load entertainment components
            Task {
                await entertainmentManager.loadComponents()
            }
        }
        .onDisappear {
            playerViewModel.cleanup()
            setOrientation(.portrait)
            webSocketManager.disconnect()
        }
        .onReceive(webSocketManager.$currentPoll) { newPoll in
            guard let poll = newPoll else { return }
            print("🎯 [VideoPlayer] Poll recibido: \(poll.question)")
            withAnimation {
                showPoll = true
            }
            
            if let duration = newPoll?.duration {
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(duration)) {
                    withAnimation {
                        showPoll = false
                    }
                }
            }
        }
        .onReceive(webSocketManager.$currentProduct) { newProduct in
            guard let product = newProduct else { return }
            print("🎯 [VideoPlayer] Producto recibido: \(product.name)")
            withAnimation {
                showProduct = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
                withAnimation {
                    showProduct = false
                }
            }
        }
        .onReceive(webSocketManager.$currentContest) { newContest in
            guard let contest = newContest else { return }
            print("🎁 [VideoPlayer] Concurso recibido: \(contest.name)")
            withAnimation {
                showContest = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
                withAnimation {
                    showContest = false
                }
            }
        }
    }
    
    // MARK: - Top Bar (same as original)
    private var topBar: some View {
        HStack {
            Button(action: { onDismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.black.opacity(0.3))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            HStack(spacing: 16) {
                Button(action: {}) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                }
                
                Button(action: {}) {
                    Image(systemName: "airplayvideo")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
    
    // MARK: - Bottom Controls (same as original)
    private var bottomControls: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                HStack {
                    Text(playerViewModel.currentTimeText)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(playerViewModel.durationText)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                }
                
                GeometryReader { progressGeometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.white.opacity(0.3))
                            .frame(height: 4)
                        
                        Rectangle()
                            .fill(Color(red: 0.96, green: 0.08, blue: 0.42))
                            .frame(width: progressGeometry.size.width * playerViewModel.progress, height: 4)
                    }
                }
                .frame(height: 4)
            }
            .padding(.horizontal, 16)
            
            HStack(spacing: 24) {
                Button(action: { playerViewModel.toggleMute() }) {
                    Image(systemName: playerViewModel.isMuted ? "speaker.slash.fill" : "speaker.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                }
                
                Button(action: { playerViewModel.seekBackward() }) {
                    Image(systemName: "gobackward.10")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                }
                
                Button(action: { playerViewModel.togglePlayPause() }) {
                    Image(systemName: playerViewModel.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(.white)
                }
                
                Button(action: { playerViewModel.seekForward() }) {
                    Image(systemName: "goforward.10")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                }
                
                Button(action: { playerViewModel.togglePlaybackSpeed() }) {
                    Text("\(Int(playerViewModel.playbackSpeed))x")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 100)
    }
    
    // MARK: - Live Badge (same as original)
    private var liveBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Color(red: 0.96, green: 0.08, blue: 0.42))
                .frame(width: 8, height: 8)
                .scaleEffect(1.2)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: playerViewModel.isPlaying)
            
            Text("LIVE")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.6))
        .cornerRadius(16)
    }
    
    // MARK: - Helpers (same as original)
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

// MARK: - Preview
#Preview {
    ViaplayVideoPlayerWithEntertainment(match: Match.barcelonaPSG) {
        print("Dismissed")
    }
    .environmentObject(CartManager())
}



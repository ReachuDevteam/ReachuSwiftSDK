//
//  ViaplayVideoPlayer.swift
//  Viaplay
//
//  Created by Angelo Sepulveda on 27/10/2025.
//

import SwiftUI
import AVKit
import AVFoundation
import Combine
import ReachuCore
import ReachuUI

/// Viaplay Video Player with casting support
/// Simulates a live streaming experience with AirPlay/Chromecast capability
struct ViaplayVideoPlayer: View {
    let match: Match
    let onDismiss: () -> Void
    
    @StateObject private var playerViewModel = VideoPlayerViewModel()
    @StateObject private var webSocketManager = WebSocketManager()
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
                // Video Player Layer
                VStack(spacing: 0) {
                    ZStack {
                        if let player = playerViewModel.player {
                            CustomVideoPlayerView(player: player)
                                .aspectRatio(16/9, contentMode: .fit)
                                .onAppear {
                                    // Hide loader when video appears
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        isLoadingVideo = false
                                    }
                                }
                        }
                        
                        // Loading overlay
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
            
            // Overlay Controls
            if playerViewModel.showControls {
                VStack {
                    // Top Bar
                    topBar
                    
                    Spacer()
                    
                    // Bottom Controls
                    bottomControls
                }
                .transition(.opacity)
                .allowsHitTesting(true)
            }

            ZStack {
                ViaplayChatOverlay(
                    showControls: $playerViewModel.showControls,
                    onExpandedChange: { expanded in
                        isChatExpanded = expanded
                    }
                )
            }
            
            // Live Badge
            VStack {
                HStack {
                    Spacer()
                    
                    liveBadge
                        .padding(.top, isLandscape ? 8 : 24)
                        .padding(.trailing, 16)
                }
                
                Spacer()
            }
            
            // Poll Overlay (alineado con TV2: respeta estado del chat y onVote)
            if let poll = webSocketManager.currentPoll, showPoll {
                ViaplayPollOverlay(
                    poll: poll,
                    isChatExpanded: isChatExpanded,
                    onVote: { option in
                        print("📊 [Poll] Votado: \(option)")
                        // Aquí se enviará el voto al servidor después
                    },
                    onDismiss: {
                        withAnimation {
                            showPoll = false
                        }
                    }
                )
            }
            
            // Product Overlay (sobre el chat y poll)
            if let productEvent = webSocketManager.currentProduct, showProduct {
                ViaplayProductOverlay(
                    productEvent: productEvent,
                    isChatExpanded: isChatExpanded,
                    sdk: sdkClient,
                    currency: cartManager.currency,
                    country: cartManager.country,
                    onAddToCart: { productDto in
                        if let apiProduct = productDto {
                            print("🛍️ [Product] Agregando producto de la API al carrito: \(apiProduct.title)")
                            // Convertir ProductDto a Product para el CartManager
                            let product = convertDtoToProduct(apiProduct)
                            Task {
                                await cartManager.addProduct(product, quantity: 1)
                                print("✅ [Product] Producto agregado al carrito")
                            }
                        } else {
                            print("⚠️ [Product] Producto de la API aún no disponible, usando fallback: \(productEvent.name)")
                            // El producto de la API aún no ha cargado, no hacer nada o usar fallback
                        }
                    },
                    onDismiss: {
                        withAnimation {
                            showProduct = false
                        }
                    }
                )
            }
            
            // Contest Overlay
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
            
            // Floating cart indicator - SIEMPRE visible en el video player
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
            .zIndex(1000) // Por encima de todo en el video player
        }
        }
        .sheet(isPresented: $showCheckout) {
            RCheckoutOverlay()
                .environmentObject(cartManager)
        }
        .ignoresSafeArea() // Full screen
        .onAppear {
            playerViewModel.setupPlayer()
            // Enable all orientations for video playback
            setOrientation(.allButUpsideDown)
            
            // Conectar WebSocket
            webSocketManager.connect()
        }
        .onDisappear {
            playerViewModel.cleanup()
            // Return to portrait when dismissed
            setOrientation(.portrait)
            
            // Desconectar WebSocket
            webSocketManager.disconnect()
        }
        .onReceive(webSocketManager.$currentPoll) { newPoll in
            guard let poll = newPoll else { return }
            print("🎯 [VideoPlayer] Poll recibido: \(poll.question)")
            if true {
                print("🎯 [VideoPlayer] Mostrando poll")
                withAnimation {
                    showPoll = true
                }
                
                // Auto-ocultar después de la duración del poll
                if let duration = newPoll?.duration {
                    print("🎯 [VideoPlayer] Auto-ocultar en \(duration)s")
                    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(duration)) {
                        withAnimation {
                            print("🎯 [VideoPlayer] Ocultando poll")
                            showPoll = false
                        }
                    }
                }
            }
        }
        .onReceive(webSocketManager.$currentProduct) { newProduct in
            guard let product = newProduct else { return }
            print("🎯 [VideoPlayer] Producto recibido: \(product.name)")
            if true {
                print("🎯 [VideoPlayer] Mostrando producto")
                withAnimation {
                    showProduct = true
                }
                
                // Auto-ocultar después de 30 segundos
                DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
                    withAnimation {
                        print("🎯 [VideoPlayer] Ocultando producto")
                        showProduct = false
                    }
                }
            }
        }
        .onReceive(webSocketManager.$currentContest) { newContest in
            guard let contest = newContest else { return }
            print("🎁 [VideoPlayer] Concurso recibido: \(contest.name)")
            if true {
                print("🎁 [VideoPlayer] Mostrando concurso")
                withAnimation {
                    showContest = true
                }
                
                // Auto-ocultar después de 15 segundos
                DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
                    withAnimation {
                        print("🎁 [VideoPlayer] Ocultando concurso")
                        showContest = false
                    }
                }
            }
        }
    }
    
    // MARK: - Top Bar
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
    
    // MARK: - Bottom Controls
    private var bottomControls: some View {
        VStack(spacing: 16) {
            // Progress Bar
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
            
            // Control Buttons
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
    
    // MARK: - Live Badge
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
    
    // MARK: - Helpers
    
    /// Convierte PriceDto a Price
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
    
    /// Convierte ProductImageDto a ProductImage
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
    
    /// Convierte VariantDto a Variant
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
    
    /// Convierte ProductDto a Product para el CartManager
    private func convertDtoToProduct(_ dto: ProductDto) -> Product {
        let price = convertPrice(dto.price)
        let variants = convertVariants(dto.variants)
        let images = convertImages(dto.images)
        
        let options = dto.options.map { 
            Option(
                id: $0.id, 
                name: $0.name, 
                order: $0.order, 
                values: $0.values  // Ya es String, no array
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

// MARK: - Custom Video Player View
struct CustomVideoPlayerView: UIViewControllerRepresentable {
    let player: AVPlayer
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = false
        controller.videoGravity = .resizeAspectFill
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        // No updates needed
    }
}

// MARK: - View Model
@MainActor
class VideoPlayerViewModel: ObservableObject {
    @Published var player: AVPlayer?
    @Published var isPlaying = false
    @Published var showControls = true
    @Published var progress: Double = 0
    @Published var currentTimeText = "00:00"
    @Published var durationText = "2:10:48"
    @Published var isMuted = true
    @Published var playbackSpeed: Float = 1.0
    
    private var timeObserver: Any?
    private var controlsTimer: Timer?
    
    func setupPlayer() {
        // Priority 1: Try local video file (if included in bundle)
        if let localVideoPath = Bundle.main.path(forResource: "match", ofType: "mp4") {
            let url = URL(fileURLWithPath: localVideoPath)
            print("🎥 [VideoPlayer] Using local video: match.mp4")
            initializePlayer(with: url)
            return
        }
        
        // Priority 2: Load from Firebase Storage (remote video)
        // This video is hosted on Firebase Storage and works perfectly with AVPlayer
        print("🌐 [VideoPlayer] Loading video from Firebase Storage...")
        
        let firebaseVideoURL = "https://firebasestorage.googleapis.com/v0/b/tipio-1ec97.appspot.com/o/bar.v.psg.1.ucl.01.10.2025.fullmatchsports.com.1080p.mp4?alt=media&token=593ce8a1-0462-4c37-98c3-e399f25e3853"
        
        guard let videoURL = URL(string: firebaseVideoURL) else {
            print("❌ [VideoPlayer] Invalid Firebase URL")
            return
        }
        
        print("✅ [VideoPlayer] Firebase video URL ready")
        initializePlayer(with: videoURL)
    }
    
    private func initializePlayer(with url: URL) {
        print("🎬 [VideoPlayer] Initializing player with URL: \(url)")
        
        let playerItem = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: playerItem)
        
        // Configure audio session for background playback
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("❌ [VideoPlayer] Failed to configure audio session: \(error)")
        }
        
        self.player = player
        
        // Start playing immediately
        player.play()
        isPlaying = true
        
        // Setup time observer
        setupTimeObserver()
        
        // Auto-hide controls after 3 seconds
        startControlsTimer()
        
        print("✅ [VideoPlayer] Player initialized and playing")
    }
    
    private func setupTimeObserver() {
        guard let player = player else { return }
        
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            
            if let duration = player.currentItem?.duration, duration.seconds > 0 {
                let progress = time.seconds / duration.seconds
                self.progress = min(max(progress, 0), 1)
                
                // Update time text
                self.currentTimeText = self.formatTime(time.seconds)
                self.durationText = self.formatTime(duration.seconds)
            }
        }
    }
    
    private func formatTime(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
    
    func togglePlayPause() {
        guard let player = player else { return }
        
        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
        
        startControlsTimer()
    }
    
    func toggleMute() {
        guard let player = player else { return }
        
        isMuted.toggle()
        player.isMuted = isMuted
    }
    
    func seekBackward() {
        guard let player = player else { return }
        let currentTime = player.currentTime()
        let newTime = CMTime(seconds: max(0, currentTime.seconds - 10), preferredTimescale: currentTime.timescale)
        player.seek(to: newTime)
    }
    
    func seekForward() {
        guard let player = player else { return }
        let currentTime = player.currentTime()
        let newTime = CMTime(seconds: currentTime.seconds + 10, preferredTimescale: currentTime.timescale)
        player.seek(to: newTime)
    }
    
    func togglePlaybackSpeed() {
        guard let player = player else { return }
        
        switch playbackSpeed {
        case 1.0:
            playbackSpeed = 1.25
        case 1.25:
            playbackSpeed = 1.5
        case 1.5:
            playbackSpeed = 2.0
        default:
            playbackSpeed = 1.0
        }
        
        player.rate = playbackSpeed
    }
    
    func toggleControlsVisibility() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showControls.toggle()
        }
        
        if showControls {
            startControlsTimer()
        }
    }
    
    private func startControlsTimer() {
        controlsTimer?.invalidate()
        controlsTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 0.3)) {
                    self?.showControls = false
                }
            }
        }
    }
    
    func cleanup() {
        timeObserver = nil
        controlsTimer?.invalidate()
        controlsTimer = nil
        player?.pause()
        player = nil
    }
}

// MARK: - Orientation Helper
func setOrientation(_ orientation: UIInterfaceOrientationMask) {
    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
        windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: orientation))
    }
}

// MARK: - Overlay Views (legacy - no longer used)
// ContestOverlayView has been replaced by ViaplayContestOverlay
struct ContestOverlayView: View {
    let contest: ContestEventData
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            if let imageUrl = contest.campaignLogo, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                }
                .frame(height: 120)
                .cornerRadius(8)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 120)
                    .cornerRadius(8)
            }
            
            VStack(spacing: 8) {
                Text(contest.name)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("Premie: \(contest.prize)")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                
                Text("Frist: \(contest.deadline)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(red: 0.96, green: 0.08, blue: 0.42))
            }
            
            HStack(spacing: 12) {
                Button(action: {}) {
                    Text("Delta")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color(red: 0.96, green: 0.08, blue: 0.42))
                        .cornerRadius(8)
                }
                
                Button(action: onDismiss) {
                    Text("Lukk")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(8)
                }
            }
        }
        .padding(20)
        .background(Color.black.opacity(0.8))
        .cornerRadius(16)
    }
}

struct ViaplayVideoPlayer_Previews: PreviewProvider {
    static var previews: some View {
        ViaplayVideoPlayer(match: Match.barcelonaPSG) {
            print("Dismissed")
        }
        .environmentObject(CartManager())
    }
}
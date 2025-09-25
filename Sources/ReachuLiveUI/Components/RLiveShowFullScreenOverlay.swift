import SwiftUI
import AVKit
import AVFoundation
import CoreMedia
import WebKit
import ReachuCore
import ReachuLiveShow
import ReachuDesignSystem
import ReachuUI

#if os(iOS)
import UIKit
#endif

/// Full-screen LiveShow overlay with video player, chat, shopping, and controls
public struct RLiveShowFullScreenOverlay: View {
    
    // MARK: - Properties
    @ObservedObject private var liveShowManager = LiveShowManager.shared
    @EnvironmentObject var cartManager: CartManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var player: AVPlayer?
    @State private var showControls = true
    @State private var controlsTimer: Timer?
    // showShopping removed - now handled by RLiveBottomTabs
    @State private var isLoading = true
    @State private var isPlaying = false
    @State private var isMuted = true
    @State private var showPlayPauseIndicator = false
    @State private var selectedProductForDetail: Product?
    
    // Colors based on theme
    private var adaptiveColors: AdaptiveColors {
        ReachuColors.adaptive(for: colorScheme)
    }
    
    // Current stream
    private var currentStream: LiveStream? {
        liveShowManager.currentStream
    }
    
    public init() {}
    
    // MARK: - Body
    public var body: some View {
        ZStack {
            // Video Player Background
            Color.black
                .ignoresSafeArea()
            
            if let stream = currentStream {
                videoPlayerSection(stream: stream)
                    .ignoresSafeArea()
            } else {
                // No stream placeholder
                noStreamPlaceholder
            }
            
            // Overlay UI
            if let stream = currentStream {
                overlayUI(stream: stream)
            }
            
            // Floating LIVE badge (positioned above X button)
            VStack {
                HStack {
                    Spacer()
                    
                    VStack {
                        // Animated LIVE badge positioned above controls
                        AnimatedLiveBadge()
                            .padding(.bottom, ReachuSpacing.sm)
                        
                        Spacer()
                    }
                    .padding(.top, ReachuSpacing.lg)
                    .padding(.trailing, ReachuSpacing.md) // Align with control buttons
                }
                
                Spacer()
            }
            
            // Bottom content (Chat above, Products at very bottom)
            VStack {
                Spacer()
                
                // Chat component
                RLiveChatComponent()
                    .environmentObject(cartManager)
                
                // Featured products slider (at bottom edge)
                if let stream = currentStream, !stream.featuredProducts.isEmpty {
                    featuredProductsSlider(products: stream.featuredProducts)
                        .onAppear {
                            print("🛍️ [LiveShow] Showing \(stream.featuredProducts.count) products in slider")
                            for product in stream.featuredProducts {
                                print("   - \(product.title): \(product.price.formattedPrice)")
                            }
                        }
                } else {
                    // Debug: Show why no products
                    if let stream = currentStream {
                        Text("No products available (\(stream.featuredProducts.count) products)")
                            .foregroundColor(.red)
                            .padding()
                    }
                }
            }
            
            // Center indicators
            VStack {
                Spacer()
                
                // Play/Pause indicator (appears temporarily)
                if showPlayPauseIndicator {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.white)
                        .background(
                            Circle()
                                .fill(Color.black.opacity(0.6))
                                .frame(width: 100, height: 100)
                        )
                        .transition(.scale.combined(with: .opacity))
                }
                
                Spacer()
            }
            
            // Loading indicator
            if isLoading {
                loadingIndicator
            }
            
            // Flying likes component
            RLiveLikesComponent()
        }
        .onAppear {
            print("🎬 [LiveShow] Overlay appeared - starting setup")
            isLoading = true // Start with loading immediately
            showControls = true
            
            // Delay player setup slightly to show loading first
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.setupPlayer()
                if let stream = self.currentStream {
                    self.configurePlayer(with: stream)
                }
            }
        }
        .onDisappear {
            cleanup()
        }
        .sheet(item: $selectedProductForDetail) { product in
            RProductDetailOverlay(
                product: product,
                onAddToCart: { product in
                    // Handle add to cart from detail overlay
                    print("🛒 [LiveShow] Adding to cart from detail: \(product.title)")
                    Task {
                        await cartManager.addProduct(product, quantity: 1)
                        print("✅ [LiveShow] Successfully added to cart: \(product.title)")
                    }
                    
                    // Close modal after adding to cart
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        selectedProductForDetail = nil
                    }
                }
            )
            .environmentObject(cartManager)
        }
        .onTapGesture(count: 2) {
            // Double tap to play/pause
            togglePlayPause()
        }
        // Remove single tap to hide controls - keep them always visible
        // .onTapGesture { toggleControls() }
        .gesture(
            DragGesture(minimumDistance: 100)
                .onEnded { value in
                    handleSwipeGesture(value)
                }
        )
    }
    
    // MARK: - Video Player Section
    
    @ViewBuilder
    private func videoPlayerSection(stream: LiveStream) -> some View {
        if let stream = currentStream {
        // Use WebView for Vimeo URLs, AVPlayer for direct video URLs
        if stream.videoUrl.contains("player.vimeo.com") {
            VimeoWebPlayer(videoUrl: stream.videoUrl)
                .onReceive(NotificationCenter.default.publisher(for: .vimeoPlayerLoaded)) { _ in
                    // Hide loading when video actually loads
                    isLoading = false
                    print("✅ [LiveShow] Vimeo player loaded - hiding loading indicator")
                }
                .onAppear {
                    // Fallback: hide loading after 5 seconds if no signal received
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                        if isLoading {
                            isLoading = false
                            print("⏰ [LiveShow] Loading timeout - hiding indicator")
                        }
                    }
                }
        } else if let player = player {
                CustomVideoPlayer(player: player)
            } else {
                // Loading placeholder
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
            }
        } else {
            // Thumbnail placeholder
            AsyncImage(url: URL(string: stream.thumbnailUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
            }
        }
    }
    
    // MARK: - Overlay UI
    
    @ViewBuilder
    private func overlayUI(stream: LiveStream) -> some View {
        VStack(spacing: 0) {
            // Top overlay (controls, close button, stream info)
            topOverlay(stream: stream)
            
            Spacer()
            
            // Bottom overlay removed - now using product banner and chat separately
        }
        // Always show controls - no fade in/out
        .opacity(1)
    }
    
    // MARK: - Top Overlay
    
    @ViewBuilder
    private func topOverlay(stream: LiveStream) -> some View {
        VStack(spacing: 0) {
            // Top gradient
            LinearGradient(
                colors: [Color.black.opacity(0.7), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 120)
            .overlay(
                topControlsContent(stream: stream),
                alignment: .top
            )
        }
    }
    
    @ViewBuilder
    private func topControlsContent(stream: LiveStream) -> some View {
        HStack(alignment: .top, spacing: ReachuSpacing.md) {
            // Left side - Stream info
            VStack(alignment: .leading, spacing: ReachuSpacing.sm) {
                // Stream title and streamer info
                VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
                    Text(stream.title)
                        .font(ReachuTypography.headline)
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    // Remove streamer info to keep it cleaner
                    // HStack with streamer details removed
                }
            }
            
            Spacer()
            
            // Viewer count (LIVE badge now floating)
            if liveShowManager.currentViewerCount > 0 {
                HStack(spacing: ReachuSpacing.xs) {
                    Image(systemName: "eye.fill")
                        .font(.caption2)
                    Text("\(liveShowManager.currentViewerCount)")
                        .font(.caption)
                }
                .foregroundColor(.white)
                .padding(.horizontal, ReachuSpacing.sm)
                .padding(.vertical, ReachuSpacing.xs)
                .background(Color.black.opacity(0.6))
                .cornerRadius(ReachuBorderRadius.small)
            }
            
            // Right controls (clean style, moved towards center)
            VStack(spacing: ReachuSpacing.md) {
                // Close button
                Button(action: {
                    liveShowManager.hideLiveStream()
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(Color.black.opacity(0.4))
                                .background(
                                    Circle()
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                }
                
                // Play/Pause button
                Button(action: togglePlayPause) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(Color.black.opacity(0.4))
                                .background(
                                    Circle()
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                }
                
                // Mute/Unmute button
                Button(action: toggleMute) {
                    Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.2.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(Color.black.opacity(0.4))
                                .background(
                                    Circle()
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                }
                
                // Minimize to mini player
                Button(action: {
                    liveShowManager.showMiniPlayer()
                    dismiss()
                }) {
                    Image(systemName: "pip.enter")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(Color.black.opacity(0.4))
                                .background(
                                    Circle()
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                }
                
                // Share button
                Button(action: {
                    shareStream(stream)
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(Color.black.opacity(0.4))
                                .background(
                                    Circle()
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                }
                
                // Cart button with badge (at the end)
                Button(action: {
                    cartManager.isCheckoutPresented = true
                }) {
                    ZStack {
                        Image(systemName: "bag.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(Color.black.opacity(0.4))
                                    .background(
                                        Circle()
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                            )
                        
                        // Cart badge
                        if !cartManager.items.isEmpty {
                            Text("\(cartManager.items.count)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 18, height: 18)
                                .background(Circle().fill(.red))
                                .offset(x: 15, y: -15)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, ReachuSpacing.md) // Less padding to move controls towards center
        .padding(.top, ReachuSpacing.lg)
    }
    
    // MARK: - Bottom Overlay
    
    @ViewBuilder
    private func bottomOverlay(stream: LiveStream) -> some View {
        VStack(spacing: 0) {
            // Bottom gradient
            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 300)
            .overlay(
                bottomControlsContent(stream: stream),
                alignment: .bottom
            )
        }
    }
    
    @ViewBuilder
    private func bottomControlsContent(stream: LiveStream) -> some View {
        VStack(spacing: ReachuSpacing.md) {
            // Connection status only (tabs handle chat/shopping)
            HStack {
                Spacer()
                
                // Connection status
                if liveShowManager.isConnectedToTipio {
                    HStack(spacing: ReachuSpacing.xs) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                        Text("Tipio Connected")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.horizontal, ReachuSpacing.sm)
                    .padding(.vertical, ReachuSpacing.xs)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(ReachuBorderRadius.small)
                }
            }
        }
        .padding(.horizontal, ReachuSpacing.lg)
        .padding(.bottom, ReachuSpacing.xl)
    }
    
    // MARK: - Featured Products Slider
    
    @ViewBuilder
    private func featuredProductsSlider(products: [LiveProduct]) -> some View {
        GeometryReader { geometry in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: ReachuSpacing.sm) {
                    ForEach(products) { liveProduct in
                        // Use the horizontal card we had before (was perfect)
                        liveProductHorizontalCard(product: liveProduct)
                            .frame(width: geometry.size.width - 32) // Full width minus small margins
                    }
                }
                .padding(.horizontal, ReachuSpacing.md) // Small margins on sides
            }
        }
        .frame(height: 80) // Compact height for bottom placement
        .background(Color.black.opacity(0.8)) // Background for products area
    }
    
    // MARK: - Live Product Horizontal Card (perfect version)
    
    @ViewBuilder
    private func liveProductHorizontalCard(product: LiveProduct) -> some View {
        HStack(spacing: ReachuSpacing.md) {
            // Product image (60x60 like before)
            AsyncImage(url: URL(string: product.imageUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
            }
            .frame(width: 60, height: 60)
            .cornerRadius(8)
            .clipped()
            
            // Product info (matching previous perfect layout)
            VStack(alignment: .leading, spacing: 4) {
                Text(product.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text("COSMED BEAUTY")
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
                    .lineLimit(1)
                
                // Price row (red price + strikethrough)
                HStack(spacing: ReachuSpacing.xs) {
                    Text(product.price.formattedPrice)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.red)
                    
                    if let originalPrice = product.originalPrice {
                        Text(originalPrice.formattedPrice)
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                            .strikethrough()
                    }
                }
            }
            
            Spacer()
            
            // Red dot indicator (exactly like before)
            Circle()
                .fill(Color.red)
                .frame(width: 8, height: 8)
        }
        .padding(.horizontal, ReachuSpacing.md)
        .padding(.vertical, ReachuSpacing.sm)
        .background(Color.black.opacity(0.85))
        .onTapGesture {
            // Open product detail overlay for variant selection
            print("🛍️ [LiveShow] Opening product detail for: \(product.title)")
            selectedProductForDetail = product.asProduct
        }
    }
    
    // MARK: - Placeholders
    
    @ViewBuilder
    private var noStreamPlaceholder: some View {
        VStack(spacing: ReachuSpacing.lg) {
            Image(systemName: "video.slash")
                .font(.system(size: 64))
                .foregroundColor(.gray)
            
            Text("No Live Stream Available")
                .font(ReachuTypography.title1)
                .foregroundColor(.white)
            
            Text("Please check back later or try connecting to Tipio.")
                .font(ReachuTypography.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            Button("Close") {
                dismiss()
            }
            .foregroundColor(adaptiveColors.primary)
        }
        .padding(ReachuSpacing.xl)
    }
    
    @ViewBuilder
    private var loadingIndicator: some View {
        VStack(spacing: ReachuSpacing.lg) {
            // Animated loading indicator
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 4)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(Color.white, lineWidth: 4)
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isLoading)
            }
            
            VStack(spacing: ReachuSpacing.sm) {
                Text("Loading Vimeo Stream...")
                    .font(ReachuTypography.headline)
                    .foregroundColor(.white)
                
                Text("Please wait while the video loads")
                    .font(ReachuTypography.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(ReachuSpacing.xl)
        .background(
            RoundedRectangle(cornerRadius: ReachuBorderRadius.large)
                .fill(Color.black.opacity(0.85))
                .shadow(radius: 20)
        )
        .frame(maxWidth: 280)
    }
    
    // MARK: - Helper Methods
    
    private func setupPlayer() {
        guard let stream = currentStream else { 
            print("❌ [LiveShow] No current stream for setup")
            return 
        }
        
        print("🎬 [LiveShow] Setting up player for stream: \(stream.title)")
        print("🎬 [LiveShow] Stream URL: \(stream.videoUrl)")
        
        // Check if it's a Vimeo player URL
        if stream.videoUrl.contains("player.vimeo.com") {
            print("🎬 [LiveShow] Detected Vimeo player URL - using WebView")
            // Keep loading = true until WebView finishes loading
            return // WebView will handle loading state
        }
        
        // For HLS and direct video URLs, use AVPlayer
        print("🎬 [LiveShow] Using AVPlayer for direct video URL")
        
        // Use working demo URLs for testing
        let workingUrls = [
            "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
            "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
            "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4"
        ]
        
        // Use stream URL or fallback
        let videoUrl: String
        if stream.videoUrl.contains("m3u8") {
            videoUrl = stream.videoUrl
            print("🎬 [LiveShow] Using HLS URL: \(videoUrl)")
        } else {
            videoUrl = workingUrls[0] // Use demo video as fallback
            print("🎬 [LiveShow] Using demo video URL: \(videoUrl)")
        }
        
        print("🔗 [LiveShow] Final video URL: \(videoUrl)")
        
        guard let url = URL(string: videoUrl) else {
            print("❌ [LiveShow] Failed to create URL from: \(videoUrl)")
            isLoading = false
            return
        }
        
        print("📱 [LiveShow] Creating AVPlayer with URL...")
        player = AVPlayer(url: url)
        
        guard let player = player else {
            print("❌ [LiveShow] Failed to create AVPlayer")
            isLoading = false
            return
        }
        
        print("⚙️ [LiveShow] Configuring player settings...")
        
        // Configure for better streaming experience
        player.automaticallyWaitsToMinimizeStalling = false
        player.isMuted = true // Start muted for better UX
        player.allowsExternalPlayback = false // Prevent fullscreen takeover
        
        // Monitor player status
        player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 1), queue: .main) { time in
            let currentTime = CMTimeGetSeconds(time)
            if Int(currentTime) % 5 == 0 { // Log every 5 seconds to avoid spam
                print("⏱️ [LiveShow] Video time: \(currentTime)s")
            }
        }
        
        // Monitor player item status
        if let currentItem = player.currentItem {
            print("📋 [LiveShow] Player item status: \(currentItem.status)")
            
            // Monitor status changes without KVO
            monitorPlayerStatus(currentItem)
        }
        
        print("▶️ [LiveShow] Starting playback...")
        
        // Auto-play
        player.play()
        isPlaying = true
        
        isLoading = false
        print("✅ [LiveShow] Player setup complete")
        
        // Check status after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if let item = self.player?.currentItem {
                print("🔍 [LiveShow] Status check after 3s:")
                print("   - Player item status: \(item.status)")
                print("   - Is playing: \(self.player?.rate != 0)")
                print("   - Error: \(item.error?.localizedDescription ?? "None")")
                
                if item.status == .failed {
                    print("❌ [LiveShow] Player failed, trying fallback URL...")
                    self.setupPlayerWithFallback()
                }
            }
        }
    }
    
    private func setupPlayerWithFallback() {
        print("🔄 [LiveShow] Setting up player with fallback URL...")
        
        let fallbackUrl = "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4"
        
        guard let url = URL(string: fallbackUrl) else {
            print("❌ [LiveShow] Failed to create fallback URL")
            return
        }
        
        player = AVPlayer(url: url)
        player?.automaticallyWaitsToMinimizeStalling = false
        player?.isMuted = true
        player?.allowsExternalPlayback = false
        player?.play()
        isPlaying = true
        
        print("✅ [LiveShow] Fallback player setup complete with: \(fallbackUrl)")
    }
    
    private func monitorPlayerStatus(_ item: AVPlayerItem) {
        // Check status periodically instead of using KVO
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            print("📊 [LiveShow] Player status: \(item.status.description)")
            
            if item.status == .readyToPlay {
                print("✅ [LiveShow] Player is ready to play")
                timer.invalidate()
            } else if item.status == .failed {
                print("❌ [LiveShow] Player failed: \(item.error?.localizedDescription ?? "Unknown error")")
                timer.invalidate()
                
                // Try fallback
                DispatchQueue.main.async {
                    self.setupPlayerWithFallback()
                }
            }
        }
    }
    
    private func configurePlayer(with stream: LiveStream) {
        // Configure player for live streaming
        if stream.isLive {
            player?.automaticallyWaitsToMinimizeStalling = false
        }
        
        // Set initial state
        player?.isMuted = isMuted
        isPlaying = player?.rate != 0
        
        // Monitor playback state
        player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.1, preferredTimescale: 600), queue: .main) { _ in
            self.isPlaying = self.player?.rate != 0
        }
    }
    
    private func togglePlayPause() {
        guard let player = player else { return }
        
        if isPlaying {
            player.pause()
        } else {
            player.play()
        }
        
        // Show temporary play/pause indicator
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            showPlayPauseIndicator = true
        }
        
        // Hide indicator after 1 second
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeOut(duration: 0.3)) {
                showPlayPauseIndicator = false
            }
        }
    }
    
    private func toggleMute() {
        guard let player = player else { return }
        
        isMuted.toggle()
        player.isMuted = isMuted
    }
    
    private func toggleControls() {
        showControls.toggle()
        if showControls {
            startControlsTimer()
        } else {
            controlsTimer?.invalidate()
        }
    }
    
    private func startControlsTimer() {
        controlsTimer?.invalidate()
        controlsTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
            withAnimation {
                showControls = false
            }
        }
    }
    
    private func handleSwipeGesture(_ value: DragGesture.Value) {
        if value.translation.height > 100 {
            // Swipe down - minimize to mini player
            liveShowManager.showMiniPlayer()
            dismiss()
        }
    }
    
    private func addProductToCartWithFeedback(_ liveProduct: LiveProduct) {
        liveShowManager.addProductToCart(liveProduct, cartManager: cartManager)
        
        // Show visual feedback
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            // Could add some visual feedback here
        }
        
        print("🛒 [LiveShow] Added to cart: \(liveProduct.title)")
    }
    
    // sendChatMessage removed - now handled by RLiveChatComponent
    
    private func shareStream(_ stream: LiveStream) {
        // Implement sharing functionality
        print("📤 [LiveShow] Sharing stream: \(stream.title)")
    }
    
    private func cleanup() {
        player?.pause()
        controlsTimer?.invalidate()
    }
    
    // Cart overlay removed - handled globally by ContentView
}

// MARK: - Custom Video Player

#if os(iOS)
/// Vimeo WebView player that works with player.vimeo.com URLs
struct VimeoWebPlayer: UIViewRepresentable {
    let videoUrl: String
    
    func makeUIView(context: Context) -> WKWebView {
        print("🎬 [LiveShow] Creating Vimeo WebView player with URL: \(videoUrl)")
        
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.backgroundColor = UIColor.black
        webView.isOpaque = false
        webView.navigationDelegate = context.coordinator
        
        context.coordinator.webView = webView
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        // Only load if not already loaded
        if webView.url == nil {
            print("🔗 [LiveShow] Loading Vimeo HTML...")
            let html = createVimeoHTML()
            webView.loadHTMLString(html, baseURL: URL(string: "https://player.vimeo.com"))
        }
    }
    
    private func createVimeoHTML() -> String {
        // Extract video ID from URL
        let videoId = videoUrl.components(separatedBy: "/").last ?? "1029631656"
        
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            <style>
                body, html {
                    margin: 0;
                    padding: 0;
                    height: 100vh;
                    width: 100vw;
                    background-color: #000000;
                    overflow: hidden;
                }
                .video-container {
                    position: relative;
                    width: 100%;
                    height: 100vh;
                    overflow: hidden;
                }
                iframe {
                    position: absolute;
                    top: 50%;
                    left: 50%;
                    width: 120%;
                    height: 120%;
                    transform: translate(-50%, -50%);
                    border: none;
                    object-fit: cover;
                }
            </style>
        </head>
        <body>
            <div class="video-container">
                <iframe src="https://player.vimeo.com/video/\(videoId)?badge=0&autopause=0&autoplay=1&muted=1&controls=0&title=0&byline=0&portrait=0&background=1"
                        frameborder="0"
                        allow="autoplay; fullscreen; picture-in-picture"
                        allowfullscreen>
                </iframe>
            </div>
            
            <script>
                console.log('🎬 Vimeo player HTML loaded');
                console.log('📹 Video ID: \(videoId)');
                console.log('🔗 Full iframe src: https://player.vimeo.com/video/\(videoId)?badge=0&autopause=0&autoplay=1&muted=1&controls=0&title=0&byline=0&portrait=0&background=1');
            </script>
        </body>
        </html>
        """
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var webView: WKWebView?
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("✅ [LiveShow] Vimeo WebView navigation finished")
            
            // Wait for iframe to load, then send notification
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                NotificationCenter.default.post(name: .vimeoPlayerLoaded, object: nil)
                print("📺 [LiveShow] Posted Vimeo player loaded notification")
            }
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("❌ [LiveShow] Vimeo WebView failed: \(error.localizedDescription)")
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            print("🔄 [LiveShow] Vimeo WebView started loading")
        }
    }
}

/// Custom video player for direct video URLs (non-Vimeo)
struct CustomVideoPlayer: UIViewRepresentable {
    let player: AVPlayer
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor.black
        
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.frame = view.bounds
        
        // IMPORTANT: Prevent fullscreen by disabling certain player controls
        playerLayer.player?.allowsExternalPlayback = false
        
        view.layer.addSublayer(playerLayer)
        
        // Store layer reference for updates
        context.coordinator.playerLayer = playerLayer
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Update layer frame when view bounds change
        if let playerLayer = context.coordinator.playerLayer {
            DispatchQueue.main.async {
                playerLayer.frame = uiView.bounds
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var playerLayer: AVPlayerLayer?
    }
}
#else
/// Fallback video player for non-iOS platforms
struct VimeoWebPlayer: View {
    let videoUrl: String
    
    var body: some View {
        // Simple fallback for non-iOS
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .overlay(
                Text("Video: \(videoUrl)")
                    .foregroundColor(.white)
            )
    }
}

struct CustomVideoPlayer: View {
    let player: AVPlayer
    
    var body: some View {
        VideoPlayer(player: player)
    }
}
#endif

// MARK: - Animated LIVE Badge

struct AnimatedLiveBadge: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 6) {
            // Pulsating red dot (only the dot animates)
            Circle()
                .fill(Color.red)
                .frame(width: 8, height: 8)
                .scaleEffect(isAnimating ? 1.4 : 1.0)
                .opacity(isAnimating ? 0.6 : 1.0)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)
            
            Text("LIVE")
                .font(.caption.weight(.bold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, ReachuSpacing.sm)
        .padding(.vertical, ReachuSpacing.xs)
        .background(Color.black.opacity(0.6))
        .cornerRadius(ReachuBorderRadius.small)
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Preview

#Preview {
    RLiveShowFullScreenOverlay()
        .environmentObject(CartManager())
}

// MARK: - Notification Names

extension Notification.Name {
    static let vimeoPlayerLoaded = Notification.Name("vimeoPlayerLoaded")
}

// MARK: - Extensions for Debugging

extension AVPlayer.Status: CustomStringConvertible {
    public var description: String {
        switch self {
        case .unknown: return "unknown"
        case .readyToPlay: return "readyToPlay"
        case .failed: return "failed"
        @unknown default: return "unknown default"
        }
    }
}

extension AVPlayerItem.Status: CustomStringConvertible {
    public var description: String {
        switch self {
        case .unknown: return "unknown"
        case .readyToPlay: return "readyToPlay"  
        case .failed: return "failed"
        @unknown default: return "unknown default"
        }
    }
}

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
    @State private var hasError = false
    @State private var errorMessage = ""
    @State private var isPlaying = false
    @State private var isMuted = true
    @State private var showPlayPauseIndicator = false
    @State private var selectedProductForDetail: Product?
    @State private var showProductsGrid = false
    
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

            // Dynamic components overlay (renderer)
            DynamicComponentRenderer()
                .zIndex(10_000_000)
            
            // Floating LIVE badge (positioned on the right)
            VStack {
                HStack {
                    Spacer()
                    
                    VStack {
                        AnimatedLiveBadge()
                        Spacer()
                    }
                    .padding(.top, ReachuSpacing.lg)
                    .padding(.trailing, ReachuSpacing.lg)
                }
                
                Spacer()
            }
            
            // Bottom content with controls at chat level
            VStack {
                Spacer()
                
                // Controls at chat level (right side)
                HStack {
                    Spacer()
                    
                    rightSideControls
                        .padding(.trailing, ReachuSpacing.md) // Less margin
                        .padding(.bottom, 160) // Lower position, closer to chat
                }
                
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
        .sheet(isPresented: $showProductsGrid) {
            RLiveProductsGridOverlay(products: currentStream?.featuredProducts ?? [])
                .environmentObject(cartManager)
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
        // Remove gesture conflicts - keep controls always visible
        // .onTapGesture { toggleControls() }
        .gesture(
            DragGesture(minimumDistance: 100, coordinateSpace: .global)
                .onEnded { value in
                    // Swipe up to minimize to mini-player
                    if value.translation.height < -100 {
                        print("⬆️ [LiveShow] Swipe up detected - minimizing to mini-player")
                        liveShowManager.showMiniPlayer()
                        dismiss()
                    }
                }
        )
    }
    
    // MARK: - Video Player Section
    
    @ViewBuilder
    private func videoPlayerSection(stream: LiveStream) -> some View {
        if currentStream != nil {
            // Use optimized video player with proper URL type detection
            if let videoUrl = stream.videoUrl, !videoUrl.isEmpty {
                // Check URL type and use appropriate player
                if videoUrl.contains("player.vimeo.com") {
                    VimeoWebPlayer(videoUrl: videoUrl)
                } else if videoUrl.contains(".m3u8") || videoUrl.contains("hls") {
                    // HLS stream - try both approaches
                    if let player = player {
                        ZStack {
                            // Try SwiftUI VideoPlayer first (more reliable for HLS)
                            VideoPlayer(player: player)
                                .onAppear {
                                    print("🎬 [LiveShow] SwiftUI VideoPlayer appeared")
                                }
                            
                            // Fallback: Custom player with debugging
                            // CustomVideoPlayer(player: player)
                            
                            // Debug overlay to verify video is showing
                            VStack {
                                HStack {
                                    Text("HLS Video Playing")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.green.opacity(0.8))
                                        .cornerRadius(4)
                                    Spacer()
                                }
                                Spacer()
                            }
                            .padding(.top, 50)
                            .padding(.leading, 20)
                        }
                    } else {
                        // Fallback for HLS
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                VStack {
                                    Text("Loading HLS Stream...")
                                        .foregroundColor(.white)
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                }
                            )
                    }
                } else if let player = player {
                    // Direct video URL - use AVPlayer
                    CustomVideoPlayer(player: player)
                } else {
                    // Fallback
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Text("Video not available")
                                .foregroundColor(.white)
                        )
                }
            } else {
                // Si no hay videoUrl, muestra "Coming soon"
                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                    Text("Coming soon")
                        .font(.title)
                        .foregroundColor(.white)
                        .bold()
                }
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
            // Left side - Close button (small)
            VStack {
                Button(action: {
                    liveShowManager.hideLiveStream()
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(Color.black.opacity(0.5))
                        )
                }
                
                Spacer()
            }
            
            // Center - Stream info with avatar
            VStack(alignment: .center, spacing: ReachuSpacing.xs) {
                // Avatar + Title
                HStack(spacing: ReachuSpacing.sm) {
                    // Streamer avatar
                    AsyncImage(url: URL(string: stream.streamer.avatarUrl ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                    }
                    .frame(width: 28, height: 28)
                    .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(stream.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Text("by \(stream.streamer.name)")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                
                // Viewer count
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
            }
            
            Spacer()
            
            // This will be moved to bottom - removing from top
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

    private func monitorPlayerStatus(_ item: AVPlayerItem) {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            print("📊 [LiveShow] Player status: \(item.status.description)")
            
            // Log additional HLS debugging info
            if let url = item.asset as? AVURLAsset {
                print("🔗 [LiveShow] Asset URL: \(url.url.absoluteString)")
                if url.url.absoluteString.contains(".m3u8") {
                    print("📺 [LiveShow] HLS stream detected")
                }
            }
            
            if item.status == .readyToPlay {
                print("✅ [LiveShow] Player is ready to play")
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                timer.invalidate()
            } else if item.status == .failed {
                let errorMsg = item.error?.localizedDescription ?? "Unknown error"
                print("❌ [LiveShow] Player failed: \(errorMsg)")
                
                // Enhanced error detection for HLS
                var shouldRefresh = false
                var isHLSError = false
                
                if let error = item.error as NSError? {
                    print("🔍 [LiveShow] Error details:")
                    print("   - Domain: \(error.domain)")
                    print("   - Code: \(error.code)")
                    print("   - UserInfo: \(error.userInfo)")
                    
                    // Check for HTTP response errors
                    if error.domain == NSURLErrorDomain {
                        if let response = error.userInfo["NSErrorFailingURLResponseKey"] as? HTTPURLResponse {
                            print("   - HTTP Status: \(response.statusCode)")
                            if response.statusCode == 403 {
                                shouldRefresh = true
                                isHLSError = true
                            }
                        }
                    }
                    
                    // Check for HLS-specific errors
                    if errorMsg.lowercased().contains("hls") || 
                       errorMsg.lowercased().contains("m3u8") ||
                       errorMsg.lowercased().contains("playlist") {
                        isHLSError = true
                    }
                }
                
                // Fallback: si el mensaje contiene "permission" o "403"
                if errorMsg.lowercased().contains("permission") || 
                   errorMsg.contains("403") ||
                   errorMsg.lowercased().contains("forbidden") {
                    shouldRefresh = true
                    isHLSError = true
                }
                
                timer.invalidate()
                
                if shouldRefresh && isHLSError, let stream = self.currentStream {
                    print("🔄 [LiveShow] HLS token expired or permission denied, refreshing HLS URL...")
                    refreshHLSAndRetry(streamId: stream.id)
                    return
                }
                
                // Try fallback for non-HLS errors or if refresh fails
                DispatchQueue.main.async {
                    print("🔄 [LiveShow] Trying fallback video...")
                }
            }
        }
    }

    /// Llama al endpoint de refresh y reintenta la reproducción
    private func refreshHLSAndRetry(streamId: String) {
        print("🔄 [LiveShow] Starting HLS refresh for stream ID: \(streamId)")
        isLoading = true
        
        let urlString = "https://stg-dev-microservices.tipioapp.com/api/stg/livestreams/refresh-hls/sdk/\(streamId)"
        guard let url = URL(string: urlString) else {
            print("❌ [LiveShow] Invalid refresh HLS URL: \(urlString)")
            DispatchQueue.main.async { self.isLoading = false }
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 30.0
        
        // Add headers if needed
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("ReachuSDK/1.0", forHTTPHeaderField: "User-Agent")
        
        print("📡 [LiveShow] Making refresh request to: \(urlString)")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ [LiveShow] Failed to refresh HLS: \(error.localizedDescription)")
                    self.isLoading = false
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("❌ [LiveShow] Invalid response type")
                    self.isLoading = false
                    return
                }
                
                print("📊 [LiveShow] Refresh response status: \(httpResponse.statusCode)")
                
                guard httpResponse.statusCode == 200 else {
                    print("❌ [LiveShow] Refresh failed with status: \(httpResponse.statusCode)")
                    self.isLoading = false
                    return
                }
                
                guard let data = data else {
                    print("❌ [LiveShow] No data from refresh HLS")
                    self.isLoading = false
                    return
                }
                
                do {
                    // Decodifica el objeto stream actualizado
                    let decoder = JSONDecoder()
                    let refreshedTipioStream = try decoder.decode(TipioLiveStream.self, from: data)
                    let refreshedStream = refreshedTipioStream.toLiveStream()
                    
                    print("✅ [LiveShow] Successfully refreshed stream")
                    print("🔗 [LiveShow] New video URL: \(refreshedStream.videoUrl ?? "nil")")
                    
                    // Actualiza el stream y reintenta setupPlayer
                    self.liveShowManager.updateCurrentStream(refreshedStream)
                    self.setupPlayer()
                } catch {
                    print("❌ [LiveShow] Failed to decode refreshed stream: \(error.localizedDescription)")
                    self.isLoading = false
                }
            }
        }.resume()
    }
    
    private func setupPlayer() {
        guard let stream = currentStream else { 
            print("❌ [LiveShow] No current stream for setup")
            return 
        }
        
        print("🎬 [LiveShow] Setting up player for stream: \(stream.title)")
        print("🎬 [LiveShow] Stream URL: \(stream.videoUrl ?? "nil")")
        
        guard let videoUrl = stream.videoUrl, !videoUrl.isEmpty else {
            print("❌ [LiveShow] Stream has no video URL")
            isLoading = false
            return
        }

        if videoUrl.contains("player.vimeo.com") {
            print("🎥 [LiveShow] Vimeo player URL detected. Skipping AVPlayer creation.")
            player = nil
            isLoading = false
            return
        }

        print("🔗 [LiveShow] Final video URL: \(videoUrl)")
        
        // Detect URL type for better logging
        if videoUrl.contains(".m3u8") {
            print("📺 [LiveShow] HLS stream detected (.m3u8)")
        } else if videoUrl.contains("player.vimeo.com") {
            print("🎥 [LiveShow] Vimeo player URL detected")
        } else if videoUrl.contains("hls") {
            print("📺 [LiveShow] HLS stream detected (hls keyword)")
        } else {
            print("🎬 [LiveShow] Direct video URL detected")
        }

        guard let url = URL(string: videoUrl) else {
            print("❌ [LiveShow] Failed to create URL from: \(videoUrl)")
            isLoading = false
            return
        }
        
        print("📱 [LiveShow] Creating AVPlayer with URL...")
        
        // Configurar sesión de audio antes de crear el reproductor
        AudioSessionManager.shared.configureForContent(isLive: stream.isLive)
        
        player = AVPlayer(url: url)
        
        guard let player = player else {
            print("❌ [LiveShow] Failed to create AVPlayer")
            isLoading = false
            return
        }
        
        // Registrar este reproductor como activo
        AudioSessionManager.shared.registerPlayer(player, isLive: stream.isLive)
        
        print("⚙️ [LiveShow] Configuring player settings...")
        
        // Configure for better streaming experience
        // For HLS streams, we want to minimize stalling
        if videoUrl.contains(".m3u8") || videoUrl.contains("hls") {
            print("🎬 [LiveShow] Configuring for HLS stream")
            player.automaticallyWaitsToMinimizeStalling = true // Better for HLS
        } else {
            player.automaticallyWaitsToMinimizeStalling = false // Better for direct videos
        }
        
        player.isMuted = isMuted
        player.allowsExternalPlayback = false // Prevent fullscreen takeover
        
        // Additional HLS-specific configuration
        if let currentItem = player.currentItem {
            // Enable HLS optimizations
            currentItem.preferredForwardBufferDuration = 5.0 // 5 seconds buffer for HLS
            currentItem.canUseNetworkResourcesForLiveStreamingWhilePaused = true
        }
        
        // Monitor player status (minimal logging)
        player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 5, preferredTimescale: 1), queue: .main) { time in
            let currentTime = CMTimeGetSeconds(time)
            if Int(currentTime) % 30 == 0 { // Log every 30 seconds to reduce spam
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
        isMuted.toggle()
        print("🔊 [RLiveShowFullScreenOverlay] Audio \(isMuted ? "silenciado" : "activado")")
        if let player = player {
            // ✅ Caso AVPlayer (HLS/MP4)
            player.isMuted = isMuted
            print("🎧 [RLiveShowFullScreenOverlay] AVPlayer isMuted: \(player.isMuted)")
            if !isMuted {
                // Activar sesión de audio para que se escuche realmente
                do {
                    try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
                    try AVAudioSession.sharedInstance().setActive(true)
                    print("✅ AVAudioSession activated for playback")
                } catch {
                    print("❌ AVAudioSession error: \(error.localizedDescription)")
                }
            }
        } else {
            // ✅ Caso Vimeo WebView
            let targetVolume = isMuted ? 0 : 1;
            let js = """
                (function() {
                    const MAX_ATTEMPTS = 20;
                    const INTERVAL_MS = 500;
                    let attempts = 0;
                    const targetOrigin = 'https://player.vimeo.com';
                    const volumeValue = \(targetVolume); // Inyecta el volumen deseado

                    const trySetVolume = () => {
                        attempts++;
                        const iframe = document.getElementById('vimeo-player');

                        if (iframe && iframe.contentWindow) {
                            clearInterval(intervalId);
                            
                            const command = {
                                method: 'setVolume',
                                value: volumeValue
                            };
                            const message = JSON.stringify(command);
                            
                            iframe.contentWindow.postMessage(message, targetOrigin);
                            console.log('✅ Vimeo: Volumen establecido en ' + volumeValue + ' después de ' + attempts + ' intentos.');
                        } else if (attempts >= MAX_ATTEMPTS) {
                            clearInterval(intervalId);
                        }
                    };
                    const intervalId = setInterval(trySetVolume, INTERVAL_MS);
                })();
            """;

            NotificationCenter.default.post(
                name: .executeVimeoJS,
                object: js
            )

            print("🎧 [RLiveShowFullScreenOverlay] Vimeo WebView - toggle via JS")
        }
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
    
    // handleSwipeGesture removed - now handled inline to reduce gesture conflicts
    
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
    
    private func createUserLike() {
        // Efecto local inmediato
        LiveLikesManager.shared.createUserLike()
        // Notificar backend HEART
        if let stream = liveShowManager.currentStream {
            LiveShowManager.shared.sendHeartForCurrentStream(isVideoLive: stream.isLive)
        }
        
        // Haptic feedback
        #if os(iOS)
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        #endif
    }
    
    private func cleanup() {
        if let player = player {
            AudioSessionManager.shared.unregisterPlayer(player)
        }
        player?.pause()
        controlsTimer?.invalidate()
    }
    
    // MARK: - Right Side Controls
    
    @ViewBuilder
    private var rightSideControls: some View {
        VStack(spacing: ReachuSpacing.md) {
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
            
            // Products grid button
            Button(action: {
                showProductsGrid = true
            }) {
                Image(systemName: "grid")
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
            
            // Cart button with badge
            Button(action: {
                print("🛒 [LiveShow] Opening cart overlay")
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
            
            // Likes button
            Button(action: {
                createUserLike()
            }) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.red)
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
        }
    }
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
        configuration.suppressesIncrementalRendering = true
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.scrollView.showsHorizontalScrollIndicator = false
        webView.backgroundColor = UIColor.black
        webView.isOpaque = false
        webView.navigationDelegate = context.coordinator
        
        // Reduce gesture conflicts
        webView.allowsBackForwardNavigationGestures = false
        
        context.coordinator.webView = webView

        NotificationCenter.default.addObserver(
            forName: .executeVimeoJS,
            object: nil,
            queue: .main
        ) { notification in
            if let script = notification.object as? String {
                context.coordinator.webView?.evaluateJavaScript(script) { _, error in
                    if let error = error {
                        print("❌ Vimeo JS failed: \(error.localizedDescription)")
                    } else {
                        print("🔊 Vimeo JS success: \(script)")
                    }
                }
            }
        }
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        print("🎬 [VimeoWebPlayer] makeUIView called with videoUrl: \(videoUrl)")
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
                        id="vimeo-player"
                        frameborder="0"
                        allow="autoplay; fullscreen; picture-in-picture"
                        allowfullscreen>
                </iframe>
            </div>
            
            <script>
                // Minimal JavaScript to reduce processing
                console.log('🎬 Vimeo loaded');
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

extension Notification.Name {
    static let executeVimeoJS = Notification.Name("executeVimeoJS")
}


/// Custom video player for direct video URLs (non-Vimeo)
struct CustomVideoPlayer: UIViewRepresentable {
    let player: AVPlayer
    
    func makeUIView(context: Context) -> UIView {
        print("🎬 [CustomVideoPlayer] Creating video player view")
        
        let view = UIView()
        view.backgroundColor = UIColor.red // Temporary red background to see the view bounds
        
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.backgroundColor = UIColor.blue.cgColor // Temporary blue background to see the layer
        
        // IMPORTANT: Prevent fullscreen by disabling certain player controls
        playerLayer.player?.allowsExternalPlayback = false
        
        view.layer.addSublayer(playerLayer)
        
        // Store layer reference for updates
        context.coordinator.playerLayer = playerLayer
        context.coordinator.containerView = view
        
        print("🎬 [CustomVideoPlayer] Player layer created and added to view")
        print("🎬 [CustomVideoPlayer] Initial view bounds: \(view.bounds)")
        print("🎬 [CustomVideoPlayer] Initial layer frame: \(playerLayer.frame)")
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Update layer frame when view bounds change
        if let playerLayer = context.coordinator.playerLayer {
            let newFrame = uiView.bounds
            print("🎬 [CustomVideoPlayer] Updating frame to: \(newFrame)")
            
            DispatchQueue.main.async {
                playerLayer.frame = newFrame
                print("🎬 [CustomVideoPlayer] Frame updated successfully")
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var playerLayer: AVPlayerLayer?
        var containerView: UIView?
        private var frameUpdateTimer: Timer?
        
        init() {
            // Set up frame update timer to ensure proper sizing
            frameUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                self?.updateFrameIfNeeded()
            }
        }
        
        deinit {
            frameUpdateTimer?.invalidate()
        }
        
        private func updateFrameIfNeeded() {
            guard let playerLayer = playerLayer,
                  let containerView = containerView else { return }
            
            let currentFrame = playerLayer.frame
            let targetFrame = containerView.bounds
            
            // Debug logging
            if targetFrame.width > 0 && targetFrame.height > 0 {
                print("🎬 [CustomVideoPlayer] Frame check - Current: \(currentFrame), Target: \(targetFrame)")
            }
            
            // Force update if target frame has valid dimensions
            if targetFrame.width > 0 && targetFrame.height > 0 {
                DispatchQueue.main.async {
                    playerLayer.frame = targetFrame
                    print("🎬 [CustomVideoPlayer] Frame force-updated to: \(targetFrame)")
                    
                    // Additional debugging
                    print("🎬 [CustomVideoPlayer] Layer bounds after update: \(playerLayer.bounds)")
                    print("🎬 [CustomVideoPlayer] Layer position: \(playerLayer.position)")
                    print("🎬 [CustomVideoPlayer] Layer anchorPoint: \(playerLayer.anchorPoint)")
                }
            }
        }
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

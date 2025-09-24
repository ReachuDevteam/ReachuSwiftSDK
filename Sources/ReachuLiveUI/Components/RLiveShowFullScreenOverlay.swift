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
    @State private var showChat = true
    @State private var showShopping = false
    @State private var chatMessage = ""
    @State private var isLoading = true
    @State private var isPlaying = false
    @State private var isMuted = true
    @State private var showPlayPauseIndicator = false
    
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
        }
        .onAppear {
            setupPlayer()
            startControlsTimer()
            if let stream = currentStream {
                configurePlayer(with: stream)
            }
        }
        .onDisappear {
            cleanup()
        }
        .onTapGesture(count: 2) {
            // Double tap to play/pause
            togglePlayPause()
        }
        .onTapGesture {
            // Single tap to show/hide controls
            toggleControls()
        }
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
        if let player = player {
            // Custom video player using WebView to maintain UI control
            CustomVideoPlayer(
                player: player,
                isPlaying: $isPlaying,
                videoProgress: .constant(0),
                videoDuration: .constant(100)
            )
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
            
            // Bottom overlay (chat, shopping, controls)
            bottomOverlay(stream: stream)
        }
        .opacity(showControls ? 1 : 0)
        .animation(.easeInOut(duration: 0.3), value: showControls)
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
            VStack(alignment: .leading, spacing: ReachuSpacing.sm) {
                // Live indicator and viewer count
                HStack(spacing: ReachuSpacing.sm) {
                    // LIVE badge
                    HStack(spacing: ReachuSpacing.xs) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                        
                        Text("LIVE")
                            .font(.caption.weight(.bold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, ReachuSpacing.sm)
                    .padding(.vertical, ReachuSpacing.xs)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(ReachuBorderRadius.small)
                    
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
                
                // Stream title and streamer info
                VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
                    Text(stream.title)
                        .font(ReachuTypography.headline)
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    HStack(spacing: ReachuSpacing.xs) {
                        AsyncImage(url: URL(string: stream.streamer.avatarUrl ?? "")) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                        }
                        .frame(width: 24, height: 24)
                        .clipShape(Circle())
                        
                        Text(stream.streamer.name)
                            .font(ReachuTypography.body)
                            .foregroundColor(.white.opacity(0.9))
                        
                        if stream.streamer.isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.caption2)
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Top right controls
            VStack(spacing: ReachuSpacing.sm) {
                // Close button
                Button(action: {
                    liveShowManager.hideLiveStream()
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.black.opacity(0.6))
                        .clipShape(Circle())
                }
                
                // Play/Pause button
                Button(action: togglePlayPause) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.black.opacity(0.6))
                        .clipShape(Circle())
                }
                
                // Mute/Unmute button
                Button(action: toggleMute) {
                    Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.2.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.black.opacity(0.6))
                        .clipShape(Circle())
                }
                
                // Minimize to mini player
                Button(action: {
                    liveShowManager.showMiniPlayer()
                    dismiss()
                }) {
                    Image(systemName: "pip.enter")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.black.opacity(0.6))
                        .clipShape(Circle())
                }
                
                // Share button
                Button(action: {
                    shareStream(stream)
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.black.opacity(0.6))
                        .clipShape(Circle())
                }
            }
        }
        .padding(.horizontal, ReachuSpacing.lg)
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
            // Toggle buttons
            HStack(spacing: ReachuSpacing.lg) {
                Button(action: { showChat.toggle() }) {
                    HStack(spacing: ReachuSpacing.xs) {
                        Image(systemName: "bubble.left.fill")
                        Text("Chat")
                    }
                    .font(.caption)
                    .foregroundColor(showChat ? adaptiveColors.primary : .white.opacity(0.7))
                }
                
                Button(action: { showShopping.toggle() }) {
                    HStack(spacing: ReachuSpacing.xs) {
                        Image(systemName: "bag.fill")
                        Text("Shop")
                    }
                    .font(.caption)
                    .foregroundColor(showShopping ? adaptiveColors.primary : .white.opacity(0.7))
                }
                
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
                }
            }
            
            // Content sections
            HStack(spacing: ReachuSpacing.md) {
                // Chat section
                if showChat {
                    chatSection(stream: stream)
                        .frame(maxWidth: .infinity)
                }
                
                // Shopping section
                if showShopping {
                    shoppingSection(stream: stream)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, ReachuSpacing.lg)
        .padding(.bottom, ReachuSpacing.xl)
    }
    
    // MARK: - Chat Section
    
    @ViewBuilder
    private func chatSection(stream: LiveStream) -> some View {
        VStack(spacing: ReachuSpacing.sm) {
            // Chat messages
            ScrollView {
                LazyVStack(alignment: .leading, spacing: ReachuSpacing.xs) {
                    ForEach(stream.chatMessages.suffix(5)) { message in
                        chatMessageView(message: message)
                    }
                }
            }
            .frame(maxHeight: 120)
            
            // Chat input
            HStack(spacing: ReachuSpacing.sm) {
                TextField("Type a message...", text: $chatMessage)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(ReachuTypography.body)
                
                Button(action: sendChatMessage) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(adaptiveColors.primary)
                }
                .disabled(chatMessage.isEmpty)
            }
        }
        .padding(ReachuSpacing.md)
        .background(Color.black.opacity(0.6))
        .cornerRadius(ReachuBorderRadius.medium)
    }
    
    @ViewBuilder
    private func chatMessageView(message: LiveChatMessage) -> some View {
        HStack(alignment: .top, spacing: ReachuSpacing.xs) {
            Text(message.user.username)
                .font(.caption.weight(.semibold))
                .foregroundColor(message.isStreamerMessage ? Color.blue : Color.white.opacity(0.8))
            
            Text(message.message)
                .font(.caption)
                .foregroundColor(.white)
                .lineLimit(nil)
            
            Spacer()
        }
    }
    
    // MARK: - Shopping Section
    
    @ViewBuilder
    private func shoppingSection(stream: LiveStream) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: ReachuSpacing.md) {
                ForEach(stream.featuredProducts) { liveProduct in
                    liveProductCard(liveProduct: liveProduct)
                }
            }
            .padding(.horizontal, ReachuSpacing.sm)
        }
        .frame(height: 140)
    }
    
    @ViewBuilder
    private func liveProductCard(liveProduct: LiveProduct) -> some View {
        VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
            // Product image
            AsyncImage(url: URL(string: liveProduct.imageUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
            }
            .frame(width: 80, height: 80)
            .cornerRadius(ReachuBorderRadius.small)
            
            // Product info
            VStack(alignment: .leading, spacing: 2) {
                Text(liveProduct.title)
                    .font(.caption)
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                Text(liveProduct.price.formattedPrice)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(adaptiveColors.primary)
            }
            
            // Add to cart button
            Button(action: {
                addProductToCart(liveProduct)
            }) {
                Text("Add")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, ReachuSpacing.sm)
                    .padding(.vertical, ReachuSpacing.xs)
                    .background(adaptiveColors.primary)
                    .cornerRadius(ReachuBorderRadius.small)
            }
        }
        .frame(width: 100)
        .padding(ReachuSpacing.sm)
        .background(Color.black.opacity(0.6))
        .cornerRadius(ReachuBorderRadius.medium)
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
        VStack(spacing: ReachuSpacing.md) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)
            
            Text("Loading stream...")
                .font(ReachuTypography.body)
                .foregroundColor(.white)
        }
        .padding(ReachuSpacing.xl)
        .background(Color.black.opacity(0.8))
        .cornerRadius(ReachuBorderRadius.medium)
    }
    
    // MARK: - Helper Methods
    
    private func setupPlayer() {
        guard let stream = currentStream else { return }
        
        // For demo, use the working Vimeo URL
        let vimeoUrl = "https://player.vimeo.com/video/1029631656"
        
        if let url = URL(string: vimeoUrl) {
            player = AVPlayer(url: url)
            
            // Auto-play if live
            if stream.isLive {
                player?.play()
            }
            
            isLoading = false
            print("🎬 [LiveShow] Using Vimeo URL: \(vimeoUrl)")
        } else {
            isLoading = false
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
    
    private func addProductToCart(_ liveProduct: LiveProduct) {
        liveShowManager.addProductToCart(liveProduct, cartManager: cartManager)
        
        // Show visual feedback
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            // Could add some visual feedback here
        }
    }
    
    private func sendChatMessage() {
        guard !chatMessage.isEmpty else { return }
        
        // In a real implementation, this would send the message via WebSocket
        print("💬 [LiveShow] Sending chat message: \(chatMessage)")
        
        chatMessage = ""
    }
    
    private func shareStream(_ stream: LiveStream) {
        // Implement sharing functionality
        print("📤 [LiveShow] Sharing stream: \(stream.title)")
    }
    
    private func cleanup() {
        player?.pause()
        controlsTimer?.invalidate()
    }
}

// MARK: - Custom Video Player

#if os(iOS)
/// Custom Vimeo video player using WebView (based on working implementation)
struct CustomVideoPlayer: UIViewRepresentable {
    let player: AVPlayer
    @Binding var isPlaying: Bool
    @Binding var videoProgress: Double
    @Binding var videoDuration: Double
    
    // Extract URL from AVPlayer
    private var vimeoUrl: String {
        guard let url = player.currentItem?.asset as? AVURLAsset else {
            return "https://player.vimeo.com/video/1029631656"
        }
        return url.url.absoluteString
    }
    
    func makeUIView(context: Context) -> WKWebView {
        print("🎬 [LiveShow] Creating WebView video player with URL: \(vimeoUrl)")
        
        // Basic configuration
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        // Create the WebView
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.backgroundColor = UIColor.black
        webView.isOpaque = false
        
        // Add navigation delegate
        webView.navigationDelegate = context.coordinator
        
        // Setup coordinator
        context.coordinator.webView = webView
        context.coordinator.parent = self
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        print("🔄 [LiveShow] Updating WebView video player")
        
        // Check if isPlaying changed and update the video
        if context.coordinator.tempIsPlaying != isPlaying {
            context.coordinator.tempIsPlaying = isPlaying
            
            let playPauseScript = isPlaying ? 
                "if (window.vimeoPlayer) { window.vimeoPlayer.play(); }" :
                "if (window.vimeoPlayer) { window.vimeoPlayer.pause(); }"
            
            webView.evaluateJavaScript(playPauseScript) { _, error in
                if let error = error {
                    print("❌ [LiveShow] Error controlling playback: \(error.localizedDescription)")
                }
            }
        }
        
        // Load HTML with Vimeo embed (only if not already loaded)
        if webView.url == nil {
            let html = createVimeoHTML()
            webView.loadHTMLString(html, baseURL: URL(string: "https://player.vimeo.com"))
        }
    }
    
    private func createVimeoHTML() -> String {
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            <style>
                body, html {
                    margin: 0;
                    padding: 0;
                    height: 100%;
                    width: 100%;
                    background-color: #000000;
                    overflow: hidden;
                }
                div {
                    position: relative;
                    padding: 56.25% 0 0 0; /* 16:9 aspect ratio */
                }
                iframe {
                    position: absolute;
                    top: 0;
                    left: 0;
                    width: 100%;
                    height: 100%;
                    border: none;
                }
            </style>
        </head>
        <body>
            <div>
                <iframe src="\(vimeoUrl)?badge=0&autopause=0&player_id=0&app_id=58479&autoplay=1&muted=1&controls=0&title=0&byline=0&portrait=0&api=1"
                        frameborder="0"
                        allow="autoplay; fullscreen; picture-in-picture"
                        allowfullscreen>
                </iframe>
            </div>
            
            <script src="https://player.vimeo.com/api/player.js"></script>
            <script>
                window.onload = function() {
                    console.log('🎬 Vimeo HTML page loaded');
                    setupVimeoPlayer();
                };
                
                function setupVimeoPlayer() {
                    try {
                        var iframe = document.querySelector('iframe');
                        if (iframe) {
                            console.log('🎬 Iframe found, initializing Vimeo player');
                            
                            var player = new Vimeo.Player(iframe);
                            
                            player.on('play', function() {
                                console.log('▶️ Video is playing');
                                window.isPlaying = true;
                            });
                            
                            player.on('pause', function() {
                                console.log('⏸️ Video is paused');
                                window.isPlaying = false;
                            });
                            
                            player.on('timeupdate', function(data) {
                                window.videoProgress = data.percent;
                                window.videoDuration = data.duration;
                            });
                            
                            player.on('loaded', function() {
                                console.log('✅ Video loaded successfully');
                            });
                            
                            window.vimeoPlayer = player;
                        }
                    } catch (e) {
                        console.error('❌ Error setting up Vimeo player:', e);
                    }
                }
            </script>
        </body>
        </html>
        """
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: CustomVideoPlayer
        var webView: WKWebView?
        var tempIsPlaying: Bool = false
        
        init(_ parent: CustomVideoPlayer) {
            self.parent = parent
            self.tempIsPlaying = parent.isPlaying
            super.init()
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("✅ [LiveShow] WebView navigation finished")
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("❌ [LiveShow] WebView navigation failed: \(error.localizedDescription)")
        }
    }
}
#else
/// Fallback video player for non-iOS platforms
struct CustomVideoPlayer: View {
    let player: AVPlayer
    @Binding var isPlaying: Bool
    @Binding var videoProgress: Double
    @Binding var videoDuration: Double
    
    var body: some View {
        // Use VideoPlayer for non-iOS platforms
        VideoPlayer(player: player)
    }
}
#endif

// MARK: - Preview

#Preview {
    RLiveShowFullScreenOverlay()
        .environmentObject(CartManager())
}

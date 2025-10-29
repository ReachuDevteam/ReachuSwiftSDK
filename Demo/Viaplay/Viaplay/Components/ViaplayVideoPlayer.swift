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
                                .onTapGesture {
                                    playerViewModel.toggleControlsVisibility()
                                }
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
            
            // Poll Overlay
            if showPoll, let poll = webSocketManager.currentPoll {
                VStack {
                    Spacer()
                    
                    PollOverlay(poll: poll) {
                        showPoll = false
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100)
                }
            }
            
            // Product Overlay
            if showProduct, let product = webSocketManager.currentProduct {
                VStack {
                    Spacer()
                    
                    ProductOverlay(product: product) {
                        showProduct = false
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100)
                }
            }
            
            // Contest Overlay
            if showContest, let contest = webSocketManager.currentContest {
                VStack {
                    Spacer()
                    
                    ContestOverlay(contest: contest) {
                        showContest = false
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100)
                }
            }
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
            print("🎯 [VideoPlayer] Poll recibido: \(newPoll?.question ?? "nil")")
            if newPoll != nil {
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
            print("🛍️ [VideoPlayer] Producto recibido: \(newProduct?.name ?? "nil")")
            if newProduct != nil {
                print("🛍️ [VideoPlayer] Mostrando producto")
                withAnimation {
                    showProduct = true
                }
                
                // Auto-ocultar después de 10 segundos
                DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                    withAnimation {
                        print("🛍️ [VideoPlayer] Ocultando producto")
                        showProduct = false
                    }
                }
            }
        }
        .onReceive(webSocketManager.$currentContest) { newContest in
            print("🎁 [VideoPlayer] Concurso recibido: \(newContest?.title ?? "nil")")
            if newContest != nil {
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
        .padding(.top, 50)
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
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.white.opacity(0.3))
                            .frame(height: 4)
                        
                        Rectangle()
                            .fill(Color(red: 0.96, green: 0.08, blue: 0.42))
                            .frame(width: geometry.size.width * playerViewModel.progress, height: 4)
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
        .padding(.bottom, 50)
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
private func setOrientation(_ orientation: UIInterfaceOrientationMask) {
    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
        windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: orientation))
    }
}

#Preview {
    ViaplayVideoPlayer(match: Match.barcelonaPSG) {
        print("Dismissed")
    }
    .environmentObject(CartManager())
}

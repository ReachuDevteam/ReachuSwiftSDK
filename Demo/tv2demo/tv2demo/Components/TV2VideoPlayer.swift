import SwiftUI
import AVKit
import AVFoundation
import Combine

/// TV2 Video Player with casting support
/// Simulates a live streaming experience with AirPlay/Chromecast capability
struct TV2VideoPlayer: View {
    let match: Match
    let onDismiss: () -> Void
    
    @StateObject private var playerViewModel = VideoPlayerViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    // Detect landscape orientation
    private var isLandscape: Bool {
        verticalSizeClass == .compact
    }
    
    var body: some View {
        ZStack {
            // Video Player Layer (Custom - no native controls)
            if let player = playerViewModel.player {
                CustomVideoPlayerView(player: player)
                    .ignoresSafeArea()
                    .onTapGesture {
                        playerViewModel.toggleControlsVisibility()
                    }
            } else {
                // Loading or placeholder
                Color.black
                    .ignoresSafeArea()
                
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            }
            
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
            
            // Live Badge (compact, near top edge)
            VStack {
                HStack {
                    Spacer()
                    
                    liveBadge
                        .padding(.top, isLandscape ? TV2Theme.Spacing.sm : TV2Theme.Spacing.lg)
                        .padding(.trailing, TV2Theme.Spacing.sm)
                }
                
                Spacer()
            }
            
            // Chat Overlay (Twitch-style, horizontal layout)
            if isLandscape {
                TV2ChatOverlay()
            }
        }
        .preferredColorScheme(.dark)
        .statusBar(hidden: true) // Hide status bar for immersive experience
        .persistentSystemOverlays(.hidden) // Hide home indicator in landscape
        .ignoresSafeArea() // Full screen
        .onAppear {
            playerViewModel.setupPlayer()
            // Enable all orientations for video playback
            setOrientation(.allButUpsideDown)
        }
        .onDisappear {
            playerViewModel.cleanup()
            // Return to portrait when dismissed
            setOrientation(.portrait)
        }
    }
    
    // MARK: - Orientation Helper
    private func setOrientation(_ orientation: UIInterfaceOrientationMask) {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: orientation))
        }
        // Force orientation update
        UIDevice.current.setValue(orientation == .portrait ? UIInterfaceOrientation.portrait.rawValue : UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
        UINavigationController.attemptRotationToDeviceOrientation()
    }
    
    // MARK: - Top Bar
    private var topBar: some View {
        HStack(spacing: TV2Theme.Spacing.md) {
            // Back Button - TV2 styled
            Button(action: {
                dismiss()
                onDismiss()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: isLandscape ? 16 : 18, weight: .bold))
                    if !isLandscape {
                        Text("Tilbake")
                            .font(.system(size: 14, weight: .semibold))
                    }
                }
                .foregroundColor(.white)
                .padding(.horizontal, isLandscape ? 10 : 14)
                .padding(.vertical, isLandscape ? 7 : 10)
                .background(TV2Theme.Colors.primary.opacity(0.9))
                .clipShape(Capsule())
            }
            
            // Title
            if !isLandscape {
                VStack(alignment: .leading, spacing: 2) {
                    Text(match.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(match.subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.8))
                }
            } else {
                Text(match.title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Mute Button
            Button(action: { playerViewModel.toggleMute() }) {
                Image(systemName: playerViewModel.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .font(.system(size: isLandscape ? 14 : 16))
                    .foregroundColor(.white)
                    .frame(width: isLandscape ? 32 : 36, height: isLandscape ? 32 : 36)
                    .background(Color.white.opacity(0.25))
                    .clipShape(Circle())
            }
            
            // Cast Button (AirPlay)
            AirPlayButton()
                .frame(width: isLandscape ? 32 : 36, height: isLandscape ? 32 : 36)
        }
        .padding(.horizontal, TV2Theme.Spacing.md)
        .padding(.top, isLandscape ? TV2Theme.Spacing.sm : 45)
        .background(
            LinearGradient(
                colors: [
                    Color.black.opacity(0.8),
                    Color.black.opacity(0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: isLandscape ? 80 : 130)
        )
    }
    
    // MARK: - Bottom Controls
    private var bottomControls: some View {
        VStack(spacing: isLandscape ? TV2Theme.Spacing.sm : TV2Theme.Spacing.md) {
            // Progress Bar with Scrubbing
            VStack(spacing: isLandscape ? 3 : 6) {
                HStack {
                    Text(playerViewModel.currentTimeText)
                        .font(.system(size: isLandscape ? 11 : 13, weight: .semibold))
                        .foregroundColor(.white)
                        .monospacedDigit()
                    
                    Spacer()
                    
                    // Live Indicator or Duration
                    Text(playerViewModel.durationText)
                        .font(.system(size: isLandscape ? 11 : 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .monospacedDigit()
                }
                
                // Progress Slider
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background Track
                        Capsule()
                            .fill(Color.white.opacity(0.3))
                            .frame(height: isLandscape ? 4 : 5)
                        
                        // Progress Fill
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [TV2Theme.Colors.primary, TV2Theme.Colors.secondary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(
                                width: geometry.size.width * playerViewModel.progress,
                                height: isLandscape ? 4 : 5
                            )
                        
                        // Scrubber Handle
                        Circle()
                            .fill(TV2Theme.Colors.primary)
                            .frame(width: isLandscape ? 12 : 14, height: isLandscape ? 12 : 14)
                            .shadow(color: TV2Theme.Colors.primary.opacity(0.5), radius: 3, x: 0, y: 0)
                            .offset(x: (geometry.size.width * playerViewModel.progress) - (isLandscape ? 6 : 7))
                    }
                }
                .frame(height: isLandscape ? 12 : 14)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let screenWidth = UIScreen.main.bounds.width - (TV2Theme.Spacing.md * 2)
                            let progress = max(0, min(1, value.location.x / screenWidth))
                            playerViewModel.seek(to: progress)
                        }
                )
            }
            
            // Main Playback Controls
            HStack(spacing: isLandscape ? TV2Theme.Spacing.lg : TV2Theme.Spacing.xl) {
                // Rewind 10s
                ControlButton(
                    icon: "gobackward.10",
                    size: isLandscape ? 20 : 24,
                    color: TV2Theme.Colors.primary,
                    action: { playerViewModel.skipBackward(seconds: 10) }
                )
                
                Spacer()
                
                // Play/Pause (Center Button)
                Button(action: { playerViewModel.togglePlayPause() }) {
                    ZStack {
                        Circle()
                            .fill(TV2Theme.Colors.primary.opacity(0.9))
                            .frame(width: isLandscape ? 50 : 60, height: isLandscape ? 50 : 60)
                        
                        Image(systemName: playerViewModel.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: isLandscape ? 22 : 26, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                
                Spacer()
                
                // Forward 10s
                ControlButton(
                    icon: "goforward.10",
                    size: isLandscape ? 20 : 24,
                    color: TV2Theme.Colors.primary,
                    action: { playerViewModel.forward() }
                )
            }
            .padding(.horizontal, TV2Theme.Spacing.lg)
            
            // Secondary Controls Area (reserved for future content)
            HStack {
                // TODO: Add additional controls here as needed
                // This space is reserved for future functionality
                Spacer()
            }
            .frame(height: isLandscape ? 36 : 44)
            .padding(.horizontal, TV2Theme.Spacing.md)
            .padding(.bottom, isLandscape ? TV2Theme.Spacing.xs : TV2Theme.Spacing.sm)
        }
        .padding(.horizontal, TV2Theme.Spacing.md)
        .padding(.bottom, isLandscape ? TV2Theme.Spacing.md : TV2Theme.Spacing.xl)
        .background(
            LinearGradient(
                colors: [
                    Color.black.opacity(0),
                    Color.black.opacity(0.85)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: isLandscape ? 150 : 220)
        )
    }
    
    // MARK: - Live Badge
    private var liveBadge: some View {
        HStack(spacing: isLandscape ? 4 : 5) {
            Circle()
                .fill(Color.white)
                .frame(width: isLandscape ? 6 : 7, height: isLandscape ? 6 : 7)
            
            Text("DIREKTE")
                .font(.system(size: isLandscape ? 10 : 11, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, isLandscape ? 8 : 10)
        .padding(.vertical, isLandscape ? 4 : 5)
        .background(
            Capsule()
                .fill(Color.red.opacity(0.95))
        )
        .shadow(color: Color.black.opacity(0.4), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Control Button Component
struct ControlButton: View {
    let icon: String
    let size: CGFloat
    var color: Color = .white
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 40, height: 40)
        }
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
        print("▶️ [VideoPlayer] Initializing player...")
        
        player = AVPlayer(url: url)
        player?.allowsExternalPlayback = true // Enable AirPlay
        player?.usesExternalPlaybackWhileExternalScreenIsActive = true
        player?.isMuted = isMuted
        
        // Start playing
        player?.play()
        isPlaying = true
        
        // Setup time observer
        setupTimeObserver()
        
        // Auto-hide controls
        resetControlsTimer()
    }
    
    private func setupTimeObserver() {
        guard let player = player else { return }
        
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            
            let currentTime = CMTimeGetSeconds(time)
            let duration = CMTimeGetSeconds(player.currentItem?.duration ?? .zero)
            
            if duration.isFinite && duration > 0 {
                self.progress = currentTime / duration
                self.currentTimeText = self.formatTime(currentTime)
                self.durationText = self.formatTime(duration)
            }
        }
    }
    
    func togglePlayPause() {
        guard let player = player else { return }
        
        if isPlaying {
            player.pause()
        } else {
            player.play()
        }
        isPlaying.toggle()
        resetControlsTimer()
    }
    
    func rewind() {
        guard let player = player else { return }
        let currentTime = CMTimeGetSeconds(player.currentTime())
        let newTime = max(currentTime - 30, 0)
        player.seek(to: CMTime(seconds: newTime, preferredTimescale: 1))
        resetControlsTimer()
    }
    
    func forward() {
        guard let player = player else { return }
        let currentTime = CMTimeGetSeconds(player.currentTime())
        let duration = CMTimeGetSeconds(player.currentItem?.duration ?? .zero)
        let newTime = min(currentTime + 30, duration)
        player.seek(to: CMTime(seconds: newTime, preferredTimescale: 1))
        resetControlsTimer()
    }
    
    func skipBackward(seconds: Double) {
        guard let player = player else { return }
        let currentTime = CMTimeGetSeconds(player.currentTime())
        let newTime = max(currentTime - seconds, 0)
        player.seek(to: CMTime(seconds: newTime, preferredTimescale: 1))
        resetControlsTimer()
    }
    
    func toggleMute() {
        guard let player = player else { return }
        isMuted.toggle()
        player.isMuted = isMuted
        resetControlsTimer()
    }
    
    func setSpeed(_ speed: Float) {
        guard let player = player else { return }
        playbackSpeed = speed
        player.rate = speed
        if isPlaying {
            player.play()
        }
        resetControlsTimer()
    }
    
    func seek(to progress: Double) {
        guard let player = player,
              let duration = player.currentItem?.duration else { return }
        
        let seconds = CMTimeGetSeconds(duration) * progress
        player.seek(to: CMTime(seconds: seconds, preferredTimescale: 1))
        resetControlsTimer()
    }
    
    func toggleControlsVisibility() {
        withAnimation {
            showControls.toggle()
        }
        
        if showControls {
            resetControlsTimer()
        }
    }
    
    private func resetControlsTimer() {
        controlsTimer?.invalidate()
        
        withAnimation {
            showControls = true
        }
        
        controlsTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            withAnimation {
                self?.showControls = false
            }
        }
    }
    
    private func formatTime(_ seconds: Double) -> String {
        guard seconds.isFinite else { return "00:00" }
        
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%02d:%02d", minutes, secs)
        }
    }
    
    func cleanup() {
        player?.pause()
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
        }
        controlsTimer?.invalidate()
    }
}

// MARK: - AirPlay Button Wrapper
struct AirPlayButton: UIViewRepresentable {
    func makeUIView(context: Context) -> AVRoutePickerView {
        let routePickerView = AVRoutePickerView()
        routePickerView.backgroundColor = .clear
        routePickerView.tintColor = .white
        routePickerView.activeTintColor = .white
        return routePickerView
    }
    
    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {
        // No update needed
    }
}

// MARK: - Custom Video Player View (No Native Controls)
struct CustomVideoPlayerView: UIViewRepresentable {
    let player: AVPlayer
    
    func makeUIView(context: Context) -> PlayerLayerView {
        let view = PlayerLayerView()
        view.playerLayer.player = player
        // Use fill to cover entire screen including edges in landscape
        view.playerLayer.videoGravity = .resizeAspectFill
        view.backgroundColor = .black
        return view
    }
    
    func updateUIView(_ uiView: PlayerLayerView, context: Context) {
        // Layer updates automatically via layoutSubviews
    }
    
    class PlayerLayerView: UIView {
        override class var layerClass: AnyClass {
            return AVPlayerLayer.self
        }
        
        var playerLayer: AVPlayerLayer {
            return layer as! AVPlayerLayer
        }
    }
}

// MARK: - Preview
#Preview {
    TV2VideoPlayer(
        match: Match.dortmundAtletico,
        onDismiss: {}
    )
}


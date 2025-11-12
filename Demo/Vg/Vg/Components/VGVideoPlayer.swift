import SwiftUI
import AVKit
import AVFoundation
import Combine

struct VGVideoPlayer: View {
    @StateObject private var playerViewModel = VGVideoPlayerViewModel()
    @StateObject private var webSocketManager = WebSocketManager()
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @State private var isChatExpanded = false
    @State private var showPoll = false
    
    private var isLandscape: Bool {
        verticalSizeClass == .compact
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let player = playerViewModel.player {
                    CustomVGPlayerView(player: player)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .background(Color.black)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                playerViewModel.showControls.toggle()
                            }
                        }
                } else {
                    Rectangle()
                        .fill(Color.black)
                        .overlay(
                            ProgressView()
                                .tint(.white)
                        )
                }
                
                if playerViewModel.showControls {
                    controlsOverlay
                        .transition(.opacity)
                }
                
                // Chat overlay
                VGChatOverlay(showControls: $playerViewModel.showControls) { expanded in
                    isChatExpanded = expanded
                }
                
                // Poll overlay
                if showPoll, let poll = webSocketManager.currentPoll {
                    VGPollOverlay(
                        poll: poll,
                        isChatExpanded: isChatExpanded,
                        onVote: { _ in
                            withAnimation {
                                showPoll = false
                            }
                        },
                        onDismiss: {
                            withAnimation {
                                showPoll = false
                            }
                        }
                    )
                }
            }
            .onAppear {
                playerViewModel.setupPlayer()
                webSocketManager.connect()
            }
            .onDisappear {
                playerViewModel.cleanup()
                webSocketManager.disconnect()
            }
            .onReceive(webSocketManager.$currentPoll) { newPoll in
                if newPoll != nil {
                    withAnimation { showPoll = true }
                    if let duration = newPoll?.duration {
                        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(duration)) {
                            withAnimation { showPoll = false }
                        }
                    }
                }
            }
        }
    }
    
    private var controlsOverlay: some View {
        VStack {
            Spacer()
            HStack(spacing: 16) {
                Button(action: { playerViewModel.rewind() }) {
                    Image(systemName: "gobackward.30")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Circle())
                }
                
                Button(action: { playerViewModel.togglePlayPause() }) {
                    Image(systemName: playerViewModel.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(VGTheme.Colors.red)
                        .clipShape(Circle())
                        .shadow(color: VGTheme.Colors.red.opacity(0.6), radius: 8, x: 0, y: 0)
                }
                
                Button(action: { playerViewModel.forward() }) {
                    Image(systemName: "goforward.30")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Circle())
                }
            }
            .padding(.bottom, 16)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}

// MARK: - ViewModel

@MainActor
final class VGVideoPlayerViewModel: ObservableObject {
    @Published var player: AVPlayer?
    @Published var isPlaying = false
    @Published var showControls = true
    @Published var isMuted = true
    
    private var timeObserver: Any?
    private var controlsTimer: Timer?
    
    func setupPlayer() {
        if let localVideoPath = Bundle.main.path(forResource: "match", ofType: "mp4") {
            let url = URL(fileURLWithPath: localVideoPath)
            initializePlayer(with: url)
            return
        }
        
        let remote = "https://firebasestorage.googleapis.com/v0/b/tipio-1ec97.appspot.com/o/bar.v.psg.1.ucl.01.10.2025.fullmatchsports.com.1080p.mp4?alt=media&token=593ce8a1-0462-4c37-98c3-e399f25e3853"
        guard let url = URL(string: remote) else { return }
        initializePlayer(with: url)
    }
    
    func cleanup() {
        if let timeObserver = timeObserver, let player = player {
            player.removeTimeObserver(timeObserver)
        }
        controlsTimer?.invalidate()
        player?.pause()
        player = nil
    }
    
    func togglePlayPause() {
        guard let player = player else { return }
        if isPlaying { player.pause() } else { player.play() }
        isPlaying.toggle()
        resetControlsTimer()
    }
    
    func rewind() {
        guard let player = player else { return }
        let current = CMTimeGetSeconds(player.currentTime())
        let newTime = max(current - 30, 0)
        player.seek(to: CMTime(seconds: newTime, preferredTimescale: 1))
        resetControlsTimer()
    }
    
    func forward() {
        guard let player = player else { return }
        let current = CMTimeGetSeconds(player.currentTime())
        let newTime = current + 30
        player.seek(to: CMTime(seconds: newTime, preferredTimescale: 1))
        resetControlsTimer()
    }
    
    private func initializePlayer(with url: URL) {
        player = AVPlayer(url: url)
        player?.allowsExternalPlayback = true
        player?.usesExternalPlaybackWhileExternalScreenIsActive = true
        player?.isMuted = isMuted
        player?.play()
        isPlaying = true
        setupTimeObserver()
        resetControlsTimer()
    }
    
    private func setupTimeObserver() {
        guard let player = player else { return }
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] _ in
            guard let self = self else { return }
            self.resetControlsTimer()
        }
    }
    
    private func resetControlsTimer() {
        controlsTimer?.invalidate()
        controlsTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            withAnimation { self?.showControls = false }
        }
    }
}

// MARK: - Player Layer View

struct CustomVGPlayerView: UIViewRepresentable {
    let player: AVPlayer
    
    func makeUIView(context: Context) -> PlayerLayerView {
        let view = PlayerLayerView()
        view.playerLayer.player = player
        view.playerLayer.videoGravity = .resizeAspect
        view.backgroundColor = .black
        return view
    }
    
    func updateUIView(_ uiView: PlayerLayerView, context: Context) {}
    
    class PlayerLayerView: UIView {
        override class var layerClass: AnyClass { AVPlayerLayer.self }
        var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    }
}



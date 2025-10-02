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
    
    var body: some View {
        ZStack {
            // Video Player Layer
            if let player = playerViewModel.player {
                VideoPlayer(player: player)
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
            
            // Live Badge
            VStack {
                HStack {
                    Spacer()
                    
                    liveBadge
                        .padding(.top, 60)
                        .padding(.trailing, TV2Theme.Spacing.md)
                }
                
                Spacer()
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            playerViewModel.setupPlayer()
        }
        .onDisappear {
            playerViewModel.cleanup()
        }
    }
    
    // MARK: - Top Bar
    private var topBar: some View {
        HStack {
            // Back Button
            Button(action: {
                dismiss()
                onDismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Circle())
            }
            
            // Title
            VStack(alignment: .leading, spacing: 4) {
                Text(match.title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                Text(match.subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            // Cast Button (AirPlay)
            AirPlayButton()
                .frame(width: 40, height: 40)
        }
        .padding(.horizontal, TV2Theme.Spacing.md)
        .padding(.top, 50)
        .background(
            LinearGradient(
                colors: [
                    Color.black.opacity(0.7),
                    Color.black.opacity(0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 150)
        )
    }
    
    // MARK: - Bottom Controls
    private var bottomControls: some View {
        VStack(spacing: TV2Theme.Spacing.md) {
            // Progress Bar
            VStack(spacing: 4) {
                HStack {
                    Text(playerViewModel.currentTimeText)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(playerViewModel.durationText)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        Rectangle()
                            .fill(Color.white.opacity(0.3))
                            .frame(height: 4)
                        
                        // Progress
                        Rectangle()
                            .fill(TV2Theme.Colors.primary)
                            .frame(
                                width: geometry.size.width * playerViewModel.progress,
                                height: 4
                            )
                    }
                    .cornerRadius(2)
                }
                .frame(height: 4)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let progress = value.location.x / UIScreen.main.bounds.width
                            playerViewModel.seek(to: progress)
                        }
                )
            }
            
            // Playback Controls
            HStack(spacing: TV2Theme.Spacing.xl) {
                // Rewind 30s
                Button(action: { playerViewModel.rewind() }) {
                    Image(systemName: "gobackward.30")
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                }
                
                // Play/Pause
                Button(action: { playerViewModel.togglePlayPause() }) {
                    Image(systemName: playerViewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                }
                
                // Forward 30s
                Button(action: { playerViewModel.forward() }) {
                    Image(systemName: "goforward.30")
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                }
            }
            .padding(.bottom, TV2Theme.Spacing.md)
        }
        .padding(.horizontal, TV2Theme.Spacing.md)
        .padding(.bottom, 40)
        .background(
            LinearGradient(
                colors: [
                    Color.black.opacity(0),
                    Color.black.opacity(0.7)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 200)
        )
    }
    
    // MARK: - Live Badge
    private var liveBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Color.red)
                .frame(width: 8, height: 8)
            
            Text("DIREKTE")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.red.opacity(0.9))
        )
        .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
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
    
    private var timeObserver: Any?
    private var controlsTimer: Timer?
    
    func setupPlayer() {
        // Football match video URL
        // Using demo sports stream that simulates a live match
        let videoUrl = "https://cph-p2p-msl.akamaized.net/hls/live/2000341/test/master.m3u8"
        
        // Alternative football streams (replace with your actual TV2 stream):
        // let videoUrl = "https://moctobpltc-i.akamaihd.net/hls/live/571329/eight/playlist.m3u8"
        // let videoUrl = "https://tu-servidor.com/dortmund-athletic/stream.m3u8"
        
        guard let url = URL(string: videoUrl) else { return }
        
        player = AVPlayer(url: url)
        player?.allowsExternalPlayback = true // Enable AirPlay
        player?.usesExternalPlaybackWhileExternalScreenIsActive = true
        
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

// MARK: - Preview
#Preview {
    TV2VideoPlayer(
        match: Match.dortmundAtletico,
        onDismiss: {}
    )
}


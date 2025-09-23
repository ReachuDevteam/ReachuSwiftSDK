import Foundation
import AVFoundation
import Combine

@MainActor
public final class LiveShowViewModel: ObservableObject {
    @Published public private(set) var player: AVPlayer
    @Published public private(set) var isBuffering: Bool = false
    @Published public private(set) var isPlaying: Bool = false
    @Published public private(set) var errorMessage: String?

    private let service: LiveShowService
    private let liveStreamId: String?
    private let fallbackURL: URL?
    private var timeObserverToken: Any?
    private var cancellables = Set<AnyCancellable>()

    public init(
        service: LiveShowService,
        liveStreamId: String?,
        fallbackURL: URL?,
        isMuted: Bool,
        autoplay: Bool
    ) {
        self.service = service
        self.liveStreamId = liveStreamId
        self.fallbackURL = fallbackURL
        self.player = AVPlayer()
        self.player.isMuted = isMuted

        Task { [weak self] in
            await self?.setupInitialSource(autoplay: autoplay)
        }
        observePlayer()
    }

    deinit {
        if let token = timeObserverToken {
            Task {
                await MainActor.run {
                    player.removeTimeObserver(token)
                }
            }
        }
    }

    private func setupInitialSource(autoplay: Bool) async {
        do {
            if let url = try await service.refreshHLS(streamId: liveStreamId) {
                setPlayerItem(url: url)
            } else if let fallback = fallbackURL {
                setPlayerItem(url: fallback)
            }
            if autoplay { player.play(); isPlaying = true }
        } catch {
            errorMessage = (error as NSError).localizedDescription
            if let fallback = fallbackURL {
                setPlayerItem(url: fallback)
                if autoplay { player.play(); isPlaying = true }
            }
        }
    }

    private func setPlayerItem(url: URL) {
        let item = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: item)
    }

    public func togglePlayPause() {
        if isPlaying { player.pause() } else { player.play() }
        isPlaying.toggle()
    }

    public func refreshStream() async {
        do {
            if let url = try await service.refreshHLS(streamId: liveStreamId) {
                setPlayerItem(url: url)
                player.play()
                isPlaying = true
            }
        } catch {
            errorMessage = (error as NSError).localizedDescription
        }
    }

    private func observePlayer() {
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: 600), queue: .main) { [weak self] _ in
            guard let self = self else { return }
            self.isBuffering = self.player.timeControlStatus == .waitingToPlayAtSpecifiedRate
        }
    }
}



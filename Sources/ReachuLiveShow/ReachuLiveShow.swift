/// Reachu LiveShow Module
/// 
/// Provides livestreaming capabilities for the Reachu SDK

import Foundation
import SwiftUI

/// Main entry point for Reachu LiveShow
public struct ReachuLiveShowPlayer {
    public struct Configuration {
        public let refreshHLSEndpoint: URL
        public let apiKey: String?
        public init(refreshHLSEndpoint: URL, apiKey: String? = nil) {
            self.refreshHLSEndpoint = refreshHLSEndpoint
            self.apiKey = apiKey
        }
    }

    public static func configure() {
        print("📺 Reachu LiveShow initialized")
    }

    @MainActor
    public static func playerView(
        liveStreamId: String?,
        fallbackURL: URL?,
        config: Configuration,
        isMuted: Bool = true,
        autoplay: Bool = true
    ) -> some View {
        LiveShowView(
            viewModel: LiveShowViewModel(
                service: LiveShowService(configuration: config),
                liveStreamId: liveStreamId,
                fallbackURL: fallbackURL,
                isMuted: isMuted,
                autoplay: autoplay
            )
        )
    }
}
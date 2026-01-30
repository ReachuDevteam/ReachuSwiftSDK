import SwiftUI
import ReachuCore
import ReachuEngagementSystem
import ReachuDesignSystem

/// Reachu Engagement UI Components
/// 
/// Optional target for pre-built SwiftUI components for engagement features
/// Import this target to get ready-to-use UI components for polls, contests, and products

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public struct ReachuEngagementUI {
    
    /// Configure ReachuEngagementUI with default settings
    public static func configure() {
        // Ensure core SDK is configured
        if !ReachuConfiguration.shared.isConfigured {
            ReachuConfiguration.configure(
                apiKey: "",
                environment: .sandbox
            )
        }
    }
}

// MARK: - Public Exports

// Export engagement UI components (cards)
public typealias ReachuEngagementPollCard = REngagementPollCard
public typealias ReachuEngagementContestCard = REngagementContestCard
public typealias ReachuEngagementProductCard = REngagementProductCard
public typealias ReachuEngagementProductGridCard = REngagementProductGridCard

// Export engagement UI components (overlays)
public typealias ReachuEngagementPollOverlay = REngagementPollOverlay
public typealias ReachuEngagementContestOverlay = REngagementContestOverlay
public typealias ReachuEngagementProductOverlay = REngagementProductOverlay

// Export overlay option types
public typealias ReachuEngagementPollOverlayOption = REngagementPollOverlayOption

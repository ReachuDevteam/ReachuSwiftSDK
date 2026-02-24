import SwiftUI
import VioCore
import VioEngagementSystem
import VioDesignSystem

/// Vio Engagement UI Components
/// 
/// Optional target for pre-built SwiftUI components for engagement features
/// Import this target to get ready-to-use UI components for polls, contests, and products

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public struct VioEngagementUI {
    
    /// Configure VioEngagementUI with default settings
    public static func configure() {
        // Ensure core SDK is configured
        if !VioConfiguration.shared.isConfigured {
            VioConfiguration.configure(
                apiKey: "",
                environment: .sandbox
            )
        }
    }
}

// MARK: - Public Exports

// Export engagement UI components (cards)
public typealias VioEngagementPollCard = REngagementPollCard
public typealias VioEngagementContestCard = REngagementContestCard
public typealias VioEngagementProductCard = REngagementProductCard
public typealias VioEngagementProductGridCard = REngagementProductGridCard

// Export engagement UI components (overlays)
public typealias VioEngagementPollOverlay = REngagementPollOverlay
public typealias VioEngagementContestOverlay = REngagementContestOverlay
public typealias VioEngagementProductOverlay = REngagementProductOverlay

// Export overlay option types
public typealias VioEngagementPollOverlayOption = REngagementPollOverlayOption

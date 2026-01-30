import Foundation

/// Reachu Engagement System
/// 
/// Core module for engagement features (polls, contests)
/// Import this target to get engagement data models and managers

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public struct ReachuEngagementSystem {
    
    /// Configure ReachuEngagementSystem with default settings
    public static func configure() {
        // Configuration can be added here if needed in the future
    }
}

// MARK: - Public Exports

// Export engagement managers
public typealias ReachuEngagementManager = EngagementManager

// Export engagement models
public typealias ReachuPoll = Poll
public typealias ReachuContest = Contest
public typealias ReachuPollOption = Poll.PollOption
public typealias ReachuPollResults = PollResults
public typealias ReachuPollOptionResults = PollResults.PollOptionResults

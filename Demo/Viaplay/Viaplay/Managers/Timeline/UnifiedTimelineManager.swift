//
//  UnifiedTimelineManager.swift
//  Viaplay
//
//  Unified timeline manager for all events
//  Syncs chat, match events, polls, products, etc. with video timestamp
//  Ready for backend integration
//

import Foundation
import Combine

@MainActor
class UnifiedTimelineManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var currentVideoTime: TimeInterval = 0  // Seconds (0-5400 for 90 min match)
    @Published private(set) var allEvents: [AnyTimelineEvent] = []
    
    // MARK: - Computed Properties
    
    var currentMinute: Int {
        Int(currentVideoTime / 60)
    }
    
    var currentDisplayTime: String {
        let minutes = Int(currentVideoTime / 60)
        let seconds = Int(currentVideoTime.truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    /// All events visible at current video time
    var visibleEvents: [AnyTimelineEvent] {
        allEvents
            .filter { $0.videoTimestamp <= currentVideoTime }
            .sorted { event1, event2 in
                if event1.videoTimestamp == event2.videoTimestamp {
                    return event1.displayPriority > event2.displayPriority
                }
                return event1.videoTimestamp > event2.videoTimestamp  // Most recent first
            }
    }
    
    // MARK: - Public Methods
    
    /// Add an event to the timeline
    func addEvent<T: TimelineEvent>(_ event: T) {
        let wrappedEvent = AnyTimelineEvent(event)
        allEvents.append(wrappedEvent)
        allEvents.sort { $0.videoTimestamp < $1.videoTimestamp }
    }
    
    /// Add multiple events
    func addEvents<T: TimelineEvent>(_ events: [T]) {
        for event in events {
            addEvent(event)
        }
    }
    
    /// Add multiple wrapped events (for pre-generated data)
    func addWrappedEvents(_ events: [AnyTimelineEvent]) {
        allEvents.append(contentsOf: events)
        allEvents.sort { $0.videoTimestamp < $1.videoTimestamp }
    }
    
    /// Remove an event
    func removeEvent(id: String) {
        allEvents.removeAll { $0.id == id }
    }
    
    /// Clear all events
    func clearAllEvents() {
        allEvents.removeAll()
    }
    
    // MARK: - Match Duration Constants
    
    static let firstHalfDuration: TimeInterval = 2700  // 45 minutes
    static let halfTimeDuration: TimeInterval = 900    // 15 minutes pause
    static let secondHalfDuration: TimeInterval = 2700 // 45 minutes
    static let totalMatchDuration: TimeInterval = 6300 // 105 minutes total (45+15+45)
    
    /// Update video time (called by video player or scrubber)
    func updateVideoTime(_ seconds: TimeInterval) {
        let clampedTime = max(0, min(seconds, Self.totalMatchDuration))
        currentVideoTime = clampedTime
    }
    
    /// Jump to specific minute
    func jumpToMinute(_ minute: Int) {
        let seconds = TimeInterval(minute * 60)
        updateVideoTime(seconds)
    }
    
    /// Go to LIVE (end of available content)
    func goToLive(maxMinute: Int = 90) {
        updateVideoTime(TimeInterval(maxMinute * 60))
    }
    
    /// Get match phase at current time
    func currentMatchPhase() -> MatchPhase {
        if currentVideoTime < Self.firstHalfDuration {
            return .firstHalf
        } else if currentVideoTime < Self.firstHalfDuration + Self.halfTimeDuration {
            return .halfTime
        } else {
            return .secondHalf
        }
    }
}

enum MatchPhase {
    case firstHalf
    case halfTime
    case secondHalf
    
    var displayName: String {
        switch self {
        case .firstHalf: return "1. omgang"
        case .halfTime: return "Pause"
        case .secondHalf: return "2. omgang"
        }
    }
    
    // MARK: - Filtering by Type
    
    func visibleEvents(ofType type: TimelineEventType) -> [AnyTimelineEvent] {
        visibleEvents.filter { $0.eventType == type }
    }
    
    func visibleEvents(ofCategory category: TimelineEventCategory) -> [AnyTimelineEvent] {
        visibleEvents.filter { $0.eventType.category == category }
    }
    
    // MARK: - Type-Safe Getters
    
    func visibleChatMessages() -> [ChatMessageEvent] {
        visibleEvents(ofType: .chatMessage).compactMap { $0.event as? ChatMessageEvent }
    }
    
    func visibleMatchGoals() -> [MatchGoalEvent] {
        visibleEvents(ofType: .matchGoal).compactMap { $0.event as? MatchGoalEvent }
    }
    
    func visiblePolls() -> [PollTimelineEvent] {
        visibleEvents(ofType: .poll).compactMap { $0.event as? PollTimelineEvent }
    }
    
    func visibleTweets() -> [TweetEvent] {
        visibleEvents(ofType: .tweet).compactMap { $0.event as? TweetEvent }
    }
    
    func visibleProducts() -> [ProductTimelineEvent] {
        visibleEvents(ofType: .productHighlight).compactMap { $0.event as? ProductTimelineEvent }
    }
    
    // MARK: - Backend Integration Helpers
    
    /// Export events for backend sync (JSON ready)
    func exportEventsForBackend() -> Data? {
        let exportData = allEvents.map { event in
            EventExportData(
                id: event.id,
                videoTimestamp: event.videoTimestamp,
                eventType: event.eventType.rawValue,
                metadata: event.metadata
            )
        }
        return try? JSONEncoder().encode(exportData)
    }
    
    /// Import events from backend
    func importEventsFromBackend(_ data: Data) throws {
        // TODO: Implement when backend structure is defined
        // Will decode JSON and create appropriate event objects
    }
}

// MARK: - Type-Erased Wrapper

/// Type-erased wrapper for storing different event types in same array
struct AnyTimelineEvent: Identifiable {
    let id: String
    let videoTimestamp: TimeInterval
    let eventType: TimelineEventType
    let displayPriority: Int
    let metadata: [String: String]?
    let event: Any  // Original typed event
    
    init<T: TimelineEvent>(_ event: T) {
        self.id = event.id
        self.videoTimestamp = event.videoTimestamp
        self.eventType = event.eventType
        self.displayPriority = event.displayPriority
        self.metadata = event.metadata
        self.event = event
    }
}

// MARK: - Backend Export Model

struct EventExportData: Codable {
    let id: String
    let videoTimestamp: TimeInterval
    let eventType: String
    let metadata: [String: String]?
}

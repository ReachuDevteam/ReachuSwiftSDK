//
//  LiveMatchViewModel.swift
//  Viaplay
//
//  ViewModel for LiveMatchView - handles business logic
//

import Foundation
import SwiftUI
import Combine

@MainActor
class LiveMatchViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var selectedTab: MatchTab = .all
    @Published var selectedMinute: Int? = nil
    @Published var useTimelineSync: Bool = true  // Toggle for timeline synchronization
    
    // MARK: - Timeline (NEW - Central source of truth)
    
    let timeline: UnifiedTimelineManager
    
    // MARK: - Managers
    
    let chatManager: ChatManager
    let matchSimulation: MatchSimulationManager
    let entertainmentManager: EntertainmentManager
    let playerViewModel: VideoPlayerViewModel
    
    // MARK: - Match Data
    
    let match: Match
    let matchStatistics: MatchStatistics
    let leagueTable: LeagueTable
    
    // MARK: - Computed Properties
    
    var matchTimeline: MatchTimeline {
        MatchTimeline(events: matchSimulation.events)
    }
    
    var currentFilterMinute: Int {
        selectedMinute ?? timeline.currentMinute
    }
    
    var currentVideoTime: TimeInterval {
        selectedMinute.map { TimeInterval($0 * 60) } ?? timeline.currentVideoTime
    }
    
    // MARK: - Initialization
    
    init(match: Match, useTimelineSync: Bool = true) {
        self.match = match
        self.matchStatistics = MatchStatistics.mock(for: match)
        self.leagueTable = LeagueTable.premierLeague
        self.useTimelineSync = useTimelineSync
        
        // Create unified timeline FIRST
        self.timeline = UnifiedTimelineManager()
        
        // Initialize managers with timeline
        self.chatManager = ChatManager(timeline: timeline)
        self.matchSimulation = MatchSimulationManager(timeline: timeline)
        self.entertainmentManager = EntertainmentManager(userId: "viaplay-user-123")
        self.playerViewModel = VideoPlayerViewModel()
        
        // Pre-load timeline with demo data
        if useTimelineSync {
            loadTimelineData()
        }
    }
    
    // MARK: - Lifecycle Methods
    
    func onAppear() {
        playerViewModel.setupPlayer()
        
        if useTimelineSync {
            // Timeline mode: events come from pre-loaded timeline
            chatManager.startSimulation(withTimeline: true)
            // Match simulation still runs to update currentMinute
            matchSimulation.startSimulation()
            
            // Start timeline playback
            startTimelinePlayback()
        } else {
            // Old mode: random simulation
            chatManager.startSimulation(withTimeline: false)
            matchSimulation.startSimulation()
        }
        
        Task {
            await entertainmentManager.loadComponents()
        }
    }
    
    func onDisappear() {
        playerViewModel.cleanup()
        chatManager.stopSimulation()
        matchSimulation.stopSimulation()
        stopTimelinePlayback()
    }
    
    // MARK: - Timeline Playback
    
    private var playbackTimer: Timer?
    
    private func startTimelinePlayback() {
        // Simulate video playback (advance 1 second every 0.1 seconds for demo speed)
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, self.selectedMinute == nil else { return }
            
            // Advance timeline by 1 second
            self.timeline.updateVideoTime(self.timeline.currentVideoTime + 1)
            
            // Update chat to show new visible messages
            self.chatManager.loadMessagesFromTimeline()
            
            // Stop at 90 minutes
            if self.timeline.currentMinute >= 90 {
                self.stopTimelinePlayback()
            }
        }
    }
    
    private func stopTimelinePlayback() {
        playbackTimer?.invalidate()
        playbackTimer = nil
    }
    
    // MARK: - Timeline Data Loading
    
    private func loadTimelineData() {
        // Load pre-generated timeline data
        let generatedEvents = TimelineDataGenerator.generateBarcelonaPSGTimeline()
        timeline.addEvents(generatedEvents.map { $0.event as! any TimelineEvent })
        
        // Initial load of visible messages
        chatManager.loadMessagesFromTimeline()
    }
    
    // MARK: - User Actions
    
    func handlePollVote(componentId: String, optionId: String) {
        Task {
            do {
                try await entertainmentManager.submitResponse(
                    componentId: componentId,
                    selectedOptions: [optionId]
                )
            } catch {
                print("❌ Error voting: \(error)")
            }
        }
    }
    
    func jumpToMinute(_ minute: Int) {
        selectedMinute = minute
        
        if useTimelineSync {
            timeline.jumpToMinute(minute)
            chatManager.loadMessagesFromTimeline()
            stopTimelinePlayback()  // Pause when user scrubs
        }
    }
    
    func goToLive() {
        selectedMinute = nil
        
        if useTimelineSync {
            timeline.goToLive(maxMinute: matchSimulation.currentMinute)
            chatManager.loadMessagesFromTimeline()
            startTimelinePlayback()  // Resume playback
        }
    }
    
    func selectTab(_ tab: MatchTab) {
        withAnimation {
            selectedTab = tab
        }
    }
    
    // MARK: - Content Filtering (Timeline-based)
    
    func filteredChatMessages() -> [ChatMessage] {
        if useTimelineSync {
            // Use timeline-synced messages
            return chatManager.messages.filter { $0.videoTimestamp <= currentVideoTime }
        } else {
            // Old estimation method
            return chatManager.messages.filter { message in
                let messageIndex = chatManager.messages.firstIndex(where: { $0.id == message.id }) ?? 0
                let estimatedMinute = (messageIndex * currentFilterMinute) / max(chatManager.messages.count, 1)
                return estimatedMinute <= currentFilterMinute
            }
        }
    }
    
    func filteredPolls() -> [InteractiveComponent] {
        if useTimelineSync {
            // Get polls from timeline
            let pollEvents = timeline.visiblePolls()
            // TODO: Convert PollTimelineEvent to InteractiveComponent
            return entertainmentManager.activeComponents.filter { $0.type == .poll }
        } else {
            return entertainmentManager.activeComponents.filter { component in
                guard component.type == .poll, let startTime = component.startTime else { return false }
                let timeDiff = Date().timeIntervalSince(startTime)
                let pollMinute = Int(timeDiff / 60)
                return pollMinute <= currentFilterMinute
            }
        }
    }
    
    func filteredEvents() -> [MatchEvent] {
        matchTimeline.events.filter { $0.minute <= currentFilterMinute }
    }
    
    // MARK: - Timeline-Specific Getters
    
    func visibleTimelineEvents() -> [AnyTimelineEvent] {
        guard useTimelineSync else { return [] }
        return timeline.visibleEvents
    }
    
    func visibleTimelineEvents(ofType type: TimelineEventType) -> [AnyTimelineEvent] {
        guard useTimelineSync else { return [] }
        return timeline.visibleEvents(ofType: type)
    }
    
    // MARK: - Mixed Content
    
    struct MixedContentItem: Identifiable {
        let id = UUID()
        let type: ContentType
        let timestamp: Date
        let event: MatchEvent?
        let chatMessage: ChatMessage?
        let poll: InteractiveComponent?
        let highlightIndex: Int?
        
        enum ContentType {
            case timelineEvent
            case chatMessage
            case poll
            case statistics
            case highlight
        }
    }
    
    func mixedContentItems() -> [MixedContentItem] {
        var items: [MixedContentItem] = []
        
        // Timeline events
        for event in filteredEvents().reversed() {
            items.append(MixedContentItem(
                type: MixedContentItem.ContentType.timelineEvent,
                timestamp: Date().addingTimeInterval(-Double((currentFilterMinute - event.minute) * 60)),
                event: event,
                chatMessage: nil,
                poll: nil,
                highlightIndex: nil
            ))
        }
        
        // Chat messages
        for message in filteredChatMessages() {
            items.append(MixedContentItem(
                type: MixedContentItem.ContentType.chatMessage,
                timestamp: message.timestamp,
                event: nil,
                chatMessage: message,
                poll: nil,
                highlightIndex: nil
            ))
        }
        
        // Polls
        for poll in filteredPolls() {
            items.append(MixedContentItem(
                type: MixedContentItem.ContentType.poll,
                timestamp: poll.startTime ?? Date(),
                event: nil,
                chatMessage: nil,
                poll: poll,
                highlightIndex: nil
            ))
        }
        
        // Highlights (every 10 minutes)
        for minute in stride(from: 10, through: currentFilterMinute, by: 10) {
            items.append(MixedContentItem(
                type: MixedContentItem.ContentType.highlight,
                timestamp: Date().addingTimeInterval(-Double((currentFilterMinute - minute) * 60)),
                event: nil,
                chatMessage: nil,
                poll: nil,
                highlightIndex: minute / 10
            ))
        }
        
        // Statistics (every 15 minutes)
        for minute in stride(from: 15, through: currentFilterMinute, by: 15) {
            items.append(MixedContentItem(
                type: MixedContentItem.ContentType.statistics,
                timestamp: Date().addingTimeInterval(-Double((currentFilterMinute - minute) * 60)),
                event: nil,
                chatMessage: nil,
                poll: nil,
                highlightIndex: nil
            ))
        }
        
        // Sort by timestamp (most recent first)
        return items.sorted { $0.timestamp > $1.timestamp }
    }
}

// MARK: - Match Tab Enum

enum MatchTab: String, CaseIterable {
    case all = "All"
    case chat = "Chat"
    case highlights = "Highlights"
    case liveScores = "Live Scores"
    case polls = "Polls"
    case statistics = "Statistics"
    
    var icon: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .chat: return "message"
        case .highlights: return "play.rectangle"
        case .liveScores: return "trophy"
        case .polls: return "clock"
        case .statistics: return "chart.bar"
        }
    }
}



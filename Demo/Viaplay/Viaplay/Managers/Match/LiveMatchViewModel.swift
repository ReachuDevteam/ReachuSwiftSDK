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
        // Simulate video playback (advance LIVE time ONLY)
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            let previousMinute = self.timeline.liveMinute
            
            // Always advance LIVE time (real-time broadcast position)
            self.timeline.updateLiveTime(self.timeline.liveVideoTime + 1)
            
            // ONLY reload chat when minute changes (reduce updates)
            if self.timeline.liveMinute != previousMinute {
                self.chatManager.loadMessagesFromTimeline()
            }
            
            // Stop at 105 minutes
            if self.timeline.liveMinute >= 105 {
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
        // Load rich Barcelona vs PSG timeline
        let generatedEvents = TimelineDataGenerator.generateBarcelonaPSGRichTimeline()
        
        print("📊 [LiveMatchViewModel] Loading rich timeline data...")
        print("📊 [LiveMatchViewModel] Total events generated: \(generatedEvents.count)")
        
        // Count by type
        let highlightCount = generatedEvents.filter { $0.eventType == .highlight }.count
        let chatCount = generatedEvents.filter { $0.eventType == .chatMessage }.count
        let tweetCount = generatedEvents.filter { $0.eventType == .tweet }.count
        let pollCount = generatedEvents.filter { $0.eventType == .poll }.count
        let commentaryCount = generatedEvents.filter { $0.eventType == .adminComment }.count
        let announcementCount = generatedEvents.filter { $0.eventType == .announcement }.count
        
        print("📊 [LiveMatchViewModel] Highlights: \(highlightCount)")
        print("📊 [LiveMatchViewModel] Chats: \(chatCount)")
        print("📊 [LiveMatchViewModel] Tweets: \(tweetCount)")
        print("📊 [LiveMatchViewModel] Polls: \(pollCount)")
        print("📊 [LiveMatchViewModel] Commentary: \(commentaryCount)")
        print("📊 [LiveMatchViewModel] Announcements: \(announcementCount)")
        
        // Show timestamp distribution
        let timestamps = generatedEvents.map { Int($0.videoTimestamp) }.sorted()
        print("📊 [LiveMatchViewModel] Timestamp range: \(timestamps.first ?? 0)s to \(timestamps.last ?? 0)s")
        print("📊 [LiveMatchViewModel] Events by minute:")
        for minute in stride(from: 0, through: 105, by: 15) {
            let eventsInRange = generatedEvents.filter {
                $0.videoTimestamp >= TimeInterval(minute * 60) &&
                $0.videoTimestamp < TimeInterval((minute + 15) * 60)
            }.count
            print("  \(minute)'-\(minute+15)': \(eventsInRange) events")
        }
        
        // Add all wrapped events at once
        timeline.addWrappedEvents(generatedEvents)
        
        print("📊 [LiveMatchViewModel] Timeline now has \(timeline.allEvents.count) events")
        
        // Initial load of visible messages
        chatManager.loadMessagesFromTimeline()
    }
    
    // MARK: - User Actions
    
    func handlePollVote(componentId: String, optionId: String) {
        // Poll voting now handled directly in TimelinePollCard
        print("📊 Usuario votó en poll \(componentId): opción \(optionId)")
        // TODO: Send to backend when integrated
    }
    
    func jumpToMinute(_ minute: Int) {
        selectedMinute = minute
        
        if useTimelineSync {
            let newTime = TimeInterval(minute * 60)
            
            print("⏩ [SCRUB] Jumped to \(minute)' (\(newTime)s)")
            
            // CRITICAL: Update currentVideoTime (not liveTime)
            // This controls what events are visible
            timeline.currentVideoTime = newTime
            
            // Reload chat for this position
            chatManager.loadMessagesFromTimeline()
            
            print("⏩ [SCRUB] Now showing \(timeline.visibleEvents.count) events")
            
            // Force complete UI refresh
            self.objectWillChange.send()
        }
    }
    
    func goToLive() {
        selectedMinute = nil
        
        if useTimelineSync {
            timeline.goToLive()  // Jump to live position
            chatManager.loadMessagesFromTimeline()
            // Playback already running, just sync position
        }
    }
    
    func selectTab(_ tab: MatchTab) {
        withAnimation {
            selectedTab = tab
        }
    }
    
    func sendChatMessage(_ text: String) {
        print("💬 [LiveMatchViewModel] Sending chat message: \(text)")
        print("💬 [LiveMatchViewModel] Current video time: \(timeline.currentVideoTime)s (\(timeline.currentMinute)')")
        
        let message = ChatMessage(
            username: "Angelo",  // TODO: Get from user profile
            text: text,
            usernameColor: Color(red: 0.96, green: 0.08, blue: 0.42),  // Viaplay pink
            likes: 0,
            timestamp: Date(),
            videoTimestamp: timeline.currentVideoTime
        )
        
        print("💬 [LiveMatchViewModel] Message created with timestamp: \(message.videoTimestamp)")
        
        // Add to ChatManager
        chatManager.addMessage(message)
        print("💬 [LiveMatchViewModel] Added to ChatManager. Total messages: \(chatManager.messages.count)")
        
        // Add to timeline if using sync
        if useTimelineSync {
            timeline.addEvent(message.toTimelineEvent())
            print("💬 [LiveMatchViewModel] Added to timeline. Total events: \(timeline.allEvents.count)")
            
            // Force reload messages from timeline
            chatManager.loadMessagesFromTimeline()
            print("💬 [LiveMatchViewModel] Reloaded from timeline. Visible messages: \(chatManager.messages.count)")
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
    
    func filteredPolls() -> [PollTimelineEvent] {
        // Get polls from timeline
        return timeline.visiblePolls()
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
        return timeline.visibleEvents.filter { $0.eventType == type }
    }
    
    func allTimelineEvents() -> [AnyTimelineEvent] {
        guard useTimelineSync else { return [] }
        return timeline.allEvents  // This is a property, not a function
    }
    
}

// MARK: - Match Tab Enum

enum MatchTab: String, CaseIterable {
    case all = "All"
    case chat = "Chat"
    case highlights = "Highlights"
    case statistics = "Statistics"
    case polls = "Interaktivt"  // Polls & Contests
    case liveScores = "Live Scores"
    
    var icon: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .chat: return "message"
        case .highlights: return "play.rectangle"
        case .liveScores: return "trophy"
        case .polls: return "hand.raised.fill"
        case .statistics: return "chart.bar"
        }
    }
}



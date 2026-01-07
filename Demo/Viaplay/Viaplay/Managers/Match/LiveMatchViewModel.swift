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
        selectedMinute ?? matchSimulation.currentMinute
    }
    
    // MARK: - Initialization
    
    init(match: Match) {
        self.match = match
        self.matchStatistics = MatchStatistics.mock(for: match)
        self.leagueTable = LeagueTable.premierLeague
        
        // Initialize managers
        self.chatManager = ChatManager()
        self.matchSimulation = MatchSimulationManager()
        self.entertainmentManager = EntertainmentManager(userId: "viaplay-user-123")
        self.playerViewModel = VideoPlayerViewModel()
    }
    
    // MARK: - Lifecycle Methods
    
    func onAppear() {
        playerViewModel.setupPlayer()
        chatManager.startSimulation()
        matchSimulation.startSimulation()
        
        Task {
            await entertainmentManager.loadComponents()
        }
    }
    
    func onDisappear() {
        playerViewModel.cleanup()
        chatManager.stopSimulation()
        matchSimulation.stopSimulation()
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
    }
    
    func goToLive() {
        selectedMinute = nil
    }
    
    func selectTab(_ tab: MatchTab) {
        withAnimation {
            selectedTab = tab
        }
    }
    
    // MARK: - Content Filtering
    
    func filteredChatMessages() -> [ChatMessage] {
        chatManager.messages.filter { message in
            let messageIndex = chatManager.messages.firstIndex(where: { $0.id == message.id }) ?? 0
            let estimatedMinute = (messageIndex * currentFilterMinute) / max(chatManager.messages.count, 1)
            return estimatedMinute <= currentFilterMinute
        }
    }
    
    func filteredPolls() -> [InteractiveComponent] {
        entertainmentManager.activeComponents.filter { component in
            guard component.type == .poll, let startTime = component.startTime else { return false }
            let timeDiff = Date().timeIntervalSince(startTime)
            let pollMinute = Int(timeDiff / 60)
            return pollMinute <= currentFilterMinute
        }
    }
    
    func filteredEvents() -> [MatchEvent] {
        matchTimeline.events.filter { $0.minute <= currentFilterMinute }
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



//
//  AllContentFeed.swift
//  Viaplay
//
//  Organism component: Mixed content feed (All tab)
//

import SwiftUI

struct AllContentFeed: View {
    let timelineEvents: [AnyTimelineEvent]
    let statistics: MatchStatistics
    let canChat: Bool
    let onPollVote: (String, String) -> Void
    let onSelectTab: (MatchTab) -> Void
    let onSendMessage: ((String) -> Void)?
    
    @State private var messageText = ""
    @FocusState private var isInputFocused: Bool
    
    init(
        timelineEvents: [AnyTimelineEvent],
        statistics: MatchStatistics,
        canChat: Bool = true,
        onPollVote: @escaping (String, String) -> Void,
        onSelectTab: @escaping (MatchTab) -> Void,
        onSendMessage: ((String) -> Void)? = nil
    ) {
        self.timelineEvents = timelineEvents
        self.statistics = statistics
        self.canChat = canChat
        self.onPollVote = onPollVote
        self.onSelectTab = onSelectTab
        self.onSendMessage = onSendMessage
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Events scroll view
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(timelineEvents, id: \.id) { wrappedEvent in
                        renderEvent(wrappedEvent)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, canChat ? 80 : 12)
            }
            
            // Chat input
            if canChat {
                ChatInputBar(
                    messageText: $messageText,
                    isFocused: $isInputFocused,
                    onSend: {
                        guard !messageText.isEmpty else { return }
                        onSendMessage?(messageText)
                        messageText = ""
                        isInputFocused = false
                    }
                )
            }
        }
        .background(Color(hex: "1B1B25"))
    }
    
    @ViewBuilder
    private func renderEvent(_ wrappedEvent: AnyTimelineEvent) -> some View {
        switch wrappedEvent.eventType {
        // Match events
        case .matchGoal, .matchCard, .matchSubstitution, .matchKickOff, .matchHalfTime, .matchFullTime:
            if let matchEvent = wrappedEvent.event as? MatchEvent {
                TimelineEventCard(event: matchEvent)
            } else {
                EmptyView()
            }
            
        // Chat
        case .chatMessage:
            if let chatEvent = wrappedEvent.event as? ChatMessageEvent {
                ChatMessageRow(
                    message: ChatMessage(
                        username: chatEvent.username,
                        text: chatEvent.text,
                        usernameColor: chatEvent.colorValue,
                        likes: chatEvent.likes,
                        timestamp: chatEvent.timestamp,
                        videoTimestamp: chatEvent.videoTimestamp
                    )
                )
            }
            
        // Admin comments
        case .adminComment:
            if let adminEvent = wrappedEvent.event as? AdminCommentEvent {
                AdminCommentCard(comment: adminEvent)
            }
            
        // Tweets
        case .tweet:
            if let tweetEvent = wrappedEvent.event as? TweetEvent {
                TweetCard(tweet: tweetEvent)
            }
            
        // Polls
        case .poll:
            // TODO: Convert PollTimelineEvent to InteractiveComponent for PollCard
            EmptyView()
            
        // Announcements
        case .announcement:
            if let announcement = wrappedEvent.event as? AnnouncementEvent {
                AnnouncementCard(announcement: announcement)
            }
            
        // Statistics
        case .statisticsUpdate:
            StatPreviewCard(
                statistics: statistics,
                onViewAll: { onSelectTab(.statistics) }
            )
            
        // Other types - add as needed
        default:
            EmptyView()
        }
    }
}

#Preview {
    AllContentFeed(
        timelineEvents: [],
        statistics: MatchStatistics.mock(for: Match.barcelonaPSG),
        onPollVote: { _, _ in },
        onSelectTab: { _ in }
    )
}



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
    @State private var keyboardHeight: CGFloat = 0
    
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
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 16) {
                        // Events oldest to newest (antiguos arriba, nuevos abajo)
                        ForEach(timelineEvents.sorted { $0.videoTimestamp < $1.videoTimestamp }, id: \.id) { wrappedEvent in
                            renderEvent(wrappedEvent)
                                .id(wrappedEvent.id)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .bottom).combined(with: .opacity),
                                    removal: .opacity
                                ))
                        }
                        
                        // Invisible anchor at bottom
                        Color.clear
                            .frame(height: 1)
                            .id("bottom")
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, canChat ? (80 + keyboardHeight) : 12)
                }
                .onAppear {
                    // Scroll to bottom on first appear
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
                .onAppear {
                    // Scroll to bottom on first appear
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
                .onChange(of: timelineEvents.count) { _ in
                    // Only scroll when count actually changes
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo("bottom", anchor: .bottom)
                        }
                    }
                }
                .onChange(of: keyboardHeight) { _ in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.easeOut(duration: 0.2)) {
                            proxy.scrollTo("bottom", anchor: .bottom)
                        }
                    }
                }
            }
            
            // Chat input - Fixed at bottom
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
        .onAppear {
            setupKeyboardObservers()
        }
        .onDisappear {
            removeKeyboardObservers()
        }
    }
    
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { notification in
            guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
            withAnimation(.easeOut(duration: 0.3)) {
                keyboardHeight = keyboardFrame.height
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { _ in
            withAnimation(.easeOut(duration: 0.3)) {
                keyboardHeight = 0
            }
        }
    }
    
    private func removeKeyboardObservers() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @ViewBuilder
    private func renderEvent(_ wrappedEvent: AnyTimelineEvent) -> some View {
        Group {
            switch wrappedEvent.eventType {
            // Match events
            case .matchGoal, .matchCard, .matchSubstitution, .matchKickOff, .matchHalfTime, .matchFullTime:
                if let matchEvent = wrappedEvent.event as? MatchEvent {
                    TimelineEventCard(event: matchEvent)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.9).combined(with: .opacity),
                            removal: .opacity
                        ))
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
                    // ChatMessageRow already has its own transition
                }
                
            // Admin comments & Commentary
            case .adminComment:
                // Try commentary first, then admin comment
                if let commentaryEvent = wrappedEvent.event as? CommentaryEvent {
                    CommentaryCard(commentary: commentaryEvent)
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .opacity
                        ))
                } else if let adminEvent = wrappedEvent.event as? AdminCommentEvent {
                    AdminCommentCard(comment: adminEvent)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .opacity
                        ))
                }
                
            // Tweets
            case .tweet:
                if let tweetEvent = wrappedEvent.event as? TweetEvent {
                    TweetCard(tweet: tweetEvent)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.95).combined(with: .opacity),
                            removal: .scale(scale: 0.95).combined(with: .opacity)
                        ))
                }
                
            // Polls
            case .poll:
                if let pollEvent = wrappedEvent.event as? PollTimelineEvent {
                    TimelinePollCard(
                        poll: pollEvent,
                        onVote: { optionId in
                            print("📊 Usuario votó: \(optionId) en poll: \(pollEvent.id)")
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.95).combined(with: .opacity),
                        removal: .opacity
                    ))
                }
                
            // Announcements (including contests, lineups, interviews, etc.)
            case .announcement:
                if let announcement = wrappedEvent.event as? AnnouncementEvent {
                    // Check metadata type for special rendering
                    switch announcement.metadata?["type"] {
                    case "contest":
                        ContestCard(
                            title: announcement.title.replacingOccurrences(of: "🏆 ", with: ""),
                            prize: announcement.metadata?["prize"] ?? "Premie",
                            onParticipate: {
                                print("🏆 Usuario participa!")
                            }
                        )
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.95).combined(with: .opacity),
                            removal: .opacity
                        ))
                        
                    case "lineup":
                        // Render lineup card
                        if let team = announcement.metadata?["team"],
                           let formation = announcement.metadata?["formation"],
                           let playersString = announcement.metadata?["players"] {
                            let playerNames = playersString.components(separatedBy: ",")
                            let players = playerNames.enumerated().map { index, name in
                                PlayerInfo(number: index + 1, name: name, position: "")
                            }
                            
                            LineupCard(
                                teamName: announcement.title.replacingOccurrences(of: "Oppstilling ", with: ""),
                                formation: formation,
                                players: players,
                                teamColor: team == "home" ? .blue : .red,
                                isHome: team == "home"
                            )
                            .transition(.asymmetric(
                                insertion: .move(edge: .top).combined(with: .opacity),
                                removal: .opacity
                            ))
                        }
                        
                    case "interview":
                        // Render interview card
                        PlayerInterviewCard(
                            playerName: announcement.metadata?["player"] ?? "",
                            playerPhoto: nil,
                            quote: announcement.message,
                            teamName: announcement.metadata?["team"] ?? ""
                        )
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading).combined(with: .opacity),
                            removal: .opacity
                        ))
                        
                    case "final-stats":
                        // Render final stats
                        FinalStatsCard(
                            statistics: statistics,
                            homeScore: 3,  // TODO: Get from match result
                            awayScore: 1
                        )
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.95).combined(with: .opacity),
                            removal: .opacity
                        ))
                        
                    case "prediction":
                        // Already handled as poll
                        EmptyView()
                        
                    default:
                        // Regular announcement
                        AnnouncementCard(announcement: announcement)
                            .transition(.asymmetric(
                                insertion: .move(edge: .top).combined(with: .opacity),
                                removal: .opacity
                            ))
                    }
                }
                
            // Statistics
            case .statisticsUpdate:
                StatPreviewCard(
                    statistics: statistics,
                    onViewAll: { onSelectTab(.statistics) }
                )
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.9).combined(with: .opacity),
                    removal: .opacity
                ))
                
            // Highlights with video
            case .highlight:
                if let highlightEvent = wrappedEvent.event as? HighlightTimelineEvent {
                    HighlightVideoCard(highlight: highlightEvent)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.95).combined(with: .opacity),
                            removal: .opacity
                        ))
                } else {
                    Text("DEBUG: Highlight event but cast failed")
                        .foregroundColor(.red)
                }
                
            // Other types - add as needed
            default:
                EmptyView()
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: wrappedEvent.id)
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



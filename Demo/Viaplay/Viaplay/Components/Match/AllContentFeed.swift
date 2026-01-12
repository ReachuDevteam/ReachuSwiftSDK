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
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, canChat ? (80 + keyboardHeight) : 12)
                }
                .onChange(of: timelineEvents.count) { _ in
                    scrollToBottom(proxy: proxy)
                }
                .onChange(of: timelineEvents.map { $0.id }) { _ in
                    // Update when events change (not just count)
                    scrollToBottom(proxy: proxy)
                }
                .onChange(of: keyboardHeight) { _ in
                    scrollToBottom(proxy: proxy, delay: 0.1)
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
    
    // MARK: - Helpers
    
    private func scrollToBottom(proxy: ScrollViewProxy, delay: TimeInterval = 0) {
        if let lastEvent = timelineEvents.sorted(by: { $0.videoTimestamp < $1.videoTimestamp }).last {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeOut(duration: 0.3)) {
                    proxy.scrollTo(lastEvent.id, anchor: .bottom)
                }
            }
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
                
            // Admin comments
            case .adminComment:
                if let adminEvent = wrappedEvent.event as? AdminCommentEvent {
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
                // TODO: Convert PollTimelineEvent to InteractiveComponent for PollCard
                EmptyView()
                
            // Announcements
            case .announcement:
                if let announcement = wrappedEvent.event as? AnnouncementEvent {
                    AnnouncementCard(announcement: announcement)
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .opacity
                        ))
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



//
//  AllContentFeed.swift
//  Viaplay
//
//  Organism component: Mixed content feed (All tab)
//

import SwiftUI

struct AllContentFeed: View {
    let items: [LiveMatchViewModel.MixedContentItem]
    let statistics: MatchStatistics
    let onPollVote: (String, String) -> Void
    let onSelectTab: (MatchTab) -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(items) { item in
                    switch item.type {
                    case .timelineEvent:
                        if let event = item.event {
                            TimelineEventCard(event: event)
                        }
                    case .chatMessage:
                        if let message = item.chatMessage {
                            ChatMessageRow(message: message)
                        }
                    case .poll:
                        if let poll = item.poll {
                            PollCard(
                                component: poll,
                                hasResponded: false, // TODO: Get from manager
                                onVote: { optionId in
                                    onPollVote(poll.id, optionId)
                                }
                            )
                        }
                    case .statistics:
                        StatPreviewCard(
                            statistics: statistics,
                            onViewAll: { onSelectTab(.statistics) }
                        )
                    case .highlight:
                        if let index = item.highlightIndex {
                            HighlightCard(index: index)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(hex: "1B1B25"))
    }
}

#Preview {
    AllContentFeed(
        items: [],
        statistics: MatchStatistics.mock(for: Match.barcelonaPSG),
        onPollVote: { _, _ in },
        onSelectTab: { _ in }
    )
}



//
//  MatchContentView.swift
//  Viaplay
//
//  Organism component: Match content router by selected tab
//

import SwiftUI

struct MatchContentView: View {
    let selectedTab: MatchTab
    @ObservedObject var viewModel: LiveMatchViewModel
    
    var body: some View {
        GeometryReader { geometry in
            Group {
                switch selectedTab {
                case .all:
                    if viewModel.useTimelineSync {
                        AllContentFeed(
                            timelineEvents: viewModel.visibleTimelineEvents(),
                            statistics: viewModel.matchStatistics,
                            canChat: true,
                            onPollVote: viewModel.handlePollVote,
                            onSelectTab: viewModel.selectTab,
                            onSendMessage: { text in
                                viewModel.sendChatMessage(text)
                            }
                        )
                    } else {
                        AllContentFeed(
                            timelineEvents: [],
                            statistics: viewModel.matchStatistics,
                            canChat: true,
                            onPollVote: viewModel.handlePollVote,
                            onSelectTab: viewModel.selectTab,
                            onSendMessage: { text in
                                viewModel.sendChatMessage(text)
                            }
                        )
                    }
                    
                case .chat:
                    ChatListView(
                        messages: viewModel.filteredChatMessages(),
                        viewerCount: viewModel.chatManager.viewerCount,
                        selectedMinute: viewModel.selectedMinute,
                        canChat: true,
                        onSendMessage: { text in
                            viewModel.sendChatMessage(text)
                        }
                    )
                    
                case .highlights:
                    // Same style as All, but filtered to highlight-worthy events
                    AllContentFeed(
                        timelineEvents: viewModel.timeline.visibleEvents.filter { event in
                            // Show all important match events + lineups
                            switch event.eventType {
                            case .matchGoal, .matchCard, .matchSubstitution,
                                 .highlight, .statisticsUpdate:
                                return true
                            case .adminComment:
                                // Show commentary for goals and cards
                                if let commentary = event.event as? CommentaryEvent {
                                    return commentary.isHighlighted || 
                                           commentary.commentaryType == .goal ||
                                           commentary.commentaryType == .card
                                }
                                return true
                            case .announcement:
                                // Include lineups, stats, and phase announcements
                                if let announcement = event.event as? AnnouncementEvent {
                                    let type = announcement.metadata?["type"]
                                    return type == "lineup" ||
                                           type == "halftime-stats" ||
                                           type == "fulltime-stats" ||
                                           type == "final-stats" ||
                                           type == "kickoff" ||
                                           type == "halftime" ||
                                           type == "fulltime"
                                }
                                return false
                            default:
                                return false
                            }
                        },
                        statistics: viewModel.matchStatistics,
                        canChat: false,
                        onPollVote: viewModel.handlePollVote,
                        onSelectTab: viewModel.selectTab,
                        onSendMessage: nil
                    )
                    
                case .liveScores:
                    LiveScoresListView()
                    
                case .polls:
                    PollsListView(
                        timelinePolls: viewModel.timeline.allEvents
                            .filter { $0.eventType == .poll }
                            .compactMap { $0.event as? PollTimelineEvent },
                        contests: viewModel.timeline.allEvents
                            .filter { $0.eventType == .announcement }
                            .compactMap { $0.event as? AnnouncementEvent }
                            .filter { $0.metadata?["type"] == "contest" },
                        timeline: viewModel.timeline
                    )
                    
                case .statistics:
                    MatchStatsView(statistics: viewModel.matchStatistics)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}

// MARK: - Live Scores List (Placeholder)

struct LiveScoresListView: View {
    // Sample matches with highlights
    private let sampleMatches: [LiveMatchData] = [
        LiveMatchData(
            id: "1",
            homeTeam: "Barcelona",
            awayTeam: "Real Madrid",
            homeScore: 3,
            awayScore: 2,
            minute: 87,
            isLive: true,
            competition: "Champions League",
            highlights: [
                MatchHighlightData(title: "MÅL: Lewandowski", minute: 23, videoURL: "https://firebasestorage.googleapis.com/v0/b/tipio-1ec97.appspot.com/o/1.MP4?alt=media&token=898b7836-5e27-492d-82bb-9d7bb50f9d66"),
                MatchHighlightData(title: "Stor sjanse!", minute: 45, videoURL: "https://firebasestorage.googleapis.com/v0/b/tipio-1ec97.appspot.com/o/2.MP4?alt=media&token=9011a94a-1085-4b69-bd41-3b1432ca577a"),
                MatchHighlightData(title: "Gult kort: Ramos", minute: 67, videoURL: "https://firebasestorage.googleapis.com/v0/b/tipio-1ec97.appspot.com/o/3.MP4?alt=media&token=f28dadf8-05df-4544-a21f-a4c45836793f")
            ]
        ),
        LiveMatchData(
            id: "2",
            homeTeam: "Manchester City",
            awayTeam: "Liverpool",
            homeScore: 1,
            awayScore: 1,
            minute: 72,
            isLive: true,
            competition: "Premier League",
            highlights: [
                MatchHighlightData(title: "MÅL: Haaland", minute: 34, videoURL: "https://firebasestorage.googleapis.com/v0/b/tipio-1ec97.appspot.com/o/1.MP4?alt=media&token=898b7836-5e27-492d-82bb-9d7bb50f9d66"),
                MatchHighlightData(title: "MÅL: Salah", minute: 56, videoURL: "https://firebasestorage.googleapis.com/v0/b/tipio-1ec97.appspot.com/o/2.MP4?alt=media&token=9011a94a-1085-4b69-bd41-3b1432ca577a")
            ]
        ),
        LiveMatchData(
            id: "3",
            homeTeam: "Bayern Munich",
            awayTeam: "PSG",
            homeScore: 2,
            awayScore: 0,
            minute: 90,
            isLive: false,
            competition: "Champions League",
            highlights: [
                MatchHighlightData(title: "MÅL: Müller", minute: 12, videoURL: "https://firebasestorage.googleapis.com/v0/b/tipio-1ec97.appspot.com/o/1.MP4?alt=media&token=898b7836-5e27-492d-82bb-9d7bb50f9d66"),
                MatchHighlightData(title: "MÅL: Sané", minute: 38, videoURL: "https://firebasestorage.googleapis.com/v0/b/tipio-1ec97.appspot.com/o/3.MP4?alt=media&token=f28dadf8-05df-4544-a21f-a4c45836793f")
            ]
        )
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                HStack {
                    Text("Live Resultater")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                        
                        Text("\(sampleMatches.filter { $0.isLive }.count) LIVE")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                
                // Match cards
                ForEach(sampleMatches) { match in
                    ExpandableLiveScoreCard(match: match)
                        .padding(.horizontal, 16)
                }
            }
            .padding(.vertical, 12)
        }
        .background(Color(hex: "1B1B25"))
    }
}

// MARK: - Live Score Item

private struct LiveScoreItem: View {
    let index: Int
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Team A")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                Spacer()
                HStack(spacing: 8) {
                    Text("\(index + 1)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    Circle()
                        .fill(Color.red)
                        .frame(width: 6, height: 6)
                    Text("\(index)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))
                }
                Spacer()
                Text("Team B")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
            }
            
            HStack {
                Text("Premier League")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
                Spacer()
                Text("\(45 + index)'")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
        .padding(.horizontal, 16)
    }
}

#Preview {
    MatchContentView_PreviewWrapper()
}

private struct MatchContentView_PreviewWrapper: View {
    @StateObject var viewModel = LiveMatchViewModel(match: Match.barcelonaPSG)
    var body: some View {
        MatchContentView(selectedTab: .all, viewModel: viewModel)
    }
}



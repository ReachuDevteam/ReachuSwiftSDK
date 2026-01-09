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
                            onPollVote: viewModel.handlePollVote,
                            onSelectTab: viewModel.selectTab
                        )
                    } else {
                        AllContentFeed(
                            timelineEvents: [],  // Fallback to old system
                            statistics: viewModel.matchStatistics,
                            onPollVote: viewModel.handlePollVote,
                            onSelectTab: viewModel.selectTab
                        )
                    }
                    
                case .chat:
                    ChatListView(
                        messages: viewModel.filteredChatMessages(),
                        viewerCount: viewModel.chatManager.viewerCount,
                        selectedMinute: viewModel.selectedMinute
                    )
                    
                case .highlights:
                    HighlightsListView(
                        goalEvents: viewModel.filteredEvents().filter {
                            if case .goal = $0.type { return true }
                            return false
                        },
                        currentMinute: viewModel.matchSimulation.currentMinute,
                        selectedMinute: viewModel.selectedMinute
                    )
                    
                case .liveScores:
                    LiveScoresListView()
                    
                case .polls:
                    PollsListView(
                        activePolls: viewModel.entertainmentManager.activeComponents.filter { $0.type == .poll },
                        completedPolls: viewModel.entertainmentManager.completedComponents.filter { $0.type == .poll },
                        upcomingPolls: viewModel.entertainmentManager.upcomingComponents.filter { $0.type == .poll },
                        hasResponded: viewModel.entertainmentManager.hasUserResponded,
                        onVote: viewModel.handlePollVote
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
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Live Scores")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                
                ForEach(0..<5) { index in
                    LiveScoreItem(index: index)
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



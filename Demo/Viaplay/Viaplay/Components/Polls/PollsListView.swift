//
//  PollsListView.swift
//  Viaplay
//
//  Organism component: Polls list
//

import SwiftUI

struct PollsListView: View {
    let timelinePolls: [PollTimelineEvent]
    let contests: [AnnouncementEvent]  // Contests from announcements
    @ObservedObject var timeline: UnifiedTimelineManager
    
    private var visiblePolls: [PollTimelineEvent] {
        timelinePolls.filter { $0.videoTimestamp <= timeline.currentVideoTime }
            .sorted { $0.videoTimestamp > $1.videoTimestamp }  // Newest first
    }
    
    private var visibleContests: [AnnouncementEvent] {
        contests.filter { $0.videoTimestamp <= timeline.currentVideoTime }
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    HStack {
                        Text("Avstemninger")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text("\(visiblePolls.count + visibleContests.count)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.white.opacity(0.1)))
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    
                    // Contests (same style)
                    ForEach(visibleContests, id: \.id) { contest in
                        ContestCard(
                            title: contest.title.replacingOccurrences(of: "🏆 ", with: ""),
                            prize: contest.metadata?["prize"] ?? "Premie",
                            onParticipate: {
                                print("🏆 Usuario participa!")
                            }
                        )
                        .padding(.horizontal, 16)
                        .id(contest.id)
                    }
                    
                    // Polls (same style as in All)
                    ForEach(visiblePolls) { poll in
                        TimelinePollCard(
                            poll: poll,
                            onVote: { optionId in
                                print("📊 Usuario votó: \(optionId)")
                            }
                        )
                        .padding(.horizontal, 16)
                        .id(poll.id)
                    }
                    
                    // Empty state
                    if visiblePolls.isEmpty && visibleContests.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "chart.bar")
                                .font(.system(size: 48))
                                .foregroundColor(.white.opacity(0.3))
                            
                            Text("Ingen avstemninger ennå")
                                .font(.system(size: 15))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 80)
                    }
                    
                    Color.clear
                        .frame(height: 1)
                        .id("bottom")
                }
                .padding(.vertical, 12)
            }
            .onChange(of: visiblePolls.count) { _ in
                if let last = visiblePolls.first {
                    withAnimation {
                        proxy.scrollTo(last.id, anchor: .top)
                    }
                }
            }
        }
        .background(Color(hex: "1B1B25"))
    }
}

#Preview {
    PollsListView(
        timelinePolls: [
            PollTimelineEvent(
                id: "poll-1",
                videoTimestamp: 600,
                question: "Hvem vinner denne kampen?",
                options: [
                    .init(id: "opt1", text: "Barcelona", voteCount: 3456, percentage: 65),
                    .init(id: "opt2", text: "Real Madrid", voteCount: 1234, percentage: 23)
                ],
                duration: 600,
                endTimestamp: 1200,
                metadata: nil
            )
        ],
        contests: [],
        timeline: UnifiedTimelineManager()
    )
}



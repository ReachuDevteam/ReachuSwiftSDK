//
//  PollsListView.swift
//  Viaplay
//
//  Organism component: Polls list
//

import SwiftUI

struct PollsListView: View {
    let activePolls: [InteractiveComponent]
    let completedPolls: [InteractiveComponent]
    let upcomingPolls: [InteractiveComponent]
    let hasResponded: (String) -> Bool
    let onVote: (String, String) -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Polls")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                
                // Active polls
                ForEach(activePolls) { component in
                    PollCard(
                        component: component,
                        hasResponded: hasResponded(component.id),
                        onVote: { optionId in
                            onVote(component.id, optionId)
                        }
                    )
                    .padding(.horizontal, 16)
                }
                
                // Completed polls
                ForEach(completedPolls) { component in
                    PollCard(
                        component: component,
                        hasResponded: true,
                        onVote: { _ in }
                    )
                    .padding(.horizontal, 16)
                    .opacity(0.6)
                }
                
                // Upcoming polls
                ForEach(upcomingPolls) { component in
                    PollCard(
                        component: component,
                        hasResponded: false,
                        onVote: { _ in }
                    )
                    .padding(.horizontal, 16)
                    .opacity(0.4)
                }
            }
            .padding(.vertical, 12)
        }
        .background(Color(hex: "1B1B25"))
    }
}

#Preview {
    PollsListView(
        activePolls: [
            InteractiveComponent(
                id: "poll-1",
                type: .poll,
                state: .active,
                title: "¿Cuál es tu equipo favorito?",
                interactionType: .singleChoice,
                options: [
                    InteractionOption(id: "opt1", text: "Real Madrid", value: "real"),
                    InteractionOption(id: "opt2", text: "Barcelona", value: "barca")
                ]
            )
        ],
        completedPolls: [],
        upcomingPolls: [],
        hasResponded: { _ in false },
        onVote: { _, _ in }
    )
}



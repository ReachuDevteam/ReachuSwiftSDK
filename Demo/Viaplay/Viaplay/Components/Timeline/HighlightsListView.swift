//
//  HighlightsListView.swift
//  Viaplay
//
//  Organism component: Highlights list
//

import SwiftUI

struct HighlightsListView: View {
    let goalEvents: [MatchEvent]
    let currentMinute: Int
    let selectedMinute: Int?
    
    private var displayMinute: Int {
        selectedMinute ?? currentMinute
    }
    
    private var title: String {
        if let minute = selectedMinute {
            return "Highlights at \(minute)'"
        }
        return "Highlights"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                
                // Goal highlights
                ForEach(Array(goalEvents.enumerated()), id: \.element.id) { index, event in
                    HighlightCard(event: event, index: index)
                        .padding(.horizontal, 16)
                }
                
                // Additional highlights every 10 minutes
                ForEach(Array(stride(from: 10, through: displayMinute, by: 10).enumerated()), id: \.offset) { index, minute in
                    HighlightCard(minute: minute, index: index + goalEvents.count)
                        .padding(.horizontal, 16)
                }
            }
            .padding(.vertical, 12)
        }
        .background(Color(hex: "1B1B25"))
    }
}

#Preview {
    HighlightsListView(
        goalEvents: [
            MatchEvent(minute: 13, type: .goal, player: "A. Diallo", team: .home, description: nil, score: "1-0"),
            MatchEvent(minute: 32, type: .goal, player: "B. Mbeumo", team: .home, description: nil, score: "2-0")
        ],
        currentMinute: 45,
        selectedMinute: nil
    )
}



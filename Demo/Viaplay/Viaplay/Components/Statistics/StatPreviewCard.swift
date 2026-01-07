//
//  StatPreviewCard.swift
//  Viaplay
//
//  Molecular component: Statistics preview card
//

import SwiftUI

struct StatPreviewCard: View {
    let statistics: MatchStatistics
    let maxStats: Int
    let onViewAll: () -> Void
    
    init(statistics: MatchStatistics, maxStats: Int = 3, onViewAll: @escaping () -> Void = {}) {
        self.statistics = statistics
        self.maxStats = maxStats
        self.onViewAll = onViewAll
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Statistics")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: onViewAll) {
                    Text("View All")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(red: 0.96, green: 0.08, blue: 0.42))
                }
            }
            
            VStack(spacing: 12) {
                ForEach(Array(statistics.stats.prefix(maxStats))) { stat in
                    StatBar(
                        name: stat.name,
                        homeValue: stat.homeValue,
                        awayValue: stat.awayValue,
                        unit: stat.unit
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
}

#Preview {
    StatPreviewCard(
        statistics: MatchStatistics.mock(for: Match.barcelonaPSG)
    )
    .padding()
    .background(Color(hex: "1B1B25"))
}



//
//  MatchCard.swift
//  Vg
//
//  Created by Angelo Sepulveda on 27/10/2025.
//

import SwiftUI

struct MatchCard: View {
    let match: Match
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Match Image
            ZStack(alignment: .bottomLeading) {
                AsyncImage(url: URL(string: match.imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(VGTheme.Colors.mediumGray)
                }
                .frame(height: 140)
                .frame(maxWidth: .infinity)
                .clipped()
                
                // VG+ Sport Badge
                if match.isVGPlus {
                    Text("VG+ Sport")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.8))
                        )
                        .padding(.leading, 6)
                        .padding(.bottom, 6)
                }
            }
            
            // Match Info
            VStack(alignment: .leading, spacing: 3) {
                Text(match.displayDate)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(VGTheme.Colors.textSecondary)
                
                Text("\(match.homeTeam) - \(match.awayTeam)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity)
        .background(VGTheme.Colors.black)
        .cornerRadius(VGTheme.CornerRadius.medium)
    }
}

#Preview {
    MatchCard(match: Match(
        homeTeam: "FC Porto",
        awayTeam: "Benfica",
        date: "I DAG",
        time: "21:05",
        imageUrl: "https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=400",
        isVGPlus: true
    ))
    .frame(width: 160, height: 220)
    .background(VGTheme.Colors.black)
}

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
                .frame(height: 180)
                .clipped()
                
                // VG+ Sport Badge
                if match.isVGPlus {
                    Text("VG+ Sport")
                        .font(VGTheme.Typography.caption())
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.7))
                        )
                        .padding(.leading, 8)
                        .padding(.bottom, 8)
                }
            }
            
            // Match Info
            VStack(alignment: .leading, spacing: 4) {
                Text(match.displayDate)
                    .font(VGTheme.Typography.caption())
                    .foregroundColor(VGTheme.Colors.textSecondary)
                
                Text("\(match.homeTeam) - \(match.awayTeam)")
                    .font(VGTheme.Typography.body())
                    .fontWeight(.semibold)
                    .foregroundColor(VGTheme.Colors.textPrimary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(VGTheme.Colors.darkGray)
        }
        .cornerRadius(VGTheme.CornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: VGTheme.CornerRadius.medium)
                .stroke(VGTheme.Colors.mediumGray, lineWidth: 1)
        )
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
    .frame(width: 180, height: 260)
    .background(VGTheme.Colors.black)
}

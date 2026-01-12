//
//  MatchHeaderView.swift
//  Viaplay
//
//  Molecular component: Match header with teams and score
//

import SwiftUI

struct MatchHeaderView: View {
    let match: Match
    let homeScore: Int
    let awayScore: Int
    let currentMinute: Int
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // Back button and sponsor in same row
            HStack {
                Button(action: onDismiss) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 16))
                    }
                    .foregroundColor(.white)
                }
                
                Spacer()
                
                // Sponsor (moved from below)
                HStack(spacing: 6) {
                    Text("Sponset av")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Image("logo1")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 16)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
            
            // Teams and Score
            HStack(spacing: 16) {
                TeamLogoView(
                    team: match.homeTeam,
                    imageUrl: "https://upload.wikimedia.org/wikipedia/en/thumb/4/47/FC_Barcelona_%28crest%29.svg/200px-FC_Barcelona_%28crest%29.svg.png"
                )
                .frame(maxWidth: .infinity)
                
                MatchScoreView(
                    homeScore: homeScore,
                    awayScore: awayScore,
                    currentMinute: currentMinute
                )
                
                TeamLogoView(
                    team: match.awayTeam,
                    imageUrl: "https://upload.wikimedia.org/wikipedia/en/thumb/a/a7/Paris_Saint-Germain_F.C..svg/200px-Paris_Saint-Germain_F.C..svg.png"
                )
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 16)
            
            // Match Details
            HStack(spacing: 16) {
                HStack(spacing: 6) {
                    Image(systemName: "soccerball")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                    Text(match.competition)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                HStack(spacing: 6) {
                    Image(systemName: "mappin.circle")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                    Text(match.venue)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 4)
        }
    }
}

#Preview {
    MatchHeaderView(
        match: Match.barcelonaPSG,
        homeScore: 0,
        awayScore: 0,
        currentMinute: 2,
        onDismiss: {}
    )
    .background(Color(hex: "1B1B25"))
}



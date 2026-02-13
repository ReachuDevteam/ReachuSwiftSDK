//
//  MatchHeaderView.swift
//  Viaplay
//
//  Molecular component: Match header with teams and score
//

import SwiftUI
import ReachuCore
import ReachuCastingUI

struct MatchHeaderView: View {
    let match: Match
    let homeScore: Int
    let awayScore: Int
    let currentMinute: Int
    let onDismiss: () -> Void
    
    @StateObject private var campaignManager = CampaignManager.shared
    
    var body: some View {
        VStack(spacing: 8) {
            // Sponsor and close button (same row)
            ZStack {
                // Sponsor (absolutely centered) - Campaign logo from CampaignManager
                VStack(spacing: 2) {
                    Text("Sponset av")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    
                    // Campaign logo; in demo mode use brand logo (Elkjøp, Skistar)
                    if let logoUrl = campaignManager.currentCampaign?.campaignLogo, let url = URL(string: logoUrl),
                       !ReachuConfiguration.shared.engagementConfiguration.demoMode {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(height: 18)
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: 18)
                            case .failure:
                                brandLogoImage
                            @unknown default:
                                brandLogoImage
                            }
                        }
                    } else {
                        brandLogoImage
                    }
                }
                
                // Close button (positioned right)
                HStack {
                    Spacer()
                    
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.1))
                            )
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 5)
            
            // Teams and Score (smaller logos)
            HStack(spacing: 12) {
                TeamLogoView(
                    team: match.homeTeam,
                    size: 50,
                    imageUrl: nil  // Uses team.logo asset (barcelona_logo)
                )
                .frame(maxWidth: .infinity)
                
                MatchScoreView(
                    homeScore: homeScore,
                    awayScore: awayScore,
                    currentMinute: currentMinute
                )
                
                TeamLogoView(
                    team: match.awayTeam,
                    size: 50,
                    imageUrl: nil  // Uses team.logo asset (psg_logo)
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
    
    private var brandLogoImage: some View {
        Image(ReachuConfiguration.shared.effectiveBrandConfiguration.iconAsset)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: 18)
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



//
//  LineupCard.swift
//  Viaplay
//
//  Modular component: Team lineup display
//  Reusable for any team, any match
//

import SwiftUI

struct LineupCard: View {
    let teamName: String
    let formation: String
    let players: [PlayerInfo]
    let teamColor: Color
    let isHome: Bool
    
    init(
        teamName: String,
        formation: String,
        players: [PlayerInfo],
        teamColor: Color = .blue,
        isHome: Bool = true
    ) {
        self.teamName = teamName
        self.formation = formation
        self.players = players
        self.teamColor = teamColor
        self.isHome = isHome
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 8) {
                // Team indicator
                Circle()
                    .fill(teamColor)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text(isHome ? "H" : "A")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(teamName)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 4) {
                        Text("Oppstilling")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text("•")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.4))
                        
                        Text("Formasjon: \(formation)")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                Spacer()
                
                // XXL sponsor
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Sponset av")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Image("logo1")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 50, maxHeight: 16)
                }
            }
            
            // Players grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(players.prefix(11), id: \.number) { player in
                    PlayerRow(player: player, teamColor: teamColor)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    teamColor.opacity(0.4),
                                    teamColor.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
}

// MARK: - Player Row

private struct PlayerRow: View {
    let player: PlayerInfo
    let teamColor: Color
    
    var body: some View {
        HStack(spacing: 6) {
            // Number badge
            Text("\(player.number)")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(Circle().fill(teamColor.opacity(0.3)))
            
            // Player name
            Text(player.name)
                .font(.system(size: 12))
                .foregroundColor(.white)
                .lineLimit(1)
            
            Spacer(minLength: 0)
        }
    }
}

// MARK: - Player Info Model

struct PlayerInfo: Identifiable {
    let id = UUID()
    let number: Int
    let name: String
    let position: String  // "Keeper", "Forsvar", "Midtbane", "Angrep"
}

#Preview {
    VStack(spacing: 16) {
        LineupCard(
            teamName: "FC Barcelona",
            formation: "4-3-3",
            players: [
                PlayerInfo(number: 1, name: "Ter Stegen", position: "Keeper"),
                PlayerInfo(number: 2, name: "Koundé", position: "Forsvar"),
                PlayerInfo(number: 3, name: "Araújo", position: "Forsvar"),
                PlayerInfo(number: 4, name: "Christensen", position: "Forsvar"),
                PlayerInfo(number: 18, name: "Alba", position: "Forsvar"),
                PlayerInfo(number: 5, name: "Busquets", position: "Midtbane"),
                PlayerInfo(number: 21, name: "De Jong", position: "Midtbane"),
                PlayerInfo(number: 8, name: "Pedri", position: "Midtbane"),
                PlayerInfo(number: 10, name: "Dembélé", position: "Angrep"),
                PlayerInfo(number: 9, name: "Lewandowski", position: "Angrep"),
                PlayerInfo(number: 7, name: "Ferran", position: "Angrep")
            ],
            teamColor: .blue,
            isHome: true
        )
    }
    .padding()
    .background(Color.black)
}

//
//  MatchModels.swift
//  Vg
//
//  Created by Angelo Sepulveda on 27/10/2025.
//

import Foundation

struct Match: Identifiable {
    let id = UUID()
    let homeTeam: String
    let awayTeam: String
    let date: String
    let time: String
    let imageUrl: String
    let isVGPlus: Bool
    
    var displayDate: String {
        return "\(date) \(time)"
    }
}

struct MatchSection: Identifiable {
    let id = UUID()
    let title: String
    let matches: [Match]
}

// MARK: - Mock Data
extension Match {
    static let mockMatches: [MatchSection] = [
        MatchSection(
            title: "Liga Portugal",
            matches: [
                Match(
                    homeTeam: "Moreirense",
                    awayTeam: "FC Porto",
                    date: "I DAG",
                    time: "21:05",
                    imageUrl: "https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=400",
                    isVGPlus: true
                ),
                Match(
                    homeTeam: "Sporting CP",
                    awayTeam: "FC Alv",
                    date: "FREDAG",
                    time: "21:05",
                    imageUrl: "https://images.unsplash.com/photo-1431324155629-1a6deb1dec8d?w=400",
                    isVGPlus: true
                )
            ]
        ),
        MatchSection(
            title: "DFB Pokal",
            matches: [
                Match(
                    homeTeam: "Eintracht Frankfurt",
                    awayTeam: "Borussia Dortmund",
                    date: "I MORGEN",
                    time: "18:20",
                    imageUrl: "https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=400",
                    isVGPlus: true
                ),
                Match(
                    homeTeam: "Heidenheim",
                    awayTeam: "Hamb",
                    date: "I MORGEN",
                    time: "18:20",
                    imageUrl: "https://images.unsplash.com/photo-1431324155629-1a6deb1dec8d?w=400",
                    isVGPlus: true
                )
            ]
        ),
        MatchSection(
            title: "Coppa Italia",
            matches: [
                Match(
                    homeTeam: "Juventus",
                    awayTeam: "AC Milan",
                    date: "TIRSDAG",
                    time: "20:45",
                    imageUrl: "https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=400",
                    isVGPlus: true
                ),
                Match(
                    homeTeam: "Inter Milan",
                    awayTeam: "Lazio",
                    date: "TIRSDAG",
                    time: "20:45",
                    imageUrl: "https://images.unsplash.com/photo-1431324155629-1a6deb1dec8d?w=400",
                    isVGPlus: true
                )
            ]
        )
    ]
}

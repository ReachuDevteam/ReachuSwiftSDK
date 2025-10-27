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
            title: "Tidligere sendinger",
            matches: [
                Match(
                    homeTeam: "New Orleans Saints",
                    awayTeam: "Tampa Bay",
                    date: "I GÅR",
                    time: "20:55",
                    imageUrl: "https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=400",
                    isVGPlus: true
                ),
                Match(
                    homeTeam: "Lazio",
                    awayTeam: "Juventus",
                    date: "I GÅR",
                    time: "20:30",
                    imageUrl: "https://images.unsplash.com/photo-1431324155629-1a6deb1dec8d?w=400",
                    isVGPlus: true
                )
            ]
        ),
        MatchSection(
            title: "NFL",
            matches: [
                Match(
                    homeTeam: "NFL RedZone",
                    awayTeam: "Week 9",
                    date: "SØNDAG",
                    time: "18:50",
                    imageUrl: "https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=400",
                    isVGPlus: true
                ),
                Match(
                    homeTeam: "Detroit Lions",
                    awayTeam: "Minnesota Vikings",
                    date: "SØNDAG",
                    time: "18:50",
                    imageUrl: "https://images.unsplash.com/photo-1431324155629-1a6deb1dec8d?w=400",
                    isVGPlus: true
                )
            ]
        ),
        MatchSection(
            title: "Women's Super League",
            matches: [
                Match(
                    homeTeam: "Chelsea",
                    awayTeam: "Arsenal",
                    date: "SØNDAG",
                    time: "15:00",
                    imageUrl: "https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=400",
                    isVGPlus: true
                ),
                Match(
                    homeTeam: "Manchester City",
                    awayTeam: "Tottenham",
                    date: "SØNDAG",
                    time: "17:30",
                    imageUrl: "https://images.unsplash.com/photo-1431324155629-1a6deb1dec8d?w=400",
                    isVGPlus: true
                )
            ]
        )
    ]
}

//
//  MatchModels.swift
//  Viaplay
//
//  Created by Angelo Sepulveda on 27/10/2025.
//

import Foundation

// MARK: - Match Model
struct Match: Identifiable {
    let id = UUID()
    let homeTeam: Team
    let awayTeam: Team
    let title: String
    let subtitle: String
    let competition: String
    let venue: String
    let commentator: String?
    let isLive: Bool
    let backgroundImage: String
    let availability: MatchAvailability
    let relatedContent: [RelatedTeam]
    let campaignLogo: String?
}

// MARK: - Team Model
struct Team: Identifiable {
    let id = UUID()
    let name: String
    let shortName: String
    let logo: String
}

// MARK: - Match Availability
enum MatchAvailability {
    case available
    case availableUntil(date: String)
    case upcoming(date: String)
    
    var title: String {
        switch self {
        case .available:
            return "Tilgjengelighet"
        case .availableUntil:
            return "Tilgjengelighet"
        case .upcoming:
            return "Kommer snart"
        }
    }
    
    var description: String {
        switch self {
        case .available:
            return "Tilgjengelig nå"
        case .availableUntil:
            return "Tilgjengelig lenger enn ett år"
        case .upcoming(let date):
            return date
        }
    }
}

// MARK: - Related Team
struct RelatedTeam: Identifiable {
    let id = UUID()
    let team: Team
    let description: String?
}

// MARK: - Mock Data
extension Match {
    static let barcelonaPSG = Match(
        homeTeam: Team(
            name: "FC Barcelona",
            shortName: "Barcelona",
            logo: "barcelona_logo"
        ),
        awayTeam: Team(
            name: "Paris Saint-Germain",
            shortName: "PSG",
            logo: "psg_logo"
        ),
        title: "Barcelona - PSG",
        subtitle: "UEFA Champions League • Fotball",
        competition: "UEFA Champions League",
        venue: "Camp Nou",
        commentator: "Magnus Drivenes",
        isLive: true,
        backgroundImage: "img1",
        availability: .available,
        relatedContent: [
            RelatedTeam(
                team: Team(name: "FC Barcelona", shortName: "Barcelona", logo: "barcelona_logo"),
                description: nil
            ),
            RelatedTeam(
                team: Team(name: "Paris Saint-Germain", shortName: "PSG", logo: "psg_logo"),
                description: nil
            )
        ],
        campaignLogo: "https://upload.wikimedia.org/wikipedia/commons/thumb/2/24/Adidas_logo.png/800px-Adidas_logo.png"
    )
    
    static let mockMatches: [Match] = [
        barcelonaPSG,
        Match(
            homeTeam: Team(name: "Manchester City", shortName: "City", logo: "city_logo"),
            awayTeam: Team(name: "Real Madrid", shortName: "Madrid", logo: "madrid_logo"),
            title: "Man City - Real Madrid",
            subtitle: "UEFA Champions League • Fotball",
            competition: "UEFA Champions League",
            venue: "Etihad Stadium",
            commentator: "Øyvind Alsaker",
            isLive: true,
            backgroundImage: "img1",
            availability: .available,
            relatedContent: [],
            campaignLogo: nil
        )
    ]
}

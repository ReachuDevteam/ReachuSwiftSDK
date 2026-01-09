//
//  TimelineDataGenerator.swift
//  Viaplay
//
//  Pre-generated timeline data for Barcelona - PSG match
//  All events synchronized with video timestamps
//

import Foundation
import SwiftUI

struct TimelineDataGenerator {
    
    /// Generate complete timeline for Barcelona - PSG match
    static func generateBarcelonaPSGTimeline() -> [AnyTimelineEvent] {
        var events: [AnyTimelineEvent] = []
        
        // MARK: - Match Events
        
        // 0' - Kick Off
        events.append(AnyTimelineEvent(MatchGoalEvent(
            id: "kickoff",
            videoTimestamp: 0,
            player: "",
            team: .home,
            score: "0-0",
            assistBy: nil,
            isOwnGoal: false,
            isPenalty: false,
            metadata: ["event": "kickoff"]
        )))
        
        // 5' - Substitution
        events.append(AnyTimelineEvent(MatchSubstitutionEvent(
            id: "sub-5",
            videoTimestamp: 300,  // 5 * 60
            playerIn: "A. Scott",
            playerOut: "T. Adams",
            team: .away,
            metadata: nil
        )))
        
        // 13' - GOL A. Diallo
        events.append(AnyTimelineEvent(MatchGoalEvent(
            id: "goal-13",
            videoTimestamp: 780,  // 13 * 60
            player: "A. Diallo",
            team: .home,
            score: "1-0",
            assistBy: "Bruno Fernandes",
            isOwnGoal: false,
            isPenalty: false,
            metadata: nil
        )))
        
        // 18' - Yellow Card
        events.append(AnyTimelineEvent(MatchCardEvent(
            id: "card-18",
            videoTimestamp: 1080,  // 18 * 60
            player: "Casemiro",
            team: .home,
            cardType: .yellow,
            reason: "Falta táctica",
            metadata: nil
        )))
        
        // 25' - Yellow Card
        events.append(AnyTimelineEvent(MatchCardEvent(
            id: "card-25",
            videoTimestamp: 1500,  // 25 * 60
            player: "M. Tavernier",
            team: .away,
            cardType: .yellow,
            reason: nil,
            metadata: nil
        )))
        
        // 32' - GOL B. Mbeumo
        events.append(AnyTimelineEvent(MatchGoalEvent(
            id: "goal-32",
            videoTimestamp: 1920,  // 32 * 60
            player: "B. Mbeumo",
            team: .home,
            score: "2-0",
            assistBy: "Diogo Dalot",
            isOwnGoal: false,
            isPenalty: false,
            metadata: nil
        )))
        
        // 45' - Half Time
        events.append(AnyTimelineEvent(AnnouncementEvent(
            id: "halftime",
            videoTimestamp: 2700,  // 45 * 60
            title: "Pause",
            message: "Første omgang ferdig",
            imageUrl: nil,
            actionUrl: nil,
            actionText: nil,
            metadata: ["type": "halftime"]
        )))
        
        // MARK: - Chat Messages (Sincronizados con eventos)
        
        // 0'45" - Chat inicial
        events.append(AnyTimelineEvent(ChatMessageEvent(
            videoTimestamp: 45,
            username: "SportsFan23",
            text: "Endelig! La oss gå! 🔥",
            usernameColor: .cyan
        )))
        
        events.append(AnyTimelineEvent(ChatMessageEvent(
            videoTimestamp: 90,
            username: "MatchMaster",
            text: "Dette blir en god kamp!",
            usernameColor: .orange
        )))
        
        // 2' - Chats tempranos
        events.append(AnyTimelineEvent(ChatMessageEvent(
            videoTimestamp: 120,
            username: "GoalKeeper",
            text: "Vamos Barcelona! 💪",
            usernameColor: .green
        )))
        
        // 5'30" - Después del cambio
        events.append(AnyTimelineEvent(ChatMessageEvent(
            videoTimestamp: 330,
            username: "TacticsGuru",
            text: "Interessant bytte så tidlig",
            usernameColor: .teal
        )))
        
        // 13'05" - JUSTO DESPUÉS DEL GOL
        events.append(AnyTimelineEvent(ChatMessageEvent(
            videoTimestamp: 785,
            username: "FutbolLoco",
            text: "GOOOOOL!!! 🎉🎉🎉",
            usernameColor: .yellow,
            likes: 45
        )))
        
        events.append(AnyTimelineEvent(ChatMessageEvent(
            videoTimestamp: 787,
            username: "TeamCaptain",
            text: "Hvilken pasning fra Bruno!",
            usernameColor: .red,
            likes: 32
        )))
        
        events.append(AnyTimelineEvent(ChatMessageEvent(
            videoTimestamp: 790,
            username: "DefenderPro",
            text: "Utrolig avslutning! ⚽",
            usernameColor: .blue,
            likes: 28
        )))
        
        // 15' - Chat durante el partido
        events.append(AnyTimelineEvent(ChatMessageEvent(
            videoTimestamp: 900,
            username: "StrikerKing",
            text: "Barcelona dominerer helt",
            usernameColor: .pink
        )))
        
        // 20' - Más chats
        events.append(AnyTimelineEvent(ChatMessageEvent(
            videoTimestamp: 1200,
            username: "CoachView",
            text: "Taktikken fungerer perfekt",
            usernameColor: .indigo
        )))
        
        // 32'10" - DESPUÉS DEL SEGUNDO GOL
        events.append(AnyTimelineEvent(ChatMessageEvent(
            videoTimestamp: 1930,
            username: "UltrasGroup",
            text: "ENDA ET MÅL!!! 🔥🔥",
            usernameColor: .red,
            likes: 67
        )))
        
        events.append(AnyTimelineEvent(ChatMessageEvent(
            videoTimestamp: 1935,
            username: "FanZone",
            text: "Dette er gull!",
            usernameColor: .orange,
            likes: 54
        )))
        
        // MARK: - Polls (en momentos específicos)
        
        // 10' - Poll sobre resultado
        events.append(AnyTimelineEvent(PollTimelineEvent(
            id: "poll-10",
            videoTimestamp: 600,  // 10 minutos
            question: "Hvem vinner denne kampen?",
            options: [
                .init(id: "opt1", text: "Barcelona", voteCount: 3456, percentage: 65),
                .init(id: "opt2", text: "PSG", voteCount: 1234, percentage: 23),
                .init(id: "opt3", text: "Uavgjort", voteCount: 645, percentage: 12)
            ],
            duration: 600,  // Active for 10 minutes
            endTimestamp: 1200,  // Closes at minute 20
            metadata: nil
        )))
        
        // 30' - Poll sobre MVP
        events.append(AnyTimelineEvent(PollTimelineEvent(
            id: "poll-30",
            videoTimestamp: 1800,  // 30 minutos
            question: "Hvem er best så langt?",
            options: [
                .init(id: "opt1", text: "A. Diallo", voteCount: 2345, percentage: 45),
                .init(id: "opt2", text: "Bruno Fernandes", voteCount: 1789, percentage: 34),
                .init(id: "opt3", text: "B. Mbeumo", voteCount: 1098, percentage: 21)
            ],
            duration: 600,
            endTimestamp: 2400,
            metadata: nil
        )))
        
        // MARK: - Tweets (en momentos clave)
        
        // 13'30" - Tweet de un jugador
        events.append(AnyTimelineEvent(TweetEvent(
            id: "tweet-13",
            videoTimestamp: 810,
            authorName: "Erling Haaland",
            authorHandle: "@ErlingHaaland",
            authorAvatar: "https://pbs.twimg.com/profile_images/...",
            tweetText: "Alltid klar for neste mål! ⚽🎯 #ChampionsLeague",
            isVerified: true,
            likes: 12340,
            retweets: 3456,
            metadata: nil
        )))
        
        // MARK: - Products (en momentos específicos)
        
        // 20' - Product highlight
        events.append(AnyTimelineEvent(ProductTimelineEvent(
            id: "product-20",
            videoTimestamp: 1200,
            productId: "408874",
            productName: "Paris Saint Germain Hjemmedrakt 2025/26",
            productImage: "https://...",
            price: "999.00",
            currency: "NOK",
            duration: 30,  // Show for 30 seconds
            metadata: nil
        )))
        
        // MARK: - Admin Comments (comentarios importantes)
        
        // 13'15" - Admin comment sobre el gol
        events.append(AnyTimelineEvent(AdminCommentEvent(
            id: "admin-13",
            videoTimestamp: 795,
            adminName: "Kommentator",
            comment: "Nydelig mål! Dette er Champions League på sitt beste!",
            isPinned: true,
            metadata: nil
        )))
        
        // MARK: - Statistics Updates
        
        // 15' - Stats update
        events.append(AnyTimelineEvent(StatisticsUpdateEvent(
            id: "stats-15",
            videoTimestamp: 900,
            statName: "Ball i besittelse",
            homeValue: 58.5,
            awayValue: 41.5,
            metadata: nil
        )))
        
        // 30' - Stats update
        events.append(AnyTimelineEvent(StatisticsUpdateEvent(
            id: "stats-30",
            videoTimestamp: 1800,
            statName: "Skudd på mål",
            homeValue: 5,
            awayValue: 2,
            metadata: nil
        )))
        
        return events.sorted { $0.videoTimestamp < $1.videoTimestamp }
    }
    
    /// Generate random chat messages throughout the match
    static func generateRandomChatMessages(count: Int = 50, maxMinute: Int = 90) -> [ChatMessageEvent] {
        let users: [(String, Color)] = [
            ("SportsFan23", .cyan),
            ("MatchMaster", .orange),
            ("TeamCaptain", .red),
            ("FutbolLoco", .yellow),
            ("DefenderPro", .blue),
            ("StrikerKing", .pink),
            ("CoachView", .indigo),
            ("TacticsGuru", .teal)
        ]
        
        let messages = [
            "Hvilket mål! 🔥",
            "For en redning!",
            "UTROLIG SPILL!!!",
            "Forsvaret sover...",
            "KOM IGJEN! 💪",
            "Nydelig pasning",
            "Keeperen er på et annet nivå",
            "SKYT!",
            "Perfekt posisjonering",
            "Denne kampen er gal",
            "Vi trenger mål nå",
            "Beste kampen denne sesongen",
            "FOR EN PASNING!",
            "Utrolig ballkontroll",
            "Perfekt timing",
            "Dette blir episk",
            "KJØR PÅ!!!",
            "Hvilken spilling!",
            "Fantastisk lagspill",
            "Publikum er tent 🔥"
        ]
        
        var chatEvents: [ChatMessageEvent] = []
        
        for i in 0..<count {
            let user = users.randomElement()!
            let text = messages.randomElement()!
            let minute = Int.random(in: 0...maxMinute)
            let seconds = TimeInterval(minute * 60 + Int.random(in: 0...59))
            
            let event = ChatMessageEvent(
                id: "chat-\(i)",
                videoTimestamp: seconds,
                username: user.0,
                text: text,
                usernameColor: user.1,
                likes: Int.random(in: 0...15)
            )
            
            chatEvents.append(event)
        }
        
        return chatEvents.sorted { $0.videoTimestamp < $1.videoTimestamp }
    }
}

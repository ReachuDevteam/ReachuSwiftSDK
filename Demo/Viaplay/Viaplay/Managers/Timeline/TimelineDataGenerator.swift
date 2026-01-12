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
        
        // 0' - Kick Off (Announcement style)
        events.append(AnyTimelineEvent(AnnouncementEvent(
            id: "kickoff",
            videoTimestamp: 0,
            title: "⚽ Avspark",
            message: "Kampen starter! Barcelona vs PSG",
            imageUrl: nil,
            actionUrl: nil,
            actionText: nil,
            metadata: ["type": "kickoff"]
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
        
        // 13' - GOL A. Diallo + Commentary
        events.append(AnyTimelineEvent(MatchGoalEvent(
            id: "goal-13",
            videoTimestamp: 780,
            player: "A. Diallo",
            team: .home,
            score: "1-0",
            assistBy: "Bruno Fernandes",
            isOwnGoal: false,
            isPenalty: false,
            metadata: nil
        )))
        
        // Goal commentary (sin crear el evento, ya usaremos admin comment existente)
        
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
        
        // 44' - Before halftime
        events.append(AnyTimelineEvent(CommentaryEvent(
            id: "comm-44",
            videoTimestamp: 2640,
            minute: 44,
            text: "Dean Huijsen (Real Madrid) finds some space inside the box to connect with the resulting corner kick. He sends a fine header towards the top right corner, but one of the defenders deflect it onto the post. Maybe next time.",
            commentaryType: .corner,
            isHighlighted: false,
            metadata: nil
        )))
        
        // 45' - Goal commentary
        events.append(AnyTimelineEvent(CommentaryEvent(
            id: "comm-45-goal",
            videoTimestamp: 2700,
            minute: 45,
            text: "Goal! Pedri gets to the ball, slips Robert Lewandowski (Barcelona) into the area and he scores with a delightful chipped finish to make it 2-1.",
            commentaryType: .goal,
            isHighlighted: true,
            metadata: nil
        )))
        
        // 45+6' - Chance
        events.append(AnyTimelineEvent(CommentaryEvent(
            id: "comm-45-6-chance",
            videoTimestamp: 2760,
            minute: 45,
            text: "Gonzalo Garcia (Real Madrid) is the first to get to a rebound inside the penalty area and his weak, but precise effort finds its way into the back of the net, bouncing in off the crossbar.",
            commentaryType: .goal,
            isHighlighted: true,
            metadata: nil
        )))
        
        // 45+8' - Halftime
        events.append(AnyTimelineEvent(CommentaryEvent(
            id: "comm-45-8",
            videoTimestamp: 2780,
            minute: 45,
            text: "3 min. of stoppage-time to be played.",
            commentaryType: .halftime,
            isHighlighted: false,
            metadata: nil
        )))
        
        // 45' - Half Time
        events.append(AnyTimelineEvent(AnnouncementEvent(
            id: "halftime",
            videoTimestamp: 2700,
            title: "Pause",
            message: "Første omgang ferdig",
            imageUrl: nil,
            actionUrl: nil,
            actionText: nil,
            metadata: ["type": "halftime"]
        )))
        
        // MARK: - Chat Messages (Sincronizados con eventos)
        
        // MARK: - Pre-Match & Commentary
        
        // Pre-match
        events.append(AnyTimelineEvent(CommentaryEvent(
            id: "comm-prematch",
            videoTimestamp: 10,
            minute: 0,
            text: "Hello, welcome to our live play-by-play commentaries. You will be able to see a written form of all the interesting moments of the game, so you won't miss a thing. Sit back and have fun.",
            commentaryType: .general,
            isHighlighted: false,
            metadata: nil
        )))
        
        events.append(AnyTimelineEvent(CommentaryEvent(
            id: "comm-lineups",
            videoTimestamp: 30,
            minute: 0,
            text: "Before the start of the game, you can see the starting lineups for today's clash.",
            commentaryType: .general,
            isHighlighted: false,
            metadata: nil
        )))
        
        events.append(AnyTimelineEvent(CommentaryEvent(
            id: "comm-supervisor",
            videoTimestamp: 50,
            minute: 0,
            text: "Jose Munuera will supervise the game today.",
            commentaryType: .general,
            isHighlighted: false,
            metadata: nil
        )))
        
        // 1' - Kickoff commentary
        events.append(AnyTimelineEvent(CommentaryEvent(
            id: "comm-1-kickoff",
            videoTimestamp: 60,
            minute: 1,
            text: "The first half of this match is about to start.",
            commentaryType: .kickoff,
            isHighlighted: false,
            metadata: nil
        )))
        
        events.append(AnyTimelineEvent(CommentaryEvent(
            id: "comm-1-start",
            videoTimestamp: 65,
            minute: 1,
            text: "Barcelona will kick the game off.",
            commentaryType: .kickoff,
            isHighlighted: false,
            metadata: nil
        )))
        
        // 1' - Tackle
        events.append(AnyTimelineEvent(CommentaryEvent(
            id: "comm-1-tackle",
            videoTimestamp: 70,
            minute: 1,
            text: "Jose Munuera blows his whistle after Eduardo Camavinga (Real Madrid) brings one of his opponents down with a strong tackle.",
            commentaryType: .foul,
            isHighlighted: false,
            metadata: nil
        )))
        
        // 3' - Pass
        events.append(AnyTimelineEvent(CommentaryEvent(
            id: "comm-3",
            videoTimestamp: 180,
            minute: 3,
            text: "Fermín (Barcelona) slides a pass forward, but one of the defenders cuts it out.",
            commentaryType: .general,
            isHighlighted: false,
            metadata: nil
        )))
        
        // 4' - Foul
        events.append(AnyTimelineEvent(CommentaryEvent(
            id: "comm-4",
            videoTimestamp: 240,
            minute: 4,
            text: "Alvaro Carreras (Real Madrid) makes a rough challenge and the referee blows for a foul.",
            commentaryType: .foul,
            isHighlighted: false,
            metadata: nil
        )))
        
        // 5' - Chance
        events.append(AnyTimelineEvent(CommentaryEvent(
            id: "comm-5",
            videoTimestamp: 300,
            minute: 5,
            text: "Another attempt to send the ball beyond the defence by Pedri (Barcelona) is thwarted and cleared to safety.",
            commentaryType: .chance,
            isHighlighted: false,
            metadata: nil
        )))
        
        // 6' - Chance
        events.append(AnyTimelineEvent(CommentaryEvent(
            id: "comm-6",
            videoTimestamp: 360,
            minute: 6,
            text: "Jules Kounde (Barcelona) whips the ball into the penalty area, but one of the defenders is alert and spanks it away.",
            commentaryType: .chance,
            isHighlighted: false,
            metadata: nil
        )))
        
        // 8' - Corner
        events.append(AnyTimelineEvent(CommentaryEvent(
            id: "comm-8-corner",
            videoTimestamp: 480,
            minute: 8,
            text: "Rodrygo (Real Madrid) attempts to find a teammate with the corner, but the effort is snuffed out by the goalkeeper.",
            commentaryType: .corner,
            isHighlighted: false,
            metadata: nil
        )))
        
        // 11' - Chance
        events.append(AnyTimelineEvent(CommentaryEvent(
            id: "comm-11",
            videoTimestamp: 660,
            minute: 11,
            text: "Alejandro Balde (Barcelona) did his best to latch on to a crossfield pass, but it was too long and it goes out of play.",
            commentaryType: .general,
            isHighlighted: false,
            metadata: nil
        )))
        
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
        
        // 46' - Second half start
        events.append(AnyTimelineEvent(CommentaryEvent(
            id: "comm-46",
            videoTimestamp: 2760,
            minute: 46,
            text: "The whistle blows and Jose Munuera starts the second half.",
            commentaryType: .kickoff,
            isHighlighted: false,
            metadata: nil
        )))
        
        // 46' - Foul
        events.append(AnyTimelineEvent(CommentaryEvent(
            id: "comm-46-foul",
            videoTimestamp: 2780,
            minute: 46,
            text: "Frenkie de Jong (Barcelona) makes a rough challenge and Jose Munuera blows his whistle for a foul.",
            commentaryType: .foul,
            isHighlighted: false,
            metadata: nil
        )))
        
        // 47' - Corner
        events.append(AnyTimelineEvent(CommentaryEvent(
            id: "comm-47",
            videoTimestamp: 2820,
            minute: 47,
            text: "Vinicius Junior (Real Madrid) sends a pass into the penalty area, but the opponent manages to cut it out. Real Madrid will have a chance to score from a corner.",
            commentaryType: .corner,
            isHighlighted: false,
            metadata: nil
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
        
        // 7' - Concurso (Contest)
        events.append(AnyTimelineEvent(AnnouncementEvent(
            id: "contest-7",
            videoTimestamp: 420,  // 7 minutos
            title: "🏆 Vinn en drakt fra ditt favorittlag!",
            message: "Delta i konkurransen og få sjansen til å vinne en signert drakt fra XXL Sports.",
            imageUrl: nil,
            actionUrl: nil,
            actionText: "Delta",
            metadata: ["type": "contest", "prize": "Fotballdrakt"]
        )))
        
        // 10' - Poll sobre resultado
        events.append(AnyTimelineEvent(PollTimelineEvent(
            id: "poll-10",
            videoTimestamp: 600,
            question: "Hvem vinner denne kampen?",
            options: [
                .init(id: "opt1", text: "Barcelona", voteCount: 3456, percentage: 65),
                .init(id: "opt2", text: "Real Madrid", voteCount: 1234, percentage: 23),
                .init(id: "opt3", text: "Uavgjort", voteCount: 645, percentage: 12)
            ],
            duration: 600,
            endTimestamp: 1200,
            metadata: nil
        )))
        
        // 20' - Poll sobre neste mål
        events.append(AnyTimelineEvent(PollTimelineEvent(
            id: "poll-20",
            videoTimestamp: 1200,
            question: "Hvem scorer neste mål?",
            options: [
                .init(id: "opt1", text: "Barcelona", voteCount: 2890, percentage: 58),
                .init(id: "opt2", text: "Real Madrid", voteCount: 1567, percentage: 31),
                .init(id: "opt3", text: "Ingen flere mål", voteCount: 543, percentage: 11)
            ],
            duration: 900,
            endTimestamp: 2100,
            metadata: nil
        )))
        
        // 35' - Poll sobre beste spiller
        events.append(AnyTimelineEvent(PollTimelineEvent(
            id: "poll-35",
            videoTimestamp: 2100,
            question: "Hvem er beste spiller så langt?",
            options: [
                .init(id: "opt1", text: "A. Diallo", voteCount: 2345, percentage: 45),
                .init(id: "opt2", text: "Bruno Fernandes", voteCount: 1789, percentage: 34),
                .init(id: "opt3", text: "B. Mbeumo", voteCount: 1098, percentage: 21)
            ],
            duration: 600,
            endTimestamp: 2700,
            metadata: nil
        )))
        
        // MARK: - Tweets (en momentos clave)
        
        // 2' - Tweet al inicio (Luka Modrić - Real Madrid)
        events.append(AnyTimelineEvent(TweetEvent(
            id: "tweet-2",
            videoTimestamp: 120,
            authorName: "Luka Modrić",
            authorHandle: "@LukaModric10",
            authorAvatar: "https://pbs.twimg.com/profile_images/1467838580013015046/Ri-Mx4k0_400x400.jpg",
            tweetText: "Nikada ne odustaj! ⚽🔥 #ChampionsLeague",
            isVerified: true,
            likes: 1345,
            retweets: 878,
            metadata: nil
        )))
        
        // 8' - Otro tweet (Erling Haaland - Manchester City)
        events.append(AnyTimelineEvent(TweetEvent(
            id: "tweet-8",
            videoTimestamp: 480,
            authorName: "Erling Haaland",
            authorHandle: "@ErlingHaaland",
            authorAvatar: "https://pbs.twimg.com/profile_images/1618611381585408002/yvY87tJm_400x400.jpg",
            tweetText: "Alltid klar for neste mål! ⚽🎯",
            isVerified: true,
            likes: 2340,
            retweets: 1456,
            metadata: nil
        )))
        
        // 13'30" - Tweet después del gol (Kylian Mbappé - PSG/Real Madrid)
        events.append(AnyTimelineEvent(TweetEvent(
            id: "tweet-13",
            videoTimestamp: 810,
            authorName: "Kylian Mbappé",
            authorHandle: "@KMbappe",
            authorAvatar: "https://pbs.twimg.com/profile_images/1654969131244240896/rCJEZU4q_400x400.jpg",
            tweetText: "Champions League! C'est magnifique! ⚡🔥",
            isVerified: true,
            likes: 4567,
            retweets: 2123,
            metadata: nil
        )))
        
        // 20' - Tweet de Cristiano Ronaldo
        events.append(AnyTimelineEvent(TweetEvent(
            id: "tweet-20",
            videoTimestamp: 1200,
            authorName: "Cristiano Ronaldo",
            authorHandle: "@Cristiano",
            authorAvatar: "https://pbs.twimg.com/profile_images/1594446880498401282/o4L2z8Yw_400x400.jpg",
            tweetText: "Grande Champions League! Siuuu! 🔥⚽",
            isVerified: true,
            likes: 8910,
            retweets: 3456,
            metadata: nil
        )))
        
        // MARK: - Highlights (con videos de Firebase)
        
        // 13' - Highlight del gol de Diallo
        events.append(AnyTimelineEvent(HighlightTimelineEvent(
            id: "highlight-goal-13",
            videoTimestamp: 780,  // 13 minutos
            title: "MÅL: A. Diallo",
            description: "Nydelig avslutning fra Diallo!",
            thumbnailUrl: nil,
            clipUrl: "https://firebasestorage.googleapis.com/v0/b/tipio-1ec97.appspot.com/o/1.MP4?alt=media&token=898b7836-5e27-492d-82bb-9d7bb50f9d66",
            highlightType: .goal,
            metadata: ["score": "1-0", "player": "A. Diallo"]
        )))
        
        // 25' - Highlight de ocasión
        events.append(AnyTimelineEvent(HighlightTimelineEvent(
            id: "highlight-chance-25",
            videoTimestamp: 1500,  // 25 minutos
            title: "Stor sjanse!",
            description: "Nesten 2-0 for Barcelona!",
            thumbnailUrl: nil,
            clipUrl: "https://firebasestorage.googleapis.com/v0/b/tipio-1ec97.appspot.com/o/2.MP4?alt=media&token=9011a94a-1085-4b69-bd41-3b1432ca577a",
            highlightType: .chance,
            metadata: ["team": "home"]
        )))
        
        // 18' - Highlight de tarjeta amarilla
        events.append(AnyTimelineEvent(HighlightTimelineEvent(
            id: "highlight-card-18",
            videoTimestamp: 1080,  // 18 minutos
            title: "Gult kort: Casemiro",
            description: "Falta táctica fra Casemiro",
            thumbnailUrl: nil,
            clipUrl: "https://firebasestorage.googleapis.com/v0/b/tipio-1ec97.appspot.com/o/3.MP4?alt=media&token=f28dadf8-05df-4544-a21f-a4c45836793f",
            highlightType: .yellowCard,
            metadata: ["player": "Casemiro", "team": "home"]
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
        
        // 10' - Admin tactical note
        events.append(AnyTimelineEvent(AdminCommentEvent(
            id: "admin-10",
            videoTimestamp: 600,
            adminName: "Magnus Drivenes",
            comment: "Barcelona kontrollerer ballen godt. PSG venter på sin sjanse.",
            isPinned: false,
            metadata: nil
        )))
        
        // 13'15" - Admin comment sobre el gol
        events.append(AnyTimelineEvent(AdminCommentEvent(
            id: "admin-13",
            videoTimestamp: 795,
            adminName: "Magnus Drivenes",
            comment: "Nydelig mål! Dette er Champions League på sitt beste!",
            isPinned: true,
            metadata: nil
        )))
        
        // 32'15" - Admin comment sobre segundo gol
        events.append(AnyTimelineEvent(AdminCommentEvent(
            id: "admin-32",
            videoTimestamp: 1935,
            adminName: "Magnus Drivenes",
            comment: "Mbeumo dobler ledelsen! Fantastisk lagarbeid!",
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

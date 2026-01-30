import Foundation
import ReachuCore

// MARK: - Engagement Models

/// Poll model for engagement system
public struct Poll: Codable, Identifiable {
    public let id: String
    public let matchId: String
    public let question: String
    public let options: [PollOption]
    public let startTime: Date?
    public let endTime: Date?
    public let isActive: Bool
    public let totalVotes: Int
    public let matchContext: MatchContext?
    
    public init(
        id: String,
        matchId: String,
        question: String,
        options: [PollOption],
        startTime: Date? = nil,
        endTime: Date? = nil,
        isActive: Bool = true,
        totalVotes: Int = 0,
        matchContext: MatchContext? = nil
    ) {
        self.id = id
        self.matchId = matchId
        self.question = question
        self.options = options
        self.startTime = startTime
        self.endTime = endTime
        self.isActive = isActive
        self.totalVotes = totalVotes
        self.matchContext = matchContext
    }
    
    public struct PollOption: Codable, Identifiable {
        public let id: String
        public let text: String
        public let voteCount: Int
        public let percentage: Double
        
        public init(id: String, text: String, voteCount: Int = 0, percentage: Double = 0.0) {
            self.id = id
            self.text = text
            self.voteCount = voteCount
            self.percentage = percentage
        }
    }
}

/// Contest model for engagement system
public struct Contest: Codable, Identifiable {
    public let id: String
    public let matchId: String
    public let title: String
    public let description: String
    public let prize: String
    public let contestType: ContestType
    public let startTime: Date?
    public let endTime: Date?
    public let isActive: Bool
    public let matchContext: MatchContext?
    
    public init(
        id: String,
        matchId: String,
        title: String,
        description: String,
        prize: String,
        contestType: ContestType,
        startTime: Date? = nil,
        endTime: Date? = nil,
        isActive: Bool = true,
        matchContext: MatchContext? = nil
    ) {
        self.id = id
        self.matchId = matchId
        self.title = title
        self.description = description
        self.prize = prize
        self.contestType = contestType
        self.startTime = startTime
        self.endTime = endTime
        self.isActive = isActive
        self.matchContext = matchContext
    }
    
    public enum ContestType: String, Codable {
        case quiz = "quiz"
        case giveaway = "giveaway"
    }
}

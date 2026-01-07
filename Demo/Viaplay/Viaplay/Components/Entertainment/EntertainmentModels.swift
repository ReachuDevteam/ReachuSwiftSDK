//
//  EntertainmentModels.swift
//  Viaplay
//
//  Data models for interactive entertainment components
//  Structure designed to be portable to ReachuSDK
//

import Foundation

// MARK: - Base Entertainment Component

/// Base protocol for all entertainment components
public protocol EntertainmentComponent: Codable, Identifiable {
    var id: String { get }
    var type: EntertainmentComponentType { get }
    var state: EntertainmentComponentState { get }
    var title: String { get }
    var description: String? { get }
    var startTime: Date? { get }
    var endTime: Date? { get }
    var metadata: [String: String]? { get }
}

// MARK: - Interactive Component

/// Main model for interactive entertainment components
public struct InteractiveComponent: EntertainmentComponent {
    public let id: String
    public let type: EntertainmentComponentType
    public var state: EntertainmentComponentState
    public let title: String
    public let description: String?
    public let startTime: Date?
    public let endTime: Date?
    public let metadata: [String: String]?
    
    // Interactive specific properties
    public let interactionType: InteractionType
    public let options: [InteractionOption]
    public let allowMultipleResponses: Bool
    public let showResults: Bool
    public let points: Int?
    public let timeLimit: TimeInterval?
    
    public init(
        id: String,
        type: EntertainmentComponentType,
        state: EntertainmentComponentState = .upcoming,
        title: String,
        description: String? = nil,
        startTime: Date? = nil,
        endTime: Date? = nil,
        metadata: [String: String]? = nil,
        interactionType: InteractionType,
        options: [InteractionOption],
        allowMultipleResponses: Bool = false,
        showResults: Bool = true,
        points: Int? = nil,
        timeLimit: TimeInterval? = nil
    ) {
        self.id = id
        self.type = type
        self.state = state
        self.title = title
        self.description = description
        self.startTime = startTime
        self.endTime = endTime
        self.metadata = metadata
        self.interactionType = interactionType
        self.options = options
        self.allowMultipleResponses = allowMultipleResponses
        self.showResults = showResults
        self.points = points
        self.timeLimit = timeLimit
    }
}

// MARK: - Interaction Option

/// Option for user interaction
public struct InteractionOption: Codable, Identifiable {
    public let id: String
    public let text: String
    public let value: String
    public let imageUrl: String?
    public let emoji: String?
    public var voteCount: Int
    public var percentage: Double?
    public let isCorrect: Bool?
    
    public init(
        id: String,
        text: String,
        value: String,
        imageUrl: String? = nil,
        emoji: String? = nil,
        voteCount: Int = 0,
        percentage: Double? = nil,
        isCorrect: Bool? = nil
    ) {
        self.id = id
        self.text = text
        self.value = value
        self.imageUrl = imageUrl
        self.emoji = emoji
        self.voteCount = voteCount
        self.percentage = percentage
        self.isCorrect = isCorrect
    }
}

// MARK: - User Response

/// User's response to an interactive component
public struct UserInteractionResponse: Codable {
    public let componentId: String
    public let userId: String
    public let selectedOptions: [String]
    public let freeTextResponse: String?
    public let timestamp: Date
    public let timeToRespond: TimeInterval?
    
    public init(
        componentId: String,
        userId: String,
        selectedOptions: [String],
        freeTextResponse: String? = nil,
        timestamp: Date = Date(),
        timeToRespond: TimeInterval? = nil
    ) {
        self.componentId = componentId
        self.userId = userId
        self.selectedOptions = selectedOptions
        self.freeTextResponse = freeTextResponse
        self.timestamp = timestamp
        self.timeToRespond = timeToRespond
    }
}

// MARK: - Component Results

/// Results of an interactive component
public struct ComponentResults: Codable {
    public let componentId: String
    public let totalResponses: Int
    public let optionResults: [String: OptionResult]
    public let correctOptionId: String?
    public let averageResponseTime: TimeInterval?
    
    public init(
        componentId: String,
        totalResponses: Int,
        optionResults: [String: OptionResult],
        correctOptionId: String? = nil,
        averageResponseTime: TimeInterval? = nil
    ) {
        self.componentId = componentId
        self.totalResponses = totalResponses
        self.optionResults = optionResults
        self.correctOptionId = correctOptionId
        self.averageResponseTime = averageResponseTime
    }
}

public struct OptionResult: Codable {
    public let optionId: String
    public let count: Int
    public let percentage: Double
    
    public init(optionId: String, count: Int, percentage: Double) {
        self.optionId = optionId
        self.count = count
        self.percentage = percentage
    }
}

// MARK: - Leaderboard

/// Leaderboard entry for competitive components
public struct LeaderboardEntry: Codable, Identifiable {
    public let id: String
    public let userId: String
    public let username: String
    public let score: Int
    public let rank: Int
    public let avatar: String?
    public let badge: String?
    
    public init(
        id: String,
        userId: String,
        username: String,
        score: Int,
        rank: Int,
        avatar: String? = nil,
        badge: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.username = username
        self.score = score
        self.rank = rank
        self.avatar = avatar
        self.badge = badge
    }
}



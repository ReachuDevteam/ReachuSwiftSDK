import Foundation
import Combine
import ReachuCore

/// Engagement Manager for handling polls and contests with match context
/// Manages engagement data organized by matchId for context-aware filtering
@MainActor
public class EngagementManager: ObservableObject {
    
    // MARK: - Singleton
    public static let shared = EngagementManager()
    
    // MARK: - Published Properties
    @Published public private(set) var pollsByMatch: [String: [Poll]] = [:]
    @Published public private(set) var contestsByMatch: [String: [Contest]] = [:]
    @Published public private(set) var pollResults: [String: PollResults] = [:]
    
    // MARK: - Private Properties
    private var participationRecord: Set<String> = []  // Track poll votes locally
    private var contestParticipation: Set<String> = []  // Track contest participation
    private var campaignRestAPIBaseURL: String {
        ReachuConfiguration.shared.campaignConfiguration.restAPIBaseURL
    }
    
    // MARK: - Initialization
    private init() {}
    
    // MARK: - Public Methods
    
    /// Load engagement data (polls and contests) for a specific match context
    public func loadEngagement(for context: MatchContext) async {
        ReachuLogger.debug("Loading engagement for matchId: \(context.matchId)", component: "EngagementManager")
        
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await self.loadPolls(for: context)
            }
            group.addTask {
                await self.loadContests(for: context)
            }
        }
    }
    
    /// Get active polls for a specific match context
    public func getActivePolls(for context: MatchContext) -> [Poll] {
        let polls = pollsByMatch[context.matchId] ?? []
        let now = Date().timeIntervalSince1970
        
        return polls.filter { poll in
            // Filter by time - only show polls that are currently active
            if let endTime = poll.endTime {
                return now < endTime.timeIntervalSince1970
            }
            return poll.isActive
        }
    }
    
    /// Get active contests for a specific match context
    public func getActiveContests(for context: MatchContext) -> [Contest] {
        return contestsByMatch[context.matchId] ?? []
    }
    
    /// Check if user has voted in a poll
    public func hasVotedInPoll(_ pollId: String) -> Bool {
        return participationRecord.contains(pollId)
    }
    
    /// Check if user has participated in a contest
    public func hasParticipatedInContest(_ contestId: String) -> Bool {
        return contestParticipation.contains(contestId)
    }
    
    /// Vote in a poll (with context validation)
    public func voteInPoll(
        pollId: String,
        optionId: String,
        matchContext: MatchContext
    ) async throws {
        // Verify that the poll belongs to the correct context
        guard let poll = pollsByMatch[matchContext.matchId]?.first(where: { $0.id == pollId }) else {
            throw EngagementError.pollNotFound
        }
        
        // Verify that the poll is still active
        let now = Date()
        if let endTime = poll.endTime, now >= endTime {
            throw EngagementError.pollClosed
        }
        if !poll.isActive {
            throw EngagementError.pollClosed
        }
        
        // Verify that the user hasn't already voted
        if hasVotedInPoll(pollId) {
            throw EngagementError.alreadyVoted
        }
        
        // Send vote to backend
        try await sendVoteToBackend(pollId: pollId, optionId: optionId, matchContext: matchContext)
        
        // Register participation locally
        participationRecord.insert(pollId)
        
        // Optimistic update - increment vote count locally
        updatePollResultsOptimistically(pollId: pollId, optionId: optionId)
    }
    
    /// Participate in a contest (with context validation)
    public func participateInContest(
        contestId: String,
        matchContext: MatchContext,
        answers: [String: String]? = nil
    ) async throws {
        // Verify that the contest belongs to the correct context
        guard let contest = contestsByMatch[matchContext.matchId]?.first(where: { $0.id == contestId }) else {
            throw EngagementError.contestNotFound
        }
        
        // Send participation to backend
        try await sendContestParticipationToBackend(
            contestId: contestId,
            matchContext: matchContext,
            answers: answers
        )
        
        // Register participation locally
        contestParticipation.insert(contestId)
    }
    
    /// Update poll results from WebSocket event
    public func updatePollResults(pollId: String, results: PollResults) {
        pollResults[pollId] = results
        ReachuLogger.debug("Updated results for poll: \(pollId)", component: "EngagementManager")
    }
    
    // MARK: - Private Methods
    
    private func loadPolls(for context: MatchContext) async {
        let config = ReachuConfiguration.shared
        let apiKey = config.apiKey
        
        guard !apiKey.isEmpty else {
            ReachuLogger.error("Cannot load polls: API key is empty", component: "EngagementManager")
            return
        }
        
        let urlString = "\(campaignRestAPIBaseURL)/v1/engagement/polls?apiKey=\(apiKey)&matchId=\(context.matchId)"
        
        guard let url = URL(string: urlString) else {
            ReachuLogger.error("Invalid polls URL: \(urlString)", component: "EngagementManager")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10.0
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                guard (200...299).contains(httpResponse.statusCode) else {
                    ReachuLogger.error("Failed to load polls: HTTP \(httpResponse.statusCode)", component: "EngagementManager")
                    return
                }
            }
            
            // Decode polls response
            let pollsResponse = try JSONDecoder().decode(PollsResponse.self, from: data)
            
            // Convert to Poll models
            var polls: [Poll] = []
            for pollData in pollsResponse.polls {
                let poll = Poll(
                    id: pollData.id,
                    matchId: pollData.matchId,
                    question: pollData.question,
                    options: pollData.options.map { option in
                        Poll.PollOption(
                            id: option.id,
                            text: option.text,
                            voteCount: option.voteCount,
                            percentage: option.percentage
                        )
                    },
                    startTime: pollData.startTime,
                    endTime: pollData.endTime,
                    isActive: pollData.isActive,
                    totalVotes: pollData.totalVotes,
                    matchContext: context
                )
                polls.append(poll)
            }
            
            // Store polls by matchId
            pollsByMatch[context.matchId] = polls
            
            ReachuLogger.debug("Loaded \(polls.count) polls for matchId: \(context.matchId)", component: "EngagementManager")
            
        } catch {
            ReachuLogger.error("Failed to load polls: \(error)", component: "EngagementManager")
        }
    }
    
    private func loadContests(for context: MatchContext) async {
        let config = ReachuConfiguration.shared
        let apiKey = config.apiKey
        
        guard !apiKey.isEmpty else {
            ReachuLogger.error("Cannot load contests: API key is empty", component: "EngagementManager")
            return
        }
        
        let urlString = "\(campaignRestAPIBaseURL)/v1/engagement/contests?apiKey=\(apiKey)&matchId=\(context.matchId)"
        
        guard let url = URL(string: urlString) else {
            ReachuLogger.error("Invalid contests URL: \(urlString)", component: "EngagementManager")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10.0
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                guard (200...299).contains(httpResponse.statusCode) else {
                    ReachuLogger.error("Failed to load contests: HTTP \(httpResponse.statusCode)", component: "EngagementManager")
                    return
                }
            }
            
            // Decode contests response
            let contestsResponse = try JSONDecoder().decode(ContestsResponse.self, from: data)
            
            // Convert to Contest models
            var contests: [Contest] = []
            for contestData in contestsResponse.contests {
                let contestType: Contest.ContestType = contestData.contestType == "quiz" ? .quiz : .giveaway
                
                let contest = Contest(
                    id: contestData.id,
                    matchId: contestData.matchId,
                    title: contestData.title,
                    description: contestData.description,
                    prize: contestData.prize,
                    contestType: contestType,
                    startTime: contestData.startTime,
                    endTime: contestData.endTime,
                    isActive: contestData.isActive,
                    matchContext: context
                )
                contests.append(contest)
            }
            
            // Store contests by matchId
            contestsByMatch[context.matchId] = contests
            
            ReachuLogger.debug("Loaded \(contests.count) contests for matchId: \(context.matchId)", component: "EngagementManager")
            
        } catch {
            ReachuLogger.error("Failed to load contests: \(error)", component: "EngagementManager")
        }
    }
    
    private func sendVoteToBackend(
        pollId: String,
        optionId: String,
        matchContext: MatchContext
    ) async throws {
        let config = ReachuConfiguration.shared
        let apiKey = config.apiKey
        
        let urlString = "\(campaignRestAPIBaseURL)/v1/engagement/polls/\(pollId)/vote"
        guard let url = URL(string: urlString) else {
            throw EngagementError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "apiKey": apiKey,
            "matchId": matchContext.matchId,
            "optionId": optionId
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw EngagementError.voteFailed
        }
    }
    
    private func sendContestParticipationToBackend(
        contestId: String,
        matchContext: MatchContext,
        answers: [String: String]?
    ) async throws {
        let config = ReachuConfiguration.shared
        let apiKey = config.apiKey
        
        let urlString = "\(campaignRestAPIBaseURL)/v1/engagement/contests/\(contestId)/participate"
        guard let url = URL(string: urlString) else {
            throw EngagementError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var body: [String: Any] = [
            "apiKey": apiKey,
            "matchId": matchContext.matchId
        ]
        
        if let answers = answers {
            body["answers"] = answers
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw EngagementError.participationFailed
        }
    }
    
    private func updatePollResultsOptimistically(pollId: String, optionId: String) {
        // Optimistic update - increment vote count locally
        // Real results will come from WebSocket update
        guard var existingResults = pollResults[pollId] else {
            return
        }
        
        guard let optionIndex = existingResults.options.firstIndex(where: { $0.optionId == optionId }) else {
            return
        }
        
        // Create new option results with updated vote count
        var updatedOptions = existingResults.options
        let oldVoteCount = updatedOptions[optionIndex].voteCount
        let newVoteCount = oldVoteCount + 1
        let newTotalVotes = existingResults.totalVotes + 1
        
        // Update the option at the found index
        updatedOptions[optionIndex] = PollResults.PollOptionResults(
            optionId: updatedOptions[optionIndex].optionId,
            voteCount: newVoteCount,
            percentage: Double(newVoteCount) / Double(newTotalVotes) * 100.0
        )
        
        // Recalculate percentages for all options
        let recalculatedOptions = updatedOptions.map { option in
            PollResults.PollOptionResults(
                optionId: option.optionId,
                voteCount: option.voteCount,
                percentage: Double(option.voteCount) / Double(newTotalVotes) * 100.0
            )
        }
        
        // Create new results with updated data
        let updatedResults = PollResults(
            pollId: existingResults.pollId,
            totalVotes: newTotalVotes,
            options: recalculatedOptions
        )
        
        pollResults[pollId] = updatedResults
    }
}

// MARK: - Response Models

private struct PollsResponse: Codable {
    let polls: [PollData]
    
    struct PollData: Codable {
        let id: String
        let matchId: String
        let question: String
        let options: [PollOptionData]
        let startTime: Date?
        let endTime: Date?
        let isActive: Bool
        let totalVotes: Int
        
        struct PollOptionData: Codable {
            let id: String
            let text: String
            let voteCount: Int
            let percentage: Double
        }
    }
}

private struct ContestsResponse: Codable {
    let contests: [ContestData]
    
    struct ContestData: Codable {
        let id: String
        let matchId: String
        let title: String
        let description: String
        let prize: String
        let contestType: String
        let startTime: Date?
        let endTime: Date?
        let isActive: Bool
    }
}

// MARK: - Poll Results Model

public struct PollResults: Codable {
    public let pollId: String
    public let totalVotes: Int
    public let options: [PollOptionResults]
    
    public struct PollOptionResults: Codable {
        public let optionId: String
        public let voteCount: Int
        public let percentage: Double
    }
}

// MARK: - Engagement Errors

public enum EngagementError: LocalizedError {
    case pollNotFound
    case contestNotFound
    case pollClosed
    case alreadyVoted
    case voteFailed
    case participationFailed
    case invalidURL
    
    public var errorDescription: String? {
        switch self {
        case .pollNotFound:
            return "Poll not found for this match"
        case .contestNotFound:
            return "Contest not found for this match"
        case .pollClosed:
            return "Poll is no longer active"
        case .alreadyVoted:
            return "You have already voted in this poll"
        case .voteFailed:
            return "Failed to submit vote"
        case .participationFailed:
            return "Failed to participate in contest"
        case .invalidURL:
            return "Invalid URL"
        }
    }
}

import Foundation
import ReachuCore

/// Backend implementation of EngagementRepositoryProtocol
/// Uses REST API to fetch polls and contests from the backend
struct BackendEngagementRepository: EngagementRepositoryProtocol {
    
    private var campaignRestAPIBaseURL: String {
        ReachuConfiguration.shared.campaignConfiguration.restAPIBaseURL
    }
    
    func loadPolls(for context: BroadcastContext) async -> [Poll] {
        let config = ReachuConfiguration.shared
        let apiKey = config.apiKey
        
        guard !apiKey.isEmpty else {
            ReachuLogger.error("Cannot load polls: API key is empty", component: "BackendEngagementRepository")
            return []
        }
        
        var urlString = "\(campaignRestAPIBaseURL)/v1/engagement/polls?apiKey=\(apiKey)&broadcastId=\(context.broadcastId)"
        // Also include matchId for backward compatibility with backend
        urlString += "&matchId=\(context.broadcastId)"
        
        guard let url = URL(string: urlString) else {
            ReachuLogger.error("Invalid polls URL: \(urlString)", component: "BackendEngagementRepository")
            return []
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10.0
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                guard (200...299).contains(httpResponse.statusCode) else {
                    ReachuLogger.error("Failed to load polls: HTTP \(httpResponse.statusCode)", component: "BackendEngagementRepository")
                    return []
                }
            }
            
            // Decode polls response
            let pollsResponse = try JSONDecoder().decode(PollsResponse.self, from: data)
            
            // Set broadcastStartTime in VideoSyncManager if available at root level
            if let broadcastStartTime = pollsResponse.broadcastStartTime ?? pollsResponse.matchStartTime {
                await VideoSyncManager.shared.setBroadcastStartTime(broadcastStartTime, for: context.broadcastId)
            }
            
            // Convert to Poll models
            var polls: [Poll] = []
            for pollData in pollsResponse.polls {
                // Use broadcastStartTime from poll data if available, otherwise from root level
                let pollBroadcastStartTime = pollData.broadcastStartTime ?? pollData.matchStartTime ?? pollsResponse.broadcastStartTime ?? pollsResponse.matchStartTime
                
                let poll = Poll(
                    id: pollData.id,
                    broadcastId: pollData.broadcastId ?? pollData.matchId,
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
                    videoStartTime: pollData.videoStartTime,
                    videoEndTime: pollData.videoEndTime,
                    broadcastStartTime: pollBroadcastStartTime,
                    isActive: pollData.isActive,
                    totalVotes: pollData.totalVotes,
                    broadcastContext: context
                )
                polls.append(poll)
            }
            
            ReachuLogger.debug("Loaded \(polls.count) polls for broadcastId: \(context.broadcastId)", component: "BackendEngagementRepository")
            return polls
            
        } catch {
            ReachuLogger.error("Failed to load polls: \(error)", component: "BackendEngagementRepository")
            return []
        }
    }
    
    func loadContests(for context: BroadcastContext) async -> [Contest] {
        let config = ReachuConfiguration.shared
        let apiKey = config.apiKey
        
        guard !apiKey.isEmpty else {
            ReachuLogger.error("Cannot load contests: API key is empty", component: "BackendEngagementRepository")
            return []
        }
        
        var urlString = "\(campaignRestAPIBaseURL)/v1/engagement/contests?apiKey=\(apiKey)&broadcastId=\(context.broadcastId)"
        // Also include matchId for backward compatibility with backend
        urlString += "&matchId=\(context.broadcastId)"
        
        guard let url = URL(string: urlString) else {
            ReachuLogger.error("Invalid contests URL: \(urlString)", component: "BackendEngagementRepository")
            return []
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10.0
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                guard (200...299).contains(httpResponse.statusCode) else {
                    ReachuLogger.error("Failed to load contests: HTTP \(httpResponse.statusCode)", component: "BackendEngagementRepository")
                    return []
                }
            }
            
            // Decode contests response
            let contestsResponse = try JSONDecoder().decode(ContestsResponse.self, from: data)
            
            // Set broadcastStartTime in VideoSyncManager if available at root level
            if let broadcastStartTime = contestsResponse.broadcastStartTime ?? contestsResponse.matchStartTime {
                await VideoSyncManager.shared.setBroadcastStartTime(broadcastStartTime, for: context.broadcastId)
            }
            
            // Convert to Contest models
            var contests: [Contest] = []
            for contestData in contestsResponse.contests {
                let contestType: Contest.ContestType = contestData.contestType == "quiz" ? .quiz : .giveaway
                
                // Use broadcastStartTime from contest data if available, otherwise from root level
                let contestBroadcastStartTime = contestData.broadcastStartTime ?? contestData.matchStartTime ?? contestsResponse.broadcastStartTime ?? contestsResponse.matchStartTime
                
                let contest = Contest(
                    id: contestData.id,
                    broadcastId: contestData.broadcastId ?? contestData.matchId,
                    title: contestData.title,
                    description: contestData.description,
                    prize: contestData.prize,
                    contestType: contestType,
                    startTime: contestData.startTime,
                    endTime: contestData.endTime,
                    videoStartTime: contestData.videoStartTime,
                    videoEndTime: contestData.videoEndTime,
                    broadcastStartTime: contestBroadcastStartTime,
                    isActive: contestData.isActive,
                    broadcastContext: context
                )
                contests.append(contest)
            }
            
            ReachuLogger.debug("Loaded \(contests.count) contests for broadcastId: \(context.broadcastId)", component: "BackendEngagementRepository")
            return contests
            
        } catch {
            ReachuLogger.error("Failed to load contests: \(error)", component: "BackendEngagementRepository")
            return []
        }
    }
    
    func voteInPoll(
        pollId: String,
        optionId: String,
        broadcastContext: BroadcastContext
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
        
        var body: [String: Any] = [
            "apiKey": apiKey,
            "broadcastId": broadcastContext.broadcastId,
            "optionId": optionId
        ]
        // Also include matchId for backward compatibility with backend
        body["matchId"] = broadcastContext.broadcastId
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw EngagementError.voteFailed
        }
    }
    
    func participateInContest(
        contestId: String,
        broadcastContext: BroadcastContext,
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
            "broadcastId": broadcastContext.broadcastId
        ]
        // Also include matchId for backward compatibility with backend
        body["matchId"] = broadcastContext.broadcastId
        
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
}

// MARK: - Response Models

private struct PollsResponse: Codable {
    let polls: [PollData]
    let broadcastStartTime: Date? // Broadcast start time at root level
    let matchStartTime: Date? // Match start time at root level (backward compatibility)
    
    struct PollData: Codable {
        let id: String
        let broadcastId: String? // New field
        let matchId: String // Backward compatibility
        let question: String
        let options: [PollOptionData]
        let startTime: Date?
        let endTime: Date?
        let videoStartTime: Int? // Time in seconds relative to broadcast start
        let videoEndTime: Int? // Time in seconds relative to broadcast start
        let broadcastStartTime: Date? // Broadcast start time per poll (optional, can use root level)
        let matchStartTime: Date? // Match start time per poll (backward compatibility)
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
    let broadcastStartTime: Date? // Broadcast start time at root level
    let matchStartTime: Date? // Match start time at root level (backward compatibility)
    
    struct ContestData: Codable {
        let id: String
        let broadcastId: String? // New field
        let matchId: String // Backward compatibility
        let title: String
        let description: String
        let prize: String
        let contestType: String
        let startTime: Date?
        let endTime: Date?
        let videoStartTime: Int? // Time in seconds relative to broadcast start
        let videoEndTime: Int? // Time in seconds relative to broadcast start
        let broadcastStartTime: Date? // Broadcast start time per contest (optional, can use root level)
        let matchStartTime: Date? // Match start time per contest (backward compatibility)
        let isActive: Bool
    }
}

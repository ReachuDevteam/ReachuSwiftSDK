//
//  EntertainmentManager.swift
//  Viaplay
//
//  Manager for interactive entertainment components
//  Structure designed to be portable to ReachuSDK
//

import Foundation
import Combine

/// Manager for handling interactive entertainment components
@MainActor
public class EntertainmentManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published public private(set) var activeComponents: [InteractiveComponent] = []
    @Published public private(set) var upcomingComponents: [InteractiveComponent] = []
    @Published public private(set) var completedComponents: [InteractiveComponent] = []
    @Published public private(set) var leaderboard: [LeaderboardEntry] = []
    @Published public private(set) var userScore: Int = 0
    @Published public private(set) var isLoading: Bool = false
    @Published public private(set) var error: Error?
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    private let userId: String
    private var componentCache: [String: InteractiveComponent] = [:]
    private var userResponses: [String: UserInteractionResponse] = [:]
    
    // MARK: - Initialization
    
    public init(userId: String) {
        self.userId = userId
        setupObservers()
    }
    
    // MARK: - Setup
    
    private func setupObservers() {
        // Timer to update component states
        Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateComponentStates()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// Load components from configuration or API
    public func loadComponents() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // TODO: Replace with actual API call or configuration loading
            let components = try await fetchComponentsFromSource()
            
            // Categorize components by state
            categorizeComponents(components)
            
        } catch {
            self.error = error
            print("Error loading components: \(error)")
        }
    }
    
    /// Submit user response to a component
    public func submitResponse(
        componentId: String,
        selectedOptions: [String],
        freeText: String? = nil,
        timeToRespond: TimeInterval? = nil
    ) async throws {
        
        guard let component = findComponent(by: componentId) else {
            throw EntertainmentError.componentNotFound
        }
        
        guard component.state == .active else {
            throw EntertainmentError.componentNotActive
        }
        
        let response = UserInteractionResponse(
            componentId: componentId,
            userId: userId,
            selectedOptions: selectedOptions,
            freeTextResponse: freeText,
            timestamp: Date(),
            timeToRespond: timeToRespond
        )
        
        // Store response locally
        userResponses[componentId] = response
        
        // TODO: Send to backend
        try await sendResponseToBackend(response)
        
        // Update local state
        await updateComponentAfterResponse(componentId: componentId, response: response)
    }
    
    /// Get user's response for a component
    public func getUserResponse(for componentId: String) -> UserInteractionResponse? {
        return userResponses[componentId]
    }
    
    /// Check if user has responded to a component
    public func hasUserResponded(to componentId: String) -> Bool {
        return userResponses[componentId] != nil
    }
    
    /// Get results for a component
    public func getResults(for componentId: String) async throws -> ComponentResults {
        // TODO: Fetch from backend
        return try await fetchResultsFromBackend(componentId: componentId)
    }
    
    /// Refresh leaderboard
    public func refreshLeaderboard() async {
        do {
            leaderboard = try await fetchLeaderboardFromBackend()
        } catch {
            self.error = error
            print("Error refreshing leaderboard: \(error)")
        }
    }
    
    // MARK: - Private Methods
    
    private func categorizeComponents(_ components: [InteractiveComponent]) {
        activeComponents = components.filter { $0.state == .active }
        upcomingComponents = components.filter { $0.state == .upcoming }
        completedComponents = components.filter { $0.state == .completed }
        
        // Update cache
        components.forEach { componentCache[$0.id] = $0 }
    }
    
    private func updateComponentStates() {
        let now = Date()
        var needsUpdate = false
        
        // Check if any upcoming components should become active
        for (index, component) in upcomingComponents.enumerated() {
            if let startTime = component.startTime, startTime <= now {
                var updatedComponent = component
                updatedComponent.state = .active
                upcomingComponents.remove(at: index)
                activeComponents.append(updatedComponent)
                componentCache[component.id] = updatedComponent
                needsUpdate = true
            }
        }
        
        // Check if any active components should become completed
        for (index, component) in activeComponents.enumerated() {
            if let endTime = component.endTime, endTime <= now {
                var updatedComponent = component
                updatedComponent.state = .completed
                activeComponents.remove(at: index)
                completedComponents.append(updatedComponent)
                componentCache[component.id] = updatedComponent
                needsUpdate = true
            }
        }
        
        if needsUpdate {
            objectWillChange.send()
        }
    }
    
    private func findComponent(by id: String) -> InteractiveComponent? {
        return componentCache[id]
    }
    
    private func updateComponentAfterResponse(componentId: String, response: UserInteractionResponse) async {
        // Update local component state after user response
        guard let component = componentCache[componentId] else { return }
        
        // Create new array with updated vote counts
        let updatedOptions = component.options.map { option -> InteractionOption in
            if response.selectedOptions.contains(option.id) {
                var updatedOption = option
                updatedOption.voteCount += 1
                return updatedOption
            }
            return option
        }
        
        // Create new component with updated options
        // Note: Since options is let, we need to recreate the component
        // For now, we'll update the cache with a new component instance
        // In a real implementation, you might want to make options mutable or use a different approach
        let updatedComponent = InteractiveComponent(
            id: component.id,
            type: component.type,
            state: component.state,
            title: component.title,
            description: component.description,
            startTime: component.startTime,
            endTime: component.endTime,
            metadata: component.metadata,
            interactionType: component.interactionType,
            options: updatedOptions,
            allowMultipleResponses: component.allowMultipleResponses,
            showResults: component.showResults,
            points: component.points,
            timeLimit: component.timeLimit
        )
        
        componentCache[componentId] = updatedComponent
        
        // Refresh categorized lists
        categorizeComponents(Array(componentCache.values))
    }
    
    // MARK: - Backend Communication (Placeholder)
    
    private func fetchComponentsFromSource() async throws -> [InteractiveComponent] {
        // TODO: Implement actual API call or configuration loading
        // For now, return mock data
        return createMockComponents()
    }
    
    private func sendResponseToBackend(_ response: UserInteractionResponse) async throws {
        // TODO: Implement actual API call
        try await Task.sleep(nanoseconds: 500_000_000) // Simulate network delay
    }
    
    private func fetchResultsFromBackend(componentId: String) async throws -> ComponentResults {
        // TODO: Implement actual API call
        try await Task.sleep(nanoseconds: 500_000_000)
        
        guard let component = componentCache[componentId] else {
            throw EntertainmentError.componentNotFound
        }
        
        let totalVotes = component.options.reduce(0) { $0 + $1.voteCount }
        var optionResults: [String: OptionResult] = [:]
        
        for option in component.options {
            let percentage = totalVotes > 0 ? Double(option.voteCount) / Double(totalVotes) * 100 : 0
            optionResults[option.id] = OptionResult(
                optionId: option.id,
                count: option.voteCount,
                percentage: percentage
            )
        }
        
        return ComponentResults(
            componentId: componentId,
            totalResponses: totalVotes,
            optionResults: optionResults,
            correctOptionId: component.options.first(where: { $0.isCorrect == true })?.id,
            averageResponseTime: 5.0
        )
    }
    
    private func fetchLeaderboardFromBackend() async throws -> [LeaderboardEntry] {
        // TODO: Implement actual API call
        try await Task.sleep(nanoseconds: 500_000_000)
        return []
    }
    
    // MARK: - Mock Data
    
    private func createMockComponents() -> [InteractiveComponent] {
        let now = Date()
        
        return [
            InteractiveComponent(
                id: "trivia-1",
                type: .trivia,
                state: .active,
                title: "¿Quién ganó el último Mundial?",
                description: "Pregunta de trivia sobre fútbol",
                startTime: now.addingTimeInterval(-300),
                endTime: now.addingTimeInterval(300),
                interactionType: .singleChoice,
                options: [
                    InteractionOption(id: "opt1", text: "Argentina", value: "argentina", isCorrect: true),
                    InteractionOption(id: "opt2", text: "Francia", value: "france", isCorrect: false),
                    InteractionOption(id: "opt3", text: "Brasil", value: "brazil", isCorrect: false),
                    InteractionOption(id: "opt4", text: "Alemania", value: "germany", isCorrect: false)
                ],
                showResults: true,
                points: 10,
                timeLimit: 30
            ),
            InteractiveComponent(
                id: "poll-1",
                type: .poll,
                state: .active,
                title: "¿Cuál es tu equipo favorito?",
                description: "Encuesta sobre preferencias deportivas",
                startTime: now.addingTimeInterval(-600),
                endTime: now.addingTimeInterval(600),
                interactionType: .singleChoice,
                options: [
                    InteractionOption(id: "team1", text: "Real Madrid", value: "real_madrid", emoji: "⚪"),
                    InteractionOption(id: "team2", text: "Barcelona", value: "barcelona", emoji: "🔵"),
                    InteractionOption(id: "team3", text: "Atlético", value: "atletico", emoji: "🔴"),
                    InteractionOption(id: "team4", text: "Otro", value: "other", emoji: "⭐")
                ],
                showResults: true
            )
        ]
    }
}

// MARK: - Errors

public enum EntertainmentError: LocalizedError {
    case componentNotFound
    case componentNotActive
    case invalidResponse
    case networkError
    
    public var errorDescription: String? {
        switch self {
        case .componentNotFound:
            return "Componente no encontrado"
        case .componentNotActive:
            return "El componente no está activo"
        case .invalidResponse:
            return "Respuesta inválida"
        case .networkError:
            return "Error de red"
        }
    }
}


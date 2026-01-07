//
//  EntertainmentComponentType.swift
//  Viaplay
//
//  Created for interactive entertainment components
//  Structure designed to be portable to ReachuSDK
//

import Foundation

/// Types of interactive entertainment components
/// This enum can be extended with new component types
public enum EntertainmentComponentType: String, Codable, CaseIterable {
    case trivia = "trivia"
    case quiz = "quiz"
    case poll = "poll"
    case prediction = "prediction"
    case reaction = "reaction"
    case voting = "voting"
    case challenge = "challenge"
    case leaderboard = "leaderboard"
    
    /// Display name for the component type
    var displayName: String {
        switch self {
        case .trivia: return "Trivia"
        case .quiz: return "Quiz"
        case .poll: return "Encuesta"
        case .prediction: return "Predicción"
        case .reaction: return "Reacciones"
        case .voting: return "Votación"
        case .challenge: return "Desafío"
        case .leaderboard: return "Tabla de Posiciones"
        }
    }
    
    /// Icon name for the component type
    var iconName: String {
        switch self {
        case .trivia: return "questionmark.circle.fill"
        case .quiz: return "brain.head.profile"
        case .poll: return "chart.bar.fill"
        case .prediction: return "crystal.ball.fill"
        case .reaction: return "hand.thumbsup.fill"
        case .voting: return "checkmark.circle.fill"
        case .challenge: return "trophy.fill"
        case .leaderboard: return "list.number"
        }
    }
}

/// State of an interactive component
public enum EntertainmentComponentState: String, Codable {
    case upcoming = "upcoming"
    case active = "active"
    case completed = "completed"
    case expired = "expired"
    
    var displayName: String {
        switch self {
        case .upcoming: return "Próximamente"
        case .active: return "Activo"
        case .completed: return "Completado"
        case .expired: return "Expirado"
        }
    }
}

/// Interaction type for user engagement
public enum InteractionType: String, Codable {
    case singleChoice = "single_choice"
    case multipleChoice = "multiple_choice"
    case freeText = "free_text"
    case numeric = "numeric"
    case emoji = "emoji"
    case gesture = "gesture"
}



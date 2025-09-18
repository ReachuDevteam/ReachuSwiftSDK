import Foundation

/// Reachu SDK Error types
public enum ReachuError: Error {
    case notImplemented(String)
    case invalidConfiguration(String)
    case networkError(Error)
    case invalidResponse(String)
    case authenticationFailed
    case notFound(String)
    case invalidInput(String)
    
    public var localizedDescription: String {
        switch self {
        case .notImplemented(let message):
            return "Not implemented: \(message)"
        case .invalidConfiguration(let message):
            return "Invalid configuration: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse(let message):
            return "Invalid response: \(message)"
        case .authenticationFailed:
            return "Authentication failed"
        case .notFound(let resource):
            return "Resource not found: \(resource)"
        case .invalidInput(let message):
            return "Invalid input: \(message)"
        }
    }
}

import Foundation

/// Configuration for the Reachu SDK
public struct Configuration {
    /// Your Reachu API key
    public let apiKey: String
    
    /// REST API endpoint
    public let restEndpoint: String
    
    /// GraphQL API endpoint
    public let graphqlEndpoint: String
    
    /// SDK Environment
    public let environment: Environment
    
    /// Request timeout in seconds
    public let timeout: TimeInterval
    
    /// Enable debug logging
    public let enableLogging: Bool
    
    /// Initialize configuration
    /// - Parameters:
    ///   - apiKey: Your Reachu API key
    ///   - restEndpoint: REST API endpoint
    ///   - graphqlEndpoint: GraphQL API endpoint
    ///   - environment: Environment
    ///   - timeout: Request timeout in seconds (default: 30)
    ///   - enableLogging: Enable debug logging (default: false)
    public init(
        apiKey: String,
        restEndpoint: String,
        graphqlEndpoint: String,
        environment: Environment,
        timeout: TimeInterval = 30.0,
        enableLogging: Bool = false
    ) {
        self.apiKey = apiKey
        self.restEndpoint = restEndpoint
        self.graphqlEndpoint = graphqlEndpoint
        self.environment = environment
        self.timeout = timeout
        self.enableLogging = enableLogging
    }
    
    /// Common headers for API requests
    public var commonHeaders: [String: String] {
        return [
            "Authorization": "Bearer \(apiKey)",
            "Content-Type": "application/json",
            "User-Agent": "ReachuSwiftSDK/1.0.0",
            "Accept": "application/json"
        ]
    }
}

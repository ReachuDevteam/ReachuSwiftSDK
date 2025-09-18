/// Reachu Swift SDK
/// 
/// The Reachu platform and infrastructure lets you administer and synchronize ecommerce data 
/// across different systems and platforms.
///
/// This SDK allows you to import products from Reachu and add ecommerce to any platform or application.
/// It's based on Reachu's API and provides the ability to retrieve products and channels from your 
/// Reachu account, add products to a cart, payments and checkout.

import Foundation

/// Main entry point for the Reachu SDK
public class Reachu {
    /// Shared instance of the Reachu SDK
    public static let shared = Reachu()
    
    /// SDK Configuration
    public private(set) var configuration: Configuration?
    
    /// Products module for managing products and channels
    public lazy var products = ProductsModule()
    
    /// Cart module for managing shopping carts
    public lazy var cart = CartModule()
    
    /// Checkout module for managing checkout process
    public lazy var checkout = CheckoutModule()
    
    /// Payments module for processing payments
    public lazy var payments = PaymentsModule()
    
    /// Orders module for managing orders
    public lazy var orders = OrdersModule()
    
    
    private init() {}
    
    /// Configure the Reachu SDK
    /// - Parameters:
    ///   - apiKey: Your Reachu API key
    ///   - restEndpoint: REST API endpoint (optional)
    ///   - graphqlEndpoint: GraphQL API endpoint (optional)
    ///   - environment: Environment (production, staging, development)
    public static func configure(
        apiKey: String,
        restEndpoint: String? = nil,
        graphqlEndpoint: String? = nil,
        environment: Environment = .production
    ) {
        let config = Configuration(
            apiKey: apiKey,
            restEndpoint: restEndpoint ?? environment.defaultRESTEndpoint,
            graphqlEndpoint: graphqlEndpoint ?? environment.defaultGraphQLEndpoint,
            environment: environment
        )
        
        shared.configuration = config
        shared.setupClients(with: config)
    }
    
    private func setupClients(with configuration: Configuration) {
        // Setup will be implemented in next tasks
        print("Reachu SDK configured for \(configuration.environment)")
    }
}

/// SDK Environment
public enum Environment {
    case production
    case staging
    case development
    
    var defaultRESTEndpoint: String {
        switch self {
        case .production:
            return "https://api.reachu.io/rest"
        case .staging:
            return "https://staging-api.reachu.io/rest"
        case .development:
            return "https://dev-api.reachu.io/rest"
        }
    }
    
    var defaultGraphQLEndpoint: String {
        switch self {
        case .production:
            return "https://api.reachu.io/graphql"
        case .staging:
            return "https://staging-api.reachu.io/graphql"
        case .development:
            return "https://dev-api.reachu.io/graphql"
        }
    }
}

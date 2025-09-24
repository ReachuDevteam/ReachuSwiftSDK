import Foundation

public final class SdkClient {
    public let baseUrl: URL
    public let apiKey: String

    // Lo llamamos igual que en tu Flutter para paralelismo conceptual
    public let apolloClient: GraphQLHTTPClient

    // Módulos
    public let cart: CartRepository
    public let channel: Channel
    public let checkout: CheckoutRepository
    public let discount: DiscountRepository
    public let market: MarketRepository
    public let payment: PaymentRepository

    public init(baseUrl: URL, apiKey: String) {
        self.baseUrl = baseUrl
        self.apiKey = apiKey

        self.apolloClient = GraphQLHTTPClient(baseURL: baseUrl, apiKey: apiKey)

        self.cart = CartRepositoryGQL(client: apolloClient)
        self.channel = Channel(apolloClient)
        self.checkout = CheckoutRepositoryGQL(client: apolloClient)
        self.discount = DiscountRepositoryGQL(
            client: apolloClient,
            apiKey: apiKey,
            baseUrl: baseUrl.absoluteString
        )
        self.market = MarketRepositoryGQL(client: apolloClient)
        self.payment = PaymentRepositoryGQL(client: apolloClient)

        _ = prepareGraphQLOpsNoop()
    }
}

extension SdkClient {
    @inlinable
    public func noop<T>(_ value: T) -> T { value }

    @discardableResult
    public func prepareGraphQLOpsNoop() -> Bool {
        Task {
            let _ = await GraphQLOperationLoader().loadAll(from: [])
        }
        return true
    }
}

// MARK: - Public Model Exports

// Export Product models for easy access
public typealias ReachuProduct = Product
public typealias ReachuPrice = Price
public typealias ReachuVariant = Variant
public typealias ReachuProductImage = ProductImage

// Export Configuration system for easy access
public typealias ReachuSDKConfiguration = ReachuConfiguration
public typealias ReachuSDKTheme = ReachuTheme
public typealias ReachuCartConfiguration = CartConfiguration
public typealias ReachuNetworkConfiguration = NetworkConfiguration
public typealias ReachuUIConfiguration = UIConfiguration
public typealias ReachuLiveShowConfiguration = LiveShowConfiguration
public typealias ReachuConfigurationLoader = ConfigurationLoader

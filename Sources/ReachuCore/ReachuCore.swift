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
            client: apolloClient, apiKey: apiKey, baseUrl: baseUrl.absoluteString)
        self.market = MarketRepositoryGQL(client: apolloClient)
        self.payment = PaymentRepositoryGQL(client: apolloClient)
    }
}

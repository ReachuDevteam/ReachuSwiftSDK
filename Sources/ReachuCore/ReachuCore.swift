import Foundation

public final class SdkClient {
    public let baseUrl: URL
    public let apiKey: String

    public let apolloClient: GraphQLHTTPClient

    public let cart: CartRepository
    public let checkout: CheckoutRepository

    public init(baseUrl: URL, apiKey: String) {
        self.baseUrl = baseUrl
        self.apiKey = apiKey
        self.apolloClient = GraphQLHTTPClient(baseURL: baseUrl, apiKey: apiKey)
        self.cart = CartRepositoryGQL(client: apolloClient)
        self.checkout = CheckoutRepositoryGQL(client: apolloClient)
    }
}

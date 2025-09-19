import Foundation

public struct CreateCheckoutDto: Codable, Equatable {
    public let id: String
    public let status: String
    public let checkoutUrl: String?

    enum CodingKeys: String, CodingKey {
        case id, status
        case checkoutUrl = "checkout_url"
    }
}

public struct UpdateCheckoutDto: Codable, Equatable {
    public let id: String
    public let status: String
    public let checkoutUrl: String?

    enum CodingKeys: String, CodingKey {
        case id, status
        case checkoutUrl = "checkout_url"
    }
}

public struct GetCheckoutDto: Codable, Equatable {
    public let id: String
    public let status: String
    public let checkoutUrl: String?

    enum CodingKeys: String, CodingKey {
        case id, status
        case checkoutUrl = "checkout_url"
    }
}

public struct RemoveCheckoutDto: Codable, Equatable {
    public let success: Bool
    public let message: String
}

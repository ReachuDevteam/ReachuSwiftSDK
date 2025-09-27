import Foundation

public struct GetAvailablePaymentMethodsDto: Codable, Equatable {
    public let name: String
}

public struct PaymentIntentStripeDto: Codable, Equatable {
    public let clientSecret: String
    public let customer: String
    public let publishableKey: String
    public let ephemeralKey: String?

    enum CodingKeys: String, CodingKey {
        case clientSecret = "client_secret"
        case customer
        case publishableKey = "publishable_key"
        case ephemeralKey = "ephemeral_key"
    }
}

public struct InitPaymentStripeDto: Codable, Equatable {
    public let checkoutUrl: String
    public let orderId: Int

    enum CodingKeys: String, CodingKey {
        case checkoutUrl = "checkout_url"
        case orderId = "order_id"
    }
}

public struct InitPaymentVippsDto: Codable, Equatable {
    public let paymentUrl: String
    enum CodingKeys: String, CodingKey { case paymentUrl = "payment_url" }
}

public struct InitPaymentKlarnaDto: Codable, Equatable {
    public let orderId: String
    public let status: String
    public let locale: String
    public let htmlSnippet: String

    enum CodingKeys: String, CodingKey {
        case orderId = "order_id"
        case status
        case locale
        case htmlSnippet = "html_snippet"
    }
}

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

public struct KlarnaNativePaymentMethodCategoryDto: Codable, Equatable {
    public let identifier: String
    public let name: String?
}

public struct KlarnaNativeOrderLineDto: Codable, Equatable {
    public let type: String
    public let name: String
    public let quantity: Int
    public let unitPrice: Int
    public let totalAmount: Int
    public let taxRate: Int
    public let taxAmount: Int

    enum CodingKeys: String, CodingKey {
        case type, name, quantity
        case unitPrice = "unit_price"
        case totalAmount = "total_amount"
        case taxRate = "tax_rate"
        case taxAmount = "tax_amount"
    }
}

public struct KlarnaNativeOrderDto: Codable, Equatable {
    public let orderId: String
    public let status: String?
    public let locale: String?
    public let htmlSnippet: String?
    public let purchaseCountry: String
    public let purchaseCurrency: String
    public let orderAmount: Int
    public let orderTaxAmount: Int?
    public let paymentMethodCategories: [KlarnaNativePaymentMethodCategoryDto]?
    public let orderLines: [KlarnaNativeOrderLineDto]?

    enum CodingKeys: String, CodingKey {
        case orderId = "order_id"
        case status
        case locale
        case htmlSnippet = "html_snippet"
        case purchaseCountry = "purchase_country"
        case purchaseCurrency = "purchase_currency"
        case orderAmount = "order_amount"
        case orderTaxAmount = "order_tax_amount"
        case paymentMethodCategories = "payment_method_categories"
        case orderLines = "order_lines"
    }
}

public struct InitPaymentKlarnaNativeDto: Codable, Equatable {
    public let clientToken: String
    public let sessionId: String
    public let purchaseCountry: String
    public let purchaseCurrency: String
    public let orderAmount: Int
    public let orderTaxAmount: Int?
    public let paymentMethodCategories: [KlarnaNativePaymentMethodCategoryDto]?
    public let orderLines: [KlarnaNativeOrderLineDto]?
    public let cartId: String?
    public let checkoutId: String?

    enum CodingKeys: String, CodingKey {
        case clientToken = "client_token"
        case sessionId = "session_id"
        case purchaseCountry = "purchase_country"
        case purchaseCurrency = "purchase_currency"
        case orderAmount = "order_amount"
        case orderTaxAmount = "order_tax_amount"
        case paymentMethodCategories = "payment_method_categories"
        case orderLines = "order_lines"
        case cartId = "cart_id"
        case checkoutId = "checkout_id"
    }
}

public struct ConfirmPaymentKlarnaNativeDto: Codable, Equatable {
    public let orderId: String
    public let checkoutId: String
    public let fraudStatus: String?
    public let order: KlarnaNativeOrderDto?

    enum CodingKeys: String, CodingKey {
        case orderId = "order_id"
        case checkoutId = "checkout_id"
        case fraudStatus = "fraud_status"
        case order
    }
}

public struct KlarnaNativeAddressInputDto: Codable, Equatable {
    public var givenName: String?
    public var familyName: String?
    public var email: String?
    public var phone: String?
    public var streetAddress: String?
    public var streetAddress2: String?
    public var city: String?
    public var region: String?
    public var postalCode: String?
    public var country: String?

    enum CodingKeys: String, CodingKey {
        case givenName = "given_name"
        case familyName = "family_name"
        case email
        case phone
        case streetAddress = "street_address"
        case streetAddress2 = "street_address2"
        case city
        case region
        case postalCode = "postal_code"
        case country
    }
}

public struct KlarnaNativeCustomerInputDto: Codable, Equatable {
    public var email: String?
    public var phone: String?
    public var dob: String?
    public var type: String?
    public var organizationRegistrationId: String?

    enum CodingKeys: String, CodingKey {
        case email
        case phone
        case dob
        case type
        case organizationRegistrationId = "organization_registration_id"
    }
}

public struct KlarnaNativeInitInputDto: Codable, Equatable {
    public var countryCode: String?
    public var currency: String?
    public var locale: String?
    public var returnUrl: String?
    public var intent: String?
    public var autoCapture: Bool?
    public var customer: KlarnaNativeCustomerInputDto?
    public var billingAddress: KlarnaNativeAddressInputDto?
    public var shippingAddress: KlarnaNativeAddressInputDto?

    enum CodingKeys: String, CodingKey {
        case countryCode = "country_code"
        case currency
        case locale
        case returnUrl = "return_url"
        case intent
        case autoCapture = "auto_capture"
        case customer
        case billingAddress = "billing_address"
        case shippingAddress = "shipping_address"
    }
}

public struct KlarnaNativeConfirmInputDto: Codable, Equatable {
    public let authorizationToken: String
    public var autoCapture: Bool?
    public var customer: KlarnaNativeCustomerInputDto?
    public var billingAddress: KlarnaNativeAddressInputDto?
    public var shippingAddress: KlarnaNativeAddressInputDto?

    enum CodingKeys: String, CodingKey {
        case authorizationToken = "authorization_token"
        case autoCapture = "auto_capture"
        case customer
        case billingAddress = "billing_address"
        case shippingAddress = "shipping_address"
    }
}

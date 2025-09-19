import Foundation

public struct PriceDataInput {
    public let currency: String
    public let tax: Double?
    public let unitPrice: Double?
    public init(currency: String, tax: Double? = nil, unitPrice: Double? = nil) {
        self.currency = currency
        self.tax = tax
        self.unitPrice = unitPrice
    }
    public func toJSON() -> [String: Any] {
        var m: [String: Any] = ["currency": currency]
        if let tax { m["tax"] = tax }
        if let unitPrice { m["unit_price"] = unitPrice }
        return m
    }
}

public struct LineItemInput {
    public let productId: Int?
    public let variantId: Int?
    public let quantity: Int?
    public let priceData: PriceDataInput?
    public init(
        productId: Int? = nil, variantId: Int? = nil, quantity: Int? = nil,
        priceData: PriceDataInput? = nil
    ) {
        self.productId = productId
        self.variantId = variantId
        self.quantity = quantity
        self.priceData = priceData
    }
    public func toJSON() -> [String: Any] {
        var m: [String: Any] = [:]
        if let productId { m["product_id"] = productId }
        if let variantId { m["variant_id"] = variantId }
        if let quantity { m["quantity"] = quantity }
        if let priceData { m["price_data"] = priceData.toJSON() }
        return m
    }
}

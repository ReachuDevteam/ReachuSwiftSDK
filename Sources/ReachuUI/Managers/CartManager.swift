import Foundation
import ReachuCore
import SwiftUI

public protocol CartManagingSDK {
    var cart: CartRepository { get }
    var product: ProductRepository { get }
    var checkout: CheckoutRepository { get }
    var payment: PaymentRepository { get }
    var discount: DiscountRepository { get }
    var market: MarketRepository { get }
}

extension SdkClient: CartManagingSDK {
    public var product: ProductRepository { channel.product }
}

@MainActor
public class CartManager: ObservableObject, LiveShowCartManaging {

    @Published public var items: [CartItem] = []
    @Published public var isCheckoutPresented = false
    @Published public var isLoading = false
    @Published public var cartTotal: Double = 0.0
    @Published public var currency: String = "USD"
    @Published public var country: String = "US"
    @Published public var errorMessage: String?
    @Published public var cartId: String?
    @Published public var checkoutId: String?
    @Published public var lastDiscountCode: String?
    @Published public var lastDiscountId: Int?
    @Published public var products: [Product] = []
    @Published public var isProductsLoading = false
    @Published public var productsErrorMessage: String?
    @Published public var shippingTotal: Double = 0.0
    @Published public var shippingCurrency: String = "USD"
    @Published public var markets: [Market] = []
    @Published public var selectedMarket: Market?
    @Published public var currencySymbol: String = "$"
    @Published public var phoneCode: String = "+1"
    @Published public var flagURL: String?

    internal var currentCartId: String?
    internal var pendingShippingSelections: [String: CartItem.ShippingOption] = [:]
    internal var didLoadMarkets = false
    internal var activeProductRequestID: UUID?
    internal var lastLoadedProductCurrency: String?
    internal var lastLoadedProductCountry: String?

    internal let sdk: CartManagingSDK

    public init(
        sdk: CartManagingSDK? = nil,
        configuration: ReachuConfiguration = .shared,
        autoBootstrap: Bool = true
    ) {
        if let provided = sdk {
            self.sdk = provided
        } else {
            let baseURL = URL(string: configuration.environment.graphQLURL)!
            let apiKey = configuration.apiKey.isEmpty ? "DEMO_KEY" : configuration.apiKey

            ReachuLogger.debug("Initializing SDK Client - Base URL: \(baseURL), API Key: \(apiKey.prefix(8))...", component: "CartManager")

            self.sdk = SdkClient(baseUrl: baseURL, apiKey: apiKey)
        }

        let fallback = configuration.marketConfiguration
        let fallbackMarket = Market(
            code: fallback.countryCode,
            name: fallback.countryName,
            officialName: fallback.countryName,
            flagURL: fallback.flagURL,
            phoneCode: fallback.phoneCode,
            currencyCode: fallback.currencyCode,
            currencySymbol: fallback.currencySymbol
        )

        markets = [fallbackMarket]
        selectedMarket = fallbackMarket
        country = fallback.countryCode
        currency = fallback.currencyCode
        currencySymbol = fallback.currencySymbol
        phoneCode = fallback.phoneCode
        flagURL = fallback.flagURL
        shippingCurrency = fallback.currencyCode

        if autoBootstrap {
            Task { [currency, country] in
                // Check if SDK should be used before attempting operations
                guard ReachuConfiguration.shared.shouldUseSDK else {
                    ReachuLogger.warning("Skipping cart creation - SDK disabled (market not available)", component: "CartManager")
                    return
                }
                
                ReachuLogger.debug("init → scheduling createCart(currency:\(currency), country:\(country))", component: "CartManager")
                await createCart(currency: currency, country: country)
                await loadMarketsIfNeeded()
            }
        }
    }

    public func showCheckout() {
        isCheckoutPresented = true
    }

    public func hideCheckout() {
        isCheckoutPresented = false
    }

    internal func iso8601String(from date: Date = Date()) -> String {
        ISO8601DateFormatter().string(from: date)
    }

    internal func logRequest(_ action: String, payload: Any? = nil) {
        if let payload = payload {
            ReachuLogger.debug("REQUEST: \(action) - Payload: \(String(describing: payload))", component: "CartManager")
        } else {
            ReachuLogger.debug("REQUEST: \(action)", component: "CartManager")
        }
    }

    internal func logResponse(_ action: String, payload: Any? = nil) {
        if let payload = payload {
            ReachuLogger.debug("\(action) response: \(String(describing: payload))", component: "CartManager")
        } else {
            ReachuLogger.debug("\(action) response", component: "CartManager")
        }
    }

    internal func logError(_ action: String, error: Error) {
        ReachuLogger.error("ERROR: \(action) - Type: \(type(of: error)), Message: \(error.localizedDescription)", component: "CartManager")
    }

    public func getCheckoutStatus(_ checkoutId: String) async -> Bool {
        ReachuLogger.debug("getCheckoutStatus() with checkoutId: \(checkoutId)", component: "CartManager")

        do {
            let result: GetCheckoutDto = try await sdk.checkout.getById(checkout_id: checkoutId);
            ReachuLogger.debug("getCheckoutStatus() result: \(result)", component: "CartManager")

            // ✅ Aquí validas si Vipps ya pagó
            if result.status == "SUCCESS" {
                ReachuLogger.success("Pago confirmado en backend", component: "CartManager")
                return true
            } else {
                ReachuLogger.debug("Aún sin pagar: \(result.status)", component: "CartManager")
                return false
            }

        } catch {
            logError("getCheckoutStatus", error: error)
            return false
        }
    }
}


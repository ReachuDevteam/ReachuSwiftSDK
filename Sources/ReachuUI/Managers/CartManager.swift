import Foundation
import ReachuCore
import ReachuDesignSystem
import ReachuLiveShow
import SwiftUI

/// Global cart manager that handles cart state and checkout flow
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

    private var currentCartId: String?
    private let sdk: SdkClient = {
        let baseURL = URL(string: "https://graph-ql-dev.reachu.io/graphql")!
        let apiKey = "THVXN06-MGB4D4P-KCPRCKP-RHGT6VJ"
        return SdkClient(baseUrl: baseURL, apiKey: apiKey)
    }()

    public init() {
        Task { [currency, country] in
            print("🛒 [Cart] init → scheduling createCart(currency:\(currency), country:\(country))")
            await createCart(currency: currency, country: country)
        }
    }

    public func createCart(currency: String = "USD", country: String = "US") async {
        if currentCartId != nil {
            print("🛒 [Cart] createCart skipped — existing cartId=\(currentCartId)")
            return
        }
        isLoading = true
        errorMessage = nil

        let session = "ios-\(UUID().uuidString)"
        print(
            "🛒 [Cart] createCart START  session=\(session) currency=\(currency) country=\(country)")

        do {
            let dto = try await sdk.cart.create(
                customer_session_id: session,
                currency: currency,
                shippingCountry: country
            )
            print(
                "✅ [Cart] createCart OK     cartId=\(dto.cartId) items=\(dto.lineItems.count) currency=\(dto.currency)"
            )
            sync(from: dto)
        } catch let e as SdkException {
            self.errorMessage = e.description
            print("❌ [Cart] createCart FAIL  \(e.description)")
        } catch {
            self.errorMessage = error.localizedDescription
            print("❌ [Cart] createCart FAIL  \(error.localizedDescription)")
        }

        isLoading = false
    }

    private func sync(from cart: CartDto) {
        self.currentCartId = cart.cartId
        self.currency = cart.currency
        self.country = cart.shippingCountry ?? "US"

    }

    // MARK: - Cart Item Model
    public struct CartItem: Identifiable, Equatable {
        public let id: String
        public let productId: Int
        public let variantId: String?
        public let title: String
        public let brand: String?
        public let imageUrl: String?
        public let price: Double
        public let currency: String
        public var quantity: Int
        public let sku: String?

        public init(
            id: String,
            productId: Int,
            variantId: String? = nil,
            title: String,
            brand: String? = nil,
            imageUrl: String? = nil,
            price: Double,
            currency: String,
            quantity: Int,
            sku: String? = nil
        ) {
            self.id = id
            self.productId = productId
            self.variantId = variantId
            self.title = title
            self.brand = brand
            self.imageUrl = imageUrl
            self.price = price
            self.currency = currency
            self.quantity = quantity
            self.sku = sku
        }
    }

    // MARK: - Public Methods

    /// Add a product to the cart
    public func addProduct(_ product: Product, quantity: Int = 1) async {
        isLoading = true
        errorMessage = nil

        let previousCount = itemCount

        if let existingIndex = items.firstIndex(where: { $0.productId == 397968 }) {
            let existingItem = items[existingIndex]
            let newQuantity = existingItem.quantity + quantity

            items[existingIndex] = CartItem(
                id: existingItem.id,
                productId: existingItem.productId,
                variantId: existingItem.variantId,
                title: existingItem.title,
                brand: existingItem.brand,
                imageUrl: existingItem.imageUrl,
                price: existingItem.price,
                currency: existingItem.currency,
                quantity: newQuantity,
                sku: existingItem.sku
            )

            if let cid = self.currentCartId {
                _ = try? await sdk.cart.updateItem(
                    cart_id: cid,
                    cart_item_id: existingItem.id,
                    shipping_id: nil,
                    quantity: newQuantity
                )
            }

            await MainActor.run {
                ToastManager.shared.showSuccess("Updated \(product.title) quantity in cart")
            }

        } else {
            var serverId: String? = nil
            if let cid = self.currentCartId {
                let line = LineItemInput(
                    productId: 397968,
                    quantity: quantity,
                    priceData: nil
                )
                if let dto = try? await sdk.cart.addItem(cart_id: cid, line_items: [line]) {
                    serverId =
                        (dto.lineItems.last { $0.productId == 397968 } ?? dto.lineItems.last)?.id
                }
            }

            let cartItem = CartItem(
                id: serverId ?? UUID().uuidString,
                productId: 397968,
                variantId: product.variants.first?.id,
                title: product.title,
                brand: product.brand,
                imageUrl: product.images.first?.url,
                price: Double(product.price.amount),
                currency: product.price.currency_code,
                quantity: quantity,
                sku: product.sku
            )

            items.append(cartItem)

            await MainActor.run {
                ToastManager.shared.showSuccess("Added \(product.title) to cart")
            }
        }

        updateCartTotal()
        isLoading = false

        #if os(iOS)
            if itemCount > previousCount {
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
            }
        #endif
    }

    /// Remove an item from the cart
    public func removeItem(_ item: CartItem) async {
        isLoading = true
        errorMessage = nil

        items.removeAll { $0.id == item.id }
        updateCartTotal()

        if let cid = self.currentCartId, !cid.isEmpty {
            do {
                _ = try await sdk.cart.deleteItem(
                    cart_id: cid,
                    cart_item_id: item.id
                )
            } catch {
                let msg = (error as? SdkException)?.description ?? error.localizedDescription
                print("⚠️ [Cart] SDK.deleteItem failed: \(msg)")
            }
        } else {
            print("ℹ️ [Cart] removeItem: skipped SDK call (missing cartId)")
        }

        await MainActor.run {
            ToastManager.shared.showInfo("Removed \(item.title) from cart")
        }

        isLoading = false
    }

    /// Update item quantity
    public func updateQuantity(for item: CartItem, to newQuantity: Int) async {
        isLoading = true
        errorMessage = nil

        if let index = items.firstIndex(where: { $0.id == item.id }) {
            if newQuantity <= 0 {
                items.remove(at: index)
            } else {
                items[index] = CartItem(
                    id: item.id,
                    productId: item.productId,
                    variantId: item.variantId,
                    title: item.title,
                    brand: item.brand,
                    imageUrl: item.imageUrl,
                    price: item.price,
                    currency: item.currency,
                    quantity: newQuantity,
                    sku: item.sku
                )
            }
        }

        if let cid = self.currentCartId, !cid.isEmpty {
            if newQuantity <= 0 {
                do {
                    _ = try await sdk.cart.deleteItem(
                        cart_id: cid,
                        cart_item_id: item.id
                    )
                } catch {
                    let msg = (error as? SdkException)?.description ?? error.localizedDescription
                    print("⚠️ [Cart] SDK.deleteItem failed: \(msg)")
                }
            } else {
                do {
                    _ = try await sdk.cart.updateItem(
                        cart_id: cid,
                        cart_item_id: item.id,
                        shipping_id: nil,
                        quantity: newQuantity
                    )
                } catch {
                    let msg = (error as? SdkException)?.description ?? error.localizedDescription
                    print("⚠️ [Cart] SDK.updateItem failed: \(msg)")
                }
            }
        } else {
            print("ℹ️ [Cart] updateQuantity: skipped SDK call (missing cartId)")
        }

        updateCartTotal()
        isLoading = false
    }

    /// Show the checkout overlay
    public func showCheckout() {
        isCheckoutPresented = true
    }

    /// Hide the checkout overlay
    public func hideCheckout() {
        isCheckoutPresented = false
    }

    /// Clear the entire cart
    public func clearCart() async {
        isLoading = true
        errorMessage = nil

        items = []
        cartTotal = 0.0

        isLoading = false
    }

    /// Get the total number of items in cart
    public var itemCount: Int {
        items.reduce(0) { $0 + $1.quantity }
    }

    // MARK: - Private Methods

    /// Update the cart total and currency
    private func updateCartTotal() {
        cartTotal = items.reduce(0) { total, item in
            total + (item.price * Double(item.quantity))
        }

        // Use currency from first item, default to USD
        currency = items.first?.currency ?? "USD"
    }
}

// MARK: - Cart Errors
public enum CartError: LocalizedError {
    case noCartId
    case productNotFound
    case invalidQuantity

    public var errorDescription: String? {
        switch self {
        case .noCartId:
            return "No cart ID available"
        case .productNotFound:
            return "Product not found"
        case .invalidQuantity:
            return "Invalid quantity"
        }
    }
}

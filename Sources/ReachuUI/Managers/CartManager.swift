import SwiftUI
import ReachuCore
import Foundation

/// Global cart manager that handles cart state and checkout flow
@MainActor
public class CartManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published public var items: [CartItem] = []
    @Published public var isCheckoutPresented = false
    @Published public var isLoading = false
    @Published public var cartTotal: Double = 0.0
    @Published public var currency: String = "USD"
    @Published public var errorMessage: String?
    
    // MARK: - Private Properties
    private let sdkClient: SdkClient
    private var currentCartId: String?
    
    // MARK: - Initialization
    public init(sdkClient: SdkClient) {
        self.sdkClient = sdkClient
    }
    
    // MARK: - Cart Item Model
    public struct CartItem: Identifiable, Equatable {
        public let id: String
        public let productId: Int
        public let variantId: Int?
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
            variantId: Int? = nil,
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
        do {
            isLoading = true
            errorMessage = nil
            
            // Ensure we have a cart
            try await ensureCartExists()
            
            guard let cartId = currentCartId else {
                throw CartError.noCartId
                return
            }
            
            // Create line item input
            let lineItem = LineItemInput(
                productId: product.id,
                variantId: product.variants.first?.id,
                quantity: quantity,
                priceData: nil
            )
            
            // Add to backend cart using Miguel Angel's module
            let updatedCart = try await sdkClient.cart.addItem(
                cart_id: cartId,
                line_items: [lineItem]
            )
            
            // Update local state
            await updateLocalCart(from: updatedCart)
            
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Error adding product to cart: \(error)")
        }
        
        isLoading = false
    }
    
    /// Remove an item from the cart
    public func removeItem(_ item: CartItem) async {
        do {
            isLoading = true
            errorMessage = nil
            
            guard let cartId = currentCartId else {
                throw CartError.noCartId
            }
            
            // Remove from backend using Miguel Angel's module
            let updatedCart = try await sdkClient.cart.removeItem(
                cart_id: cartId,
                cart_item_id: item.id
            )
            
            // Update local state
            await updateLocalCart(from: updatedCart)
            
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Error removing item from cart: \(error)")
        }
        
        isLoading = false
    }
    
    /// Update item quantity
    public func updateQuantity(for item: CartItem, to newQuantity: Int) async {
        do {
            isLoading = true
            errorMessage = nil
            
            guard let cartId = currentCartId else {
                throw CartError.noCartId
            }
            
            // Update in backend using Miguel Angel's module
            let updatedCart = try await sdkClient.cart.updateItem(
                cart_id: cartId,
                cart_item_id: item.id,
                shipping_id: nil,
                quantity: newQuantity
            )
            
            // Update local state
            await updateLocalCart(from: updatedCart)
            
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Error updating item quantity: \(error)")
        }
        
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
        do {
            isLoading = true
            errorMessage = nil
            
            guard let cartId = currentCartId else {
                throw CartError.noCartId
            }
            
            // Delete cart using Miguel Angel's module
            _ = try await sdkClient.cart.delete(cart_id: cartId)
            
            // Reset local state
            items = []
            cartTotal = 0.0
            currentCartId = nil
            
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Error clearing cart: \(error)")
        }
        
        isLoading = false
    }
    
    /// Get the total number of items in cart
    public var itemCount: Int {
        items.reduce(0) { $0 + $1.quantity }
    }
    
    // MARK: - Private Methods
    
    /// Ensure a cart exists, create one if necessary
    private func ensureCartExists() async throws {
        if currentCartId == nil {
            let newCart = try await sdkClient.cart.create()
            currentCartId = newCart.cartId
            await updateLocalCart(from: newCart)
        }
    }
    
    /// Update local cart state from backend cart data
    private func updateLocalCart(from cartDto: CartDto) async {
        // Convert CartDto line items to local CartItem objects
        let cartItems = cartDto.lineItems.compactMap { lineItem -> CartItem? in
            guard let title = lineItem.title else { return nil }
            
            return CartItem(
                id: lineItem.id,
                productId: lineItem.productId,
                variantId: lineItem.variantId,
                title: title,
                brand: lineItem.brand,
                imageUrl: lineItem.image?.first?.url,
                price: lineItem.price.amount,
                currency: lineItem.price.currencyCode,
                quantity: lineItem.quantity,
                sku: lineItem.sku
            )
        }
        
        // Update published properties
        items = cartItems
        cartTotal = cartDto.subtotal + cartDto.shipping
        currency = cartDto.currency
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

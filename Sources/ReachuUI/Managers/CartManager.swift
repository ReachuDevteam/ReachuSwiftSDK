import SwiftUI
import ReachuCore
import ReachuDesignSystem
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
    private var currentCartId: String?
    
    // MARK: - Initialization
    public init() {
        // Initialize with empty cart
        self.currentCartId = UUID().uuidString
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
        
        // Check if product already exists in cart
        if let existingIndex = items.firstIndex(where: { $0.productId == product.id }) {
            // Update existing item quantity
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
            
            // Show update notification
            await MainActor.run {
                ToastManager.shared.showSuccess("Updated \(product.title) quantity in cart")
            }
        } else {
            // Add new item to cart
            let cartItem = CartItem(
                id: UUID().uuidString,
                productId: product.id,
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
            
            // Show add notification
            await MainActor.run {
                ToastManager.shared.showSuccess("Added \(product.title) to cart")
            }
        }
        
        updateCartTotal()
        isLoading = false
        
        // Trigger haptic feedback for cart count change
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
        
        // Show removal notification
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

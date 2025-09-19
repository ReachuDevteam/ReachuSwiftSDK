//
//  MockReachuService.swift
//  ReachuDemoApp
//
//  Mock service that simulates Reachu GraphQL API calls
//  This will be easily replaceable with real GraphQL client later
//

import Foundation
import Combine

/// Mock service that simulates Reachu GraphQL API
/// Interface matches what the real ReachuCore service will have
final class MockReachuService: ObservableObject {
    static let shared = MockReachuService()
    private let mockData = MockDataProvider.shared
    private init() {}
    
    // MARK: - Product Queries (Channel.products)
    
    /// Fetch all products
    func getProducts() async throws -> [Product] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        return mockData.sampleProducts
    }
    
    /// Fetch products by category
    func getProducts(categoryId: Int) async throws -> [Product] {
        try await Task.sleep(nanoseconds: 300_000_000)
        return mockData.getProductsByCategory(categoryId)
    }
    
    /// Search products
    func searchProducts(query: String) async throws -> [Product] {
        try await Task.sleep(nanoseconds: 400_000_000)
        return mockData.searchProducts(query: query)
    }
    
    /// Get single product by ID
    func getProduct(id: Int) async throws -> Product? {
        try await Task.sleep(nanoseconds: 200_000_000)
        return mockData.getProduct(by: id)
    }
    
    /// Get product categories
    func getCategories() async throws -> [Category] {
        try await Task.sleep(nanoseconds: 300_000_000)
        return mockData.categories
    }
    
    // MARK: - Cart Queries & Mutations
    
    /// Get current cart
    func getCart() async throws -> Cart {
        try await Task.sleep(nanoseconds: 200_000_000)
        return mockData.sampleCart
    }
    
    /// Add product to cart
    func addToCart(productId: Int, variantId: Int?, quantity: Int) async throws -> Cart {
        try await Task.sleep(nanoseconds: 400_000_000)
        
        // In real implementation, this would call:
        // mutation { Cart { addItem(productId: $productId, variantId: $variantId, quantity: $quantity) } }
        
        // For now, return updated mock cart
        return mockData.sampleCart
    }
    
    /// Update cart item quantity
    func updateCartItem(itemId: String, quantity: Int) async throws -> Cart {
        try await Task.sleep(nanoseconds: 300_000_000)
        return mockData.sampleCart
    }
    
    /// Remove item from cart
    func removeFromCart(itemId: String) async throws -> Cart {
        try await Task.sleep(nanoseconds: 300_000_000)
        return mockData.sampleCart
    }
    
    /// Clear entire cart
    func clearCart() async throws -> Cart {
        try await Task.sleep(nanoseconds: 200_000_000)
        // Return empty cart
        return Cart(
            id: "empty_cart",
            items: [],
            totalPrice: Price(amount: 0, currency: "USD", displayAmount: "$0.00"),
            itemCount: 0,
            createdAt: ISO8601DateFormatter().string(from: Date()),
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )
    }
    
    // MARK: - Checkout Queries & Mutations
    
    /// Create checkout from cart
    func createCheckout(cartId: String) async throws -> Checkout {
        try await Task.sleep(nanoseconds: 500_000_000)
        return mockData.sampleCheckout
    }
    
    /// Update checkout customer info
    func updateCheckoutCustomer(checkoutId: String, customer: Customer) async throws -> Checkout {
        try await Task.sleep(nanoseconds: 300_000_000)
        return mockData.sampleCheckout
    }
    
    /// Update checkout shipping address
    func updateCheckoutShippingAddress(checkoutId: String, address: Address) async throws -> Checkout {
        try await Task.sleep(nanoseconds: 300_000_000)
        return mockData.sampleCheckout
    }
    
    /// Get available shipping methods
    func getShippingMethods(checkoutId: String) async throws -> [ShippingMethod] {
        try await Task.sleep(nanoseconds: 400_000_000)
        return mockData.shippingMethods
    }
    
    /// Update checkout shipping method
    func updateCheckoutShippingMethod(checkoutId: String, shippingMethodId: String) async throws -> Checkout {
        try await Task.sleep(nanoseconds: 300_000_000)
        return mockData.sampleCheckout
    }
    
    /// Complete checkout (process payment)
    func completeCheckout(checkoutId: String, paymentMethodId: String) async throws -> Checkout {
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second for payment processing
        
        // Return completed checkout
        var completedCheckout = mockData.sampleCheckout
        // In a real implementation, this would be properly handled
        return completedCheckout
    }
    
    // MARK: - Payment Methods
    
    /// Get available payment methods
    func getPaymentMethods() async throws -> [PaymentMethod] {
        try await Task.sleep(nanoseconds: 200_000_000)
        return mockData.paymentMethods
    }
    
    // MARK: - Discounts
    
    /// Get available discounts
    func getDiscounts() async throws -> [Discount] {
        try await Task.sleep(nanoseconds: 300_000_000)
        return mockData.availableDiscounts
    }
    
    /// Apply discount code to checkout
    func applyDiscount(checkoutId: String, discountCode: String) async throws -> Checkout {
        try await Task.sleep(nanoseconds: 400_000_000)
        
        // Simulate discount application
        if mockData.availableDiscounts.contains(where: { $0.code == discountCode }) {
            return mockData.sampleCheckout
        } else {
            throw MockServiceError.invalidDiscountCode
        }
    }
    
    /// Remove discount from checkout
    func removeDiscount(checkoutId: String, discountId: String) async throws -> Checkout {
        try await Task.sleep(nanoseconds: 300_000_000)
        return mockData.sampleCheckout
    }
}

// MARK: - Error Handling

enum MockServiceError: LocalizedError {
    case productNotFound
    case cartNotFound
    case checkoutNotFound
    case invalidDiscountCode
    case paymentFailed
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "Product not found"
        case .cartNotFound:
            return "Cart not found"
        case .checkoutNotFound:
            return "Checkout not found"
        case .invalidDiscountCode:
            return "Invalid discount code"
        case .paymentFailed:
            return "Payment processing failed"
        case .networkError:
            return "Network connection error"
        }
    }
}

// MARK: - Reactive Extensions for SwiftUI

extension MockReachuService {
    /// Publisher for cart updates (useful for real-time cart badge)
    var cartUpdatePublisher: AnyPublisher<Cart, Never> {
        // In real implementation, this would listen to GraphQL subscriptions
        Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .compactMap { _ in try? await self.getCart() }
            .catch { _ in Just(self.mockData.sampleCart) }
            .eraseToAnyPublisher()
    }
}

// MARK: - Migration Notes for Real GraphQL

/*
 When migrating to real GraphQL client:
 
 1. Replace MockReachuService with ReachuService from ReachuCore
 2. All method signatures should remain the same
 3. Error types can be mapped to GraphQL errors
 4. Publishers can use GraphQL subscriptions
 
 Example migration:
 
 // From:
 let products = try await MockReachuService.shared.getProducts()
 
 // To:
 let products = try await ReachuCore.shared.channel.products.all()
 
 The UI components won't need any changes!
 */

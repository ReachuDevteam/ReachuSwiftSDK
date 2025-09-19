//
//  ReachuModels.swift
//  ReachuDemoApp
//
//  Mock models based on Reachu GraphQL Schema
//  These models mirror the exact GraphQL schema structure
//

import Foundation

// MARK: - Product Models (from GraphQL schema)

struct Product: Identifiable, Codable {
    let id: Int
    let title: String
    let brand: String?
    let description: String?
    let tags: String
    let sku: String
    let quantity: Int?
    let price: Price
    let images: [ProductImage]
    let variants: [ProductVariant]
    let categories: [Category]
    let isActive: Bool
    let createdAt: String
    let updatedAt: String
}

struct Price: Codable {
    let amount: Double
    let currency: String
    let displayAmount: String
}

struct ProductImage: Identifiable, Codable {
    let id: Int
    let url: String
    let altText: String?
    let position: Int
}

struct ProductVariant: Identifiable, Codable {
    let id: Int
    let title: String
    let sku: String
    let price: Price
    let quantity: Int?
    let isActive: Bool
    let options: [VariantOption]
}

struct VariantOption: Identifiable, Codable {
    let id: Int
    let name: String
    let value: String
}

struct Category: Identifiable, Codable {
    let id: Int
    let name: String
    let description: String?
    let parentId: Int?
    let isActive: Bool
}

// MARK: - Cart Models (from GraphQL schema)

struct Cart: Identifiable, Codable {
    let id: String
    let items: [CartItem]
    let totalPrice: Price
    let itemCount: Int
    let createdAt: String
    let updatedAt: String
}

struct CartItem: Identifiable, Codable {
    let id: String
    let product: Product
    let variant: ProductVariant?
    let quantity: Int
    let unitPrice: Price
    let totalPrice: Price
    let addedAt: String
}

// MARK: - Checkout Models (from GraphQL schema)

struct Checkout: Identifiable, Codable {
    let id: String
    let cart: Cart
    let customer: Customer?
    let shippingAddress: Address?
    let billingAddress: Address?
    let shippingMethod: ShippingMethod?
    let paymentMethod: PaymentMethod?
    let subtotal: Price
    let shippingCost: Price
    let tax: Price
    let total: Price
    let status: CheckoutStatus
    let createdAt: String
    let updatedAt: String
}

struct Customer: Identifiable, Codable {
    let id: String
    let email: String
    let firstName: String?
    let lastName: String?
    let phone: String?
    let createdAt: String
}

struct Address: Identifiable, Codable {
    let id: String
    let firstName: String
    let lastName: String
    let company: String?
    let address1: String
    let address2: String?
    let city: String
    let province: String?
    let country: String
    let zip: String
    let phone: String?
}

struct ShippingMethod: Identifiable, Codable {
    let id: String
    let name: String
    let description: String?
    let price: Price
    let estimatedDelivery: String?
}

struct PaymentMethod: Identifiable, Codable {
    let id: String
    let name: String
    let type: PaymentType
    let isActive: Bool
}

enum CheckoutStatus: String, Codable, CaseIterable {
    case pending = "PENDING"
    case processing = "PROCESSING"
    case completed = "COMPLETED"
    case cancelled = "CANCELLED"
}

enum PaymentType: String, Codable, CaseIterable {
    case creditCard = "CREDIT_CARD"
    case debitCard = "DEBIT_CARD"
    case paypal = "PAYPAL"
    case applePay = "APPLE_PAY"
    case googlePay = "GOOGLE_PAY"
    case bankTransfer = "BANK_TRANSFER"
}

// MARK: - Market Models (from GraphQL schema)

struct Market: Identifiable, Codable {
    let id: String
    let name: String
    let description: String?
    let currency: String
    let isActive: Bool
    let timezone: String
    let locale: String
}

// MARK: - Discount Models (from GraphQL schema)

struct Discount: Identifiable, Codable {
    let id: String
    let code: String
    let name: String
    let description: String?
    let type: DiscountType
    let value: Double
    let minOrderAmount: Price?
    let maxUsage: Int?
    let currentUsage: Int
    let isActive: Bool
    let startsAt: String?
    let endsAt: String?
}

enum DiscountType: String, Codable, CaseIterable {
    case percentage = "PERCENTAGE"
    case fixedAmount = "FIXED_AMOUNT"
    case freeShipping = "FREE_SHIPPING"
}

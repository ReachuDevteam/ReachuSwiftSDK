//
//  MockDataProvider.swift
//  ReachuDemoApp
//
//  Mock data provider with realistic Reachu ecommerce data
//  Based on GraphQL schema structure
//

import Foundation

final class MockDataProvider {
    static let shared = MockDataProvider()
    private init() {}
    
    // MARK: - Products
    
    lazy var sampleProducts: [Product] = [
        Product(
            id: 1,
            title: "Reachu Premium Wireless Headphones",
            brand: "Reachu",
            description: "High-quality wireless headphones with noise cancellation and 30-hour battery life. Perfect for work, travel, and everyday listening.",
            tags: "electronics,audio,wireless,premium",
            sku: "RCH-WH-001",
            quantity: 25,
            price: Price(amount: 199.99, currency: "USD", displayAmount: "$199.99"),
            images: [
                ProductImage(id: 1, url: "https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=800", altText: "Reachu Wireless Headphones", position: 1),
                ProductImage(id: 2, url: "https://images.unsplash.com/photo-1583394838336-acd977736f90?w=800", altText: "Headphones Side View", position: 2)
            ],
            variants: [
                ProductVariant(
                    id: 1,
                    title: "Black",
                    sku: "RCH-WH-001-BLK",
                    price: Price(amount: 199.99, currency: "USD", displayAmount: "$199.99"),
                    quantity: 15,
                    isActive: true,
                    options: [VariantOption(id: 1, name: "Color", value: "Black")]
                ),
                ProductVariant(
                    id: 2,
                    title: "White",
                    sku: "RCH-WH-001-WHT",
                    price: Price(amount: 199.99, currency: "USD", displayAmount: "$199.99"),
                    quantity: 10,
                    isActive: true,
                    options: [VariantOption(id: 2, name: "Color", value: "White")]
                )
            ],
            categories: [electronicsCategory],
            isActive: true,
            createdAt: "2024-01-15T10:00:00Z",
            updatedAt: "2024-09-19T15:30:00Z"
        ),
        
        Product(
            id: 2,
            title: "Reachu Smart Watch Series 5",
            brand: "Reachu",
            description: "Advanced smartwatch with health monitoring, GPS, and week-long battery life. Stay connected and track your fitness goals.",
            tags: "wearables,smartwatch,fitness,health",
            sku: "RCH-SW-005",
            quantity: 40,
            price: Price(amount: 349.99, currency: "USD", displayAmount: "$349.99"),
            images: [
                ProductImage(id: 3, url: "https://images.unsplash.com/photo-1544117519-31a4b719223d?w=800", altText: "Reachu Smart Watch", position: 1),
                ProductImage(id: 4, url: "https://images.unsplash.com/photo-1579586337278-3f436f25d4d6?w=800", altText: "Smart Watch Features", position: 2)
            ],
            variants: [
                ProductVariant(
                    id: 3,
                    title: "42mm Space Gray",
                    sku: "RCH-SW-005-42-SG",
                    price: Price(amount: 349.99, currency: "USD", displayAmount: "$349.99"),
                    quantity: 20,
                    isActive: true,
                    options: [
                        VariantOption(id: 3, name: "Size", value: "42mm"),
                        VariantOption(id: 4, name: "Color", value: "Space Gray")
                    ]
                ),
                ProductVariant(
                    id: 4,
                    title: "44mm Silver",
                    sku: "RCH-SW-005-44-SV",
                    price: Price(amount: 379.99, currency: "USD", displayAmount: "$379.99"),
                    quantity: 20,
                    isActive: true,
                    options: [
                        VariantOption(id: 5, name: "Size", value: "44mm"),
                        VariantOption(id: 6, name: "Color", value: "Silver")
                    ]
                )
            ],
            categories: [wearablesCategory],
            isActive: true,
            createdAt: "2024-02-01T14:30:00Z",
            updatedAt: "2024-09-19T15:30:00Z"
        ),
        
        Product(
            id: 3,
            title: "Reachu Minimalist Backpack",
            brand: "Reachu",
            description: "Sleek and functional backpack perfect for work and travel. Water-resistant material with laptop compartment and multiple pockets.",
            tags: "accessories,backpack,travel,work",
            sku: "RCH-BP-001",
            quantity: 60,
            price: Price(amount: 89.99, currency: "USD", displayAmount: "$89.99"),
            images: [
                ProductImage(id: 5, url: "https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=800", altText: "Reachu Backpack", position: 1),
                ProductImage(id: 6, url: "https://images.unsplash.com/photo-1581605405669-fcdf81165afa?w=800", altText: "Backpack Interior", position: 2)
            ],
            variants: [
                ProductVariant(
                    id: 5,
                    title: "Charcoal",
                    sku: "RCH-BP-001-CHR",
                    price: Price(amount: 89.99, currency: "USD", displayAmount: "$89.99"),
                    quantity: 30,
                    isActive: true,
                    options: [VariantOption(id: 7, name: "Color", value: "Charcoal")]
                ),
                ProductVariant(
                    id: 6,
                    title: "Navy",
                    sku: "RCH-BP-001-NVY",
                    price: Price(amount: 89.99, currency: "USD", displayAmount: "$89.99"),
                    quantity: 30,
                    isActive: true,
                    options: [VariantOption(id: 8, name: "Color", value: "Navy")]
                )
            ],
            categories: [accessoriesCategory],
            isActive: true,
            createdAt: "2024-03-10T09:15:00Z",
            updatedAt: "2024-09-19T15:30:00Z"
        ),
        
        Product(
            id: 4,
            title: "Reachu Wireless Charging Pad",
            brand: "Reachu",
            description: "Fast wireless charging pad compatible with all Qi-enabled devices. Sleek design with LED charging indicator.",
            tags: "electronics,charging,wireless,accessories",
            sku: "RCH-WC-001",
            quantity: 0, // Out of stock
            price: Price(amount: 39.99, currency: "USD", displayAmount: "$39.99"),
            images: [
                ProductImage(id: 7, url: "https://images.unsplash.com/photo-1586953208448-b95a79798f07?w=800", altText: "Wireless Charging Pad", position: 1)
            ],
            variants: [
                ProductVariant(
                    id: 7,
                    title: "Black",
                    sku: "RCH-WC-001-BLK",
                    price: Price(amount: 39.99, currency: "USD", displayAmount: "$39.99"),
                    quantity: 0,
                    isActive: true,
                    options: [VariantOption(id: 9, name: "Color", value: "Black")]
                )
            ],
            categories: [electronicsCategory],
            isActive: true,
            createdAt: "2024-04-05T16:20:00Z",
            updatedAt: "2024-09-19T15:30:00Z"
        )
    ]
    
    // MARK: - Categories
    
    lazy var electronicsCategory = Category(
        id: 1,
        name: "Electronics",
        description: "Latest electronic devices and gadgets",
        parentId: nil,
        isActive: true
    )
    
    lazy var wearablesCategory = Category(
        id: 2,
        name: "Wearables",
        description: "Smart watches and wearable technology",
        parentId: 1, // Child of Electronics
        isActive: true
    )
    
    lazy var accessoriesCategory = Category(
        id: 3,
        name: "Accessories",
        description: "Bags, cases, and lifestyle accessories",
        parentId: nil,
        isActive: true
    )
    
    lazy var categories: [Category] = [
        electronicsCategory,
        wearablesCategory,
        accessoriesCategory
    ]
    
    // MARK: - Cart
    
    lazy var sampleCart: Cart = {
        let items = [
            CartItem(
                id: "cart_item_1",
                product: sampleProducts[0], // Headphones
                variant: sampleProducts[0].variants[0], // Black variant
                quantity: 1,
                unitPrice: sampleProducts[0].price,
                totalPrice: sampleProducts[0].price,
                addedAt: "2024-09-19T14:00:00Z"
            ),
            CartItem(
                id: "cart_item_2",
                product: sampleProducts[2], // Backpack
                variant: sampleProducts[2].variants[0], // Charcoal variant
                quantity: 2,
                unitPrice: sampleProducts[2].price,
                totalPrice: Price(amount: 179.98, currency: "USD", displayAmount: "$179.98"),
                addedAt: "2024-09-19T14:15:00Z"
            )
        ]
        
        let total = Price(amount: 379.97, currency: "USD", displayAmount: "$379.97")
        
        return Cart(
            id: "cart_sample_123",
            items: items,
            totalPrice: total,
            itemCount: 3,
            createdAt: "2024-09-19T14:00:00Z",
            updatedAt: "2024-09-19T14:15:00Z"
        )
    }()
    
    // MARK: - Customer & Addresses
    
    lazy var sampleCustomer = Customer(
        id: "customer_123",
        email: "john.doe@example.com",
        firstName: "John",
        lastName: "Doe",
        phone: "+1-555-0123",
        createdAt: "2024-01-01T00:00:00Z"
    )
    
    lazy var sampleShippingAddress = Address(
        id: "addr_shipping_1",
        firstName: "John",
        lastName: "Doe",
        company: nil,
        address1: "123 Main Street",
        address2: "Apt 4B",
        city: "New York",
        province: "NY",
        country: "United States",
        zip: "10001",
        phone: "+1-555-0123"
    )
    
    // MARK: - Shipping & Payment Methods
    
    lazy var shippingMethods: [ShippingMethod] = [
        ShippingMethod(
            id: "shipping_standard",
            name: "Standard Shipping",
            description: "5-7 business days",
            price: Price(amount: 9.99, currency: "USD", displayAmount: "$9.99"),
            estimatedDelivery: "September 26, 2024"
        ),
        ShippingMethod(
            id: "shipping_express",
            name: "Express Shipping",
            description: "2-3 business days",
            price: Price(amount: 19.99, currency: "USD", displayAmount: "$19.99"),
            estimatedDelivery: "September 22, 2024"
        ),
        ShippingMethod(
            id: "shipping_overnight",
            name: "Overnight Shipping",
            description: "Next business day",
            price: Price(amount: 39.99, currency: "USD", displayAmount: "$39.99"),
            estimatedDelivery: "September 20, 2024"
        )
    ]
    
    lazy var paymentMethods: [PaymentMethod] = [
        PaymentMethod(id: "pm_credit_card", name: "Credit Card", type: .creditCard, isActive: true),
        PaymentMethod(id: "pm_paypal", name: "PayPal", type: .paypal, isActive: true),
        PaymentMethod(id: "pm_apple_pay", name: "Apple Pay", type: .applePay, isActive: true),
        PaymentMethod(id: "pm_google_pay", name: "Google Pay", type: .googlePay, isActive: true)
    ]
    
    // MARK: - Sample Checkout
    
    lazy var sampleCheckout: Checkout = {
        let subtotal = sampleCart.totalPrice
        let shipping = shippingMethods[0].price
        let tax = Price(amount: 30.40, currency: "USD", displayAmount: "$30.40")
        let total = Price(amount: 420.36, currency: "USD", displayAmount: "$420.36")
        
        return Checkout(
            id: "checkout_abc123",
            cart: sampleCart,
            customer: sampleCustomer,
            shippingAddress: sampleShippingAddress,
            billingAddress: sampleShippingAddress,
            shippingMethod: shippingMethods[0],
            paymentMethod: paymentMethods[0],
            subtotal: subtotal,
            shippingCost: shipping,
            tax: tax,
            total: total,
            status: .pending,
            createdAt: "2024-09-19T15:00:00Z",
            updatedAt: "2024-09-19T15:00:00Z"
        )
    }()
    
    // MARK: - Discounts
    
    lazy var availableDiscounts: [Discount] = [
        Discount(
            id: "discount_welcome10",
            code: "WELCOME10",
            name: "Welcome Discount",
            description: "10% off your first order",
            type: .percentage,
            value: 10.0,
            minOrderAmount: Price(amount: 50.0, currency: "USD", displayAmount: "$50.00"),
            maxUsage: 1000,
            currentUsage: 450,
            isActive: true,
            startsAt: "2024-01-01T00:00:00Z",
            endsAt: "2024-12-31T23:59:59Z"
        ),
        Discount(
            id: "discount_freeship",
            code: "FREESHIP",
            name: "Free Shipping",
            description: "Free shipping on orders over $100",
            type: .freeShipping,
            value: 0.0,
            minOrderAmount: Price(amount: 100.0, currency: "USD", displayAmount: "$100.00"),
            maxUsage: nil,
            currentUsage: 2450,
            isActive: true,
            startsAt: "2024-06-01T00:00:00Z",
            endsAt: nil
        )
    ]
}

// MARK: - Convenience Extensions

extension MockDataProvider {
    func getProduct(by id: Int) -> Product? {
        return sampleProducts.first { $0.id == id }
    }
    
    func getProductsByCategory(_ categoryId: Int) -> [Product] {
        return sampleProducts.filter { product in
            product.categories.contains { $0.id == categoryId }
        }
    }
    
    func searchProducts(query: String) -> [Product] {
        let lowercaseQuery = query.lowercased()
        return sampleProducts.filter { product in
            product.title.lowercased().contains(lowercaseQuery) ||
            product.description?.lowercased().contains(lowercaseQuery) == true ||
            product.tags.lowercased().contains(lowercaseQuery)
        }
    }
}

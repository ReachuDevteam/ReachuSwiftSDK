import Foundation
import ReachuCore

/// Mock data provider for testing and previews
public class MockDataProvider {
    public static let shared = MockDataProvider()
    
    private init() {}
    
    // MARK: - Simple Product Model for UI Components
    
    public struct SimpleProduct: Identifiable {
        public let id: Int
        public let title: String
        public let brand: String?
        public let description: String?
        public let price: Double
        public let currency: String
        public let compareAtPrice: Double?
        public let imageUrl: String?
        public let isInStock: Bool
        
        public init(
            id: Int,
            title: String,
            brand: String? = nil,
            description: String? = nil,
            price: Double,
            currency: String,
            compareAtPrice: Double? = nil,
            imageUrl: String? = nil,
            isInStock: Bool = true
        ) {
            self.id = id
            self.title = title
            self.brand = brand
            self.description = description
            self.price = price
            self.currency = currency
            self.compareAtPrice = compareAtPrice
            self.imageUrl = imageUrl
            self.isInStock = isInStock
        }
    }
    
    // MARK: - Sample Products
    
    public let sampleProducts: [SimpleProduct] = [
        SimpleProduct(
            id: 101,
            title: "Reachu Wireless Headphones",
            brand: "Reachu Audio",
            description: "Experience immersive sound with premium noise-cancelling technology and crystal clear audio quality.",
            price: 199.99,
            currency: "USD",
            compareAtPrice: 249.99,
            imageUrl: "https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=400&h=300&fit=crop&crop=center",
            isInStock: true
        ),
        
        SimpleProduct(
            id: 102,
            title: "Reachu Smart Watch Series 5",
            brand: "Reachu Wearables",
            description: "Track your fitness, monitor your health, and stay connected with our latest smartwatch featuring advanced sensors.",
            price: 349.99,
            currency: "USD",
            imageUrl: "https://images.unsplash.com/photo-1434493789847-2f02dc6ca35d?w=400&h=300&fit=crop&crop=center",
            isInStock: true
        ),
        
        SimpleProduct(
            id: 103,
            title: "Reachu Minimalist Backpack",
            brand: "Reachu Gear",
            description: "Stylish and durable backpack perfect for daily commutes, travel, and outdoor adventures.",
            price: 89.99,
            currency: "USD",
            compareAtPrice: 100.00,
            imageUrl: "https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=400&h=300&fit=crop&crop=center",
            isInStock: false
        ),
        
        SimpleProduct(
            id: 104,
            title: "Reachu Wireless Charging Pad",
            brand: "Reachu Power",
            description: "Fast and convenient wireless charging for all your devices with sleek design and safety features.",
            price: 39.99,
            currency: "USD",
            imageUrl: "https://images.unsplash.com/photo-1585338447937-7082f8fc763d?w=400&h=300&fit=crop&crop=center",
            isInStock: true
        ),
        
        SimpleProduct(
            id: 105,
            title: "Reachu Bluetooth Speaker",
            brand: "Reachu Audio",
            description: "Portable bluetooth speaker with 360-degree sound, waterproof design, and 12-hour battery life.",
            price: 79.99,
            currency: "USD",
            compareAtPrice: 99.99,
            imageUrl: "https://images.unsplash.com/photo-1608043152269-423dbba4e7e1?w=400&h=300&fit=crop&crop=center",
            isInStock: true
        ),
        
        SimpleProduct(
            id: 106,
            title: "Reachu Gaming Mouse",
            brand: "Reachu Gaming",
            description: "High-precision gaming mouse with customizable RGB lighting and ergonomic design.",
            price: 59.99,
            currency: "USD",
            imageUrl: "https://images.unsplash.com/photo-1527814050087-3793815479db?w=400&h=300&fit=crop&crop=center",
            isInStock: true
        )
    ]
    
    // MARK: - Conversion to ProductDto (when needed)
    
    /// Convert SimpleProduct to ProductDto format for SDK integration
    /// This will be used when integrating with Miguel Angel's modules
    public func convertToProductDto(_ product: SimpleProduct) -> ProductDto? {
        // TODO: Implement conversion when needed for SDK integration
        // For now, return nil as this requires proper JSON data structure
        return nil
    }
}
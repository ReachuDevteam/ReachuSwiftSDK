import Foundation
import ReachuCore

/// Shared service for loading products across all components
/// Eliminates code duplication and provides consistent error handling
@MainActor
public class ProductService {
    
    // MARK: - Singleton
    public static let shared = ProductService()
    
    // MARK: - Private Properties
    private var cachedSdkClient: SdkClient?
    private let sdkClientQueue = DispatchQueue(label: "com.reachu.productsdk")
    
    private init() {}
    
    // MARK: - SDK Client Management
    
    /// Get or create SDK client (thread-safe)
    private func getSdkClient() throws -> SdkClient {
        if let cached = cachedSdkClient {
            return cached
        }
        
        let config = ReachuConfiguration.shared
        
        guard let baseURL = URL(string: config.environment.graphQLURL) else {
            throw ProductServiceError.invalidConfiguration("Invalid GraphQL URL: \(config.environment.graphQLURL)")
        }
        
        let apiKey = config.apiKey.isEmpty ? "DEMO_KEY" : config.apiKey
        
        let client = SdkClient(baseUrl: baseURL, apiKey: apiKey)
        cachedSdkClient = client
        
        ReachuLogger.debug("Created SDK client", component: "ProductService")
        
        return client
    }
    
    /// Clear cached SDK client (useful for testing or reconfiguration)
    public func clearCache() {
        cachedSdkClient = nil
        ReachuLogger.debug("Cleared SDK client cache", component: "ProductService")
    }
    
    // MARK: - Product Loading
    
    /// Load a single product by ID
    /// - Parameters:
    ///   - productId: Product ID (as String, will be converted to Int)
    ///   - currency: Currency code (e.g., "USD", "EUR")
    ///   - country: Country code (e.g., "US", "DE")
    /// - Returns: Product if found, nil otherwise
    /// - Throws: ProductServiceError for various error conditions
    public func loadProduct(
        productId: String,
        currency: String,
        country: String
    ) async throws -> Product {
        guard let productIdInt = Int(productId) else {
            throw ProductServiceError.invalidProductId(productId)
        }
        
        return try await loadProduct(productId: productIdInt, currency: currency, country: country)
    }
    
    /// Load a single product by ID
    /// - Parameters:
    ///   - productId: Product ID (as Int)
    ///   - currency: Currency code (e.g., "USD", "EUR")
    ///   - country: Country code (e.g., "US", "DE")
    ///   - imageSize: Image size ("small", "medium", "large", "thumbnail"). Defaults to "medium" for better performance
    /// - Returns: Product if found
    /// - Throws: ProductServiceError for various error conditions
    public func loadProduct(
        productId: Int,
        currency: String,
        country: String,
        imageSize: String = "medium"
    ) async throws -> Product {
        ReachuLogger.debug("Loading product with ID: \(productId)", component: "ProductService")
        ReachuLogger.debug("Currency: \(currency), Country: \(country), ImageSize: \(imageSize)", component: "ProductService")
        
        let sdk = try getSdkClient()
        
        let dtoProducts = try await sdk.channel.product.get(
            currency: currency,
            imageSize: "large",
            barcodeList: nil as [String]?,
            categoryIds: nil as [Int]?,
            productIds: [productId],
            skuList: nil as [String]?,
            useCache: true,
            shippingCountryCode: country
        )
        
        guard let dtoProduct = dtoProducts.first else {
            ReachuLogger.warning("Product not found for ID: \(productId)", component: "ProductService")
            throw ProductServiceError.productNotFound(productId)
        }
        
        let product = dtoProduct.toDomainProduct()
        ReachuLogger.success("Loaded product: \(product.title)", component: "ProductService")
        
        return product
    }
    
    /// Load multiple products by IDs
    /// - Parameters:
    ///   - productIds: Array of product IDs. If empty or nil, loads all products from channel
    ///   - currency: Currency code (e.g., "USD", "EUR")
    ///   - country: Country code (e.g., "US", "DE")
    /// - Returns: Array of products found
    /// - Throws: ProductServiceError for various error conditions
    public func loadProducts(
        productIds: [Int]?,
        currency: String,
        country: String
    ) async throws -> [Product] {
        let idsToUse = productIds
        
        if let ids = idsToUse, !ids.isEmpty {
            ReachuLogger.debug("Loading products with IDs: \(ids)", component: "ProductService")
        } else {
            ReachuLogger.debug("No product IDs provided - loading all products from channel", component: "ProductService")
        }
        
        ReachuLogger.debug("Currency: \(currency), Country: \(country)", component: "ProductService")
        
        let sdk = try getSdkClient()
        
        let dtoProducts = try await sdk.channel.product.get(
            currency: currency,
            imageSize: "large",
            barcodeList: nil as [String]?,
            categoryIds: nil as [Int]?,
            productIds: idsToUse,
            skuList: nil as [String]?,
            useCache: true,
            shippingCountryCode: country
        )
        
        ReachuLogger.info("API returned \(dtoProducts.count) products", component: "ProductService")
        
        if let ids = idsToUse, !ids.isEmpty, dtoProducts.count < ids.count {
            let foundIds = Set(dtoProducts.map { $0.id })
            let requestedIds = Set(ids)
            let missingIds = requestedIds.subtracting(foundIds)
            ReachuLogger.warning(
                "Only found \(dtoProducts.count) out of \(ids.count) products. Missing IDs: \(missingIds.sorted())",
                component: "ProductService"
            )
        }
        
        let products = dtoProducts.map { $0.toDomainProduct() }
        ReachuLogger.success("Loaded \(products.count) products", component: "ProductService")
        
        return products
    }
    
    /// Load products by category ID
    /// - Parameters:
    ///   - categoryId: Category ID to filter products
    ///   - currency: Currency code (e.g., "USD", "EUR")
    ///   - country: Country code (e.g., "US", "DE")
    /// - Returns: Array of products found in the category
    /// - Throws: ProductServiceError for various error conditions
    public func loadProductsByCategory(
        categoryId: Int,
        currency: String,
        country: String
    ) async throws -> [Product] {
        ReachuLogger.debug("Loading products for category ID: \(categoryId)", component: "ProductService")
        ReachuLogger.debug("Currency: \(currency), Country: \(country)", component: "ProductService")
        
        let sdk = try getSdkClient()
        
        let dtoProducts = try await sdk.channel.product.get(
            currency: currency,
            imageSize: "large",
            barcodeList: nil as [String]?,
            categoryIds: [categoryId],
            productIds: nil as [Int]?,
            skuList: nil as [String]?,
            useCache: true,
            shippingCountryCode: country
        )
        
        ReachuLogger.info("API returned \(dtoProducts.count) products for category \(categoryId)", component: "ProductService")
        
        let products = dtoProducts.map { $0.toDomainProduct() }
        ReachuLogger.success("Loaded \(products.count) products for category", component: "ProductService")
        
        return products
    }
}

// MARK: - ProductServiceError

public enum ProductServiceError: LocalizedError {
    case invalidConfiguration(String)
    case invalidProductId(String)
    case productNotFound(Int)
    case sdkError(SdkException)
    case networkError(Error)
    
    public var errorDescription: String? {
        switch self {
        case .invalidConfiguration(let message):
            return "Invalid configuration: \(message)"
        case .invalidProductId(let id):
            return "Invalid product ID format: \(id)"
        case .productNotFound(let id):
            return "Product not found: \(id)"
        case .sdkError(let error):
            return error.message
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}


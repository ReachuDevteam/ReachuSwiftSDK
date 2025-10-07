import Foundation
import ReachuCore
import SwiftUI

/// Internal ViewModel for RProductSlider
/// Handles automatic product loading from the API
@MainActor
class RProductSliderViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var products: [Product] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private var hasLoaded: Bool = false
    
    private var sdk: SdkClient {
        let config = ReachuConfiguration.shared
        let baseURL = URL(string: config.environment.graphQLURL)!
        let apiKey = config.apiKey.isEmpty ? "DEMO_KEY" : config.apiKey
        return SdkClient(baseUrl: baseURL, apiKey: apiKey)
    }
    
    // MARK: - Public Methods
    
    /// Load products from the API
    /// - Parameters:
    ///   - categoryId: Optional category filter
    ///   - currency: Currency code (defaults to USD)
    ///   - country: Country code for shipping (defaults to US)
    ///   - forceRefresh: Force reload even if already loaded
    func loadProducts(
        categoryId: Int? = nil,
        currency: String = "USD",
        country: String = "US",
        forceRefresh: Bool = false
    ) async {
        // Skip if already loaded and not forcing refresh
        guard !hasLoaded || forceRefresh else { return }
        
        // Skip if already loading
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        print("🛍️ [RProductSlider] Loading products from API...")
        print("   Currency: \(currency), Country: \(country)")
        if let catId = categoryId {
            print("   Category: \(catId)")
        }
        
        do {
            let dtoProducts = try await sdk.channel.product.get(
                currency: currency,
                imageSize: "large",
                barcodeList: nil,
                categoryIds: categoryId != nil ? [categoryId!] : nil,
                productIds: nil,
                skuList: nil,
                useCache: true,
                shippingCountryCode: country
            )
            
            products = dtoProducts.map { $0.toDomainProduct() }
            hasLoaded = true
            
            print("✅ [RProductSlider] Loaded \(products.count) products")
            
        } catch let error as SdkException {
            errorMessage = error.description
            print("❌ [RProductSlider] Failed to load products: \(error.description)")
        } catch {
            errorMessage = error.localizedDescription
            print("❌ [RProductSlider] Failed to load products: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    /// Reload products (force refresh)
    func reload(categoryId: Int? = nil, currency: String = "USD", country: String = "US") async {
        hasLoaded = false
        await loadProducts(categoryId: categoryId, currency: currency, country: country, forceRefresh: true)
    }
}

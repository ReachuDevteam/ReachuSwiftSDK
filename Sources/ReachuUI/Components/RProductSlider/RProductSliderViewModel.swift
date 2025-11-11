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
    @Published var isMarketUnavailable: Bool = false  // True when market/404 error occurs
    
    // MARK: - Private Properties
    private var hasLoaded: Bool = false
    
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
        // Check if SDK should be used before attempting operations
        guard ReachuConfiguration.shared.shouldUseSDK else {
            ReachuLogger.warning("Skipping product load - SDK disabled (market not available)", component: "RProductSlider")
            isMarketUnavailable = true
            isLoading = false
            return
        }
        
        // Skip if already loaded and not forcing refresh
        guard !hasLoaded || forceRefresh else { return }
        
        // Skip if already loading
        guard !isLoading else { return }
        
        if forceRefresh {
            products = []
            hasLoaded = false
        }

        isLoading = true
        errorMessage = nil
        isMarketUnavailable = false
        
        if let catId = categoryId {
            ReachuLogger.debug("Loading products for category: \(catId)", component: "RProductSlider")
        } else {
            ReachuLogger.debug("Loading all products from channel", component: "RProductSlider")
        }
        ReachuLogger.debug("Currency: \(currency), Country: \(country)", component: "RProductSlider")
        
        do {
            let loadedProducts: [Product]
            
            if let catId = categoryId {
                // Load products by category
                loadedProducts = try await ProductService.shared.loadProductsByCategory(
                    categoryId: catId,
                    currency: currency,
                    country: country
                )
            } else {
                // Load all products from channel
                loadedProducts = try await ProductService.shared.loadProducts(
                    productIds: nil,
                    currency: currency,
                    country: country
                )
            }
            
            products = loadedProducts
            hasLoaded = true
            
        } catch ProductServiceError.sdkError(let error) {
            // Only show error if it's not a NOT_FOUND error
            if error.code == "NOT_FOUND" || error.status == 404 {
                isMarketUnavailable = true
                errorMessage = nil
                ReachuLogger.warning("Market not available for \(currency)/\(country) - hiding component", component: "RProductSlider")
            } else {
                errorMessage = error.message
                ReachuLogger.error("Failed to load products: \(error.message)", component: "RProductSlider")
            }
        } catch ProductServiceError.invalidConfiguration(let message) {
            errorMessage = message
            ReachuLogger.error("Invalid configuration: \(message)", component: "RProductSlider")
        } catch ProductServiceError.networkError(let error) {
            errorMessage = error.localizedDescription
            ReachuLogger.error("Network error: \(error.localizedDescription)", component: "RProductSlider")
        } catch {
            errorMessage = error.localizedDescription
            ReachuLogger.error("Failed to load products: \(error.localizedDescription)", component: "RProductSlider")
        }
        
        isLoading = false
    }
    
    /// Reload products (force refresh)
    func reload(categoryId: Int? = nil, currency: String = "USD", country: String = "US") async {
        hasLoaded = false
        await loadProducts(categoryId: categoryId, currency: currency, country: country, forceRefresh: true)
    }
    
    /// Clear products (used when campaign becomes inactive)
    func clearProducts() {
        products = []
        hasLoaded = false
        isLoading = false
        errorMessage = nil
        isMarketUnavailable = false
    }
}

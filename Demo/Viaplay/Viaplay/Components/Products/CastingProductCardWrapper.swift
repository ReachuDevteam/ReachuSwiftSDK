//
//  CastingProductCardWrapper.swift
//  Viaplay
//
//  Wrapper component that uses REngagementProductGridCard from SDK
//  Converts CastingProductEvent to SDK component format
//

import SwiftUI
import VioCore
import VioUI
import VioEngagementUI
import VioDesignSystem

struct CastingProductCardWrapper: View {
    let productEvent: CastingProductEvent
    let onViewProduct: () -> Void
    
    @State private var products: [Product] = []
    @State private var isLoadingProducts = false
    @State private var showModal = false
    @State private var selectedProductEvent: CastingProductEvent?
    
    @EnvironmentObject private var cartManager: CartManager
    
    var body: some View {
        let brandConfig = VioConfiguration.shared.brandConfiguration
        
        return REngagementProductGridCard(
            products: convertProductsToSDKFormat(products),
            promotionalText: productEvent.description.isEmpty ? "Ikke gå glipp av denne muligheten - 25% rabatt kun under kampen" : productEvent.description,
            brandName: brandConfig.name,
            brandIcon: brandConfig.iconAsset,
            displayTime: productEvent.displayTime,
            isLoading: isLoadingProducts,
            onProductTap: { productData in
                print("🛒 [CastingProductCardWrapper] Kjøp nå tapped - productData.productId: \(productData.productId)")
                print("🛒 [CastingProductCardWrapper] products.count: \(products.count), productIds: \(products.map { String($0.id) })")
                print("🛒 [CastingProductCardWrapper] productEvent.allProductIds: \(productEvent.allProductIds)")
                
                // Find the matching Product from the loaded products
                if let product = products.first(where: { String($0.id) == productData.productId }) {
                    let configId = configProductId(for: product) ?? String(product.id)
                    let productUrl = getProductUrl(for: product)
                    let checkoutUrl = getCheckoutUrl(for: product)
                    
                    print("🛒 [CastingProductCardWrapper] Matched product id: \(product.id), configId: \(configId)")
                    print("🛒 [CastingProductCardWrapper] productUrl: \(productUrl ?? "nil")")
                    print("🛒 [CastingProductCardWrapper] checkoutUrl: \(checkoutUrl ?? "nil")")
                    
                    let tempEvent = CastingProductEvent(
                        id: productEvent.id + "-\(product.id)",
                        videoTimestamp: productEvent.videoTimestamp,
                        productId: configId,
                        productIds: nil,
                        title: product.title,
                        description: productEvent.description,
                        castingProductUrl: productUrl,
                        castingCheckoutUrl: checkoutUrl,
                        imageAsset: nil,
                        metadata: nil
                    )
                    
                    selectedProductEvent = tempEvent
                    showModal = true
                    onViewProduct()
                } else {
                    print("🛒 [CastingProductCardWrapper] ⚠️ No matching product found for productData.productId: \(productData.productId)")
                }
            }
        )
        .fullScreenCover(item: $selectedProductEvent) { event in
            CastingProductModal(productEvent: event) {
                selectedProductEvent = nil
                showModal = false
            }
        }
        .task {
            await loadProducts()
        }
    }
    
    private func convertProductsToSDKFormat(_ products: [Product]) -> [REngagementProductData] {
        return products.map { product in
            let discountPercentage = calculateDiscountPercentage(product)
            
            return REngagementProductData(
                productId: String(product.id),
                name: product.title,
                description: product.description,
                price: product.price.displayAmount,
                imageUrl: product.images.first?.url ?? "",
                discountPercentage: discountPercentage
            )
        }
    }
    
    private func calculateDiscountPercentage(_ product: Product) -> Int? {
        let currentPrice = product.price.amount_incl_taxes ?? product.price.amount
        let originalPrice = product.price.compare_at_incl_taxes ?? product.price.compare_at
        
        guard let compareAt = originalPrice, compareAt > currentPrice else {
            return nil
        }
        
        let discount = ((compareAt - currentPrice) / compareAt) * 100
        return Int(discount.rounded())
    }
    
    /// Viaplay demo fallback URLs (from demo-static-data.json) - used when config lookup fails
    private static let viaplayProductUrls: [String: (productUrl: String, checkoutUrl: String)] = [
        "408895": (
            "https://www.elkjop.no/product/tv-lyd-og-smarte-hjem/tv-og-tilbehor/tv/samsung-75-qn85f-neo-qled-4k-miniled-smart-tv-2025/906443",
            "https://www.elkjop.no/product/tv-lyd-og-smarte-hjem/tv-og-tilbehor/tv/samsung-75-qn85f-neo-qled-4k-miniled-smart-tv-2025/906443"
        ),
        "408896": (
            "https://www.elkjop.no/product/tv-lyd-og-smarte-hjem/hoyttalere-og-hi-fi/lydplanke/samsung-512ch-hw-q810f-lydplanke-sort/908694",
            "https://www.elkjop.no/product/tv-lyd-og-smarte-hjem/hoyttalere-og-hi-fi/lydplanke/samsung-512ch-hw-q810f-lydplanke-sort/908694"
        )
    ]
    
    /// Resolves the config product ID - API may return different IDs than productMappings (e.g. retailer ID vs casting ID)
    private func configProductId(for product: Product) -> String? {
        let productIdString = String(product.id)
        if DemoDataManager.shared.productUrl(for: productIdString) != nil || Self.viaplayProductUrls[productIdString] != nil {
            return productIdString
        }
        // Fallback: match by position - products loaded in same order as productEvent.allProductIds
        guard let index = products.firstIndex(where: { $0.id == product.id }),
              index < productEvent.allProductIds.count else {
            return nil
        }
        return productEvent.allProductIds[index]
    }
    
    private func getProductUrl(for product: Product) -> String? {
        if let configId = configProductId(for: product) {
            return DemoDataManager.shared.productUrl(for: configId)
                ?? Self.viaplayProductUrls[configId]?.productUrl
        }
        return productEvent.castingProductUrl?.isEmpty == false ? productEvent.castingProductUrl : nil
    }
    
    private func getCheckoutUrl(for product: Product) -> String? {
        if let configId = configProductId(for: product) {
            return DemoDataManager.shared.checkoutUrl(for: configId)
                ?? Self.viaplayProductUrls[configId]?.checkoutUrl
        }
        return productEvent.castingCheckoutUrl?.isEmpty == false ? productEvent.castingCheckoutUrl : nil
    }
    
    private func loadProducts() async {
        isLoadingProducts = true
        
        let productIds = productEvent.allProductIds
        
        do {
            let productIdInts = productIds.compactMap { Int($0) }
            let loadedProducts = try await ProductService.shared.loadProducts(
                productIds: productIdInts,
                currency: cartManager.currency,
                country: cartManager.country
            )
            
            await MainActor.run {
                self.products = loadedProducts
                self.isLoadingProducts = false
                print("🛒 [CastingProductCardWrapper] loadProducts ok - loaded \(loadedProducts.count) products: \(loadedProducts.map { String($0.id) })")
            }
        } catch {
            print("🛒 [CastingProductCardWrapper] loadProducts failed: \(error)")
            await MainActor.run {
                self.isLoadingProducts = false
            }
        }
    }
}

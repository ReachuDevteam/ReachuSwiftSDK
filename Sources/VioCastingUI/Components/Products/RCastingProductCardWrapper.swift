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
                print("🛒 [RCastingProductCardWrapper] Kjøp nå tapped - productData.productId: \(productData.productId)")
                print("🛒 [RCastingProductCardWrapper] products.count: \(products.count), productIds: \(products.map { String($0.id) })")
                print("🛒 [RCastingProductCardWrapper] productEvent.allProductIds: \(productEvent.allProductIds)")
                
                if let product = products.first(where: { String($0.id) == productData.productId }) {
                    let configId = configProductId(for: product) ?? String(product.id)
                    let productUrl = getProductUrl(for: product)
                    let checkoutUrl = getCheckoutUrl(for: product)
                    
                    print("🛒 [RCastingProductCardWrapper] Matched product id: \(product.id), configId: \(configId)")
                    print("🛒 [RCastingProductCardWrapper] productUrl: \(productUrl ?? "nil")")
                    print("🛒 [RCastingProductCardWrapper] checkoutUrl: \(checkoutUrl ?? "nil")")
                    
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
                    print("🛒 [RCastingProductCardWrapper] ⚠️ No matching product for productData.productId: \(productData.productId)")
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
    
    /// Viaplay/Elkjøp demo fallback URLs - used when DemoDataManager productMappings not loaded
    private static let demoProductUrls: [String: (productUrl: String, checkoutUrl: String)] = [
        "408895": (
            "https://www.elkjop.no/product/tv-lyd-og-smarte-hjem/tv-og-tilbehor/tv/samsung-75-qn85f-neo-qled-4k-miniled-smart-tv-2025/906443",
            "https://www.elkjop.no/product/tv-lyd-og-smarte-hjem/tv-og-tilbehor/tv/samsung-75-qn85f-neo-qled-4k-miniled-smart-tv-2025/906443"
        ),
        "408896": (
            "https://www.elkjop.no/product/tv-lyd-og-smarte-hjem/hoyttalere-og-hi-fi/lydplanke/samsung-512ch-hw-q810f-lydplanke-sort/908694",
            "https://www.elkjop.no/product/tv-lyd-og-smarte-hjem/hoyttalere-og-hi-fi/lydplanke/samsung-512ch-hw-q810f-lydplanke-sort/908694"
        )
    ]
    
    private func configProductId(for product: Product) -> String? {
        let productIdString = String(product.id)
        if DemoDataManager.shared.productUrl(for: productIdString) != nil || Self.demoProductUrls[productIdString] != nil {
            return productIdString
        }
        guard let index = products.firstIndex(where: { $0.id == product.id }),
              index < productEvent.allProductIds.count else {
            return nil
        }
        return productEvent.allProductIds[index]
    }
    
    private func getProductUrl(for product: Product) -> String? {
        if let configId = configProductId(for: product) {
            return DemoDataManager.shared.productUrl(for: configId)
                ?? Self.demoProductUrls[configId]?.productUrl
        }
        return productEvent.castingProductUrl?.isEmpty == false ? productEvent.castingProductUrl : nil
    }
    
    private func getCheckoutUrl(for product: Product) -> String? {
        if let configId = configProductId(for: product) {
            return DemoDataManager.shared.checkoutUrl(for: configId)
                ?? Self.demoProductUrls[configId]?.checkoutUrl
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
                print("🛒 [RCastingProductCardWrapper] loadProducts ok - \(loadedProducts.count) products: \(loadedProducts.map { String($0.id) })")
            }
        } catch {
            print("🛒 [RCastingProductCardWrapper] loadProducts failed: \(error)")
            await MainActor.run {
                self.isLoadingProducts = false
            }
        }
    }
}

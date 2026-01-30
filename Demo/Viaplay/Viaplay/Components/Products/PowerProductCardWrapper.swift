//
//  PowerProductCardWrapper.swift
//  Viaplay
//
//  Wrapper component that uses REngagementProductGridCard from SDK
//  Converts PowerProductEvent to SDK component format
//

import SwiftUI
import ReachuCore
import ReachuUI
import ReachuEngagementUI
import ReachuDesignSystem

struct PowerProductCardWrapper: View {
    let productEvent: PowerProductEvent
    let onViewProduct: () -> Void
    
    @State private var products: [Product] = []
    @State private var isLoadingProducts = false
    @State private var showModal = false
    @State private var selectedProductEvent: PowerProductEvent?
    
    @EnvironmentObject private var cartManager: CartManager
    
    var body: some View {
        let brandConfig = ReachuConfiguration.shared.brandConfiguration
        
        return REngagementProductGridCard(
            products: convertProductsToSDKFormat(products),
            promotionalText: productEvent.description.isEmpty ? "Ikke gå glipp av denne muligheten - 25% rabatt kun under kampen" : productEvent.description,
            brandName: brandConfig.name,
            brandIcon: brandConfig.iconAsset,
            displayTime: productEvent.displayTime,
            isLoading: isLoadingProducts,
            onProductTap: { productData in
                // Find the matching Product from the loaded products
                if let product = products.first(where: { String($0.id) == productData.productId }) {
                    let tempEvent = PowerProductEvent(
                        id: productEvent.id + "-\(product.id)",
                        videoTimestamp: productEvent.videoTimestamp,
                        productId: String(product.id),
                        productIds: nil,
                        title: product.title,
                        description: productEvent.description,
                        powerProductUrl: getProductUrl(for: product),
                        powerCheckoutUrl: getProductUrl(for: product),
                        imageAsset: nil,
                        metadata: nil
                    )
                    
                    selectedProductEvent = tempEvent
                    showModal = true
                    onViewProduct()
                }
            }
        )
        .fullScreenCover(item: $selectedProductEvent) { event in
            PowerProductModal(productEvent: event) {
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
    
    private func getProductUrl(for product: Product) -> String? {
        let productIdString = String(product.id)
        if productIdString == "408895" {
            // Samsung 75" QN85F Neo QLED 4K MiniLED Smart TV (2025)
            return "https://www.elkjop.no/product/tv-lyd-og-smarte-hjem/tv-og-tilbehor/tv/samsung-75-qn85f-neo-qled-4k-miniled-smart-tv-2025/906443"
        } else if productIdString == "408896" {
            // Samsung 5.1.2ch HW-Q810F lydplanke (sort)
            return "https://www.elkjop.no/product/tv-lyd-og-smarte-hjem/hoyttalere-og-hi-fi/lydplanke/samsung-512ch-hw-q810f-lydplanke-sort/908694"
        }
        return productEvent.powerProductUrl
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
            }
        } catch {
            await MainActor.run {
                self.isLoadingProducts = false
            }
        }
    }
}

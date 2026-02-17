//
//  CastingProductCardWrapper.swift
//  Viaplay
//
//  Wrapper component that uses REngagementProductGridCard from SDK
//  Converts CastingProductEvent to SDK component format
//

import SwiftUI
import ReachuCore
import ReachuUI
import ReachuEngagementUI
import ReachuDesignSystem

struct CastingProductCardWrapper: View {
    let productEvent: CastingProductEvent
    let onViewProduct: () -> Void
    
    @State private var products: [Product] = []
    @State private var demoProducts: [REngagementProductData] = []
    @State private var isLoadingProducts = false
    @State private var showModal = false
    @State private var selectedProductEvent: CastingProductEvent?
    
    @EnvironmentObject private var cartManager: CartManager
    
    private var displayProducts: [REngagementProductData] {
        if !products.isEmpty {
            return convertProductsToSDKFormat(products)
        }
        return demoProducts
    }
    
    var body: some View {
        let brandConfig = ReachuConfiguration.shared.effectiveBrandConfiguration
        
        return REngagementProductGridCard(
            products: displayProducts,
            promotionalText: productEvent.description.isEmpty ? "Ikke gå glipp av denne muligheten - 25% rabatt kun under kampen" : productEvent.description,
            brandName: brandConfig.name,
            brandIcon: brandConfig.iconAsset,
            displayTime: productEvent.displayTime,
            isLoading: isLoadingProducts,
            onProductTap: { productData in
                let productId = productData.productId ?? ""
                let url = DemoDataManager.shared.productUrl(for: productId) ?? productEvent.castingProductUrl
                let tempEvent = CastingProductEvent(
                    id: productEvent.id + "-\(productId)",
                    videoTimestamp: productEvent.videoTimestamp,
                    productId: productId,
                    productIds: nil,
                    title: productData.name,
                    description: productEvent.description,
                    castingProductUrl: url,
                    castingCheckoutUrl: DemoDataManager.shared.checkoutUrl(for: productId) ?? url,
                    imageAsset: nil,
                    metadata: nil
                )
                selectedProductEvent = tempEvent
                showModal = true
                onViewProduct()
            }
        )
        .fullScreenCover(item: $selectedProductEvent) { event in
            CastingProductModal(productEvent: event) {
                selectedProductEvent = nil
                showModal = false
            }
        }
        .onAppear {
            if demoProducts.isEmpty {
                let ids = productEvent.allProductIds.isEmpty ? ["408895", "408896"] : productEvent.allProductIds
                let fallback = buildDemoProducts(from: ids)
                demoProducts = fallback
                if !fallback.isEmpty {
                    isLoadingProducts = false
                }
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
    
    private func loadProducts() async {
        var productIds = productEvent.allProductIds
        if productIds.isEmpty {
            productIds = ["408895", "408896"]
        }
        // Show demo products immediately (from productMappings) so cards + URLs are visible
        let fallback = buildDemoProducts(from: productIds)
        await MainActor.run {
            self.demoProducts = fallback
            self.isLoadingProducts = fallback.isEmpty
        }
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
                if loadedProducts.isEmpty {
                    self.demoProducts = buildDemoProducts(from: productIds)
                }
            }
        } catch {
            await MainActor.run {
                self.products = []
                self.demoProducts = buildDemoProducts(from: productIds)
                self.isLoadingProducts = false
            }
        }
    }
    
    private func buildDemoProducts(from productIds: [String]) -> [REngagementProductData] {
        let dm = DemoDataManager.shared
        let currencySymbol = ReachuConfiguration.shared.marketConfiguration.currencySymbol
        let priceStr = "\(currencySymbol) —"
        return productIds.compactMap { id in
            guard let mapping = dm.productMapping(for: id) else { return nil }
            return REngagementProductData(
                productId: id,
                name: mapping.name,
                description: nil,
                price: priceStr,
                imageUrl: "",
                discountPercentage: 25
            )
        }
    }
}

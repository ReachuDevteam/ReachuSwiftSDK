//
//  PowerProductCard.swift
//  Viaplay
//
//  Component for displaying Power product events in the timeline
//  Shows multiple Reachu products with discount badge and Viaplay colors
//

import SwiftUI
import ReachuCore
import ReachuUI

struct PowerProductCard: View {
    let productEvent: PowerProductEvent
    let onViewProduct: () -> Void
    
    @State private var showModal = false
    @State private var selectedProductEvent: PowerProductEvent?
    @State private var products: [Product] = []
    @State private var isLoadingProducts = false
    
    // Get currency and country from CartManager
    @EnvironmentObject private var cartManager: CartManager
    
    // Power colors
    private let powerOrange = Color.orange
    private let powerBlue = Color.blue
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header (similar to PowerContestCard)
            HStack(spacing: 8) {
                // Power avatar
                Image("avatar_power")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text("Power")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                        
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 11))
                            .foregroundColor(powerBlue)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "cart.fill")
                            .font(.system(size: 9))
                            .foregroundColor(powerOrange)
                        
                        Text("Produkt")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text("•")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.4))
                        
                        Text(productEvent.displayTime)
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                Spacer()
                
                // Sponsor badge
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Sponset av")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Image("logo1")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 50, maxHeight: 16)
                }
            }
            
            // Promotional text
            Text("Ikke gå glipp av denne muligheten - 25% rabatt kun under kampen")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
                .lineSpacing(2)
                .padding(.vertical, 4)
            
            // Products grid (side by side, elongated cards)
            if isLoadingProducts {
                // Loading skeleton
                HStack(spacing: 12) {
                    ForEach(0..<min(2, productEvent.allProductIds.count), id: \.self) { _ in
                        VStack(spacing: 10) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 140)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 16)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.1))
                                .frame(width: 60, height: 16)
                            
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 36)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 280)
                    }
                }
            } else if !products.isEmpty {
                HStack(spacing: 12) {
                    ForEach(products.prefix(2), id: \.id) { product in
                        individualProductCard(product: product)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    powerOrange.opacity(0.4),
                                    powerOrange.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
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
    
    // MARK: - Individual Product Card View (with its own button)
    
    @ViewBuilder
    private func individualProductCard(product: Product) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Ensure card doesn't overflow
            // Image container with fixed height for consistency
            ZStack(alignment: .topTrailing) {
                // Background for image container
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white)
                    .frame(height: 140)
                
                // Product image - centered and fixed size
                if let firstImage = product.images.first,
                   let imageUrl = URL(string: firstImage.url) {
                    AsyncImage(url: imageUrl) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(height: 140)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: .infinity, maxHeight: 140)
                                .clipped()
                        case .failure:
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 140)
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(height: 140)
                    .frame(maxWidth: .infinity)
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 140)
                }
                
                // Discount badge (25%)
                discountBadge(text: "-25%")
            }
            .frame(height: 140)
            .frame(maxWidth: .infinity)
            .cornerRadius(8)
            
            // Product title
            Text(product.title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
            
            // Price
            VStack(alignment: .leading, spacing: 2) {
                Text(product.price.displayAmount)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(powerOrange)
                
                if let compareAtAmount = product.price.displayCompareAtAmount {
                    Text(compareAtAmount)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.white.opacity(0.6))
                        .strikethrough()
                }
            }
            
            // Individual buy button for this product
            Button(action: {
                // Create a temporary event for this specific product to open its checkout
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
            }) {
                HStack {
                    Spacer()
                    Text("Kjøp nå")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [
                                    powerOrange,
                                    powerOrange.opacity(0.8)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
            }
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 280) // Fixed minimum height for consistency
        .layoutPriority(1) // Ensure proper layout
    }
    
    // MARK: - Helper to get product URL
    
    private func getProductUrl(for product: Product) -> String? {
        // Map product IDs to their Power URLs
        let productIdString = String(product.id)
        if productIdString == "408895" {
            return "https://www.power.no/tv-og-lyd/tv/samsung-75-qn85f-neo-qled-4k-mini-led-smart-tv-2025/p-4019980/"
        } else if productIdString == "408896" {
            return "https://www.power.no/tv-og-lyd/lydplanker/samsung-hw-q61mf-lydplanke-med-subwoofer-2025/p-4053176/store/1185/"
        }
        return productEvent.powerProductUrl
    }
    
    // MARK: - Discount Badge
    
    private func discountBadge(text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(powerOrange)
            )
            .padding(6)
    }
    
    // MARK: - Helper Functions
    
    private func loadProducts() async {
        isLoadingProducts = true
        
        let productIds = productEvent.allProductIds
        
        do {
            // Load all products
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

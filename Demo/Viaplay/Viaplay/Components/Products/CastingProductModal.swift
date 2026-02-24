//
//  CastingProductModal.swift
//  Viaplay
//
//  Modal component for Casting product events
//  Goes directly to Casting checkout WebView
//

import SwiftUI
import VioCore

struct CastingProductModal: View {
    let productEvent: CastingProductEvent
    let onDismiss: () -> Void
    
    @StateObject private var campaignManager = CampaignManager.shared
    
    var body: some View {
        ZStack {
            // Background
            Color.black
                .ignoresSafeArea()
            
            // Direct to Casting checkout
            checkoutView
        }
    }
    
    // MARK: - URL Resolution
    
    private static let viaplayProductUrls: [String: String] = [
        "408895": "https://www.elkjop.no/product/tv-lyd-og-smarte-hjem/tv-og-tilbehor/tv/samsung-75-qn85f-neo-qled-4k-miniled-smart-tv-2025/906443",
        "408896": "https://www.elkjop.no/product/tv-lyd-og-smarte-hjem/hoyttalere-og-hi-fi/lydplanke/samsung-512ch-hw-q810f-lydplanke-sort/908694"
    ]
    
    private func resolveCheckoutUrl(for event: CastingProductEvent) -> URL? {
        print("🛒 [CastingProductModal] resolveCheckoutUrl - productId: \(event.productId), allProductIds: \(event.allProductIds)")
        print("🛒 [CastingProductModal] event.castingCheckoutUrl: \(event.castingCheckoutUrl ?? "nil")")
        print("🛒 [CastingProductModal] event.castingProductUrl: \(event.castingProductUrl ?? "nil")")
        
        if let u = event.castingCheckoutUrl, !u.isEmpty, let url = URL(string: u) {
            print("🛒 [CastingProductModal] ✓ Using event.castingCheckoutUrl")
            return url
        }
        if let u = event.castingProductUrl, !u.isEmpty, let url = URL(string: u) {
            print("🛒 [CastingProductModal] ✓ Using event.castingProductUrl")
            return url
        }
        let productId = event.productId
        if let u = DemoDataManager.shared.checkoutUrl(for: productId), let url = URL(string: u) {
            print("🛒 [CastingProductModal] ✓ Using DemoDataManager.checkoutUrl for \(productId)")
            return url
        }
        if let u = DemoDataManager.shared.productUrl(for: productId), let url = URL(string: u) {
            print("🛒 [CastingProductModal] ✓ Using DemoDataManager.productUrl for \(productId)")
            return url
        }
        for id in event.allProductIds {
            if let u = DemoDataManager.shared.checkoutUrl(for: id), let url = URL(string: u) {
                print("🛒 [CastingProductModal] ✓ Using DemoDataManager.checkoutUrl for allProductIds[\(id)]")
                return url
            }
            if let u = DemoDataManager.shared.productUrl(for: id), let url = URL(string: u) {
                print("🛒 [CastingProductModal] ✓ Using DemoDataManager.productUrl for allProductIds[\(id)]")
                return url
            }
        }
        if let u = Self.viaplayProductUrls[productId], let url = URL(string: u) {
            print("🛒 [CastingProductModal] ✓ Using viaplayProductUrls for \(productId)")
            return url
        }
        for id in event.allProductIds {
            if let u = Self.viaplayProductUrls[id], let url = URL(string: u) {
                print("🛒 [CastingProductModal] ✓ Using viaplayProductUrls for allProductIds[\(id)]")
                return url
            }
        }
        print("🛒 [CastingProductModal] ✗ No URL found - showing error")
        return nil
    }
    
    // MARK: - Checkout View
    
    private var checkoutView: some View {
        VStack(spacing: 0) {
            // Header with logo aligned to left
            HStack(alignment: .center) {
                // Campaign logo - aligned to left
                if let logoUrl = campaignManager.currentCampaign?.campaignLogo {
                    AsyncImage(url: URL(string: logoUrl)) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .scaleEffect(0.5)
                                .frame(width: 60, height: 30)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 30)
                        case .failure:
                            EmptyView()
                        @unknown default:
                            EmptyView()
                        }
                    }
                }
                
                Spacer()
                
                // Close button (X)
                Button(action: {
                    onDismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.1))
                        )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            // WebView with checkout - resolve URL from event, DemoDataManager, or Viaplay fallback
            if let url = resolveCheckoutUrl(for: productEvent) {
                CastingCheckoutWebViewContainer(
                    url: url,
                    onDismiss: onDismiss,
                    onBack: nil
                )
            } else {
                // No URL available after all fallbacks
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.orange)
                    
                    Text("Checkout URL ikke tilgjengelig")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("Kontakt Elkjøp for å fullføre kjøpet")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 20)
            }
        }
    }
}

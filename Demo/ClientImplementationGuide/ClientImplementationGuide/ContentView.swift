//
//  ContentView.swift
//  ClientImplementationGuide
//
//  Created by Alan Luis Valenzuela Simpson on 05-11-25.
//

import SwiftUI
import ReachuCore
import ReachuUI
import ReachuDesignSystem

struct ContentView: View {
    // Access CartManager from environment
    @EnvironmentObject var cartManager: CartManager
    @ObservedObject private var campaignManager = CampaignManager.shared
 
var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                    VStack(spacing: ReachuSpacing.lg) {                                       
                        RProductSlider(
                            title: "Recommended Products",
                            layout: .cards,
                            showSeeAll: false,
                            onProductTap: { product in
                                print("Tapped: \(product.title)")
                            },
                            onAddToCart: { product in
                                Task {
                                    await cartManager.addProduct(product)
                                }
                            },
                            currency: cartManager.currency,
                            country: cartManager.country
                        )
                        .environmentObject(cartManager)                                                                       
                        Spacer(minLength: 100)
                    }
                    VStack(spacing: ReachuSpacing.lg) {
                        RProductBanner(componentId: "1c15ffb1-28c3-408e-8656-3c4c78853b17")
                            .padding(.top, 20)   
                    }                    
                    VStack(spacing: ReachuSpacing.lg) {
                        RProductSpotlight(componentId: "c932ca6c-a079-4577-9013-f103c6216306")
                    }                    
                    VStack(spacing: ReachuSpacing.lg) {
                         RProductStore(componentId: "c8e1477f-9f0d-4a0f-ab5a-5aeca247a81d")
                    }
                    VStack(spacing: ReachuSpacing.lg) {
                        RProductCarousel(componentId: "b8402c1e-5673-49e9-b53e-e0f176f05b44", layout: "full")
                    }
                }
                
                // Floating cart indicator
                RFloatingCartIndicator()
                    .environmentObject(cartManager)
            }
            .navigationTitle("My Store")
        }
    }
}

#Preview {
    ContentView()
}

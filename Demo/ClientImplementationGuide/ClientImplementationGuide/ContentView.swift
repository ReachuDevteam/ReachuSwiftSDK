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

    var body: some View {
        ScrollView {
            VStack() {
                // Automatic product banner (shows skeleton while loading)
                //RProductBanner()            
                
                RProductCarousel()      // Large vertical cards (full width)
                //RProductCarousel(layout: "full")      // Large vertical cards (full width)
                //RProductCarousel(layout: "compact")   // Small vertical cards (2 cards visible)
                //RProductCarousel(layout: "horizontal") // Horizontal cards (image left, info right)
            }
            VStack() {
                RProductSlider(
                    title: "Recommended Products",
                    layout: .cards,
                    showSeeAll: true,
                    onProductTap: { product in
                        print("Tapped product: \(product.title)")
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
             }
        }
    }
}

#Preview {
    ContentView()
}

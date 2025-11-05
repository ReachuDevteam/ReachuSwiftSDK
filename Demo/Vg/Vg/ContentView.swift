//
//  ContentView.swift
//  Vg
//
//  Created by Angelo Sepulveda on 27/10/2025.
//

import SwiftUI
import ReachuUI
import ReachuCore

struct ContentView: View {
    @EnvironmentObject private var cartManager: CartManager
    @EnvironmentObject private var checkoutDraft: CheckoutDraft

    var body: some View {
        ZStack {
            VGHomeView()

            // Indicador global de carrito flotante
            RFloatingCartIndicator(
                customPadding: EdgeInsets(top: 0, leading: 0, bottom: 100, trailing: 16)
            )
            .zIndex(999)
        }
        // Overlay de checkout
        .sheet(isPresented: $cartManager.isCheckoutPresented) {
            RCheckoutOverlay()
                .environmentObject(cartManager)
                .environmentObject(checkoutDraft)
        }
    }
}

#Preview {
    ContentView()
}

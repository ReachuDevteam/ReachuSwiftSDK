//
//  ContentView.swift
//  Viaplay
//
//  Created by Angelo Sepulveda on 27/10/2025.
//

import SwiftUI
import ReachuUI
import ReachuCore
import ReachuLiveUI
import ReachuLiveShow

struct ContentView: View {
    @EnvironmentObject var cartManager: CartManager
    
    var body: some View {
        ZStack {
            // Main app content
            ViaplayHomeView()
            
            // Global floating cart indicator - always on top
            RFloatingCartIndicator(
                customPadding: EdgeInsets(
                    top: 0,
                    leading: 0,
                    bottom: 100,
                    trailing: 16
                )
            )
            .zIndex(999) // Asegurar que esté por encima de todo (video, overlays, etc.)
        }
        .overlay {
            // Global live stream overlay (Tipio integration)
            LiveStreamGlobalOverlay()
                .environmentObject(cartManager)
        }
    }
}

// MARK: - Live Stream Overlay

struct LiveStreamGlobalOverlay: View {
    @ObservedObject private var liveShowManager = LiveShowManager.shared
    @EnvironmentObject private var cartManager: CartManager
    
    var body: some View {
        ZStack {
            // Full screen LiveShow overlay
            if liveShowManager.isLiveShowVisible {
                RLiveShowFullScreenOverlay()
                    .environmentObject(cartManager)
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(CartManager())
        .environmentObject(CheckoutDraft())
}

//
//  ClientImplementationGuideApp.swift
//  ClientImplementationGuide
//
//  Created by Alan Luis Valenzuela Simpson on 05-11-25.
//

import SwiftUI
import ReachuCore
import ReachuUI
import ReachuDesignSystem


@main
struct ClientImplementationGuideApp: App {
    // MARK: - Global State Managers
    // Initialize CartManager and CheckoutDraft once for the entire app
    @StateObject private var cartManager = CartManager()
    @StateObject private var checkoutDraft = CheckoutDraft()

    init() {
        // Load configuration from reachu-config.json
        // This reads the config file with API key, theme colors, and settings
        print("🚀 [YourApp] Loading Reachu SDK configuration...")
        
        // Option 1: Use device locale for country detection
        // ConfigurationLoader.loadConfiguration()
        
        // Option 2: Force a specific country (for testing)
        ConfigurationLoader.loadConfiguration(userCountryCode: "NO")
        
        print("✅ [YourApp] Reachu SDK configured successfully")
        print("🎨 [YourApp] Theme: \(ReachuConfiguration.shared.theme.name)")
        print("🔑 [YourApp] API Key: \(ReachuConfiguration.shared.apiKey.isEmpty ? "Not set" : "\(ReachuConfiguration.shared.apiKey.prefix(8))...")")
        print("🌍 [YourApp] Environment: \(ReachuConfiguration.shared.environment)")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                // Inject managers as environment objects
                // This makes them available to ALL child views via @EnvironmentObject
                .environmentObject(cartManager)
                .environmentObject(checkoutDraft)
                // Show checkout overlay when user taps checkout button
                .sheet(isPresented: $cartManager.isCheckoutPresented) {
                    RCheckoutOverlay()
                        .environmentObject(cartManager)
                        .environmentObject(checkoutDraft)
                }
                // Global floating cart indicator (optional)
                .overlay {
                    RFloatingCartIndicator()
                        .environmentObject(cartManager)
                }            
        }
    }
}

//
//  tv2demoApp.swift
//  tv2demo
//
//  Created by Angelo Sepulveda on 02/10/2025.
//

import SwiftUI
import ReachuCore
import ReachuUI
import StripeCore

@main
struct tv2demoApp: App {
    // MARK: - Global State Managers
    // These are initialized once and shared across the entire app
    @StateObject private var cartManager = CartManager()
    @StateObject private var checkoutDraft = CheckoutDraft()
    
    init() {
        // Load Reachu SDK configuration FIRST
        // This reads the reachu-config.json file with TV2 colors and theme
        print("🚀 [TV2Demo] Loading Reachu SDK configuration...")
        ConfigurationLoader.loadConfiguration()
        print("✅ [TV2Demo] Reachu SDK configured successfully")
        print("🎨 [TV2Demo] Theme: \(ReachuConfiguration.shared.theme.name)")
        print("🎨 [TV2Demo] Mode: \(ReachuConfiguration.shared.theme.mode)")
        
        // Initialize Stripe
        let defaultPublishableKey = "pk_test_51MvQONBjfRnXLEB43vxVNP53LmkC13ZruLbNqDYIER8GmRgLX97vWKw9gPuhYLuOSwXaXpDFYAKsZhYtBpcAWvcy00zQ9ZES0L"
        
        // Initialize SDK Client
        let config = ReachuConfiguration.shared
        let baseURL = URL(string: config.environment.graphQLURL)!
        let apiKey = config.apiKey.isEmpty ? "DEMO_KEY" : config.apiKey
        
        print("🔧 [TV2Demo] Initializing SDK Client for Stripe")
        print("   Base URL: \(baseURL)")
        print("   API Key: \(apiKey.prefix(8))...")
        
        let sdkClient = SdkClient(baseUrl: baseURL, apiKey: apiKey)
        
        Task {
            // Fetch Stripe publishable key dynamically
            do {
                let paymentMethods = try await sdkClient.payment.getAvailableMethods()
                if let stripeMethod = paymentMethods.first(where: { $0.name == "Stripe" }) {
                    StripeAPI.defaultPublishableKey = stripeMethod.publishableKey ?? defaultPublishableKey
                    print("💳 [TV2Demo] Stripe configured dynamically with key: \(stripeMethod.publishableKey ?? defaultPublishableKey)")
                } else {
                    // Use default key if Stripe method is not found
                    StripeAPI.defaultPublishableKey = defaultPublishableKey
                    print("⚠️ [TV2Demo] Stripe method not found, using default key")
                }
            } catch {
                // Use default key in case of error
                StripeAPI.defaultPublishableKey = defaultPublishableKey
                print("❌ [TV2Demo] Failed to fetch payment methods: \(error), using default key")
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                // Inject managers as environment objects
                // This makes them available to ALL child views via @EnvironmentObject
                .environmentObject(cartManager)
                .environmentObject(checkoutDraft)
        }
    }
}

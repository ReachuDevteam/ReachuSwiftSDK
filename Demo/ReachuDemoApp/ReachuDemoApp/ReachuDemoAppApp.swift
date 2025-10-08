//
//  ReachuDemoAppApp.swift
//  ReachuDemoApp
//
//  Created by Angelo Sepulveda on 19/09/2025.
//

import ReachuCore
import StripeCore
import SwiftUI

@main
struct ReachuDemoAppApp: App {
    init() {
        // Load Reachu SDK configuration FIRST
        // This reads the reachu-config.json file with theme colors and settings
        print("🚀 [ReachuDemoApp] Loading Reachu SDK configuration...")
        ConfigurationLoader.loadConfiguration()
        print("✅ [ReachuDemoApp] Reachu SDK configured successfully")
        print("🎨 [ReachuDemoApp] Theme: \(ReachuConfiguration.shared.theme.name)")
        print("🎨 [ReachuDemoApp] Mode: \(ReachuConfiguration.shared.theme.mode)")
        print("🛒 [ReachuDemoApp] Cart Display: \(ReachuConfiguration.shared.cartConfiguration.floatingCartDisplayMode)")

        let defaultPublishableKey = "pk_test_51MvQONBjfRnXLEB43vxVNP53LmkC13ZruLbNqDYIER8GmRgLX97vWKw9gPuhYLuOSwXaXpDFYAKsZhYtBpcAWvcy00zQ9ZES0L"

        // Initialize SDK Client
        let config = ReachuConfiguration.shared
        let baseURL = URL(string: config.environment.graphQLURL)!
        let apiKey = config.apiKey.isEmpty ? "DEMO_KEY" : config.apiKey

        print("🔧 [ReachuDemoApp] Initializing SDK Client")
        print("   Base URL: \(baseURL)")
        print("   API Key: \(apiKey.prefix(8))...")

        let sdkClient = SdkClient(baseUrl: baseURL, apiKey: apiKey)

        Task {
            // Fetch Stripe publishable key dynamically
            do {
                let paymentMethods = try await sdkClient.payment.getAvailableMethods()
                if let stripeMethod = paymentMethods.first(where: { $0.name == "Stripe" }) {
                    StripeAPI.defaultPublishableKey = stripeMethod.publishableKey ?? defaultPublishableKey
                    print("💳 [ReachuDemoApp] Stripe configured dynamically with key: \(stripeMethod.publishableKey ?? defaultPublishableKey)")
                } else {
                    // Use default key if Stripe method is not found
                    StripeAPI.defaultPublishableKey = defaultPublishableKey
                    print("⚠️ [ReachuDemoApp] Stripe method not found, using default key")
                }
            } catch {
                // Use default key in case of error
                StripeAPI.defaultPublishableKey = defaultPublishableKey
                print("❌ [ReachuDemoApp] Failed to fetch payment methods: \(error), using default key")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    print("✨ [ReachuDemoApp] App ready")
                }
        }
    }
}

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
        
        // Setup Stripe after configuration is loaded
        StripeAPI.defaultPublishableKey =
            "pk_test_51MvQONBjfRnXLEB43vxVNP53LmkC13ZruLbNqDYIER8GmRgLX97vWKw9gPuhYLuOSwXaXpDFYAKsZhYtBpcAWvcy00zQ9ZES0L"
        print("💳 [ReachuDemoApp] Stripe configured")
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

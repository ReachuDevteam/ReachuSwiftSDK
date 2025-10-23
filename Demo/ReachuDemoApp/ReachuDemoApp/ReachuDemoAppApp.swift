//
//  ReachuDemoAppApp.swift
//  ReachuDemoApp
//
//  Created by Angelo Sepulveda on 19/09/2025.
//

import ReachuCore
import SwiftUI
import ReachuUI 

@main
struct ReachuDemoAppApp: App {
    init() {
        // Load Reachu SDK configuration
        // This reads the reachu-config.json file with theme colors and settings
        // Stripe is initialized automatically by the SDK
        print("🚀 [ReachuDemoApp] Loading Reachu SDK configuration...")
        ConfigurationLoader.loadConfiguration()
        print("✅ [ReachuDemoApp] Reachu SDK configured successfully")
        print("🎨 [ReachuDemoApp] Theme: \(ReachuConfiguration.shared.theme.name)")
        print("🎨 [ReachuDemoApp] Mode: \(ReachuConfiguration.shared.theme.mode)")
        print("🛒 [ReachuDemoApp] Cart Display: \(ReachuConfiguration.shared.cartConfiguration.floatingCartDisplayMode)")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    print("✨ [ReachuDemoApp] App ready")
                }
                .onOpenURL { url in
                    print("📡 [Vipps] returned with URL: \(url)")
                    
                    NotificationCenter.default.post(
                        name: .vippsPaymentReturn,
                        object: url
                    )
                }
        }
    }
}

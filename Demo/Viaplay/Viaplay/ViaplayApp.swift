//
//  ViaplayApp.swift
//  Viaplay
//
//  Created by Angelo Sepulveda on 27/10/2025.
//

import SwiftUI
import CoreData
import ReachuCore
import ReachuUI

@main
struct ViaplayApp: App {
    let persistenceController = PersistenceController.shared
    
    // MARK: - Global State Managers
    // These are initialized once and shared across the entire app
    @StateObject private var cartManager = CartManager()
    @StateObject private var checkoutDraft = CheckoutDraft()
    
    init() {
        // Load Reachu SDK configuration
        // This reads the reachu-config.json file with Viaplay colors and theme
        // Stripe is initialized automatically by the SDK
        print("🚀 [Viaplay] Loading Reachu SDK configuration...")
        ConfigurationLoader.loadConfiguration()
        print("✅ [Viaplay] Reachu SDK configured successfully")
        print("🎨 [Viaplay] Theme: \(ReachuConfiguration.shared.theme.name)")
        print("🎨 [Viaplay] Mode: \(ReachuConfiguration.shared.theme.mode)")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                // Inject managers as environment objects
                // This makes them available to ALL child views via @EnvironmentObject
                .environmentObject(cartManager)
                .environmentObject(checkoutDraft)
        }
    }
}

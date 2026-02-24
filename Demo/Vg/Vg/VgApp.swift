//
//  VgApp.swift
//  Vg
//
//  Created by Angelo Sepulveda on 27/10/2025.
//

import SwiftUI
import CoreData
import VioCore
import VioUI
// TODO: Add ReachuCore package dependency in Xcode
// import VioCore

@main
struct VgApp: App {
    let persistenceController = PersistenceController.shared

    @StateObject private var cartManager = CartManager()
    @StateObject private var checkoutDraft = CheckoutDraft()
    
    init() {
        print("🚀 [VG] Loading Reachu SDK configuration...")
        ConfigurationLoader.loadConfiguration()
        print("✅ [VG] Reachu SDK configured successfully")
        print("🎨 [VG] Theme: \(VioConfiguration.shared.theme.name)")
        print("🎨 [VG] Mode: \(VioConfiguration.shared.theme.mode)")

        // MARK: - Reachu Diagnostic Logs
        let cfg = VioConfiguration.shared
        let apiKeyMasked = cfg.apiKey.isEmpty ? "(empty)" : String(repeating: "*", count: max(0, cfg.apiKey.count - 4)) + cfg.apiKey.suffix(4)
        print("🔧 [Reachu][Config] environment=\(cfg.environment.rawValue)")
        print("🔧 [Reachu][Config] graphQLURL=\(cfg.environment.graphQLURL)")
        print("🔧 [Reachu][Config] apiKey=\(apiKeyMasked)")
        print("🔧 [Reachu][Market] country=\(cfg.marketConfiguration.countryCode) currency=\(cfg.marketConfiguration.currencyCode)")
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

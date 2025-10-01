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
        // Load Reachu SDK configuration
        StripeAPI.defaultPublishableKey =
            "pk_test_51MvQONBjfRnXLEB43vxVNP53LmkC13ZruLbNqDYIER8GmRgLX97vWKw9gPuhYLuOSwXaXpDFYAKsZhYtBpcAWvcy00zQ9ZES0L"

        do {
            try ConfigurationLoader.loadConfiguration()
            print("✅ Reachu SDK configuration loaded successfully")
        } catch {
            print("❌ Failed to load Reachu SDK configuration: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    print("🚀 Reachu SDK Demo App iniciada")
                }
        }
    }
}

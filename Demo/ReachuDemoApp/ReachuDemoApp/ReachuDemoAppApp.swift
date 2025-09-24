//
//  ReachuDemoAppApp.swift
//  ReachuDemoApp
//
//  Created by Angelo Sepulveda on 19/09/2025.
//

import SwiftUI
import ReachuCore

@main
struct ReachuDemoAppApp: App {
    init() {
        // Load Reachu SDK configuration
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
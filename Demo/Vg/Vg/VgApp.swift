//
//  VgApp.swift
//  Vg
//
//  Created by Angelo Sepulveda on 27/10/2025.
//

import SwiftUI
import CoreData
import ReachuCore

@main
struct VgApp: App {
    let persistenceController = PersistenceController.shared
    
    init() {
        // Initialize Reachu SDK
        ConfigurationLoader.loadConfiguration()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

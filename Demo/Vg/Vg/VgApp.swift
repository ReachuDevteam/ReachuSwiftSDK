//
//  VgApp.swift
//  Vg
//
//  Created by Angelo Sepulveda on 27/10/2025.
//

import SwiftUI
import CoreData
// TODO: Add ReachuCore package dependency in Xcode
// import ReachuCore

@main
struct VgApp: App {
    let persistenceController = PersistenceController.shared
    
    init() {
        // Initialize Reachu SDK
        // TODO: Uncomment after adding ReachuCore dependency
        // ConfigurationLoader.loadConfiguration()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

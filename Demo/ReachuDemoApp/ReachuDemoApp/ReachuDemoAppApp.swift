//
//  ReachuDemoAppApp.swift
//  ReachuDemoApp
//
//  Created by Angelo Sepulveda on 19/09/2025.
//

import SwiftUI

@main
struct ReachuDemoAppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    print("🚀 Reachu SDK Demo App iniciada")
                }
        }
    }
}
//
//  ContentView.swift
//  tv2demo
//
//  Created by Angelo Sepulveda on 02/10/2025.
//

import SwiftUI
import ReachuUI

struct ContentView: View {
    var body: some View {
        ZStack {
            // Main app content
            HomeView()
            
            // Global floating cart indicator - always on top
            RFloatingCartIndicator(
                customPadding: EdgeInsets(
                    top: 0,
                    leading: 0,
                    bottom: 100, // Above tab bar
                    trailing: TV2Theme.Spacing.md
                )
            )
        }
    }
}

#Preview {
    ContentView()
}

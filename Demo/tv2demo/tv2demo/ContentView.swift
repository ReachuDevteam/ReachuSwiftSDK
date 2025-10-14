//
//  ContentView.swift
//  tv2demo
//
//  Created by Angelo Sepulveda on 02/10/2025.
//

import SwiftUI
import ReachuUI

struct ContentView: View {
    @StateObject private var castingManager = CastingManager.shared
    @State private var showCastingView = false
    @EnvironmentObject var cartManager: CartManager
    
    var body: some View {
        ZStack {
            // Main app content
            HomeView()
            
            // Mini player de casting (cuando está casteando y minimizado)
            if castingManager.isCasting && !showCastingView {
                CastingMiniPlayer(match: Match.barcelonaPSG) {
                    showCastingView = true
                }
            }
            
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
        .fullScreenCover(isPresented: $showCastingView) {
            if castingManager.isCasting {
                CastingActiveView(match: Match.barcelonaPSG)
                    .environmentObject(cartManager)
            }
        }
        .onChange(of: castingManager.isCasting) { isCasting in
            if !isCasting {
                showCastingView = false
            }
        }
    }
}

#Preview {
    ContentView()
}

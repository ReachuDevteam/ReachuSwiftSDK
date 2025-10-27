//
//  ViaplayHomeView.swift
//  Viaplay
//
//  Created by Angelo Sepulveda on 27/10/2025.
//

import SwiftUI

struct ViaplayHomeView: View {
    @State private var selectedTab = 0
    let heroContent = HeroContent.mock
    let continueWatchingItems = ContinueWatchingItem.mockItems
    
    var body: some View {
        ZStack {
            // Background
            ViaplayTheme.Colors.black
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Content based on selected tab
                Group {
                    switch selectedTab {
                    case 0:
                        homeContent
                    default:
                        // Placeholder for other tabs
                        VStack {
                            Text("Tab \(selectedTab)")
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                
                // Bottom Navigation Bar
                ViaplayBottomNav(selectedTab: $selectedTab)
            }
        }
    }
    
    private var homeContent: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Hero Section
                HeroSection(content: heroContent)
                
                // Continue Watching Section
                VStack(alignment: .leading, spacing: ViaplayTheme.Spacing.md) {
                    Text("Fortsett å se")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, ViaplayTheme.Spacing.lg)
                        .padding(.top, ViaplayTheme.Spacing.lg)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: ViaplayTheme.Spacing.md) {
                            ForEach(continueWatchingItems) { item in
                                ContinueWatchingCard(item: item)
                            }
                        }
                        .padding(.horizontal, ViaplayTheme.Spacing.lg)
                    }
                }
                .padding(.bottom, 100) // Space for bottom nav
            }
        }
    }
}

#Preview {
    ViaplayHomeView()
}

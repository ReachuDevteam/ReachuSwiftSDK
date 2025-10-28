//
//  VGHomeView.swift
//  Vg
//
//  Created by Angelo Sepulveda on 27/10/2025.
//

import SwiftUI

struct VGHomeView: View {
    let sections = Match.mockMatches
    @State private var selectedTab = 3 // "Direkte" tab
    
    var body: some View {
        ZStack {
            // Background
            VGTheme.Colors.black
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Content based on selected tab
                Group {
                    switch selectedTab {
                    case 0:
                        NewsView()
                    case 1:
                        ClipsView()
                    case 2:
                        VGLiveView()
                    case 3:
                        liveContentView
                    case 4:
                        SettingsView()
                    default:
                        liveContentView
                    }
                }
                
                // Bottom Navigation Bar (always visible)
                BottomNavigationBar(selectedTab: $selectedTab)
            }
        }
    }
    
    // Live content with header
    private var liveContentView: some View {
        VStack(spacing: 0) {
            // VG Logo Header
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Image("logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 22)
                    Spacer()
                }
                .padding(.vertical, VGTheme.Spacing.sm)
                
                // Separator line
                Divider()
                    .background(VGTheme.Colors.mediumGray)
            }
            .background(VGTheme.Colors.black)
            
            // Main Content
            ScrollView {
                VStack(spacing: 0) {
                    // Featured Match Hero
                    FeaturedMatchHero(
                        imageUrl: "https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=800",
                        time: "I dag 18:15",
                        title: "Lecce - Napoli",
                        category: "Sport",
                        description: "Se italiensk Serie A direkte på VG+Sport. Lecce og Napoli møtes i niende serierunde på Stadio Via del Mare i Lecce. Vegard Aulstad står for kommenteringen.",
                        onPlayTapped: {
                            print("🎬 [VG] Opening match: Lecce - Napoli")
                        }
                    )
                    
                    // Match sections
                    VStack(spacing: VGTheme.Spacing.xl) {
                        ForEach(sections) { section in
                            MatchSectionView(section: section)
                        }
                    }
                    .padding(.top, VGTheme.Spacing.xl)
                    .padding(.bottom, 80) // Space for bottom nav
                }
            }
        }
    }
}

#Preview {
    VGHomeView()
}

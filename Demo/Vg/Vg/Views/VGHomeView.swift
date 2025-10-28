//
//  VGHomeView.swift
//  Vg
//
//  Created by Angelo Sepulveda on 27/10/2025.
//

import SwiftUI

struct VGHomeView: View {
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
                        time: "I dag 18:15",
                        title: "Lecce - Napoli",
                        category: "Sport",
                        description: "Se italiensk Serie A direkte på VG+Sport. Lecce og Napoli møtes i niende serierunde på Stadio Via del Mare i Lecce. Vegard Aulstad står for kommenteringen.",
                        onPlayTapped: {
                            print("🎬 [VG] Opening match: Lecce - Napoli")
                        }
                    )
                    
                    // Next Live Section
                    NextLiveSection(
                        onSeeAllTapped: {
                            print("📺 [VG] See all next live broadcasts")
                        },
                        onCardTapped: { index in
                            print("📺 [VG] Card \(index) tapped")
                        }
                    )
                    .padding(.top, 24)
                    
                    // Serie A Section
                    SerieASection(
                        onSeeAllTapped: {
                            print("⚽ [VG] See all Serie A matches")
                        },
                        onCardTapped: { index in
                            print("⚽ [VG] Serie A card \(index) tapped")
                        }
                    )
                    .padding(.top, 32)
                    
                    // Previous Broadcasts Section
                    PreviousBroadcastsSection(
                        onSeeAllTapped: {
                            print("📺 [VG] See all previous broadcasts")
                        },
                        onCardTapped: { index in
                            print("📺 [VG] Previous broadcast card \(index) tapped")
                        }
                    )
                    .padding(.top, 32)
                    
                    // Bottom padding for navigation
                    Spacer()
                        .frame(height: 80)
                }
            }
        }
    }
}

#Preview {
    VGHomeView()
}

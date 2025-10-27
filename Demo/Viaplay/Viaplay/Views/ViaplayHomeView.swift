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
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with Viaplay Logo and Boombox
                HStack {
                    Spacer()
                    
                    // Viaplay Logo
                    HStack(spacing: 6) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(red: 1.0, green: 0.2, blue: 0.6), Color(red: 0.6, green: 0.2, blue: 1.0)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        
                        Text("viaplay")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    // Boombox icon
                    Image(systemName: "music.note.list")
                        .font(.system(size: 20))
                        .foregroundColor(.cyan)
                        .padding(8)
                        .background(Color.cyan.opacity(0.2))
                        .cornerRadius(8)
                        .padding(.trailing, 16)
                }
                .padding(.top, 8)
                .padding(.bottom, 16)
                
                // Content
                ScrollView {
                    VStack(spacing: 0) {
                        // Hero Section
                        HeroSection(content: heroContent)
                        
                        // Fortsett å se Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Fortsett å se")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.top, 24)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(continueWatchingItems) { item in
                                        ContinueWatchingCard(item: item)
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                        .padding(.bottom, 100) // Space for bottom nav
                    }
                }
                
                // Bottom Navigation Bar
                ViaplayBottomNav(selectedTab: $selectedTab)
            }
        }
    }
}

#Preview {
    ViaplayHomeView()
}

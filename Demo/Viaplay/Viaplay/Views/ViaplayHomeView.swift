//
//  ViaplayHomeView.swift
//  Viaplay
//
//  Created by Angelo Sepulveda on 27/10/2025.
//

import SwiftUI

struct ViaplayHomeView: View {
    @State private var selectedTab = 0
    @State private var scrollOffset: CGFloat = 0
    let heroContent = HeroContent.mock
    let continueWatchingItems = ContinueWatchingItem.mockItems
    
    var body: some View {
        ZStack(alignment: .top) {
            // Background
            Color.black
                .ignoresSafeArea()
            
            // Main Content
            ScrollView {
                VStack(spacing: 0) {
                    // Hero Section (no header here)
                    HeroSection(content: heroContent)
                    
                    // Fortsett å se Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Fortsett å se")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.top, 20)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(continueWatchingItems) { item in
                                    ContinueWatchingCard(item: item)
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.bottom, 100) // Space for bottom nav and crown
                }
            }
            
            // Floating Header (appears on scroll)
            if scrollOffset > 100 {
                HStack {
                    Spacer()
                    
                    // Viaplay Logo from assets
                    Image("logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 24)
                    
                    Spacer()
                    
                    // Boombox icon
                    Image(systemName: "music.note.list")
                        .font(.system(size: 16))
                        .foregroundColor(.cyan)
                        .padding(6)
                        .background(Color.cyan.opacity(0.2))
                        .cornerRadius(6)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.black.opacity(0.95))
                .transition(.move(edge: .top))
            }
            
            // Bottom Navigation
            VStack {
                Spacer()
                ViaplayBottomNav(selectedTab: $selectedTab)
            }
        }
    }
}

#Preview {
    ViaplayHomeView()
}

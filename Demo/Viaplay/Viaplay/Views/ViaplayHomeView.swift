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
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                // Background
                Color.black
                    .ignoresSafeArea()
                
                // Main Content
                ScrollView {
                    VStack(spacing: 0) {
                        // Hero Section (extends to top)
                        HeroSection(content: heroContent)
                            .frame(width: geometry.size.width)
                        
                        // Pagination dots after hero
                        HStack(spacing: 7) {
                            Circle()
                                .fill(.white)
                                .frame(width: 8, height: 8)
                            
                            ForEach(0..<5) { _ in
                                Circle()
                                    .fill(.white.opacity(0.4))
                                    .frame(width: 7, height: 7)
                            }
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 24)
                        
                        // Category Buttons Grid
                        VStack(spacing: 16) {
                            HStack(spacing: 16) {
                                CategoryButton(title: "Series") {}
                                CategoryButton(title: "Films") {}
                            }
                            
                            HStack(spacing: 16) {
                                CategoryButton(title: "Sport") {}
                                CategoryButton(title: "Kids") {}
                            }
                            
                            CategoryButton(title: "Channels") {}
                                .frame(maxWidth: .infinity)
                        }
                        .padding(.horizontal, 16)
                        .frame(width: geometry.size.width)
                        
                        // Akkurat nå ser andre på Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Akkurat nå ser andre på")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.top, 32)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    CategoryCard(
                                        title: "Norske Truckers",
                                        imageUrl: "https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=300",
                                        seasonEpisode: "S3 | E2"
                                    )
                                    
                                    CategoryCard(
                                        title: "Kraven The Hunter",
                                        imageUrl: "https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=300",
                                        seasonEpisode: nil
                                    )
                                    
                                    CategoryCard(
                                        title: "Paradise Hotel",
                                        imageUrl: "https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=300",
                                        seasonEpisode: "S17 | E28"
                                    )
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                        .frame(width: geometry.size.width)
                        
                        // Nytt hos oss Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Nytt hos oss")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.top, 32)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    CategoryCard(
                                        title: "American Gangster",
                                        imageUrl: "https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=300",
                                        seasonEpisode: nil
                                    )
                                    
                                    CategoryCard(
                                        title: "The Equalizer",
                                        imageUrl: "https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=300",
                                        seasonEpisode: nil
                                    )
                                    
                                    CategoryCard(
                                        title: "The 924th",
                                        imageUrl: "https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=300",
                                        seasonEpisode: nil
                                    )
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                        .frame(width: geometry.size.width)
                        .padding(.bottom, 100) // Space for bottom nav
                    }
                }
                .ignoresSafeArea(edges: .top) // Allow scroll content to go under status bar
                
                // Floating Header (appears on scroll) with blur effect
                if scrollOffset > 200 {
                    VStack(spacing: 0) {
                        ZStack {
                            // Blur background
                            VisualEffectBlur(blurStyle: .systemUltraThinMaterialDark)
                            
                            HStack {
                                Spacer()
                                
                                // Viaplay Logo from assets
                                Image("logo")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: 24)
                                
                                Spacer()
                                
                                // Avatar/Profile circle
                                Circle()
                                    .fill(Color.cyan.opacity(0.3))
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(.cyan)
                                    )
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                        }
                        
                        Divider()
                            .background(Color.gray.opacity(0.3))
                    }
                    .frame(width: geometry.size.width)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.3), value: scrollOffset)
                }
                
                // Bottom Navigation
                VStack {
                    Spacer()
                    ViaplayBottomNav(selectedTab: $selectedTab)
                        .frame(width: geometry.size.width)
                }
            }
            .frame(width: geometry.size.width)
        }
    }
}

#Preview {
    ViaplayHomeView()
}

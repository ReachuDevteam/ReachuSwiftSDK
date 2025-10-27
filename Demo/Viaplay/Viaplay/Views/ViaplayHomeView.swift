//
//  ViaplayHomeView.swift
//  Viaplay
//
//  Created by Angelo Sepulveda on 27/10/2025.
//

import SwiftUI

struct ViaplayHomeView: View {
    @State private var selectedTab = 0 // Sport tab
    let heroContent = HeroContent.mock
    let continueWatchingItems = ContinueWatchingItem.mockItems
    
    var body: some View {
        ZStack {
            // Background
            ViaplayTheme.Colors.black
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Status Bar
                HStack {
                    Text("12:42")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "bell")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.green)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "wifi")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                        Text("5G")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                        Image(systemName: "battery.100")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 12)
                
                // Header with Viaplay Logo
                HStack {
                    Spacer()
                    
                    // Viaplay Logo
                    HStack(spacing: 8) {
                        // Gradient chevron
                        Image(systemName: "chevron.right")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(ViaplayTheme.Colors.brandGradient)
                        
                        Text("viaplay")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    // Boombox icon
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                        .frame(width: 32, height: 32)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(8)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                
                // Content based on selected tab
                Group {
                    switch selectedTab {
                    case 0: // Sport tab
                        homeContent
                    case 1: // Categories tab
                        VStack {
                            Text("Categories")
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    case 2: // Search tab
                        VStack {
                            Text("Search")
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    default:
                        homeContent
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
                
                // Rent Section
                VStack(alignment: .leading, spacing: ViaplayTheme.Spacing.md) {
                    Text("Rent")
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

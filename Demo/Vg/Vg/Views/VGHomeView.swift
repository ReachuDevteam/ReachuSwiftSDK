//
//  VGHomeView.swift
//  Vg
//
//  Created by Angelo Sepulveda on 27/10/2025.
//

import SwiftUI

struct VGHomeView: View {
    let sections = Match.mockMatches
    @State private var selectedTab = 2 // "Direkte" tab
    
    var body: some View {
        ZStack {
            // Background
            VGTheme.Colors.black
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top status area
                VStack(spacing: 0) {
                    // Status Bar
                    HStack {
                        Text("12:10")
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Image(systemName: "bell.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 14))
                        }
                    }
                    .padding(.horizontal, VGTheme.Spacing.md)
                    .padding(.top, 4)
                    .padding(.bottom, VGTheme.Spacing.sm)
                    
                    // VG SPORT Logo
                    HStack {
                        Spacer()
                        HStack(spacing: 4) {
                            Text("VG")
                                .foregroundColor(VGTheme.Colors.red)
                                .font(VGTheme.Typography.title())
                                .fontWeight(.bold)
                            
                            Text("SPORT")
                                .foregroundColor(.white)
                                .font(VGTheme.Typography.title())
                                .fontWeight(.bold)
                        }
                        Spacer()
                    }
                    .padding(.bottom, VGTheme.Spacing.md)
                }
                .background(VGTheme.Colors.black)
                
                // Main Content
                ScrollView {
                    VStack(spacing: VGTheme.Spacing.xl) {
                        ForEach(sections) { section in
                            MatchSectionView(section: section)
                        }
                    }
                    .padding(.top, VGTheme.Spacing.lg)
                }
                
                Spacer()
            }
            
            // Bottom Navigation Bar
            VStack {
                Spacer()
                BottomNavigationBar(selectedTab: $selectedTab)
            }
            .ignoresSafeArea(edges: .bottom)
        }
    }
}

#Preview {
    VGHomeView()
}

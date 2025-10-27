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
                // VG Logo Header
                HStack {
                    Spacer()
                    Image("logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 32)
                    Spacer()
                }
                .padding(.vertical, VGTheme.Spacing.md)
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

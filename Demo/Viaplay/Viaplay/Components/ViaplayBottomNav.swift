//
//  ViaplayBottomNav.swift
//  Viaplay
//
//  Created by Angelo Sepulveda on 27/10/2025.
//

import SwiftUI

struct ViaplayBottomNav: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack(spacing: 0) {
            TabButton(
                icon: "house.fill",
                label: "Home",
                isSelected: selectedTab == 0
            ) {
                selectedTab = 0
            }
            
            TabButton(
                icon: "sportscourt.fill",
                label: "Sport",
                isSelected: selectedTab == 1
            ) {
                selectedTab = 1
            }
            
            TabButton(
                icon: "square.grid.2x2",
                label: "Categories",
                isSelected: selectedTab == 2
            ) {
                selectedTab = 2
            }
            
            TabButton(
                icon: "magnifyingglass",
                label: "Search",
                isSelected: selectedTab == 3
            ) {
                selectedTab = 3
            }
            
            TabButton(
                icon: "books.vertical.fill",
                label: "My library",
                isSelected: selectedTab == 4
            ) {
                selectedTab = 4
            }
        }
        .padding(.vertical, ViaplayTheme.Spacing.sm)
        .background(ViaplayTheme.Colors.darkGray)
    }
}

struct TabButton: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? .white : ViaplayTheme.Colors.lightGray)
                
                Text(label)
                    .font(.system(size: 11))
                    .foregroundColor(isSelected ? .white : ViaplayTheme.Colors.lightGray)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    ViaplayBottomNav(selectedTab: .constant(0))
        .background(ViaplayTheme.Colors.black)
}

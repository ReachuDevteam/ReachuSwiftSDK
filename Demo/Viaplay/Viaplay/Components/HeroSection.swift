//
//  HeroSection.swift
//  Viaplay
//
//  Created by Angelo Sepulveda on 27/10/2025.
//

import SwiftUI

struct HeroSection: View {
    let content: HeroContent
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background Image
            AsyncImage(url: URL(string: content.imageUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(ViaplayTheme.Colors.darkGray)
            }
            .frame(height: 500)
            .clipped()
            
            // Dark gradient overlay
            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.7)],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Content
            VStack(alignment: .leading, spacing: ViaplayTheme.Spacing.md) {
                // Title
                Text(content.title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                
                // Description
                Text(content.description)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(3)
                
                // Action Button
                Button(action: {}) {
                    Text("Les mer")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, ViaplayTheme.Spacing.lg)
                        .padding(.vertical, ViaplayTheme.Spacing.sm)
                        .background(ViaplayTheme.Colors.mediumGray)
                        .cornerRadius(ViaplayTheme.CornerRadius.medium)
                }
                
                // Pagination Dots
                HStack(spacing: 6) {
                    Circle()
                        .fill(.white)
                        .frame(width: 8, height: 8)
                    
                    ForEach(0..<4) { _ in
                        Circle()
                            .fill(.white.opacity(0.4))
                            .frame(width: 6, height: 6)
                    }
                }
                .padding(.top, ViaplayTheme.Spacing.sm)
            }
            .padding(.horizontal, ViaplayTheme.Spacing.lg)
            .padding(.bottom, ViaplayTheme.Spacing.xl)
        }
    }
}

#Preview {
    HeroSection(content: HeroContent.mock)
        .frame(height: 500)
        .background(ViaplayTheme.Colors.black)
}

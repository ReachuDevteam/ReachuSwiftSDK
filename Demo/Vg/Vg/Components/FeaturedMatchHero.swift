//
//  FeaturedMatchHero.swift
//  Vg
//
//  Created by Angelo Sepulveda on 28/10/2025.
//

import SwiftUI

struct FeaturedMatchHero: View {
    let time: String
    let title: String
    let category: String
    let description: String
    let onPlayTapped: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottomLeading) {
                // Background image from assets
                Image("bg-sport")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: 520)
                    .clipped()
                
                // Dark gradient overlay
                LinearGradient(
                    colors: [
                        Color.black.opacity(0),
                        Color.black.opacity(0.2),
                        Color.black.opacity(0.5),
                        Color.black.opacity(0.8),
                        Color.black.opacity(0.95)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(width: geometry.size.width, height: 520)
            
            // Time badge (top-left, absolute position)
            VStack {
                HStack {
                    Text(time)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.white)
                        .cornerRadius(4)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                Spacer()
            }
            .frame(width: geometry.size.width)
            .zIndex(10)
            
            // Content at bottom
            VStack {
                Spacer()
                
                VStack(alignment: .leading, spacing: 6) {
                    // Title
                    Text(title)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    // Category
                    Text(category)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.white.opacity(0.6))
                    
                    // Description with play button
                    HStack(alignment: .top, spacing: 12) {
                        Text(description)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(3)
                            .padding(.top, 4)
                        
                        // Play button (on right, over description)
                        Button(action: onPlayTapped) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.white)
                                        .offset(x: 2)
                                )
                        }
                    }
                    
                    // VG+ Sport badge
                    Text("VG+ Sport")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.top, 4)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
                .frame(width: geometry.size.width)
            }
            }
            .frame(width: geometry.size.width, height: 520)
        }
        .frame(height: 520)
    }
}

#Preview {
    FeaturedMatchHero(
        time: "I dag 18:15",
        title: "Lecce - Napoli",
        category: "Sport",
        description: "Se italiensk Serie A direkte på VG+Sport. Lecce og Napoli møtes i niende serierunde på Stadio Via del Mare i Lecce. Vegard Aulstad står for kommenteringen.",
        onPlayTapped: {
            print("Play tapped")
        }
    )
}


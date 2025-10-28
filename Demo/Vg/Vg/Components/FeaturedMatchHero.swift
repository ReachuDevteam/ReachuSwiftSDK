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
            
            // Content at bottom
            VStack {
                Spacer()
                
                VStack(alignment: .leading, spacing: 12) {
                    // Time badge (above title, more spacing)
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
                    .padding(.bottom, 8)
                    
                    // Title with play button (same row)
                    HStack(alignment: .center) {
                        Text(title)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        // Play button (same height as title, smaller, custom red)
                        Button(action: onPlayTapped) {
                            Circle()
                                .fill(Color(red: 0.85, green: 0, blue: 0))
                                .frame(width: 48, height: 48)
                                .overlay(
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                        .offset(x: 2)
                                )
                        }
                    }
                    
                    // Category
                    Text(category)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.white.opacity(0.6))
                    
                    // Description (full width, below title)
                    Text(description)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(3)
                        .padding(.top, 4)
                    
                    // VG+ Sport badge
                    Text("VG+ Sport")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.top, 6)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
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


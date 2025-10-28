//
//  FeaturedMatchHero.swift
//  Vg
//
//  Created by Angelo Sepulveda on 28/10/2025.
//

import SwiftUI

struct FeaturedMatchHero: View {
    let imageUrl: String
    let time: String
    let title: String
    let category: String
    let description: String
    let onPlayTapped: () -> Void
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background image
            AsyncImage(url: URL(string: imageUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color(red: 0.15, green: 0.15, blue: 0.2))
            }
            .frame(height: 420)
            .clipped()
            
            // Dark gradient overlay
            LinearGradient(
                colors: [
                    Color.black.opacity(0),
                    Color.black.opacity(0.3),
                    Color.black.opacity(0.7),
                    Color.black.opacity(0.95)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 420)
            
            // Content
            VStack(alignment: .leading, spacing: 12) {
                // Time badge
                Text(time)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white)
                    .cornerRadius(4)
                
                // Title
                Text(title)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                // Category
                Text(category)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
                
                // Description
                Text(description)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white.opacity(0.85))
                    .lineLimit(3)
                    .padding(.top, 4)
                
                // VG+ Sport badge
                Text("VG+ Sport")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.top, 2)
                
                // Play button
                Button(action: onPlayTapped) {
                    HStack(spacing: 0) {
                        Spacer()
                        
                        Circle()
                            .fill(Color.red)
                            .frame(width: 64, height: 64)
                            .overlay(
                                Image(systemName: "play.fill")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                                    .offset(x: 2) // Slight offset to center visually
                            )
                        
                        Spacer()
                    }
                }
                .padding(.top, 16)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .frame(height: 420)
    }
}

#Preview {
    FeaturedMatchHero(
        imageUrl: "https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=800",
        time: "I dag 18:15",
        title: "Lecce - Napoli",
        category: "Sport",
        description: "Se italiensk Serie A direkte på VG+Sport. Lecce og Napoli møtes i niende serierunde på Stadio Via del Mare i Lecce. Vegard Aulstad står for kommenteringen.",
        onPlayTapped: {
            print("Play tapped")
        }
    )
}


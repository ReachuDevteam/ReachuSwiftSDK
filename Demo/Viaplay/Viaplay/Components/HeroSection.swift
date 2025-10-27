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
        ZStack {
            // Background Image
            AsyncImage(url: URL(string: content.imageUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color(red: 0.15, green: 0.1, blue: 0.12))
            }
            .frame(height: 650)
            .clipped()
            
            // Dark gradient overlay
            LinearGradient(
                colors: [Color.black.opacity(0.3), Color.clear, Color.clear, Color.black.opacity(0.9)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 650)
            
            VStack(spacing: 0) {
                // Header with Logo and Boombox
                HStack {
                    Spacer()
                    
                    // Viaplay Logo from assets
                    Image("logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 28)
                    
                    Spacer()
                    
                    // Boombox icon
                    Image(systemName: "music.note.list")
                        .font(.system(size: 18))
                        .foregroundColor(.cyan)
                        .padding(8)
                        .background(Color.cyan.opacity(0.2))
                        .cornerRadius(8)
                }
                .padding(.horizontal, 20)
                .padding(.top, 50)
                
                Spacer()
                
                // Content at bottom
                VStack(alignment: .leading, spacing: 16) {
                    // Title
                    Text(content.title)
                        .font(.system(size: 38, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    // Description
                    Text(content.description)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(.white.opacity(0.95))
                        .lineLimit(2)
                        .padding(.bottom, 8)
                    
                    // Action Buttons
                    HStack(spacing: 16) {
                        // Crown Button (Pink)
                        Button(action: {}) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 60, height: 50)
                                .background(
                                    LinearGradient(
                                        colors: [Color(red: 0.91, green: 0.12, blue: 0.39), Color(red: 0.85, green: 0.10, blue: 0.35)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .cornerRadius(12)
                        }
                        
                        // Les mer Button (Gray)
                        Button(action: {}) {
                            Text("Les mer")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 180, height: 50)
                                .background(Color(red: 0.25, green: 0.25, blue: 0.28))
                                .cornerRadius(12)
                        }
                    }
                    
                    // Pagination Dots
                    HStack(spacing: 8) {
                        Circle()
                            .fill(.white)
                            .frame(width: 8, height: 8)
                        
                        ForEach(0..<5) { _ in
                            Circle()
                                .fill(.white.opacity(0.4))
                                .frame(width: 7, height: 7)
                        }
                    }
                    .padding(.top, 12)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .frame(height: 650)
    }
}

#Preview {
    HeroSection(content: HeroContent.mock)
        .background(Color.black)
}

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
            // Background Image from assets
            Image("bg-main")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 620)
                .clipped()
            
            // Dark gradient overlay
            LinearGradient(
                colors: [Color.black.opacity(0.3), Color.clear, Color.clear, Color.black.opacity(0.85)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 620)
            
            VStack(spacing: 0) {
                // Header with Logo and Boombox
                HStack {
                    Spacer()
                    
                    // Viaplay Logo from assets
                    Image("logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 26)
                    
                    Spacer()
                    
                    // Boombox icon
                    Image(systemName: "music.note.list")
                        .font(.system(size: 17))
                        .foregroundColor(.cyan)
                        .padding(7)
                        .background(Color.cyan.opacity(0.2))
                        .cornerRadius(7)
                }
                .padding(.horizontal, 16)
                .padding(.top, 50)
                
                Spacer()
                
                // Content at bottom
                VStack(alignment: .leading, spacing: 12) {
                    // Title
                    Text(content.title)
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    // Description
                    Text(content.description)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.white.opacity(0.95))
                        .lineLimit(2)
                    
                    // Action Buttons
                    HStack(spacing: 12) {
                        // Crown Button (Pink)
                        Button(action: {}) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 54, height: 46)
                                .background(
                                    LinearGradient(
                                        colors: [Color(red: 0.91, green: 0.12, blue: 0.39), Color(red: 0.85, green: 0.10, blue: 0.35)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .cornerRadius(10)
                        }
                        
                        // Les mer Button (Gray)
                        Button(action: {}) {
                            Text("Les mer")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 150, height: 46)
                                .background(Color(red: 0.28, green: 0.28, blue: 0.32))
                                .cornerRadius(10)
                        }
                    }
                    .padding(.top, 4)
                    
                    // Pagination Dots
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
                    .padding(.top, 10)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
        }
        .frame(height: 620)
    }
}

#Preview {
    HeroSection(content: HeroContent.mock)
        .background(Color.black)
}

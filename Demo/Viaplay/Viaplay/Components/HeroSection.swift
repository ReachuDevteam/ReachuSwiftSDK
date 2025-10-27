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
                .frame(height: 700)
                .clipped()
            
            // Dark gradient overlay
            LinearGradient(
                colors: [Color.black.opacity(0.4), Color.clear, Color.clear, Color.black.opacity(0.85)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 700)
            
            VStack(spacing: 0) {
                // Header with Logo and Avatar
                HStack {
                    Spacer()
                    
                    // Viaplay Logo from assets
                    Image("logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 26)
                    
                    Spacer()
                    
                    // Avatar/Profile circle (instead of boombox icon)
                    Circle()
                        .fill(Color.cyan.opacity(0.3))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.cyan)
                        )
                }
                .padding(.horizontal, 16)
                .padding(.top, 60)
                
                Spacer()
                
                // Content at bottom
                VStack(alignment: .center, spacing: 12) {
                    // Title (centered)
                    Text(content.title)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                    
                    // Description (centered)
                    Text(content.description)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.white.opacity(0.95))
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                    
                    // Action Buttons (centered)
                    HStack(spacing: 14) {
                        // Crown Button (Pink/Magenta)
                        Button(action: {}) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 70, height: 50)
                                .background(
                                    Color(red: 0.96, green: 0.08, blue: 0.42) // Magenta/Pink #F51569
                                )
                                .cornerRadius(8)
                        }
                        
                        // Les mer Button (Dark Gray)
                        Button(action: {}) {
                            Text("Les mer")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 160, height: 50)
                                .background(Color(red: 0.23, green: 0.24, blue: 0.27))
                                .cornerRadius(8)
                        }
                    }
                    .padding(.top, 6)
                    
                    // Pagination Dots (centered)
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
                    .padding(.top, 12)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                .padding(.bottom, 36)
            }
        }
        .frame(height: 700)
    }
}

#Preview {
    HeroSection(content: HeroContent.mock)
        .background(Color.black)
}

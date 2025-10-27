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
        GeometryReader { geometry in
            ZStack {
                // Background Image from assets
                Image("bg-main")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: 620)
                    .clipped()
                
                // Dark gradient overlay (fade to background color)
                LinearGradient(
                    colors: [
                        Color.clear,
                        Color.clear,
                        Color(hex: "1B1B25").opacity(0.3),
                        Color(hex: "1B1B25").opacity(0.7),
                        Color(hex: "1B1B25")
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(width: geometry.size.width, height: 620)
                
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
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            // Description (centered)
                            Text(content.description)
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(.white.opacity(0.95))
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            // Action Buttons (centered) - Same size for both
                            HStack(spacing: 12) {
                                // Crown Button (Pink/Magenta) - Same size as Les mer
                                Button(action: {}) {
                                    Image(systemName: "crown.fill")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(width: 160, height: 50)
                                        .background(
                                            Color(red: 0.96, green: 0.08, blue: 0.42) // Magenta/Pink #F51569
                                        )
                                        .cornerRadius(10)
                                }
                                
                                // Les mer Button (Dark Gray) - Same size as Crown
                                Button(action: {}) {
                                    Text("Les mer")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(width: 160, height: 50)
                                        .background(Color(red: 0.23, green: 0.24, blue: 0.27))
                                        .cornerRadius(10)
                                }
                            }
                            .padding(.top, 6)
                        }
                        .frame(maxWidth: geometry.size.width)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)
                    }
            }
            .frame(width: geometry.size.width, height: 620)
        }
        .frame(height: 620)
    }
}

#Preview {
    HeroSection(content: HeroContent.mock)
        .background(Color.black)
}

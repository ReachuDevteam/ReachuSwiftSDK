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
        ZStack(alignment: .top) {
            // Background Image
            AsyncImage(url: URL(string: content.imageUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color(red: 0.15, green: 0.1, blue: 0.12))
            }
            .frame(height: 600)
            .clipped()
            
            // Dark gradient overlay
            LinearGradient(
                colors: [Color.black.opacity(0.6), Color.clear, Color.black.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 600)
            
            VStack(spacing: 0) {
                // Viaplay Logo at top
                HStack(spacing: 6) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(red: 1.0, green: 0.2, blue: 0.6), Color(red: 0.6, green: 0.2, blue: 1.0)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text("viaplay")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.top, 60)
                
                Spacer()
                
                // Content at bottom
                VStack(alignment: .leading, spacing: 12) {
                    // Title
                    Text(content.title)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    // Description
                    Text(content.description)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(2)
                    
                    // Pagination Dots
                    HStack(spacing: 6) {
                        Circle()
                            .fill(.white)
                            .frame(width: 8, height: 8)
                        
                        ForEach(0..<5) { _ in
                            Circle()
                                .fill(.white.opacity(0.4))
                                .frame(width: 6, height: 6)
                        }
                    }
                    .padding(.top, 8)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
    }
}

#Preview {
    HeroSection(content: HeroContent.mock)
        .frame(height: 600)
        .background(Color.black)
}

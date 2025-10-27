//
//  CategoryButton.swift
//  Viaplay
//
//  Created by Angelo Sepulveda on 27/10/2025.
//

import SwiftUI

struct CategoryButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color(red: 0.18, green: 0.19, blue: 0.22))
                .cornerRadius(12)
        }
    }
}

struct CategoryCard: View {
    let title: String
    let imageUrl: String
    let seasonEpisode: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                // Thumbnail
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color(red: 0.15, green: 0.15, blue: 0.2))
                }
                .frame(width: 150, height: 210)
                .clipped()
                .cornerRadius(10)
                
                // Crown icon at bottom center
                VStack {
                    Spacer()
                    
                    HStack {
                        Spacer()
                        
                        ZStack {
                            Circle()
                                .fill(Color(red: 0.35, green: 0.35, blue: 0.38))
                                .frame(width: 48, height: 48)
                            
                            Image(systemName: "crown.fill")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                    }
                    .offset(y: 24)
                }
            }
            .frame(width: 150, height: 210)
            
            // Season/Episode info
            if let seasonEpisode = seasonEpisode {
                Text(seasonEpisode)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }
}

#Preview {
    VStack {
        CategoryButton(title: "Series") {}
        CategoryCard(title: "Truckers", imageUrl: "", seasonEpisode: "S3 | E2")
    }
    .padding()
    .background(Color.black)
}


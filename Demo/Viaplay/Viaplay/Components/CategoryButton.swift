//
//  CategoryButton.swift
//  Viaplay
//
//  Created by Angelo Sepulveda on 27/10/2025.
//

import SwiftUI

// MARK: - Color Extension for Hex Support
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct CategoryButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 64)
                .background(Color(hex: "302F3F"))
                .cornerRadius(16)
        }
    }
}

struct CategoryCard: View {
    let title: String
    let imageUrl: String
    let seasonEpisode: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
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
                .frame(width: 170, height: 240)
                .clipped()
                .cornerRadius(14)
                
                // Crown icon at bottom center
                VStack {
                    Spacer()
                    
                    HStack {
                        Spacer()
                        
                        ZStack {
                            Circle()
                                .fill(Color(red: 0.35, green: 0.35, blue: 0.38))
                                .frame(width: 54, height: 54)
                            
                            Image(systemName: "crown.fill")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                    }
                    .offset(y: 27)
                }
            }
            .frame(width: 170, height: 240)
            
            // Season/Episode info
            if let seasonEpisode = seasonEpisode {
                Text(seasonEpisode)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
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


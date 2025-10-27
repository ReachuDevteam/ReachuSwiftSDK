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
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(Color(hex: "302F3F"))
                .cornerRadius(14)
        }
    }
}

struct CategoryCard: View {
    let title: String
    let imageUrl: String
    let seasonEpisode: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .center) {
                // Thumbnail
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color(red: 0.15, green: 0.15, blue: 0.2))
                }
                .frame(width: 130, height: 185)
                .clipped()
                .cornerRadius(10)
                
                // Crown icon in center with alpha background
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.5))
                        .frame(width: 46, height: 46)
                    
                    Image(systemName: "crown.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .frame(width: 130, height: 185)
            
            // Season/Episode info
            if let seasonEpisode = seasonEpisode {
                Text(seasonEpisode)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }
}

struct RentBuyCard: View {
    let title: String
    let imageUrl: String
    let badge: String // "Buy", "Rent", or "KINOAKTUE"
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Thumbnail
            AsyncImage(url: URL(string: imageUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color(red: 0.15, green: 0.15, blue: 0.2))
            }
            .frame(width: 130, height: 185)
            .clipped()
            .cornerRadius(10)
            
            // Badge (Buy/Rent/KINOAKTUE)
            if !badge.isEmpty {
                Text(badge)
                    .font(.system(size: badge == "KINOAKTUE" ? 10 : 11, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, badge == "KINOAKTUE" ? 8 : 10)
                    .padding(.vertical, 4)
                    .background(
                        badge == "KINOAKTUE" ? Color(red: 0.96, green: 0.08, blue: 0.42) : Color.black.opacity(0.7)
                    )
                    .cornerRadius(4)
                    .padding(8)
            }
        }
        .frame(width: 130, height: 185)
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


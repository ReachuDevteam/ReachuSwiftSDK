//
//  ContinueWatchingCard.swift
//  Viaplay
//
//  Created by Angelo Sepulveda on 27/10/2025.
//

import SwiftUI

struct ContinueWatchingCard: View {
    let item: ContinueWatchingItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                // Thumbnail Image
                AsyncImage(url: URL(string: item.imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(ViaplayTheme.Colors.mediumGray)
                }
                .frame(width: 140, height: 200)
                .clipped()
                .cornerRadius(ViaplayTheme.CornerRadius.medium)
                
                // Rent Label
                if let rentLabel = item.rentLabel {
                    Text(rentLabel)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(4)
                        .padding(8)
                }
            }
            
            // Title
            Text(item.title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(2)
                .padding(.top, 6)
                .frame(width: 140)
        }
    }
}

#Preview {
    ContinueWatchingCard(item: ContinueWatchingItem.mockItems[0])
        .background(ViaplayTheme.Colors.black)
}

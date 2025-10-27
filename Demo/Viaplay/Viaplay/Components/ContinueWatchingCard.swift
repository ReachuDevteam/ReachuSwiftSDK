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
            ZStack(alignment: .topLeading) {
                // Thumbnail Image
                AsyncImage(url: URL(string: item.imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color(red: 0.15, green: 0.15, blue: 0.2))
                }
                .frame(width: 160, height: 230)
                .clipped()
                .cornerRadius(8)
                
                // Rent Label (top left corner)
                if let rentLabel = item.rentLabel {
                    Text(rentLabel)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.75))
                        .cornerRadius(4)
                        .padding(8)
                }
            }
            
            // Title (hidden as not visible in reference)
        }
    }
}

#Preview {
    ContinueWatchingCard(item: ContinueWatchingItem.mockItems[0])
        .background(ViaplayTheme.Colors.black)
}

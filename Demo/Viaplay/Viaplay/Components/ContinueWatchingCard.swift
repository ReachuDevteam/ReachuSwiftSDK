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

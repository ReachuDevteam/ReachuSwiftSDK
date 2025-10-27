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
        ZStack(alignment: .bottom) {
            // Thumbnail Image
            AsyncImage(url: URL(string: item.imageUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color(red: 0.15, green: 0.15, blue: 0.2))
            }
            .frame(width: 130, height: 190)
            .clipped()
            .cornerRadius(12)
            
            // Crown icon at bottom center
            Image(systemName: "crown.fill")
                .font(.system(size: 22))
                .foregroundColor(.white)
                .padding(12)
                .background(
                    Circle()
                        .fill(Color(red: 0.3, green: 0.3, blue: 0.35).opacity(0.9))
                        .frame(width: 44, height: 44)
                )
                .offset(y: 22) // Half outside the card
        }
        .frame(width: 130, height: 190)
    }
}

#Preview {
    ContinueWatchingCard(item: ContinueWatchingItem.mockItems[0])
        .background(Color.black)
}

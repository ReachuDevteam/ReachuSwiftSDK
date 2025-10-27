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
            .frame(width: 200, height: 280)
            .clipped()
            .cornerRadius(16)
            
            // Rent Label (top left corner)
            if let rentLabel = item.rentLabel {
                Text(rentLabel)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.black.opacity(0.75))
                    .cornerRadius(6)
                    .padding(10)
            }
            
            // Crown icon at bottom center (for items without rent label)
            if item.rentLabel == nil {
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
                    .offset(y: 27) // Half outside the card
                }
            }
        }
        .frame(width: 200, height: 280)
    }
}

#Preview {
    HStack(spacing: 16) {
        ContinueWatchingCard(item: ContinueWatchingItem.mockItems[0])
        ContinueWatchingCard(item: ContinueWatchingItem.mockItems[1])
        ContinueWatchingCard(item: ContinueWatchingItem.mockItems[2])
    }
    .padding()
    .background(Color.black)
}

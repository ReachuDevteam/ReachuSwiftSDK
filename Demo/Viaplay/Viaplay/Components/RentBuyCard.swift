import SwiftUI

struct RentBuyCard: View {
    let title: String
    let imageUrl: String
    let badge: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Image with badge overlay
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                }
                .frame(width: 140, height: 80)
                .clipped()
                .cornerRadius(8)
                
                // Badge
                Text(badge)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        badge == "KINOAKTUE" ? Color.red :
                        badge == "Rent" ? Color.blue :
                        badge == "Buy" ? Color.green : Color.gray
                    )
                    .cornerRadius(4)
                    .padding(.top, 6)
                    .padding(.trailing, 6)
            }
            
            // Title
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
        .frame(width: 140, alignment: .leading)
    }
}

#Preview {
    VStack(spacing: 16) {
        RentBuyCard(
            title: "The Conjuring 4",
            imageUrl: "https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=300",
            badge: "KINOAKTUE"
        )
        
        RentBuyCard(
            title: "Jurassic World",
            imageUrl: "https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=300",
            badge: "Rent"
        )
        
        RentBuyCard(
            title: "Movie 1",
            imageUrl: "https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=300",
            badge: "Buy"
        )
    }
    .background(Color.black)
    .padding()
}

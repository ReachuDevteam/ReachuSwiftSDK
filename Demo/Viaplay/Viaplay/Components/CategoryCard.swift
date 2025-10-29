import SwiftUI

struct CategoryCard: View {
    let title: String
    let imageUrl: String
    let seasonEpisode: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Image
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
            
            // Title
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            // Season/Episode if available
            if let seasonEpisode = seasonEpisode {
                Text(seasonEpisode)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
            }
        }
        .frame(width: 140, alignment: .leading)
    }
}

#Preview {
    CategoryCard(
        title: "Norske Truckers",
        imageUrl: "https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=300",
        seasonEpisode: "S3 | E2"
    )
    .background(Color.black)
    .padding()
}

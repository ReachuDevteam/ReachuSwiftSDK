import SwiftUI

/// Badge de sponsor para mostrar en la esquina de los overlays
struct TV2SponsorBadge: View {
    let logoUrl: String?
    
    var body: some View {
        if let logoUrl = logoUrl, !logoUrl.isEmpty {
            VStack(spacing: 2) {
                Text("Sponset av")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                
                AsyncImage(url: URL(string: logoUrl)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .scaleEffect(0.5)
                            .frame(width: 40, height: 20)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: 50, maxHeight: 24)
                    case .failure:
                        Image(systemName: "photo")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.3))
                            .frame(width: 40, height: 20)
                    @unknown default:
                        EmptyView()
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.4))
            )
        }
    }
}

#Preview {
    ZStack {
        Color.gray.ignoresSafeArea()
        
        TV2SponsorBadge(logoUrl: "https://via.placeholder.com/100x40")
    }
}


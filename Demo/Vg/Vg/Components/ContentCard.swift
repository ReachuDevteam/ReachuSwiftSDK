import SwiftUI

struct ContentCard: View {
    let imageName: String
    let title: String
    let subtitle: String
    let duration: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // Image with overlays
                ZStack(alignment: .bottomLeading) {
                    Image(imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 320, height: 180)
                        .clipped()
                        .cornerRadius(8)
                    
                    // VG+ Sport badge (bottom-left)
                    Text("VG+ Sport")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(4)
                        .padding(.leading, 8)
                        .padding(.bottom, 8)
                    
                    // Duration badge (bottom-right)
                    Text(duration)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(4)
                        .padding(.trailing, 8)
                        .padding(.bottom, 8)
                }
                
                // Text content below image
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Text(subtitle)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 12)
                .frame(width: 320, alignment: .leading)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ContentCard(
        imageName: "card2x1",
        title: "Tondela - Sporting CP",
        subtitle: "Sport · 2. oktober",
        duration: "02:12:09"
    ) {
        print("Content card tapped")
    }
    .background(Color.black)
    .padding()
}

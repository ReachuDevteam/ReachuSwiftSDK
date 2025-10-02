import SwiftUI

struct ContentCard: View {
    let item: ContentItem
    let width: CGFloat
    let height: CGFloat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image
            ZStack(alignment: .topLeading) {
                // Placeholder with gradient
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                TV2Theme.Colors.surface,
                                TV2Theme.Colors.surfaceLight
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: width, height: height)
                
                // Placeholder text (in production this would be AsyncImage)
                VStack {
                    Spacer()
                    Text(item.title.uppercased())
                        .font(.system(size: 20, weight: .black))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding()
                    Spacer()
                }
                .frame(width: width, height: height)
                
                // Live badge
                if item.isLive {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(TV2Theme.Colors.live)
                            .frame(width: 8, height: 8)
                        
                        Text("DIREKTE")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.8))
                    )
                    .padding(TV2Theme.Spacing.sm)
                }
                
                // Date/Duration badge
                if let date = item.date, !item.isLive {
                    Text(date)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(TV2Theme.Colors.primary)
                        )
                        .padding(TV2Theme.Spacing.sm)
                }
            }
            .cornerRadius(TV2Theme.CornerRadius.medium)
            
            // Title
            Text(item.title)
                .font(TV2Theme.Typography.caption)
                .foregroundColor(TV2Theme.Colors.textPrimary)
                .lineLimit(1)
                .padding(.top, TV2Theme.Spacing.sm)
            
            // Subtitle
            if let subtitle = item.subtitle {
                Text(subtitle)
                    .font(TV2Theme.Typography.small)
                    .foregroundColor(TV2Theme.Colors.textSecondary)
                    .lineLimit(1)
                    .padding(.top, 2)
            }
        }
        .frame(width: width)
    }
}

#Preview {
    ContentCard(
        item: ContentItem.mockItems[0],
        width: 280,
        height: 160
    )
    .padding()
    .background(TV2Theme.Colors.background)
}



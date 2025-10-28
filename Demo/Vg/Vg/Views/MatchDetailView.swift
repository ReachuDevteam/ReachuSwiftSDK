import SwiftUI

struct MatchDetailView: View {
    let matchTitle: String
    let matchSubtitle: String
    let onBackTapped: () -> Void
    let onShareTapped: () -> Void
    
    private let contentItems = [
        (image: "content1", title: "Tondela - Sporting CP", subtitle: "Sport · 2. oktober", duration: "02:12:09"),
        (image: "content2", title: "Jose Mourinho Interview", subtitle: "Sport · 1. oktober", duration: "03:01:55")
    ]
    
    var body: some View {
        ZStack {
            // Background
            VGTheme.Colors.black
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Header with back button and share
                    HStack {
                        Button(action: onBackTapped) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        Button(action: onShareTapped) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 20)
                    
                    // Main content area (placeholder for video)
                    VStack(spacing: 0) {
                        // Video placeholder - will be replaced with actual video player
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 200)
                            .overlay(
                                VStack {
                                    Image(systemName: "play.circle.fill")
                                        .font(.system(size: 50))
                                        .foregroundColor(.white.opacity(0.8))
                                    Text("Video Player Placeholder")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white.opacity(0.6))
                                        .padding(.top, 8)
                                }
                            )
                        
                        // Match details
                        VStack(alignment: .leading, spacing: 8) {
                            Text(matchTitle)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                            
                            HStack {
                                Text(matchSubtitle)
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundColor(.white.opacity(0.7))
                                
                                Spacer()
                                
                                Button(action: onShareTapped) {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                    
                    // "Neste" section
                    VStack(alignment: .leading, spacing: 16) {
                        // Section header
                        Text("Neste")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.top, 24)
                        
                        // Content cards
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(0..<contentItems.count, id: \.self) { index in
                                    ContentCard(
                                        imageName: contentItems[index].image,
                                        title: contentItems[index].title,
                                        subtitle: contentItems[index].subtitle,
                                        duration: contentItems[index].duration
                                    ) {
                                        print("Content item \(index) tapped")
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    
                    // Bottom padding
                    Spacer()
                        .frame(height: 100)
                }
            }
        }
    }
}

#Preview {
    MatchDetailView(
        matchTitle: "Moreirense - FC Porto",
        matchSubtitle: "Sport · i går, 21:05... Se mer",
        onBackTapped: {
            print("Back tapped")
        },
        onShareTapped: {
            print("Share tapped")
        }
    )
}

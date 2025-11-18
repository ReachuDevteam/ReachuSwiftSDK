import SwiftUI

struct VGPreMatchView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showPlayer = false
    
    var body: some View {
        ZStack {
            // Background image
            Image("bg")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
                .overlay(
                    // Dark overlay for better text readability
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                )
            
            VStack {
                // Close button
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .padding(.trailing, 16)
                    .padding(.top, 50)
                }
                
                Spacer()
                
                // Match title
                VStack(spacing: 16) {
                    Text("Barcelona - PSG")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    // Play button
                    Button(action: { showPlayer = true }) {
                        HStack(spacing: 12) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 18, weight: .bold))
                            Text("Watch Live")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 14)
                        .padding(.horizontal, 28)
                        .background(VGTheme.Colors.red)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .shadow(color: VGTheme.Colors.red.opacity(0.6), radius: 12, x: 0, y: 4)
                    }
                }
                .padding(.bottom, 60)
            }
        }
        .fullScreenCover(isPresented: $showPlayer) {
            VGFullScreenPlayerView()
                .preferredColorScheme(.dark)
        }
    }
}

#Preview {
    VGPreMatchView()
}


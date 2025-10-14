import SwiftUI

/// Mini player que se muestra en la parte inferior cuando hay casting activo
struct CastingMiniPlayer: View {
    @StateObject private var castingManager = CastingManager.shared
    let match: Match
    let onTap: () -> Void
    
    @State private var isPlaying = true
    
    var body: some View {
        if castingManager.isCasting {
            VStack {
                Spacer()
                
                miniPlayerCard
                    .padding(.horizontal, 16)
                    .padding(.bottom, 110) // Sobre la tab bar
            }
        }
    }
    
    private var miniPlayerCard: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Thumbnail con indicador de casting
                ZStack(alignment: .bottomLeading) {
                    Image("football_field_bg")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipped()
                        .cornerRadius(8)
                    
                    // Cast indicator
                    HStack(spacing: 4) {
                        Image(systemName: "tv.fill")
                            .font(.system(size: 8))
                        Text("LIVE")
                            .font(.system(size: 8, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.red)
                    .cornerRadius(4)
                    .padding(4)
                }
                
                // Match info
                VStack(alignment: .leading, spacing: 4) {
                    Text(castingManager.selectedDevice?.name ?? "TV")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(match.title)
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Play/Pause button
                Button(action: { isPlaying.toggle() }) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                }
                
                // Stop casting button
                Button(action: {
                    castingManager.stopCasting()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: "1a0033"))
                    .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        CastingMiniPlayer(match: Match.barcelonaPSG) {
            print("Tapped mini player")
        }
    }
}


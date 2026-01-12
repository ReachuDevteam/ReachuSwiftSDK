//
//  HighlightVideoCard.swift
//  Viaplay
//
//  Molecular component: Highlight card with video player
//

import SwiftUI
import AVKit

struct HighlightVideoCard: View {
    let highlight: HighlightTimelineEvent
    @State private var showVideoPlayer = false
    
    var body: some View {
        Button(action: {
            showVideoPlayer = true
        }) {
            HStack(spacing: 12) {
                // Thumbnail with play icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 100, height: 56)
                    
                    // Play icon
                    ZStack {
                        Circle()
                            .fill(Color.black.opacity(0.6))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: "play.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                    }
                    
                    // Type badge
                    VStack {
                        HStack {
                            Spacer()
                            
                            HStack(spacing: 3) {
                                Image(systemName: highlight.highlightType.icon)
                                    .font(.system(size: 8))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(highlightColor(for: highlight.highlightType))
                            )
                            .padding(4)
                        }
                        Spacer()
                    }
                }
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: highlight.highlightType.icon)
                            .font(.system(size: 12))
                            .foregroundColor(highlightColor(for: highlight.highlightType))
                        
                        Text(highlight.title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                    
                    if let description = highlight.description {
                        Text(description)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(2)
                    }
                    
                    Text(highlight.displayTime)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
            )
        }
        .fullScreenCover(isPresented: $showVideoPlayer) {
            if let clipUrl = highlight.clipUrl, let url = URL(string: clipUrl) {
                HighlightVideoPlayerView(videoURL: url, title: highlight.title) {
                    showVideoPlayer = false
                }
            }
        }
    }
    
    private func highlightColor(for type: HighlightTimelineEvent.HighlightType) -> Color {
        switch type {
        case .goal: return .green
        case .chance: return .orange
        case .save: return .blue
        case .yellowCard: return .yellow
        case .redCard: return .red
        case .tackle: return .cyan
        case .pass: return .purple
        case .other: return .white
        }
    }
}

// MARK: - Highlight Video Player

struct HighlightVideoPlayerView: View {
    let videoURL: URL
    let title: String
    let onDismiss: () -> Void
    
    @State private var player: AVPlayer?
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if let player = player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
            }
            
            VStack {
                HStack {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white.opacity(0.8))
                            .shadow(radius: 4)
                    }
                    .padding()
                    
                    Spacer()
                }
                
                Spacer()
                
                // Title overlay
                VStack {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.7))
                        )
                }
                .padding(.bottom, 32)
            }
        }
        .onAppear {
            player = AVPlayer(url: videoURL)
            player?.play()
            
            // Loop video
            NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: player?.currentItem,
                queue: .main
            ) { _ in
                player?.seek(to: .zero)
                player?.play()
            }
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }
}

#Preview {
    HighlightVideoCard(
        highlight: HighlightTimelineEvent(
            id: "h1",
            videoTimestamp: 780,
            title: "MÅL: A. Diallo",
            description: "Nydelig avslutning!",
            thumbnailUrl: nil,
            clipUrl: "https://firebasestorage.googleapis.com/v0/b/tipio-1ec97.appspot.com/o/1.MP4?alt=media&token=898b7836-5e27-492d-82bb-9d7bb50f9d66",
            highlightType: .goal,
            metadata: nil
        )
    )
    .padding()
    .background(Color.black)
}
